---
title: Data Analysis
phase: analyze
intent: Analyze and inspect the data created and manipulated by the system for its content, structure, quantity and size.
status: complete
---

## Description

In data analysis you could examine the following topics:

* [Data Structure](#analyze-data-structures)
* [Data Access](#analyze-data-access)
* [Data Size](#analyze-data-size)
* [Data Validation](#analyze-data-validation)
* [Data Actuality and Correctness](#analyze-data-actuality-and-correctness) (which covers integrity issues as well)
* [Data Access Protection](#analyze-data-access-protection)
* Analyze Data Distribution, Replication and Syncing
* [Backup](#analyze-backup)

### Analyze Data Structures

Are data structures suited to represent the problem domain?

At first, make the *structure* of the existing data explicit, e.g. by creating a rough sketch of a data model as either informal diagrams, entity-relationship or class diagrams. Focus should be on overview: Where and how are which kinds of data stored in which format. What are the relationships between the data elements?

Second, create an explicit model of the *required domain data structures*.

Some typical questions might help in finding problems:

* structural differences between those two models?
* differences in data types?
* differences in plausibility or validity checking?

### Analyze Data Access

Get an overview of data access paths: How is data read or written? Do the queries match their requirements, or are complex mappings or unsuitable indirections involved?

* What queries or executed how often?
* How large are the results in number or volume?
* Do relationships between query results have to be computed or do appropriate indices exist?

### Analyze Data Size

* Are some parts of the data especially large?
* Is the relation between record-size (*how large is a single record*?) and record-volume (*how many records exists*?) plausible?
* Do critical queries involve especially large parts of data?

### Analyze Data Validation

* How is data validated? (upon write, upon read, on client, on server, redundantly, uniformly)
* Is validation consistent with current business rules?
* Is validation overly complex?
* Is validation implemented with appropriate technical means?

### Analyze Data Actuality and Correctness

Especially in data concerning dynamic entities like people, organizations, markets, commodities etc., facts are very likely to change over time. Such data (*stored facts*) might become invalid sooner or later. Other types of information (like tax records, invoices or bookings on bank accounts) are created once and remain valid forever).

> * **Tip:** Peoples' address typically changes something between 2-10 times during their lives.
> * Empirical studies show that between 5 and 10% of business or job email addresses become invalid every year.

* Which parts of the data are subject to (what kind of) changes?
* Are parts of the data known to be invalid or contain invalid portions?
* Does the System handle potentially wrong or invalid data appropriately?
* Are there (organizational or technical) processes in place that deal with data inconsistencies or faults?

### Analyze Data Access Protection

* Is there an overview what kinds of data need which level of (access) protection?
* Is there a security concept in place covering protection against unauthorized access?
  * How are users/roles/organizations *allowed* to access data managed?
  * Is there a process in place to revoke access for outdated users/roles/organizations?

* Is there a plan what shall happen in case of security breaches or data theft?
* How is data theft recognized?

### Analyze Backup

* Is there a universal backup strategy in place, covering all areas of data storage?
* Does the backup strategy match the business criticality of the data?
* To what extend has the backup been verified?
* Does a fallback scenario exist in case of (partial or complete) data loss?
