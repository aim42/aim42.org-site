source "https://rubygems.org"

gem "minimal-mistakes-jekyll"

# Jekyll 4.3.1 breaks with logger >= 1.6 (bundled with Ruby 3.3)
gem "logger", "< 1.6"
# liquid 4.0.3 calls String#tainted?, removed in Ruby 3.2
gem "liquid", ">= 4.0.4"

group :jekyll_plugins do
  gem 'jekyll-include-cache'
  gem 'webrick'
  gem 'jemoji'
end

group :test do
  gem "minitest"
  gem "nokogiri"
end
