# Converts one AsciiDoc snippet of the aim42 method reference to Markdown.
# Asciidoctor parses, Nokogiri normalizes the HTML, kramdown writes Markdown.
#
#   result = Aim42::Migrate::AdocToMd.new(anchors).convert(adoc, self_url: "/patterns/x/")
#   result.title, result.intent, result.related, result.body, result.images, result.notes
require "asciidoctor"
require "nokogiri"
require "kramdown"

module Aim42
  module Migrate
    # kramdown's own writer, with three changes for hand-editable output:
    # inline links instead of reference links, no escaping of quotes,
    # fenced code blocks and one delimiter cell per table column.
    class MarkdownWriter < Kramdown::Converter::Kramdown
      ESCAPES = /(\$\$|[\\*_`\[\]{|])|^ {0,3}(:)/

      def convert_text(el, opts)
        return el.value if opts[:raw_text]
        result = el.value.gsub(/\A\n/) { opts[:prev] && opts[:prev].type == :br ? "" : "\n" }
        result.gsub!(/\s+/, " ") unless el.options[:cdata]
        result.gsub(ESCAPES) { $1 || !opts[:prev] || opts[:prev].type == :br ? "\\#{$1 || $2}" : $& }
      end

      def convert_a(el, opts)
        href = el.attr["href"].to_s
        return super if href.empty?
        "[#{inner(el, opts)}](#{href})"
      end

      def convert_codeblock(el, _opts)
        lang = el.attr.delete("class").to_s[/language-(\S+)/, 1]
        "```#{lang}\n#{el.value.chomp}\n```\n"
      end

      def convert_thead(el, opts)
        columns = el.children.first ? el.children.first.children.size : 1
        "#{inner(el, opts)}|#{(["---"] * columns).join("|")}|\n"
      end
    end

    class AdocToMd
      Result = Struct.new(:title, :intent, :related, :body, :images, :notes, keyword_init: true)

      HEADINGS = %w[h1 h2 h3 h4 h5 h6].freeze
      RELATED = /\Arelated(\s+(patterns|practices))?\z/i
      ADMONITIONS = %w[note tip important warning caution].freeze
      KEEP = { "a" => %w[href], "img" => %w[src alt], "code" => %w[class],
               "p" => %w[id], "li" => %w[id], "dt" => %w[id], "dd" => %w[id] }.freeze
      # Blocks that take over the id of an inline [[anchor]] inside them.
      ID_HOSTS = %w[p li dt dd].freeze

      # anchors: an Anchors instance (lookup(ref) -> Anchors::Entry or nil).
      def initialize(anchors)
        @anchors = anchors
      end

      # adoc: the AsciiDoc source of one pattern or page, includes already expanded.
      # self_url: the URL the result is published at; links to it are dropped.
      def convert(adoc, self_url: nil)
        @notes = []
        @images = []
        @self_url = self_url
        frag = Nokogiri::HTML::DocumentFragment.parse(render(adoc))
        footnotes = extract_footnotes(frag)
        normalize_blocks(frag)
        rewrite_links(frag)
        flatten(frag)
        nodes = frag.children.reject { |n| n.text? && n.text.strip.empty? }
        title = take_title(nodes)
        intent_nodes, related, body_nodes = split_sections(nodes)
        body = markdown(body_nodes.map(&:to_html).join("\n"))
        body = add_footnotes(body, footnotes)
        intent = intent_nodes && one_line(markdown(intent_nodes.to_html))
        Result.new(title: title, intent: intent, related: related, body: body,
                   images: @images.uniq, notes: @notes)
      end

      private

      def render(adoc)
        logger = Asciidoctor::MemoryLogger.new
        Asciidoctor::LoggerManager.logger = logger
        html = Asciidoctor.convert(adoc, safe: :safe, attributes: { "imagesdir" => "/images/patterns" })
        logger.messages.each do |m|
          text = m[:message].is_a?(String) ? m[:message] : m[:message].text
          @notes << "asciidoctor: #{text}" unless text.include?("section title out of sequence")
        end
        html
      ensure
        Asciidoctor::LoggerManager.logger = nil
      end

      # Footnote markers become placeholder tokens; their texts are returned in order.
      def extract_footnotes(frag)
        texts = frag.css("div#footnotes div.footnote").map do |div|
          div.at_css("a")&.remove
          one_line(markdown(div.inner_html.sub(/\A\s*\.\s*/, "")))
        end
        frag.css("div#footnotes").each(&:remove)
        frag.css("hr").each(&:remove) if texts.any?
        frag.css("sup.footnote").each do |sup|
          number = sup.text[/\d+/]
          sup.replace(Nokogiri::XML::Text.new("AIMFN#{number}X", frag.document))
        end
        texts
      end

      def normalize_blocks(frag)
        frag.css("map").each(&:remove)
        frag.css("div.admonitionblock").each { |div| admonition(div) }
        frag.css("div.imageblock").each { |div| image_block(div) }
        frag.css("div.quoteblock").each { |div| quote_block(div) }
        frag.css("div.hdlist").each { |div| hdlist(div) }
        frag.css("table.tableblock").each { |table| table_block(table) }
        frag.css("div.listingblock, div.literalblock").each do |div|
          div.css("div.title").each { |t| t.name = "p"; t.inner_html = "<em>#{t.inner_html}</em>" }
        end
        frag.css("div.ulist > div.title, div.olist > div.title, div.paragraph > div.title").each do |t|
          t.name = "p"
          t.inner_html = "<strong>#{t.inner_html}</strong>"
        end
        frag.css("img").each { |img| image_src(img) }
        frag.css("li, dd").each do |item|
          paragraphs = item.element_children.select { |c| c.name == "p" }
          first = item.element_children.first
          first.replace(first.children) if first&.name == "p" && paragraphs.size == 1
        end
      end

      def admonition(div)
        kind = (div["class"].split & ADMONITIONS).first || "note"
        content = div.at_css("td.content")
        quote = Nokogiri::XML::Node.new("blockquote", div.document)
        inner = content.element_children.any? { |c| c.name == "div" || c.name == "p" } ? content.inner_html : "<p>#{content.inner_html}</p>"
        quote.inner_html = inner
        flatten(quote)
        first = quote.at_css("p") || quote.add_child("<p></p>").first
        first.prepend_child("<strong>#{kind.capitalize}:</strong> ")
        div.replace(quote)
      end

      # A block image with a title becomes ![title](src): the pilot's convention.
      def image_block(div)
        img = div.at_css("img")
        caption = div.at_css("div.title")&.text&.sub(/\A(Figure|Abbildung)\s+\d+\.\s*/, "")
        img["alt"] = caption.strip if caption && !caption.strip.empty?
        para = Nokogiri::XML::Node.new("p", div.document)
        para << (img.parent.name == "a" ? img.parent : img)
        para["id"] = div["id"] if explicit_id?(div["id"])
        div.replace(para)
      end

      def quote_block(div)
        quote = div.at_css("blockquote")
        attribution = div.at_css("div.attribution")
        quote.add_child("<p>— #{attribution.inner_html.strip}</p>") if attribution
        div.replace(quote)
      end

      def hdlist(div)
        dl = Nokogiri::XML::Node.new("dl", div.document)
        div.css("tr").each do |tr|
          dl.add_child("<dt>#{tr.at_css("td.hdlist1").inner_html}</dt>")
          dl.add_child("<dd>#{tr.at_css("td.hdlist2").inner_html}</dd>")
        end
        div.replace(dl)
      end

      def table_block(table)
        table.css("colgroup").each(&:remove)
        caption = table.at_css("caption")
        if caption
          text = caption.text.sub(/\A(Table|Tabelle)\s+\d+\.\s*/, "").strip
          table.add_previous_sibling("<p><em>#{text}</em></p>") unless text.empty?
          caption.remove
        end
        table.css("th, td").each do |cell|
          cell.css("div.content").each { |c| c.replace(c.children) }
          paragraphs = cell.css("p")
          next if paragraphs.empty?
          cell.inner_html = paragraphs.map(&:inner_html).join("<br>")
        end
      end

      def image_src(img)
        src = img["src"].to_s
        return if src.match?(%r{\A(https?:)?//})
        path = src.sub(%r{\A/images/patterns/}, "").sub(%r{\A(\./)?images/}, "")
        img["src"] = "/images/patterns/#{path}"
        @images << path
      end

      def rewrite_links(frag)
        frag.css("a[href]").each do |a|
          href = a["href"]
          if href.start_with?("#_") && (target = frag.at_css("[id='#{href[1..]}']")) && heading?(target)
            a["href"] = "##{heading_id(target.text)}"
          elsif href.start_with?("#")
            internal_link(a, href.delete_prefix("#"))
          elsif href.match?(%r{\A(\./)?(docs|whitepaper)/})
            a["href"] = "/assets/downloads/#{File.basename(href)}"
          end
        end
      end

      # <<Anchor>> arrives as <a href="#Anchor">[Anchor]</a>, <<Anchor,text>> with its text.
      def internal_link(a, ref)
        entry = @anchors.lookup(ref)
        text = a.text.strip
        default = text == "[#{ref}]" || text == ref
        if entry.nil?
          @notes << "unresolved xref: #{ref}"
          a.replace(Nokogiri::XML::Text.new(default ? ref : text, a.document))
          return
        end
        label = entry.link_text if default
        if entry.url == @self_url
          a.replace(label ? Nokogiri::XML::Text.new(label, a.document) : a.children)
        else
          a["href"] = entry.url
          a.content = label if label
        end
      end

      # Removes asciidoctor's wrapper divs and spans and every attribute
      # that the Markdown writer would turn into {: …} noise.
      def flatten(node)
        node.css("div, span").each { |n| n.replace(n.children) }
        node.css("a[id]:not([href])").each do |a|
          host = a.ancestors.find { |n| ID_HOSTS.include?(n.name) }
          host["id"] ||= a["id"] if host && explicit_id?(a["id"])
          a.remove
        end
        node.traverse do |n|
          next unless n.element?
          keep = HEADINGS.include?(n.name) ? %w[id] : KEEP.fetch(n.name, [])
          n.attribute_nodes.each { |attr| attr.remove unless keep.include?(attr.name) }
          n.remove_attribute("id") if n["id"] && !explicit_id?(n["id"])
          n["id"] = n["id"].downcase if n["id"]
          n.remove_attribute("class") if n["class"] && !n["class"].start_with?("language-")
        end
      end

      # Asciidoctor's generated ids start with "_"; [[Anchor]] ids do not.
      def explicit_id?(id)
        !id.to_s.empty? && !id.start_with?("_")
      end

      # The id kramdown generates for a heading (auto_ids), for links within a page.
      def heading_id(text)
        text.downcase.gsub(/[^a-z0-9 -]/, "").strip.gsub(/\s+/, "-").sub(/\A[^a-z]+/, "")
      end

      def heading?(node)
        node.element? && HEADINGS.include?(node.name)
      end

      def level(node)
        node.name[1].to_i
      end

      # The first heading at the top level is the title; the levels below it
      # are shifted so that the title's children become h2.
      def take_title(nodes)
        headings = nodes.select { |n| heading?(n) }
        return nil if headings.empty?
        top = headings.map { |h| level(h) }.min
        title = nil
        if heading?(nodes.first) && level(nodes.first) == top
          title = nodes.shift.text.strip
          shift = top - 1
        else
          shift = top - 2
        end
        headings.drop(title ? 1 : 0).each { |h| h.name = "h#{[[level(h) - shift, 2].max, 6].min}" }
        title
      end

      # Returns [intent nodes or nil, related slugs, body nodes].
      def split_sections(nodes)
        intent = nil
        related = []
        notes = []
        body = []
        section = nil
        nodes.each do |node|
          if heading?(node) && level(node) == 2
            section = node.text.strip
            next if section.match?(/\Aintent\z/i) || section.match?(RELATED)
          end
          if section&.match?(/\Aintent\z/i) && !heading?(node)
            if intent.nil? && node.name == "p"
              intent = node
            else
              body << node
              @notes << "intent section has more than one paragraph; the rest stays in the body"
            end
          elsif section&.match?(RELATED) && !heading?(node)
            related.concat(related_slugs(node))
            notes.concat(explained_items(node))
          else
            body << node
          end
        end
        unless notes.empty?
          doc = nodes.first.document
          body << Nokogiri::XML::Node.new("h2", doc).tap { |h| h.content = "Notes on related patterns" }
          list = Nokogiri::XML::Node.new("ul", doc)
          notes.each { |item| list << item }
          body << list
        end
        [intent, related.uniq, drop_empty_sections(body)]
      end

      def related_slugs(node)
        node.css("a[href]").map { |a| a["href"][%r{\A/patterns/([a-z0-9-]+)/\z}, 1] }.compact
      end

      # List items that say more than the link itself; they stay in the body.
      def explained_items(node)
        items = node.name.match?(/\A[uo]l\z/) ? node.css("> li") : [node]
        items.select do |item|
          copy = item.dup
          copy.css("a").each(&:remove)
          copy.text.gsub(/[[:punct:]\s]|\b(and|or|see|also|especially|e\.g)\b/i, "").length > 0
        end.map { |item| item.name == "li" ? item : Nokogiri::XML::Node.new("li", item.document).tap { |li| li << item } }
      end

      def drop_empty_sections(nodes)
        loop do
          empty = nodes.each_index.find do |i|
            next false unless heading?(nodes[i])
            following = nodes[i + 1]
            following.nil? || (heading?(following) && level(following) <= level(nodes[i]))
          end
          break nodes if empty.nil?
          nodes.delete_at(empty)
        end
      end

      # One line per paragraph: wrapping would split link and alt texts.
      def markdown(html)
        doc = Kramdown::Document.new(html, input: "html", html_to_native: true, line_width: 100_000)
        output, = MarkdownWriter.convert(doc.root, doc.options)
        output.delete("​").gsub(/  \n +/, "  \n").gsub(/\n{3,}/, "\n\n").strip + "\n"
      end

      def one_line(text)
        text.gsub(/\s*\n\s*/, " ").strip
      end

      def add_footnotes(body, footnotes)
        return body if footnotes.empty?
        body = body.gsub(/\s*AIMFN(\d+)X/) { "[^#{$1}]" }
        defs = footnotes.each_with_index.map { |text, i| "[^#{i + 1}]: #{text}" }
        "#{body}\n#{defs.join("\n")}\n"
      end
    end
  end
end
