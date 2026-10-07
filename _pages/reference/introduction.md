---
title: Introduction
layout: aim42-page
permalink: /reference/introduction/
lede: What aim42 is, why software needs systematic improvement, and how its three phases work together iteratively.
---

## Overview

aim42 organizes software improvement in three major phases ([Analyze](/patterns/analyze/), [Evaluate](/patterns/evaluate/) and [Improve](/patterns/improve/)), build around some [crosscutting](/patterns/crosscutting/) activities.

![Three Phases of aim42](/images/patterns/aim42-phases.png)

<table>

<tbody>
<tr>
<td>
<strong>Analyze</strong> <br />
Identify problems and improvement options</td>
<td>
<strong>Evaluate</strong><br />
Estimate cost or value of issues and improvements</td>
<td>
<strong>Improve</strong><br />
Apply or perform selected improvements</td>
</tr>
<tr>
<td>Understand the system</td>
<td>Estimate issue cost:
How grave is this problem?</td>
<td>Improve architecture and code</td>
</tr>
<tr>
<td>Find issues and risks</td>
<td>Estimate improvement cost:
How expensive is this change?</td>
<td>Improve processes</td>
</tr>
<tr>
<td>Collect improvement options</td>
<td>Usually "evaluation" means <em>estimation</em>
</td>
<td>Improve technology</td>
</tr>
<tr>
<td>Interview stakeholders</td>
<td>Estimate in intervals</td>
<td>Improve (technical) concepts</td>
</tr>
<tr>
<td>Analyze context</td>
<td>Evaluate tradeoffs</td>
<td></td>
</tr>
<tr>
<td>Analyze architecture and code</td>
<td></td>
<td></td>
</tr>
<tr>
<td colspan="3">
<strong>Crosscutting</strong><br />
Manage issues, improvement and their relationships</td>
</tr>
<tr>
<td colspan="3">Manage issues (risks, problems, symptoms, root-causes)</td>
</tr>
<tr>
<td colspan="3">Manage improvements</td>
</tr>
<tr>
<td colspan="3">Manage the (m:n) relationships between issues and improvements</td>
</tr>
<tr>
<td colspan="3">Plan improvements, interleaved with to day-to-day activities</td>
</tr>
<tr>
<td colspan="3">Verify improvements (check if improvements resolved appropriate issues)</td>
</tr>
<tr>
<td colspan="3"></td>
</tr>
</tbody>
</table>

## Why is software being changed?

Software systems, at least most of those that are practically used, are changed all the time. Features are added, modified or removed, user interaction is streamlined, performance is tuned, changes to external interfaces or systems are reflected. The reasons for changing a system can be grouped into four categories (see [\[ISO-14764\]](/reference/bibliography/#iso-14764)):

* Corrective changes
  * fixing failures within the software system

* Adaptive changes
  * data structures we rely on have been changed
  * external interfaces have been changed - our system has to cope with these changes
  * some technology, framework or product used within the system is not available any longer and needs to be replaced

* Perfective changes
  * operational costs have to be reduced
  * maintenance costs have to be reduced
  * existing documentation does not reflect the truth (any more)
  * resource consumption needs to be optimized
  * system needs to work faster
  * system needs to become more reliable or fault-tolerant
  * people need new features
  * system needs to be integrated with *new neighbour*
  * system needs to comply to new regulations or laws
  * system needs new or improved user interface
  * existing features have to be modified or removed

* Preventive changes
  * technical debt has to be reduced

You see - lots of good reasons :-)

## Why does software need improvement?

The most important reason is depicted in the following diagram: The cost-of-change of most software increases heavily over time… making those people really unhappy that have to pay for these changes (called maintenance, evolution, new-features or else).

An additional effect of long-term maintenance of software is the strong *decrease in understandability*: When a system matures it becomes more and more difficult to understand its inner workings, changes become increasingly risky and consequences of changes become difficult to foresee which can lead to quite blurry effort estimations.

![Reality: Maintaining software is too expensive](/images/patterns/cost-of-change.jpg)
{: #figure-real-situation}

These negative effects share a few common root causes:

1.  lack of *conceptual integrity*
2.  *internal disorder*
3.  overly *complex internal structure*, either of source code or data
4.  overly *complex concepts* (cross-cutting solutions for fine-grained problems)
5.  overly complex or inappropriate internal processes
6.  inappropriate selection of *technology* (*frameworks, libraries or languages*)
7.  (you surely can find a few more…)

### Long-term Goal

In the beginning, though, everything was fine: nice coupling and cohesion, appropriate technologies, well written code, understandable structures and concepts (see figure [Goal: Maintainable Software](/reference/introduction/#figure-target-situation))

But as more and more changes, modifications, tweaks and supposed *optimizations* were performed under growing time and budget pressure, things got nasty. The maintainers piled up so called *technical debt* (we software folks call it quick-hacks, quick-and-dirty-fixes, detours or abbreviations). We’re quite sure you know what we’re talking about - we experienced it over and over again, it seems to be the normal situation, not the (bad) exception.

Investment in methodical and systematic software architecture improvement will have the following effect.

![Goal: Maintainable Software](/images/patterns/target-situation.jpg)
{: #figure-target-situation}

## How does aim42 work?

### Three Simple Phases

aim42 works in a phased iterative manner:

![Three Phases of aim42](/images/patterns/aim42-phases.png)
{: #figure-aim-phases}

1.  [Analyze](/patterns/analyze/): collect *issues*: problems, risks, deficiencies and technical debt within your system and your development process. Focus on problems in this phase, not on potential solution approaches. In addition, develop (and document) an understanding of internal structures, concepts and architectural approaches.
2.  [Evaluate](/patterns/evaluate/): determine the "value" of issues and their solutions (*improvements*)
3.  [Improve](/patterns/improve/): systematically improve code and structures, reduce technical debt, remove waste and optimize.

These three phases are performed iteratively - as explained [below](/reference/introduction/#iterative-approach). Several [cross-cutting practices and patterns](/patterns/crosscutting/) should be applied in all phases, for example documenting results, [Collect Opportunities for Improvement](/patterns/collect-opportunities-for-improvement/) or long- and short-term planning activities.

### Common Terminology

aim42 relies on a common terminology, a small set of fundamental concepts.

![aim42 domain terminology](/images/patterns/aim42-concept-map.png)
{: #figure-fundamental-concepts}

| **Issue** | Any problem, error, fault, risk, suboptimal situation or their causes within the [system](/glossary/#system) or processes related to it (e.g. management, operational, development, administrative or organizational activities). |
| **Cause** | Fundamental reason for one or several issues. |
| **Improvement** | Solution, remedy or cure for one or several issues. |
| **Cost (of issue)** | The cost (in any unit appropriate for business, e.g. money, effort or such) of the issue, related to a frequency or period of time. For example – cost of every occurrence of the issue or recurring cost per week. |
| **Cost (of improvement)** | The cost (in monetary units) of the improvement, remedy, tactic or strategy. |
| **Risk** | *Potential* problem. Improvements can change associated risks for the better or the worse, even create new risks. |

See also the more detailed [Domain Model](/reference/domain-model/) (not required for the casual reader)

### Iterative Approach   {#iterative-approach}

In compliance with modern agile development methodologies, aim42 fundamentally depends on iteration and feedback between the phases.

Within each phase, you collect both issues and opportunities for improvement, as depicted in the illustration below:

![Iterate and Collect](/images/patterns/collect-issues-improvements.png)
{: #figure-iterate-and-collect}

Issues and improvements need to be

* related to each other: No idea of improvement without an existing issue - as we do not want to optimize "because we can".
* evaluated in some business-compatible unit (e. g. Euro, $) as described above. See [Evaluate](/patterns/evaluate/).

## Patterns and Practices Provide No Guarantee

We are **very** sure that aim42 can work for your system or your organization. But (yes, there’s always a but) we cannot guarantee: Maybe your software is so **extraordinary**, so very special, that it needs other treatments.

Maybe your organization does not fit our prerequisites or is way more advanced than we anticipated in our approach…

You have to use all practices, patterns and approaches of aim42 at your own risk and responsibility. We (the aim42 contributor team) can by no means be held responsible for any results of applying aim42.
