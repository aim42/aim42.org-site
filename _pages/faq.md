---
title: "Leiden..."
layout: single
permalink: /leiden
---

![]({{ site.url }}/images/splash/leiden-splash.png){: width="30%"}

Wie ein ehemals erfolgreiches, flexibles und gut strukturiertes System
innerhalb weniger Jahre zu einem unwartbaren Monster mutieren kann?

Wie eine motivierte Gruppe produktiver Softwareentwickler zu einem Schatten
ihrer selbst degradiert?

Wie die Stabilität von VENOM immer mehr abnimmt, obwohl doch die _Kinderkrankheiten_
allmählich beseitigt sein müssten...

Viele Faktoren führten SAMM Inc. und VENOM in dieses _Tal der Tränen_.


## Mehr Infos

{% for leiden in site.leiden %}

## [{{ leiden.title }}]({{ leiden.url }})

{{ leiden.excerpt }}

{% endfor %}
