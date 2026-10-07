require "minitest/autorun"
require "tmpdir"
require "fileutils"
require_relative "../tools/validate"

class ValidatorTest < Minitest::Test
  PHASES = "analyze:\n  title: Analyze\nimprove:\n  title: Improve\n"

  def setup
    @root = Dir.mktmpdir
    FileUtils.mkdir_p(File.join(@root, "_data"))
    FileUtils.mkdir_p(File.join(@root, "_patterns"))
    File.write(File.join(@root, "_data", "phases.yml"), PHASES)
  end

  def teardown
    FileUtils.rm_rf(@root)
  end

  def pattern(name, front_matter, body: "Body.\n")
    File.write(File.join(@root, "_patterns", "#{name}.md"), "---\n#{front_matter}---\n\n#{body}")
  end

  def errors
    Aim42::Validator.new(@root).run
  end

  VALID = "title: Stakeholder Interview\nphase: analyze\nintent: Learn.\nstatus: complete\n"

  def test_valid_patterns_have_no_errors
    pattern("stakeholder-interview", VALID + "related: [stakeholder-analysis]\n")
    pattern("stakeholder-analysis", "title: Stakeholder Analysis\nphase: analyze\nintent: Find.\nstatus: complete\n")
    assert_empty errors
  end

  def test_missing_required_key
    pattern("a", "title: A\nphase: analyze\nstatus: complete\n")
    assert_includes errors, "a.md: missing required key 'intent'"
  end

  def test_unknown_phase
    pattern("a", "title: A\nphase: evaluate\nintent: x\nstatus: complete\n")
    assert_includes errors, "a.md: unknown phase 'evaluate' (allowed: analyze, improve)"
  end

  def test_unknown_status
    pattern("a", "title: A\nphase: analyze\nintent: x\nstatus: draft\n")
    assert_includes errors, "a.md: unknown status 'draft' (allowed: complete, stub)"
  end

  def test_related_must_be_a_list
    pattern("a", VALID + "related: stakeholder-analysis\n")
    assert_includes errors, "a.md: 'related' must be a list of slugs"
  end

  def test_related_unknown_slug
    pattern("a", VALID + "related: [nope]\n")
    assert_includes errors, "a.md: related slug 'nope' does not exist in _patterns/"
  end

  def test_categories_must_be_a_list
    pattern("a", VALID + "categories: approaches\n")
    assert_includes errors, "a.md: 'categories' must be a list"
  end

  def test_filename_must_be_kebab_case
    pattern("Stakeholder_Interview", VALID)
    assert_includes errors, "Stakeholder_Interview.md: filename must be a kebab-case slug"
  end

  def test_slug_must_not_collide_with_phase_pages
    pattern("analyze", VALID)
    pattern("index", VALID)
    assert_includes errors, "analyze.md: slug 'analyze' is reserved for a phase page"
    assert_includes errors, "index.md: slug 'index' is reserved"
  end

  def test_duplicate_titles
    pattern("a", VALID)
    pattern("b", VALID)
    assert_includes errors, "duplicate title 'stakeholder interview' in a.md, b.md"
  end

  def test_missing_front_matter
    File.write(File.join(@root, "_patterns", "a.md"), "no front matter\n")
    assert_includes errors, "a.md: missing front matter"
  end

  def test_invalid_yaml
    pattern("a", "title: [unclosed\n")
    assert errors.any? { |e| e.start_with?("a.md: invalid YAML front matter") }, errors.inspect
  end

  def test_title_and_intent_must_be_strings
    pattern("a", "title: 2026\nphase: analyze\nintent: [one, two]\nstatus: complete\n")
    assert_includes errors, "a.md: 'title' must be a string"
    assert_includes errors, "a.md: 'intent' must be a string"
  end

  def test_intent_must_be_a_single_paragraph
    pattern("a", "title: A\nphase: analyze\nintent: |\n  First paragraph.\n\n  Second paragraph.\nstatus: complete\n")
    assert_includes errors, "a.md: 'intent' must be a single paragraph"
  end

  def test_front_matter_must_be_a_mapping
    pattern("a", "- title\n- phase\n")
    pattern("b", "just a string\n")
    assert_includes errors, "a.md: front matter must be a mapping"
    assert_includes errors, "b.md: front matter must be a mapping"
  end

  def test_unquoted_dates_are_allowed
    pattern("a", VALID + "updated: 2026-10-07\n")
    assert_empty errors
  end

  def test_yaml_aliases_are_reported_not_raised
    pattern("a", "title: &t A\nphase: analyze\nintent: *t\nstatus: complete\n")
    assert errors.any? { |e| e.start_with?("a.md: invalid YAML front matter") }, errors.inspect
  end

  def test_crlf_line_endings_validate
    File.write(File.join(@root, "_patterns", "a.md"), "---\n#{VALID}---\n\nBody.\n".gsub("\n", "\r\n"))
    assert_empty errors
  end

  def test_markdown_extensions_and_subdirectories_are_validated
    FileUtils.mkdir_p(File.join(@root, "_patterns", "improve"))
    File.write(File.join(@root, "_patterns", "b.markdown"), "---\ntitle: B\nphase: nope\nintent: x\nstatus: complete\n---\n")
    File.write(File.join(@root, "_patterns", "improve", "c.md"), "---\ntitle: C\nphase: analyze\nstatus: complete\n---\n")
    assert_includes errors, "b.markdown: unknown phase 'nope' (allowed: analyze, improve)"
    assert_includes errors, "improve/c.md: missing required key 'intent'"
  end

  def test_related_may_name_a_pattern_in_a_subdirectory
    FileUtils.mkdir_p(File.join(@root, "_patterns", "analyze-more"))
    File.write(File.join(@root, "_patterns", "analyze-more", "b.md"), "---\ntitle: B\nphase: analyze\nintent: x\nstatus: complete\n---\n")
    pattern("a", VALID + "related: [b]\n")
    assert_empty errors
  end

  def test_duplicate_slugs_across_extensions_and_directories
    FileUtils.mkdir_p(File.join(@root, "_patterns", "sub"))
    pattern("a", VALID)
    File.write(File.join(@root, "_patterns", "sub", "a.md"), "---\ntitle: Other\nphase: analyze\nintent: x\nstatus: complete\n---\n")
    assert_includes errors, "duplicate slug 'a' in a.md, sub/a.md"
  end

  # The README's front-matter example must be copy-pasteable.
  def test_readme_front_matter_example_is_valid_yaml
    readme = File.read(File.expand_path("../README.md", __dir__))
    example = readme[/^    ---\n(.*?)^    ---\n/m, 1]
    assert example, "front-matter example not found in README.md"
    fm = YAML.safe_load(example.gsub(/^    /, ""))
    Aim42::Validator::REQUIRED.each { |key| assert_kind_of String, fm[key], "README example: '#{key}'" }
  end

  CATEGORIES = "approaches:\n  title: Improvement approaches\narchitecture-and-code:\n  title: Architecture and code structure\n"

  def test_known_categories_pass
    File.write(File.join(@root, "_data", "categories.yml"), CATEGORIES)
    pattern("a", "title: A\nphase: improve\ncategories: [approaches, architecture-and-code]\nintent: I.\nstatus: complete\n")
    assert_empty errors
  end

  def test_unknown_category
    File.write(File.join(@root, "_data", "categories.yml"), CATEGORIES)
    pattern("a", "title: A\nphase: improve\ncategories: [approaches, nonsense]\nintent: I.\nstatus: complete\n")
    assert_includes errors, "a.md: unknown category 'nonsense' (allowed: approaches, architecture-and-code)"
  end

  def test_categories_only_on_improve
    File.write(File.join(@root, "_data", "categories.yml"), CATEGORIES)
    pattern("a", "title: A\nphase: analyze\ncategories: [approaches]\nintent: I.\nstatus: complete\n")
    assert_includes errors, "a.md: 'categories' are only allowed on improve patterns"
  end

  def test_categories_without_categories_file
    pattern("a", "title: A\nphase: improve\ncategories: [approaches]\nintent: I.\nstatus: complete\n")
    assert_includes errors, "a.md: unknown category 'approaches' (allowed: )"
  end

  def test_todo_intent_is_rejected
    pattern("a", "title: A\nphase: improve\nintent: TODO\nstatus: complete\n")
    assert_includes errors, "a.md: 'intent' is still TODO"
  end

  HOME_OK = <<~YAML
    layout: home
    headline: Improve software systems, systematically.
    lede: A method.
    cycle:
      analyze: find the issues
      improve: fix step by step
    examples:
      analyze: [a1, a2, a3]
      improve: [i1, i2, i3]
    get_started:
      - text: Collect issues.
        patterns: [a1]
  YAML

  def home(front_matter)
    FileUtils.mkdir_p(File.join(@root, "_pages"))
    File.write(File.join(@root, "_pages", "home.md"), "---\n#{front_matter}---\n\nBody.\n")
  end

  def home_patterns
    %w[a1 a2 a3].each { |s| pattern(s, "title: #{s.upcase}\nphase: analyze\nintent: x\nstatus: complete\n") }
    %w[i1 i2 i3].each { |s| pattern(s, "title: #{s.upcase}\nphase: improve\nintent: x\nstatus: complete\n") }
  end

  def test_valid_home_page_has_no_errors
    home_patterns
    home(HOME_OK)
    assert_empty errors
  end

  def test_home_page_with_another_layout_is_not_checked
    home_patterns
    home("layout: splash\n")
    assert_empty errors
  end

  def test_home_needs_headline_and_lede
    home_patterns
    home(HOME_OK.sub(/^headline:.*\n/, "").sub(/^lede:.*\n/, "lede: \"\"\n"))
    assert_includes errors, "_pages/home.md: missing required key 'headline'"
    assert_includes errors, "_pages/home.md: missing required key 'lede'"
  end

  def test_home_needs_examples_and_cycle_line_for_every_phase
    home_patterns
    home(HOME_OK.sub("  improve: fix step by step\n", "").sub("  improve: [i1, i2, i3]\n", ""))
    assert_includes errors, "_pages/home.md: cycle line for 'improve' is missing"
    assert_includes errors, "_pages/home.md: examples for 'improve' must be a list of three slugs"
  end

  def test_home_example_must_be_three
    home_patterns
    home(HOME_OK.sub("[a1, a2, a3]", "[a1, a2]"))
    assert_includes errors, "_pages/home.md: examples for 'analyze' must be a list of three slugs"
  end

  def test_home_example_must_exist
    home_patterns
    home(HOME_OK.sub("[a1, a2, a3]", "[a1, a2, nope]"))
    assert_includes errors, "_pages/home.md: example 'nope' does not exist in _patterns/"
  end

  def test_home_example_must_belong_to_its_phase
    home_patterns
    home(HOME_OK.sub("[a1, a2, a3]", "[a1, a2, i1]"))
    assert_includes errors, "_pages/home.md: example 'i1' belongs to 'improve', not 'analyze'"
  end

  def test_home_examples_for_unknown_phase
    home_patterns
    home(HOME_OK.sub("examples:\n", "examples:\n  evaluate: [a1, a2, a3]\n"))
    assert_includes errors, "_pages/home.md: examples for unknown phase 'evaluate'"
  end

  def test_home_get_started_is_required
    home_patterns
    home(HOME_OK.sub(/^get_started:.*\z/m, ""))
    assert_includes errors, "_pages/home.md: 'get_started' must be a list of steps"
  end

  def test_home_get_started_step_needs_text_and_existing_patterns
    home_patterns
    home(HOME_OK.sub("  - text: Collect issues.\n    patterns: [a1]\n", "  - text: Collect issues.\n    patterns: [nope]\n  - patterns: [a1]\n  - text: Estimate.\n"))
    assert_includes errors, "_pages/home.md: get_started step 1: 'nope' does not exist in _patterns/"
    assert_includes errors, "_pages/home.md: get_started step 2 needs a 'text'"
    assert_includes errors, "_pages/home.md: get_started step 3 needs a list of patterns"
  end
end
