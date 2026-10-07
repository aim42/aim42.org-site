# The ids the old book (aim42.github.io) generated for sections without an
# [[Anchor]] (#_description_7, #_glossary …) and the URLs they now live at.
# Readers copied those links, so _data/anchors.yml carries them for the
# phase-3 redirector. The ids follow Asciidoctor 1.5, which built that site
# (see OLD_ID_CHARS); the result matches the ids aim42.github.io serves.
#
#   result = SectionIds.build(asciidoc_dir, manifest, anchors, site_root)
#   result.map      # { "_description_7" => "/patterns/documentation-analysis/#description", … }
#   result.notes    # sections mapped to a page without a fragment, and why
#   result.left_out # [[id, file], …] sections of chapters the site dropped
#
# Target page: the section's own pattern file (whole-file manifest pattern),
# else the nearest ancestor whose [[Anchor]] the anchor table resolves, else
# the manifest page whose source is the section's file or includes it.
# Fragment: the id kramdown gives the heading with the same title on that page;
# without such a heading the section maps to the page itself.
require "asciidoctor"
require "kramdown"
require "kramdown-parser-gfm"
require "nokogiri"
require_relative "adoc_to_md"
require_relative "source"

module Aim42
  module Migrate
    module SectionIds
      Result = Struct.new(:map, :notes, :left_out, keyword_init: true)

      # The attributes of the old build (_import/build.gradle) that shape section
      # ids; idprefix and idseparator kept Asciidoctor's default "_".
      ATTRIBUTES = { "doctype" => "book", "numbered" => "", "sectanchors" => "" }.freeze
      # Jekyll's kramdown settings (_config.yml) that decide heading ids.
      KRAMDOWN = { input: "GFM", auto_ids: true, hard_wrap: false }.freeze
      # Asciidoctor 1.5's InvalidSectionIdCharsRx: unlike 2.x it keeps the markup
      # of the converted title, so "[pattern]#X#" gave _span_class_pattern_x_span
      # and "Conway's" gave _conway_s.
      OLD_ID_CHARS = /&(?:[a-z][a-z]+\d{0,2}|#\d\d\d{0,4}|#x[\da-f][\da-f][\da-f]{0,3});|[^[:word:]]+?/

      module_function

      # asciidoc: the directory of index.adoc; manifest: the parsed manifest.yml;
      # anchors: the Anchors table; site_root: where _patterns/ and _pages/ live.
      def build(asciidoc, manifest, anchors, site_root)
        context = {
          root: asciidoc,
          anchors: anchors,
          patterns: manifest["patterns"].reject { |p| p["source"].include?("#") }
                                        .to_h { |p| [p["source"], "/patterns/#{p["slug"]}/"] },
          pages: manifest["pages"].flat_map { |p| Array(p["source"]).map { |s| [s, p["url"]] } }.to_h,
          parents: include_parents(asciidoc)
        }
        files = markdown_files(site_root)
        result = Result.new(map: {}, notes: [], left_out: [])
        old_ids(load(asciidoc)).each do |section, id|
          page = target_page(section, context)
          unless page
            result.left_out << [id, relative(section.source_location.file, asciidoc)]
            next
          end
          result.map[id] = url(section, id, page, files[page], result.notes)
        end
        result
      end

      # [[section, old id]] for each section without [[Anchor]], in document
      # order; a repeated id gets _2, _3 … (also past explicit ids).
      def old_ids(doc)
        sections = doc.find_by(context: :section).select { |s| generated_id?(s) }
        taken = doc.catalog[:refs].keys - sections.map(&:id)
        sections.map do |section|
          base = "_#{section.title.downcase.gsub(OLD_ID_CHARS, "_")}".tr_s("_", "_").chomp("_")
          id = base
          count = 1
          id = "#{base}_#{count += 1}" while taken.include?(id)
          taken << id
          [section, id]
        end
      end

      # The book as the old build loaded it.
      def load(asciidoc)
        Asciidoctor::LoggerManager.logger = Asciidoctor::MemoryLogger.new
        Asciidoctor.load_file(File.join(asciidoc, "index.adoc"), safe: :safe, base_dir: asciidoc,
                                                                  sourcemap: true, attributes: ATTRIBUTES)
      ensure
        Asciidoctor::LoggerManager.logger = nil
      end

      # Asciidoctor generated the id (with its "_" prefix); [[Anchor]] ids sit in the attributes.
      def generated_id?(section)
        section.attributes["id"].nil? && section.id.to_s.start_with?("_")
      end

      def target_page(section, context)
        node = section
        while node.is_a?(Asciidoctor::Section)
          if (id = node.attributes["id"]) && (entry = context[:anchors].lookup(id))
            return entry.url.split("#", 2).first
          end
          pattern = context[:patterns][relative(node.source_location.file, context[:root])]
          return pattern if pattern
          node = node.parent
        end
        file = section.source_location.file
        while file
          page = context[:pages][relative(file, context[:root])]
          return page if page
          file = context[:parents][file]
        end
        nil
      end

      def url(section, id, page, file, notes)
        title = Nokogiri::HTML::DocumentFragment.parse(section.title).text.strip
        wanted = AdocToMd.heading_id(title)
        ids = file ? heading_ids(file).select { |base, _| base == wanted }.map(&:last) : []
        return "#{page}##{ids.first}" if ids.size == 1
        why = ids.empty? ? "no heading \"#{title}\"" : "#{ids.size} headings \"#{title}\""
        notes << "section id #{id}: #{why} on #{page}, mapped to the page"
        page
      end

      # [[id the heading text gives, id kramdown assigns]] for each heading of a Markdown file.
      def heading_ids(file)
        body = File.read(file, encoding: "UTF-8").sub(/\A---\n.*?\n---\n/m, "")
        headers = []
        stack = [Kramdown::Document.new(body, **KRAMDOWN).root]
        until stack.empty?
          el = stack.shift
          headers << [AdocToMd.heading_id(el.options[:raw_text]), el.attr["id"]] if el.type == :header
          stack.unshift(*el.children)
        end
        headers
      end

      # URL → Markdown file: patterns by slug, pages by permalink.
      def markdown_files(site_root)
        files = Dir[File.join(site_root, "_patterns", "*.md")].to_h do |f|
          ["/patterns/#{File.basename(f, ".md")}/", f]
        end
        Dir[File.join(site_root, "_pages", "**", "*.md")].each do |f|
          permalink = File.read(f, encoding: "UTF-8")[/\A---\n.*?^permalink:\s*(\S+)/m, 1]
          files[permalink] ||= f if permalink
        end
        files
      end

      # Included file → the file that includes it (absolute paths).
      def include_parents(asciidoc)
        parents = {}
        Dir[File.join(asciidoc, "**", "*.adoc")].sort.each do |parent|
          File.foreach(parent, encoding: "UTF-8") do |line|
            match = line.strip.match(Source::INCLUDE)
            parents[File.expand_path(match[1], File.dirname(parent))] ||= parent if match
          end
        end
        parents
      end

      def relative(file, root)
        File.expand_path(file).delete_prefix("#{File.expand_path(root)}/")
      end
    end
  end
end
