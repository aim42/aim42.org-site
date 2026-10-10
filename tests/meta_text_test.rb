require "minitest/autorun"
require_relative "../_plugins/aim42_filters"

class MetaTextTest < Minitest::Test
  def meta(html, length = 160) = Aim42::MetaText.call(html, length)

  def test_strips_tags_and_collapses_whitespace
    assert_equal "Learn from people.", meta("<p>Learn from\n<em>people</em>.</p>\n")
  end

  def test_escapes_exactly_once
    assert_equal "R&amp;D &quot;x&quot;", meta("<p>R&amp;D \"x\"</p>")
  end

  def test_truncation_never_splits_an_entity
    assert_equal "#{"a" * 155} &amp;...", meta("<p>#{"a" * 155} &amp; more</p>")
  end

  def test_text_of_exactly_the_limit_is_kept
    assert_equal "a" * 160, meta("a" * 160)
  end
end
