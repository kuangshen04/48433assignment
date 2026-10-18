# Agricultural Supply Chain Tracker — Architecture Report

## A1 Problem, objectives and stakeholders

An agricultural product moves through independent businesses, each keeping its own record of what it received, did
and passed on. Nothing joins those records: a regulator reconstructing a recall asks each business in turn and gets a
different identifier scheme, time zone and idea of "batch", so the answer arrives in weeks while the product is on
shelves. What is missing is a shared, attributable record a small producer can join cheaply and a regulator can trust
without trusting its host.

**Objectives.** Publish a claim cheaply, including offline (O1); make confirmed history tamper-evident to parties who
distrust the operator (O2); let a regulator scope an incident quickly and defensibly (O3); give consumers a truthful
view (O4); keep commercial detail and private evidence off the record (O5); run on a small team (O6); take device
evidence without becoming a device platform (O7); screen regulatory risk with ML optional (O8).

| ID | Party | What they need |
|---|---|---|
| S1 | Producer, grower, packer | Low-cost offline capture; signing without a corporate PKI |
| S2 | Processor | Transformation claims with quantities; no imposed mass-balance verdict |
| S3 | Distributor, cold chain | Two-sided handover; summaries, not raw telemetry |
| S4 | Retailer | Fast, conservative recall scope; a cacheable public view |
| S5 | Consumer | QR entry; "confirmed", "pending" and "no record" kept distinct |
| S6 | Regulator officer | Read access, case-scoped evidence, signed findings, audit trail |

The rest are parties to the design, not users of it: analytics (S7), governance (S8), the operator (S9), trustees
(S10), courts and auditors (S11), device vendors (S12).

## 2. Constraints

| ID | Constraint | Architectural effect |
|---|---|---|
| C1 | The brief requires a blockchain | Public anchoring of commitments carries a real responsibility |
| C2 | Australian and NSW food, privacy and records law | Residency, retention, privacy by design, correctable personal data |
| C3 | Participants keep their own systems | EPCIS 2.0 / CBV rather than a bespoke schema |
| C4 | Rural connectivity is intermittent | Durable offline queue, client-generated identifiers |
| C5 | Pilot scale: 200 organisations, 10 000 events/day | No premature distribution, no cluster, no broker |
| C6 | A small operating team | Managed services only, one deployable image |
| C7 | No production access | Deployment stated as a reference configuration |

## 4. Risk

| Risk ID | Category | Description | Priority | Probability | Severity | Response plan | Recovery plan | Owner | Status |
|---|---|---|---|---|---|---|---|---|---|
| R101 | Delivery | No consortium exists to operate validators | High | High | High | Do not build a permissioned ledger | Anchor on a public chain | Architect | Closed |
| R102 | Trust | The operator becomes the single point of trust | High | High | High | Copy outside the operator; external signature gates confirmation | Rebuild from archive and chain | Architect | Mitigated |
| R103 | Legal | Evidence is not defensible in a process | High | Medium | High | Signed acknowledgements, append-only, inclusion proofs | Re-issue proofs from the chain | Architect | Mitigated |
| R104 | Coverage | Smallholders excluded, leaving holes | High | Medium | High | PWA, offline queue, device-bound signing | Gateway onboarding | Product | Open |
| R105 | Compliance | Immutable log breaches privacy obligations | High | Medium | High | No natural-person field; personal data mutable | Deletion transition with a record | Architect | Mitigated |
| R106 | Scope | Creep into ERP, inventory or adjudication | Medium | High | Medium | Explicit non-objectives; admission does not judge plausibility | Cut the module | Sponsor | Open |
| R107 | Cost | Chain cost and latency make it impractical | Medium | Medium | Medium | Thirty-minute batching, one transaction per window | Move to a cheaper chain or L2 | Architect | Mitigated |
| R108 | Governance | Regulatory analytics over-reach | Medium | Medium | High | Findings private; no automated enforcement | Withdraw the advisory | Regulator | Open |
| R109 | Portability | Vendor or chain lock-in | Medium | Medium | Medium | Ports at every edge; chain-agnostic leaves | Re-anchor from the manifest | Architect | Mitigated |
| R110 | Data quality | False or collusive claims | Medium | Medium | High | Stated as a non-guarantee; conflicting claims coexist | Investigation, not computation | Regulator | Accepted |

## A2 Why these change the design, and what was excluded

Participants (S1–S5) with C4 force an integration tier: with only large manufacturers an ERP integration and a
corporate key would do, but because the smallest tier must publish, capture is browser-first, the queue survives
offline, the key never leaves the device and identifiers are client-generated. The regulator (S6, S7) forces a
boundary that would otherwise be invisible: analytics inside the platform's account would let the operator read every
rule and finding. Trust infrastructure (S8–S11) takes the record out of the operator's hands — cost is served,
unilateral control is not.

R1 and R3 eliminate the permissioned ledger, which fits the evidence requirement but needs validators this project
lacks. C1 and C2 are in tension — a public chain is mandatory, personal data must stay correctable — and the
resolution follows: commitments on chain, ciphertext off it, personal data in the mutable layer.

Out of scope, each because serving it would change the system's category: banks and insurers (pricing and settlement),
customs (a second legal regime), consumers as data producers (marketing, and personal data), certification bodies
(their certificates enter as private evidence), recycling operators (unvalidated event semantics), and marketing or BI
(served, if at all, inside the Insights module).

## 3. NFRs

| NFR ID | Description | Estimation | Priority | Dependency |
|---|---|---|---|---|
| NFR-S01 | Sensitive data is encrypted in transit and at rest | 5 | High | All writes |
| NFR-S02 | Every write is authorised against an organisation and role | 5 | High | Capture, handover, governance |
| NFR-S03 | No natural-person identifier enters the immutable record | 5 | High | Onboarding, evidence, analytics |
| NFR-S04 | A confirmed event is verifiable from published proofs alone | 8 | High | Anchoring, archive |
| NFR-S05 | Losing one dependency never yields a false "no record" | 8 | High | Recall, projection |
| NFR-P01 | 5 000 requests per second at the edge | 8 | High | Public delivery |
| NFR-P02 | 10 000 events per day sustained | 5 | Medium | Ingestion, batching |
| NFR-A01 | RPO 0 for receipted events; RTO 4 hours | 13 | High | Archive, recovery |
| NFR-U01 | Capture in under three minutes at 2G; WCAG 2.2 AA | 8 | High | Portal, offline queue |
| NFR-I01 | Interpretable from profile and canonicalisation version alone | 8 | Medium | Validation, archives |

## A3 Quality scenarios, and the alternatives rejected

Four scenarios test the qualities that decide the shape. **QS-1** an operator deletes a batch and the missing batch
breaks the chain sequence — integrity must be detectable from published proofs alone. **QS-2** a three-year-old event
is verified after two key rotations and a suspension — attribution must survive rotation. **QS-3** a recall runs at
02:00 during an archive outage — a lost dependency must degrade a capability, never to a false "no record". **QS-6** a
grower with no signal for 36 hours captures four events on a low-end phone — under three minutes at 2G, WCAG 2.2 AA.

Rejected while setting these: a database plus WORM backup (the operator stays sole verifier); a permissioned ledger
(no validators, R1); per-employee signing keys (natural persons in an immutable record, R5); synchronous calls to every
dependency on the read path; a graph database from day one; field-level encryption in the shared record (the platform
would still hold the keys).

## A4 Security, privacy and regulation

Every write is authorised against an organisation, a role and a delegation, bound per request; every canonical event
is non-repudiable across rotation and revocation; governance changes need dual control and apply only once anchored;
reads are audited per organisation and staff access needs recorded break-glass; analytics cannot pull arbitrary
private evidence, and findings are private by default.

**Integrity** rests on the public chain: a Merkle root every thirty minutes that any third party can verify without
asking the platform (NSW Food Act 2003; Food Standards Code). **Confidentiality** is a three-tier tradeoff — public
projection, consortium trace, owner-held evidence, with no middle tier; the platform reads consortium plaintext
because traversal needs it and never private content, and no natural-person identifier enters the immutable record
(Privacy Act 1988 and the APPs; NSW PPIP Act 1998). **Availability** comes from read/write separation: writes fail
closed and retry idempotently, reads come from the materialised copy with an explicit degradation state, so a recall
during an outage returns a labelled partial result rather than a silent miss.

## 1. User Story Backlog

| # | As a | I want to | So that | Est. | Priority | Dependency |
|---|---|---|---|---|---|---|
| 101 | Producer | publish an EPCIS event offline | my lot is in the record before I reach signal | 8 | H | Device key; profile |
| 102 | Producer | sign with a device-bound key | I can join without a corporate PKI | 5 | H | Onboarding |
| 103 | Processor | record a transformation with quantities | the input lot stays traceable through processing | 8 | H | Profile; lineage |
| 104 | Processor | submit competing claims | the record shows both, not one | 3 | M | Non-collapsing read |
| 201 | Distributor | confirm a two-sided handover | both parties attest the same transfer | 5 | H | Portal; signature |
| 202 | Cold chain operator | send a summary, not raw telemetry | my readings stay private | 8 | M | Profile extension; commitment |
| 301 | Retailer | run a recall scope query | I pull the right lot fast | 8 | H | Traversal |
| 302 | Retailer | read a public page for a lot | staff answer a customer without me | 3 | M | CDN snapshot |
| 401 | Consumer | scan a QR and see confirmed, pending or no record | I know what the record does not say | 3 | M | Public projection |
| 501 | Regulator officer | open a case and request evidence | I get the report without a data pull | 8 | H | Case scope; evidence request |
| 502 | Regulator officer | receive a signed notice | the finding is attributable and defensible | 5 | H | Advisory; anchor |
| 601 | Platform operator | see outbox lag and backlog age | I catch a stalled holder early | 5 | H | Monitoring |
| 701 | Analyst | view insight at a stated watermark | the figure I quote reproduces | 8 | M | Projection |

## 5. Data Dictionary

| Ref | Data element | Variable name | Format | Length | Description | Source |
|---|---|---|---|---|---|---|
| DE1001 | Capture record id | captureRecordId | UUID v4 | 36 | Idempotency key for one submission | Participant device |
| DE1002 | Event time | eventTime | ISO 8601 with offset | 30 | Business time asserted by the publisher | Publisher |
| DE1003 | Instance and lot list | epcList, quantityList | EPC URI / class-quantity-uom | 255 per entry | What moved and how much | Publisher |
| DE1004 | Quantity and unit | quantity, uom | Decimal 18,6 / UN-CEFACT | 22 / 3 | Asserted amount | Publisher |
| DE1005 | Profile identity | profileId, profileVersion | Slug / semver | 64 / 20 | Validation profile and version | Governance |
| DE1006 | Signing organisation | signerOrganisationId | UUID v5 | 36 | Organisation accountable for the claim | Registry |
| DE1007 | Signed digest | canonicalPayloadDigest | SHA-256 hex | 64 | The value actually signed | Platform |
| DE1008 | Evidence commitment | plaintextCommitment | SHA-256 hex | 64 | Salted commitment to off-platform content | Evidence owner |
| DE1009 | Custody mode | custodyMode | Enum | 16 | Consortium, private, public or device-held | Publisher |
| DE1010 | Archive acknowledgement | ArchiveAckDigest | SHA-256 hex | 64 | Holder's signature over stored bytes | Archive holder |
| DE1011 | Confirmation status | ConfirmationStatus | Enum | 32 | Lifecycle state of the submission | Platform |
| DE1012 | Finding identity | findingId, ruleVersion, dataWatermark | UUID / semver / uint64 | 36 / 20 / 20 | Finding and the inputs it used | Regulator |

## A5 Data scenarios, and the relational choice

**DS-1** a retail lot is traced to a farm block seven years later — forces append-only canonical tables and indexed
lineage edges. **DS-2** two processors consume one lot — forces no uniqueness on lineage and a query layer that
returns both rather than picking one. **DS-3** a regulator requests a packer's report — forces only a commitment and a
storage mode on the platform. **DS-5** a batch expires during a dispute — forces deletion as a recorded transition
executed by three parties. **DS-6** events arrive after a key rotation — forces idempotent ingestion and a review
state, because "invalid" and "not yet established" are different facts.

One managed relational database holds submission state, registries, the outbox, a queryable materialisation and
rebuildable projections. It is relational because EPCIS fields are typed and constrained, admission needs one atomic
step across event, idempotency claim and outbox, traversal is a bounded recursive query and reporting is set-oriented.
Rejected: a document store (loses cross-event constraints), a graph database as the record (the graph is derived), and
event sourcing for the whole application (profiles and job state are not events).

## A6 The data model: conceptual, logical, physical

Conceptually, a submission materialises one canonical event; an event validates against one profile version, is
acknowledged by one or more holders, commits as one leaf and references zero or more evidence records; a batch holds
many leaves and chains to its predecessor. Logically, the copy of record is the external archive; the database holds a
plaintext queryable copy that is rebuildable and excluded from the recovery guarantee, because lineage cannot decrypt
per hop.

Physically, eight tables. Five constraints matter: `capture_record_id` is the primary key of submission and canonical
event, so idempotency identity is identity; `merkle_leaf` is unique on `capture_record_id`, which makes anchoring
idempotent; `canonical_event` is partitioned monthly and append-only; `payload` holds only fields the platform does not
query; row-level predicates on `organisation_id` back the scope filter.

## 6. C4 Level 1 and Level 2 Analysis

![Figure 1 — System context](../docs/public/diagrams/c4-context.svg)

### Level 1: system context

| Ref | Element name | Element type | Description | Interaction with the record | Source |
|---|---|---|---|---|---|
| L1-001 | Producer, grower, packer | Person | Captures events at the point of production | Publishes claims, confirms handover | S1 |
| L1-002 | Processor | Person | Transforms inputs into outputs | Publishes transformation claims | S2 |
| L1-003 | Distributor, cold chain | Person | Moves and stores product | Confirms two-sided handovers, sends summaries | S3 |
| L1-004 | Retailer | Person | Sells to consumers, runs recalls | Scopes recalls, publishes public view | S4 |
| L1-005 | Consumer | Person | Reads the public view | Scans a QR, sees confirmed, pending or no record | S5 |
| L1-006 | Regulator officer | Person | Investigates incidents | Opens cases, requests evidence, signs notices | S6 |
| L1-007 | Traceability Core | Software system | Shared attributable record | Accepts, anchors and serves claims | O1–O3 |
| L1-008 | Regulatory Analytics | Software system | Regulator's rule domain | Screens confirmed claims, returns signed advisories | S7 |
| L1-009 | External archive | Software system | Copy of record | Signs for stored ciphertext | R102 |
| L1-010 | Consortium KMS | Software system | Key holder outside the platform | Wraps per-event data keys | R102 |
| L1-011 | Public chain | Software system | Commitment anchor | Receives Merkle roots | R103 |
| L1-012 | Identity provider, business registry | Software system | Identity on two lines | Authenticates humans, verifies organisations | NFR-S02 |

### Level 2: container analysis

| Ref | Container | Type | Responsibility | Users served | Communicates with | Data used | NFR justification |
|---|---|---|---|---|---|---|---|
| L2-001 | Participant and Regulator Portal | Web application | Role-specific capture, handover, recall, scan, insights | All user roles | Application, CDN | Forms, views | NFR-U01 |
| L2-002 | Traceability Application | Application | Admission, confirmation gate, evidence graph, read entrance | Portal, analytics | PostgreSQL, workers, KMS | Canonical events | NFR-S04, NFR-P01 |
| L2-003 | Ingestion and Projection Workers | Worker | Archive writes, rebuilds, exports, retention | Application | Archive, PostgreSQL, CDN | Envelopes, projections | NFR-A01 |
| L2-004 | Batch Builder and Relayer | Worker | Leaf allocation, Merkle batching, root submission, proofs | — | Chain, PostgreSQL | Leaves, roots | NFR-S04 |
| L2-005 | Operational PostgreSQL | Database | Submission state, registries, outbox, query copy | Application, workers | — | All operational data | NFR-A01 |
| L2-006 | Public Snapshot Delivery | CDN | Versioned public snapshots at the edge | Consumers, retailers | Workers | Public projection | NFR-P01 |
| L2-007 | Analytics Workspace | Application | Regulator's rules, screening, private findings | Regulator | Application | Minimised dataset, findings | R108 |

### External systems

| Ref | External system | Responsibility | Connected container | Data sent | Data received | Source |
|---|---|---|---|---|---|---|
| ES-001 | External archive | Holds the copy of record | Workers | Ciphertext envelope | Archive acknowledgement | R102 |
| ES-002 | Consortium KMS | Holds the consortium wrapping key | Application | Wrapped data key request | Wrapped key | R102 |
| ES-003 | Public chain | Anchors commitments | Relayer | Merkle root | Transaction reference | R103 |
| ES-004 | Identity provider | Authenticates humans | Portal | Assertion request | Authenticated session | NFR-S02 |
| ES-005 | Business registry | Verifies organisations | Application | Organisation identifier | Verified legal entity | NFR-S02 |
| ES-006 | Regulator case systems | Holds cases and notices | Analytics | Signed advisory | Case reference | R108 |
| ES-007 | Participant IoT systems | Collect and alarm locally | Application | Profile-declared summary | Acknowledgement | NFR-U01 |

## A7 Components, code and cross-view consistency

The core has one write path and one read entrance: `Capture API`, `Idempotency & Outbox Coordinator`, `Canonicalisation
& Profile Validator`, `Signature & Authority Validator`, `Submission State Machine`, `Archive & Anchor Orchestrator`,
`Evidence Graph Builder`, `Confirmed Event Store` and `QueryPort`. The orchestrator owns the confirmation gate and
records the archive intent while the worker role of the same image executes it; `QueryPort` exposes `edges()` and a
bounded `traverse()`, and nothing that returns a business status; the store is append-only, so a correction is a new
event. The relayer is drawn separately because it holds the only credential that can spend money: six of its seven
components need no private key, leaf allocation is deterministic, and the manifest writer places the manifest beside
the payload so recovery can reconstruct a batch without the database. The analytics workspace has four components,
with `Dataset Intake` as its only entrance.

In the type model, `SignatureEnvelope` has no natural-person field; `AcceptanceReceipt` binds the `ArchiveAck` digest,
so a receipt can only exist once an outside holder has confirmed persistence; `ProtectedResourceRef` holds a
commitment and a storage mode, never content. The three enumerations are published values. Consistency is maintained
by four rules rather than by review: one name per element across views, one owning component per class, one interface
per trust boundary, and enumerations as published contracts.

## A8 Quality tactics, patterns and SOLID

Each tactic names the quality it serves. Batching keeps cost and latency inside budget; the outbox and retry keep
recoverability; the single read entrance keeps privacy and auditability; the external signature keeps integrity;
derived projections keep performance. The patterns are a modular monolith layered inside, ports and adapters at every
external edge, a transactional outbox, a read model derived from the log, a state machine with anchored transitions,
and versioned contracts with published enumerations. Services, a direct SDK call, two-phase commit and per-hop
decryption were each rejected.

SOLID is visible where it matters: responsibilities split by reason to change, a new custody mode arrives as an
addition rather than a modification, four modes share one envelope, the read interface has two operations, and
dependencies point at interfaces. The five named smells are absent: no feature concentration (nine components split by
reason to change), no scattered functionality (one graph builder, one read entrance), no dense structure (acyclic,
single fan-in), no cycle (admission enqueues, workers execute), no unstable dependency (the core imports no vendor
package).

## 12. Architecture Pattern Analysis

| Style | Requirements supported | Advantages | Disadvantages | Decision |
|---|---|---|---|---|
| Layered | Admission, validation, storage, reads | Clear separation, easy to test | Limited deployment independence | Used inside the application |
| Modular monolith | All pilot requirements | One deployable, one database, no broker | Cannot scale components separately | Chosen for the pilot |
| Event-driven | Archive writes, projection rebuilds, anchoring | Asynchronous, retryable, decoupled | Ordering and duplicate handling | Used at the outbox and worker boundary |
| Ports and adapters | Archive, KMS, chain, identity | Replaceable vendors, chain-agnostic leaves | Indirection cost | Chosen at every external edge |
| Microservices | Independent scaling | Failure isolation | Sagas, broker, schema registry, platform team | Rejected at 10 000 events/day |
| Service-oriented | Enterprise integration | Reuse of existing services | Heavy governance, coarse contracts | Not applicable |

## 11. Smell Analysis Table

| Ref | C4 element | Architecture smell | Evidence | Proposed correction |
|---|---|---|---|---|
| AS-001 | Traceability Application | Feature concentration | Holds admission, confirmation, graph and reads | Nine components split by reason to change — already corrected |
| AS-002 | Traceability Application | Scattered functionality | Lineage computed in modules | One graph builder; reads pass through QueryPort — corrected |
| AS-003 | Traceability Core | Dense structure | Nine components with one fan-in | Acyclic; QueryPort is the only fan-in — none outstanding |
| AS-004 | Application and workers | Cyclic dependency | Callbacks between worker and application | Admission enqueues, workers execute, no callback — corrected |
| AS-005 | Adapters | Unstable dependency | Vendor SDKs inside the core | Ports at every external edge — corrected |

## 13. Communication Pattern Analysis

| Source | Destination | Data exchanged | Response | Dependency holder | Pattern and protocol | Justification |
|---|---|---|---|---|---|---|
| Portal | Application | Capture request | Immediate | Portal | REST over HTTPS/JSON | Caller needs the receipt |
| Application | PostgreSQL | State, outbox intent | Immediate | Application | SQL in one transaction | Atomic admission |
| Workers | Archive | Ciphertext envelope | Delayed | Application | Object API | Archive outage must not block admission |
| Workers | KMS | Wrap request | Delayed | Application | Key API | Key never leaves the trustee |
| Relayer | Chain | Merkle root | Delayed | Platform | RPC, batch every thirty minutes | Cost and finality |
| Application | Analytics | Minimised dataset | Delayed | Application | Signed export | Regulator runtime is independent |
| Analytics | Application | Signed advisory | Delayed | Regulator | Signed message | Findings are private by default |
| Workers | CDN | Versioned snapshot | Delayed | Platform | Object API | Edge serves consumers |

## 7. Cloud Model Selection

### Core internal containers

| C4 element | Deployment location | Service model | AWS service | Azure service |
|---|---|---|---|---|
| Portal | Public cloud | PaaS | Amplify Hosting | Static Web Apps |
| Traceability Application | Public cloud | PaaS | App Runner | Container Apps |
| Workers and relayer | Public cloud | PaaS | ECS Fargate | Container Apps jobs |
| Operational PostgreSQL | Public cloud | DBaaS | RDS PostgreSQL | Azure Database for PostgreSQL |
| Public snapshot delivery | Public cloud edge | SaaS | CloudFront with S3 | Front Door with Blob Storage |
| External archive | Trustee account | SaaS | S3 with Object Lock | Blob immutable storage |
| Analytics workspace | Regulator account | PaaS | App Runner | Container Apps |

### Internal cloud capabilities

| Capability | Purpose | Service model | AWS | Azure |
|---|---|---|---|---|
| Key management | Wraps per-event data keys outside the platform | SaaS | KMS | Key Vault |
| Batch anchoring | Submits roots to a public chain | Public network | Chain RPC | Chain RPC |
| Identity | Authenticates humans and services | SaaS | Cognito | Entra ID |
| Monitoring | Outbox lag, backlog age, degradation state | SaaS | CloudWatch | Monitor |
| Secret storage | Relayer wallet and adapters | SaaS | Secrets Manager | Key Vault |

### External systems

| External system | Responsibility | Connected capability | AWS integration | Azure integration |
|---|---|---|---|---|
| Archive | Copy of record | Object storage | S3 API through an adapter | Blob API through an adapter |
| Chain | Commitment anchor | RPC | Managed node or provider | Managed node or provider |

## A9 Cloud-native principles, and the deployment

The platform is PaaS: one managed container service running the application and the workers, a managed relational
database with a reader, object storage behind a CDN, and a managed KMS in a trustee's account. The principles applied
are managed services over infrastructure, one deployable scaled by role, twelve-factor configuration, stateless
application instances with state in managed stores, and infrastructure defined declaratively so the four accounts are a
property of the pipeline rather than of a checklist. Four scenarios decide the service model: QS-4 asks who serves the
bytes (a CDN, not a server); DS-3 asks who holds the content (a separate provider); QS-8 asks who operates the
analytics workspace (the regulator); C6 asks how much is operated at all (as little as possible). Rejected: IaaS with
a self-managed cluster, a shared tenant for analytics, on-premises object storage, origin-only delivery.

## 8. Dynamic Diagram Analysis

![Figure 12 — Dynamic view: event acceptance](../docs/public/diagrams/c4-dynamic.svg)

| # | Source | Destination | Data flow | Sensitive data | Trust boundary |
|---|---|---|---|---|---|
| 1 | Participant | Portal | Signed event, identifiers | Commercial | Internet to cloud |
| 2 | Portal | Application | Capture request | Commercial | Public to application |
| 3 | Application | PostgreSQL | Event, idempotency claim, outbox intent | Commercial | Application to data |
| 4 | Workers | Consortium KMS | Wrap request | Key material | Platform to trustee |
| 5 | Workers | External archive | Ciphertext envelope | Encrypted content | Platform to trustee |
| 6 | External archive | Workers | Acknowledgement, holder signature | None | Trustee to platform |
| 7 | Application | Participant | Acceptance receipt | Commercial | Application to participant |
| 8 | Relayer | Public chain | Merkle root | Commitment only | Platform to public |
| 9 | Application | Workers | Projection rebuild | Commercial | Internal |
| 10 | Workers | CDN | Versioned public snapshot | Public projection | Platform to edge |
| 11 | Consumer | CDN | Scan request | None | Internet to edge |
| 12 | Application | Analytics | Minimised dataset | Minimised | Platform to regulator |
| 13 | Analytics | Application | Signed advisory | Regulator-only | Regulator to platform |
| 14 | Regulator | Application | Evidence request | Case scope | Regulator to platform |

## 9. STRIDE Threat Model

| Threat ID | Element or flow | STRIDE category | Threat description | Security impact | Priority |
|---|---|---|---|---|---|
| T-01 | Capture request | Spoofing | A participant claims another organisation | Integrity | High |
| T-02 | Capture request | Repudiation | A publisher denies an event years later | Integrity | High |
| T-03 | Canonical event store | Tampering | A row or batch is altered or skipped | Integrity | High |
| T-04 | Archive envelope | Information disclosure | The archive is compromised | Confidentiality | High |
| T-05 | Evidence request | Information disclosure | A member reads outside scope | Confidentiality | High |
| T-06 | Public delivery | Tampering | A cached snapshot is edited at the edge | Integrity | Medium |
| T-07 | Ingestion | Denial of service | An event flood or a stalled holder | Availability | High |
| T-08 | Staff access | Elevation of privilege | An operator reads plaintext or a regulator reaches evidence | Confidentiality | High |
| T-09 | Relayer | Elevation of privilege | The chain wallet is stolen | Integrity, cost | High |

## 10. Security Mitigation Analysis

| Threat ID | Mitigation technique | Security control | Responsible element | Residual risk |
|---|---|---|---|---|
| T-01 | Bind the envelope to a verified organisation and key | Organisation identity, acting organisation | Admission | Compromised participant credentials |
| T-02 | Keep non-repudiable signatures and key history | Signature envelope, registry history | Signature validator | Third-party key custody shifts the question |
| T-03 | Append-only store with roots chained | Signed digests, consistency proofs | Confirmed event store, relayer | Asynchronous finality |
| T-04 | Never store readable content with the archive | Per-event data key wrapped outside the platform | Workers, KMS | Metadata exposure |
| T-05 | Single read entrance with per-request scope | Scope, non-collapsing, watermark | QueryPort | Access-pattern metadata |
| T-06 | Sign snapshots and version them | Immutable objects, CDN invalidation | Workers, CDN | Propagation delay |
| T-07 | Quotas, backpressure, bounded queues, two holders | Admission quotas, outbox monitoring | Application, workers | Sustained flood degrades others |
| T-08 | No standing access; dual-approved break-glass | Case-scoped grants, anchored access record | Application | Compromised break-glass path |
| T-09 | Isolate the relayer and its wallet | Dedicated container, no inbound path, KMS key | Relayer | KMS compromise |

## 17. HAZOP Analysis

Not used — ATAM selected. The system controls no physical process; its hazards are evidentiary and lifecycle, already enumerated as states and dependency failures.

## 16. Architectural Decision

| Issue | Alternatives | Decision | Rationale | Affected C4 elements | Stakeholders |
|---|---|---|---|---|---|
| Where confirmed history lives | Operator database; WORM backup; external holder | External archive is the copy of record | RPO 0 is only credible outside the operator | Workers, archive | Regulator, auditors |
| How a claim is confirmed | Platform timestamp; external holder signature; chain only | Holder signature plus final root | The operator must not be able to manufacture confirmation | Application, workers, relayer | All participants |
| How reads are scoped | Per-module filters; single entrance | QueryPort with scope, non-collapsing, watermark | A bypass is a confidentiality incident | Application | Regulator, participants |
| Where analytics runs | Shared tenant; separate account | Separate account in the regulator's domain | One administrator must not read rules and findings | Analytics | Regulator |
| How the chain is used | Per-event transaction; batched roots | Thirty-minute Merkle batches | Cost and finality | Relayer | Operator |
| How evidence is held | On the platform; owner-held with a commitment | Owner-held, commitment on the platform | Nothing to compel, nothing to delete | Portal, application | Evidence owners |
| How many deployables | Services per concern; one image | One image running as application or worker | A small team cannot operate a platform | All containers | Operator |
| Which model for analytics | ML model in the write path; deterministic rules | Signed rules, ML optional | A model must not adjudicate | Analytics | Regulator |

## 14. Architecture Evaluation

![Figure 2 — Container view](../docs/public/diagrams/core-container.svg)

| Requirement | Architectural support | Rating (0–5) | Evidence | Improvement |
|---|---|---|---|---|
| Immutable attributable record | Envelope, holder acknowledgement, Merkle inclusion | 5 | Confirmation requires an outside signature and a final root | Add cross-batch consistency proofs to the public UI |
| Participation by the smallest | Browser capture, offline queue, device-bound signing | 4 | Capture works without infrastructure | Keyless devices must draft and sign later |
| Recall scope | Traversal at a watermark with edge provenance | 5 | Bounded recursive query over derived edges | Cost grows with history; add an index review |
| Truthful consumer view | Versioned snapshots with explicit states | 4 | Pending and confirmed are distinct | A cached snapshot can lag a notice |
| Data not exposed | Content off-platform, owner-chosen recipients | 4 | The platform never decrypts private evidence | Metadata remains visible |
| Growth by configuration | Additive profiles | 3 | New products need no schema change | A new region needs a deployment and governance step |
| Operable by a small team | Managed services, one deployable | 5 | One image, one database, no cluster | Two more operated environments exist |
| Device evidence | Summaries with provenance | 4 | Raw telemetry never enters the record | Coverage follows participant instrumentation |
| Regulatory screening | Signed rules, watermark, private findings | 4 | Analytics at all three C4 levels | Depends on the regulator running it |
| Insight | Aggregation and scope designed | 3 | Projections support it | The view layer is a thin client, not specified |

## 15. ATAM Evaluation

| Scenario | Alternatives | Benefits | Trade-offs | Decision | Justification |
|---|---|---|---|---|---|
| Operator deletes a batch | A: database plus WORM backup. B: public anchoring with an external holder | A: simple, cheap. B: verifiable by any third party | A: the operator is the sole verifier. B: cost, finality, holder liveness | Select B | The guarantee is only as strong as the party who can verify it |
| Event flood at a checkpoint | A: synchronous archive write. B: archive intent in the transaction, executed by workers | A: immediate durability. B: admission stays fast and resumable | A: an outage blocks writes. B: an intent that has not yet been executed | Select B | Availability of admission outranks immediate archival |
| Regulator requests a lab report | A: store evidence on the platform. B: commitment plus owner-held content | A: simple retrieval. B: nothing to compel | A: privacy and deletion both break. B: availability depends on the owner | Select B | The privacy claim is the product |
| Analytics must be independent | A: shared tenant. B: separate account, signed messages | A: cheaper. B: the platform cannot read rules or findings | A: one administrator reaches both. B: two runtimes to operate | Select B | Separation is an IAM fact, not a promise |

**Risks.** External holders or the chain stalling ingestion; a flat read scope leaving admission as the only confidentiality control; the regulator not operating its runtime; chain cost and finality variance; a regional loss taking up to 24 hours; growth of the field floor burdening the smallest participants; one relayer with one wallet.

**Non-risks.** A monolith that will not scale; chain cost that will explode; a plaintext copy that contradicts privacy; an immutable log that defeats deletion.

**Trade-offs.** Finality versus freshness; shared visibility versus confidentiality; evidentiary strength versus forensics.

## A10 Alternative architectures

**A1 permissioned consortium ledger.** Four to seven validators with BFT consensus give seconds-level finality and
finer privacy, but need independent operators with HSMs, on-call and a charter; none exists, so it wins only if an
industry body funds them. **A2 trusted timestamping plus a transparency log.** WORM storage, RFC 3161 timestamps and
roots in an auditor-co-signed log: two or three trusted institutions instead of a public network, far cheaper, and the
strongest fallback — it wins only if C1 were relaxed. **A3 layer-2 anchoring.** The same envelope, leaves and proofs
under a rollup: cost down by orders of magnitude, at the price of a sequencer and a seven-year bet on that L2. **A4
microservices with an event bus.** Independent scaling, paid for with sagas, a broker, a registry and a platform team;
cost without benefit at 10 000 events/day.

| Criterion | Chosen | A1 | A2 | A3 | A4 |
|---|---|---|---|---|---|
| External verifiability | Any third party | Members only | TSA plus auditor | Public via L2 | Same as chosen |
| Operational burden | Low | High | Lowest | Low | High |
| Feasibility now | High | Low | High | High | Medium |

The chosen design is not the best in the abstract but the cheapest that keeps the first objective without institutions
that do not yet exist. Every alternative changes the edges, not the core: the event model, the query entrance and the
archive envelope survive each of them.

## A11 What this workbook still does not contain

The sheets are analysis scaffolding. A submitted report still needs the thirteen diagrams, the component and code
views, the data models, and the justification that turns each row into an argument.
