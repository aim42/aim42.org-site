---
title: Evaluate
layout: aim42-page
section: evaluate
eyebrow_label: Phase
eyebrow_href: /patterns/
permalink: /patterns/evaluate/
lede: Make issues and remedies comparable by estimating their value, cost and risk, then prioritize.
---

## Goals

Make the issues, problems and risks found during [analysis](/patterns/analyze/)
comparable by estimating or measuring their *value* (that's why we call this
activity *evaluate*):

1. estimate the *value* of problems, issues, risks and their remedies,
2. prioritize issues, their remedies and improvement measures.

Usually, evaluation implies *estimation*; only in few cases can you measure or
observe the evaluation subject and produce *hard facts*.

## Estimation

![Evaluation Concepts Domain Model](/images/patterns/evaluate-domain-conceptmap.png)
{: #figure-evaluation-concepts}

*Evaluation Domain Concepts*

| Domain concept | Explanation | Example |
|---|---|---|
| Estimation | an *approximation* of any subject (here: issues, problems or remedies), which is needed because facts or real observations are not available or possible. |  |
| Subject |  | a recurring problem in the [system](/glossary/#system) or associated processes |
| Parameter | an important element or foundation of the estimation. | • number of developers on the system<br>• Lines-of-Code (LOC) |
| Assumption | a fixed setting for any parameter. See [Explicit Assumption](/patterns/explicit-assumption/) |  |
| Observation | measure, count, calculate gather real data for parameters | if every developer is concerned by the problem, we count their number. |
| Interval | see [Estimate in Interval](/patterns/estimate-in-interval/) | between 15% and 25% |

## Patterns and practices for evaluation

![concept map of the evaluate patterns](/images/patterns/evaluate-patterns-conceptmap.png)

{% include aim42/pattern-list.html phase="evaluate" %}
