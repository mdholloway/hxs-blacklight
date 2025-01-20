# frozen_string_literal: true

require 'test_helper'

class IndexTest < ActionDispatch::IntegrationTest
  test 'all items display DS ID and title' do
    get '/?search_field=all_fields&q=almagest'
    assert_response :success

    assert_select '.documents-list > article' do |articles|
      articles.each do |article|
        assert_select article, '.blacklight-id'
        assert_select article, '.blacklight-title_facet'
      end
    end
  end
end
