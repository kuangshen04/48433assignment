# 3. Architecture Views

*Draft — untrimmed. Rows covered: 3.1–3.10.*

This section describes the architecture as a hierarchy of views. Each view answers one question, and each
level narrows the scope of the previous one: the context view fixes the system boundary, the container view
opens it once, the component views open the two containers that carry the guarantees, and the code views show
the types that make those guarantees enforceable. Section 4 explains why each choice was made; this section
only states what the structure is.

## 3.1 View set and conventions

| View | Scope | Figure |
|---|---|---|
| System context (3.1) | The system as one box, its users and external systems | Figure 1 |
| Containers (3.2–3.4) | The runnable units, their responsibilities and interactions | Figures 2 and 3 |
| Components (3.5–3.7) | Internal structure of Traceability Core, the relayer and the analytics workspace | Figures 4, 5, 6 |
| Code (3.8–3.9) | Major classes, one interface and the enumerations that act as contracts | Figures 7 and 8 |

All figures use C4 notation: a box carries its name, its type, a short technology note and, where useful, one
line of responsibility. Relationships are labelled with intent and, where the transport matters, with the
protocol. Boundaries mark ownership or trust domains, not deployment. Diagrams are generated from versioned
source, so the figures in this document and the ones in the project repository cannot drift apart.

Two conventions are worth stating because they recur:

- **Naming is stable across levels.** A container keeps its name in the container, component and deployment
  views. "Ingestion & Projection Workers" is the same thing everywhere; it does not become "worker tier" in
  one figure and "async processor" in another. Two refinements are documented rather than silent: the
  deployment views split Public Snapshot Delivery into a snapshot origin and a CDN cache, and the sequence
  diagram uses short participant labels.
- **Protocol labels only appear where the protocol is architecturally relevant** — mTLS for key operations,
  transaction submission for chain writes, object API for snapshot publication. Plain HTTPS/JSON is the
  default for everything else and is not repeated on every edge.

## 3.2 System context

![Figure 1 — System context](../docs/public/diagrams/c4-context.svg)

*Figure 1 — System context: two peer subsystems, four groups of users, eight external systems.*

The context view establishes five things.

**The boundary contains two peer subsystems.** `Traceability Core` holds the shared record; `Regulatory
Analytics` holds the regulator's rule domain. They are peers, not a system and its add-on: the platform cannot
author the rules and the analytics subsystem cannot rewrite the trace. Participants' ERP, WMS, TMS and IoT
platforms are theirs; the external archive, the consortium KMS and the public chain are outside by definition —
their value comes from not being in the operator's account. Everything inside the boundary is described in
3.3–3.5.

**IoT devices attach to participants, not to the platform.** Sensors, scales and scanners feed the
participant's own systems, and the participant publishes EPCIS events from there. This is not an omission: it
is what keeps raw telemetry out of a shared record and keeps device fleet management out of the platform's
responsibilities.

**The device interface is deliberately narrow.** A device is registered as a delegation of an organisation —
an integration principal plus a set of allowed devices, locations and event types — not as a platform user with
an account. What crosses into the shared record is a profile-declared summary (min/max/mean, excursion
duration, source-reported alarm, with units and a time window) carried as an ordinary EPCIS extension field, so
it travels the same write path as any other event and needs no separate ingestion pipeline. The raw bundle
stays with the participant behind a reference and a salted commitment; the platform records only whether the
required summary is present, never what the sensor actually measured.

Three latency tiers follow from that boundary, and each has exactly one owner: real-time collection and
alarming at the edge (the participant), near-real-time availability once the event is received (the platform),
and final verifiability once it is confirmed (the archive and the chain). The cold-chain control loop therefore
belongs to the participant, and the platform's alarm is a post-confirmation advisory — requirements IoT-1 to
IoT-3 in Section 2.B, with the rationale in Section 4.B.

**Identity arrives on two independent lines.** Human authentication is delegated to an external identity
provider over OIDC. The legal identity of an organisation is verified once, at onboarding, against a business
registry. Neither is issued by the platform, and the second is what makes an organisation — rather than a
person — the unit of accountability.

**Three externals carry the "provable outside the platform" role.** The archive acknowledges stored bytes, the
KMS holds the consortium key outside the operator's account, and the chain stores Merkle roots. A fourth
external, the regulator's case-management and publication systems, carries the outputs that must reach the
official record. `Regulatory Analytics` is deliberately not one of them: it is a subsystem of this architecture,
not a third-party black box, and Section 4.6 returns to what that placement buys and costs.

## 3.3 Container view

![Figure 2 — Container view](../docs/public/diagrams/core-container.svg)

*Figure 2 — Containers, the two control domains, and the external systems they depend on.*

### 3.3.1 Containers and responsibilities

| Container | Responsibility | Form | Principal interfaces |
|---|---|---|---|
| Participant & Regulator Portal | Role-specific entry points — capture for grower and packer, handover confirmation for distributor, recall execution for retailer and regulator — plus scan-to-trace, insight views, evidence requests and exports | Progressive web application in the browser | HTTPS/JSON to the application; local offline queue |
| Traceability Application | Admission validation, confirmation orchestration, evidence graph, the single read entrance | Modular monolith: Core plus six semantic modules | REST in; SQL to the database; mTLS to the KMS; signed messages to analytics |
| Ingestion & Projection Workers | Archive writes, projection rebuild, exports, retention, advisory intake | Same image as the application, worker role | SQL; HTTPS to archive holders; object API to the snapshot origin |
| Batch Builder & Relayer | Leaf allocation, Merkle batching, root submission, inclusion proofs | Isolated worker; the only holder of the chain wallet | SQL; chain transactions |
| Operational PostgreSQL | Submission state, current registries, outbox, the queryable plaintext copy, projections | Managed relational database | SQL |
| Public Snapshot Delivery | Versioned public snapshots at the edge | Object storage plus CDN | Object API; HTTPS |
| Analytics Workspace | Screening, private findings, signed advisories | Regulator-operated runtime in the regulator's own account | Signed messages only — no shared network with the platform |

Two containers deserve a note because their boundaries are easy to misread. **Operational PostgreSQL holds a
plaintext copy of confirmed events** (the `QueryStore`), not only indexes: online lineage queries cannot
afford to fetch and decrypt from the archive on every hop. That copy is rebuildable, is not part of the
recovery guarantee, and is read-audited. **Analytics Workspace sits inside the system boundary but outside the
platform control domain**: it is operated in the regulator's own account (Figure 1), and it stays in this view
because the platform has a contract with it — what dataset may be exported, what may come back. That is why
the only edges crossing into it are signed messages.

### 3.3.2 Interactions

The container view shows four flows. Every other edge that crosses a boundary is a credential, a key operation
or a publication, and each of those crosses through a single interface.

1. **Capture.** Portal or a participant system submits a signed event to the application. The application
   validates and persists state, and enqueues an archive intent in the same transaction. Workers pick the
   intent up, obtain a wrapped key, write the envelope to an archive holder and record the acknowledgement.
   The relayer then batches the leaf and submits the root. This path is linear and has no branches: every
   later step depends on the previous one having produced durable evidence.
2. **Read.** Portal queries go to the application, which answers exclusively through the query interface and
   the plaintext copy. No read path touches the archive or the KMS; that is what keeps query latency
   independent of external systems.
3. **Public delivery.** Workers publish versioned snapshots to the origin; the CDN serves them. Consumers
   never reach the application.
4. **Cross-tenant.** The application exports a minimised dataset snapshot to analytics; analytics returns
   signed advisories and rule manifests to the workers' advisory intake. Both directions are signed messages,
   because the two sides do not share an account, a network or a trust domain.

### 3.3.3 Two control domains

The dashed boundary between the two control domains, both inside the system boundary, is the architectural
point of this view. The platform control domain holds everything the operator runs. The regulator control
domain holds analytics, its rule registry and its finding store, in an account the platform can deploy
artefacts into but cannot read from or operate.

This is why the container view carries the regulatory subsystem at all. It is modelled down to component and
code level because the contract with it — what dataset may leave, what may come back, what the platform may
never see — is part of the architecture. Drawing it as a black box would hide the boundary that the privacy
argument depends on.

![Figure 3 — Regulatory Analytics containers](../docs/public/diagrams/analytics-container.svg)

*Figure 3 — The three containers of the regulator control domain.*

## 3.4 Component views

Three containers carry guarantees that are worth opening: Traceability Core, the relayer, and the analytics
workspace. The portal and the snapshot delivery are deliberately left at container level; decomposing them
would produce screens and cache rules, not architecture.

### 3.4.1 Traceability Core

![Figure 4 — Core components](../docs/public/diagrams/core-component.svg)

*Figure 4 — Components of Traceability Core, with the modules that consume its read interface.*

The core has one write path and one read entrance:

- **Capture API** accepts a submission: the EPCIS event, the signature envelope, a client-generated
  `captureRecordId` and a profile reference.
- **Idempotency & Outbox Coordinator** claims the identifier, deduplicates by digest, and enqueues side
  effects so that archive, projection and anchoring are retried rather than lost.
- **Canonicalisation & Profile Validator** produces a deterministic digest and checks the event against the
  published profile, including the core field floor and the conformance rules.
- **Signature & Authority Validator** verifies the envelope, resolves the organisation, key and delegation,
  and evaluates trusted signing time for late or offline submissions.
- **Submission State Machine** owns the lifecycle and the failure states; nothing else advances a submission.
- **Archive & Anchor Orchestrator** owns the confirmation gate. It records the archive and anchor intent in
  the same transaction as the state change, checks the acknowledged digest when a worker reports it, issues the
  receipt, and decides when a submission may move on. The worker role of the same image executes the intent:
  it wraps the DEK and writes the envelope to a holder. The relayer claims the anchor intent from the database
  and submits the batch.
- **Confirmed Event Store / QueryStore** keeps the append-only canonical fields and edges, and the
  plaintext materialisation used by queries.
- **Evidence Graph Builder** derives lineage edges from EPCIS semantics, using a versioned derivation rule.
- **QueryPort** is the only way in for readers. It enforces scope, non-collapsing and watermark, and returns
  edge groups with per-edge provenance.

The six semantic modules appear in this view as an external component because they are outside the core but
inside the same process. They hold no canonical data and write no history; they read through `QueryPort` and
maintain rebuildable projections. `Insights` is the one that serves the analytical views: aggregates
materialised from the confirmed projection at a named watermark, scoped like every other read and holding no
private content.

### 3.4.2 Batch Builder & Relayer

![Figure 5 — Relayer components](../docs/public/diagrams/relayer-component.svg)

*Figure 5 — Components of the relayer, the only container that touches a chain.*

The relayer is drawn separately because it is the only container with a credential that can spend money and
write to a public network. Its components split along that line: `Anchor Intent Reader`, `Leaf Allocator`,
`Batch Builder`, `Manifest Writer`, `Finality Watcher` and `Proof Service` need no private key; only
`Chain Submitter` does. The allocator is deterministic, so a retry cannot create a second leaf for the same
event. The manifest writer puts the batch manifest next to the payload in the archive, which is what allows
recovery to reconstruct
"which batch contained this event" without the platform database.

### 3.4.3 Analytics Workspace

![Figure 6 — Analytics Workspace components](../docs/public/diagrams/analytics-component.svg)

*Figure 6 — Components of the analytics workspace, inside the regulator's account.*

The workspace has four components and no more in the first release: `Dataset Intake` (the only entrance, and
the only place where the dataset contract is enforced), `Rule Loader & Validator` (verifies the regulator's
signature and the rule's applicability, not its content), `Screening Runner` (deterministic rules over one
immutable snapshot at one watermark) and `Advisory Publisher` (applies the disclosure policy, signs, routes).
There is no model loader, no training pipeline and no review queue in this release, because the first
release runs deterministic rules only.

## 3.5 Code views

The code views show the major classes and interfaces that the guarantees depend on. They deliberately omit
persistence mapping, transport objects and generated types: C4 asks for code elements that make the design
legible, not for an implementation.

### 3.5.1 Traceability Core

![Figure 7 — Core code view](../docs/public/diagrams/core-code.svg)

*Figure 7 — Major classes, one interface and three enumerations of Traceability Core.*

Thirteen classes fall into four groups, and one class is the hub: `CanonicalEvent` is produced by
`CaptureSubmission`, validated against `ProfileVersion`, encrypted into `ArchiveEnvelope`, acknowledged by
`ArchiveAck`, committed as `MerkleLeaf` inside `AnchorBatch`, and derived into `EvidenceEdge`. Four design
properties are visible in the type model itself:

- `SignatureEnvelope` has no natural-person field, so attribution cannot accidentally acquire an employee
  reference.
- `ArchiveAck` carries the holder's signature over the stored bytes; `AcceptanceReceipt` binds its digest, so
  a receipt can only exist once an external holder has confirmed persistence.
- `QueryPort` exposes two operations and no others: `edges(EdgeQuery)` returns one hop of edge groups, and
  `traverse(EdgeQuery, depth)` returns a bounded multi-hop result that the store executes as a single recursive
  query under the same scope, non-collapsing and watermark rules. Neither returns a business status, so no
  caller can bypass any of the three.
- `ProtectedResourceRef` holds a salted commitment and a storage mode, but never content.

The three enumerations (`ConfirmationStatus`, `CustodyMode`, `EdgeType`) are part of the published contract:
once a value is in use, it cannot be silently added to or removed from.

### 3.5.2 Analytics Workspace

![Figure 8 — Analytics code view](../docs/public/diagrams/analytics-code.svg)

*Figure 8 — The eight classes of the analytics subsystem.*

Eight classes, three properties: `RuleVersionManifest` is the only artefact of the rule domain that leaves the
regulator's account, and it carries only a digest of the rule body; `Finding` and `AdvisoryFinding` share a
`findingId`, so an advisory is a disclosure of an existing finding rather than a new object, and a retraction
is the same identifier re-signed; `DisclosurePolicy` constrains advisories, not findings, because findings are
private by default.

## 3.6 Cross-view consistency

Criterion 3.10 asks whether the code structure actually reflects the context, container and component views.
The mapping below is the check, and it is also how the report defends the claim: every class is produced by
exactly one component, every component belongs to exactly one container, and the table names where each class
is also consumed.

| Component | Classes it produces or consumes |
|---|---|
| Capture API | `CaptureSubmission`, `ProtectedResourceRef` |
| Idempotency & Outbox Coordinator | `CaptureSubmission` (identifier and digest) |
| Canonicalisation & Profile Validator | `CanonicalEvent`, `ProfileVersion` |
| Signature & Authority Validator | `SignatureEnvelope`, `CustodyMode` |
| Submission State Machine | `ConfirmationStatus` |
| Archive & Anchor Orchestrator | `ArchiveEnvelope`, `ArchiveAck`, `MerkleLeaf`, `AnchorBatch`, `AcceptanceReceipt` |
| Confirmed Event Store / QueryStore | `CanonicalEvent`, `EvidenceEdge` (persisted, append-only) |
| Evidence Graph Builder | `EvidenceEdge`, `EdgeType` |
| QueryPort | `EdgeQuery`, `EdgeGroup` |
| Analytics Workspace | `DatasetSnapshot`, `ScreeningRun`, `Rule`, `RuleVersion`, `RuleVersionManifest`, `Finding`, `AdvisoryFinding`, `DisclosurePolicy` |
| Relayer components | `MerkleLeaf`, `AnchorBatch` |

Consistency is maintained by four rules rather than by review effort:

1. **One name per element.** The same container, component and class names appear in every view, so a rename
   is a visible change rather than a translation.
2. **Every component has a container, and every class has a component.** There are no orphan code elements
   and no components that exist only in a diagram.
3. **Exactly one interface crosses each trust boundary.** `QueryPort` for reads inside the platform, signed
   messages for the two cross-tenant flows, and `ArchiveAck` for the archive. A second entrance would mean a
   second enforcement point, which is the failure this design avoids.
4. **Enumerations are contracts.** They appear in the code view because they are published values, not
   implementation detail.

## 3.7 What these views deliberately do not model

- **Screens, routes and component state** of the portal. They change weekly and carry no architectural
  constraint.
- **Persistence mapping** (tables, indexes, ORM entities). The storage choice is described in Section 2 and
  revisited in Section 4; it does not belong in a C4 code view.
- **Transport objects and generated clients**, except where they are themselves the contract
  (`SignatureEnvelope`, `ArchiveAck`, `AdvisoryFinding`).
- **The regulator's internal analytics UI.** It is the regulator's product; the platform only depends on the
  signed messages it receives.

Deployment and dynamic behaviour are shown in Section 4, where the physical placement and the ordered
interactions are used as evidence for the security and cloud arguments.
