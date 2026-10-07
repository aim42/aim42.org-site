# Validates the front matter of every file in _patterns/.
#
#   ruby tools/validate.rb            # checks the current directory
#   ruby tools/validate.rb path/to/site
#
# Exit status 1 and one "ERROR …" line per finding when anything is wrong.
# _plugins/validate_patterns.rb runs the same checks in every Jekyll build.
require "yaml"
require "date"

module Aim42
  class Validator
    REQUIRED = %w[title phase intent status].freeze
    STRINGS = %w[title intent].freeze
    STATUSES = %w[complete stub].freeze
    SLUG = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/
    # Jekyll publishes these as pages (markdown_ext in _config.yml), also from subdirectories.
    EXTENSIONS = %w[md markdown mkdown mkdn mkd].freeze

    def initialize(root)
      @root = root
    end

    # Every pattern source file, sorted.
    def files
      Dir[File.join(@root, "_patterns", "**", "*.{#{EXTENSIONS.join(",")}}")].sort
    end

    # The URL slug: /patterns/:name/ uses the basename without extension.
    def slug(file)
      File.basename(file, File.extname(file))
    end

    def run
      errors = []
      phases = YAML.safe_load(File.read(File.join(@root, "_data", "phases.yml"))).keys
      paths = files
      known = paths.map { |f| slug(f) }
      slugs = Hash.new { |h, k| h[k] = [] }
      titles = Hash.new { |h, k| h[k] = [] }

      paths.each do |file|
        name = file.delete_prefix(File.join(@root, "_patterns", ""))
        slug = slug(file)
        slugs[slug] << name
        errors << "#{name}: filename must be a kebab-case slug" unless slug.match?(SLUG)
        errors << "#{name}: slug '#{slug}' is reserved for a phase page" if phases.include?(slug)
        errors << "#{name}: slug 'index' is reserved" if slug == "index"

        begin
          fm = front_matter(file)
        rescue Psych::Exception => e
          errors << "#{name}: invalid YAML front matter (#{e.message})"
          next
        end
        if fm.nil?
          errors << "#{name}: missing front matter"
          next
        end
        unless fm.is_a?(Hash)
          errors << "#{name}: front matter must be a mapping"
          next
        end

        REQUIRED.each do |key|
          errors << "#{name}: missing required key '#{key}'" if fm[key].to_s.strip.empty?
        end
        STRINGS.each do |key|
          errors << "#{name}: '#{key}' must be a string" if fm.key?(key) && !fm[key].nil? && !fm[key].is_a?(String)
        end
        # intent is rendered inline (teasers, meta description): one paragraph only.
        if fm["intent"].is_a?(String) && fm["intent"].strip.match?(/\n[ \t]*\n/)
          errors << "#{name}: 'intent' must be a single paragraph"
        end
        if fm.key?("phase") && !phases.include?(fm["phase"])
          errors << "#{name}: unknown phase '#{fm["phase"]}' (allowed: #{phases.join(", ")})"
        end
        if fm.key?("status") && !STATUSES.include?(fm["status"])
          errors << "#{name}: unknown status '#{fm["status"]}' (allowed: #{STATUSES.join(", ")})"
        end
        if fm.key?("related")
          if fm["related"].is_a?(Array)
            (fm["related"] - known).each { |r| errors << "#{name}: related slug '#{r}' does not exist in _patterns/" }
          else
            errors << "#{name}: 'related' must be a list of slugs"
          end
        end
        errors << "#{name}: 'categories' must be a list" if fm.key?("categories") && !fm["categories"].is_a?(Array)
        titles[fm["title"].to_s.strip.downcase] << name unless fm["title"].to_s.strip.empty?
      end

      slugs.each { |slug, names| errors << "duplicate slug '#{slug}' in #{names.join(", ")}" if names.size > 1 }
      titles.each { |title, names| errors << "duplicate title '#{title}' in #{names.join(", ")}" if names.size > 1 }
      errors
    end

    # Returns the parsed front matter, nil when the file has none.
    # Raises Psych::Exception on invalid YAML.
    def front_matter(file)
      text = File.read(file).gsub("\r\n", "\n")
      return nil unless text.start_with?("---\n")
      close = text.index("\n---", 4)
      return nil unless close
      YAML.safe_load(text[4...close], permitted_classes: [Date, Time]) || {}
    end
  end
end

if $PROGRAM_NAME == __FILE__
  errors = Aim42::Validator.new(ARGV[0] || Dir.pwd).run
  if errors.empty?
    puts "patterns OK"
  else
    errors.each { |e| warn "ERROR #{e}" }
    exit 1
  end
end
