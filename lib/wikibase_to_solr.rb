# frozen_string_literal: true

require 'digital_scriptorium'
require 'logging'
require 'optparse'
require 'time'
require 'tty-spinner'
require 'zlib'

dir = File.dirname __FILE__

input_file = File.expand_path 'wikibase_export.json.gz', dir
output_file = File.expand_path 'solr_import.json', dir
pretty_print = false

logger = Logging.logger($stdout)

OptionParser.new { |opts|
  opts.banner = 'Usage: wikibase_to_solr.rb [options]'

  opts.on('-i', '--in FILE', 'The file path to the gzipped Wikibase JSON export file.') do |f|
    input_file = File.expand_path f, dir
  end

  opts.on('-o', '--out FILE', 'The file path to output the formatted Solr JSON file.') do |f|
    output_file = File.expand_path f, dir
  end

  opts.on('-p', '--pretty-print', 'Whether to pretty-print the JSON output.') do
    pretty_print = true
  end
}.parse!

def merge(solr_item, new_props)
  solr_item.merge(new_props) do |_, old_val, new_val|
    old_val.nil? ? new_val : (old_val + new_val).uniq
  end
end

def base_solr_item(meta)
  ds_id = meta.manuscript.ds_id
  {
    'qid_meta' => [meta.holding.id, meta.manuscript.id, meta.record.id],
    'id' => [ds_id],
    'id_display' => [JSON.generate(recorded_value: ds_id)],
    'id_search' => [ds_id]
  }
end

def record?(entity)
  entity.is_a?(DigitalScriptorium::DsItem) &&
    entity.claims_by_property_id?(DigitalScriptorium::PropertyId::INSTANCE_OF) &&
    entity.record?
end

start_time = Time.now.utc

loading_spinner = TTY::Spinner.new('[:spinner] Loading export data', hide_cursor: true)
loading_spinner.auto_spin

export_json = Zlib::GzipReader.open(input_file).read
export_hash = DigitalScriptorium::ExportRepresenter.new(DigitalScriptorium::Export.new)
                                                   .from_json(export_json)
                                                   .to_hash
loaded_time = Time.now.utc
loading_spinner.success("(#{format('%0.02f', loaded_time - start_time)}s)")

item_count = 0
generating_spinner = TTY::Spinner.new('[:spinner] Generating Solr documents', hide_cursor: true)
generating_spinner.auto_spin

File.open(output_file, 'w') do |file|
  file << '['
  file << "\n" if pretty_print

  export_hash.each_with_index do |(_, entity), idx|
    next unless record?(entity)

    meta = DigitalScriptorium::DsMeta.new(entity, export_hash)
    solr_item = base_solr_item(meta)

    [meta.holding, meta.manuscript, meta.record].each do |item|
      item.claims.each do |property_id, claims|
        claims.each do |claim|
          next unless DigitalScriptorium::Transformers.defined? property_id

          begin
            transformer = DigitalScriptorium::Transformers.create property_id, claim, export_hash
            solr_item = merge solr_item, transformer.solr_props
          rescue StandardError => e
            logger.error "Error processing #{property_id} claim for item #{item.id}: #{e}"
          end
        end
      end
    end

    file << (pretty_print ? JSON.pretty_generate(solr_item) : JSON.generate(solr_item))
    file << ',' if idx < export_hash.size - 1
    file << "\n" if pretty_print

    item_count += 1
  end

  file << ']'
end

finish_time = Time.now.utc
generating_spinner.success("(#{format('%0.02f', finish_time - loaded_time)}s)")
logger.info "Generated #{item_count} Solr documents in #{format('%0.02f', finish_time - start_time)} seconds"
