# frozen_string_literal: true

require 'digital_scriptorium'
require 'logging'
require 'optparse'
require 'time'
require 'zlib'

dir = File.dirname __FILE__
logger = Logging.logger($stdout)

options = {}

OptionParser.new { |opts|
  opts.banner = 'Usage: wikibase_to_solr.rb [options]'

  opts.on('-i', '--in FILE', 'The file path to the gzipped Wikibase JSON export file.') do |f|
    options[:input_file] = f
  end

  opts.on('-o', '--out FILE', 'The file path to output the formatted Solr JSON file.') do |f|
    options[:output_file] = f
  end

  opts.on('-p', '--pretty-print', 'Whether to pretty-print the JSON output.') do
    options[:pretty_print] = true
  end
}.parse!

abort('Input file (-i) is required.') unless options[:input_file]
abort('Output file (-o) is required.') unless options[:output_file]

input_file = options[:input_file]
output_file = options[:output_file]
pretty_print = options[:pretty_print]

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

export_json = Zlib::GzipReader.open(input_file).read
export_hash = DigitalScriptorium::ExportRepresenter.new(DigitalScriptorium::Export.new)
                                                   .from_json(export_json)
                                                   .to_hash

start_time = Time.now.utc
item_count = 0

File.open(output_file, 'w') do |file|
  file << '['

  export_hash.each_value do |entity|
    next unless record?(entity)

    meta = DigitalScriptorium::DsMeta.new(entity, export_hash)
    solr_item = base_solr_item(meta)

    [meta.holding, meta.manuscript, meta.record].each do |item|
      item.claims_hash.each do |property_id, claims|
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

    file << ',' if item_count.positive?
    file << "\n" if pretty_print
    file << (pretty_print ? JSON.pretty_generate(solr_item) : JSON.generate(solr_item))

    item_count += 1
  end

  file << "\n" if pretty_print
  file << ']'
end

finish_time = Time.now.utc
logger.info "Generated #{item_count} Solr documents in #{format('%0.02f', finish_time - start_time)} seconds"
