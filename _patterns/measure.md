---
title: Measure
phase: improve
categories: [architecture-and-code]
intent: If you don’t measure it, you can’t optimize it. — Coda Hale
related: [runtime-artifact-analysis, instrument-system]
status: complete
---

## Description

TODO: explain different kind of metrics (static-code, runtime, organisational…)

## Risks

If you measure too many different parameters or attributes, you might get drown in numbers.

## Applicability

This pattern should always be considered.

## Also Known As

* quantitative analysis
* quantitative runtime analysis
* profiling
* organisational metrics

## References

* [Coda Hale Talk on "Metrics-Everywhere"](https://www.youtube.com/watch?v=czes-oa0yik)

## Notes on related patterns

* This pattern is an important enabler for a successful [Runtime Artifact Analysis](/patterns/runtime-artifact-analysis/) or performance analysis.
* [Instrument System](/patterns/instrument-system/) and [profiling](https://en.wikipedia.org/wiki/Profiling_(computer_programming)) are very similar to this pattern, however they are limited to a temporary instrumentation that is needed during the Analysis phase to identify or scope a certain problem that cannot be isolated without modifying the code.
