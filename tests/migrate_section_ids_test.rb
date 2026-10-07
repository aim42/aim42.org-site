require "minitest/autorun"
require "yaml"
require_relative "../tools/migrate/source"
require_relative "../tools/migrate/anchors"
require_relative "../tools/migrate/section_ids"

# The old book (aim42.github.io) gave every section without [[Anchor]] an
# Asciidoctor id such as #_description_7; these tests pin where they now go.
class MigrateSectionIdsTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  ASCIIDOC = File.join(ROOT, "_import", "src", "main", "asciidoc")
  MANIFEST = YAML.safe_load(File.read(File.join(ROOT, "tools", "migrate", "manifest.yml")))

  # Loading the whole book takes a few seconds: once for all tests.
  def self.result
    @result ||= begin
      files = MANIFEST["patterns"].map { |p| p["source"] }.reject { |s| s.include?("#") }
      anchors = Aim42::Migrate::Anchors.build(MANIFEST, Aim42::Migrate::Source.new(ASCIIDOC, skip: files))
      Aim42::Migrate::SectionIds.build(ASCIIDOC, MANIFEST, anchors, ROOT)
    end
  end

  def map
    self.class.result.map
  end

  def test_a_pattern_section_maps_to_the_pattern_and_its_heading
    # Documentation-Analysis is the 7th section titled "Description" in the book.
    assert_equal "/patterns/documentation-analysis/#description", map["_description_7"]
    assert_equal "/patterns/atam/#description", map["_description"]
  end

  def test_an_introduction_section_maps_to_the_introduction_page
    assert_equal "/reference/introduction/#why-is-software-being-changed", map["_why_is_software_being_changed"]
    # aim42-overview.adoc is included by aim42_introduction.adoc
    assert_equal "/reference/introduction/#overview", map["_overview"]
    assert_equal "/reference/introduction/", map["_introduction"]
  end

  def test_a_section_inside_a_pattern_section_of_a_page_file_maps_to_that_pattern
    # crosscutting.adoc holds Fail-Fast inline; its "Takeaways" belongs to the pattern.
    assert_equal "/patterns/fail-fast/#takeaways", map["_takeaways"]
    assert_equal "/patterns/crosscutting/#how-it-works", map["_how_it_works_2"]
  end

  def test_a_duplicate_title_keeps_its_suffix_and_finds_its_pattern
    # Butterfly-Methodology has no [[Anchor]]; its "Risks" is the book's third.
    assert_equal "/patterns/butterfly-methodology/#risks", map["_risks_3"]
  end

  # The old site was built with Asciidoctor 1.5.x: markup and entities in a
  # title became separators (ids checked against aim42.github.io).
  def test_ids_keep_the_quirks_of_the_old_asciidoctor
    assert_equal "/patterns/butterfly-methodology/", map["_span_class_pattern_butterfly_methodology_span"]
    refute map.key?("_butterfly_methodology")
    assert_equal "/patterns/organizational-analysis/#conways-law-and-what-to-do-about-it",
                 map["_conway_s_law_and_what_to_do_about_it"]
    assert_equal "/patterns/change-by-abstraction-refactoring/#related-patternsnames", map["_related_patterns_names"]
    assert_equal "/patterns/strangler-approach/#risks", map["_risks_5"]
  end

  def test_a_section_without_that_heading_on_its_page_maps_to_the_page
    assert_equal "/patterns/atam/", map["_intent"]
    assert_equal "/glossary/", map["_glossary"]
    assert self.class.result.notes.any? { |n| n.include?("_intent") }
  end

  # "===== References" is the last line (no newline) of these two pattern files;
  # Asciidoctor then reports the next included file as its source.
  def test_a_heading_on_the_last_line_of_a_file_stays_with_its_pattern
    assert_equal "/patterns/interface-segregation-principle/", map["_references_22"]
    assert_equal "/patterns/manage-complex-client-dependencies-with-facade/", map["_references_24"]
  end

  # Spec §6: the chapter was rewritten for the Markdown workflow (ruling R37).
  def test_the_how_to_chapter_maps_to_the_rewritten_page
    assert_equal "/reference/how-to-add-a-pattern/", map["_how_to_add_a_new_pattern_or_practice"]
  end

  def test_sections_of_dropped_chapters_are_left_out
    %w[_about_aim42 _about_this_documentation _organizational_stuff _license
       _pattern_index].each do |id|
      refute map.key?(id), "#{id} should be left out"
      assert self.class.result.left_out.any? { |left, _| left == id }, "#{id} not reported"
    end
  end

  def test_explicit_anchors_are_not_section_ids
    assert map.keys.all? { |id| id.start_with?("_") }
    refute map.key?("Iterative-Approach")
  end

  def test_every_url_points_at_an_existing_target_file
    pages = Dir[File.join(ROOT, "_pages", "**", "*.md")].to_h do |f|
      [File.read(f)[/^permalink:\s*(\S+)/, 1], f]
    end
    refute_empty map
    map.each do |id, url|
      page, fragment = url.split("#", 2)
      file = page[%r{\A/patterns/([a-z0-9-]+)/\z}, 1].then { |slug| slug && File.join(ROOT, "_patterns", "#{slug}.md") }
      file = pages[page] unless file && File.file?(file)
      assert file && File.file?(file), "#{id}: no file for #{page}"
      next unless fragment
      text = File.read(file)
      assert(text.match?(/\{##{Regexp.escape(fragment)}\}/) || text.lines.any? { |l| l.start_with?("#") && Aim42::Migrate::AdocToMd.heading_id(l.sub(/\A#+\s*/, "").strip) == fragment },
             "#{id}: heading ##{fragment} missing in #{file}")
    end
  end
end
