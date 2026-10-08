# Week 10 Data Architecture

## 1 Purpose and decision baseline

This document implements the Week 10 peer-review deliverables for the Agricultural Supply Chain Traceability Network:

1. data management requirements and scenarios;
2. data decisions incorporated into the C4 views;
3. conceptual, logical and physical data models;
4. architectural rationale, alternatives and rejection reasons.

The fixed data-architecture thesis is:

> Canonical traceability events are append-only authoritative history in one PostgreSQL application database. A multi-organisation consortium ledger stores minimal verifiable commitments. PostgreSQL projections support trace and recall queries. Sensitive artifacts remain in participant-controlled storage and are represented by signed references and content commitments.

The application does not maintain separate operational databases for metadata, events and graph queries. Logical responsibilities remain separate through schemas, tables, roles and ports.

## 2 Data management requirements

### 2.1 Authoritative data and derived data

| Data category | Authority | Mutability and consistency |
|---|---|---|
| Organisation, identity, site, device, profile and policy metadata | PostgreSQL `registry` schema | Versioned and strongly consistent |
| Accepted canonical event facts | PostgreSQL `events` schema | Append-only after commitment |
| Cross-organisation integrity proof | Consortium ledger | Append-only, replicated by independent organisations |
| Handover, lineage, current state and audience views | PostgreSQL `projection` schema | Eventually consistent, disposable and rebuildable |
| Raw IoT, certificates, laboratory documents and private extensions | Participant-controlled external systems | Governed by the owning organisation |
| AI risk assessment | PostgreSQL derived projection | Advisory, versioned and non-authoritative |

### 2.2 Core validation requirements

- Every event has a globally unique event ID and immutable profile-version reference.
- Repeating an event ID with the same commitment returns the existing result; reusing it with different content is rejected and audited.
- Event time and repository record time are distinct.
- Publisher identity, organisation membership, signing-key validity and authorisation are evaluated at submission time.
- A committed event is never physically updated or deleted by the application.
- Corrections append an Error Declaration and corrective event.
- Shipping and receiving remain independent signed assertions.
- Aggregation preserves child identity; transformation creates new outputs with complete input lineage.
- Quantities carry a unit and use profile-defined conversion, yield and loss rules.
- External artifacts use opaque references and content commitments without embedded credentials.
- Consumer data is created from an allowlisted projection rather than by removing fields from a complete response.

### 2.3 Storage requirements

- One managed PostgreSQL database contains `registry`, `events`, `projection` and `operations` schemas.
- PostgreSQL transactions atomically persist submission state, canonical event facts and outbox records.
- PostgreSQL recursive CTEs traverse lineage and impact data.
- The consortium ledger stores minimal event envelopes and commitments rather than complete payloads.
- Large or sensitive artifacts remain external by default.
- Read projections can be truncated and rebuilt from committed events.
- PostgreSQL uses Multi-AZ deployment, automated backup and point-in-time recovery.
- Projection checkpoints and replayable broker messages support deterministic recovery.

### 2.4 Access-control requirements

| Audience | Data access |
|---|---|
| Consumer | Public origin, approved stages, public evidence status, temperature summary and affected or recalled status |
| Participant | Events, quantities and evidence permitted by organisation relationship and purpose |
| Auditor or regulator | Authorised canonical facts, signatures, commitments, correction history and external-artifact references |
| Platform operator | Operational access separated from unrestricted business-data access and audited |

Command authorisation and query disclosure are separate policy interfaces even when implemented in the same Access Policy module.

### 2.5 Retention requirements

No jurisdiction or statutory period is supplied by the case study. Retention therefore uses versioned policies rather than an invented legal duration.

Every retained record can reference:

- `retentionPolicyId`;
- `retainUntil`;
- `legalHold`;
- deletion or anonymisation action.

External artifact owners remain responsible for source-content retention. The platform preserves the reference and commitment and reports `Available`, `Unavailable`, `Expired` or `Revoked`. Ledger records contain no sensitive payload that requires ordinary application deletion.

### 2.6 Ingestion requirements

Supported ingestion paths are:

- participant PWA, including durable offline queue;
- enterprise EPCIS or REST integration;
- external IoT evidence integration;
- laboratory or certification evidence integration;
- optional file import after the core API is stable.

All paths produce the same canonical submission command and state lifecycle:

```text
Received
→ Validated
→ PayloadStored
→ PendingLedger
→ Committed
→ Projected
```

Recovery states are `Rejected`, `LedgerRetry`, `ProjectionRetry` and `Superseded`.

## 3 Data scenarios

### 3.1 Offline batch commissioning

| Concern | Requirement |
|---|---|
| Validation | Stable client event ID, valid profile, authorised farmer, unique batch ID, event time and time-zone offset |
| Storage | Submission and canonical event in PostgreSQL; minimal commitment on ledger after connectivity returns |
| Access | Farmer sees local pending state; other users see the event only after commitment |
| Retention | Selected by the product and regional profile |
| Ingestion | PWA durable queue and delayed HTTPS submission |
| Consistency | Local draft is not shared history; PostgreSQL and ledger converge through submission state |
| Recovery | Same event ID and commitment can retry without duplication |
| Rejected alternative | Treating a local draft as committed history would create unverifiable provenance |

### 3.2 Multi-hop handover with partial receipt

| Concern | Requirement |
|---|---|
| Validation | Shipping and receiving publisher authority, object identity, source and destination, correlation reference, quantity and UOM |
| Storage | Independent events in write model; handover state in projection |
| Access | Involved organisations and authorised auditor see quantities and discrepancies; consumer does not |
| Retention | Shipping, receiving and derived dispute remain linked for the selected event-retention period |
| Ingestion | PWA or enterprise API at each hop |
| Consistency | Shipping remains valid when receiving is absent or conflicting; projection becomes Pending, Partial, Rejected or Disputed |
| Recovery | Projection replay recomputes state without changing source events |
| Rejected alternative | One mutable transfer row would allow one party to overwrite the other party's assertion |

### 3.3 Batch split, pallet aggregation and processing merge

| Concern | Requirement |
|---|---|
| Validation | Committed input identities, unique output IDs, permitted profile, quantity/UOM rules, declared loss or yield, no containment cycle |
| Storage | Transformation and Aggregation events in write model; `CONTAINS` and `DERIVED_FROM` projections in PostgreSQL |
| Access | Quantities visible only to authorised participants and auditors; consumer receives approved lineage summary |
| Retention | Input, output and relationship history share compatible policies |
| Ingestion | Participant PWA or enterprise API |
| Consistency | Write event is authoritative; graph edge is eventually consistent and rebuildable |
| Recovery | Duplicate projection messages are idempotent |
| Rejected alternative | Updating parent and child fields on a batch would erase relationship history and prevent replay |

### 3.4 IoT or compliance artifact ingestion

| Concern | Requirement |
|---|---|
| Validation | Provider identity, artifact ID, signed metadata, observation or validity period, commitment scheme and referenced object |
| Storage | Artifact reference and commitment in PostgreSQL; source content remains external; event commitment anchors the reference |
| Access | External content resolved only after policy evaluation; opaque locator never contains credentials |
| Retention | Source owner applies source retention; platform records policy and current availability |
| Ingestion | Provider API or participant submission referencing an existing artifact |
| Consistency | A missing artifact does not delete its historical reference; availability is reported separately from integrity |
| Recovery | Provider outage returns `Unavailable`, not `Verified` or `Deleted` |
| Rejected alternative | Copying all documents and telemetry into the platform would make it a general document and IoT store |

### 3.5 Error declaration and correction

| Concern | Requirement |
|---|---|
| Validation | Original event exists, requester is authorised, correction reason and replacement relationship are valid |
| Storage | Original event, Error Declaration and corrective event are separately committed |
| Access | Consumer receives current approved interpretation; auditor receives complete history |
| Retention | Correction chain cannot expire before the event it interprets |
| Ingestion | Normal event-submission path |
| Consistency | Projection marks original as superseded without changing source content |
| Recovery | Projection replay deterministically selects the latest authorised correction chain |
| Rejected alternative | In-place update breaks hash verification and auditability |

### 3.6 Downstream recall-impact query

| Concern | Requirement |
|---|---|
| Validation | Caller purpose and scope, starting object, projection watermark and edge visibility |
| Storage | PostgreSQL adjacency-list and handover projection tables |
| Access | Result filters organisations, quantities and destinations through disclosure policy |
| Retention | Projection cannot outlive its authorised source events |
| Ingestion | Query API, not the write path |
| Consistency | Result declares projection timestamp or committed sequence |
| Recovery | If projection is rebuilding, API reports a stale or unavailable status rather than silently returning an incomplete result |
| Rejected alternative | Traversing the ledger for each query couples latency and availability to consensus infrastructure |

## 4 C4 data architecture mapping

### 4.1 Context level

External data systems are:

- Enterprise Operational Systems;
- External IoT Platform;
- Laboratory and Certification Systems;
- Participant-controlled Artifact Stores.

The central Traceability Network receives canonical events and references rather than assuming ownership of every source record.

### 4.2 Container level

The data containers are:

- Traceability PostgreSQL Database;
- Consortium Ledger Network;
- Participant-controlled Artifact Stores;
- Message Broker as a durable integration mechanism.

The Projection Worker consumes committed events and writes rebuildable projections to PostgreSQL. The optional Risk Analysis Service reads an authorised analytical projection and stores versioned advisory results.

### 4.3 Component level

Logical ports remain independent:

- Identity and Metadata Port;
- Event Repository Port;
- Read Model Port;
- Ledger Port;
- Event Publisher Port;
- Artifact Reference Port.

One PostgreSQL Adapter implements the first three logical persistence ports. Separate Consortium Ledger, Transactional Outbox and Artifact Provider adapters preserve external boundaries.

### 4.4 Backup and recovery

- PostgreSQL canonical data uses Multi-AZ, automated backups and point-in-time recovery.
- Projection tables can be rebuilt from committed events and projection checkpoints.
- Ledger history is replicated across independently administered nodes; node snapshots do not replace consortium replication.
- External artifact backup is the owning organisation's responsibility and is visible through availability status.
- Restore procedures must include a projection replay and hash-to-ledger verification sample.

## 5 Conceptual data model

The conceptual model is event-centred:

- an Organisation controls identities, keys, sites and devices;
- a Trace Event is published and signed by authorised identities;
- an event conforms to an immutable Profile Version;
- an event involves one or more Traceable Objects in explicit roles;
- an event may reference external Evidence Artifacts;
- accepted event content is verified by a Ledger Commitment;
- corrections append relationships between original, declaration and corrective events;
- handover and lineage are derived from accepted events.

See [Conceptual Data Model](./diagrams/04-data-conceptual-model.puml).

## 6 Logical data model

### 6.1 Registry schema

- organisation;
- site;
- identity;
- signing key;
- membership;
- device;
- product profile;
- profile version;
- visibility policy;
- retention policy.

### 6.2 Events schema

- event submission;
- trace event;
- traceable object;
- event object role and quantity;
- event correction;
- external artifact reference;
- event-artifact relationship;
- ledger commitment receipt;
- transactional outbox.

### 6.3 Projection schema

- trace edge for `CONTAINS` and `DERIVED_FROM`;
- handover projection;
- current object state;
- consumer projection;
- provenance completeness;
- optional risk assessment.

### 6.4 Operations schema

- projection checkpoint;
- append-only access audit.

See [Logical Write Model](./diagrams/05a-data-logical-write-model.puml), [Logical Projection Model](./diagrams/05b-data-logical-projection-model.puml) and [Data Dictionary](./data-model/data-dictionary.md).

## 7 Physical model

The physical model uses PostgreSQL types, keys, checks and indexes. Stable envelope fields are normalised. Extensible profile content uses JSONB only where a relational constraint is not appropriate. Large or sensitive content is represented by an external artifact reference.

Important physical decisions include:

- UUID primary keys for internal records;
- URI-compatible text identifiers for traceable objects and vocabularies;
- `timestamptz` plus explicit event time-zone offset;
- `numeric(20,6)` quantity;
- `char(64)` SHA-256 commitment representation;
- unique event ID and ledger transaction ID;
- composite indexes for object-event and recursive edge traversal;
- check constraints for states, roles, edge types, non-negative quantities and paired quantity/UOM values;
- append-only enforcement through application role permissions and trigger protection;
- row-level security or equivalent policy enforcement for organisation-scoped access.

See [Physical Data Model](./diagrams/06-data-physical-model.puml), [PostgreSQL Schema](./data-model/traceability-schema.sql) and [Reference Recursive Queries](./data-model/traceability-queries.sql).

## 8 Data architecture constraints

### 8.1 Event integrity

- Committed events are append-only.
- The canonicalisation version and hash algorithm are recorded.
- The ledger commitment must match the PostgreSQL event commitment.
- Reusing an event ID with different content is rejected.
- A projection cannot create source facts not present in committed events.

### 8.2 Temporal integrity

- Event time describes the physical-world occurrence.
- Record time is assigned by the repository.
- Historical signatures remain verifiable after key revocation.
- Containment and handover validity intervals cannot silently overlap incompatibly.

### 8.3 Lineage integrity

- `CONTAINS` and `DERIVED_FROM` cannot create object cycles.
- One object has at most one active logistic parent.
- Outputs reference every contributing input.
- Split and transformation quantities use profile-defined conversion, yield and loss rules.
- Correction creates new events and edges instead of rewriting old ones.

### 8.4 Artifact integrity

- Opaque locators contain no credentials or permanent signed URL.
- Low-entropy sensitive content is not committed with an unsalted raw hash.
- The baseline commitment is `SHA-256(randomNonce || canonicalisedArtifact)`.
- Integrity, availability, issuer validity and business verification are distinct statuses.

### 8.5 Projection integrity

- Projection handlers are idempotent.
- Each projection records a message or ledger checkpoint.
- Query responses expose projection age or source sequence where completeness matters.
- Projection rebuild does not require writing new ledger transactions.

## 9 Architectural rationale and alternatives

| Decision | Requirement and causal rationale | Alternative rejected |
|---|---|---|
| Event-first authoritative history | Immutable audit, correction and conflicting assertions require append-only facts | Mutable batch and transfer records overwrite history |
| One PostgreSQL application database | Relational integrity, ACID outbox, student feasibility and lower operational burden | Polyglot metadata, document and graph databases add synchronisation and operational boundaries without measured need |
| Logical CQRS in one database | Write semantics and query projections differ, but initial deployment does not require independent database products | Separate command and query databases add CDC and consistency work |
| PostgreSQL recursive traversal | Multi-hop lineage needs graph traversal and the proposed scale is moderate | Dedicated graph database deferred until a prototype misses the 10,000-edge, five-second target |
| Minimal consortium-ledger commitment | Independent verification is required, but sensitive and large data should not be replicated | All-on-chain storage increases privacy, retention, cost and query problems |
| Participant-controlled artifact storage | The case supplies no universal sensitive-data semantics and the platform should not become a document or IoT warehouse | Platform-owned document and telemetry stores expand custody and compliance scope |
| Core quantities remain in PostgreSQL | The platform claims to validate split, merge and transformation lineage | Externalising all quantities would make validation impossible without zero-knowledge mechanisms outside project scope |
| Versioned retention policy | No jurisdiction or statutory period is supplied | Inventing a fixed legal period would be unsupported |
| Transactional outbox and submission state machine | PostgreSQL and ledger cannot share one ACID transaction | Distributed transaction or best-effort dual writes are impractical or unreliable |

## 10 Evaluation criteria

The data architecture is acceptable when it can demonstrate:

- duplicate submission produces one accepted event;
- committed-event mutation is detectable;
- split and merge lineage survives projection rebuild;
- partial handover retains both organisations' assertions;
- external artifact tampering fails commitment verification;
- artifact unavailability is reported without deleting provenance;
- consumer projection excludes restricted fields;
- a 10,000-edge authorised impact traversal meets the proposed five-second p95 target in a prototype;
- PostgreSQL restore plus projection replay reproduces the same trace and ledger hashes.

## 11 Remaining implementation parameters

The following do not reopen the architecture:

- managed PostgreSQL product and version;
- consortium-ledger implementation;
- message-broker product;
- jurisdiction-specific retention values;
- partition thresholds and final index tuning;
- participant artifact-provider implementations;
- whether the optional AI extension is submitted for bonus marks.

