# Reads the imported AsciiDoc sources (_import/src/main/asciidoc) and cuts
# them into the snippets the converter works on.
module Aim42
  module Migrate
    class Source
      ANCHOR = /\[\[\[?([A-Za-z0-9_.-]+)(?:,[^\]]*)?\]\]\]?/
      INCLUDE = /\Ainclude::([^\[]+)\[[^\]]*\]\s*\z/
      HEADING = /\A(=+)\s+\S/

      # root: the asciidoc directory. skip: paths (relative to root) whose
      # includes are dropped, because they are converted on their own.
      def initialize(root, skip: [])
        @root = root
        @skip = skip.map { |p| File.expand_path(p, root) }
      end

      # The file's text with includes inlined, except includes of skipped files.
      def expand(path)
        full = File.expand_path(path, @root)
        File.read(full, encoding: "UTF-8").gsub("\r\n", "\n").lines.map do |line|
          match = line.match(INCLUDE)
          next line unless match
          target = File.expand_path(match[1], File.dirname(full))
          next "" if @skip.include?(target)
          expand(target.delete_prefix("#{@root}/")) + "\n"
        end.join
      end

      # The block that starts at the line [[anchor]] and ends before the next
      # heading at the same or a higher level (or before the anchor line of it).
      def section(text, anchor)
        lines = text.lines
        start = lines.index { |l| l.strip.match?(/\A\[\[#{Regexp.escape(anchor)}(,[^\]]*)?\]\]\z/) }
        raise ArgumentError, "anchor #{anchor} not found" unless start
        heading = (start + 1...lines.size).find { |i| lines[i].match?(HEADING) }
        depth = lines[heading][HEADING, 1].size
        stop = (heading + 1...lines.size).find do |i|
          lines[i].match?(HEADING) && lines[i][HEADING, 1].size <= depth
        end || lines.size
        stop -= 1 while stop > heading + 1 && (lines[stop - 1].strip.empty? || lines[stop - 1].strip.match?(/\A\[\[.*\]\]\z/))
        lines[start...stop].join
      end

      # text without the sections that start at the given anchors.
      def cut(text, anchors)
        anchors.reduce(text) do |result, anchor|
          result.include?("[[#{anchor}]]") ? result.sub(section(result, anchor), "") : result
        end
      end

      # The one-line description of an entry in pattern-index.adoc, as AsciiDoc.
      def index_entry(anchor)
        entries = expand("pattern-index.adoc").split(/^(?=\. )/)
        entry = entries.find { |e| e.match?(/\A\. (\[\[#{Regexp.escape(anchor)}\]\]|\*<<#{Regexp.escape(anchor)}(,[^>]*)?>>\*)/) }
        return nil unless entry
        text = entry.sub(/\A\. \*<<[^>]+>>\*\s*/, "")
                    .sub(/\A\. \[\[[^\]]+\]\]\s*(\+\s*)?\[pattern\]#[^#]+#[^:\n]*::\s*/, "")
        text = text.sub(/\s*Category:.*\z/m, "").gsub(/^\+\s*$/, "").strip
        text.empty? ? nil : text
      end

      def anchors_in(text)
        text.scan(ANCHOR).flatten.uniq
      end
    end
  end
end
