---
title: "Using aim42"
layout: single
permalink: /using
header:
  overlay_image: /images/aim42-splash.png
  excerpt: "**Software improvement,<br>done right**"
sidebar:
  nav: "docs"

---

Here you find an extract of the method - the most essential patterns and practices.

You can apply aim42 to all kinds of situations - it's simple to integrate
into day-to-day development work.



{% for apply in site.apply %}

### [{{ apply.title }}]({{ apply.url }})

{{ apply.excerpt }}

{% endfor %}
