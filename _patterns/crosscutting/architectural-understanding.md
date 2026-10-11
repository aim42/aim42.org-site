---
title: Architectural Understanding
phase: crosscutting
intent: Document relevant structures, concepts, decisions, interfaces etc. of the [system](/glossary/#system) to *locate* issues, risks and opportunities for improvement.
related: [view-based-understanding]
status: complete
---

Develop and document an understanding of internal structures, concepts, architectural approaches and important decisions of the [system](/glossary/#system).

## Description

Collect and organize architectural information about the [system](/glossary/#system): Document structures, concepts, decisions, interfaces etc. of the [system](/glossary/#system) to *locate* issues, risks and opportunities for improvement.

* Business or technical system context, with external interfaces. Learn this from [Context Analysis](/patterns/context-analysis/) or [Infrastructure Analysis](/patterns/infrastructure-analysis/).
* Solution strategy, often to be learnt from [Stakeholder Interview](/patterns/stakeholder-interview/) with experienced developers of the system.
* Building block structure, the static organization of the source code. At least elaborate the highest level of code blocks (level 1 building blocks)
* Runtime structures, like important use-case scenarios. Sometimes this can be learned from [Runtime Analysis](/patterns/runtime-analysis/).
* Infrastructure and deployment, often derived from [Infrastructure Analysis](/patterns/infrastructure-analysis/).
* Cross-cutting and technical concepts, like domain models, persistence, user-interface and other concepts.
* Important architecture and design decisions taken and revoked during development of the system.

## Experiences

Architectural understanding can be gained in small increments, so there is no need to reserve long times just for documentation.

Understanding should come from various sources - see all the [Analyze](/patterns/analyze/) practices.

## Notes on related patterns

* [\[arc42\]](/reference/bibliography/#arc42) provides a free and pragmatic template for software architecture documentation. It’s available in various formats (e.g. Microsoft-Word (tm) and AsciiDoc).
