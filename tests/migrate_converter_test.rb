require "minitest/autorun"
require_relative "../tools/migrate/adoc_to_md"
require_relative "../tools/migrate/anchors"

class MigrateConverterTest < Minitest::Test
  PATTERN = <<~ADOC
    [[Some-Pattern]]
    ==== [pattern]#Some Pattern#
    Lede about the <<System>>.

    ===== Intent
    Do _this_ with <<Stakeholder-Analysis>>.

    ===== Description
    See <<Stakeholder-Analysis,the analysis>> and <<Unknown-Thing>>.

    ====== Detail
    He said "hi".

    ===== Applicability

    ===== Related Patterns
    * <<Stakeholder-Analysis>>
  ADOC

  def anchors
    table = Aim42::Migrate::Anchors.new
    table.add("Stakeholder-Analysis", "/patterns/stakeholder-analysis/", link_text: "Stakeholder Analysis")
    table.add("System", "/glossary/#system", link_text: "system")
    table.add("Nygard07", "/reference/bibliography/#nygard07")
    table
  end

  def convert(adoc, self_url: "/patterns/some-pattern/")
    Aim42::Migrate::AdocToMd.new(anchors).convert(adoc, self_url: self_url)
  end

  def test_title_comes_from_the_top_heading
    assert_equal "Some Pattern", convert(PATTERN).title
  end

  def test_intent_is_one_line_of_inline_markdown
    assert_equal "Do *this* with [Stakeholder Analysis](/patterns/stakeholder-analysis/).", convert(PATTERN).intent
  end

  def test_sections_become_h2_and_title_and_intent_leave_the_body
    body = convert(PATTERN).body
    assert_includes body, "## Description\n"
    assert_includes body, "### Detail\n"
    refute_includes body, "Some Pattern"
    refute_match(/^#+ Intent/, body)
  end

  def test_the_lede_stays_at_the_top_of_the_body
    assert convert(PATTERN).body.start_with?("Lede about the [system](/glossary/#system).\n")
  end

  def test_empty_sections_are_dropped
    refute_includes convert(PATTERN).body, "Applicability"
  end

  def test_a_bare_related_list_becomes_front_matter_only
    result = convert(PATTERN)
    assert_equal ["stakeholder-analysis"], result.related
    refute_includes result.body, "Related"
  end

  def test_related_items_with_explanations_stay_in_the_body
    result = convert("== [pattern]#P#\n\n=== Related Patterns\n\n* <<Stakeholder-Analysis>>, to find people.\n* <<Stakeholder-Analysis>>\n")
    assert_equal ["stakeholder-analysis"], result.related
    assert_equal "## Notes on related patterns\n\n* [Stakeholder Analysis](/patterns/stakeholder-analysis/), to find people.\n", result.body
  end

  def test_xrefs_use_the_target_title_or_their_own_text
    body = convert(PATTERN).body
    assert_includes body, "See [the analysis](/patterns/stakeholder-analysis/)"
  end

  def test_unresolved_xrefs_become_plain_text_and_are_reported
    result = convert(PATTERN)
    assert_includes result.body, "and Unknown-Thing."
    assert_includes result.notes, "unresolved xref: Unknown-Thing"
  end

  def test_links_to_the_page_itself_become_plain_text
    result = convert("== [pattern]#P#\n\n=== Description\n\nSee <<Stakeholder-Analysis>>.\n", self_url: "/patterns/stakeholder-analysis/")
    assert_equal "## Description\n\nSee Stakeholder Analysis.\n", result.body
  end

  def test_links_to_sections_of_the_same_page_use_kramdown_ids
    body = convert("== [pattern]#P#\n\n=== Description\n\nSee <<Data Size>>.\n\n=== Data Size\n\nBig.\n").body
    assert_includes body, "See [Data Size](#data-size)."
  end

  def test_quotes_are_not_escaped
    assert_includes convert(PATTERN).body, %(He said "hi".)
  end

  def test_block_image_uses_its_title_as_alt_text
    result = convert("== [pattern]#P#\n\n=== Description\n\n.The big picture\nimage::approaches/big.png[\"ignored\"]\n")
    assert_includes result.body, "![The big picture](/images/patterns/approaches/big.png)"
    assert_equal ["approaches/big.png"], result.images
  end

  def test_admonitions_become_labelled_quotes
    assert_includes convert("== [pattern]#P#\n\n=== Description\n\nTIP: Start small.\n").body, "> **Tip:** Start small."
  end

  def test_tables_become_pipe_tables
    adoc = "== [pattern]#P#\n\n=== Description\n\n[options=\"header\"]\n|===\n| Name | Value\n| a | 1\n|===\n"
    assert_includes convert(adoc).body, "| Name | Value |\n|---|---|\n| a | 1 |\n"
  end

  def test_footnotes_become_kramdown_footnotes
    body = convert("== [pattern]#P#\n\n=== Description\n\nTrue footnote:[Mostly.].\n").body
    assert_includes body, "True[^1]."
    assert body.end_with?("[^1]: Mostly.\n")
  end

  def test_listings_become_fenced_code_with_language
    adoc = "== [pattern]#P#\n\n=== Description\n\n[source,java]\n----\nint x = 1;\n----\n"
    assert_includes convert(adoc).body, "```java\nint x = 1;\n```\n"
  end

  def test_download_links_point_to_assets
    body = convert("== [pattern]#P#\n\n=== Description\n\nlink:./docs/Form.pdf[pdf version^]\n").body
    assert_includes body, "[pdf version](/assets/downloads/Form.pdf)"
  end

  def test_explicit_anchors_survive_as_ids
    adoc = "== Improve\n\n[[improve-approaches-overview]]\n=== Approaches\n\nText.\n\n[bibliography]\n* [[[Nygard07]]] Michael Nygard: Release It!\n"
    body = convert(adoc, self_url: "/patterns/improve/").body
    assert_includes body, "## Approaches   {#improve-approaches-overview}"
    assert_includes body, "* {: #nygard07} \\[Nygard07\\] Michael Nygard: Release It!"
  end
end
