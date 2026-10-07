# Checks on the generated site. Run after `bundle exec jekyll build`.
require "minitest/autorun"
require "nokogiri"

SITE_DIR = File.expand_path("../_site", __dir__)

class SiteTest < Minitest::Test
  # Resolves a site URL ("/about", "/patterns/atam/") to its generated file.
  def site_file(url)
    url = url.sub(%r{\?.*\z}, "").sub(/#.*\z/, "")
    candidates = if url.end_with?("/")
                   [File.join(SITE_DIR, url, "index.html")]
                 else
                   [File.join(SITE_DIR, url), File.join(SITE_DIR, "#{url}.html"), File.join(SITE_DIR, url, "index.html")]
                 end
    candidates.find { |f| File.file?(f) }
  end

  def page(url)
    file = site_file(url)
    assert file, "expected #{url} to be generated under _site/"
    Nokogiri::HTML(File.read(file))
  end

  def test_home_page_still_builds_with_minimal_mistakes
    doc = page("/")
    assert doc.at_css(".page__hero--overlay, .page__hero"), "home page lost its Minimal Mistakes hero"
  end

  def test_existing_pages_still_build
    %w[/about /getstarted /learn /faq /imprint /contact].each { |url| page(url) }
  end

  def test_aim42_css_is_generated_with_modern_color_functions
    css = File.read(File.join(SITE_DIR, "assets/css/aim42.css"))
    assert_includes css, "--phase-analyze:", "palette tokens missing from aim42.css"
    assert_includes css, "color-mix(", "libsass must pass color-mix() through unchanged"
  end

  def test_glossary_uses_the_aim42_layout
    doc = page("/glossary/")
    assert_equal "Glossary", doc.at_css("h1.section-hero__title")&.text&.strip
    assert doc.at_css("header.site-header nav.site-primary-nav a[href='/patterns/']"), "primary nav missing"
    assert doc.at_css("footer.site-footer"), "aim42 footer missing"
    assert doc.at_css("h3#system"), "glossary anchor #system missing"
    assert doc.at_css("link[href='/assets/css/aim42.css']"), "aim42 stylesheet not linked"
  end
end
