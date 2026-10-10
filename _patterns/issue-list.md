---
title: Issue List
phase: crosscutting
intent: Collect all known issues and problems within a system or its associated processes. Make the issues comparable by evaluating each one, usually using economical units like money or time.
status: complete
---

A collection of issues (problems, risks) found during [Collect Issues](/patterns/collect-issues/).

## Content

*Issue List*

| ID | Issue | Description | Frequency | min Value | max Value | Improvements |
|---|---|---|---|---|---|---|
| identifier | name | a short description of the issue | how often does the issue occur, once, daily, weekly, with every new feature? | minimal value | maximal value | links to improvements |

## Representation and Tools

It’s difficult to decide how much formalism to apply in collecting issues and problems: Sometimes a wiki page might suffice, for other systems a full-blown issue tracker can be useful.

As always: documentation is only valuable if it can be found easily, which makes electronic approaches more viable.

For every entry in this issue list we need to [Estimate Issue Cost](/patterns/estimate-issue-cost/), an estimation of the cost of this issued in any business-related unit.

In case you already have identified or developed [opportunities for improvement](/patterns/collect-opportunities-for-improvement/) addressing this issue, links to the corresponding improvements (remedies, tactics, strategies, changes) in the [Improvement Backlog](/patterns/improvement-backlog/) are necessary.
