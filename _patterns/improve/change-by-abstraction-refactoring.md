---
title: Change-by-Abstraction Refactoring
phase: improve
categories: [architecture-and-code]
intent: Incrementally replace part of the system with a new implementation.
related: [introduce-boy-scout-rule]
status: complete
---

## Prerequisites

Intention to change or replace a cohesive piece of code with a lot of incoming (afferent) dependencies. A common example is replacing homegrown ORM or plain SQL with a standard tool or exchanging a logging library for another with incompatible interfaces.

## Description

1.  Mark the Method or Class you would like to replace as deprecated.
2.  Introduce an abstraction that is implemented by the old implementation. If the API of the new solution differs, consider the Adapter Pattern to perform  
![Change by abstraction, step 1](/images/patterns/change-by-abstraction-1.png)
3.  Incrementally move all the calls where the deprecated Class/Method is still being used to use the new API instead.  
![Change by abstraction, step 2](/images/patterns/change-by-abstraction-2.png)
4.  You can now implement and start testing the new functionality by deriving it from the abstraction you introduced in step 2.  
![Change by abstraction, step 3](/images/patterns/change-by-abstraction-3.png)
5.  When all the places where the deprecated Class/Method is called directly are moved to the abstraction, you can use a feature toggle in a proxy class that implements the common abstraction to toggle between the old and the new implementation.  
![Change by abstraction, step 4](/images/patterns/change-by-abstraction-3.png)
6.  If you made sure the new functionality performs well enough, you can remove the deprecated implementation and possibly the abstraction.

## Related patterns/names

This method is also known as "Branch by Abstraction" and a similar technique that goes under the names "Parallel Change" or "Expand and Contract" exists, where the abstraction step is skipped and callers are migrated to a new method/object immediately.

This approach works best when it is used in combination with [Introduce Boy Scout Rule](/patterns/introduce-boy-scout-rule/).

## Risks

Too many of these half-performed incremental refactorings will leave your code base in a mess. You still need to finish, what you start.

## Applicability

Your team is familiar with and embraces Trunk-Based development.

## Consequences

* Teams can collaboratively move code towards a new implementation by replacing calls to deprecated methods/classes with calls to the abstraction, even in parallel.
* The refactoring can be made incrementally.
* The build will remain "green", even when the refactoring is unfinished.
* The abstraction enables comparison of the behaviour of the old to the new implementation in production or testing environments to make sure that the new implementation matches the old behaviour.

## References

[http://continuousdelivery.com/2011/05/make-large-scale-changes-incrementally-with-branch-by-abstraction/](http://continuousdelivery.com/2011/05/make-large-scale-changes-incrementally-with-branch-by-abstraction/)  
[http://paulhammant.com/blog/branch\_by\_abstraction.html](http://paulhammant.com/blog/branch_by_abstraction.html)  
[http://www.alwaysagileconsulting.com/application-pattern-verify-branch-by-abstraction/](http://www.alwaysagileconsulting.com/application-pattern-verify-branch-by-abstraction/)  
[http://martinfowler.com/bliki/BranchByAbstraction.html](http://martinfowler.com/bliki/BranchByAbstraction.html)  
[https://printhelloworld.de/posts/refactoring-in-baby-steps/](https://printhelloworld.de/posts/refactoring-in-baby-steps/)  
[https://www.branchbyabstraction.com/](https://www.branchbyabstraction.com/)
