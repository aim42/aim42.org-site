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
end
