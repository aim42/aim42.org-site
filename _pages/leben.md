---
title: "Leben..."
layout: single
permalink: /leben
---


![]({{ site.url }}/images/splash/leben-splash.png){: width="30%"}


## Das hat VENOM zum Erfolg geführt!

Hier lesen Sie, was VENOM erfolgreich gemacht hat, aus der Perspektive
ganz verschiedener Menschen...


{% for leben in site.leben %}

### [{{ leben.title }}]({{ leben.url }})

{{ leben.excerpt }}

{% endfor %}
