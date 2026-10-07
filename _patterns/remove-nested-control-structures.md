---
title: Remove Nested Control Structures
phase: improve
categories: [architecture-and-code]
intent: Re-structure code so that deeply nested or complicated control structures are replaced by semantically identical versions. Special case of [Refactoring](/patterns/refactoring/), similar to [Untangle Code](/patterns/untangle-code/). Often performed by reducing complexity and especially cyclomatic complexity. When reducing code complexity one needs to make sure we’re not exchanging inner/ method/ cyclomatic complexity by outer/ design or runtime complexity.
related: [refactoring, untangle-code]
status: stub
---
