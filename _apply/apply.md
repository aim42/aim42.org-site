---
title: "Apply..."
layout: single
permalink: /apply
---

Here you find an extract of the method - the most essential patterns and practices.

You can apply aim42 to all kinds of situations - it's simple to integrate
into day-to-day development work.

{% for apply in site.apply %}

### [{{ apply.title }}]({{ apply.url }})

{{ apply.excerpt }}

{% endfor %}
