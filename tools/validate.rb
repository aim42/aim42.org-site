# Validates the front matter of every file in _patterns/.
#
#   ruby tools/validate.rb            # checks the current directory
#   ruby tools/validate.rb path/to/site
#
# Exit status 1 and one "ERROR …" line per finding when anything is wrong.
require "yaml"

module Aim42
  class Validator
    REQUIRED = %w[title phase intent status].freeze
    STATUSES = %w[complete stub].freeze
    SLUG = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

    def initialize(root)
      @root = root
    end

    def run
      errors = []
      phases = YAML.safe_load(File.read(File.join(@root, "_data", "phases.yml"))).keys
      files = Dir[File.join(@root, "_patterns", "*.md")].sort
      slugs = files.map { |f| File.basename(f, ".md") }
      titles = Hash.new { |h, k| h[k] = [] }

      files.each do |file|
        name = File.basename(file)
        slug = File.basename(file, ".md")
        errors << "#{name}: filename must be a kebab-case slug" unless slug.match?(SLUG)
        errors << "#{name}: slug '#{slug}' is reserved for a phase page" if phases.include?(slug)
        errors << "#{name}: slug 'index' is reserved" if slug == "index"

        begin
          fm = front_matter(file)
        rescue Psych::SyntaxError => e
          errors << "#{name}: invalid YAML front matter (#{e.message})"
          next
        end
        if fm.nil?
          errors << "#{name}: missing front matter"
          next
        end

        REQUIRED.each do |key|
          errors << "#{name}: missing required key '#{key}'" if fm[key].to_s.strip.empty?
        end
        if fm.key?("phase") && !phases.include?(fm["phase"])
          errors << "#{name}: unknown phase '#{fm["phase"]}' (allowed: #{phases.join(", ")})"
        end
        if fm.key?("status") && !STATUSES.include?(fm["status"])
          errors << "#{name}: unknown status '#{fm["status"]}' (allowed: #{STATUSES.join(", ")})"
        end
        if fm.key?("related")
          if fm["related"].is_a?(Array)
            (fm["related"] - slugs).each { |r| errors << "#{name}: related slug '#{r}' does not exist in _patterns/" }
          else
            errors << "#{name}: 'related' must be a list of slugs"
          end
        end
        errors << "#{name}: 'categories' must be a list" if fm.key?("categories") && !fm["categories"].is_a?(Array)
        titles[fm["title"].to_s.strip.downcase] << name unless fm["title"].to_s.strip.empty?
      end

      titles.each { |title, names| errors << "duplicate title '#{title}' in #{names.join(", ")}" if names.size > 1 }
      errors
    end

    private

    # Returns the parsed front matter hash, nil when the file has none.
    def front_matter(file)
      text = File.read(file)
      return nil unless text.start_with?("---\n")
      close = text.index("\n---", 4)
      return nil unless close
      YAML.safe_load(text[4...close]) || {}
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
