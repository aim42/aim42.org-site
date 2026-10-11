---
title: Expect Denial
phase: crosscutting
intent: Some people will oppose your findings, will whitewash or sugarcoat issues, problems or [root causes](/patterns/root-cause-analysis/). Regardless on how careful you prepared your analysis, they will try to diminish or attack your findings.
related: [collect-issues, estimate-issue-cost, traceability]
status: complete
---

Some people will oppose your findings, will whitewash or sugarcoat issues, problems or [root causes](/patterns/root-cause-analysis/). Regardless on how careful you prepared your analysis, they will try to diminish, attack or dispute your findings.

* Prepare you (as analyzer or evaluator or systems) for serious opposition and resistance by some stakeholders.
* Describe which kind of reaction might be turned into acceptance.
* Describe what might be gained by certain slightly negative reactions.

## Description

![Levels of Reaction when presented with problems](/images/patterns/expect-denial-reaction-levels.png)
{: #figure-reaction-pyramid}

From enthusiasm to neutrality things will be easy, but from here on it gets interesting or difficult, however you might call it.

1.  **Enthusiasm**: Some people will embrace your findings - like "that’s what we always said…". Enthusiasts sometimes expect that findings or the appropriate improvement approaches directly improve their own situation.
2.  **Agreement**: Others will agree, without further ado.
3.  **Neutrality**: Some stakeholders won’t care. These are probably unconcerned by any finding.
4.  **Amazement**: Your results will amaze or astonish some people. Although they would never have expected your findings, amazed stakeholders might be convinced to agreement or neutrality by using explanation and proofs in stakeholder-specific language or communication. On the other hand, amazed stakeholders pose the serious risk of becoming more negative (doubtful or resisting) if you fail to convince them - or if other people (your opponents, for example) manage to bring them over to the *dark side*…

    Always ask amazed stakeholders *why* for the reasons of their amazement - that can help you in your argumentation.

5.  **Doubt**: You will hear or read "Can’t be, impossible!" or similar expressions from some people. If these stakeholders can explain the reasons for their doubts, you might find ways to improve your explanation (maybe your issues were simply ill-formulated) or you have to look for additional and better ways to explain. Doubt can lead you to errors or omissions in your own argumentation or conclusions.

    Some doubtful stakeholders will be emotional - and therefore not open for rational or objective arguments. That’s a serious and difficult communication problem - beyond the scope of this document.

6.  **Minimization**, sometimes disavowal: This is the first level of denial. The fact itself is accepted, but its consequences, evaluations or seriousness are denied. In practice we encountered this phenomenon quite often: Affected stakeholders repeat their assessment "problem acknowledged, but the consequences are only minimal" like a mantra. Other stakeholders, especially doubtful or amazed ones, might start to believe in this minimization tactic - especially if the truth implies inconvenient or uncomfortable changes in their own working environment.
7.  **Resistance**: Findings are opposed, either actively or passively.

    In case you encounter minimization or resistance, get support from the highest management level you can access: As a consequence some, if not many, minimizing or resisting stakeholders will turn to your side.

8.  **Hostility**, or "*Shoot the messenger*". Always remain calm and polite - but hard in your argumentation and facts. Hostile stakeholders can rarely be convinced of something, but need to be handled with diplomacy, politics and organizational skills (none of which we can cover here).

    Be prepared for *hostile actions*, though: In case of critical issues, always keep details documentation of their origin. Be prepared to *proof* those issues, remove even minor omissions or formal weaknesses in your argumentation. Your issues and [Root Cause Analysis](/patterns/root-cause-analysis/) has to be flawless and backed by meticulous research and management support. Ensure [Traceability](/patterns/traceability/) of your chain of reasoning! Keep written records of [Stakeholder Interview](/patterns/stakeholder-interview/) and of suspicious pieces of source code or documentation.

Let others review your findings before publication.

## Experiences

In one audit of a European Logistic Company (> 40.000 employees) we found serious issues within their development processes, in addition to some issues in their source code. The process problems caused massive (> 3 months) delays in delivery of working software to production, whereas the pure software bugs were relatively minor in their consequences. When we presented these issues, all process-related issues were minimized or doubted by senior management of the IT department.

With the help of the CIO, we identified those minimizers to be the root cause of most process issues, as they had themselves introduced inefficient, formal and bloated processes.

## Consequences

Especially when presenting results to (opposing) management stakeholders, you should be able to **verify** all your claims. In critical cases you should keep written protocols and note who-said-what in your [stakeholder interviews](/patterns/stakeholder-interview/).
