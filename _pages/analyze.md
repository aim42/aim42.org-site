---
title: "Analyze..."
layout: single
permalink: /analyze
---

![](/images/analyze-phase.png)

{% for page in site.analyze %}

### [{{ page.title }}]({{ page.url }})

{{ page.excerpt }}

{% endfor %}
