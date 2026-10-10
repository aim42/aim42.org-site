---
title: View-Based Understanding
phase: analyze
intent: Understand the inner workings and internal (code) structure of of the systems. Document (and communicate) this via architectural views, especially the building-block view.
related: [docs-as-code, context-analysis]
status: complete
---

## Description

* Apply [\[arc42\]](/reference/bibliography/#arc42) views
* Apply [Static Code Analysis](/patterns/static-code-analysis/)
* Interview technical stakeholders
* Start either from the
  * business context, mainly the external business interfaces
  * technical context, the involved hardware and network structure
  * known technology areas, i.e. products, programming languages or frameworks used

![Three main views (building block, runtime and deployment view)](/images/patterns/view-based-understanding.jpg)
{: #figure-view-based-understanding}

## Applicability

Use view-based-understanding when:

* System has a medium to large codebase
* Structural understanding of the code is limited: only few stakeholders can explain and reason about the code structure
* Documentation of the code structure is not existing, outdated or wrong
* Long-term maintenance and evolution of the system is required

## Consequences

* Explicit overview of the system context with the external interfaces.
* Overview of the larger units of source-code (subsystems, high-level components) and their relationships.

## Also Known As

* building block view (formerly known as logical view)
* high-level overview

## References

* [\[arc42\]](/reference/bibliography/#arc42)
* [4+1 architectural view model](https://en.wikipedia.org/wiki/4%2B1_architectural_view_model) by Philippe Kruchten
