---
title: Runtime Analysis
phase: analyze
intent: Analyze the runtime behavior of the [system](/glossary/#system), e.g. with respect to time and resource consumption or creation.
related: [infrastructure-analysis, instrument-system, quantitative-analysis]
status: complete
---

## Description

* Ask stakeholders about *perceived* runtime behavior - double check by measuring.
* Measure runtime behavior, e.g. with profilers, logs or traces.
* Inspect *artifacts* created at runtime (e.g. logfiles, protocolls, system-traces) for information about problems, root-causes or system behavior.
* Perform [Infrastructure Analysis](/patterns/infrastructure-analysis/) to learn about the technical infrastructure.

WARNING
: Measuring might influence behavior. That can be especially disturbing in multi-threaded, multi-user or multi-core applications.
