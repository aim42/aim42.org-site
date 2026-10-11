---
title: Fail Fast
phase: crosscutting
intent: Identify quality issues as early as possible and aim to fix them.
status: complete
---

"fail fast" is actually a reference to an architecture principle describing a runtime behaviour of a system. I.e. if the application already knows that a remote system is not reachable, it should not try to send other/ more requests to this system so that this system can recover. Instead the application should immediately return either an error message or - even better - a functional fallback value.

Transferring this to software improvements, a fail-fast approach would be to immediately report when an improvement can not be applied. Don’t wait e.g. until the end of the sprint to communicate the failure. Instead this early feedback provides the opportunity to reflect and pivot on the improvement before the next sprint is started.

## Takeaways

* fail-fast is actually an architecture principle for software runtime behaviour
* report failures as early as possible
* use failures as opportunities to pivot
