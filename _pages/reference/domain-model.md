---
title: Domain Model
layout: aim42-page
permalink: /reference/domain-model/
lede: The entities aim42 considers during improvement, such as issues, causes and improvements, with their definitions and relationships.
---

Within the systematic improvement we consider and manipulate several typical kinds of information, **entities**.

For a more pragmatic description, please see the [Common Terminology](/reference/introduction/#common-terminology) section

![aim42 domain terminology - detailed](/images/patterns/aim42-domain-model.png)
{: #figure-domain-model}

<table>

<tbody>
<tr>
<td colspan="2"><strong>Cause</strong></td>
<td>Root cause of an Issue, in contrast to a symptom.</td>
</tr>
<tr>
<td></td>
<td><em>is-a</em></td>
<td>(inherits from) Issue</td>
</tr>
<tr>
<td></td>
<td><em>is real source of</em></td>
<td>one or many Issues.</td>
</tr>
<tr>
<td colspan="2"><strong>Configuration</strong></td>
<td></td>
</tr>
<tr>
<td colspan="2"><strong>Constraints</strong></td>
<td>Technical or organizational constraints, restraining management, design, implementation or operation of the System.</td>
</tr>
<tr>
<td></td>
<td><em>restrict</em></td>
<td>the System, associated Processes or Organization.</td>
</tr>
<tr>
<td colspan="2"><strong>Documentation</strong></td>
<td>Any (hopefully written) information about
the systems, its goals, requirements, architecture, implementation, operation or management.</td>
</tr>
<tr>
<td colspan="2"><strong>Goals</strong></td>
<td>What does the Organization or Stakeholder expect from
the System, why does the System exist anyway.</td>
</tr>
<tr>
<td colspan="2"><strong>Hardware</strong></td>
<td>Structure and kind of hardware required to develop, test and operate the System.</td>
</tr>
<tr>
<td colspan="2"><strong>Improvement</strong></td>
<td>Any remedy, opportunity, tactic or strategy to improve the System by resolving one or several Issues.</td>
</tr>
<tr>
<td></td>
<td>
<em>modifies</em> or <em>creates</em>
</td>
<td>Risk</td>
</tr>
<tr>
<td></td>
<td><em>is remedy for</em></td>
<td>the System.</td>
</tr>
<tr>
<td></td>
<td><em>resolves</em></td>
<td>(partially or complete) one or several Issues</td>
</tr>
<tr>
<td colspan="2"><strong>Issue</strong></td>
<td>Any problem, error, fault, risk, suboptimal situation or their causes within the
System, Processes or Organization related to it (e.g. management, operational, development, administrative or organizational activities).</td>
</tr>
<tr>
<td></td>
<td>Frequency:</td>
<td>how often does the Issue occur?</td>
</tr>
<tr>
<td></td>
<td><em>resolved by</em></td>
<td>one or several Improvements.</td>
</tr>
<tr>
<td colspan="2"><strong>Organization</strong></td>
<td>The organization or entity responsible or owning the System.</td>
</tr>
<tr>
<td></td>
<td><em>source of</em></td>
<td>Issues.</td>
</tr>
<tr>
<td colspan="2"><strong>Process</strong></td>
<td>Processes, conventions or activities for developing, maintaining, operating or managing the System.</td>
</tr>
<tr>
<td></td>
<td><em>source of</em></td>
<td>Issues.</td>
</tr>
<tr>
<td colspan="2"><strong>Risk</strong></td>
<td></td>
</tr>
<tr>
<td></td>
<td>EarlyWarning</td>
<td>Indicator that the Risk is occurring and turning into a problem.</td>
</tr>
<tr>
<td></td>
<td><em>is an</em></td>
<td>(inherits from) Issue, but not occurred yet.</td>
</tr>
<tr>
<td colspan="2"><strong>Software</strong></td>
<td>All source code and configuration that make up the System under improvement. Hopefully stored in version-control.</td>
</tr>
<tr>
<td></td>
<td><em>is an</em></td>
<td>Issue, but not occurred yet.</td>
</tr>
<tr>
<td colspan="2"><strong>Stakeholder</strong></td>
<td>People or roles interested or participating in the System or any of its associated Processes.</td>
</tr>
<tr>
<td></td>
<td><em>belong to</em></td>
<td>the Organization responsible or owning the System.</td>
</tr>
<tr>
<td></td>
<td><em>knows / informs about</em></td>
<td>Issues and/or Improvements. Stakeholders often
  know about existing problems and opportunities for improvements.</td>
</tr>
<tr>
<td colspan="2"><strong>System</strong></td>
<td>The system under improvement, consisting of Software, Hardware and Documentation.</td>
</tr>
<tr>
<td></td>
<td><em>managed and affected by</em></td>
<td>Processes</td>
</tr>
<tr>
<td></td>
<td><em>remedy</em></td>
<td>the System or aspects of it by Improvements</td>
</tr>
<tr>
<td></td>
<td><em>suffers from</em></td>
<td>Issue</td>
</tr>
<tr>
<td></td>
<td><em>complies with</em></td>
<td>one or several Goals.</td>
</tr>
<tr>
<td></td>
<td><em>consists of</em></td>
<td>Software, Configuration, Hardware and Documentation.</td>
</tr>
</tbody>
</table>
