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

  def test_pattern_page_renders_title_intent_and_phase
    doc = page("/patterns/stakeholder-interview/")
    assert_equal "Stakeholder Interview", doc.at_css("h1.section-hero__title")&.text&.strip
    assert_equal "analyze", doc.at_css("header.section-hero")["data-section"]
    assert_equal "/patterns/analyze/", doc.at_css(".section-hero__eyebrow a")["href"]
    assert_includes doc.at_css(".pattern-meta p").text, "Learn from the people"
    assert doc.at_css(".post-content h2"), "body headings missing"
    refute doc.at_css(".stub-notice"), "complete pattern must not show the stub notice"
    edit = doc.at_css("a.pattern-edit__link")
    assert_equal "https://github.com/aim42/aim42.org-site/edit/master/_patterns/stakeholder-interview.md", edit["href"]
  end

  def test_related_patterns_render_in_both_directions
    interview = page("/patterns/stakeholder-interview/")
    assert interview.at_css(".pattern-related a[href='/patterns/stakeholder-analysis/']"), "forward relation missing"
    analysis = page("/patterns/stakeholder-analysis/")
    assert analysis.at_css(".pattern-related a[href='/patterns/stakeholder-interview/']"), "reverse relation missing"
  end

  def test_stub_pattern_shows_contribution_notice
    doc = page("/patterns/assertions/")
    notice = doc.at_css(".stub-notice")
    assert notice, "stub notice missing"
    assert_includes notice.text, "stub"
    assert notice.at_css("a[href*='/edit/master/_patterns/assertions.md']"), "edit link missing from stub notice"
    assert doc.at_css(".section-hero__chips .tag--stub"), "stub chip missing"
  end

  def test_pattern_with_categories_renders_at_flat_url
    doc = page("/patterns/assertions/")
    assert_equal "improve", doc.at_css("header.section-hero")["data-section"]
    refute site_file("/architecture-and-code/assertions/"), "categories must not change the pattern URL"
  end

  PILOT_PATTERNS = %w[stakeholder-interview stakeholder-analysis atam strangler-approach assertions improvement-backlog].freeze

  def test_all_pilot_patterns_are_generated
    PILOT_PATTERNS.each { |slug| page("/patterns/#{slug}/") }
  end

  def test_pattern_images_exist
    PILOT_PATTERNS.each do |slug|
      page("/patterns/#{slug}/").css(".post-content img").each do |img|
        src = img["src"]
        assert File.file?(File.join(SITE_DIR, src)), "#{slug}: image #{src} missing from _site/"
      end
    end
  end

  def test_pattern_links_to_glossary_and_patterns_resolve
    PILOT_PATTERNS.each do |slug|
      page("/patterns/#{slug}/").css(".post-content a[href^='/']").each do |a|
        href = a["href"]
        next unless href.start_with?("/glossary", "/patterns/")
        assert site_file(href), "#{slug}: dead internal link #{href}"
        if href.include?("#")
          anchor = href.split("#").last
          assert page(href.split("#").first).at_css("##{anchor}"), "#{slug}: anchor ##{anchor} missing in #{href}"
        end
      end
    end
  end

  def test_index_lists_every_pattern_with_phase_cards
    doc = page("/patterns/")
    titles = doc.css(".pattern-list__title a").map { |a| a.text.strip }
    assert_equal ["Assertions", "ATAM", "Improvement Backlog", "Stakeholder Analysis", "Stakeholder Interview", "Strangler Approach"], titles
    assert_equal 4, doc.css(".phase-card").size
    assert doc.at_css(".phase-card[data-phase='analyze'] a[href='/patterns/analyze/']")
    stub_item = doc.css(".pattern-list__item").find { |li| li.text.include?("Assertions") }
    assert stub_item.at_css(".tag--stub"), "stub badge missing on the index"
  end

  def test_phase_page_lists_only_its_patterns
    doc = page("/patterns/analyze/")
    assert_equal "analyze", doc.at_css("header.section-hero")["data-section"]
    titles = doc.css(".pattern-list__title a").map { |a| a.text.strip }
    assert_equal ["ATAM", "Stakeholder Analysis", "Stakeholder Interview"], titles
    assert doc.at_css(".post-content h2"), "phase prose (Goals / How it works) missing"
  end

  def test_every_phase_page_exists
    %w[analyze evaluate improve crosscutting].each do |phase|
      doc = page("/patterns/#{phase}/")
      assert_equal phase, doc.at_css("header.section-hero")["data-section"]
    end
  end

  def test_internal_links_on_new_pages_resolve
    urls = ["/patterns/", "/glossary/"] + %w[analyze evaluate improve crosscutting].map { |p| "/patterns/#{p}/" } + PILOT_PATTERNS.map { |s| "/patterns/#{s}/" }
    urls.each do |url|
      page(url).css("a[href^='/']").each do |a|
        href = a["href"]
        next if href.start_with?("/images/") || href.start_with?("/assets/")
        assert site_file(href), "#{url}: dead internal link #{href}"
      end
    end
  end
end
