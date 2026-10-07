---
title: Improve
layout: aim42-page
section: improve
eyebrow_label: Phase
eyebrow_href: /patterns/
permalink: /patterns/improve/
lede: Apply approaches and practices that eliminate issues, reduce technical debt and optimize quality.
---

## Goals

1. Execute and coordinate the improvement activities to eliminate problems and
   issues found during [analysis](/patterns/analyze/). There is a whole bunch
   of practices devoted to this step, and several approaches you can take to
   run the improvements.
2. Apply selected opportunities for improvement:
   * change code, structures, concepts or processes to achieve better software,
   * reduce costs and/or technical debt,
   * eliminate all kinds of issues,
   * optimize quality attributes (like performance, maintainability, security),
   * optimize operation and administration processes, thereby reducing effort
     and cost.

## Structure of the improvement phase

*Fundamentals* are principles you should consider whatever steps you take on
your road to improvement. *Approaches* are overall (strategic, long-term)
decisions on how to tackle improvement. *Practices* are fine-grained practices
or patterns, structured in several categories.

## Fundamentals   {#improve-fundamentals}

For improvement we take a number of fundamental principles for granted, depicted in [Fundamentals](/patterns/improve/#improve-fundamentals).

![Improvement Fundamentals - Overview](/images/patterns/improve-fundamentals.png)

These fundamental principles surely belong to software engineering good practices - but we consider them indispensable for improvement projects.

Fast-Feedback
: Get feedback to your actions and changes as early as possible, so you can adjust as quickly as adequate.

Improve Iteratively
: Improve in (potentially small) iterations and/or increments, so that change does not disturb or negatively affect the system, its associated processes and organization. Iterations are the prerequisite for our whole *phased improvement*.

Prototype-Improvement
: Verify the viability and effectiveness of improvements, usually in smaller scales with reasonable risks.

Verify-After-Every-Change
: Always make sure that changes, even minor ones, leave your system intact. (The awesome Jerry Weinberg has written up several [examples of such failures](http://secretsofconsulting.blogspot.de/2015/01/some-very-expensive-software-failures.html)).

Reduce Complexity
: Simpler solutions are most often easier to comprehend, maintain and operate. Therefore always strive for simplicity and the reduction of accidental, unnecessary complexity.

Explicit Assumption
: Compensate missing facts (especially requirements, goals, estimates, opinions) by explicit (written) assumptions about those facts. See [Explicit Assumption](/patterns/explicit-assumption/).

Group Improvement Actions
: Group related actions, so that they refer to similar entities and potential synergies are utilized.

## Improvement Approaches (Overview)   {#improve-approaches-overview}

![Categories of Improvement Approaches](/images/patterns/improve-approaches-categories.png)

Data Migration
: Keep your (valuable) data, and toss (or rewrite or otherwise change) your code. Oftentimes combined with approaches from the categories *rewrite* or *restructure*.

Rewrite
: Your system is *broken beyond repair* and you need to completely replace it by a new one. Rewrite approaches give you some ideas how and if that might work (spoiler: we fear that Big-Bang won’t work…)

Restructure
: Improve your system by restructuring your code *in-the-large*. Might involve extraction of certain functionalities, splitting your system, improving the modularization or strangulating certain (bad) parts of the system (and, of course, replacing those by better solutions).

Improve Modularization
: Subcategory of *restructure*: improve responsibilities within the system, improving the boundaries between components, improving interfaces and similar operations.

Brainsize
: Evidence from neuroscience suggests our working memory has a capacity of about four items[^1]. That’s why smaller solutions tend to be more maintainable, as the cognitive load on the developers working memory is reduced. These "brainsizing" strategies can be used to reduce the amount of *stuff*, e.g. by splitting your system up, extracting certain parts into abstractions, or other ways to reduce LOC or other complexity metrics. Terms like *microservices* fall into this category.

Improve-Domain-Focus
: Subcategory of *restructure*:Clear separation of domain-related code from purely technical aspects has long been a useful design heuristic - but is still often violated. In addition, aspects belonging to similar areas of the domain should be implemented within the same building-blocks (in Domain-Drive Design terminology called *Bounded Context*).

You find further information on the [detailed approaches here](/patterns/improve/#improve-approaches-details).

## Improvement Practices (Overview)   {#improve-practices-overview}

![Categories of Improvement Practices](/images/patterns/improve-practice-categories.png)

Improve Processes and Organization
: Sometimes your issues originate in process or organizational root causes, meaning your development, rollout or operations processes are less efficient than they should be. This category adresses such problems. For details see [Practices to Improve Processes](/patterns/improve/#improve-processes).

Improve Architecture and Code Structure
: All aspects of sourcecode may be subject to improvement - style, structure, dependencies, conventions, naming and the like. Furthermore, structure *in the large* (modules, components, interfaces) or crosscutting and technical concepts belong to this area of improvement. For details see [Improve Architecture and Code Structure](/patterns/improve/#improve-architecture).

Improve Technical Infrastructure
: Technical infrastructure encompasses both underlying hardware and software. For details see [Practices to Improve Technical Infrastructure](/patterns/improve/#improve-technical-infrastructure).

Improve Analyzability and Evaluatability
: Make the system easier to analyze and understand, e.g. by improving logging, tracing or by introducing clearer structures. Enable or facilitate evaluation (e.g. of certain issues) by creating, collecting and managing certain numbers (*metrics*), either in development-, deploy- or runtime. For details see [Practices to Improve Analyzability and Evaluability](/patterns/improve/#improve-analyzability).

## Approaches, Practices and Regular Development

In regular development (sometimes known as *daily business*) you will most likely intertwine your approach(es) with numerous practices - as depicted in [Integrating improvement approaches and practices with regular development](/patterns/improve/#fig-relation-of-approaches-practices).

In both long- and short-term planning (yes - even in highly agile and iterative development models you’ll have such planning) you need to balance the following often conflicting goals:

* short-term profitability by creating business value by delivering features or fixes to production.
* long-term maintainability of the system by improving inner quality, improving code structure, technology choices and the like.

![Integrating improvement approaches and practices with regular development](/images/patterns/integrate-improve-with-daily-business.png)
{: #fig-relation-of-approaches-practices}

## Improvement Approaches (Details)   {#improve-approaches-details}

One of the central decisions involves your long-term improvement-approach, the overall, long-range or **strategic** decision how you want to improve your system.

![Improvement Approaches](/images/patterns/improve-approaches-all.png)
{: #fig-improve-approaches}

TODO: Describe Approaches

Change-By-Split
: Split up the original system into (not neccessarily distinct) parts. Clean-up those parts individually, and then evolve the parts independently.

Keep-Data-Toss-Code
: As value sometimes resides in data, keep data intact and replace the functional/service/process part of a system.

Frontend-Switch
: Start creating new backend parts. Frontend routes some requests to those new backend parts, others still to the existing ones. Gradually enhancing the new backend parts, frontend routes more and more requests to new backend.

Big-Bang
: Keep the existing system for a limited time, apply only critical bugfixes. In parallel, build a replacement system. Replace old by new at predefined time.

Chicken-Little
: Incrementally (11 steps) build a replacement system. You can choose between Database-First, Database-Last and Composite-Database Approach.

Database-First
: Do a Big-Bang migration of the database, incrementally implement new applications and interfaces and connect the legacy system to the new database by forward gateways.

Database-Last
: Keep the existing database for a limited time, incrementally implement new applications and interfaces and connect them to the legacy database by reverse gateways.

Composite-Database
: Combination of Database-First and Database-Last. Beside a forward- and reverse-gateway, there is a need for a transaction-coordinator.

Butterfly-Methodology
: Data-Migration Method without the need for gateways. Enables zero-downtime migrations by working with temporary data stores.

Evolution
: This approach has been extensively practiced by a Swiss Bank and published as a [book](http://www.amazon.de/Managed-Evolution-Strategy-Information-Systems/dp/3642016324). Underlying idea is to refactor those parts of the system(s) which are actually to be changed, especially to move all interfaces to new service standard and replace all legacy technologies and other couplings (via DB etc). Over time services should emerge that can be moved to a new platform altogether (from Mainframe to Java).

## Improvement Practices (Details)   {#improve-practices}

Practices, in contrast to approaches, are the short-term or tactical improvements.

We already explained the categories of these improvement practices in [Improvement Practices (Overview)](/patterns/improve/#improve-practices-overview). Here we dive into more details, structured along these categories:

* Improve Processes,see [Practices to Improve Processes](/patterns/improve/#improve-processes)
* Improve Architecture and Code Structure, see [Improve Architecture and Code Structure](/patterns/improve/#improve-architecture)
* Improve Technical Infrastructure, see [Practices to Improve Technical Infrastructure](/patterns/improve/#improve-technical-infrastructure)
* Improve Analyzability, see [Practices to Improve Analyzability and Evaluability](/patterns/improve/#improve-analyzability)

## Practices to Improve Processes   {#improve-processes}

![Practices to improve processes](/images/patterns/improve-practice-processes.png)
{: #fig-improve-processes}

For an overview of other improvement practices, see [Improvement Practices (Overview)](/patterns/improve/#improve-practices-overview).

One way to improve the processes is to resort to [Mob Programming](https://mobprogramming.org) for onsite teams or [Remote Mob Programming](https://www.remotemobprogramming.org) for distributed teams.

## Improve Architecture and Code Structure   {#improve-architecture}

> **Note:** This category contains a fairly large number of practices.

![Practices to improve architecture and code structure](/images/patterns/improve-practice-architecture.png)
{: #fig-improve-architecture}

For an overview of other improvement practices, see [Improvement Practices (Overview)](/patterns/improve/#improve-practices-overview).

## Practices to Improve Technical Infrastructure   {#improve-technical-infrastructure}

![Practices to improve technical infrastructure](/images/patterns/improve-practice-technical-infrastructure.png)
{: #fig-improve-technical-infrastructure}

For an overview of other improvement practices, see [Improvement Practices (Overview)](/patterns/improve/#improve-practices-overview).

## Practices to Improve Analyzability and Evaluability   {#improve-analyzability}

![Practices to improve analyzability](/images/patterns/improve-practice-analyzability.png)
{: #fig-improve-analyzability}

For an overview of other improvement practices, see [Improvement Practices (Overview)](/patterns/improve/#improve-practices-overview).

[^1]: Cowan: The magical number 4 in short-term memory: a reconsideration of mental storage capacity.

## Approaches and practices for improvement

{% include aim42/pattern-list.html phase="improve" %}
