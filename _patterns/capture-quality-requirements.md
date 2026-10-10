---
title: Capture Quality Requirements
phase: analyze
intent: Make the specific quality requirements of a system explicit.
related: [atam, explicit-assumption, qualitative-analysis, requirements-analysis]
status: complete
---

## Description

Invite authoritative stakeholders to a joint workshop (e.g. half- or full-day). Let them write *quality scenarios* to describe their specific quality requirements for the system. Moderate this workshop.

* Use *scenarios* to formulate specific quality requirements.
* Order those scenarios within a mostly hierarchical quality tree, similar to [\[ISO-9126\]](/reference/bibliography/#iso-9126).

### Scenario-based Quality Description

Scenario
: describes the reaction of a system to a certain event (or type of event).

![Structure of Quality Scenarios](/images/patterns/quality-scenario.png)
{: #quality-scenario-diagram}

Although this definition is concise, it needs some explanation to become understandable. See figure Structure of Quality Scenarios:

* An *event* can be
  * a user clicking a button
  * an administrator starting or stopping the system
  * a hacker trying to get unauthorized access.

* An *event* can also be
  * a manager needing another feature
  * another manager wanting to reduce operation costs
  * some government agency requiring financial data to be tamper-proof

Example 1. Example scenario "Mandatory changes to Business Processes"

| Context | The individual processing step AB within use case XY is declared invalid by the regulatory authority and removed from the system. The data processed by the system is not affected. |
| Business Goal(s) | The needed changes to the use case XY can be carried out at low cost and without negative effects. |
| Trigger | The legislator, represented by the regulatory authority, prohibits the use of the AB processing step. |
| Reaction | A developer or architect removes the AB processing step in the system (by deleting the corresponding calls or reconfiguring the process flows). |
| Target value | The change requires a maximum of 24 hours with a maximum of 48 person-hours of effort. After this time, the system is fully working again. |
| Constraints | This change has no effect on the existing data of the users/customers in the system regarding the XY application case. An (automatic) migration of some data is permitted, but must not exceed the 24-hour limit. |

Such a scenario makes it clear to everyone that not only business functionality is needed to achieve the project’s goals. It makes technical requirements (in the example above: modifiability) visible to non-technical stakeholders by providing traceability from the business goal to the technical details.

## Experiences

* **Needs moderation**: Brainstorming quality requirements usually works well in moderated workshops. If given (even trivial) examples, every stakeholder will most likely write down several scenarios. We often received 80-120 different scenarios in one-day workshops.
* **Uncovers problems and risks**: Scenarios collected within brainstorming sessions often contain *hidden* problem descriptions, risks or problems with the current systems.
* **Covers organization and process**: Scenarios sometimes cover process or organizational aspects (like release cycles should be faster than they are now). Move those to your [Improvement Backlog](/patterns/improvement-backlog/).
* **Improves human communication**: Different stakeholders often start communicating about the system or their requirements during such workshops. This kind of interaction *should* have happened long before…

## Applicability

Use this practice when (authoritative) stakeholders are available for discussion or a workshop.

If you have well-documented, specific and current (!) quality requirements available, you might consider skipping this practice for now (although we’re quite sure it’s a good opportunity to learn a lot about the system, its stakeholders, their requirements and opinions).

## Consequences

* The required constraints (aka quality attributes) of a system are made explicit.

## Also Known As

* Non-functional requirements (although this term is misleading, as *functional* requirements strongly influence the *quality* of any system!)
* Documentation of quality requirements.

## References

The workshop-based collection of quality requirements has been described by [\[Clements-ATAM\]](/reference/bibliography/#clements-atam).

* Real-world examples of software quality requirements (currently available only in German): [https://github.com/arc42/quality-requirements](https://github.com/arc42/quality-requirements)
* [\[Clements-ATAM\]](/reference/bibliography/#clements-atam) contains a brief description of scenario-based quality description and details on how to set up such workshops.
