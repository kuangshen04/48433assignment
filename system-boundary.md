# Agricultural Supply Chain Tracker System Boundary

> Status: Architecture baseline for Week 9 modelling  
> Updated: 2026-10-08  
> Purpose: Fix the product position, scope, trust model and modelling constraints before producing quality scenarios and C4 views.  
> Interpretation: This is a traceability platform with user-facing applications and enterprise integration. It is not a full ERP.

## 1. Architectural thesis

Agricultural Supply Chain Tracker is a cross-organisation traceability network for agricultural products.

It allows independent supply-chain organisations to publish signed traceability events, associate those events with IoT and compliance evidence, and query an end-to-end product provenance without moving all operational data into one shared ERP or trusting one platform operator to control the complete history.

The core responsibility is:

> Connect separately produced supply-chain assertions into an authorised, verifiable and non-silently-rewriteable provenance history.

The platform does not replace ERP, WMS, TMS, MES, farm-management, POS, laboratory, certification or regulatory systems. Organisations with no suitable system can use the platform PWA; digitally mature organisations can publish the same canonical events through an API.

```text
Enterprise Operational Systems                 Platform Applications
ERP / WMS / TMS / Farm System ── API ──┐       Participant PWA
                                       │       Consumer Portal
External IoT Platform ─ evidence API ──┼────── Audit Portal
                                       │
Small Organisation ───── PWA ─────────┘
                                       │
                                       ▼
                    Agricultural Supply Chain Traceability Network
                    Identity / Profiles / Events / Ledger / Trace
```

## 2. Scope strategy

The architecture is narrow in business behaviour but broad enough in quality constraints to satisfy the case study.

### 2.1 Reference product and scenario

The detailed design uses temperature-sensitive fresh produce tracked primarily at lot or batch level and secondarily at pallet level.

This is a reference product profile, not a single-product limitation. The core event model and services must support additional product lines through versioned profiles rather than product-specific services or databases.

### 2.2 Core vertical slice

All detailed models must support one end-to-end slice:

```text
Create batch
→ split the batch into traceable outputs
→ aggregate selected outputs into a pallet
→ dispatch through one or more logistics or distribution organisations
→ attach transport temperature evidence
→ receive or report discrepancy
→ disaggregate, split, merge or transform when the physical process requires it
→ distribute derived quantities to multiple retailers
→ expose an authorised provenance view
→ verify history
→ correct an error without deleting history
→ calculate downstream impact when the batch is affected
```

Features that do not support this slice must be treated as an extension or an external responsibility.

### 2.3 Requirement depth

The project requirements are represented at different depths:

| Requirement | Architectural treatment |
|---|---|
| End-to-end traceability | Core business behaviour modelled in Context, Container, Component and Code views |
| Blockchain-based immutable records | Core trust and integrity mechanism, with explicit chain/off-chain partitioning |
| Multiple product lines | Versioned product profiles over a stable canonical event model |
| Multiple regions | Horizontal scaling, partitioning and deployment constraints; not separate regional products |
| Cloud adoption | Deployment and operational architecture; not a business subsystem |
| IoT integration | External raw telemetry platform plus signed evidence or summaries inside the traceability system |
| AI/ML | Optional asynchronous risk analysis extension; never the source of traceability truth |
| Data visualisation | Batch timeline, provenance graph and temperature timeline only in the first release |
| Food-safety compliance | Evidence linkage, audit export, completeness checks and affected or recalled status; not regulatory decision-making |
| Rural accessibility | Offline event drafting, delayed submission, retry and idempotency |

## 3. Boundary at a glance

| Inside the Traceability Network | Integration boundary | Outside the Traceability Network |
|---|---|---|
| Organisation, user, site, device and public-key registration | Participant PWA | ERP, WMS, TMS, MES, farm-management and POS |
| Versioned EPCIS and product profiles | EPCIS or REST API | Complete agricultural production management |
| Signed event capture and validation | IoT evidence API | IoT firmware, fleet management and raw telemetry platform |
| Dispatch and receipt correlation | Laboratory or certificate evidence API | Laboratory testing and certificate issuance |
| Append-only correction and dispute representation | Consumer QR or Digital Link query | Government approval, enforcement and regulatory databases |
| Encrypted event payload store | Auditor query and export interface | Payment, accounting and contract management |
| Consortium ledger commitments | Optional file import after the core API is stable | Detailed inventory, warehouse operations and route optimisation |
| Provenance read model and impact query | Optional ML inference endpoint | Public blockchain, if future anchoring is adopted |
| Consumer, participant and auditor projections | Notification provider if later adopted | Email, SMS and push infrastructure |

## 4. Stakeholders and actors

### 4.1 Supply-chain participants

- Farmer or Producer creates the source batch and publishes origin facts.
- Processor or Packer transforms or aggregates products when the selected scenario requires it.
- Logistics Provider supplies transport and custody facts and may provide IoT evidence.
- Distributor or Wholesaler dispatches, receives, splits or aggregates traceable objects.
- Retailer receives products and makes an approved consumer identifier available.

These actors publish assertions only for actions they are authorised to perform. They do not edit another organisation's event.

### 4.2 Evidence providers

- IoT Platform or Device Operator publishes signed sensor summaries, alerts and raw-data references.
- Laboratory publishes a report reference, issuer identity, result metadata and integrity hash.
- Certification Body publishes certificate metadata and revocation status.

Evidence providers attest to supplied evidence. The traceability platform does not perform the physical measurement, laboratory test or certification decision.

### 4.3 Query actors

- Consumer sees a public, minimised provenance projection.
- Trading Partner sees events and evidence authorised by its business relationship.
- Auditor or Regulator sees a more complete history, signatures, hashes, corrections and evidence when authorised.
- Supply-chain Manager sees operational trace and exception visualisations for authorised data.

### 4.4 Operation and governance actors

- Platform Operator runs the shared SaaS application plane and some infrastructure.
- Consortium Administrator manages membership, profiles and governance policies.
- Independent Consortium Members operate ledger nodes or participate in governance.

The Platform Operator must not exclusively control all participant private keys, ledger nodes and governance decisions.

## 5. Canonical domain model

The platform is event-centred. It does not treat one mutable `BatchStatus` record as the complete history.

### 5.1 Traceable objects

The first release supports:

- lot or batch as the primary food-safety traceability unit;
- pallet or logistic unit for aggregation and transport;
- product class;
- site or business location;
- device reference;
- evidence reference.

Serialised retail items, reusable assets and arbitrary associations are extension points, not first-release modelling targets.

### 5.2 Canonical event subset

The stable event model is based on EPCIS concepts.

The reference scenario uses:

- `ObjectEvent` for commissioning, shipping, receiving, inspecting, sensor reporting and status declarations;
- `AggregationEvent` for packing items or batches into a pallet and unpacking them;
- `TransformationEvent` for one-to-many batch splitting, many-to-one commingling or processing, and many-to-many re-batching where input identities become output lineage;
- `ErrorDeclaration` and a corrective event for correction.

`AssociationEvent` is not required for the first detailed model.

Every accepted event must contain or reference:

- stable event ID;
- profile ID and version;
- event type;
- event time and time-zone offset;
- record time assigned by the repository;
- publisher organisation and signing identity;
- traceable object identifiers;
- business step and resulting disposition where applicable;
- read point or business location where applicable;
- source, destination or business-transaction reference where applicable;
- evidence references where applicable;
- visibility-policy reference;
- digital signature and payload hash.

### 5.3 Core relationship primitives

The provenance model is a directed graph rather than a linear batch history. It uses three stable relationship primitives:

| Relationship | Meaning | Identity effect |
|---|---|---|
| `HANDOVER` | An organisation dispatches a traceable object or quantity and another organisation independently receives it | Object identity is unchanged; custody, location or responsibility may change |
| `CONTAINS` | A pallet or logistic unit contains child batches or objects | Child identities are preserved and the relationship is reversible through disaggregation |
| `DERIVED_FROM` | One or more input batches are split, mixed, processed or re-batched into one or more outputs | New output identities are created and must retain lineage to every contributing input |

An arbitrary number of `HANDOVER` edges must be supported. The system must not encode a fixed `Farmer → Distributor → Retailer` route or create separate workflows for each pair of participant roles.

Aggregation is not batch merging. Placing Batch A and Batch B on Pallet P creates `CONTAINS` relationships; it does not create a new mixed Batch C. A true merge, split or processing step creates `DERIVED_FROM` relationships through a `TransformationEvent`.

Lineage validation must enforce these invariants:

- every output batch created by a split, merge or transformation references all contributing inputs;
- quantities include a unit and are comparable only after an explicit conversion rule;
- split outputs cannot silently exceed the available input quantity;
- expected processing loss, waste or yield difference is recorded rather than hidden;
- one child object cannot belong to two active parent logistic units at the same time;
- disaggregation ends a `CONTAINS` relationship but does not delete its history;
- custody transfer does not by itself change batch identity or composition;
- corrections append new lineage assertions and do not rewrite previously committed edges.

### 5.4 Product profiles

The EPCIS-style core remains stable. A versioned product profile defines:

- required and optional fields;
- permitted event types and business steps;
- units and value constraints;
- required evidence;
- validation and compatibility rules;
- deprecation and migration rules.

The first complete profile is `Fresh Produce Cold Chain v1`.

Adding another product line, such as dairy, must not require a new event service, database or ledger contract. It should require a new approved profile and, if necessary, presentation changes in the UI.

### 5.5 Derived state

The following are projections derived from accepted events rather than mutable historical truth:

- current or last known disposition;
- current or last known custodian;
- current or last known location;
- pallet contents;
- provenance completeness;
- handover state;
- upstream and downstream lineage;
- affected or recalled status;
- consumer-safe provenance.

Projection errors can be rebuilt from the accepted event history.

## 6. Core behavioural constraints

### 6.1 Event submission

An event submission follows this logical sequence:

```text
Receive command
→ normalise to canonical event
→ validate profile and schema
→ authenticate publisher
→ verify signature and authorisation
→ validate referenced objects and business rules
→ enforce idempotency
→ persist encrypted payload and outbox record
→ build ledger commitment
→ submit to consortium ledger
→ mark event committed or pending retry
→ publish projection message
```

Validation failure must not create a committed ledger record. A ledger timeout must not cause duplicate events when the client retries.

### 6.2 Inter-organisation handover

A handover is not one mutable transfer row.

```text
Sender Shipping Event
        ↓
Pending Handover
        ↓
Receiver Receiving Event
        ↓
Accepted / Partially Accepted / Rejected / Disputed
```

The sender and receiver publish separate signed assertions. The platform correlates them but does not overwrite either assertion or claim which party is factually correct when they conflict.

Ownership, custody and physical location are separate concepts.

The same handover protocol is repeatable across any number of logistics providers, distributors, processors and retailers. Each hop has its own sender assertion, receiver assertion and derived state.

### 6.3 Aggregation, splitting and transformation

Aggregation and disaggregation manage reversible logistics containment:

```text
Batch A1 ─┐
Batch B1 ─┼→ Pallet P
Batch C1 ─┘
```

The batches keep their identities. The pallet can be handed over multiple times without converting its children into a new batch.

Transformation manages lineage when identities or quantities change:

```text
One-to-many split
Batch A → Batch A1 + Batch A2

Many-to-one merge or processing
Batch A2 + Batch D → Processed Batch C

Many-to-many re-batching
Inputs A + B → Outputs C + D + recorded loss
```

The `QuantityAndLineageValidator` checks identifiers, units, available input quantities, output quantities, declared loss or yield, profile rules and duplicate use of the same input. It records lineage even when a processing discrepancy requires later review.

### 6.4 Correction

Committed events cannot be physically edited or deleted through the application.

Correction uses:

```text
Original Event
→ Error Declaration
→ Corrective Event
```

Queries must preserve the original assertion and correction history while clearly identifying the currently effective interpretation.

### 6.5 IoT evidence

Raw high-frequency telemetry remains in an external IoT platform or specialised time-series store.

The Traceability Network stores only the evidence required for provenance and food-safety analysis:

- device identity and organisation;
- associated batch, pallet, shipment or time window;
- measurement type and unit;
- bounded summary or threshold exception;
- observation start and end time;
- raw-data URI and hash;
- device or platform signature;
- processing-method version where a summary was calculated.

An unavailable external raw-data URI does not invalidate the existence of the recorded assertion, but the query result must show that the supporting evidence is unavailable.

### 6.6 Controlled disclosure

The first release uses three explicit projections:

| Projection | Permitted content |
|---|---|
| Consumer | origin region, public stages, public certificates, temperature compliance summary, affected or recalled status |
| Participant | authorised handover, quantity, logistics and evidence details involving the organisation or an approved relationship |
| Auditor | authorised full event payload, publisher, signature, hash, evidence and correction history |

Prices, contracts, exact inventory, personal information and unrelated commercial fields are not exposed by default.

## 7. Data boundary

### 7.1 Consortium ledger

The permissioned consortium ledger stores a minimal verifiable commitment, not the complete operational payload.

The initial ledger record contains:

- network and event ID;
- event type;
- profile ID and version;
- publisher organisation ID;
- event time and ledger record time;
- traceable object identifiers required for shared interpretation;
- relationship type and related object identifiers required to verify handover, containment and derivation commitments;
- business step and disposition when approved for sharing;
- payload hash;
- publisher signature or signature reference;
- visibility-policy reference;
- original-event and corrective-event linkage;
- ledger transaction receipt and sequence.

Exact quantities, personal data, commercial terms, full certificates, raw telemetry and unrestricted precise locations are not placed on the shared ledger by default.

### 7.2 Platform off-chain storage

The SaaS application plane stores:

- encrypted canonical EPCIS payloads;
- organisation, site, user, device and public-key metadata;
- product profiles and validation rules;
- evidence metadata and protected document references;
- idempotency records and transactional outbox entries;
- provenance graph and query indexes;
- derived current-state and handover projections;
- consumer-safe projections;
- optional AI risk assessments with model version and generation time.

### 7.3 External authoritative stores

External systems retain:

- complete ERP, WMS, TMS, MES, farm and POS records;
- raw IoT time-series and device maintenance records;
- laboratory source records;
- certificate issuance workflows and source documents;
- regulatory records and decisions;
- documents or media not required in the traceability platform.

The platform stores only the shared event or evidence required by the traceability use case. It does not become the authoritative system for unrelated enterprise operations.

## 8. Trust and governance boundary

### 8.1 Trust assumptions

- Organisations may make mistakes or publish conflicting assertions.
- The platform operator is trusted to operate the SaaS plane but is not trusted as the sole controller of shared history.
- A valid signature proves who submitted an assertion; it does not prove the physical-world assertion is true.
- A ledger commitment proves that accepted content has not been silently changed after commitment; it does not guarantee sensor calibration, laboratory competence or regulatory legality.
- Consumers receive minimised derived information and do not receive unrestricted ledger access.

### 8.2 Key ownership

- Each organisation controls its signing keys or delegates signing under an explicit policy.
- Platform-managed keys, where needed for small organisations, must be isolated per organisation and protected by a managed KMS or HSM.
- The platform does not use one shared application key to impersonate every participant.
- Revoked or suspended identities cannot submit new accepted events, but their historical signatures remain verifiable.

### 8.3 Consortium operation

The logical deployment assumes independent participation from at least:

- Platform Operator;
- Producer or Farmer Cooperative;
- Logistics or Distributor representative;
- Retail representative;
- Independent Auditor or industry body.

The exact ledger product, quorum and endorsement syntax remain technology decisions, but the architecture must prevent the Platform Operator from unilaterally rewriting committed history or changing governance policy.

Public-blockchain anchoring is not part of the first-release baseline. It may be evaluated as an alternative defence against collusion by the complete consortium.

## 9. Cloud and deployment constraints

Cloud adoption applies to the SaaS application plane, not to the ownership of every consortium node.

The target deployment uses:

- CDN or managed static hosting for browser applications;
- API gateway and web application firewall;
- stateless, horizontally scalable application services;
- managed relational metadata and event storage;
- managed message broker;
- object storage for protected evidence where appropriate;
- independently scalable trace read store;
- KMS or HSM-backed secret and signing-key protection;
- multi-availability-zone deployment, health checks, backup and restore;
- centralised logs, metrics, traces and security audit events;
- infrastructure as code.

Consortium ledger nodes must be distributed across independent organisations or administrative accounts. Hosting all nodes and administrative credentials in one platform-controlled account violates the trust model even if the infrastructure is technically distributed.

The first deployment can operate in one primary cloud region with multiple availability zones. Multi-region growth is supported through stateless services, explicit region and tenant identifiers, partitionable event and read stores, asynchronous processing and deployable regional read capacity. Global active-active writes are not a first-release requirement.

## 10. Multiple products and regions

### 10.1 Multiple product lines

Support for multiple product lines means:

- no core service is named or implemented for one crop;
- event processing uses the stable canonical event model;
- product-specific constraints reside in versioned profiles;
- a new profile can be registered without replacing the event store or ledger interface;
- the UI may render profile-specific forms from metadata or isolated presentation modules;
- old events remain interpretable using the profile version recorded at submission.

The architecture evaluation must include the change scenario: add a dairy profile without modifying the core event-submission workflow.

### 10.2 Multiple regions

Support for multiple regions means:

- organisations, sites, events and profiles carry explicit region or jurisdiction context;
- time zones are preserved rather than normalised away at capture;
- services can scale horizontally;
- data stores can be partitioned by stable identifiers without changing the domain model;
- regional compliance profiles can extend validation without forking the platform;
- data residency and cross-region replication remain explicit deployment decisions.

It does not mean the first release implements every jurisdiction or operates an active-active global ledger.

## 11. Rural and failure-mode constraints

### 11.1 Offline event capture

The Participant PWA supports offline event drafting and a durable local submission queue.

Each offline event has:

- client-generated stable event ID;
- event time and local time-zone offset;
- publisher identity and signature when secure local signing is available;
- local state: `Draft`, `Pending Sync`, `Submitted`, `Committed` or `Rejected`;
- retry metadata.

An offline record is not presented as ledger-confirmed until the server validates and commits it.

### 11.2 Idempotency and retry

- Repeating a submission with the same event ID and identical payload returns the existing result.
- Reusing an event ID with a different payload is rejected and audited.
- Ledger or broker outages place a validated submission into an explicit pending state rather than silently losing it.
- Projection processing is replayable and must tolerate duplicate messages.

### 11.3 Conflicting and incomplete data

- A missing receiving event leaves a handover pending.
- Mismatched quantity or object identifiers produce partial, rejected or disputed state.
- Invalid signatures and unauthorised publishers are rejected before ledger commitment.
- Missing optional evidence lowers provenance completeness but does not fabricate a fact.
- Corrections append new records and do not erase the original event.

## 12. Working quality targets

The following are project assumptions for architecture modelling and peer review. They must be labelled as proposed targets rather than facts supplied by the case study.

| Quality | Working target |
|---|---|
| Trace query performance | Return a normal consumer batch trace within 2 seconds at the 95th percentile using the read model, without traversing the ledger |
| Impact-query performance | Traverse up to 10,000 authorised handover, containment and derivation edges and return the affected-object set within 5 seconds at the 95th percentile |
| Submission responsiveness | Validate and acknowledge an online event submission within 3 seconds at the 95th percentile, excluding delayed final ledger confirmation |
| Ledger completion | Under normal network conditions, expose committed or explicit pending status within 30 seconds at the 95th percentile |
| Reliability | Client and server retries do not create duplicate accepted events |
| Rural accessibility | Users can create signed or attributable drafts without connectivity and synchronise after connectivity returns |
| Scalability | A tenfold increase in event ingestion or public queries can be handled by horizontal scaling and partitioning without changing the domain model |
| Availability | Public trace queries target 99.9 percent monthly availability; temporary ledger unavailability does not disable read-only queries of already committed data |
| Integrity | Any change to a committed payload is detectable by comparing its hash and signature with the ledger commitment |
| Privacy | Consumer responses exclude non-public commercial and personal fields by construction through a separate projection |
| Modifiability | A new product profile can be introduced without changing the core event-submission service or ledger port |
| Auditability | An authorised auditor can retrieve the original event, corrections, publisher identity, signature status and evidence references |

These numbers are intentionally testable. They can be revised after team review, but vague phrases such as `real time`, `large volume` and `acceptable response time` must not replace them.

## 13. Optional AI and ML extension

AI and ML are not part of traceability truth or ledger consensus.

If the team pursues the optional AI and IoT marks, the bounded use case is:

> Produce an advisory spoilage-risk or cold-chain anomaly score from authorised trace events and IoT summaries.

The optional Risk Analysis Service:

- reads from an authorised analytical projection rather than the write path;
- runs asynchronously and cannot block event submission or trace queries;
- records model ID, model version, input window and generation time;
- returns an advisory score and explanation or contributing factors;
- sends high-risk results for human review;
- does not declare legal non-compliance or rewrite source events;
- can be disabled without affecting core traceability.

Training-platform design, generic feature stores, generative AI, autonomous regulatory decisions and AI-generated ledger facts are outside the first-release scope.

## 14. Explicit exclusions

The following are outside the system boundary:

- complete farm operations, planting, feeding, fertiliser and treatment management;
- procurement, sales negotiation, pricing, payment, settlement and accounting;
- detailed inventory, picking, packing operations and warehouse optimisation;
- vehicle dispatch and route optimisation;
- laboratory testing and certification decisions;
- IoT firmware, connectivity and fleet maintenance;
- raw high-frequency telemetry retention as a general IoT platform;
- full regulatory case management, enforcement and legal-liability determination;
- automatic proof that a submitted claim is physically true;
- global active-active deployment in the first release;
- public-blockchain anchoring in the first release;
- complete recall case-management workflow;
- serialisation of every consumer item;
- general-purpose BI, data warehouse or AI platform.

The system may reference data produced by these activities without taking responsibility for performing them.

## 15. End-to-end reference scenario

The reference scenario used across requirements and diagrams is:

1. A Farmer creates Batch A with 1,000 kg under `Fresh Produce Cold Chain v1`.
2. The Farmer submits a signed commissioning event while online or queues it offline.
3. A `TransformationEvent` splits Batch A into Batch A1 with 600 kg and Batch A2 with 400 kg while preserving `DERIVED_FROM` lineage.
4. Batch A1 and an independently identified Batch B1 are aggregated into Pallet P using reversible `CONTAINS` relationships; they are not merged into a new batch.
5. The Farmer submits a signed shipping event for Pallet P to Logistics Provider L1.
6. An external IoT platform publishes signed temperature evidence for the shipment window.
7. Logistics Provider L1 independently receives Pallet P, then submits a new shipping event to Distributor D1.
8. Distributor D1 independently receives and disaggregates Pallet P.
9. Distributor D1 splits Batch A1 into Batch A1-R1 and Batch A1-R2 and ships them to different retailers through separate handovers.
10. Each Retailer independently submits a receiving event that accepts, partially accepts, rejects or disputes its handover.
11. In a processing branch, Batch A2 and Batch D are transformed into Processed Batch C, preserving both input lineages and any declared processing loss.
12. A Consumer scans an approved identifier and receives a public provenance projection for the purchased output batch.
13. An Auditor verifies event signatures, ledger commitments, handover history, quantity lineage, evidence and correction history.
14. An authorised participant corrects an erroneous event through an Error Declaration and corrective event.
15. Batch A is marked affected, and the system traverses `DERIVED_FROM`, `CONTAINS` and `HANDOVER` edges to identify all downstream batches, pallets, organisations and retail destinations.
16. If enabled, the Risk Analysis Service calculates an advisory cold-chain risk score without changing the recorded facts.

This scenario is the source for quality scenarios, the C4 dynamic explanation and cross-view consistency checks.

## 16. Week 9 modelling contract

The following constraints govern the Application Architecture work required by `Tutorial PR.md`.

### 16.1 Project context

The project context must state:

- the platform is a traceability layer rather than a full ERP;
- organisations remain responsible for their internal operations and source systems;
- the business objective is verifiable cross-organisation provenance and faster food-safety impact analysis;
- the main risks are false source data, key compromise, conflicting handovers, privacy leakage, ledger governance, rural connectivity, interoperability and scale;
- blockchain is a required integrity and multi-party governance mechanism, not proof that physical claims are true.

### 16.2 Quality requirements

Quality scenarios must be selected from the reference scenario and working targets. Each scenario must include:

- source of stimulus;
- stimulus;
- operating environment;
- affected artefact;
- expected response;
- measurable response target;
- selected tactic;
- alternative and rejection reason.

The priority qualities are integrity and auditability, interoperability and modifiability, reliability under intermittent connectivity, query performance, scalability, availability, security and privacy.

### 16.3 C4 System Context

The Context diagram contains one central software system:

`Agricultural Supply Chain Traceability Network`

People:

- Supply-chain Participant;
- Consumer;
- Auditor or Regulator;
- Consortium Administrator.

External systems:

- Enterprise Operational Systems;
- External IoT Platform;
- Laboratory or Certification System;
- optional Notification Provider;
- optional AI or ML Endpoint only if implemented outside the platform.

The permissioned consortium ledger is part of the overall Traceability Network even though its nodes are operated by multiple organisations. A future public blockchain is external.

### 16.4 C4 Container view

The initial logical containers are:

- Participant PWA;
- Consumer Portal;
- Governance and Audit Portal;
- API Gateway;
- Identity and Profile Service;
- Traceability Command Service;
- Integration and IoT Gateway;
- Query and Visualisation Service;
- Projection Worker;
- optional Risk Analysis Service;
- Metadata Database;
- Encrypted Event Store;
- Trace Read Store;
- Message Broker;
- Consortium Ledger Network.

These are deployable or data containers, not a one-to-one copy of business-domain headings. The diagram must label responsibility and interaction protocols rather than showing unlabeled arrows.

### 16.5 Component views

Only two containers require detailed Component diagrams:

1. Traceability Command Service, covering normalisation, validation, identity and signature verification, idempotency, repeatable handover, aggregation, transformation, quantity and lineage validation, correction, commitment construction, ledger adapter, repository and outbox.
2. Query and Visualisation Service, covering policy evaluation, graph traversal across `HANDOVER`, `CONTAINS` and `DERIVED_FROM`, integrity verification, upstream lineage, downstream impact analysis and projection building.

The optional Risk Analysis Service does not require a detailed component diagram unless the team chooses AI and ML as a major peer-review focus.

### 16.6 Code view

The Code diagram expands one submission path only. It should show major interfaces and classes such as:

- `TraceEvent` and selected event types;
- `ObjectEvent`, `AggregationEvent` and `TransformationEvent`;
- `TraceableObjectRef`, `QuantityElement` and `LineageEdge`;
- `Handover` and its derived state;
- `TraceEventSubmissionService`;
- `EventValidationPipeline`;
- `EventValidator` implementations;
- `QuantityAndLineageValidator`;
- `EventRepository` port;
- `LedgerPort`;
- `OutboxPort`;
- `SubmissionReceipt`.

It must not become a diagram of every database entity or framework class.

### 16.7 Architectural rationale

The rationale must preserve this causal chain:

```text
Independent organisations and separate source systems
→ standard canonical events and integration adapters
→ generic repeatable handovers and graph-based split, merge and containment relationships
→ signatures, authorisation and versioned profiles
→ append-only event history and multi-organisation ledger commitments
→ asynchronous projection and CQRS read model
→ fast, authorised provenance and impact queries
→ offline queue, retry and idempotency for rural reliability
```

Patterns and tactics must be justified by this chain rather than listed independently.

## 17. Decisions fixed and decisions still open

### 17.1 Fixed architecture decisions

- The product is a traceability platform or layer, not a full ERP.
- Fresh produce cold chain is the detailed reference profile.
- Multiple products are supported through versioned profiles over a stable event model.
- EPCIS concepts provide the canonical event language.
- The write model is append-only; current state is derived.
- Shipping and receiving are separate signed assertions.
- The handover protocol supports an arbitrary number of logistics, distribution, processing and retail hops without role-pair-specific workflows.
- Provenance is a directed graph using `HANDOVER`, `CONTAINS` and `DERIVED_FROM` relationships rather than a linear batch history.
- Batch splitting, true merging or processing transformation, and pallet aggregation or disaggregation are core domain semantics.
- Aggregation preserves child identities; transformation creates new outputs with explicit input lineage and quantities.
- Complete event payloads are stored encrypted off-chain.
- Minimal commitments and approved shared facts are recorded on a permissioned consortium ledger.
- Enterprise operational systems and raw IoT telemetry remain external.
- Query and visualisation use an off-chain read model rather than ledger traversal.
- The application plane uses cloud-managed, horizontally scalable infrastructure.
- Ledger governance is multi-organisation.
- AI or ML, if included, is advisory, asynchronous and non-authoritative.

### 17.2 Open implementation decisions that do not block Week 9 modelling

- specific ledger technology and endorsement syntax;
- specific cloud provider;
- database and message-broker products;
- exact consortium quorum and onboarding procedure;
- final numeric workload assumptions after team review;
- selected regulatory jurisdiction and retention period;
- whether the AI risk extension is pursued for bonus marks;
- whether file import and notifications are included in the first release.

These choices must not change the system positioning, canonical event flow or trust boundaries.

## 18. Related documents

- [Case background](./Agricultural%20Supply%20Chain%20Tracker.md)
- [Assignment specification](./spec.md)
- [Week 9 and Week 10 peer review requirements](./Tutorial%20PR.md)
- [Industry platform research](./industry-platform-research.md)
- [GS1 EPCIS model notes](./epcis-model-notes.md)

