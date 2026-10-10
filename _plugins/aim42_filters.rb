# Liquid filters of the aim42 layouts.
require "cgi"

module Aim42
  # Plain text for <meta name="description">: tags stripped, entities decoded,
  # whitespace collapsed, cut to `length` characters ("..." included), then
  # escaped once, so a cut can never split an entity like &amp;.
  module MetaText
    module_function

    def call(html, length = 160)
      text = CGI.unescapeHTML(html.to_s.gsub(/<[^>]*>/, "")).gsub(/\s+/, " ").strip
      text = "#{text[0, length - 3]}..." if text.length > length
      CGI.escapeHTML(text)
    end
  end

  module Filters
    # {{ page.intent | meta_description }}: Markdown in, escaped plain text out.
    def meta_description(input)
      converter = @context.registers[:site].find_converter_instance(Jekyll::Converters::Markdown)
      MetaText.call(converter.convert(input.to_s))
    end
  end
end

Liquid::Template.register_filter(Aim42::Filters) if defined?(Liquid::Template)
