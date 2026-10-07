---
title: Qualitative Analysis
phase: analyze
intent: "Find out (analyze):"
status: complete
---

* whether quality requirements can be met by the system,
* which specific quality requirements are risks with respect to the current architecture,
* which specific quality requirements are currently non-risks

## Description

1.  [Capture quality requirements](/patterns/capture-quality-requirements/) to ensure you have explicit, specific, valid and current *quality requirements* available - preferably in form of *scenarios*.
2.  Prioritize these scenarios with respect to business value or importance for the authoritative stakeholders.
3.  For every important scenario:
    1.  analyze the architectural approach the system takes,
    2.  decide whether this approach seems appropriate or risky

## Experiences

* Conducting workshops with a variety of stakeholders often leads to intense and productive communication.

## Applicability

Use qualitative analysis to support in the following situations:

* You need to analyze which specific quality requirements are at risk and which will most likely be met by the system.
* You have a variety of different stakeholders or groups which can all impose quality requiements - but have not yet agreed on a common set of such requirements.
* A current and understandable collection of specific quality requirements for the system is missing.

## Also Known As

* [ATAM](/patterns/atam/)

## References

* [ATAM](/patterns/atam/). Published by the Software Engineering Institute in numerous whitepapers and books, especially [\[Clements-ATAM\]](/reference/bibliography/#clements-atam).
