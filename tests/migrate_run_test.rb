require "minitest/autorun"
require "tmpdir"
require "fileutils"
require_relative "../tools/migrate/run"
require_relative "../tools/validate"

class MigrateRunTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  MANIFEST = YAML.safe_load(File.read(File.join(ROOT, "tools", "migrate", "manifest.yml")))
  PILOT = MANIFEST["patterns"].select { |p| p["pilot"] }.map { |p| p["slug"] }

  # Deliberate pilot-only headings: the pilot's improvement-backlog adds "Description";
  # its strangler-approach titles the related notes "Related". The converter's
  # "Notes on related patterns" (spec §4) is allowed everywhere.
  PILOT_ONLY_HEADINGS = { "improvement-backlog" => ["description"], "strangler-approach" => ["related"] }.freeze

  # Hand-curated pilot relations that the source's Related section lacks
  # (recorded in phase 1 as "phase 2 restores").
  PILOT_EXTRA_RELATED = { "improvement-backlog" => ["issue-list"], "strangler-approach" => ["big-bang-approach"] }.freeze

  # One full conversion into a scratch root, shared by the tests below.
  def self.converted
    @converted ||= begin
      out = Dir.mktmpdir("aim42-migrate")
      FileUtils.mkdir_p(File.join(out, "_data"))
      Dir[File.join(ROOT, "_data", "*.yml")].each { |f| FileUtils.cp(f, File.join(out, "_data")) }
      FileUtils.mkdir_p(File.join(out, "_patterns"))
      PILOT.each { |slug| FileUtils.cp(File.join(ROOT, "_patterns", "#{slug}.md"), File.join(out, "_patterns")) }
      report = Aim42::Migrate::Run.new(out: out).call
      [out, report]
    end
  end

  def out
    self.class.converted.first
  end

  def report
    self.class.converted.last
  end

  def headings(text)
    text.sub(/\A---\n.*?\n---\n/m, "").scan(/^(#+) (.+?)(?:\s+\{#[^}]*\})?$/).map { |level, name| [level.size, name.downcase] }
  end

  def test_every_manifest_pattern_gets_a_file
    MANIFEST["patterns"].each do |p|
      assert File.file?(File.join(out, "_patterns", "#{p["slug"]}.md")), "#{p["slug"]} not written"
    end
  end

  def test_converted_front_matter_passes_the_validator
    assert_equal [], Aim42::Validator.new(out).run
  end

  def test_no_intent_is_left_empty
    todo = Dir[File.join(out, "_patterns", "*.md")].select { |f| File.read(f).include?("\nintent: TODO\n") }
    assert_equal [], todo.map { |f| File.basename(f) }
  end

  def test_stubs_from_the_index_have_no_body
    text = File.read(File.join(out, "_patterns", "bulkhead.md"))
    assert_includes text, "\nstatus: stub\n"
    assert text.end_with?("---\n"), "stub body must be empty"
  end

  def test_anchor_table_and_report_are_written
    anchors = YAML.safe_load(File.read(File.join(out, "_data", "anchors.yml")))
    assert_equal "/patterns/stakeholder-interview/", anchors["Stakeholder-Interview"]
    assert_operator anchors.size, :>=, 190
    assert File.file?(File.join(out, "tools", "migrate", "report.md"))
    refute report.any? { |_, note| note.start_with?("duplicate anchor") }, "anchor conflicts"
  end

  def test_pilot_files_are_left_alone
    PILOT.each do |slug|
      assert_equal File.read(File.join(ROOT, "_patterns", "#{slug}.md")), File.read(File.join(out, "_patterns", "#{slug}.md"))
    end
  end

  def test_existing_files_are_not_overwritten
    Dir.mktmpdir("aim42-rerun") do |dir|
      Aim42::Migrate::Run.new(out: dir, only: ["fail-fast"]).call
      path = File.join(dir, "_patterns", "fail-fast.md")
      File.write(path, "hand edited")
      report = Aim42::Migrate::Run.new(out: dir, only: ["fail-fast"]).call
      assert_equal "hand edited", File.read(path)
      assert_includes report, ["_patterns/fail-fast.md", "exists: not overwritten"]
    end
  end

  # The hand-converted pilot is the oracle (spec §5): the converter must agree on
  # front matter, images and section structure. Prose edits made by hand in the
  # pilot (spelling, wording) are deliberate and not compared.
  def test_converter_agrees_with_the_hand_converted_pilot
    Dir.mktmpdir("aim42-oracle") do |oracle|
      Aim42::Migrate::Run.new(out: oracle, only: PILOT, pilot: true).call
      PILOT.each do |slug|
        mine = File.read(File.join(oracle, "_patterns", "#{slug}.md"))
        pilot = File.read(File.join(ROOT, "_patterns", "#{slug}.md"))
        mine_fm = YAML.safe_load(mine[/\A---\n.*?\n---\n/m])
        pilot_fm = YAML.safe_load(pilot[/\A---\n.*?\n---\n/m])
        keys = %w[title phase categories status]
        assert_equal pilot_fm.slice(*keys), mine_fm.slice(*keys), "#{slug}: front matter"
        assert_equal pilot.scan(/!\[[^\]]*\]\(([^)]+)\)/), mine.scan(/!\[[^\]]*\]\(([^)]+)\)/), "#{slug}: images"
        mine_headings = headings(mine).reject { |_, name| name == "notes on related patterns" }
        pilot_headings = headings(pilot).reject { |_, name| PILOT_ONLY_HEADINGS.fetch(slug, []).include?(name) }
        assert_equal pilot_headings, mine_headings, "#{slug}: section structure (level, name, order)"
        assert_empty Array(pilot_fm["related"]) - Array(mine_fm["related"]) - PILOT_EXTRA_RELATED.fetch(slug, []), "#{slug}: related the converter misses"
      end
    end
  end

  def test_a_body_that_only_repeats_the_intent_makes_a_stub
    text = File.read(File.join(out, "_patterns", "widen-your-options.md"))
    assert_includes text, "\nstatus: stub\n"
    assert text.end_with?("---\n"), "stub body must be empty"
  end

  def test_converted_bodies_do_not_repeat_the_intent
    Dir[File.join(out, "_patterns", "*.md")].each do |file|
      next if PILOT.include?(File.basename(file, ".md"))
      text = File.read(file)
      intent = YAML.safe_load(text[/\A---\n.*?\n---\n/m])["intent"]
      first = text.sub(/\A---\n.*?\n---\n/m, "").strip.split(/\n{2,}/).first.to_s.gsub(/\s*\n\s*/, " ")
      refute_equal intent, first, File.basename(file)
    end
  end
end
