---
title: REST's semantics are informal. Here is a formal alternative.
date: 2026-03-25
description: An entity protocol model and implementation.
abstract: What makes a good abstraction? Unix suggests they are possible; Docker suggests we have lost the habit. REST, often cited as a modern example of clean design, turns out to be informal where it matters most. This post develops a small alternative — a formal model for distributed state — and walks it from mathematical definition to working implementation.
keywords: entity model formal denotational semantics REST python
categories: posts
---

# Questions About Docker

As is often the case, it all started with a question that seemed unrelated to
the topic.

I was using Docker and wondered why images weren’t automatically saved as
files—files that we could copy, compress, pipe… just like any other file. At
first glance, that seemed like a more robust and straightforward approach. After
doing a bit of research, I found the following arguments justifying Docker’s
approach:

1. Disk space optimization: images are composed of layers, with each layer being
   shareable by an arbitrary number of images

2. Storage abstraction: storage can be handled in various ways, through Docker’s
   use of dedicated drivers

3. Layer composition: there isn’t really a single image file, just layer files
   and metadata that Docker composes to create the image

I thought to myself: OK, but wouldn’t it be more natural for the OS to provide
these features?

1. Disk space optimization: The OS could optimize file copies, for example via
   copy-on-write.

2. Storage abstraction: the OS can manage various filesystems

3. Layer composition: the OS typically provides, via the filesystem, the concept
   of directories, which allows data to be grouped and organized

Upon further research, I realized that this was true, but that in practice
operating systems sometimes provided these features only partially (`btrfs` and
`zfs` support copy-on-write, but `ext4`—which is the most widely used—does not),
in a non-standard way (no cross-distro package format for a filesystem snapshot
with metadata), only relatively recently (`overlayfs` was merged into the Linux
kernel in 2014, the same year Docker gained traction), or in a way that was too
low-level and difficult to integrate (`namespaces` and `cgroups`). Docker’s
contribution, therefore, laid more in usability and standardization than in
purely new features.

# It was better before

The last point in particular (difficulty of composition) struck me. Were the
abstractions too low-level or technical? This made me think, by contrast, of
Unix. I had the impression that its designers had produced good
abstractions—composable and easily understandable by humans: the file-based
approach, pipes, etc. This seemed all the more surprising to me given that these
“human-oriented” choices were made at a time when computers were very
resource-constrained and when it would have been, *a priori*, more obvious to
prioritize performance over usability: binary everywhere, low-level
abstractions, etc.

The designers of Unix gave me the impression that they prioritized the human
over technology. Hadn’t we lost sight of that a bit since then and leaned a
little too far toward the technical side? And besides, weren’t we simply not
very good at producing good abstractions? Looking at the quality and longevity
of abstractions in math, there was good reason to ask the question...

# Examples of good abstractions?

So I looked for examples of good “modern” abstractions. People mentioned Git and
the HTTP REST model in particular, describing them as clean, minimal, and
composable. As for Git, I thought the object model was fine, but when it comes
to repository composition, I was not so sure... Submodules seemed a bit limited,
like an afterthought. If the concept of a repository had been modeled from the
start using an algebraic structure, the concept of a morphism would surely have
been defined, and composition taken into account from the beginning. And we
might have solid ways today to compose repositories: product, sum, etc.

As for REST, I must admit that for me it mainly evoked entities addressable via
URIs and actions via HTTP verbs, but I didn’t know much more than that. I was
told: yes, but be careful, apps that claim to be REST are often just RPC over
HTTP and JSON, not true REST. Ah, so what was true REST? Well, according to
Fielding (the author of the original thesis), it was crucially HATEOAS:
Hypermedia As The Engine of Application State. To put it simply, after the
server receives a request (an action on a URI), it returns a list of URIs with
possible actions. Here is an example of a response:

```json
{
  "account_id": "12345",
  "balance": 100.0,
  "_links": {
    "deposit": { "href": "/accounts/12345/deposit", "method": "POST" },
    "withdraw": { "href": "/accounts/12345/withdraw", "method": "POST" },
    "history": { "href": "/accounts/12345/transactions", "method": "GET" }
  }
}
```

The client then knows what it can do: deposit money, withdraw money, view the
history. If, following the previous action, the account balance had dropped to
0, the server would not have sent the link to withdraw money. The server
therefore manages state transitions: it returns only the transitions that are
valid for the current state. The client, in theory, does not need to know the
interface in advance; it discovers it through the server’s responses. Another
benefit is that the server can modify the interface freely: it can add new
actions (for example, a transfer to a third-party account) or remove them. No
prior, external contract between the server and the client—everything is
dynamic; it’s great.

# Disillusionment

Or is that not the case? Alright, the system can work with humans, who are
capable of understanding actions even if they are new (undo, view history,
etc.), but what about machines? How could a machine know what to do with a new
action, such as “history”? We can see two possible solutions here:

1. a prior agreement between the client and the server is required, but that’s
   exactly what we were trying to avoid

2. a meta-system is needed to interpret the new action

Solution 1 contradicts the initial goal, and solution 2 requires something like
the Semantic Web—a massive infrastructure that hasn’t lived up to its promises
so far.

I had been sold on true REST as an example of good “modern” abstraction, but the
result left me a bit unsatisfied. So I decided to delve into these issues
(entities, actions, contracts) and settle the problem once and for all (or try
to).

# Avanti

What exactly did we need? Why not start with a short list? We needed:

- Entities, of course. For instance, bank accounts, people, etc.

- Coordinates. Entities needed these to be manipulable. Or, to put it more
  technically, they had to be addressable.

- Relationships between entities: the owner of an account, the age of a person,
  etc.

- Changes in entities over time. Entities could appear, change, disappear.

From a practical point of view, what actions could be standardized? First, the
actions involving changes to entities: create, alter, delete. Perhaps also
tracing, that is, viewing an entity’s history, its past states. But tracing
seemed different, more in the realm of properties, whereas the others were
strictly speaking actions. To simplify, I decided to extend the concept of
action to include tracing.

Another question: should entities and actions be represented in the same way? At
first glance, no—they were truly different things (a loose intuition might be
that in a category, objects and morphisms are of a different nature).

Before going any further, it might be helpful to give an example.

## Example

0. Initially, there are no entities.

    <!-- The comments in this section describe image contents. -->
    
    <!-- H(0) = {} -->
    ![no entity](/assets/img/h0.svg)

1. We create the entity “Bob”.

    <!-- H(1) = {(Bob, id, Bob)} -->
    ![entity Bob](/assets/img/h1.svg)

2. We create the entity “bank account 1,” which is linked to “Bob” by the
   “owner” relationship (Bob is the owner of bank account 1).

    <!-- H(2) = {
            (Bob, id, Bob),
            (bank account 1, id, bank account 1),
            (bank account 1, owner, Bob)
        } -->
    ![bank account 1 owned by Bob](/assets/img/h2.svg)

3. We create an entity “bank account 2”, also owned by “Bob”.

    <!-- H(3) = {
            (Bob, id, Bob),
            (bank account 1, id, bank account 1),
            (bank account 1, owner, Bob),
            (bank account 2, id, bank account 2),
            (bank account 2, owner, Bob)
        } -->
    ![bank accounts 1 and 2 owned by Bob](/assets/img/h3.svg)

    Note: We may also want to account for the concept of a set, for example, the set
    of bank accounts.

4. We delete “bank account 2”, which also deletes the ownership relationship
   with Bob.

    <!-- H(4) = {
            (Bob, id, Bob),
            (bank account 1, id, bank account 1),
            (bank account 1, owner, Bob),
        } -->
    <!-- ![bank account 1 owned by Bob](/assets/img/h4.svg) -->
    ![bank account 1 owned by Bob](/assets/img/h2.svg)

5. We delete “Bob”, which also deletes the ownership relationship with
   “bank account 1”.

    <!-- H(5) = {
            (bank account 1, id, bank account 1)
        } -->
    ![entity Bob](/assets/img/h1.svg)

Additionally, if we want to add information, such as Bob's age or the balance of
bank account 1, we can always add properties:

<!-- {
        (Bob, id, Bob),
        (bank account 1, id, bank account 1),
        (bank account 1, owner, Bob),
        (Bob, age, 23),
        (bank account 1, balance, 100)
    } -->
![entity Bob with extra properties](/assets/img/extra_properties.svg)


# Beginning of Formalization

Let’s revisit the previous example. We have a sequence of states, each state
consisting of entities and relationships. Transitions from one state to another
correspond to the actions create, alter, and delete. To describe the
relationships, the simplest approach is to use predicates in the form of triples
(subject, predicate, object). In a triple, the predicate corresponds to an
arrow, the subject to the entity at the source of the arrow, and the object to
the entity at the destination of the arrow. An entity is represented by an
identity relation of the entity to itself in order to form a triple.

If we denote the sequence of states by $H$, for “History,” and follow the
numbering from the example, we obtain:

```equation
• H(0) = {}

• H(1) = { (Bob, id, Bob) }

• H(2) = { (Bob, id, Bob),
         (bank account 1, id, bank account 1),
         (bank account 1, owner, Bob) }

• H(3) = { (Bob, id, Bob),
         (bank account 1, id, bank account 1),
         (bank account 1, owner, Bob),
         (bank account 2, id, bank account 2),
         (bank account 2, owner, Bob) }

• H(4) = { (Bob, id, Bob),
         (bank account 1, id, bank account 1),
         (bank account 1, owner, Bob) }

• H(5) = { (bank account 1, id, bank account 1) }
```

<!--
\begin{equation}\begin{split}
H(0) = \{ & \}
\\ \\
H(1) = \{ & (Bob, id, Bob) \}
\\ \\
H(2) = \{\ & (Bob,\ id,\ Bob), \\
           & (bank\ account\ 1,\ id,\ bank\ account\ 1), \\
           & (bank\ account\ 1,\ owner,\ Bob)\ \}
\\ \\
H(3) = \{\ & (Bob,\ id,\ Bob), \\
           & (bank\ account\ 1,\ id,\ bank\ account\ 1), \\
           & (bank\ account\ 1,\ owner,\ Bob), \\
           & (bank\ account\ 2,\ id,\ bank\ account\ 2), \\
           & (bank\ account\ 2,\ owner,\ Bob)\ \}
\\ \\
H(4) = \{ & (Bob,\ id,\ Bob), \\
          & (bank\ account\ 1,\ id,\ bank\ account\ 1), \\
          & (bank\ account\ 1,\ owner,\ Bob) \}
\\ \\
H(5) = \{\ & (bank\ account\ 1,\ id,\ bank\ account\ 1)\ \}
\end{split}\end{equation}
-->

For illustration, a state including Bob's age and the balance of bank account 1
would look like:

<!--
\begin{equation}\begin{split}
\{\ & (Bob,\ id,\ Bob), \\
   & (\text{bank account 1},\ \text{id},\ \text{bank account 1}), \\
   & (23,\ id,\ 23), \\
   & (100,\ id,\ 100), \\
   & (bank\ account\ 1,\ owner,\ Bob), \\
   & (Bob,\ age,\ 23), \\
   & (bank\ account\ 1,\ balance,\ 100)\ \}
\end{split}\end{equation}
-->

```equation
{ (Bob, id, Bob),
  (bank account 1}, id, bank account 1),
  (23, id, 23),
  (100, id, 100),
  (bank account 1, owner, Bob),
  (Bob, age, 23),
  (bank account 1, balance, 100) }
```

We now formalize this intuition.

# Formalization

We will proceed in an incremental way, with several models named $M₀$, $M₁$..., each
adding new features.

## Model $M₀$

Let $M₀$ be the model composed of:

- $E$, the set of all possible entities. $E$ contains notably all numbers.

- $State$, the set of all possible states, where a state is a set of entities and
  relations. $State = Subset(E × E × E)$

  Entities and relations are modeled in the same way, as triples. This is
  because in reality only relations are modeled, entities being considered a
  special case of relations. Indeed, a triple in $E × E × E$ has the form
  (subject, predicate, object) where subject and object can be represented by
  dots, and predicate as an arrow from subject to object. An entity, for
  instance Bob, is then modeled as a triple (Bob, id, Bob).

- $create$, a function that adds to the state an entity with the relations it is
  the subject:

  ```equation
  create : State × E × Subset(E × E) → State
  create(state, entity, relations) =
    state ∪ { (entity, id, entity) }
          ∪ { (entity, predicate, object) ∈ E × E × E | (predicate, object) ∈ relations }
  ```

- $delete$, a function that removes from the state entities with any triple in
  which they appear:

  ```equation
  delete : State × Subset(E) → State
  delete(state, entities) =
    state ∖ { (subject, predicate, object) ∈ E × E × E | subject ∈ entities ∨ object ∈ entities }
  ```


## Implementation of $M₀$

$M₀$ can be implemented as a client-server protocol. The client sends commands and
the server updates its state. The commands are `CREATE` and `DELETE`. Each command
takes one or more parameters and may have a body. For example:

- `CREATE path { key1: value1, key2: value2, ... }`

- `DELETE path`

"path" designates a priori a single entity (e.g. `/bank-accounts/1`) or a set of
entities (e.g. `/bank-accounts`). To unify we will consider that a path always
designates a set of entities, the single-entity case being considered as a set
containing this single entity. We will say that some entities exist at a given
path.

In the case of `CREATE`, the path must designate an empty set, i.e. there must not
be any entity at this path. The body of the command is enclosed in curly
brackets. In the body, each key represents a predicate and each value the object
of the predicate.

We define the semantics of the protocol by the function $m$, which takes a
syntactic element to be interpreted and the state in which to perform this
interpretation:

- $m(CREATE path { key1: value1, ... }, state) =$
  $~~~~create(state, e, { (m(key1, state), m(value1, state)), ... })$ where:

    + $m(path, state) = {}$ -- no entity at path

    + $(e, id, e) ∉ state$ -- e is an entity not in state

- $m(DELETE path, state) = delete(state, m(path, state))$

### Example

Here is an example of a sequence of commands. The state is initially empty (no
entity and no relation).

- `CREATE /bob`

Resulting state: contains only the entity `/bob`. Note that we name here the
entity following its path. This is merely for convenience, to avoid having to
invent a new name. Beware that this is just a naming convention and that paths
and entities are different notions.

- `CREATE /bank-accounts/1 { owner: /bob }`

Resulting state: contains also an arrow from `/bank-accounts/1` to `/bob`.

- `CREATE /bank-accounts/2 { owner: /bob }`

Resulting state: contains also an arrow from `/bank-accounts/2` to `/bob`.

- `DELETE /bank-accounts/2`

Resulting state: contains only an arrow from `/bank-accounts/1` to `/bob`.

- `DELETE /bob`

Resulting state: contains only `/bank-accounts/1`.

## Model $M₁$: Alteration

In $M₀$, if we want to alter an entity, we have to delete it and create a new one.
If we consider that each state is observable, this can pose a problem because
the alteration is not atomic. Moreover, deletion removes the triples whose
object is the entity while creation only add triples whose subject is the
entity, so a deletion followed by a creation may lose information. Concretely,
`DELETE /bob` wipes `(bank-accounts/1, owner, bob)` but a subsequent `CREATE
/bob {age: 23}` does not restore it. We therefore provide a definition for
alteration that is not simply in terms of creation and deletion:

- $alter$, a function for alteration not in terms of creation and deletion:

  ```equation
  alter : State × E × Subset(E × E) → State
  alter(state, entity, relations) =
    (state ∖ { (entity, p, o) ∈ state | p ∈ predicates(relations) }) ∪ { (entity, p, o) | (p, o) ∈ relations }
  ```

  where

    + $predicates(relations) = { p | (p, _) ∈ relations }$

- $m(ALTER path { key1: value1, ... }, state) =$
  $alter(state, entity, { (m(key1, state), m(value1, state)), ... })$ where:

    + $m(path, state) = {entity}$

Alteration suggests that entities can change, which is not true in $M₁$ since
entities are values, i.e. they are immutable. However a path, which is a notion
that is external to $M₁$, provides an identity by allowing to relate the
potentially different entities that live at the same path in different states.
In this sense, a path plays the role of a variable.

$M₁$ does have a notion of execution. An execution is a sequence of commands
$c₀$, $c₁$, ... The state then evolves inductively:

- $state₀ = {}$  -- the empty set

- $stateₙ₊₁ = m(commandₙ, stateₙ)$


## Model $M₂$: History

We may be interested in the successive relations of the entity living at a given
path. By an abuse of language, we will say equivalently that we watch an entity.
Watching an entity means getting the relations of which it is the subject, from
its creation to its deletion.

To this end, we define the history $H$ of an execution. H is a sequence of (state,
command) pairs, defined by:

- $H: History$ where $History = ℕ → State × Command$, and
    $Command = { CREATE p {...}, ALTER p {...}, DELETE p }$

- $H(0) = ({}, ⊥)$ where $⊥$ denotes the lack of command leading to the initial
  state

- $H(n+1) = (m(commandₙ, H(n).state), commandₙ)$

$H$ is not an independent object — it is uniquely determined by the command
sequence. $M₂$ does not add new data, it adds a new perspective on what $M₁$ already
produces.

Note that $H$ is the complete history, including past and future.

We want to watch an entity until it is deleted. We introduce the `WATCH` command
which returns a sequence of relations where the entity at path is the subject.
The complete version watches an entity over at most the interval from stateₙ to
stateₘ, with $n ≤ m$. This is a maximal interval since it is bounded by the
lifetime of the entity at p, i.e. from its creation to its destruction.

- `WATCH path { from: n, to: m }`

This command covers at least two different use-cases:

1. the history of an entity if `n` is in the past and `m` is now

2. the subscription to future values if `n` is now and `m` is in the future

To define its semantics, we first define the $watch$ function:

<!--
- ```equation
  watch : Path × ℕ × ℕ × History → Seq(Subset(E × E))
  watch(path, n, m, H) = (k ∈ 0..(m'-n'-1) ↦ local(path, n'+k, H)) where

    n' = min({ k ∈ n..m | m(path, H(k).state) ≠ {} } ∪ { m }) -- first state in the interval with non-empty path

    m' = min({ k ∈ n'..m | m(path, H(k).state) = {} } ∪ { m })

    local(p, k, H) = { (predicate, object) | s ∈ m(p, H(k).state) ∧ (s, predicate, object) ∈ H(k).state }

    Seq(A) = ⋃ { 0..(len-1) → A | len ∈ ℕ }
  ```
-->

- $watch : Path × ℕ × ℕ × History → Seq(Subset(E × E))$
  $watch(path, n, m, H) = (k ∈ 0..(m'-n'-1) ↦ local(path, n'+k, H))$ where

    + $n' = min({ k ∈ n..m | m(path, H(k).state) ≠ {} } ∪ { m })$ -- first state in the interval with non-empty path

    + $m' = min({ k ∈ n'..m | m(path, H(k).state) = {} } ∪ { m })$

    + $local(p, k, H) = { (predicate, object) | s ∈ m(p, H(k).state) ∧ (s, predicate, object) ∈ H(k).state }$

    + $Seq(A) = ⋃ { 0..(len-1) → A | len ∈ ℕ }$

$Seq(A)$ includes the empty sequence ($len = 0$), because $0..(0-1)$ is empty.

Note that if the path is empty throughout $n..m$, then $n' = m$, $m' = m$ and the range
becomes $0..-1$. Therefore, watch returns an empty sequence as expected.

Also note that when path designates a set of entities, watching stops when the set
becomes empty. This can happen in two cases:

1. when the set is deleted (e.g. `DELETE /bank-accounts`)

2. when all entities inside the set are deleted (e.g. `DELETE /bank-accounts/1` ;
   `DELETE /bank-accounts/2`)

The model does not attempt to distinguish these two cases.

We define a new semantic function w that takes the history as input, instead of
a mere state as is the case for m:

- $w: Command × History → Seq(Subset(E × E))$
  $w(WATCH path { from: n, to: m }, H) = watch(path, n, m, H)$

### Variants

From the complete form, we define several variants.

- $w(WATCH path { to: m }, H) = w(WATCH path { from: 0, to: m }, H)$

It is also possible to watch from a specific point. We assume the entity at path
is eventually created and eventually deleted:

- $w(WATCH path { from: n }, H) = (k ∈ 0..(m'-n'-1) ↦ local(path, n'+k, H))$ where
  - $n' = min({ k ∈ ℕ | k ≥ n ∧ m(path, H(k).state) ≠ {} })$

  - $m' = min({ k ∈ ℕ | k ≥ n' ∧ m(path, H(k).state) = {} })$

When $n$ corresponds to now, this models subscription.

## Model $M₃$: Real-world time

In practice, we'd also like to use `WATCH` with dates. This requires enriching the
definition of $H$ to add timestamps. Timestamps do not come from the model, they
come from the outside world. The only assumptions on them are that they are
totally ordered and they can be subtracted yielding a real or natural number.
Since the model cannot derive them inductively from previous states, we define a
timestamping function:

- $τ: ℕ → Timestamp$

$τ(n)$ is the timestamp assigned to the n-th command. This function is external to
the model — it is provided by the environment. There is a single precondition on
$τ$, namely that it should be non-decreasing: $τ(n) ≤ τ(n+1)$ for all n since time
does not go backwards.

Then $H$ and index are redefined as follows:

- $H: ℕ → State × Command × Timestamp$

- $H(0) = ({}, ⊥, τ(0))$

- $H(n+1) = (m(commandₙ, H(n).state), commandₙ, τ(n+1))$

- $index: Timestamp → Subset(ℕ) with index(t) = { k | τ(k) = t' }$ where
  - $t' = min { τ(k) | abs(t - τ(k)) = d }$ -- if no command bears exactly timestamp $t$, we snap to the nearest one

  - $d = min { abs(t - τ(k)) | k ∈ ℕ }$

Note that d exists since the set of distances is non-empty and bounded below by 0.

Note: Contrary to $M₂$, $H$ depends not only on the command sequence but also on the
external function $τ$.

The semantics of the timestamped `WATCH` is then simply:

- $w(WATCH path { from: t0, to: t1 }, H) = watch(path, min(index(t0)), max(index(t1)), H)$

We can also define a version where the range is left implicit:

- $w(WATCH path, H) = w(WATCH path { from: now }, H)$ where
  - $now ∈ Timestamp$ and is provided by the environment (it is external to the
    model)

## Model $M₄$: Read

A `READ` command can be added for convenience. It adds no new expressive power,
only notation:

- $w(READ path, H) = w(WATCH path { from: now, to: now }, H)$ where
  - $now ∈ Timestamp$ and is provided by the environment

This definition therefore depends on the timestamped version of `WATCH` defined in
$M₃$.

# Toy implementation

We now present a toy implementation of the final model ($M₄$).

We create a server listening to requests on a TCP port, connected to a separate
database, notifying watchers on changes. The server handles one persistent
connection per client. Each line received is parsed as a request.

The server is written in Python 3.14 with asyncio. It records data (`CREATE`,
`ALTER`, `DELETE`) in a database known by its URL passed by env var.

## Database

The data is stored in a PostgreSQL 16 database. The tables are:

- `Users {name, age}`

- `BankAccounts {id, owner, balance}`

- `Events { id, timestamp, command, path, body }`

`Users.name` is the primary key, mapping directly to `/users/<Name>`.
`BankAccounts.id` is the primary key, mapping directly to `/bank-accounts/<id>`.
`BankAccounts.owner` is a foreign key to `Users` with `ON DELETE CASCADE`
constraint.

`Events` is an append-only table. Every `CREATE`, `ALTER`, `DELETE` writes to `Events`
in the same transaction. This is what backs timestamped `WATCH` bursts and defines
"too far in the past" for 416 (the error returned when the requested timestamp
predates retained history). History is unbounded (a configurable retention
window would be a possible extension).

## Server in-memory state

The server maintains in its in-memory state who watches what, and sends answers
to watchers.

Watchers are notified after commit, not inside the transaction. This is to avoid
notifying on a rolled-back write. We accept the risk that a notification may
not happen if the process crashes between commit and notify.

On client disconnection, the watcher is silently dropped from the in-memory
state. We do not bother logging the disconnection for observability.

## Request and answer grammars

```
Request  := Command Path Body?
Command  := "CREATE" | "ALTER" | "DELETE" | "WATCH" | "READ"
Path     := ("/" Word)+
Body     := "{" (KeyValue ("," KeyValue)*)? "}"
KeyValue := Word ":" (Word | Path)
Word     := [a-zA-Z0-9_-]+
```

Note: Blanks between tokens are omitted in the grammar but allowed in practice.

Note: Values of `from` and `to` keys are parsed as Timestamp (see below); all
other values are Word or Path.

```
Timestamp := [a-zA-Z0-9_:+-]+
```

Timestamps are ISO 8601 strings, e.g. `2024-01-01T00:00:00Z`.

Answers are also sent in plain text following this grammar:

```
Answer     := StatusCode Body
StatusCode := [1-9][0-9][0-9]
```

Note: Status codes follow HTTP.

## Code organisation

Here is a file tree:

```{.filetree}
.
├── docker-compose.yml           # server + database
├── docker-compose.test.yml      # test database
├── Dockerfile
├── Makefile
├── pyproject.toml
├── uv.lock
├── .python-version
├── .github/
│   └── workflows/
│       └── ci.yml               # lint, typecheck, test
├── src/
│   └── server/
│       ├── main.py              # TCP listener, client connection loop
│       ├── parser.py            # request parser
│       ├── handlers.py          # command handlers
│       ├── db.py                # SQLAlchemy models and session management
│       ├── state.py             # in-memory watch state
│       └── protocol.py          # response formatting
└── tests/
    ├── conftest.py
    ├── test_alter.py
    ├── test_create.py
    ├── test_delete.py
    ├── test_parser.py
    ├── test_read.py
    └── test_watch.py
```

**Parser** (`parser.py`): hand-written recursive descent parser implementing
the Request grammar. Produces a `Request` dataclass (command, path, body).

**Handlers** (`handlers.py`): one async function per command. Each handler opens
a database session, performs the operation inside a transaction, records the
command in the `Events` table (same transaction), commits, then notifies
watchers.

**Database** (`db.py`): SQLAlchemy async models over PostgreSQL 16.

**Watch state** (`state.py`): in-memory list of active watchers. Each watcher
holds the watched path, a reference to the client's `StreamWriter`, and an
optional `to` timestamp bound. After every committed mutation, the relevant
handler calls `notify_change`, `notify_deleted`, or `terminate_prefix_watchers`,
which write directly to matching client writers.

We also use `uv` to manage the project and set up a CI via GitHub Actions with
three jobs (lint with `ruff`, typecheck with `mypy`, test with `pytest` against
a real `Postgres` service).

## Tests

Tests require Docker to be running.

```bash
make test
```

This starts a dedicated test database container on port 5433, runs the full
pytest suite against it, then tears the container down. Tests cover the parser,
all five commands, and WATCH notifications including cascades.

## Running the Server

Start the server and its database:

```bash
make up
```

Stop them:

```bash
make down
```

The server listens on port 8888. The `DATABASE_URL` and `PORT` environment
variables can be overridden in `docker-compose.yml`.

## Sending Commands

Connect with `nc`:

```bash
nc 0.0.0.0 8888
```

Here are some examples of commands and their answers:

### CREATE

```
CREATE /users/bob { age: 23 }
201 { path: /users/bob }

CREATE /users/bob { age: 23 }
409 { path: /users/bob }

CREATE /bank-accounts/1 { owner: /users/bob, balance: 100 }
201 { path: /bank-accounts/1 }

CREATE /bank-accounts/2 { owner: /users/nobody, balance: 0 }
404 { path: /users/nobody }
```

### ALTER

```
ALTER /users/bob { age: 30 }
200 { path: /users/bob }

ALTER /bank-accounts/1 { balance: 200 }
200 { path: /bank-accounts/1 }

ALTER /bank-accounts/1 { owner: /users/bob, balance: 50 }
200 { path: /bank-accounts/1 }
```

### DELETE

```
DELETE /users/bob
200 { path: /users/bob }

DELETE /bank-accounts
200 { path: /bank-accounts }
```

Deleting a user cascades to their bank accounts.

### READ

```
READ /users/bob
200 { path: /users/bob, age: 23 }

READ /users
200 { path: /users/bob, age: 23 }
200 { path: /users/alice, age: 30 }

READ /bank-accounts/1
200 { path: /bank-accounts/1, owner: /users/bob, balance: 100 }
```

### WATCH

Open a first connection and register a watch:

```
WATCH /users/bob
200 { path: /users/bob }
```

From a second connection, alter the entity:

```
ALTER /users/bob { age: 99 }
```

The first connection receives:

```
200 { command: WATCH, path: /users/bob, age: 99 }
```

When the entity is deleted, the first connection receives:

```
410 { command: WATCH, path: /users/bob }
```

Subgroup watches are also supported:

```
WATCH /users
200 { path: /users }
```

This covers all current and future entities under `/users`.

Bounded watches replay past events as a burst then stream live updates:

```
WATCH /users/bob { from: 2024-01-01T00:00:00Z, to: 2024-01-01T00:01:00Z }
```

## Repo

A repo with the implementation can be found here:

# Conclusion

We started with a mundane question about Docker and ended up with a formal
model.

Docker led us to question whether modern software engineering produces good
abstractions. Unix suggested that good abstractions are possible and durable —
but require deliberate effort. REST, presented as a modern example of clean
design, turned out to be unsatisfying on closer inspection: its most important
constraint (HATEOAS) does not work for machine-to-machine communication without
an external semantic layer, and its verb semantics (the difference between POST
and PUT, the meaning of a URL containing an action) are informal and
inconsistently applied in practice.

The model proposed here addresses these issues directly. It makes three
commitments:

- Strict separation of entities and actions. Entities are addressed by paths.
  Actions are a small, fixed set of verbs. The two are never mixed. This
  eliminates the ambiguity of REST URLs containing action names.

- Explicit acknowledgment that contracts are inevitable. Rather than pretending
  that semantics can be discovered dynamically (HATEOAS) or encoded in a
  meta-system (the Semantic Web), the model is honest: domain semantics belong
  to an external contract between client and server. The model provides a clean
  foundation; meaning is built on top.

- A formal semantics. The model is small enough to be stated precisely using
  undergraduate mathematics. Every command has an unambiguous meaning. This is
  not a luxury — it is what makes the model teachable, implementable, and
  verifiable. A formal model is not an academic add-on; it is the clearest
  possible answer to the question "how should I think about this system?"

The result is a layered set of models — $M₀$ through $M₄$ — each adding exactly one
concept: entities and relations, alteration, history, real-world time, and read
convenience. The core ($M₀$ and $M₁$) is a handful of definitions. The rest follows
naturally.

The toy implementation validates this claim. The five commands map directly to
handler functions. The path grammar, the status codes, the cascade semantics,
and the watch notifications all follow from the model with no awkward
translation layer. The places where the implementation makes explicit choices
not dictated by the model — a relational schema tailored to the domain,
notifications sent after commit with the accepted risk of a missed notification
on crash, delta notifications as a possible optimisation — are localised
engineering decisions that do not affect the model's validity.

Of course, the model stays silent on a lot of topics. It says nothing about
authorization, concurrency, or error handling — all real concerns that belong to
layers above it. Nor does it address replication or consistency, which are
problems of implementation rather than semantics. But a good foundation does not
need to solve everything. It needs to solve its own problem cleanly, and leave
room for everything else to be built on top.
