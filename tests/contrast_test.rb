# WCAG 2.x contrast of the aim42 palette tokens in _sass/base/_variables.scss.
require "minitest/autorun"

class ContrastTest < Minitest::Test
  VARS = File.read(File.expand_path("../_sass/base/_variables.scss", __dir__))

  def token(name)
    VARS[/^\$#{Regexp.escape(name)}:\s*(#[0-9a-fA-F]{6})\s*;/, 1] or flunk "token $#{name} not found as a hex literal"
  end

  def luminance(hex)
    r, g, b = hex[1..].scan(/../).map do |c|
      v = c.hex / 255.0
      v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055)**2.4
    end
    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  def contrast(a, b)
    hi, lo = [luminance(a), luminance(b)].sort.reverse
    (hi + 0.05) / (lo + 0.05)
  end

  def assert_contrast(fg, bg, min)
    ratio = contrast(token(fg), token(bg))
    assert ratio >= min, "#{fg} on #{bg}: #{ratio.round(2)}:1 is below #{min}:1"
  end

  def test_phase_text_colors_are_readable_on_paper
    %w[analyze evaluate improve crosscutting].each do |phase|
      assert_contrast("phase-#{phase}-text", "brand-paper", 4.5)
    end
  end

  # The home page shows phase names and links on the white page background too.
  def test_phase_text_colors_are_readable_on_white
    %w[analyze evaluate improve crosscutting].each do |phase|
      ratio = contrast(token("phase-#{phase}-text"), "#ffffff")
      assert ratio >= 4.5, "phase-#{phase}-text on white: #{ratio.round(2)}:1 is below 4.5:1"
    end
  end

  def test_body_text_is_readable_on_paper
    assert_contrast("brand-ink", "brand-paper", 7.0)
    assert_contrast("brand-muted-strong", "brand-paper", 4.5)
  end

  def test_header_text_is_readable_on_primary
    assert_contrast("brand-cream", "brand-primary", 4.5)
  end

  def test_stub_badge_text_is_readable
    assert_contrast("brand-ink", "phase-crosscutting", 4.5)
  end
end
