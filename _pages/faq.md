---
title: "FAQ"
layout: single
header:
  overlay_image: /images/aim42-splash.png
permalink: /faq

sidebar:
  nav: "learn"

---

{% include toc %}

# Frequently Asked Questions

Here you find answers to some of the frequently asked questions.


## What is aim42?
aim42 is a collection of practices, patterns and methods to support software improvement: In reality, many software systems suffer from a variety of problems, which often cannot be solved due to cost or complexity issues.

aim42 provides a way out of maintenance disasters - it systematically helps to reduce maintenance cost, technical debt and risks. aim42 helps teams and organizations to optimize their software to their specific needs.

aim42 is free (like open-source) - see our [license page](/license).

## Why is refactoring not enough?
Refactoring is a brilliant and important technique to improve source code -
but refactoring is a _local_ (or _tactical_) optimization_. Rarely does refactoring
address _fundamental_ issues with existing systems:

* improper design decisions (like the use of inappropriate technologies)
* broken overall design (e.g. low cohesion, resulting in tight coupling, between larger system components
* ill-designed interfaces
* all kinds of process issues: requirements-elicitation, architecture, test or operations
processes might be overly time-consuming or inefficient.

aim42 proposes an adequate mixture of _global_ and _local_ improvements.  


## Who are the people behind it?
aim42 has been founded by Gernot Starke in 2013, joined by Stefan Tilkov in 2014.
Several others joined - see the current list of [contributors](https://github.com/aim42/aim42/graphs/contributors).

[INNOQ](https://innoq.com) is sponsoring some of the aim42 effort, many contributions
arrive from the community.

aim42 is a team effort - we are actively looking for [contributions](/contribute).

## Where's the code?
Our reference manual is written in AsciiDoc (a plain-text format, ideal for team-collaboration). A ([Gradle](https://gradle.org)
based) build-process generates a static html site ([aim42.github.io](/https://aim42.github.io)) from it.

All the code is located in our [Github repository](https://github.com/aim42/aim42).

## Does it work in reality?
Yes, it does (seriously)!

Although the term aim42 has been coined only in 2013, many of the patterns and practices have been in productive use since several years.

We successfully applied mixtures of those practices at several medium to large systems in different industries.
