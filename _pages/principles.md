---
title: aim42 Principles
layout: aim42-page
permalink: /principles
---

## Important Terms
Let's clarify some fundamental terms:

![aim42 Domain Model](/images/aim42-concept-map.png)

| Term   | Meaning |
|--------|---------|
|Issue | Any problem, error, fault, risk, suboptimal situation or their causes within the system or processes related to it (e.g. management, operational, development, administrative or organizational activities). |
|Cause | Fundamental reason for one or several issues. |
|Improvement | Solution, remedy or cure for one or several issues.|
|Cost (of issue) | Simply said: The degree of pain this issue causes. More formal: The cost (in any unit appropriate for business, e.g. money, effort or such) of the issue, related to a frequency or period of time. For example – cost of every occurrence of the issue or recurring cost per week.|
|Cost (of improvement) | The cost (in monetary units) of the improvement, remedy, tactic or strategy.|
|Risk | _Potential_ problem. Improvements can change associated risks for the better or the worse, even create new risks.

The [method reference](/reference/introduction/#common-terminology) covers these terms in more detail, and provides a more elaborate [domain model](/reference/domain-model/).

## Fundamental Principles

#### Separate issues from improvements
When hitting any problem, don't immediately start solving it, but methodically analyze and evaluate it beforehand. Compared to other issues, this specific problem might not be economically relevant... (you won't know before you compared it to other problems).

#### Improve only _relevant_ issues
_Relevance_ is relative to stakeholders - one issue seems huge for developers, but is neglectable from managements' perspective.

aim42 proposes the [EVALUATE](/patterns/evaluate/) phase to methodically prioritize issues and improvements.

#### Improve iteratively, with early and fast feedback
Improving systems always implies change, often on both technical and organizational levels. Such operations
are inherently difficult, and only a few of their consequences might be anticipated.

Therefore you should _bake_ iteration and feedback into your improvement approach, regardless of the detailed or concrete approach.

#### Explicit assumptions
Other people often see the world (especially the system and related processes) from a different angle, and might have different mental models
or opinions on these aspects.

Therefore, always make your assumptions about _things_ explicit:

* what exactly makes up this issue (problem, risk...)?
* what exactly do you mean by that improvement option?
* what are your assumptions regarding the cost of this issue?
* what factors influence the cost of this issue?

aim42 has some more info on [explict assumptions](/patterns/explicit-assumption/)
