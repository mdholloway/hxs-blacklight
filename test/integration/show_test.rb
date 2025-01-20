# frozen_string_literal: true

require 'test_helper'

class ShowTest < ActionDispatch::IntegrationTest
  test 'correctly displays Kitāb al-Majisṭī (DS 156)' do
    get '/catalog/DS156'
    assert_response :success

    # Assert title author, language, material values with linked data bars
    assert_select 'dd.blacklight-title_display > div.ds-ld-bar'
    assert_select 'dd.blacklight-author_display > div.ds-ld-bar'
    assert_select 'dd.blacklight-language_display > div.ds-ld-bar'
    assert_select 'dd.blacklight-material_display > div.ds-ld-bar'

    # Assert title value with original script text
    assert_select 'dd.blacklight-title_display' do |el|
      el.text.starts_with?('Kitāb al-Majisṭī / كتاب المجسطي.')
    end

    # Assert author value with original script text
    assert_select 'dd.blacklight-author_display' do |el|
      el.text.starts_with?('Ptolemy, active 2nd century / بطليموس، active 2nd century')
    end

    # Assert owner values with original script and linked data bars
    assert_select 'dd.blacklight-owner_display' do |el|
      assert el.text.include?('/') unless el.text.starts_with?('Schoenberg, Lawrence J')
      assert_select '> div.ds-ld-bar'
    end
  end

  test 'correctly displays breviary sine numero (DS 261)' do
    get '/catalog/DS261'
    assert_response :success

    # Assert title, scribe, artist, date, language, material values with linked data bars
    assert_select 'dd.blacklight-title_display > div.ds-ld-bar'
    assert_select 'dd.blacklight-scribe_display > div.ds-ld-bar'
    assert_select 'dd.blacklight-artist_display > div.ds-ld-bar'
    assert_select 'dd.blacklight-date_display > div.ds-ld-bar'
    assert_select 'dd.blacklight-language_display > div.ds-ld-bar'
    assert_select 'dd.blacklight-material_display > div.ds-ld-bar'

    # Assert place value with two linked data bars
    assert_select 'dd.blacklight-place_display > div.ds-ld-bar', 2

    # Assert owner value with four linked data bars
    assert_select 'dd.blacklight-owner_display > div.ds-ld-bar', 4
  end
end
