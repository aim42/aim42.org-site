require "minitest/autorun"
require "yaml"
require_relative "../tools/migrate/source"
require_relative "../tools/migrate/anchors"

class MigrateSourceTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  ASCIIDOC = File.join(ROOT, "_import", "src", "main", "asciidoc")
  MANIFEST = YAML.safe_load(File.read(File.join(ROOT, "tools", "migrate", "manifest.yml")))

  def source(skip: [])
    Aim42::Migrate::Source.new(ASCIIDOC, skip: skip)
  end

  def test_expand_inlines_includes_but_drops_skipped_files
    text = source(skip: ["patterns/analyze/atam.adoc"]).expand("analyze.adoc")
    refute_includes text, "[[ATAM]]"
    assert_includes text, "[[Stakeholder-Interview]]"
    refute_match(/^include::/, text)
  end

  def test_section_runs_from_the_anchor_to_the_next_sibling_heading
    text = source.section(source.expand("crosscutting.adoc"), "Fail-Fast")
    assert text.start_with?("[[Fail-Fast]]\n=== [pattern]#Fail Fast#")
    assert_includes text, "==== Takeaways"
    refute_includes text, "Fast-Feedback"
  end

  def test_section_raises_for_an_unknown_anchor
    assert_raises(ArgumentError) { source.section("text\n", "Nope") }
  end

  def test_cut_removes_sections
    text = source.cut(source.expand("crosscutting.adoc"), %w[Fail-Fast Fast-Feedback])
    refute_includes text, "[[Fail-Fast]]"
    refute_includes text, "[[Fast-Feedback]]"
    assert_includes text, "[[Impact-Analysis]]"
  end

  def test_index_entry_reads_both_entry_forms
    assert source.index_entry("Bulkhead").start_with?("Can be placed between two systems")
    assert source.index_entry("Deprecate-Obsolete-Parts").start_with?("Actively mark parts")
    assert source.index_entry("Quality-Driven-Software-Architecture").start_with?("Derive (technical")
    assert source.index_entry("ATAM").start_with?("Systematic approach")
    refute_includes source.index_entry("ATAM"), "Category"
    assert_nil source.index_entry("No-Such-Pattern")
  end

  def test_anchors_in_finds_block_inline_and_bibliography_anchors
    assert_equal %w[a b c], source.anchors_in("[[a]] text [[[b]]] and [[c,label]]")
  end

  def test_lookup_is_exact_then_case_insensitive_then_with_hyphens
    table = Aim42::Migrate::Anchors.new
    table.add("Domain-Model", "/reference/domain-model/")
    assert_equal "/reference/domain-model/", table.lookup("Domain-Model").url
    assert_equal "/reference/domain-model/", table.lookup("domain-model").url
    assert_equal "/reference/domain-model/", table.lookup("Domain Model").url
    assert_nil table.lookup("Domain")
  end

  def test_first_registration_wins_and_conflicts_are_recorded
    table = Aim42::Migrate::Anchors.new
    table.add("X", "/a/")
    table.add("X", "/a/")
    table.add("X", "/b/")
    assert_equal "/a/", table.lookup("X").url
    assert_equal ["X"], table.duplicates
  end

  def test_the_manifest_table_resolves_every_kind_of_anchor
    files = MANIFEST["patterns"].map { |p| p["source"] }.reject { |s| s.include?("#") }
    table = Aim42::Migrate::Anchors.build(MANIFEST, source(skip: files))
    assert_equal "/patterns/atam/", table.lookup("ATAM").url
    assert_equal "ATAM", table.lookup("ATAM").link_text
    assert_equal "/patterns/fail-fast/", table.lookup("Fail-Fast").url
    assert_equal "/patterns/bulkhead/", table.lookup("Bulkhead").url
    assert_equal "/patterns/atam/#figure-atam-approach", table.lookup("figure-atam-approach").url
    assert_equal "/patterns/improve/", table.lookup("Improve").url
    assert_equal "/patterns/improve/#improve-processes", table.lookup("improve-processes").url
    assert_equal "/reference/bibliography/#nygard07", table.lookup("Nygard07").url
    assert_equal "/glossary/#system", table.lookup("System").url
    assert_equal "/reference/domain-model/", table.lookup("Domain Model").url
    assert_empty table.duplicates
  end

  def test_index_entry_strips_a_mid_line_category_label
    refute_includes source.index_entry("Report-Structure"), "Category"
    toggle = source.index_entry("Toggle-Feature")
    refute_includes toggle, "Category"
    assert toggle.end_with?("feature flags."), toggle
  end
end
