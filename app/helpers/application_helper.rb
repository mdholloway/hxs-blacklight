# frozen_string_literal: true

# Application view helper methods
module ApplicationHelper
  LINK_DATA_DEFAULT = :other
  LINK_DATA_ACRONYMS = {
    wikidata: {
      domain: 'wikidata.org'
    },
    tgn: {
      host: 'vocab.getty.edu',
      path: %r{^/tgn/}i
    },
    aat: {
      host: 'vocab.getty.edu',
      path: %r{^/aat/}i
    }
  }.freeze

  # rubocop:disable Lint/UnusedMethodArgument
  #  Blacklight requires the named arguments
  def make_link(document:, field:, value:, context:, config:)
    safe_join(Array(value).map do |v|
                link_to(v, v)
              end, ',')
  end
  # rubocop:enable Lint/UnusedMethodArgument

  # rubocop:disable Lint/UnusedMethodArgument
  #  Blacklight requires the named arguments
  def make_btn_iiif(document:, field:, value:, context:, config:)
    safe_join(Array(value).map do |v|
                link_to('IIIF Manifest', v, class: 'btn btn-secondary')
              end, ',')
  end
  # rubocop:enable Lint/UnusedMethodArgument

  # rubocop:disable Lint/UnusedMethodArgument
  #  Blacklight requires the named arguments
  def make_btn_inst(document:, field:, value:, context:, config:)
    safe_join(Array(value).map do |v|
                link_to('Institutional Record', v, class: 'btn btn-secondary')
              end, ',')
  end
  # rubocop:enable Lint/UnusedMethodArgument

  #  Blacklight requires the named arguments
  def link_with_copy(document:, field:, value:, context:, config:)
    values = value.map do |v|
      render partial: 'shared/link_with_icon',
             locals: { document: document, field: field, value: v, context: context, config: config }
    end

    safe_join values, "\n"
  end

  def century_label(value)
    case value
    # ADD WIKIBASE DATA REFERENCE
    when '101'
      '2nd century'
    when '201'
      '3rd century'
    when '301'
      '4th century'
    when '401'
      '5th century'
    when '501'
      '6th century'
    when '601'
      '7th century'
    when '701'
      '8th century'
    when '801'
      '9th century'
    when '901'
      '10th century'
    when '1001'
      '11th century'
    when '1101'
      '12th century'
    when '1201'
      '13th century'
    when '1301'
      '14th century'
    when '1401'
      '15th century'
    when '1501'
      '16th century'
    when '1601'
      '17th century'
    when '1701'
      '18th century'
    when '1801'
      '19th century'
    when '1901'
      '20th century'
    when '2001'
      '21st century'
    else
      value
    end
  end

  # V2.0 TEXT ONLY
  # rubocop:disable Lint/UnusedMethodArgument
  #  Blacklight requires the named arguments
  def property_value(document:, field:, value:, context:, config:)
    values = Array(value).map do |json_string|
      data = JSON.parse json_string
      get_display_text(data)
    end

    safe_join values, '<br />'.html_safe
  end
  # rubocop:enable Lint/UnusedMethodArgument

  # rubocop:disable Lint/UnusedMethodArgument
  #  Blacklight requires the named arguments
  def search_term_link(document:, field:, value:, context:, config:, facet_field: nil)
    facet_field ||= generate_search_facet_field field
    links = Array(value).map { |term| search_term_item term, field, facet_field }
    safe_join links, "\n"
  end
  # rubocop:enable Lint/UnusedMethodArgument

  # V2.0 VISUAL BAR, NO LINKED DATA
  # rubocop:disable Lint/UnusedMethodArgument
  #  Blacklight requires the named arguments
  def search_link(document:, field:, value:, context:, config:, facet_field: nil)
    facet_field ||= generate_search_facet_field field
    links = Array(value).map { |json_string| search_link_item json_string, field, facet_field }
    safe_join links, "\n"
  end
  # rubocop:enable Lint/UnusedMethodArgument

  # V3.1 Linked Data bar with placeholder grayscale icon and #AUTH# hyperlink + AGR value
  # rubocop:disable Lint/UnusedMethodArgument
  #  Blacklight requires the named arguments
  def search_data_link(document:, field:, value:, context:, config:, facet_field: nil)
    facet_field ||= generate_search_facet_field field
    links = Array(value).map { |json_string| search_data_link_item json_string, field, facet_field }
    safe_join links, "\n"
  end
  # rubocop:enable Lint/UnusedMethodArgument

  private

  def generate_search_facet_field(field)
    "#{field.to_s.split('_')[0...-1].join('_')}_facet"
  end

  def search_term_item(term, field, facet_field)
    return if term.blank?

    render partial: 'shared/search_link',
           locals: { field: field, facet_field: facet_field, term: term }
  end

  def search_link_item(json_string, field, facet_field)
    data = JSON.parse json_string
    return unless data['linked_terms']

    render partial: 'shared/search_link',
           locals: {
             field: field,
             facet_field: facet_field,
             term: data['linked_terms'].first['label']
           }
  end

  def search_data_link_item(json_string, _field, facet_field)
    data = JSON.parse json_string
    render partial: 'shared/search_data_link',
           locals: {
             display_text: get_display_text(data),
             linked_terms: (data['linked_terms'] || []).map do |term|
               {
                 label: term['label'],
                 facet_field: term['facet_field'] || facet_field,
                 facet_value: term['facet_value'] || term['label'],
                 source_url: term['source_url'],
                 source_acronym: find_url_acronym(term['source_url'])
               }
             end
           }
  end

  def get_display_text(data)
    data['original_script'].present? ? "#{data['recorded_value']} / #{data['original_script']}" : data['recorded_value']
  end

  def find_url_acronym(url, default: LINK_DATA_DEFAULT)
    return nil if url.blank?

    uri = Addressable::URI.parse url
    LINK_DATA_ACRONYMS.keys.find(-> { default }) { |key| url_acronym_match? uri, LINK_DATA_ACRONYMS[key] }
  end

  def url_acronym_match?(uri, acronym)
    acronym.all? do |part, test|
      case test
      when Regexp
        uri.send(part).match? test
      else
        uri.send(part) == test
      end
    end
  end
end
