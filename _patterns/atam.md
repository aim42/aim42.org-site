---
title: ATAM
phase: analyze
intent: Apply the ATAM method to evaluate the software architecture regarding its compliance with quality goals.
# phase 2 restores: qualitative-analysis, capture-quality-requirements
status: complete
---

Architecture Tradeoff Analysis Method. Systematic approach to find
architectural risks, tradeoffs and sensitivity points.

## Description

The ATAM method consists of four phases as shown in the diagram "Approach of ATAM".

![Approach of ATAM](/images/patterns/approach-of-atam.png)
{: #figure-atam-approach}

The phases are:

1. **Preparation**
   1. *Identify the relevant stakeholders*: The specific goals of the relevant
      stakeholders define the primary goals of the architecture. Who belongs to
      these *relevant* stakeholders has to be determined by a
      [Stakeholder Analysis](/patterns/stakeholder-analysis/).
2. **Kickoff**
   1. *Present the ATAM method*: Convince the relevant stakeholders of the
      significance of comprehensible and specific architecture and quality
      goals. ATAM helps identify risks, non-risks, tradeoffs and sensitivity
      points. Calculation of quantitative attributes is not subject of this
      method.
   2. *Present the business objectives and architecture goals*: Present the
      business context to the relevant stakeholders, especially the *business
      motivation and reasons* for the development of the system. Clarify
      specific requirements that the architecture should meet, for instance
      flexibility, modifiability and performance.
   3. *Present the architecture of the system*: The architect presents the
      *architecture* of the system. This includes:
      * all other systems with interactions to the [system](/glossary/#system),
      * building blocks of the top abstraction level,
      * runtime views of some important use cases,
      * change or modification scenarios.
3. **Evaluation**
   1. *Explain in detail the architecture approaches*: The following questions
      are answered by the architect or developers:
      * How are the relevant quality requirements achieved within the
        architecture or the implementation?
      * What are the structures and concepts solving the relevant problems or
        challenges?
      * What are the important design decisions of the architecture?
   2. *Create a quality tree and scenarios*: In the context of a creative
      brainstorming the stakeholders develop the relevant required quality
      goals. These are arranged in a quality tree. Afterwards the quality
      requirements and architecture goals of the system are refined by
      scenarios which are added to the quality tree. The found scenarios are
      prioritized according to their business value.
   3. *Analyze the architecture approaches with respect to the scenarios*:
      Based on the priorities of the scenarios the evaluation team examines
      together with the architect or developers how the architecture
      approaches support the considered scenario. The findings of the analysis
      are:
      * existing risks concerning the attainment of the architecture goals,
      * non-risks, which means that the quality requirements are achieved,
      * tradeoff points: decisions that affect some quality attributes
        positively and others negatively,
      * sensitivity points: elements of the architecture that have formative
        influence on the quality attributes.
4. **Follow-up**
   1. *Present the results*: Creation of a report with:
      * architectural approaches
      * quality tree with prioritized scenarios
      * risks
      * non-risks
      * tradeoffs
      * sensitivity points

## Experiences

The ATAM method:

* provides operational, specific quality requirements,
* discloses important architectural decisions of the [system](/glossary/#system),
* promotes the communication between relevant stakeholders.

> **Important:** The ATAM method does not develop concrete measures, strategies
> or tactics against the found risks.

ATAM has been successfully applied by many organizations to a variety of
systems. It is widely regarded as the most important systematic approach to
qualitative system/architecture analysis.[^1]

[^1]: The original authors of ATAM call it an *evaluation* method, whereas
    aim42 classifies ATAM as belonging to the category of analysis practices.

## Applicability

Evaluate an architecture:

* as soon as possible,
* already in the construction phase,
* better not after the completion of the system.
