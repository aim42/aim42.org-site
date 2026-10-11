---
title: Software Archeology
phase: analyze
intent: Understand software by examining existing source code.
related: [runtime-artifact-analysis, structural-analysis]
status: complete
---

## Description

1.  Make sure you have the complete code, scripts, frameworks and tools required to build the system.
2.  Ensure you have access rights to all required systems, at least to version control, database, participating servers etc.
3.  Ensure you can build the system from scratch (compile, load all dependencies, link or whatever steps are necessary).
4.  Practice [View-Based Understanding](/patterns/view-based-understanding/) by sketching notes or diagrams. Get an *aerial view*, a glimpse of the topmost, biggest structures in the code.
5.  Try to understand the *terminology* of the original authors by scanning code and searching for multiple occurrences. Start creating a *glossary*.
6.  Introduce *tracing* or *logging* statements. Aspect-oriented tools (like AspectJ) might be helpful.

## Experience

* By examining the build scripts of the software project or the job definitions on a continuous integration server, you can build the software and the needed testing environment on your own.
* With simple tools like the `git shortlog -ns` command you can easily check parts of a software system for potential loss of knowledge based on the commits per developer.
* By using word clouds, you can quickly extract the most occurring terms in your source code and start creating a glossary for the most prominent words.

## Applicability

You have to understand a system with:

* little or no current documentation.
* no knowledgeable technical stakeholders or development team available

## References

* [\[Hunt-Archeology\]](/reference/bibliography/#hunt-archeology), pleasant introduction without adherence to any strict pattern template. Recommended reading.
* [\[Moyer-Archeology\]](/reference/bibliography/#moyer-archeology), short report.
* [\[OORP\]](/reference/bibliography/#oorp), page 53ff. , "Read all the Code in One Hour" suggest to read all source code in a short period of time to get a rough feeling about the software system.
* [\[OORP\]](/reference/bibliography/#oorp), page 97ff. , "Speculate about Design" suggest to create diagrams based on hypothesis and progressive refinement.
* [\[Tornhill-XRay\]](/reference/bibliography/#tornhill-xray) shows many ways of using version control systems to recreate knowledge about software systems.

## Notes on related patterns

* Code Reading
