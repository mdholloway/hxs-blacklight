# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.2'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 7.0.4'

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails'

# Use PostgreSQL as the database for Active Record
gem 'pg', '~> 1.4'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '~> 5.0'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'

# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

gem 'addressable', '~> 2.8'
gem 'blacklight', '>= 7.0'
gem 'blacklight_range_limit', '~> 7.8'
gem 'bootstrap', '~> 4.0'
gem 'devise'
gem 'devise-guests', '~> 0.8'
gem 'faraday', '~> 2.7'
gem 'hashdiff', '~> 1.0'
gem 'jquery-rails'
gem 'jsbundling-rails', '~> 1.1'
gem 'rsolr', '>= 1.0', '< 3'
gem 'sassc-rails', '~> 2.1'
gem 'twitter-typeahead-rails', '0.11.1.pre.corejavascript'
gem 'whenever', '~> 1.0', require: false

# gem 'blacklight_advanced_search', '~> 7.0'
# BL Advanced Search / Pinned to EWL bug-fix
# See: https://github.com/projectblacklight/blacklight_advanced_search/issues/127
gem 'blacklight_advanced_search', git: 'https://github.com/ewlarson/blacklight_advanced_search.git',
                                  branch: 'bl7-fix-gentle-hands'

group :development, :test do
  gem 'brakeman', require: false
  gem 'bundler-audit', require: false
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'upennlib-rubocop', '~> 1.1', require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end
