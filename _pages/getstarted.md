---
title: Get started
layout: aim42-section
permalink: /getstarted
---

## Elevator Pitch

Most software lives longer than planned, and every year changes get slower and riskier.
aim42 helps you improve such systems systematically: find the issues that hurt most,
estimate what they cost, and fix them in the order that pays off.

{% assign stubs = site.patterns | where: "status", "stub" -%}
The [method reference](/patterns/) describes {{ site.patterns.size | minus: stubs.size }} proven practices and patterns in detail,
from [stakeholder interviews](/patterns/stakeholder-interview/) to the [strangler approach](/patterns/strangler-approach/),
and names {{ stubs.size }} more that still [need writing](/contribute).
aim42 is free to use under the [Creative Commons BY-SA 4.0](/license) license.

## Overview

aim42 works in three phases, analyze, evaluate and improve, repeated in short iterations;
cross-cutting practices keep the work on track. Each part of the cycle leads to its phase.

{% assign home = site.pages | where: "url", "/" | first -%}
<div class="getstarted-cycle">
{% include aim42/cycle.html notes=home.cycle %}
</div>
