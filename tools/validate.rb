# Validates the front matter of every file in _patterns/, and the pattern
# references on the home page (_pages/home.md with layout: home).
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
    HOME = File.join("_pages", "home.md").freeze

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
      categories_file = File.join(@root, "_data", "categories.yml")
      categories = File.file?(categories_file) ? YAML.safe_load(File.read(categories_file)).keys : []
      paths = files
      known = paths.map { |f| slug(f) }
      slugs = Hash.new { |h, k| h[k] = [] }
      titles = Hash.new { |h, k| h[k] = [] }
      phase_of = {}

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
        phase_of[slug] = fm["phase"]

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
        if fm.key?("categories")
          errors << "#{name}: 'categories' are only allowed on improve patterns" if fm["phase"] != "improve"
          if fm["categories"].is_a?(Array)
            (fm["categories"] - categories).each do |c|
              errors << "#{name}: unknown category '#{c}' (allowed: #{categories.join(", ")})"
            end
          else
            errors << "#{name}: 'categories' must be a list"
          end
        end
        errors << "#{name}: 'intent' is still TODO" if fm["intent"].to_s.strip == "TODO"
        titles[fm["title"].to_s.strip.downcase] << name unless fm["title"].to_s.strip.empty?
      end

      slugs.each { |slug, names| errors << "duplicate slug '#{slug}' in #{names.join(", ")}" if names.size > 1 }
      titles.each { |title, names| errors << "duplicate title '#{title}' in #{names.join(", ")}" if names.size > 1 }
      errors.concat(home_errors(phases, phase_of))
      errors
    end

    # The home page names patterns by slug (examples per phase, Get started
    # steps). A rename or delete must fail the build like a broken `related`.
    def home_errors(phases, phase_of)
      file = File.join(@root, HOME)
      return [] unless File.file?(file)
      begin
        fm = front_matter(file)
      rescue Psych::Exception => e
        return ["#{HOME}: invalid YAML front matter (#{e.message})"]
      end
      return [] unless fm.is_a?(Hash) && fm["layout"] == "home"

      errors = []
      text = ->(value) { value.is_a?(String) && !value.strip.empty? }
      %w[headline lede].each do |key|
        errors << "#{HOME}: missing required key '#{key}'" unless text.(fm[key])
      end
      # The hero renders the lede inline; a blank line would run two paragraphs together.
      if text.(fm["lede"]) && fm["lede"].strip.match?(/\n[ \t]*\n/)
        errors << "#{HOME}: 'lede' must be a single paragraph"
      end

      cycle = fm["cycle"].is_a?(Hash) ? fm["cycle"] : {}
      phases.each do |phase|
        errors << "#{HOME}: cycle line for '#{phase}' is missing" unless text.(cycle[phase])
      end

      examples = fm["examples"].is_a?(Hash) ? fm["examples"] : {}
      phases.each do |phase|
        list = examples[phase]
        unless list.is_a?(Array) && list.size == 3
          errors << "#{HOME}: examples for '#{phase}' must be a list of three slugs"
          next
        end
        list.each do |slug|
          if !phase_of.key?(slug)
            errors << "#{HOME}: example '#{slug}' does not exist in _patterns/"
          elsif phase_of[slug] != phase
            errors << "#{HOME}: example '#{slug}' belongs to '#{phase_of[slug]}', not '#{phase}'"
          end
        end
      end
      (examples.keys - phases).each { |key| errors << "#{HOME}: examples for unknown phase '#{key}'" }

      steps = fm["get_started"]
      unless steps.is_a?(Array) && !steps.empty?
        return errors << "#{HOME}: 'get_started' must be a list of steps"
      end
      steps.each.with_index(1) do |step, n|
        unless step.is_a?(Hash)
          errors << "#{HOME}: get_started step #{n} must be a mapping"
          next
        end
        errors << "#{HOME}: get_started step #{n} needs a 'text'" unless text.(step["text"])
        if step["patterns"].is_a?(Array) && !step["patterns"].empty?
          (step["patterns"] - phase_of.keys).each do |slug|
            errors << "#{HOME}: get_started step #{n}: '#{slug}' does not exist in _patterns/"
          end
        else
          errors << "#{HOME}: get_started step #{n} needs a list of patterns"
        end
      end
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
