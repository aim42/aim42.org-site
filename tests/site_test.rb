# Checks on the generated site. Run after `bundle exec jekyll build`.
require "minitest/autorun"
require "nokogiri"
require "yaml"
require "json"
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
  PHASE_DATA = YAML.safe_load(File.read(File.join(ROOT, "_data", "phases.yml"))).freeze
  HOME = VALIDATOR.front_matter(File.join(ROOT, "_pages", "home.md")).freeze
  NAV = YAML.safe_load(File.read(File.join(ROOT, "_data", "navigation.yml"))).freeze
  BAR = ["Get started", "Patterns", "Learn", "About"].freeze
  MIGRATED = %w[/principles /using /examples /publications /training /faq /contact /contribute /license /imprint/].freeze
  CATEGORIES = YAML.safe_load(File.read(File.join(ROOT, "_data", "categories.yml"))).freeze
  # Every page under _pages/reference/ (glossary, introduction, bibliography, …).
  REFERENCE = Dir[File.join(ROOT, "_pages", "reference", "*.md")].sort.filter_map { |f| VALIDATOR.front_matter(f)&.fetch("permalink", nil) }.freeze
  # Every built page; the link and image checks run over all of them.
  PAGES = Dir[File.join(SITE_DIR, "**", "*.html")].map { |f| "/" + f.delete_prefix("#{SITE_DIR}/").sub(%r{(\A|/)index\.html\z}, "\\1") }.sort.freeze

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

  def pattern_title(slug)
    PATTERNS.find { |p| p["slug"] == slug }&.fetch("title") || flunk("unknown pattern slug #{slug.inspect}")
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

  def test_home_page_uses_the_aim42_layout
    doc = page("/")
    assert_nil doc.at_css(".page__hero, .page__hero--overlay, .feature__wrapper, .masthead"), "old theme markup on /"
    assert doc.at_css("header.site-header"), "aim42 header missing on /"
    assert_equal [HOME["headline"]], doc.css("h1").map { |h| h.text.strip }
    assert_equal ["How it works", "Get started", "Free and open"], doc.css("main h2").map { |h| h.text.strip }
    assert_equal "Architecture Improvement Method | aim42", doc.at_css("title").text.strip
    assert_equal plain(HOME["lede"]), doc.at_css("meta[name='description']")["content"]
    assert_equal plain(HOME["lede"]), doc.at_css(".home-hero__lede").text.strip
  end

  def test_home_buttons_lead_to_phases_and_patterns
    doc = page("/")
    buttons = doc.css(".home-hero__actions a")
    assert_equal ["#how-it-works", "/patterns/"], buttons.map { |a| a["href"] }
    assert_equal ["How it works", "Browse #{PATTERNS.size} patterns"], buttons.map { |a| a.text.strip }
    assert doc.at_css("h2#how-it-works"), "How it works heading missing"
  end

  def test_home_cycle_links_to_the_four_phases
    nav = page("/").at_css(".home-hero nav.home-cycle[aria-label='aim42 phases']")
    assert nav, "cycle navigation missing from the hero"
    links = nav.css("a")
    assert_equal PHASES.map { |k| PHASE_DATA[k]["url"] }, links.map { |a| a["href"] }
    assert_equal PHASES.map { |k| "#{PHASE_DATA[k]["title"]}: #{HOME["cycle"][k]}" }, links.map { |a| a["aria-label"] }
    assert_equal PHASES.map { |k| PHASE_DATA[k]["title"] }, links.map { |a| a.at_css(".home-cycle__name").text.strip }
    links.each do |a|
      assert a.css("path, circle, text").all? { |e| e["aria-hidden"] == "true" }, "#{a["href"]}: shapes and labels must be aria-hidden"
    end
  end

  def test_home_phase_cards_show_blurb_count_and_examples
    cards = page("/").css(".home-phase-list .phase-card")
    assert_equal PHASES, cards.map { |c| c["data-phase"] }
    cards.each do |card|
      key = card["data-phase"]
      phase = PHASE_DATA[key]
      count = PATTERNS.count { |p| p["phase"] == key }
      assert_equal phase["title"], card.at_css("h3 a").text.strip
      assert_equal phase["url"], card.at_css("h3 a")["href"]
      assert_equal phase["blurb"], card.at_css(".home-phase__blurb").text.strip
      examples = card.css(".home-examples a")
      assert_equal HOME["examples"][key].map { |s| "/patterns/#{s}/" }, examples.map { |a| a["href"] }
      assert_equal HOME["examples"][key].map { |s| pattern_title(s) }, examples.map { |a| a.text.strip }
      assert_equal "All #{count} #{phase["title"].downcase} patterns", card.at_css(".home-phase__all a").text.strip
    end
  end

  def test_home_get_started_and_contribution_links
    doc = page("/")
    steps = doc.css(".home-steps__item")
    assert_equal HOME["get_started"].map { |s| s["text"] }, steps.map { |li| li.at_css(".home-steps__text").text.strip }
    HOME["get_started"].zip(steps).each do |step, li|
      assert_equal step["patterns"].map { |s| "/patterns/#{s}/" }, li.css(".home-steps__links a").map { |a| a["href"] }
    end
    assert doc.at_css(".home-start a[href='/getstarted']"), "link to the getting-started guide missing"
    assert doc.at_css(".home-open a[href='/reference/how-to-add-a-pattern/']"), "Add a pattern link missing"
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

  def test_navigation_urls_resolve
    NAV["sections"].each do |key, section|
      ([section["url"]] + section["pages"].map { |p| p["url"] }).each do |url|
        assert site_file(url), "navigation #{key}: #{url} is not built"
      end
    end
  end

  def test_navigation_lists_each_url_once
    urls = NAV["sections"].values.flat_map { |s| [s["url"]] + s["pages"].map { |p| p["url"] } }
    assert_equal urls.uniq, urls
  end

  def test_header_bar_lists_the_sections_and_marks_the_current_one
    {
      "/patterns/atam/" => ["Patterns", "true"],
      "/patterns/" => ["Patterns", "page"],
      "/glossary/" => ["Patterns", "true"],
      "/reference/team/" => ["About", "true"],
      "/contact" => ["About", "true"],
      "/about" => ["About", "page"],
      "/getstarted" => ["Get started", "page"]
    }.each do |url, expected|
      links = page(url).css("nav.site-primary-nav a")
      assert_equal BAR, links.map { |a| a.text.strip }, "#{url}: bar"
      assert_equal [expected], links.select { |a| a["aria-current"] }.map { |a| [a.text.strip, a["aria-current"]] }, "#{url}: current section"
    end
  end

  def test_menu_groups_every_section_with_its_pages
    groups = page("/glossary/").css("#site-secondary-nav .site-secondary-nav__group")
    assert_equal NAV["bar"], groups.map { |g| g["data-section"] }
    groups.each do |group|
      section = NAV["sections"][group["data-section"]]
      label = group.at_css("a.site-secondary-nav__label")
      assert_equal [section["title"], section["url"]], [label.text.strip, label["href"]]
      assert_equal section["pages"].map { |p| [p["title"], p["url"]] },
                   group.css("a:not(.site-secondary-nav__label)").map { |a| [a.text.strip, a["href"]] }
    end
  end

  def test_header_shows_the_svg_logo
    logo = page("/glossary/").at_css(".site-brand img")
    assert_equal ["/images/logo/AIM42_white.svg", "aim42"], [logo["src"], logo["alt"]]
  end

  def test_section_pages_show_a_card_per_page
    %w[getstarted learn about].each do |key|
      section = NAV["sections"][key]
      doc = page(section["url"])
      assert_equal section["title"], doc.at_css("h1.section-hero__title").text.strip, "#{key}: title"
      assert_equal section["lede"], doc.at_css(".section-hero__lede").text.strip, "#{key}: lede"
      cards = doc.css(".section-cards .phase-card")
      assert_equal section["pages"].map { |p| [p["title"], p["url"], p["blurb"]] },
                   cards.map { |c| [c.at_css("h3 a").text.strip, c.at_css("h3 a")["href"], c.at_css("p").text.strip] }, "#{key}: cards"
      assert_equal 1, doc.css("h1").size, "#{key}: exactly one h1"
    end
  end

  def test_pages_show_their_section_as_eyebrow
    {
      "/reference/team/" => ["About", "/about"],
      "/glossary/" => ["Patterns", "/patterns/"],
      "/patterns/analyze/" => ["Phase", "/patterns/"]
    }.each do |url, expected|
      link = page(url).at_css(".section-hero__eyebrow a")
      assert_equal expected, [link&.text&.strip, link&.[]("href")], "#{url}: eyebrow"
    end
  end

  OLD_THEME_MARKUP = ".page__hero, .page__hero--overlay, .masthead, .sidebar, .page__content, .feature__wrapper, .greedy-nav, i.fa, i.fab".freeze

  def test_migrated_pages_use_the_aim42_layout
    MIGRATED.each do |url|
      doc = page(url)
      assert doc.at_css("header.site-header"), "#{url}: aim42 header missing"
      assert_equal 1, doc.css("h1").size, "#{url}: exactly one h1"
      assert doc.at_css(".section-hero__eyebrow a"), "#{url}: section eyebrow missing"
      assert_nil doc.at_css(OLD_THEME_MARKUP), "#{url}: old theme markup"
    end
  end

  def test_not_found_page_uses_the_aim42_layout
    doc = page("/404.html")
    assert doc.at_css("header.site-header"), "404: aim42 header missing"
    assert_equal 1, doc.css("h1").size
    assert_nil doc.at_css(OLD_THEME_MARKUP)
  end

  def test_contact_lists_email_github_and_linkedin
    hrefs = page("/contact").css(".post-content a").map { |a| a["href"] }
    assert_includes hrefs, "https://www.linkedin.com/in/gernotstarke/"
    assert_includes hrefs, "https://github.com/aim42"
    assert hrefs.any? { |h| h.start_with?("xmxaxixlxtxo:") }, "obfuscated email link missing"
  end

  def test_no_page_links_to_twitter_or_xing
    Dir[File.join(SITE_DIR, "**", "*.html")].each do |file|
      hrefs = Nokogiri::HTML(File.read(file)).css("a[href]").map { |a| a["href"] }
      bad = hrefs.grep(%r{\Ahttps?://(www\.)?(twitter\.com|x\.com|xing\.com)/})
      assert_empty bad, "#{file.delete_prefix(SITE_DIR)} links to #{bad.join(", ")}"
    end
  end

  def test_every_page_is_in_the_navigation
    listed = NAV["sections"].values.flat_map { |s| [s["url"]] + s["pages"].map { |p| p["url"] } }
    Dir[File.join(ROOT, "_pages", "**", "*.md")].sort.each do |file|
      next if file.include?("/_pages/patterns/") || %w[home.md search.md].include?(File.basename(file))
      url = VALIDATOR.front_matter(file)["permalink"]
      assert_includes listed, url, "#{file.delete_prefix(ROOT)} (#{url}) is not in _data/navigation.yml"
    end
  end

  # Spec §5: nothing outside docs/superpowers/ mentions the old theme.
  OLD_THEME = /minimal[-_ ]?mistakes|mmistakes|mademistakes/i

  def test_old_theme_is_not_mentioned_in_the_repository
    skip_dirs = %w[.git .jekyll-cache .sass-cache .superpowers .bundle .idea _site vendor node_modules docs/superpowers]
    files = Dir.glob("**/*", File::FNM_DOTMATCH, base: ROOT).reject do |f|
      skip_dirs.any? { |d| f == d || f.start_with?("#{d}/") } ||
        f.split("/").include?("node_modules") || # tests/e2e/node_modules (search plan)
        File.directory?(File.join(ROOT, f))
    end
    hits = (files - ["tests/site_test.rb"]).select { |f| File.binread(File.join(ROOT, f)).match?(OLD_THEME) }
    assert_empty hits, "files mentioning the old theme"
  end

  def test_no_built_page_has_old_theme_markup
    PAGES.each do |url|
      doc = page(url)
      assert_nil doc.at_css(OLD_THEME_MARKUP), "#{url}: old theme markup"
      assert doc.at_css("header.site-header"), "#{url}: aim42 header missing"
    end
  end

  def test_search_documents_cover_patterns_pages_and_terms_once
    docs = JSON.parse(File.read(File.join(SITE_DIR, "assets", "search.json")))
    urls = docs.map { |d| d["url"] }
    assert_equal urls.uniq, urls, "duplicate search documents"
    PATTERNS.each { |p| assert_includes urls, "/patterns/#{p["slug"]}/" }
    NAV["sections"].values.flat_map { |s| [s["url"]] + s["pages"].map { |p| p["url"] } }
                   .reject { |u| u.end_with?(".pdf") }
                   .each { |u| assert_includes urls, u }
    YAML.safe_load(File.read(File.join(ROOT, "_data", "glossary.yml"))).each { |t| assert_includes urls, "/glossary/##{t["id"]}" }
    docs.each do |d|
      assert_equal %w[body context kind label title url], d.keys.sort, "#{d["url"]}: keys"
      assert_includes %w[pattern page term], d["kind"], "#{d["url"]}: kind"
      refute d["title"].strip.empty?, "#{d["url"]}: title"
      refute d["label"].strip.empty?, "#{d["url"]}: label"
      assert site_file(d["url"]), "#{d["url"]}: not built"
    end
  end

  def test_search_document_of_a_pattern_has_phase_and_plain_intent
    doc = JSON.parse(File.read(File.join(SITE_DIR, "assets", "search.json"))).find { |d| d["url"] == "/patterns/atam/" }
    atam = PATTERNS.find { |p| p["slug"] == "atam" }
    assert_equal ["pattern", "ATAM", "Analyze", plain(atam["intent"])], doc.values_at("kind", "title", "label", "context")
    refute_match(/<[a-z]/, doc["body"], "body must be plain text")
  end

  def test_lunr_is_vendored_at_the_pinned_version
    head = File.read(File.join(SITE_DIR, "assets", "js", "vendor", "lunr-2.3.9.min.js"), 300)
    assert_includes head, "2.3.9"
  end

  def test_search_dialog_and_button_are_on_every_page
    PAGES.each do |url|
      doc = page(url)
      assert doc.at_css("dialog#search-dialog input#search-dialog-input[role='combobox'][aria-controls='search-dialog-results']"), "#{url}: search combobox missing"
      assert doc.at_css("dialog#search-dialog #search-dialog-results[role='listbox']"), "#{url}: result listbox missing"
      assert doc.at_css("label[for='search-dialog-input']"), "#{url}: search label missing"
      assert doc.at_css("header.site-header a.site-search-button[href='/search/'][data-search-open]"), "#{url}: header search button missing"
    end
  end

  def test_search_page_works_as_a_plain_form
    doc = page("/search/")
    assert doc.at_css("main form[action='/search/'][method='get'] input#search-page-input[name='q']"), "GET form with q missing"
    assert_match(/Search needs JavaScript/, doc.at_css("main noscript")&.text.to_s)
    assert doc.at_css("main noscript a[href='/patterns/']"), "no-JavaScript notice must link to the patterns index"
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
