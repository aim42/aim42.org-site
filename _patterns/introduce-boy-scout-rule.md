---
title: Introduce Boy Scout Rule
phase: improve
categories: [architecture-and-code]
intent: Enable cross-cutting architectural improvement even if it is not feasible to change the whole codebase.
related: [refactoring-plan, introduce-layering, anticorruption-layer, improvement-backlog]
status: complete
---

The “Boy Scout Rule” for software development basically states that we

> “Always check a module in cleaner than when you checked it out.”.
> — — Robert C. Martin

Uncle Bob (Robert C. Martin) proposed this adoption of the rule from the boy scout rulebook which reads “Try and leave this world a little better than you found it.” for the software development world in an article in Kevlin Henney’s “97 Things a Programmer Should Know” [\[Henney\]](/reference/bibliography/#henney).

> **Tip:** Often the introduction of concepts like layering is deemed *“impossible”* due to the huge codebase that would be affected. In these cases the Boy Scout Rule approach is a lightweight way to enhance the code quality one day at a time.

## Description

* Drafting from an [Improvement Backlog](/patterns/improvement-backlog/), define a specific rule set on how to improve the contents of specific file types.
* Specify how much effort should be allowed to perform each specific clean-up operation
* Specify how to proceed if the cleanup takes up too much time
* Revisit the rule set regularly
* Install a mechanism to ensure that the things that where too big to be cleaned up while visiting the file will end up in the [Improvement Backlog](/patterns/improvement-backlog/).

> Example Boy Scout Rule agreement
> **Tip:** This is a very concrete agreement from a specific project - yours should look rather different.
> 
> **Boy Scout Rule agreement for project X from 2014-02-19 onwards:** . Apply defined source code formatting (via IDE) to adhere to coding style  
>  If the formatting introduces errors and those errors can not be fixed within 10 Minutes revert changes and add the file to the "redo formatting list" (e.g. add an TODO REFORMAT comment, if such a comment already exist add an exclamation mark each time you handle the file)
> 
> 1.  Move SQL strings to the db-encapsulation layer and replace the former direct database calls by appropriate calls to the correct architecture elements  
>      If this takes longer than 20 minutes revert changes and add file to the list "difficulties with database extraction" (e.g. add an TODO DB-EXTRACT comment, if such a comment already exist add an exclamation mark each time you handle the file)
> 2.  Remove magic numbers from source code and replace them with constants (e.g. replace if (item.id &gt; 99) with if (item.id &gt; Item.COMPOUND\_ITEMS\_THRESHHOLD).
> 3.  If time allows replace the former "magic number conditionals" with a function on a business logic level (e.g. replace if (item.id &gt; Item.COMPOUND\_ITEMS\_THRESHHOLD) with if (item.is\_compound())

## Experiences

Introducing the Boy Scout Rule on a heavily deteriorated code base induces heavy payback on [technical debt](https://en.wikipedia.org/wiki/Technical_debt) and often gets challenged by team members and senior management. It is important to point out that the extended time spent on fixing the artifacts "as the teams goes" actually is the *explicit* payment of the technical debt interest rate.

## Risks

Sometimes the Boy Scout Rule can be taken as a means by itself. In these cases the higher goals tend to be forgotten and thus

## Applicability

The pattern “Introduce Boy Scout Rule” can always be applied.  
Some of the most effective uses are

* unstructured code (no layers, no separation of concerns etc.)
* systematic weaknesses (insecure logging, insecure handling of database inserts etc.

## Consequences

The introduction the Boy Scout Rule often proved to enable structural improvements as a prerequisite for higher level architectural improvements. Also it heightens the team’s awareness of good practices in their code base.

The introduction of the Boy Scout Rule leads to a dramatic shift in the distribution of the code quality because those parts of the system that get changed the most also get the most care. For more stable parts of the system other approaches have to be utilized.

## References

The original description of the boy scout rule can be found online at [\[Boy-Scout-Rule-article\]](/reference/bibliography/#boy-scout-rule-article).

## Notes on related patterns

* [Refactoring Plan](/patterns/refactoring-plan/), as an alternative or complimenting approach
* [Introduce Layering](/patterns/introduce-layering/) can be performed using the Boy Scout Rule
* [Anticorruption Layer](/patterns/anticorruption-layer/) can be performed using the Boy Scout Rule
* An [Improvement Backlog](/patterns/improvement-backlog/) should be the basis for the tasks performed when applying the Boy Scout Rule
