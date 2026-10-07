# The table of old AsciiDoc anchors and the URLs they now live at.
# The converter resolves <<xrefs>> with it; _data/anchors.yml is its dump
# and feeds the phase-3 redirector on aim42.github.io.
module Aim42
  module Migrate
    class Anchors
      Entry = Struct.new(:url, :link_text, keyword_init: true)

      attr_reader :duplicates

      def initialize
        @map = {}
        @duplicates = []
      end

      # The first registration of an anchor wins; later ones are recorded.
      def add(anchor, url, link_text: nil)
        if @map.key?(anchor)
          @duplicates << anchor unless @map[anchor].url == url
          return
        end
        @map[anchor] = Entry.new(url: url, link_text: link_text)
      end

      # Exact match first, then case-insensitive, then with blanks as hyphens.
      def lookup(ref)
        ref = ref.strip
        @map[ref] || find { |k| k.casecmp?(ref) } || find { |k| k.casecmp?(ref.gsub(/\s+/, "-")) }
      end

      def to_h
        @map.sort_by { |k, _| k.downcase }.to_h { |k, v| [k, v.url] }
      end

      # manifest: the parsed tools/migrate/manifest.yml; source: a Source.
      # Patterns, pages and glossary terms come first, so their own anchors win
      # over anchors that merely sit somewhere inside another file.
      def self.build(manifest, source)
        table = new
        manifest["patterns"].each do |p|
          url = "/patterns/#{p["slug"]}/"
          ([p["anchor"]] + Array(p["aliases"])).each { |a| table.add(a, url, link_text: p["title"]) }
        end
        manifest["pages"].each do |page|
          Array(page["anchors"]).each { |a| table.add(a, page["url"]) }
        end
        manifest["glossary"].each do |term, slug|
          table.add(term, "/glossary/##{slug}", link_text: term.downcase)
        end
        Array(manifest["extra_anchors"]).each { |anchor, url| table.add(anchor, url) }
        manifest["patterns"].each do |p|
          url = "/patterns/#{p["slug"]}/"
          (source.anchors_in(Snippets.pattern(source, p)) - [p["anchor"]]).each do |a|
            table.add(a, "#{url}##{a.downcase}")
          end
        end
        manifest["pages"].each do |page|
          (source.anchors_in(Snippets.page(source, page, manifest)) - Array(page["anchors"])).each do |a|
            table.add(a, "#{page["url"]}##{a.downcase}")
          end
        end
        table
      end

      private

      def find
        key = @map.keys.find { |k| yield k }
        key && @map[key]
      end
    end

    # Where the AsciiDoc text of a manifest entry comes from.
    module Snippets
      module_function

      # source: "file.adoc" (whole file) or "file.adoc#Anchor" (one section).
      def pattern(source, entry)
        file, anchor = entry["source"].split("#", 2)
        if file == "pattern-index.adoc"
          source.index_entry(anchor).to_s
        elsif anchor
          source.section(source.expand(file), anchor)
        else
          source.expand(file)
        end
      end

      def page(source, page, manifest)
        text = Array(page["source"]).map { |f| source.expand(f) }.join("\n")
        inline = manifest["patterns"].map { |p| p["source"].split("#", 2) }
                                     .select { |f, a| a && Array(page["source"]).include?(f) }.map(&:last)
        source.cut(text, inline)
      end
    end
  end
end
