---
title: Patterns and Practices
layout: aim42-page
section: patterns
permalink: /patterns/
lede: aim42 collects proven practices and patterns to analyze, evaluate and improve software systems and the organizations around them.
---

{% assign total = site.patterns | size %}
{% assign stubs = site.patterns | where: "status", "stub" | size %}
{% assign phases = site.data.phases %}

<ul class="phase-list">
{% for entry in phases %}
  {% assign key = entry[0] %}
  {% assign phase = entry[1] %}
  {% assign count = site.patterns | where: "phase", key | size %}
  <li class="phase-card" data-phase="{{ key }}">
    <h2><a href="{{ phase.url | relative_url }}">{{ phase.title }}</a></h2>
    <p>{{ phase.blurb }}</p>
    <p><b>{{ count }}</b> {% if count == 1 %}pattern{% else %}patterns{% endif %}</p>
  </li>
{% endfor %}
</ul>

<p class="section-hero__meta"><b>{{ total }}</b> patterns and practices, of which <b>{{ stubs }}</b> are stubs waiting for contributors. New here? Read the <a href="/reference/introduction/">introduction</a> first.</p>

## All patterns, A–Z

{% include aim42/pattern-list.html %}
