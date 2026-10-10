---
title: aim42 Principles
layout: aim42-page
permalink: /principles
---

## Important Terms
aim42 talks about [issues](/reference/domain-model/#issue), their [causes](/reference/domain-model/#cause) and [risks](/reference/domain-model/#risk),
the [improvements](/reference/domain-model/#improvement) that resolve them, and the [cost](/reference/domain-model/#cost-of-issue) of both.
The [domain model](/reference/domain-model/) defines these terms and shows how they relate.

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
