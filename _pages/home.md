---
title: Architecture Improvement Method
layout: home
permalink: /
# Plain text, one line each. tools/validate.rb checks every slug below.
headline: Improve software systems, systematically.
lede: "aim42 is a free, open method for architects and developers: analyze what hurts, evaluate what it costs, improve what's worth it, step by step."
# The short line under each phase name in the cycle graphic.
cycle:
  analyze: find the issues
  evaluate: value and effort
  improve: fix step by step
  crosscutting: plan and keep on track
# Exactly three pattern slugs (file names in _patterns/) per phase.
examples:
  analyze: [stakeholder-interview, static-code-analysis, root-cause-analysis]
  evaluate: [estimate-issue-cost, estimate-improvement-cost, estimate-in-interval]
  improve: [strangler-approach, anticorruption-layer, introduce-boy-scout-rule]
  crosscutting: [issue-list, improvement-backlog, impact-analysis]
get_started:
  - text: Collect issues.
    patterns: [issue-list, stakeholder-interview]
  - text: Estimate what they cost, and what fixing them would cost.
    patterns: [estimate-issue-cost]
  - text: Improve the most valuable ones first, in small steps.
    patterns: [improvement-backlog]
---

aim42 is free to use and open source, with no vendor or tool lock-in. It is
built from the experience of many contributors from different industries.

Know a practice that's missing? Every pattern is one Markdown file on GitHub.
[Add a pattern](/reference/how-to-add-a-pattern/).
