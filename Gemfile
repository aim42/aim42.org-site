source "https://rubygems.org"

gem "jekyll", "4.3.1"
# The contrast and CSS tests rely on libsass passing color-mix() through.
gem "jekyll-sass-converter", "~> 2.2"

# Jekyll 4.3.1 breaks with logger >= 1.6 (bundled with Ruby 3.3)
gem "logger", "< 1.6"
# liquid 4.0.3 calls String#tainted?, removed in Ruby 3.2
gem "liquid", ">= 4.0.4"

group :jekyll_plugins do
  gem "jekyll-sitemap"
  gem "webrick"
end

group :test do
  gem "minitest"
  gem "nokogiri"
end
