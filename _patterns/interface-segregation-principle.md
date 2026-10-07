---
title: Interface Segregation Principle
phase: improve
categories: [architecture-and-code]
intent: Reduce coupling between clients and service providers.
related: [never-change-running-system, manage-complex-client-dependencies-with-facade, front-end-switch]
status: complete
---

## Description

Service components may provide more functionality than required by one client. To remove the client’s dependency from functionality not required introduce interfaces that are tailored to the client’s needs.

## Applicability

Apply when

* clients only require a restricted functionality from a complex service,
* you have to deal with low cohesion components you cannot change

## Consequences

* Reduces coupling between client and service providers. Changing the service provider interface will affect fewer clients.
* Introduces additional interfaces that must be maintained.
* You have to find a good compromise between "good client fit" and the number of interfaces.

## Notes on related patterns

* If [Never Change Running System](/patterns/never-change-running-system/) is a must meaning a service component or its API must not be changed, consider using
  * [Manage Complex Client Dependencies with Facade](/patterns/manage-complex-client-dependencies-with-facade/) and
  * [Front-End Switch](/patterns/front-end-switch/)
