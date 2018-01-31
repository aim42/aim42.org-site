---
title: Using aim42
layout: single
permalink: /using
header:
  overlay_image: /images/aim42-splash.png
sidebar:
  nav: "getstarted"


---

{% include toc %}


We want to show you how you can get started with aim42 in just a few steps:


### 0. Prerequisites

As you are interested in the **architecture improvement method**, we assume you experienced certain **unpleasantness** with your current system.
The first step is to put this _unpleasantness_ into more concrete words that we can use as a starting point.
We call them **problems and risks** or, more generally,  **issues**.

Please skim over the [principles](/principles) to ensure you understand our terminology.

### 1. Initial brainstorming

**Conduct an initial brainstorming session with a few key stakeholders**. The target is to come up with _essential_ problems and risks within the system and  corresponding processes.

To stay focussed on the most important issues, we suggest to limit this brainstorming session to at most 15 minutes.

### 2. _Breadth-first_ search for issues

Depending on the issues you found in the brainstorming,
conduct detailed interviews with various stakeholders.

### 3. Focus on top issues

Over time the Issue List might become quite long. Only focus on the 15 or 20 highest ranked issues to not overwhelm yourself and others.

To make sure you have an up-to-date ranking, re-evaluate issue cost and probability on a regular basis. As aim42 is an iterative approach, you should come by this task about once a month*.

* the interval depends on the influence factors of your risks and how fast your system is evolving. If you have a higher cycle time, risk re-evaluation should be done more often.  

<!-- TODO write section about risk re-evaluation -->

### 4. Evaluate issues

Assess each issue concerning their one-time and recurring costs. Hereby you will often have to rely on estimations and assumptions. Pin down these evaluations. Costs are a great basis for prioritisation.

### 5. Conduct _root cause analysis_

Some issues are only symptoms of underlying causes. The „Root-Cause-Analysis“ aids you in systematically finding them.

### 6. Search for improvement options   

Consult technically knowledgeable involved people to search for measures which can potentially solve these issues.

### 7. Separate Issues from Improvements

One of the fundamental recommendations in aim42 is to clearly **separate issues (problems and risks) from improvements**. The reasons behind this are

1. different improvements could solve the same issue
2. one improvement could solve multiple issues
3. issue cost and improvement cost are separate values

As you can see in our point of view, issues and improvements have a many-to-many i.e. **m:n relationship**.

### 8. Manage Issues and Improvements

So far most of us will already be used to create tickets, put them on a backlog and estimate their effort. In aim42 terminology these are the Improvements which are managed in the **Improvement Backlog**.

As we said before, our issues are of a different kind and should be separated from the improvements. We manage issues in an **Issue List**.

### 9. Evaluate improvement costs

Of course Improvements do not only have benefits but also costs. You should systematically evaluate or estimate these costs so they can be taken into account for topics like cost-benefit or return on investment calculations.


### 10. Consider side effects or consequences

An improvement can also have side-effects. Make them explicit by creating according issues (problems and risks) in the Issue Backlog.

### 11. Compare issue-costs with improvement-costs

The line-up of the cost-of-improvements and the cost-of-issues and being able to compare them, is a valuable decision aid for business people responsible for budget or product management. Having this line-up available also supports software architects in making their arguments about inner quality, coupling, cohesion or implementation details more comprehensible and accessible to decision makers without strong technical background.


### 12. aim42 works iteratively

Evaluation of issues and improvements can change over time. It's the same way as priorities of requirements and goals may change in modern development processes. Periodic (iterative) re-evaluation and prioritization of issue list and improvement backlog assure their up-to-dateness.
