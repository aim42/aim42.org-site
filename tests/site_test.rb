# Checks on the generated site. Run after `bundle exec jekyll build`.
require "minitest/autorun"
require "nokogiri"
require "yaml"
require "kramdown"
require "kramdown-parser-gfm"
require_relative "../tools/validate"

ROOT = File.expand_path("..", __dir__)
SITE_DIR = File.join(ROOT, "_site")

class SiteTest < Minitest::Test
  # The expected pattern set comes from the sources, so new patterns are covered.
  VALIDATOR = Aim42::Validator.new(ROOT)
  PATTERNS = VALIDATOR.files.map { |f| VALIDATOR.front_matter(f).merge("slug" => VALIDATOR.slug(f)) }.freeze
  PHASES = YAML.safe_load(File.read(File.join(ROOT, "_data", "phases.yml"))).keys.freeze
  CATEGORIES = YAML.safe_load(File.read(File.join(ROOT, "_data", "categories.yml"))).freeze
  # Every page under _pages/reference/ (glossary, introduction, bibliography, …).
  REFERENCE = Dir[File.join(ROOT, "_pages", "reference", "*.md")].sort.filter_map { |f| VALIDATOR.front_matter(f)&.fetch("permalink", nil) }.freeze
  PAGES = (["/patterns/"] + REFERENCE + PHASES.map { |p| "/patterns/#{p}/" } + PATTERNS.map { |p| "/patterns/#{p["slug"]}/" }).uniq.freeze

  # Titles in Liquid's sort_natural order (case-insensitive).
  def sorted_titles(patterns)
    patterns.map { |p| p["title"] }.sort { |a, b| a.casecmp(b) }
  end

  # The intent as plain text: inline Markdown rendered like the site's
  # kramdown settings (_config.yml), tags stripped, newlines removed.
  def plain(markdown)
    html = Kramdown::Document.new(markdown, input: "GFM", hard_wrap: false, smart_quotes: %w[lsquo rsquo ldquo rdquo]).to_html
    Nokogiri::HTML.fragment(html).text.delete("\r\n").strip
  end

  def by_title(title)
    PATTERNS.find { |p| p["title"] == title } || flunk("unknown pattern title #{title.inspect}")
  end

  def stub?(title)
    PATTERNS.any? { |p| p["title"] == title && p["status"] == "stub" }
  end

  def assert_pattern_list(doc, patterns, url)
    items = doc.css(".pattern-list__item")
    assert_equal sorted_titles(patterns), items.map { |li| li.at_css(".pattern-list__title a").text.strip }, "#{url}: pattern list"
    items.each do |li|
      title = li.at_css(".pattern-list__title a").text.strip
      assert_equal stub?(title), !li.at_css(".tag--stub").nil?, "#{url}: stub badge wrong for #{title}"
      assert_equal plain(by_title(title)["intent"]), li.at_css(".pattern-list__intent").text.strip, "#{url}: intent of #{title}"
    end
  end
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
    assert doc.at_css("dl.glossary dt#system"), "glossary term #system missing"
    assert_equal YAML.safe_load(File.read(File.join(ROOT, "_data", "glossary.yml"))).size, doc.css("dl.glossary dt").size
    assert doc.at_css("link[href='/assets/css/aim42.css']"), "aim42 stylesheet not linked"
  end

  # aria-expanded carries the open/closed state; the label must not contradict it.
  def test_menu_toggle_label_is_state_neutral
    toggle = page("/glossary/").at_css("button.site-menu-toggle")
    assert_equal "false", toggle["aria-expanded"]
    assert_equal "Navigation menu", toggle["aria-label"]
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

  def test_stub_without_body_renders_no_empty_section
    refute page("/patterns/assertions/").at_css("section.post-content"), "empty body section on a stub"
  end

  def test_pattern_with_categories_renders_at_flat_url
    doc = page("/patterns/assertions/")
    assert_equal "improve", doc.at_css("header.section-hero")["data-section"]
    refute site_file("/architecture-and-code/assertions/"), "categories must not change the pattern URL"
  end

  def test_pattern_sources_are_found
    refute_empty PATTERNS
  end

  def test_every_pattern_is_generated
    PATTERNS.each { |p| page("/patterns/#{p["slug"]}/") }
  end

  def test_images_exist_on_new_pages
    PAGES.each do |url|
      page(url).css("img[src^='/']").each do |img|
        assert File.file?(File.join(SITE_DIR, img["src"])), "#{url}: image #{img["src"]} missing from _site/"
      end
    end
  end

  def test_internal_links_and_anchors_on_new_pages_resolve
    PAGES.each do |url|
      doc = page(url)
      doc.css("a[href^='/'], a[href^='#']").each do |a|
        href = a["href"]
        target, anchor = href.split("#", 2)
        target_doc = if target.empty?
                       doc
                     else
                       assert site_file(target), "#{url}: dead internal link #{href}"
                       next unless anchor
                       page(target)
                     end
        next if anchor.nil? || anchor.empty?
        assert target_doc.css("[id]").any? { |e| e["id"] == anchor }, "#{url}: anchor ##{anchor} missing in #{href}"
      end
    end
  end

  def test_index_lists_every_pattern_with_phase_cards
    doc = page("/patterns/")
    assert_pattern_list(doc, PATTERNS, "/patterns/")
    assert_equal PHASES.size, doc.css(".phase-card").size
    PHASES.each do |phase|
      card = doc.at_css(".phase-card[data-phase='#{phase}']")
      assert card.at_css("a[href='/patterns/#{phase}/']"), "#{phase} card link missing"
      assert_equal PATTERNS.count { |p| p["phase"] == phase }, card.at_css("b").text.to_i, "#{phase} card count"
    end
  end

  def test_phase_pages_list_only_their_patterns
    PHASES.each do |phase|
      doc = page("/patterns/#{phase}/")
      assert_equal phase, doc.at_css("header.section-hero")["data-section"]
      next if phase == "improve" # grouped by category, see below
      mine = PATTERNS.select { |p| p["phase"] == phase }
      if mine.empty?
        assert_includes doc.at_css(".post-content").text, "No patterns in this phase yet."
      else
        assert_pattern_list(doc, mine, "/patterns/#{phase}/")
      end
    end
    assert page("/patterns/analyze/").at_css(".post-content h2"), "phase prose (Goals / How it works) missing"
  end

  def test_improve_page_groups_patterns_by_category
    doc = page("/patterns/improve/")
    improve = PATTERNS.select { |p| p["phase"] == "improve" }
    CATEGORIES.each_key do |key|
      group = doc.at_css(".pattern-group[data-category='#{key}']")
      assert group, "/patterns/improve/: group #{key} missing"
      mine = improve.select { |p| Array(p["categories"]).include?(key) }
      if mine.empty?
        assert_includes group.text, "No patterns in this category yet."
      else
        assert_pattern_list(group, mine, "/patterns/improve/ #{key}")
      end
    end
    other = doc.at_css(".pattern-group[data-category='other']")
    assert other, "/patterns/improve/: group other missing"
    assert_pattern_list(other, improve.select { |p| Array(p["categories"]).empty? }, "/patterns/improve/ other")
  end

  def test_category_chips_show_category_titles
    chips = page("/patterns/assertions/").css(".section-hero__chips .tag").map { |t| t.text.strip }
    assert_includes chips, CATEGORIES["architecture-and-code"]["title"]
  end

  def test_meta_description_is_the_plain_text_intent
    PATTERNS.each do |p|
      metas = page("/patterns/#{p["slug"]}/").css("meta[name='description']")
      assert_equal 1, metas.size, "#{p["slug"]}: expected one meta description"
      expected = plain(p["intent"])
      content = metas.first["content"]
      if expected.length > 160
        assert content.end_with?("...") && expected.start_with?(content.chomp("...")), "#{p["slug"]}: truncated meta description #{content.inspect}"
      else
        assert_equal expected, content, "#{p["slug"]}: meta description"
      end
    end
  end

  def test_pattern_titles_and_intents_render_as_text
    PATTERNS.each do |p|
      doc = page("/patterns/#{p["slug"]}/")
      assert_equal "#{p["title"]} | aim42", doc.at_css("title").text, "#{p["slug"]}: <title>"
      assert_equal p["title"], doc.at_css("h1.section-hero__title").text.strip, "#{p["slug"]}: h1"
      assert_equal plain(p["intent"]), doc.at_css(".pattern-meta p").text.strip, "#{p["slug"]}: intent"
      doc.css(".pattern-related li").each do |li|
        other = by_title(li.at_css("a").text.strip)
        assert_equal plain(other["intent"]), li.at_css(".pattern-list__intent").text.strip, "#{p["slug"]}: related intent"
      end
    end
  end

  # Every anchor of the old AsciiDoc reference has a working new home (spec §9),
  # so the phase-3 redirector can send aim42.github.io/#Anchor there.
  def test_every_old_anchor_resolves
    anchors = YAML.safe_load(File.read(File.join(ROOT, "_data", "anchors.yml")))
    docs = {}
    anchors.each do |old, url|
      target, fragment = url.split("#", 2)
      assert site_file(target), "anchor #{old}: #{target} is not generated"
      next unless fragment
      doc = (docs[target] ||= page(target))
      assert doc.css("[id]").any? { |e| e["id"] == fragment }, "anchor #{old}: ##{fragment} missing on #{target}"
    end
  end
end
