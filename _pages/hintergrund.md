---
title: "Hintergrund"
layout: single
permalink: /hintergrund
---

### Zu Beginn war alles gut

Obwohl anfänglich alles sauber entwickelt und
entworfen war, degenerieren Systeme über die Zeit – das Phänomen der
„verfaulenden Software“ schlägt zu. Änderungen werden schwieriger,
riskanter und dauern immer länger. In Entwicklung und Betrieb treten vermehrt
Probleme auf, deren Behebung mehr und mehr Zeit und Ressourcen in Anspruch
nimmt. Damit einher steigen Änderungs- und Betriebskosten.

### Unterschiedliche Gründe

Für solche misslichen Situationen zeichnen ganz unterschiedliche Gründe
verantwortlich – einige verbreitete Beispiele:

1. Mangelnde konzeptionelle Integrität: identische Probleme werden innerhalb
   eines Systems unterschiedlich gelöst, es gibt mehrere unterschiedliche,
   teils widersprüchliche Lösungsansätze.
2. Übermäßige strukturelle Komplexität, umständliche Konzepte oder Abläufe
   innerhalb des Systems.
3. Schlechter Quellcode, der beispielsweise Grundlagen des Clean Code
   verletzt, unter zu hoher Kopplung oder niedriger Kohäsion leidet, gegen
   Coding-Konventionen verstößt, Redundanzen enthält oder schlicht
   unverständlich ist.
4. Zum fachlichen Problem unpassende Wahl von Technologien, Frameworks oder
   sonstiger Infrastruktur („mit Kanonen auf Spatzen schießen“). Diese Liste
   könnte ich nahezu beliebig weiter führen – und jeder neue Eintrag würde mich
   dabei an eine reale Situation meines bisherigen Berufslebens erinnern.

### Wege in den Abgrund
Zu Beginn vieler Entwicklungsprojekte sieht Software doch recht ordentlich aus:
Motivierte Teams erarbeiten stimmige Konzepte und setzen diese dann
handwerklich sauber um. Konzepte und Technologien passen zum Problem, ebenso
die Daten und Datenstrukturen.

Im Laufe der Zeit jedoch beginnt das Drama: Die ursprüngliche Ordnung weicht
einem ständig steigenden Chaos. Ausnahmen werden zur Regel, Code wird immer
schwerer verständlich, das Entwicklungsteam beginnt von „historisch gewachsen“
zu sprechen – weil kaum jemand nachvollziehen kann, wie es zu dieser
kontinuierliche Verschlechterung kommen konnte.

Durch welche Gründe kommt es dazu? Verlernen Teams über die Zeit das
vernünftige und saubere Arbeiten? Nein – vielmehr zwingen oftmals äußere
Einflüsse zu Kompromissen, die dann langfristig zu den oben genannten Problemen
führen. Neudeutsch nennen Manager dieses Phänomen „technische Schulden“ –
Softwareentwickler bezeichnen diese als Quick-And-Dirty, Hot-Fix, oder
Workaround – und wissen, dass sich dahinter meistens ein weiterer Schritt in
Richtung „degenerierter Systeme“ (*rotten-software*) verbirgt.

### Innere Werte werden vernachlässigt
Ursächlich resultieren diese Probleme in einem mangelnden Bewusstsein für die
innere Qualität von Software. Auftraggeber interessieren sich primär für neue
Features, Erweiterungen oder schnellstmögliche Fehlerbehebung, weniger für den
Erhalt konzeptioneller Integrität, verständlichen Quellcode oder stimmige
Anwendung von Konzepten oder Technologien. Aber gerade diese innere Qualität
von Systemen stellt sicher, Ziele wie niedrige Änderungskosten, schnelle
Fehlerbehebung, hohe Anpassbarkeit zu erreichen. Leider ignorieren immer noch
zu viele IT-Manager diesen kausalen Zusammenhang.

### Systematisch Verbessern
Der Weg zu besserer Software führt in der kommerziellen Realität immer über
mehrere, meist kleine, Schritte zum Ziel. Praktisch niemals können wir den Lauf
der Welt für einige Monate anhalten, um in dieser Zeit die Qualität unserer
Software zu verbessern. Vielmehr müssen wir Verbesserungen in die regulären
Wartungsarbeiten (etwa: Erweiterungen, Fehlerkorrekturen) integrieren.

![](/images/hintergrund/aim42-logo.svg)

Ich möchte Ihnen [aim42](http://aim42.org) vorstellen – eine frei verfügbare Methode zur
systematischen Verbesserung von Software. Basierend auf langjähriger
praktischer Erfahrung wird sie mittlerweile als Open-Source
Projekt durch ein engagiertes Team
[kollaborativ (auf Github) weiterentwickelt](http://aim42.github.io).

> aim42 adressiert Business und Technik gleichermaßen.

Die zentralen Konzepte von aim42 kommen Ihnen garantiert bekannt vor:

* Probleme identifieren (_analyze_),
* Kosten und Risiken dieser Probleme bewerten (_evaluate_)
* passende (Lösungs-)Maßnahmen identifizieren oder entwickeln,
* Maßnahmen mit dem Tagesgeschäft koordiniert umsetzen (_improve_).   

aim42 packt diese Aspekte in einen methodischen Rahmen und stellt sicher,
dass wirklich relevante  Probleme auch
durch Maßnahmen abgedeckt werden – und nicht vorschnell an Themen optimiert
wird, die nur geringen geschäftlichen Nutzen erbringen.


## Mehr Infos

{% for hintergrund in site.hintergrund %}

### [{{ hintergrund.title }}]({{ hintergrund.url }})

{{ hintergrund.excerpt }}

{% endfor %}
