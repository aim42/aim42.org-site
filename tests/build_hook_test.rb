# The Jekyll build runs tools/validate.rb through _plugins/validate_patterns.rb,
# so a plain `jekyll build` (as on the deploy host) fails on invalid patterns.
require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "jekyll"

class BuildHookTest < Minitest::Test
  PLUGINS = File.expand_path("../_plugins", __dir__)

  def setup
    @root = Dir.mktmpdir
    FileUtils.mkdir_p(File.join(@root, "_data"))
    FileUtils.mkdir_p(File.join(@root, "_patterns"))
    File.write(File.join(@root, "_data", "phases.yml"), "analyze:\n  title: Analyze\n")
  end

  def teardown
    FileUtils.rm_rf(@root)
  end

  def pattern(name, front_matter)
    File.write(File.join(@root, "_patterns", "#{name}.md"), "---\n#{front_matter}---\n\nBody.\n")
  end

  # Builds the temp site with the real _plugins/ directory, output silenced;
  # what Jekyll logged stays in Jekyll.logger.messages.
  def build
    Jekyll.logger.messages.clear
    capture_subprocess_io do
      config = Jekyll.configuration(
        "source" => @root, "destination" => File.join(@root, "_site"),
        "plugins_dir" => PLUGINS, "collections" => { "patterns" => { "output" => true } }
      )
      Jekyll::Site.new(config).process
    end
  end

  def test_valid_patterns_build
    pattern("a", "title: A\nphase: analyze\nintent: x\nstatus: complete\n")
    build
    assert File.file?(File.join(@root, "_site", "patterns", "a.html")), "valid site did not build"
  end

  def test_invalid_pattern_fails_the_build
    pattern("a", "title: A\nphase: nope\nintent: x\nstatus: complete\n")
    error = assert_raises(Jekyll::Errors::FatalException) { build }
    assert_includes error.message, "1 invalid pattern finding"
    assert Jekyll.logger.messages.any? { |m| m.include?("a.md: unknown phase 'nope'") }, Jekyll.logger.messages.last(5).inspect
  end
end
