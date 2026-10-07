---
title: Anticorruption Layer
phase: improve
categories: [architecture-and-code]
intent: An anticorruption layer is a logical layer that provides a stable interface to (potentially) volatile software components. As long as this interface remains untouched developers can implement changes or even replace their own or third-party software without affecting the clients of this interface.
related: [isolate-changes, bulkhead]
status: complete
---

## Description

The original definition [\[Evans03, p. 365\]](/reference/bibliography/#evans03):

> "" Create an isolating layer to provide clients with functionality in terms of their own domain model. The layer talks to the other system through its existing interface, requiring little or no modification to the other system. Internally, the layer translates in both directions as necessary between the two models. ""
> — — Eric Evans  
>  <cite>Domain Driven Design</cite>

## Experiences

Here are some real-life experiences:

* Anticorruption layer for a search-index to defer the decision if the best performance can be achieved with Elastic Search, Solr or a self-developed Lucene index.

## Applicability

Apply this pattern when clients shall be protected from internal changes in a module or subsystem.

## Consequences

* Allows to (ex)change software elements without affecting depending components
* Introduces one more level of indirection and thus may increase complexity

## Also Known As

* Isolation layer

## References

* [\[Evans03\]](/reference/bibliography/#evans03) p. 364ff.

## Notes on related patterns

* [Isolate Changes](/patterns/isolate-changes/), as an alternative or complimenting approach
* [Bulkhead](/patterns/bulkhead/), introduces stability boundaries within applications or systems by segmenting runtime resources.
