# White paper: the FOLIO workflow engine

Mike Taylor, Index Data `<mike@indexdata.com>`

Document version 1.3 (10 October 2017).

Version history:
* 1.0 (5 October 2017): first essentially complete version.
* 1.1 (6 October 2017): copy-edited and cleaned up.
* 1.2 (6 October 2017): turn "see also"s into Appendix B.
* 1.3 (10 October 2017): add some more links to Appendix B, fix some typos.
* 1.4 (12 December 2017): add Appendix C on relevant standards


Contents
--------

<!-- md2toc -l 2 folio-workflow-engine.md -->
* [Preface: what this document is](#preface-what-this-document-is)
* [Background](#background)
    * [Terminology](#terminology)
* [Review of existing workflow systems](#review-of-existing-workflow-systems)
* [Example workflows](#example-workflows)
    * [Scenario 1: acquisition of a requested book](#scenario-1-acquisition-of-a-requested-book)
    * [Scenario 2: unboxing a delivery](#scenario-2-unboxing-a-delivery)
    * [Scenario 3: submitting a dissertation](#scenario-3-submitting-a-dissertation)
* [Use of data in workflows](#use-of-data-in-workflows)
    * [Implicit or explicit data-passing?](#implicit-or-explicit-data-passing)
    * [Pass by value or by reference?](#pass-by-value-or-by-reference)
    * [Notion of object type](#notion-of-object-type)
    * [Workflow state vs. object state](#workflow-state-vs-object-state)
    * [Data standardisation](#data-standardisation)
* [Implementation analogies](#implementation-analogies)
    * [Finite state machine with transitions](#finite-state-machine-with-transitions)
    * [Makefile-like dependency tree](#makefile-like-dependency-tree)
    * [Connector Framework](#connector-framework)
    * [Very high-level DSL](#very-high-level-dsl)
* [Implementation strategy](#implementation-strategy)
    * [Front-end/back-end interaction](#front-endback-end-interaction)
    * [Virtual Machine for running workflows](#virtual-machine-for-running-workflows)
    * [Expressing workflows](#expressing-workflows)
        * [XML or JSON](#xml-or-json)
        * [Human-readable/writeable DSL](#human-readablewriteable-dsl)
        * [Compiled form](#compiled-form)
        * [Visual representation](#visual-representation)
        * [Discussion](#discussion)
    * [Data types](#data-types)
    * [Operations](#operations)
        * [Okapi calls](#okapi-calls)
        * [Record manipulation](#record-manipulation)
        * [Control flow](#control-flow)
        * [Subroutines](#subroutines)
        * [Human interaction](#human-interaction)
        * [Other](#other)
    * [Tracking jobs](#tracking-jobs)
    * [Some specific issues](#some-specific-issues)
    * [Error handling](#error-handling)
* [Appendix A: Using the notification system](#appendix-a-using-the-notification-system)
* [Appendix B: Related documents](#appendix-b-related-documents)
* [Appendix C: Relevant standards](#appendix-c-relevant-standards)



## Preface: what this document is

This is an overview of what workflow is or could be in FOLIO, how it breaks down into v1 and v2 features, what implications it has for the broader FOLIO architecture, and how we might go about implementing the v1 parts of it without circumscribing our options for the v2 parts when the time comes.

Much of what is contained herein was first discussed in the Workflow breakout group on the morning of Friday 20 September 2017, in the Montreal FOLIO developer's meeting. Contributors in that session included
D Ellen Bonner,
Ian Ibbotson,
Heikki Levanto,
Peter Murray,
Nassib Nassar,
Jason Skomorowski,
and
Mike Taylor.

At this stage, the contents of this document should be considered as a foundation for discussion, rather than as a design. The document's purpose at this stage is not to guide implementation, but to provide a more concrete vision of what workflow is or could be, so that future discussions have a more secure footing and do not drift away into abstractions.



## Background

The term "workflow" in FOLIO has been used in several different ways and has accumulated a lot of connotations. Among other things, it is a wildly popular future feature, which has been used to great effect by the marketing team. But it has yet to be clearly defined what it consists of, and seems to have been interpreted in different ways by different groups.

What is meant here by "workflow" is that facility of a FOLIO system to guide human users through sequences of operations, filling in as much of the work as it can. This encompasses cases where _all_ parts of a workflow can be done by the computer without human intervention: in this case we refer to the process as "automation"; but automation in this sense is not a conceptually separate thing from workflow, it is simply workflow in which none of the steps require human intervention.

Workflow in FOLIO is more important than in other library systems, because FOLIO is composed of numerous small applications which interact. Workflow (including automation) will be the glue that binds them together into a powerful, flexible, configurable whole. Rather than a single monolithic Acquisitions application with tightly bound procedures built into it, we envisage smaller, substitutable applications such as Ordering, Invoicing and Unboxing, each of them operated primarily in terms of higher-level procedures defined as workflows.

Although "workflow" has been thought of as a FOLIO v2 feature, we need to think about this now, because the term has been used in two quite separate senses. The v2 feature is the visual Workflow Editor that has been [prototyped by Filip Jakobsen](http://ux.folio.org/prototype/en/workflows?view=full) and which will allow librarians to set up their own workflows. (For more on a UX-oriented perspective: see [the "Workflow app" issue in the UX Jira project](https://issues.folio.org/browse/UX-52).)

But well before this is required, FOLIO will need the underlying mechanisms for executing workflows. Until we have the visual editor, we can make do with hand-authored workflows: creating such workflows will be part of the job of developing high-level applications.

We need to think about this now, rather then deferring until after the v1 release, because otherwise we will need to waste a lot of re-engineering down the line: replacing what in effect will be hardwired workflows with applications of the Workflow Engine. We want to avoid wasting development effort on hardwired workflows that we are only going to throw away.


### Terminology

* A _workflow_ is a set of instructions for FOLIO and/or human users, expressing how to carry out a task. In v1, we will author these by hand, and in v2 there will be an editor. Either way, except when being edited, these are static, like classes in object-oriented programs.

* A _workflow instance_ is a specific running instance of a workflow. It has parameters that may be set when it's started (e.g. the title of a book to order) and its own state that changes as the task progresses (e.g. the status of an ongoing order). It resembles an instance of class in an object-oriented program.

* A _job_ is a simpler term for a workflow instance.

* The _Workflow Editor_ is the visual editor for creating workflows, which will be created as part of FOLIO v2.

* The _Workflow Engine_ is the software that executes workflows on behalf of a user. It will exist quite separately from the Workflow Editor, which is only one way of authoring a workflow.

* A _workflow language_ is a textual representation of a workflow, which can be authored by a developer. See [below](#expressing-workflows). Since this will be a domain-specific language (DSL) this may also be referred to as a _workflow DSL_.



## Review of existing workflow systems

Nassib has volunteered to do this: see [INTFOLIO-6](https://jira.indexdata.com/browse/INTFOLIO-6).



## Example workflows

To ensure that FOLIO's workflow capabilities are sufficiently expressive to execute real library workflows, we need to establish some concrete scenarios. We will then be able to express these in a workflow language and consider how a Workflow Engine could execute them.

Here are three scenarios.


### Scenario 1: acquisition of a requested book

The following rather unlikely sequence of actions involved in placing a purchase order illustrates some of the possible difficulties that can be encountered in the course of this seemingly simple task.

* A patron wants to read a certain book -- for example, an edition of _Pride and Prejudice_ with an interesting introductory essay -- but it is not in the library. She submits a request.

* A paraprofessional (see below) picks up the request and finds a source for a hardback edition of the book. He submits it as a purchase request.

* An acquisitions librarian picks up the purchase request and notices that the suggested edition is expensive. She pushes that purchase request back to the patron, asking whether there is any reason that an inexpensive paperback edition will not suffice.

* The patron responds that only the nominated edition is acceptable since her interest is in the introductory essay.

* The acquisitions librarian accepts this, but is not authorised to spend the high price of this edition, to she escalates the purchase request to a senior librarian.

* The senior librarian receives the request, along with the explanation for why the expensive edition of the book is necessary, and OKs the purchase.

At this stage, a purchase order is raised, and the present job is complete. A new job may be created to handle the financial side of the transaction, but this will likely involve different people.

("Paraprofessional" is an awful term used for people that do library jobs without a library degree. Seriously.)


### Scenario 2: unboxing a delivery

When a package of books arrives at a library, a file is also supplied that contains some relevant metadata. This may be physically included in the package, or downloaded from a specified FTP location, or obtained by some other method. Ingesting the file is the beginning of the process of getting the books into the system and onto the shelves.

* Librarian imports the file of bibliographic data -- or, better, specifies a location, and FOLIO fetches and imports it.

* Typically this file will consist only of instance-level bibliographic records. For each such record:

  * If the system does not already have a record with this ISBN, insert the record into the instance store.
  * Otherwise, merge the data in the new record with that in the existing record. This process will potentially be complex, involving heuristics and perhaps human intervention. (This might in fact be a whole other workflow, to be called as a subroutine.)

  * The books typically come shelf-ready with barcodes already attached. Somewhere in the bib records will be a list of the barcodes for each physical item -- e.g. for all six copies of a given book. For each barcode:

    * An item-level record must be created.
    * Each item record must be populated with certain fields copied across from the instance record that it pertains to.

  * Shelving locations (buildings/branches and shelf ranges) will typically be determined by the call number (or shelf mark -- essentially different phrases for the same thing).  Call numbers specify the sort order at a local library, but the call numbers themselves are usually determined by a national library that is looking across the whole of published literature.  The first part of the call number specifies the broad subject area.  (For instance, Dewey Decimal _560s_ and Library of Congress _QE_ -- both representing the subject of geology and dinosaurs.)  The shelving location is based on that first part of the call number; there would be rules for shelving items in one location or another. Locations would need to be derived and set into each item record.

  * Check for holds on the newly added instance. If they exist, notify the patrons that the book is now available. Note that holds may be on either instances or (less often) individual items. Typically the patron doesn't care which item they get, but sometimes they do.


### Scenario 3: submitting a dissertation

Workflows for dissertation submission vary widely between libraries. Here is one possible flow.

* A student submits her dissertation.

* The submitted dissertation is added to the institutional repository (IR) with status "not yet accepted".

* Examiners evaluate the dissertation. Assuming it is adequate, they arrange and evaluate the student's defence.

* Depending on their verdict, the status of the dissertation in the IR is updated to "accepted", "rejected" or "revisions required".

* If revisions were required, the student submits a revised dissertation.

* The revised version is added to the IR with status "not yet accepted". It now becomes the version that is discovered by default in the IR, but retains history so that the original submitted version can still be obtained.

* The examiners evaluate the revisions. Assuming they are acceptable, the status of the revised manuscript in the IR is updated to "accepted".

* Once the dissertation is accepted (whether with or without revisions), the cataloguing librarian writes an abstract and it is added to the library catalogue.

Note that this example extends FOLIO workflow's influence outside the library to the institutional repository and even potentially to the dissertation examination process.



## Use of data in workflows

It will be apparent from the scenarios above that many kinds of data are going to be involved in workflows:
instances,
items,
dissertations,
locations,
holds,
purchase requests,
purchase orders
and more. Each of these kinds of object will presumably be represented by its own kind of record within FOLIO, defined by its own schema and stored by its own back-end module. For many of them there will also be a front-end module allowing users to manage them.

This raises several issues.


### Implicit or explicit data-passing?

Do we want to implicitly pass anonymous records from one step in a workflow to the next, analogously to how Unix pipes data between processes? Or do we need workflows to explicitly name objects and refer to them by name subsequently?

First approach:
```
book < getPatronRequest | findSource | obtainBook
```
Second approach:
```js
request = getPatronRequest(book)
vendor = findSource(request)
obtainBookFrom(book, vendor)
```

The former is terser and more elegant when it works, but the latter is more explicit and expressive. It's nice to imagine that we could support the simpler style when it's sufficiently expressive, but also the more explicit style when it's needed.

Is there precedent in existing programming languages for supporting both styles? The shell itself offers something along these lines, but it is rather inelegant. The second approach would look like:
```
getPatronRequest `cat book` > request
cat request | findSource > vendor
cat vendor | obtainBookFrom `cat book`
```
I would hope we could improve on that.

It will be possible to think about this in more detail once we start to sketch the representation of workflows (see [below](#expressing-workflows)).


### Pass by value or by reference?

Should the objects that are inputs to and outputs from workflow steps be whole objects, or merely references to them?

In the former approach, we would be passing around, for example, item records with `id`, `title`, `barcode` and `status` fields; and workflow steps would make changes to the in-memory records and pass the changed versions on.

In the latter approach, we would be passing only the ID that points to the relevant item in the data store; and workflow steps would need to fetch the record in order to see data fields, and to write back modifications.

The latter approach is less efficient, in that most steps will need to carry out several HTTP requests. That may not be a fatal objection, though: more important is getting the conceptual model right.


### Notion of object type

Whether we use pass-by-value or pass-by-reference, we will need an explicit notion of object type. If we pass only IDs, we will need to know the type of each object so we can look it up in the appropriate back-end service when we need data from it; and even if we pass whole objects, we will still need to know the type so that we can determine what service to use to persist changes.

For the purposes of this document, we will refer to objects with a simple [URN](https://en.wikipedia.org/wiki/Uniform_Resource_Name)-like scheme where type-specific IDs look like `item:234` or `instance:543`. But that should not be taken to indicate a preference for passing by reference: it's just a notation adopted for convenience.

Since we will need a notion of type, we may well wish to make it more explicit and visible within FOLIO. For example, we could introduce a type registry similar to those in operating systems like macOS, allowing users to register their preference of which application to use when viewing objects of a given type: "When I get an object of type `user` I want to use the `@folio/users` app to open it" (i.e. the standard Users application) but "When I get an object of type `item` I want to use Frontside's `@fontside/pretty-users` instead".


### Workflow state vs. object state

Does a workflow instance have its own state separate from the state of the objects it deals with? That is, does it suffice to mark a purchase as "needs authorization", or do we also need to mark the workflow instance that generated this purchase as "awaiting purchase authorization"?

Suppose the progress of a job is halted on the need for a purchase order to be okayed by someone with sufficient authority. We do not need to assign the responsibility for doing this to an individual: there may be a whole group of people who can OK the purchase. So it's tempting to imagine we could place some kind of trigger on the purchase record itself to restart the workflow, and so avoid having the workflow instance itself track where it is in its sequence of operations. But making all the other kinds of task workflow-aware may spread the responsibility thinner than we want. Lots more thought required here.

If the workflow instance has its own state, then we can tie together related operations after the event. Workflow can be a useful source of audit capability, perhaps saving individual services from having to do excessive audit logging.


### Data standardisation

Our experience of information systems is that data-cleaning is invariably a more extensive and costly task than anticipated. Experience of workflow systems in scientific contexts corroborates this impression: large sections of scientific workflows tend to be concerned with transforming and massaging data -- both on input, to make it amenable to processing, and on output so it is usable to the destination system.

Happily, much of this difficulty should be avoidable in the context of FOLIO, as we will generally be dealing with data that has already been canonicalised on entering the system. So data normalisation should not be something that most workflows need to worry about.

However, importing data from other systems may well be one of the important use-cases for the workflow mechanisms. It is useful that workflow mechanisms provide us with a means to script and customise import.

Since we aim to import data without human intervention, this process would usually be classified as automation; but these processes will be able, if necessary, to delegate to a human to fix problems encountered along the way.



## Implementation analogies

To help guide our thinking as we begin to consider implementation, it's useful to consider some analogies -- none of them perfect, but each potentially shedding some light on the problem we need to solve and how it is best modelled.


### Finite state machine with transitions

A workflow can be seen as defining a state machine with a start state, a desired end state, and a set of transitions between states which can result in arriving at the end state.

Considering it in these terms may help us to think more clearly about what kind of state needs to be represented and where it is best maintained. Most fundamental here is the question of how much state we want to centralise within the workflow instance itself, and how much can reside in the affected objects (items, instances, etc.).

In practical terms, the entire FOLIO database contains state (as all databases do). This is far too much state to model coherently, and we will be interested in the transitions between possible states of only a small part of this.


### Makefile-like dependency tree

In many cases, a workflow will require that some set of two or more tasks are completed before it can proceed to the next step, but the order in which those tasks are completed does not matter: for example, it might require one person to validate the choice of a book to buy, while another person clears funds for the purchase:
```
        Request received
             /    \
            /      \
           /        \
          v          v
Request cleared    Funds acquired
           \        /
            \      /
             \    /
              v  v
           Place order
```

The combination of these requirements cannot be satisfactorily modelled as a sequence of steps, since we do not wish to make one person wait until the other has finished his part of the job. Such situations may be better expressed by considering each task as separate, and specifying a directed acyclic graph of their dependencies. In the Unix `make` program, it would be specified something like this:
```
**target**: placeOrder

placeOrder: requestCleared fundsAcquired
	doPlaceOrderActions

requestCleared: requestReceived
	doRequestClearedActions

fundsAcquired: requestReceived
	doFundsAcquiredActions
```

(In practice, most implementations of `make` run tasks one at a time, but some implementations really do run parallel tasks simultaneously on multi-processor machines.)

If we go some way towards adopting this model, we will face the challenge of integrating `make`-like dependency-graph syntax with the more conventional programming-language syntax used in whatever DSL we come up with.


### Connector Framework

The FOLIO workflow system has several points in common with the
Index Data Connector Framework (CF), and experience gained on that project may be valuable here.

* Workflows, like connectors, are composed of functional steps that perform high-level, domain-specific operations. (For example: "Navigate to URL", "Fill form field", "Parse HTML", etc. in the Connector Framework; "Create item record", "Obtain human confirmation", "Place purchase order", etc. in FOLIO workflow.)

* Workflows, like connectors, will need a persistent representation -- possibly several (see [below](#expressing-workflows)).

* FOLIO workflow, like the Connector Framework, will need a powerful and general "Transform" step to handle data-cleaning.

* The separation between CF Engine and the CF Builder mirrors that between the FOLIO Workflow Engine (which we probably need for v1) and the Workflow Editor (which is not for v1).


### Very high-level DSL

Another way to think of workflows is as programs written in a very high-level domain-specific language (DSL). In this language, fundamental operations are not on integers and strings, but on high-level objects such as items, loans and invoices. Many operations will be implemented in whole or in part by CRUD requests against Okapi.

In these respects, such a DSL will resemble commands in the forthcoming Okapi CLI ([OKAPI-425](https://issues.folio.org/browse/OKAPI-425)).

However a workflow DSL will require control-flow primitives -- and, most likely, domain-specific primitives such as the ability to iterate over all books in a delivery, or all items related to an instance. See [below](#control-flow).



## Implementation strategy

With these analogies in mind, and aware of the three workflow scenarios outlined above, we can now begin to sketch what an implementation might look like. We will first investigate the interaction between front-end and back-end components; then consider the need for a virtual machine that can run workflows, before considering different representations -- for humans and computers -- of workflows. We'll then consider some of the operations that we will need to be able to represent and execute, and finally work through what will be required to track the state of an in-progress workflow, and how to handle errors.


### Front-end/back-end interaction

Leaving aside the v2 Workflow Editor, which is outside the scope of this document, we expect that most or all of the workflow implementation will be on the back-end. In fact, this is necessary for it to function in automation: we cannot have background tasks stop executing when the user's browser is closed. So while workflows will often be invoked from the front-end, the effects must run mostly on the back-end. (Some workflows will also be started from the back-end: for example, scheduled jobs.)

In some cases, front-end involvement will of course be necessary: for example, when a librarian is required to OK a purchase. Much of the design work in the Workflow system pertains to how this can be done. The most promising approach seems to be using the FOLIO notification system to inform individuals when a task awaits their input. Then we can make it possible for individuals to configure how that system treats various kinds of notifications: see [the Appendix](#appendix-a-using-the-notification-system) for details.

In other cases, front-end/back-end interaction will be simpler and more transitory. Consider for example a workflow to create a new item record based on a specific instance. The workflow will embody the knowledge of which instance fields to copy across to the new item record, and how to modify those fields, but the result will likely not be the immediate creation of a new item record, but rather transitioning the UI to a "create new item" page with the form already largely filled in. In this scenario, we expect that no new record is persisted within FOLIO until the user hits the Save button.


### Virtual Machine for running workflows

At the heart of the Workflow Engine will be a virtual machine that can interpret instructions to execute the high-level actions that constitute a job. It will need the ability to load the instructions that make up a workflow using some persistent format (see the next section), and to move through the steps while maintaining an appropriate notion of the workflow's state, which must be able to persist across long jobs that involve human intervention.

We have at least two candidate approaches for how to implement the Workflow VM. These are:

* Interpreting each operation and executing it directly from an engine.

* Compiling workflow to some existing language and running it within that language's execution environment, in the presence of a runtime system that provides the necessary APIs for actually executing the steps. For example, we might compile to JVM instructions (or to a JVM language such as Groovy or Java itself) and run inside a Java Virtual Machine; or compile to JavaScript, and run under the Node interpreter.

While the second approach is superficially appealing in that it seems to give us less work to do, that is largely an illusion: providing the runtime support will be the great bulk of the work. In comparison, creating an interpreter loop that can execute control-flow primitives as well as FOLIO operations will be only a little more work, but give us much more flexibility -- especially in dealing with the thorny difficulty of blocking on steps that require human action that may not be completed for days or weeks.

At least initially, the control gained by executing workflows inside
our own VM outweighs any possible performance gain from compiling to a
language with an optimised execution environment. And this is likely
to remain true, as the overhead of primitives like looping and
branching is going to be absolutely swamped by the much more expensive
operations being executed: Okapi requests and suchlike.


### Expressing workflows

Surprisingly, there could conceivably be as many as four different
representations of workflows.

#### XML or JSON

We will likely (but not necessarily -- see [discussion](#discussion) below) have a representation of workflows that is simple for machines to parse, and which is stored in the FOLIO database as the canonical representation of workflows. This format is analogous to the XML representation of connectors in the CF, although we might conceivably pick a different metaformat in 2017: JSON is a contender.

#### Human-readable/writeable DSL

XML and JSON are difficult for humans to write: consider, for example, a typical CF connector such [the PLOS ONE connector](http://cfrepo.indexdata.com/repo.pl/allcon/PLoS_ONE.10.cf). This is for a relatively well-behaved site, yet it comes to more than 700 lines of XML, much of it difficult to follow even for those already familiar with CF concepts.

This is not a problem in the CF, because we have the CF Builder to create these for us. However, the analogous Workflow Editor is a very substantial piece of work, which we will not even begin to work on until after the v1 release. Until then, we will need a reasonable way of authoring workflows. A high-level domain-specific language is the obvious way to do this: it will not enable regular librarians to author workflows, but will make it easy for developers to do so.

It's likely that we will find ourselves sketching workflows in a high-level pseudocode in any case. So going ahead and creating an interpreter that can run those workflows directly (or compile them into a form that can be run) seems like an obvious step.

#### Compiled form

When a workflow is loaded into the engine -- whether from an XML/JSON format file, or a DSL -- the result will be an in-memory representation, most likely a tree, that can be directly executed. We may find it useful to eliminate the overhead of parsing and compiling by storing the compiled version in a binary format that can be loaded very quickly -- analogous to Java's `.class` files. Or perhaps the potential efficiency gain will be little enough that we benefit more from simplicity of just compiling every time and running directly from the internal representation, as Perl, Python and JavaScript do.

#### Visual representation

The fourth and final form of workflows is the visual representation that will appear in the v2 Workflow Editor. This will need to parse stored workflows (from XML/JSON or a DSL) to determine what to draw on the page; and it will need to render edited drawings back into a form to send back to the server.

#### Discussion

Four representations of workflows certainly feels like too many. For the moment. We can simplify matters by ignoring the visual representation, which certainly will not be in v1, but certainly will need to appear in a subsequent version. Of the other three representations, how many do we need?

We can certainly do without the compiled form, at least in early versions of the workflow implementation. This is purely an optimisation, to reduce parsing overhead, and can be ignored until and unless profiling shows that it is needed.

But that still leaves us with two forms: XML/JSON and the DSL. In one conception, the latter exists as a human-maintainable form to compile into the former. But in that case, do we even need the XML/JSON version? Instead, the DSL could itself be the canonical form: workflows will be written by developers, using the DSL; they will be stored in the FOLIO database in that form; then they are compiled and run directly from the parse tree by the Workflow Engine. Later on after v1, these workflows will be compiled and translated into visual form by the Workflow Editor, which will then emit updated workflows in the same DSL, and write them back to the database.

So it seems possible that we have no pressing need for an XML/JSON form.

What language should we write the DSL parser in? (Or, if we decide to make an XML/JSON representation canonical, the parser that translates raw parse trees into an executable form?) In a future version of FOLIO, we will need to parse and render this language on the client side for the Workflow Editor, so we will need an implementation of the parser/renderer in JavaScript. That suggests we should create those JavaScript implementations for version 1, using them on the server side initially, and avoid later having two separate implementations in different languages. This may mean that the workflow compiler becomes the first Okapi module written in JavaScript; or it may entail somehow calling out from an RMB-based module into a separate JavaScript compiler/renderer.


### Data types

The workflow VM will need to represent, and provide operations on, several data-types. These include the obvious primitives:
* `integer`
* `boolean`
* `string`

And of course structured types:
* `array`
* `hash` (a mapping of key-names to values)

But also possibly domain-specific types:
* `item`
* `instance`
* `loan`

It is an open question whether we need to reify domain-dependent concepts such as items and instances, or whether it will suffice to blindly operate on named fields. If we do add type-specific operations, where would they be defined? If the Engine is made schema-aware, and is able to read the necessary JSON Schema files (where from?), what additional capabilities would that facilitate?


### Operations

We now consider some of the operations that will need to be supported by the Workflow Engine. These will most likely be represented by nodes in a parse tree or equivalent.

#### Okapi calls

Most fundamentally, we will need operations for CRUDding various kinds of objects: items, instances, loans, etc. A workflow for renewing a loan will consist primarily of fetching the loan (HTTP GET), modifying its due-date, and rewriting it (HTTP PUT). So we will want a very efficient, readable way of specifying such operations. Perhaps something like:
```js
record = fetchItem(id)
// Make whatever changes we wish
storeItem(id, record)
// Oh, we changed our mind
deleteItem(id)
```
Or maybe something more explicit along the lines of:
```js
record = fetch(`/items/${id}`)
// Make whatever changes we wish
store(`/items/${id}`, record)
// Oh, we changed our mind
delete(`/items/${id}`)
```
(Or of course could implement the former in terms of the latter.)

#### Record manipulation

Manipulation of records will be the other major part of most workflows. These changes, typically made to a single field at a time, fall into several categories:

* Adding a field, or appending a new subfield to an existing field.
* Replacing the value of an existing field.
* Deleting a field or a subfield.

It seems clear that the model will need to recognise subfields from the outset, and that we may need to handle both structured and list fields (analogous to JSON objects and arrays).

Transformations of fields will need to be supported: at minimum, the ability to copy one field, transformed by regular-expression substitution, either to another field or back to itself. For example, we may need a workflow step to normalise names from "Brian W. Kernighan" form to "Kernighan, Brian W." form:
```
assign author = author: /(.*) (.*)/ to "\2, \1"
```

Or to reset a loan date while remembering the old one:
```
append oldReturnDates, returnDate
assign returnDate = $1
```

#### Control flow

Like any sufficiently expressive language, the Workflow language will need primitives to control the flow of execution.

In the Connector Framework, we tried initially to sidestep this requirement by providing the "simpler" alternative of alternative steps; this proved insufficiently expressive, and the Skip-If step had to be introduced, leaving us with an unsatisfactory situation that has neither the simplicity we desired or the expressiveness we might prefer. For this new VM, it's better to face the problem of control-flow head on, and design it in from the start.

We will of course need the standard set:
* `if` / `then` / `else`
* `while`
* Maybe `do` ... `while`

And perhaps some domain-specific iterators:
* `foreach` item related to an instance
* `foreach` loan held by a patron
* `foreach` patron in a group

It's not yet clear how these would best be expressed, and whether they would need the schema-aware type system hinted at [above](#data-types).

More importantly, we will need control flow for parallel jobs. Consider the [earlier example](#scenario-1-acquisition-of-a-requested-book) of a request to buy a book, which must be cleared by a librarian and the funds acquired by a purchaser. Since both these tasks require human intervention, they will typically take hours, minutes or even days -- so parallelising is indispensable to avoid long delays.

How might such a control-flow be most cleanly expressed? Perhaps something like a `doall` keyword which governs a comma-separated list of statements?
```js
doall
  authorizeChoice(),
  clearFunds()
```

Or, with braces for clarity:
```js
doall {
  authorizeChoice(),
}, {
  clearFunds()
}
```

#### Subroutines

In many cases, one workflow will need to invoke another. This is equivalent to a subroutine call. In fact, we can think of individual workflows as simply being subroutines -- and the ones that we invoke from the UI as being like main functions.

Note that this requirement makes explicit the notion that workflows must take arguments. When invoking workflows from the UI -- as, for example, a "make new item for this instance" workflow -- some of the parameters will be determined by the context: for example, "this instance" would be the item that the user is viewing when invoking the workflow. In other contexts, some or all of the arguments will need to be explicitly specified.

#### Human interaction

So far, all the operations we have considered can be executed by the computer: they constitute automation. But what marks workflow out is that it involves the actions of humans. The workflow language will need a way to express what inputs are required from users, and which users can provide them. In some cases, an individual user may be specified; in others, any member of a specified group will suffice. In yet other situations, we might want to specify that particular action can be completed by any user with a specific permission.

The problems of notifying users of their responsibilities, and of resuming a workflow once their operations are completed, are among the most difficult to be solved in implementing workflow. We will discuss them in more detail [below](#tracking-jobs).

#### Other

Besides these operations, there will no doubt be others that we've missed so far: perhaps ways to use some form of local storage for persistent state that is outside of the library objects, for example. So the list above should be considered indicative, not definitive.

Besides actual operations, other kinds of nodes are likely to occur inside parse trees: regular expressions, for example (which may be reified as a type), arithmetic operations, string-manipulation primitives, and so on. (Perhaps these can be implemented as functions within the workflow DSL, rather than being true primitives.)


### Tracking jobs

While workflows are relatively permanent and static (like computer programs), workflow _instances_, or jobs, are temporary and dynamic (like Unix processes). Their state will change throughout their lifetime: even the simplest job will have a program-counter or equivalent pointer to the specific step that is in the process of being executed.

This would not raise any difficulty if we were merely building an automation system: in that case, jobs would be short-lived, and could reside entirely in memory. But the need for human intervention in workflows raises many difficulties. In particular, it requires us to somehow "freeze" the state of a job, potentially for many days, and subsequently resume it in response to a trigger.

### Some specific issues

* **How do we store the state of the in-progress workflow when a human action is required?** We will likely need a back-end module for CRUDding the status of jobs. This status will consist of at least a reference to the workflow that is being run, a pointer into that workflow indicating which step to run next, and some information about what human interventions are awaited. This status will not need to be transmitted outside of the server, so there is no need for a serialised or human-readable form.

* **What person, or class of people, may perform the required action?** We will want some flexibility in how a workflow is able to specify this. In some cases, we will want specifically to require that it be the person who launched the present instance of the workflow.

* **How do we notify the person or class that the action needs to be performed?** Hopefully the general-purpose notification system will work well for this, and will provide an appropriate level of configurability.

* **How do we recognise when the action has been completed?** There are broadly two approaches to this: either the workflow engine can periodically poll the state of all pending actions; or non-workflow objects can have triggers attached to them. For the latter approach, consider job #3456, which requires a librarian to validate purchase order #99. Then we would add a trigger to purchase order #99 saying "when validated, trigger job #3456".

* **How do we notify other members of a class when one of them has done it?** We don't want to have a dozen finance-approved librarians all to go to approve the same purchase order, only for eleven of them to find it's already been done, so we will want to cancel notifications that have been sent. Sending a new "This has been done so you don't need to" notification would be a start; better still would be simply deleting any of the original notifications that have not been read, so that the other librarians never even need to know that anything happened.

* **What happens if someone other than a member of a nominated class performs the action?** For example, if a purchase is approved by someone from a different department who happens to have the necessary authority, we will want this to trigger the continuation of the workflow just as though one of the nominated people had performed the action -- in fact, we probably don't even want to make a distinction between nominated people and others, except in terms of sending notifications to the former (and cancelling them when appropriate). This is an additional argument for the idea that the state-change itself must trigger the continuation of the workflow, rather than using an approach where the job itself is in control of the sequence of operations.

* **How do we resume the correct workflow when the action has been completed?** Using either the polling approach or the triggering approach, FOLIO will be in a position to know when an event that a job is dependent on has been completed. At this stage, it will need to hand control back to the job, which can then determine whether _all_ the dependent tasks have been completed, or if more remain. If they have all been completed, then execution can resume from the next instruction that the program-counter points to.

* **How can we cope when a single action triggers the resumption of multiple jobs?** This scenario would occur if, for example, a patron has a hold on a circulated item, and that patron's issue-new-loan job wakes up when the item is returned to the library; and a librarian has also started a workflow to do with refurbishing the item. Then both jobs depend on the same event, the return of the item. In this case, either the polling will need to recognise that multiple job have had their blocking tasks completed, or the item record in question will need multiple triggers to be installed.

* **What can we do if a workflow is edited while an instance of it is running?** A job may run for a long time, so it is quite possible that the workflow that it's an instance of may be edited. This will render the program-counter stored in the persistent job incorrect. The simplest solution is to have the job carry a complete copy of the workflow that it's running. There are more efficient, though correspondingly more complex, solutions. For example, if each job only references a workflow, then the code that updates a workflow could keep the old version around if there are any running jobs that reference it, with some kind of garbage-collection mechanism to dispose of no-longer-referenced workflows once their jobs are complete.


### Error handling

The complex, parallelised and long-running nature of workflow jobs means the error handling is going to be rather more complex than in most software. In general, we will want to support various severity levels: some causing the whole job to fail immediately, others allowing the job to continue but being accumulated somewhere so that they can be inspected after the job completes (or, for that matter, while it's still ongoing). For example, consider the unboxing scenario above: perhaps three of the books can't be shelved, but that is no reason not to handle the others. At the end, there should be a report, "here are the three books we weren’t able to do anything with, and here are the reasons why we couldn't handle each of them."

The way to handle errors needs to be configurable not just at the level of a workflow, but at the lower level of individual steps within the workflow: it is a matter for the creator of a given workflow to judge whether a given error should be fatal, or merely stored up to be reported while the job continues.

An additional level of complexity is introduced by the requirement for the workflow engine to allow several subtasks to run in parallel. What should happen when one of these fails?

* Should the whole parallel operation be considered to have failed?
* If so, should some attempt be made to roll back any of the other parallel tasks that have already run to completion?
* If some of the successful peer tasks were carried out by humans, should we notify them?
* If so, should we ask them whether or not to attempt reversion?
* How configurable should all of this be?

Much of the detail of this can be, and will need to be, deferred until well after the initial implementation, but it's important to appreciate the complexities to be sure we don't make some decision early on that precludes flexibility later.



## Appendix A: Using the notification system

It is clear that workflow will need to use a notification system to inform human users that their input is required, and quite possibly also to inform the workflow engine when such human tasks have been completed. Sample notifications might include:

* "Please authorize this purchase."
* "Please consider this suggested change to cataloging."
* "Someone else has done this task, there is no need for you to do it."
* "Your purchase request has been accepted."
* "Your purchase request has been rejected."
* "The job you started has completed successfully."
* "The job you started has failed, with the following errors ..."

In this document, we have assumed that workflow will use the FOLIO notification system that has already been [designed and prototyped](http://ux.folio.org/prototype/en/users?popover=notifications), rather than creating a new, largely overlapping, system. However, in order to fully serve workflows, though, the notification system will need to be flexible and configurable in ways that may not have previously been envisaged.

* We will need a notion of notification title -- a short piece of text analogous to an email's subject-line -- so that many notifications can be listed in a compact form.

* We will need a notion of notification type -- a token drawn from a small controlled vocabulary that will include values such as `po` (requesting sign-off on a purchase-order), `cat` (a cataloging request) and `ok` (notification of a successfully completed job). This will enable users to see at a glance what kind of work awaits them, and to sort notifications into categories so that they can, for example, handle all the cataloging requests together.

* We will need to provide users with the ability to configure how different types of notification are handled. For example, a librarian may elect to leave low-priority tasks such as a cataloging changes to be queued within FOLIO, to be picked up when the user finds it convenient; higher-priority tasks could be emailed out to solicit a more rapid response; and top-priority tasks might even interrupt a user who is working elsewhere within FOLIO. (As always, our goal here is to provide mechanism, not dictate policy.)

* Since we will need in some cases to forward notifications for delivery as email, it may be useful for notifications to have other fields analogous to those used in email, e.g. From, Date.

The notification system itself is a significant piece of work. It may be best to consider gateways that deliver notification via mechanisms such as email, text-message, tweet, etc., as their own separate and optional modules.

&nbsp;



## Appendix B: Related documents

The following documents and prototypes are relevant here:

* [Charlotte Whitt's workflow use-cases](https://docs.google.com/spreadsheets/d/1i0WKhIY04G38OQJ0KzbiIEUHat_5Wt-3kvFDMlrovK0/edit#gid=1999745637)
* [Filip Jakobsen's presentation of workflow editor UX](https://discuss.folio.org/t/zap-workflows-ux-iteration-3-english/1041)
* [Filip Jakobsen's presentation of notification UX](http://ux.folio.org/prototype/en/notifications?view=full)
* [Filip Jakobsen's "Design Bite" on notifications](https://discuss.folio.org/t/tangerine-design-bite-bell-notifications-in-the-ui/194)
* [Another, more rationale-focused, white paper on FOLIO workflow](https://docs.google.com/document/d/1Q_owoSAss2GfiQcMV7E8hd9JJRM11CxIpaYp-YKl9Bc/edit#heading=h.36347oo84qw8)
* [Ongoing discussion of other workflow systems](https://jira.indexdata.com/browse/INTFOLIO-6)



## Appendix C: Relevant standards

It seems there was quite a burst of work on systems like this in the early 2000s, but most of it came to nothing. Still, some of the artifacts that remain may be useful for helping us to think clearly through the issues, even if they have not generated actual software that we can use. They include:

* [BPEL (Business Process Execution Language)](https://en.wikipedia.org/wiki/Business_Process_Execution_Language) is an OASIS standard describing an XML format that can describe workflows. It emerged from, and obsoletes, IBM's WSFL (Web Services Flow Language) and Microsoft's Xlang, both of which can now be ignored. However, BPEL itself appears moribund: [the OASIS standard for WS-BPEL 2.0](http://docs.oasis-open.org/wsbpel/2.0/OS/wsbpel-v2.0-OS.html) is from 2006.

* [BPELscript](http://www.bpelscript.org/) is a human-readable representation of BPEL inspired by programming languages such as JavaScript. Its website was last modified in 2008, however. [Code exists on GitHub](https://github.com/bpeltools/bpelscript) to translate Bpelscript into the XML format, and may be useful -- though [its licence is not clear](https://github.com/BPELtools/bpelscript/issues/14) and, a small documentation update aside, the code was last touched in 2012.

* [BPEL4People](http://docs.oasis-open.org/ns/bpel4people/bpel4people/200803) "introduces a BPEL extension to address human interactions in BPEL as a first-class citizen" (from [the specification](http://docs.oasis-open.org/bpel4people/bpel4people-1.1-spec-cs-01.html)). This seems very relevant to our interests, but once again seems to be have been abandoned: there is essentially no discussion of it apart from the 2010 standard itself.

I have not been able to establish that these specifications have been adopted widely, or at all, or that they have been superseded by anything more modern: it seems that the world has simply lost insterest in standardising this kind of functionality. I assume that the various commercial operations have simply each gone their own way with proprietary offerings.

My sense is that we can probably learn something from the notation of BPELscript and from the human-role analysis of BPEL4People, but that we will likely still need to write our own software. One possible alternative might be to adopt the BPELscript translator, if its licence allows this, extend it to support BPEL4People, and use that as our workflow language.



<!--
COMMENTS FROM OTHERS

HEIKKI: You said in Montreal that "workflow instance" is a clumsy word, and proposed "job" instead. I liked that, and think you should sneak it into your document. (It _is_ in the document, but I lacked the courage of my convictions and kept using both terms. I'll make it more consistent.)

HEIKKI: I would like to append a comment to "Pass by value or by reference?": We can always optimize things later, when or if we find problems.

HEIKKI: "When I get an object of type item I want to use Frontside's @fontside/pretty-users instead" Should that not be "@fontside/pretty-items" ?

KURT: There's any number of existing scripting languages that we can turn into a DSL. I'd use Lua before rolling our own.

NASSIB: I know it has been popular lately to create DSLs, but there are some really great ones out there we could use for this. (So long as we have access to the parse-tree from JavaScript. "Roll out own" doesn't _have_ to mean building the whole thing. But it does mean we need to be able to get our fingers into the inner workings.)

HEIKKI: I think our CF worked pretty well with a small set of domain-specific steps. That also fits with the graphical editor. I think that would be the easiest way to get a good workflow engine.
If we use an existing scripting language, how on earth are we going to manage the various levels of error handling? I would not trust a librarian to remember to write code for all failure modes, but I would trust him to check a box "abort the job if this fails", or "list any failures in the error log, and proceed"
Besides, scripting languages might be too powerful, so we would need to sandbox them so they don't load untrusted modules, make random web requests, etc.

HEIKKI: One thing we did right in CF was our variable structure. Basically the whole state of the connector was kept in one javascript object, that was divided on the top level into input, output, tmp, and system. Any steps could access any of the variables with something like ${input.keyword} and we had standard settings for assigning a variable (overwrite value, append to the array, concatenate value, fail if empty, etc)
We could do the same in the workflow. That would make it easy to save the state of the job, and continue later.
And that would give us a good set of data types to work with - those defined in Json. We would probably not need to make users or items first class citizens for the workflow, they would be just json objects.  Also, a log of steps executed and of errors and warnings would fit in there too.

HEIKKI: For the first version, I think we could get away with a fairly small number of steps.
- Okapi request (GET, POST, PUT, or DELETE) with path, input data, and where to put the output data and error messages
- Some kind of data manipulation step, like the transform in CF.
- Suspend job until a condition is true. setting for how often to check, and when to give up
- Some way to iterate over an array
- Some conditional

-->
