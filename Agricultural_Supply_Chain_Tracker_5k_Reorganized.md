# Agricultural Supply Chain Tracker — Software Architecture Report

## 0. Architecture at a glance

This system is a cross-organisation record of **attributable supply-chain claims**, not an ERP or an arbiter of physical truth. Participants publish versioned GS1 EPCIS events; other participants and regulators can inspect their provenance, competing claims and derived lineage. A claim is **CONFIRMED** only after an independent holder acknowledges its archived bytes and a batch commitment reaches public-chain finality. Thus a single operator cannot silently rewrite confirmed history, although signatures cannot prove that a claim describes reality. A modular application handles admission and scoped queries; workers handle archiving and projections; an isolated relayer anchors Merkle roots; public scans use CDN snapshots. Regulatory screening runs in a separate regulator-controlled domain. This architecture buys verifiability and recoverability at the cost of external-holder availability, asynchronous confirmation and cross-organisation governance.

For example, a retailer investigating a contaminated lot must traverse aggregation and transformation claims towards upstream producers. If two processors dispute an input lot, the trace preserves both provenance paths; it reports *possibly affected* material rather than selecting a winner. This makes traceability an evidence service for human decisions, not an automated food-safety verdict.

## 1. Project context

### 1.1 Problem, objectives and interested parties — rubric 1.1

Agricultural products pass between firms with incompatible identifiers, records and batch semantics. During a recall, reconstructing upstream and downstream movements requires contacting each firm; delay and inconsistent claims can undermine a defensible investigation. The proposed trace connects statements without taking over participants' operational systems. Its business objectives are: O1 affordable/offline participation; O2 attributable and tamper-evident history; O3 defensible incident scope; O4 a truthful consumer-facing state; O5 scoped commercial visibility and owner-controlled private evidence; O6 operability by a small team; O7 device evidence without becoming an IoT platform; and O8 reproducible regulatory screening, with ML optional.

| Stakeholder | Architectural interest and consequence |
|---|---|
| S1 Producers, growers, packers | Browser-first capture, offline queue and organisation-bound device signing avoid mandatory ERP or corporate PKI. |
| S2 Processors | EPCIS transformation quantities preserve input/output lineage without a platform mass-balance verdict. |
| S3 Distributors and cold-chain operators | Two-sided handovers and attributable sensor summaries, not uploaded raw telemetry. |
| S4 Retailers | Conservative recall traversal and public snapshots that survive scan bursts. |
| S5 Consumers | QR views distinguish CONFIRMED, PENDING and NO RECORD; consumers do not submit claims. |
| S6 Regulators | Watermarked scope, case-linked evidence requests and signed notices without unrestricted private-data access. |

A processing event may consume multiple lots and create one or more outputs; its quantity assertions belong to the publisher. If two processors each claim the same input lot, the record must show both edges and their provenance, not select the more plausible one. A retailer's recall traversal therefore returns a conservative potentially affected set, including disputed or provisional links as labelled evidence. This domain rule drives the graph and read interface as much as the blockchain choice does.

Governance, platform operations, archive/key trustees, auditors, courts and device vendors also matter: they define independent control, evidentiary verification and integration boundaries rather than extra user interfaces. The brief requires a blockchain (C1), food-safety compliance, IoT integration, multiple product lines and regions, data visualisation and rural accessibility. The design adopts NSW regulatory scope (C2), interoperability with participants' existing systems (C3) and intermittent rural connectivity (C4) as constraints; a pilot of 200 organisations, 10 000 events per day, a small operating team and no production access (C5–C7) sets the planning envelope.

### 1.2 Risks, exclusions and architectural relevance — rubric 1.2–1.3

| Risk or constraint | Decision and remaining exposure |
|---|---|
| No independent consortium validators (R1) | Public anchoring rather than operating a permissioned BFT network; public-chain cost and finality remain. |
| One operator could rewrite or remove evidence (R2–R3) | External ArchiveAck, separately controlled keys and Merkle inclusion; collusion or an unavailable holder remain risks. |
| Immutable personal or commercially sensitive records (R5) | No natural-person identifiers in canonical events; private evidence remains owner-held. Metadata persists. |
| Rural exclusion (R4) | PWA/offline submission; devices without viable signing capability must draft and sign later. |
| False, conflicting or collusive statements (R10) | Preserve provenance and competing claims; investigation, not automatic adjudication, determines business truth. |

ERP/WMS, inventory settlement, payment and full recall execution are excluded because they replace participants' business systems or introduce unrelated authority. Customs and certification processes introduce other legal/issuer regimes; certificates can instead appear as private evidence. Platform-side raw telemetry, consumer-originated claims and generic marketing/BI are likewise outside the pilot. State-level attackers, bankruptcy and compromised onboarding are acknowledged beyond this architecture's directly demonstrated controls. The governing distinction is **verifiable claims, not certified facts**.

## 2. Requirements analysis

### 2.1 System qualities, scenarios and rejected approaches — rubric 2.1–2.2

The following qualities connect stakeholder needs to measurable architecture tests.

| ID / stakeholder | Requirement and critical scenario | Risk and architectural consequence |
|---|---|---|
| SQ-1 Integrity / S6,S11 | Verify any CONFIRMED event against published proofs; QS-1 operator deletes a batch. | A broken batch sequence must be detectable; use chained Merkle commitments. |
| SQ-2 Attribution / S1–S3,S6 | Verify a three-year-old signature after two rotations and suspension (QS-2). | Retain signing-time authority and key history separately from cryptographic validity. |
| SQ-3 Availability / S4,S6 | QS-3 recall during archive outage never yields a false NO RECORD. | Declared degraded reads; fail-closed, retryable writes. |
| SQ-4 Performance / S4,S5 | QS-4 public demand reaches 5,000 scans/s; bound synchronous traversal to 10,000 edges. | Use edge snapshots and an indexed query copy rather than origin joins at scan time. |
| SQ-5 Recovery / S6,S9 | QS-5 platform account lost after receipt: receipted-event RPO 0; DB RPO ≤5 min, RTO ≤4 h, regional rebuild ≤24 h. | Archive, manifests and proofs must outlive platform tables; targets require drills. |
| SQ-6 Accessibility / S1 | QS-6 four captures during 36 h offline; usable at 2G, WCAG 2.2 AA and 200% text. | Durable client queue, local identifiers and appropriate signing fallback. |
| SQ-7 Privacy / S1,S6 | QS-7 regulator requests a laboratory report; QS-8 operator seeks regulator findings. | No private plaintext or natural-person fields in shared canonical records. |
| SQ-8 Interoperability / S1–S4 | Interpret an event from retained profile/canonicalisation versions; QS-10 chain replacement. | EPCIS/CBV profiles and chain-independent digests. |
| SQ-9 Auditability / S6,S11 | QS-9 two processors assert the same input lot; replay preserves both claims and provenance. | Non-collapsing evidence graph, versioned derivation and watermarks. |
| SQ-10 Operability / S9 | Small team operates one deployable application and managed database. | Avoid an orchestrated microservice estate without a scaling driver. |
| SQ-11 Device evidence / S3 | QS-12 a reefer exceeds limits for 40 minutes. | Profile-required, signed summaries with raw samples left at source. |
| SQ-12 Regulatory screening / S6 | QS-11 analytics unavailable during an open case; every finding is reproducible. | Screening is asynchronous and not on the capture/recall critical path. |
| SQ-13 Insights / S2–S6 | QS-13 reproduce a product-line figure at yesterday's watermark. | Materialised, scoped projections; no independent untraceable analytics truth. |

Rejected: operator-controlled WORM backup (no independent verification, SQ-1/5), per-employee immutable identities (SQ-7), synchronous external reads (SQ-3/4), authoritative graph storage (derived edges cease to be independently reconstructable, SQ-9), and ML-based admission (unauthorised adjudication). Section 4 traces these risks to tactics.

### 2.2 Data management, scenarios and storage — rubric 2.3–2.4

DM-1 requires events interpretable under their original profile; DM-2 forbids readable PRIVATE content on the platform; DM-3 distinguishes the authoritative archive from rebuildable copies; DM-4 defines per-class retention and legal hold; DM-5 excludes natural-person canonical identifiers; DM-6 binds findings to rule versions and data watermarks. Critical architecture-specific elements are:

| Element | Format / max length | Description; source; need |
|---|---|---|
| `captureRecordId` | UUID v4 / 36 | Submission identity and idempotency; participant; DM-3/S1. |
| `eventTime` | ISO 8601 with offset / 30 | Publisher-asserted business time; publisher; DM-1/S6. |
| `epcList`, `quantityList` | EPC URI / class, quantity, UOM; ≤255 per entry | Lot/instance and quantities; publisher; O3/S2. |
| `quantity`, `uom` | Decimal(18,6) / UN-CEFACT; 22 / 3 | Asserted amount and unit; publisher; S2. |
| `profileId`, `profileVersion` | Slug / semver; 64 / 20 | Frozen validation language; governance; DM-1/SQ-8. |
| `signerOrganisationId` | UUID v5 / 36 | Accountable organisation, not a person; registry; DM-5/SQ-2. |
| `canonicalPayloadDigest` | SHA-256 hex / 64 | Signed canonical content; platform; SQ-1. |
| `plaintextCommitment` | Salted SHA-256 hex / 64 | Reference to owner-held evidence; owner; DM-2. |
| `ArchiveAckDigest` | SHA-256 hex / 64 | Digest of holder's signed persistence acknowledgement; holder; DM-3. |
| `findingId`, `ruleVersion`, `dataWatermark` | UUID / semver / uint64; 36 / 20 / 20 | Reproducible finding identity; regulator; DM-6. |

The table covers the fields where architecture is decided; EPCIS 2.0/CBV supplies the standard business-event fields, and a retained versioned network profile constrains accepted extensions. Admission enforces typed, length-bounded profile fields. Profiles may add product-specific fields but cannot remove the core traceability floor, so a new product line changes approved validation rather than the shared event semantics.

`captureRecordId` is a transport idempotency identity, distinct from the EPCIS business event identifier. A correction does not overwrite the signed statement, and structural validity permits conflicting claims, whereas signing authority, required fields and idempotency collisions are admission checks. A query consumer sees the recorded assertion and its lifecycle status, not a platform-issued certification.

Six scenarios fix what would otherwise be design preferences. **DS-1** a seven-year recall requires indexed, versioned lineage. **DS-2** competing transformations require multiple provenance edges and never arbitrary deduplication. **DS-3** a laboratory report stays private behind a commitment. **DS-4** 5 000 scans per second requires CDN projections. **DS-5** an expiring batch under legal hold requires an auditable retention transition. **DS-6** delayed offline events after a key rotation require a review state rather than assuming a timestamp proves authority.

One managed relational database provides typed EPCIS columns, exact decimals, referential checks, one transaction for event/idempotency/outbox, recursive bounded traversal, row-level scope predicates and point-in-time recovery. A document store weakens cross-event relational enforcement, a graph database should not become the canonical truth, and full-application event sourcing would needlessly event-source profiles and worker state. Private evidence is not stored as platform-readable blobs. Section 4.2 specifies the physical split.

### 2.3 Cloud needs, adoption scenarios and service models — rubric 2.5–2.6

Participants need browser access rather than owned infrastructure; C6 rules out routine cluster patching; the regulator needs a control plane inaccessible to the platform operator. QS-4 requires edge rather than origin serving, DS-3 requires external evidence ownership, and QS-8 requires regulator-controlled analytics. The resulting choices are:

| Capability | Model / selected responsibility | Rejected alternative |
|---|---|---|
| Application and workers | Managed container PaaS; application/worker roles from one image | Self-managed IaaS cluster and operational platform team. |
| PostgreSQL | Managed relational PaaS, primary and reader, PITR | Self-managed database administration. |
| Public delivery | CDN plus versioned object snapshots | Per-scan origin/API reads. |
| Canonical archive and wrapping keys | Separate trustee-owned object storage and managed KMS | Operator-controlled backup and platform-held KEK. |
| Chain | Paid public network, batched root submission | Consortium validators with no operators. |
| Regulatory analytics | PaaS inside regulator account | Platform-administered shared tenant. |
| Identity | External identity provider and business registry | In-house passwords or platform-issued legal identity. |

Australian deployment locations, standards-based PostgreSQL and portable canonical formats support residency and exit planning.

### 2.4 Security, privacy, regulation and optional device/AI requirements — rubric 2.7–2.8 and 2.B

SP-1 binds every write to an acting organisation, role and delegation; SP-2 keeps signatures and historical authorisation verifiable; SP-3 prevents the platform from decrypting owner-held evidence; SP-4 excludes natural-person fields from immutable history; SP-5 requires dual approval for high-impact governance; SP-6 audits reads and break-glass; SP-7 keeps regulator rules/findings private; SP-8 records residual threats. **Confidentiality:** QS-7/8 test independent evidence ownership and analytics isolation. **Integrity:** QS-1/2 test public commitments and key history. **Availability:** QS-3/5 test explicitly degraded reads and separately recoverable receipts. Australian Privacy Principles/Privacy Act, NSW privacy obligations, NSW Food Act and Food Standards Code inform minimisation, retention, recall evidence and signed notices; Appendix B maps each obligation to its answer.

**IoT (2.B).** In a cold-chain excursion, a participant's device/system collects readings and alarms locally; a profile-required windowed summary, unit, provenance and commitment accompany an EPCIS event. Devices are organisation delegations, not independent platform identities. Uploading raw telemetry or making the platform the primary alarm path would turn traceability into time-series operations.

**AI/ML (2.B).** A regulator-controlled screening run uses a signed deterministic rule at a fixed watermark; an optional future model must produce the same reproducible, advisory output. ML at admission and platform-side training are rejected: neither may become an automatic finding of wrongdoing or block a valid statement.

## 3. Architecture views

Four views narrow in sequence: context fixes the boundary, containers show runtime roles, components and code specify responsibilities and contracts. Every diagram is generated from versioned source, so the report and the repository cannot drift apart.

### 3.1 Context and containers — rubric 3.1–3.4

![Figure 1 — System context](docs/diagrams/preview/c4-context.png)

*Figure 1 — Two peer subsystems, four groups of users, eight external systems.*

Traceability Core holds shared canonical claims, never the regulator's rule authority; Regulatory Analytics receives only a minimised export and returns signed disclosure messages. Devices feed participant systems, which submit profile-conformant EPCIS summaries. Humans authenticate through an identity provider; the business registry establishes the accountable organisation. The archive, KMS and chain remain external because their evidentiary role depends on not being administered solely by the platform.

![Figure 2 — Core containers](docs/diagrams/preview/core-container.png)

*Figure 2 — Containers of the platform control domain and the external systems they depend on.*

![Figure 3 — Analytics containers](docs/diagrams/preview/analytics-container.png)

*Figure 3 — The regulator's workspace, its rule registry and its finding store.*

| Container | Responsibility and key interaction |
|---|---|
| Portal | PWA capture, handover, regulator investigation, QR/insight views; uses the application or public CDN. |
| Traceability Application | Admission, confirmation gate, canonical event store, evidence graph and single read interface. |
| Ingestion/Projection Workers | Archive persistence, retries, lineage/projection rebuild, exports, retention and advisory intake. |
| Batch Builder/Relayer | Deterministic leaves, manifests, Merkle batches, chain submission, finality and proofs. |
| Operational PostgreSQL | Transactional state, registries, outbox and rebuildable plaintext QueryStore. |
| Public Snapshot Delivery | Versioned public objects served by a CDN, not origin database joins. |
| Analytics Workspace | Regulator-owned rule registry, screening, private findings and signed disclosures. |

Admission commits submission state and archive intent atomically; workers operate asynchronously. QueryPort reads the scoped materialisation rather than contacting archive or chain per query. Only the relayer holds the chain wallet. The analytics domain cannot rewrite canonical history; the platform cannot read its rule bodies or findings. Figure 3 makes that control separation explicit.

### 3.2 Components and code — rubric 3.5–3.10

![Figure 4 — Traceability Core components](docs/diagrams/preview/core-component.png)

*Figure 4 — Components of Traceability Core and the modules that consume its read interface.*

![Figure 5 — Relayer components](docs/diagrams/preview/relayer-component.png)

*Figure 5 — Components of the relayer, the only container that touches a chain.*

![Figure 6 — Analytics Workspace components](docs/diagrams/preview/analytics-component.png)

*Figure 6 — Four components, inside the regulator's account.*

The Core separates Capture API; Idempotency/Outbox Coordinator; Canonicalisation/Profile Validator; Signature/Authority Validator; Submission State Machine; Archive/Anchor Orchestrator; Evidence Graph Builder; Confirmed Event Store; and QueryPort. The orchestrator owns the gate, workers execute intents, and QueryPort exposes `edges()` and bounded `traverse()` but no business-truth verdict. The relayer isolates the single spending credential; deterministic leaves and archive-side manifests make proof regeneration possible. Analytics has Dataset Intake, Rule Loader/Validator, Screening Runner and Advisory Publisher; the first release has no ML model loader.

The component view sets responsibility boundaries for the conceptual entities; the code view specifies their types and relationships.

| Responsibility area | Primary entity | Key logical attributes |
|---|---|---|
| Capture API, validators, state machine | Submission | `captureRecordId`, `profileVersion`, `signerOrganisationId`, lifecycle state |
| Confirmed Event Store | Canonical event | `payload`, `eventTime`, `canonicalPayloadDigest` |
| Archive/Anchor Orchestrator | Acknowledgement, leaf, batch | `ArchiveAckDigest`, `merkleLeafIndex`, `batchId`, batch root |
| Evidence Graph Builder | Derived edge | source and target identifiers, `edgeDerivationVersion`, watermark |

![Figure 7 — Core code view](docs/diagrams/preview/core-code.png)

*Figure 7 — Thirteen classes, one interface, three enumerations.*

![Figure 8 — Analytics code view](docs/diagrams/preview/analytics-code.png)

*Figure 8 — Eight classes; the manifest carries a rule digest, never the rule body.*

![Figure 9 — Physical data model](docs/diagrams/preview/core-physical-model.png)

*Figure 9 — Nine tables; the constraints that matter are named in §4.2.*

`SignatureEnvelope` binds an organisation and signing evidence but no employee identity; `AcceptanceReceipt` references external `ArchiveAck`; `ProtectedResourceRef` contains a salted commitment and a storage mode rather than private content. `EvidenceEdge`, `EdgeQuery` and `EdgeGroup` carry provenance, scope and watermark. `RuleVersionManifest` discloses a rule digest, not its body; `Finding` and `AdvisoryFinding` share a stable identity.

Conceptually, submissions become canonical events linked to profile versions, evidence references, acknowledgement, leaf and batch. Logically, derived edges and projections belong to query components, not to the archived record. Across views each class has one owning component and container, external dependencies enter through ports, and enumerations are published contracts (Appendix A). Figure 9 resolves the same event, submission, leaf and batch identities into physical keys and relations — the deliberate bridge between the conceptual, logical and physical models. The SQL tables are not a second source of business truth.

## 4. Architectural rationale and decisions

### 4.1 Application structure, tactics, SOLID and design smells — rubric 4.1–4.5

The architecture adopts one modular application deployable, not one unstructured component. Admission has one write gate; all modules share one read entrance; append-only canonical claims feed replayable projections. This simultaneously serves SQ-1/3/4/8/9/10: independent proofs, resumable intake, fast reads, replaceable edges and manageable operations. The important decisions and alternatives are:

| Tactic / pattern | Why it serves a quality | Rejected instead |
|---|---|---|
| Modular monolith, layered inside | One release, bounded responsibilities at pilot scale (SQ-10) | Per-concern microservices, broker, sagas, platform team. |
| Transactional outbox | Submission identity, state and archive intent commit together (SQ-3/5) | Distributed two-phase commit or best-effort dual write. |
| CQRS-like derived read model + QueryPort | Indexed lineage and one scope/non-collapsing/watermark policy (SQ-4/7/9) | Per-module SQL filtering; decrypt on each traversal hop. |
| Append-only events + state machine | Corrections remain visible; CONFIRMED requires explicit gates (SQ-1/9) | Mutable event rows or a single `processed` flag. |
| Merkle batch anchoring | One root per 30-minute window with independent verification (SQ-1/10) | Per-event on-chain transactions or a platform timestamp. |
| Ports/adapters and versioned contracts | Archive/KMS/chain/identity can change without core rewrite (SQ-8) | Direct SDK dependencies and unversioned values. |

Responsibility by reason to change implements **SRP** (validation, graph construction and gate are distinct); a new custody adapter extends the port rather than changing the core (**OCP/DIP**); one envelope serves custody implementations under the same contract (**LSP**); QueryPort's narrow two-operation interface follows **ISP**. The design also checks the five smells rather than merely naming them: one graph builder avoids scattered lineage; one read entrance avoids duplicate privacy policy; acyclic admission → outbox → worker direction avoids cycles; narrow components prevent concentration inside one deployable; vendor packages stop at adapters to avoid unstable dependencies. A modular monolith still concentrates deployment risk, accepted for C5/C6.

### 4.2 Data authority, models and analytics — rubric 4.6–4.10

**The external archive is the copy of record; PostgreSQL is not.** A holder outside the platform's control domain signs for persisted ciphertext before a receipt is issued. The database retains a plaintext consortium query copy because recursive lineage cannot decrypt archived payloads on every hop. Its loss is recoverable from canonical events, manifests and proofs; it is not the RPO-0 authority. PRIVATE evidence stays with owners behind commitments; PUBLIC is a minimal projection, not a fourth unrestricted store. Three visibility classes avoid an unenforceable per-field policy inside an immutable record.

| Data role | Placement and lifecycle |
|---|---|
| Canonical encrypted events | Independent archive/qualified holder; authoritative during recovery. |
| Admission, idempotency, registries, outbox | Managed PostgreSQL; point-in-time recovery. |
| QueryStore and derived lineage | PostgreSQL materialisation; rebuildable with replay/versioned derivation. |
| Public view and insight marts | Versioned snapshots/materialised views; rebuildable, watermark-labelled. |
| Regulatory rules/findings | Independent regulator workspace; private; signed advisories cross the boundary. |

Figure 9 identifies nine physical tables. Five decisive constraints bind the logical model: `capture_record_id` identifies submissions/canonical events; `merkle_leaf.capture_record_id` is unique; canonical events are append-only and monthly partitioned; nonqueried payload remains separate; organisation predicates enforce the single scoped read path. Conceptual submission → event → profile/acknowledgement/leaf/batch relationships reconcile with Figure 4's store, graph and gate. Corrections add EPCIS error/corrective records rather than altering signed history. Edge derivation is versioned and replayable; conflicting claims coexist instead of being reconciled by hidden business heuristics.

For a transformation, canonical event types carry the claimed input and output identifiers. `Evidence Graph Builder` derives versioned edges but does not impose uniqueness on consumed lots: the same input may appear in multiple competing assertions. A recall query uses a fixed watermark and includes provenance on every traversed edge, so an officer can reproduce the scope rather than silently relying on a later, changed dataset. The event record, edge derivation version and public projection remain separately identifiable during replay.

No warehouse or data lake is warranted at 10,000 events/day: materialised insights meet the initial use cases without duplicating private content or adding another consistency boundary. The projection workers are the only ELT step — canonical events in, versioned marts out — so nothing downstream becomes a second source of truth. A new region requires a separate deployment and governance decision; a new product profile should not require rewriting the canonical event model. These choices address DM-1–6 without implying the platform can verify the physical truth of an event.

### 4.3 Cloud-native execution and deployment — rubric 4.11–4.15

![Figure 10 — Logical deployment](docs/diagrams/preview/c4-deployment.png)

*Figure 10 — Logical placement: which control domain owns which node.*

![Figure 11 — Reference deployment](docs/diagrams/preview/c4-reference-deployment.png)

*Figure 11 — A reference configuration that can be procured and built.*

Managed execution, declarative infrastructure, workload isolation, stateless application replicas and asynchronous worker scaling are the applied cloud-native principles. One container image runs as request-serving application or background worker; workers scale by outbox lag, portal/API by request demand, public delivery independently at the CDN. Stateful PostgreSQL remains managed rather than being placed in an application pod. This avoids administering Kubernetes or a self-managed IaaS cluster, consistent with C6; scale-out is based on observed load, not a promise of unlimited throughput.

Four administrative domains express ownership: the platform; an independent trustee holding archive and keys; the regulator's analytics workspace; and the regulator's evidence mirror. IAM and the deployment pipeline may deliver approved artefacts into the regulator's account, but cannot grant the platform standing read or operations access there.

The reference placement is a Sydney primary with Melbourne recovery copies, a managed PostgreSQL writer and reader with point-in-time recovery, an outbound-only single relayer with its wallet in KMS, object storage for the archive, and CDN delivery for public snapshots. The reference chain is Ethereum mainnet under a non-upgradeable anchoring contract, which also fixes the batch window and the confirmation depth at which a root becomes final. Active-active writes, self-run validators and a dedicated warehouse are not justified at pilot scale.

A qualified holder must be separately administered, retain and enumerate archived envelopes, and sign acknowledgements over the stored bytes; an ordinary object bucket cannot satisfy the confirmation gate. The reference quorum is one qualified acknowledgement, with additional independent mirrors for resilience. This trades launch coordination for independence: prolonged holder unavailability blocks new receipts, and regional rebuild within 24 hours is a drill target.

### 4.4 Dynamic evidence flows and trust boundaries — rubric 4.16–4.20

![Figure 12 — Dynamic view: event acceptance](docs/diagrams/preview/c4-dynamic.png)

*Figure 12 — One event from submission to confirmed visibility.*

![Figure 13 — Dynamic view: recall investigation](docs/diagrams/preview/c4-dynamic-recall.png)

*Figure 13 — Scope at a watermark, evidence request, signed notice.*

In Figure 12, (1) a participant submits the canonical event, organisation signature and client idempotency key; (2) admission validates profile and historical authority and commits state plus archive intent; (3) a worker obtains a wrapped per-event key from the externally governed KMS, stores an encrypted envelope with a qualified holder and records its signed `ArchiveAck`; (4) the platform issues a receipt and batches its deterministic leaf; (5) a segregated relayer publishes the chained Merkle root, observes finality and exposes inclusion proof; (6) only then does the event become CONFIRMED and contribute to public snapshots. Failed dependencies leave it pending; timeouts never silently promote it. Consumer scans terminate at the CDN, not the application.

| Flow crossing | Classification | Enforced boundary |
|---|---|---|
| Participant → admission | CONSORTIUM canonical data/signature | Identity, acting organisation and profile checks. |
| Platform → KMS/holder | Wrapped key, ciphertext and signed acknowledgement | Trustee account; no holder-readable plaintext. |
| Relayer → public chain | Batch root, sequence and transaction reference | Public commitment; no business payload. |
| Worker → public CDN | Versioned PUBLIC projection | Controlled disclosure/snapshot version. |
| Platform ↔ regulator domain | Minimised export; signed advisory | Signed contract, regulator-owned processing. |

Figure 13 fixes recall traversal at a data watermark, preserves provisional claims separately and records a regulator evidence request as an auditable reference rather than an arbitrary data pull. An official notice becomes CONFIRMED only after its canonical signing/anchoring requirements; the system establishes scope but businesses execute the recall. This prevents a transient dependency failure from being misreported as proof that no affected lot exists.

**STRIDE coverage** follows the actual entry points: participant API/onboarding, portal reads, staff and evidence requests, exports to archive/KMS/chain/regulator, and internal worker/wallet control. Residuals are deliberately stated rather than implied away.

| Category / threat | Mitigation and boundary | Residual risk |
|---|---|---|
| Spoofing: forged organisation/device | Verified legal organisation, delegated signer, authority-at-signing-time | Stolen participant credentials. |
| Tampering: altered/omitted batch | Signed digest, append-only events, chained roots, consistency/inclusion proof | Asynchronous finality and unavailable proofs. |
| Repudiation: denial of claim/notice | Envelope signature, historical key registry, signed holder/issuer receipts | External key custody and disputed real-world facts. |
| Information disclosure: private evidence/out-of-scope query | Owner-held encryption and QueryPort enforcement | Metadata, access patterns and authorised runtime plaintext. |
| Denial of service: flood or missing holder | Quotas, bounded queues, backpressure, retry; qualified holder set | Sustained saturation or absent acknowledgements. |
| Elevation of privilege: operator or wallet compromise | No standing staff access, dual-approved anchored break-glass; isolated outbound relayer | Colluding approvers or compromised KMS/wallet. |

These controls address SP-1–7 within stated trust boundaries. Anchoring proves a commitment, not physical truth. The platform runtime still reads CONSORTIUM plaintext; collusion, access metadata and partner insolvency remain risks. External holders control their own evidence, and the operator cannot alone fabricate a valid holder signature.

### 4.5 IoT and AI/ML in the architecture — rubric 4.B, bonus

IoT ingestion begins at the participant's sensors and local control system, which performs collection and real-time alarms. The integration adapter publishes a profile-conformant summary (window, unit, min/max/mean, excursion duration/alarm), device delegation and commitment to owner-retained samples. Neither raw streams nor mandatory platform-side alerting enter the shared record. This preserves a verifiable evidence reference while limiting retention and protecting rural intermittent links.

Regulatory screening consumes a minimised, versioned snapshot in the regulator account. A signed deterministic rule is evaluated against a known watermark; the private finding records rule version and inputs, while a scoped advisory is separately signed before disclosure. An ML scorer could implement the same advisory interface later, but there is no model loader in the pilot. The model must not gate admission or automatically issue an enforcement/recall decision. Independence costs a second operating environment, and screening can be temporarily unavailable without preventing canonical trace queries. Insight views are derived from the same materialised lineage, labelled by acting organisation, projection version and watermark. Product-line aggregation therefore cannot silently override disputed claims or reinterpret a provisional edge as established provenance. The portal provides role-specific capture, handover, investigation and insight entry points; detailed screen design is deferred, while offline capture, accessible field labels and state distinctions remain architectural acceptance criteria.

## 5. Evaluation and feasible alternatives

### 5.1 Business-objective assessment — rubric 5.1–5.2

The Brief column names which of the brief's seven key requirements each row answers; privacy and pilot operability follow from the design rather than from the brief.

| Objective | Brief | Verdict and architectural evidence | Unclosed limitation |
|---|---|---|---|
| O1 Rural participation | 2, 7 | Conditional: PWA/offline queue and local identifiers | Some devices cannot sign until connected. |
| O2 Attributable history | 1 | Strong design: signed events, independent ack, Merkle finality | False/collusive assertions and governance remain. |
| O3 Recall scope | 5 | Supported: non-collapsing, watermarked indexed lineage | Completeness follows participants' event coverage. |
| O4 Consumer view | 2 | Supported: versioned CDN states and signed notices | Cache propagation may lag a new notice. |
| O5 Evidence/privacy | implied | Supported: owner-held PRIVATE data; scoped consortium read | Metadata and runtime plaintext remain. |
| O6 Pilot operability | implied | Plausible: one deployable, managed services, batch anchoring | External holders and regulator domain need operators. |
| O7 IoT evidence | 3 | Conditional: summaries plus source commitments | Instrumentation and source retention differ by firm. |
| O8 Reproducible screening | bonus | Structural: regulator rule versions and watermarks | Regulator must operate the workspace. |
| Product lines, regions, insights | 4, 6 | Partly supported: profiles and materialised views | Region expansion and front-end visual design remain work. |

### 5.2 ATAM: sensitivities, risks and trade-offs — rubric 5.3

ATAM is chosen over HAZOP because this platform records evidence rather than controlling physical processes. High-importance drivers are integrity after operator loss, non-repudiation across key rotations, recall under archive outage, 5 000 public scans per second, offline capture and PRIVATE evidence disclosure.

Sensitivity points are the anchoring window (cost against confirmation delay), qualified-holder liveness (receipt throughput against independence), the query traversal bound (recall completeness against latency) and visibility scope (regulatory authority against commercial confidentiality). Risks are an unavailable holder or chain, a single relayer spending credential, inadequate admission governance, a regulator unwilling to run its workspace, and an untested regional recovery time.

Accepted trade-offs are provisional visibility before finality, metadata leakage instead of hosting private content, and small-team operability over independent scaling of every module. No benchmark or recovery drill has yet proved the targets; the reference deployment is a buildable proposal, not an operational result. Test priority follows from that: signature and authority replay, independent archive enumeration after platform loss, holder and chain outage injection, non-collapsing recall under load, and low-end offline capture. A failed test reopens the requirement; it does not license a quietly weaker guarantee.

The key assessment is not whether the architecture eliminates all failures. Confirmation deliberately trades immediacy for independently checkable persistence and finality; rural accessibility trades synchronous verification for durable local capture; regulatory independence trades operational simplicity for separation of rule authority. A pilot should measure all three before adopting stronger availability or geographic scale claims.

### 5.3 Alternative architectures — rubric 5.4

| Alternative | Feasibility and reason not selected | When it becomes preferable |
|---|---|---|
| A1 Permissioned BFT consortium ledger | Strong member governance and faster finality, but needs four or more independent validator operators, HSMs and on-call charter absent at launch. | Industry consortium funds sustained shared operations. |
| A2 Layer-2 anchoring | Retains chain-based verification with lower indicative transaction cost; adds sequencer, settlement/finality and longevity dependencies. | Mainnet cost or delay breaches a measured threshold. |
| A3 Microservices/event bus | Independent releases/scaling but adds broker, distributed state/sagas and a platform team at 10,000 events/day. | Workloads/teams acquire independent release or scaling requirements. |
| Conditional non-blockchain fallback: TSA + transparency log | Potentially cheaper with auditor co-signing, but violates the brief's mandatory blockchain constraint. | Only if C1 is formally relaxed. |

The selected design is not universally optimal: it favours independently verifiable evidence without relying on an unformed validator consortium, while keeping the operational application modular but centrally deployed.

---

## Appendix A — Evidence index

| Claim or requirement | Primary evidence |
|---|---|
| SQ-1/2, SP-1/2 | Figures 4, 5, 7, 12; Section 4.4 signed acknowledgment and chain proof. |
| SQ-3/5, DM-3/4 | Figures 2, 9–12; archive, outbox, retention and recovery boundaries. |
| SQ-4/9, DM-1/6 | Figures 4, 7, 9, 13; QueryPort, provenance, derivation and watermark. |
| SQ-6/8/10 | Figures 1, 2, 10, 11; offline capture, EPCIS profiles, managed modular deployment. |
| SQ-7, SP-3–8 | Figures 1, 3, 6, 8, 12–13; owner-held evidence and regulator isolation. |
| SQ-11–13 | Figures 1, 3, 6, 8; participant IoT summaries and regulator/insight projections. |
| Code-to-component-to-container | Figures 7/8 → 4/6 → 2/3; stable names, one owner per model, boundary ports. |

## Appendix B — Regulation and terminology

| Obligation or term | Interpretation in this design |
|---|---|
| NSW Food Act / Food Standards Code | Supports conservative recall evidence and signed notices; does not authorise automated findings of fact. |
| Privacy Act / APPs; NSW privacy obligations | Minimise immutable identity, scope reads, keep evidence owner-held and retain mutable correction paths. |
| Records retention and legal hold | Class-based rules, logged transitions, multi-party deletion controls and anchored audit evidence. |
| EPCIS / CBV | GS1 event semantics / Core Business Vocabulary; extended through retained versioned profiles. |
| ArchiveAck; DEK; KEK | Holder-signed persistence acknowledgement; per-event data-encryption key; externally controlled key-encryption key. |
| Merkle root; finality; inclusion proof | Batch commitment; chain confirmation threshold; evidence that a leaf belongs to a root. |
| QueryPort; watermark; non-collapsing | Single scoped read interface; fixed input version; preservation of contradictory lineage claims. |
| PWA; CDN; KMS; PITR | Progressive Web App; content delivery network; key-management service; point-in-time recovery. |
| ATAM; STRIDE; SOLID | Architecture Tradeoff Analysis Method; threat categories; object-oriented design principles. |
| C4; CQRS; IAM; WORM; BFT | Software architecture view model; command/query responsibility separation; identity and access management; write-once-read-many; Byzantine fault tolerance. |
| RPO; RTO; WCAG; NFR | Recovery point objective; recovery time objective; Web Content Accessibility Guidelines; non-functional requirement. |
