---
title: Analyze
layout: aim42-page
section: analyze
eyebrow_label: Phase
eyebrow_href: /patterns/
permalink: /patterns/analyze/
lede: Find issues, risks and technical debt in the system and its organization, and understand their root causes.
---

## Goals

1. Obtain an overview of intent, purpose and quality requirements of the
   [system](/glossary/#system).
2. Develop and document an understanding of internal structures, concepts and
   architectural approaches.
3. Find all problems, issues, symptoms, risks or technical debt within the
   system, its operation, maintenance or otherwise related processes.
4. Understand root causes of the problems found, and potential
   interdependencies between issues.

## How it works

Look systematically for such issues at various places and with support of
various people.

> **Tip:** To effectively find issues, you need an appropriate amount of
> *understanding* of the system under design, its technical concepts, code
> structure, inner workings, major external interfaces and its development
> process.

One serious risk in this phase is a premature restriction to certain artifacts
or aspects of the system: if you search with a microscope, you're likely to
miss several aspects.

![Overview of the most important analysis practices](/images/patterns/analyze-patterns-overview.png)

Always begin with a [Stakeholder Analysis](/patterns/stakeholder-analysis/),
then conduct [Stakeholder Interviews](/patterns/stakeholder-interview/) with
important stakeholders.

Improve your *architectural understanding* of the system by

* context analysis,
* documentation analysis — read especially the architecture documentation,
  focus on view-based understanding,
* development-process analysis,
* static code analysis, to learn about code structure *in the large*; this
  also helps to identify risky code.

Then

* capture quality requirements from the *authoritative* stakeholders of the
  system,
* conduct a qualitative analysis of the system, its architecture and the
  associated organization, based upon the specific quality requirements —
  inspect and analyze all involved organizational processes (development,
  project management, operations, requirements analysis),
* perform runtime analysis or quantitative analysis, e.g. performance and load
  monitoring, process and thread analysis — inspect the data created, modified
  and queried by the system for structure, size, volume or specialities.

Finally, conduct a root cause analysis for the discovered major issues in
close collaboration with the appropriate stakeholders.

> **Warning:** Never start solving problems until you have a thorough
> understanding of the current stakeholder requirements. Otherwise you risk
> wasting effort in areas which no influential stakeholder cares about.

## Patterns and practices for analysis

{% include aim42/pattern-list.html phase="analyze" %}
