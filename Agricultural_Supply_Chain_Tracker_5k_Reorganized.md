# Agricultural Supply Chain Tracker — Software Architecture Report

## 0. Architecture at a glance

This system is a cross-organisation record of **attributable supply-chain claims**, not an ERP or an arbiter of physical truth. Participants publish versioned GS1 EPCIS events; other participants and regulators can inspect their provenance, competing claims and derived lineage. A claim is **CONFIRMED** after durable platform storage and finality of its public-chain batch commitment. Participants retain signed submissions and can export confirmation proofs for verification independent of platform query results. Thus a single operator cannot silently rewrite confirmed history, although signatures cannot prove that a claim describes reality. A modular application handles admission and scoped queries; workers handle projections and exports; an isolated relayer anchors Merkle roots; public scans use CDN snapshots. Authorised regulators use the platform’s scoped investigation and export functions. This architecture separates independently verifiable history from service availability: managed backups support recovery, while anchoring introduces cost and confirmation delay.

For example, a retailer investigating a contaminated lot must traverse aggregation and transformation claims towards upstream producers. If two processors dispute an input lot, the trace preserves both provenance paths; it reports *possibly affected* material rather than selecting a winner.

## 1. Project context

### 1.1 Problem, objectives and interested parties — rubric 1.1

Agricultural products pass between firms with incompatible identifiers, records and batch semantics. During a recall, reconstructing upstream and downstream movements requires contacting each firm; delay and inconsistent claims can undermine a defensible investigation. The proposed trace connects statements without taking over participants' operational systems.

| ID | Business objective |
|---|---|
| O1 | Affordable/offline participation. |
| O2 | Attributable and tamper-evident history. |
| O3 | Defensible incident scope. |
| O4 | A truthful consumer-facing state. |
| O5 | Scoped commercial visibility and owner-controlled private evidence. |
| O6 | Operability by a small team. |
| O7 | Real-time transport monitoring with retained journey and exception evidence. |

| Stakeholder | Architectural interest and consequence |
|---|---|
| S1 Producers, growers, packers | Browser-first capture, offline queue and organisation-authorised signing avoid mandatory ERP or employee certificates. |
| S2 Processors | EPCIS transformation quantities preserve input/output lineage without a platform mass-balance verdict. |
| S3 Distributors and cold-chain operators | Two-sided handovers and attributable sensor summaries, not uploaded raw telemetry. |
| S4 Retailers | Conservative recall traversal and public snapshots that survive scan bursts. |
| S5 Consumers | QR views distinguish CONFIRMED, PENDING and NO RECORD; consumers do not submit claims. |
| S6 Regulators | Scoped, watermarked trace queries and evidence exports without unrestricted private-data access. |

| ID / supporting stakeholder | Interest and architectural relevance |
|---|---|
| S8 Governance | Controls membership and shared semantics; requires organisation approval, auditable key changes and versioned profiles. |
| S9 Platform operations | Needs manageable cost and recovery; favours one application deployable, managed services and observable background work. |
| S10 Cloud and backup providers | Supply managed execution and recovery; service limits and failure domains shape deployment and backup placement. |
| S11 Auditors and courts | Need attributable, reproducible evidence; motivates historical key records, fixed query watermarks and exportable proofs. |
| S12 Device vendors | Need a stable integration contract; profile-based gateway submissions isolate device protocols from the Core. |

A processing event may consume multiple lots and create one or more outputs; its quantity assertions belong to the publisher. If two processors each claim the same input lot, the record must show both edges and their provenance, not select the more plausible one. A retailer's recall traversal therefore returns a conservative potentially affected set, including disputed or provisional links as labelled evidence. This domain rule drives the graph and read interface as much as the blockchain choice does.

The brief also requires food-safety compliance, IoT integration, multiple product lines and regions, data visualisation and rural accessibility.

| ID | Constraint / planning envelope |
|---|---|
| C1 | Blockchain-based solution. |
| C2 | Assumed initial jurisdiction: NSW, to bound first-release compliance analysis; regional load scalability remains required. |
| C3 | Interoperability with participants’ existing systems. |
| C4 | Intermittent rural connectivity. |
| C5–C7 | Pilot: 200 organisations, 10 000 events/day across all participating regions; small operating team; no production access. |

### 1.2 Risks, exclusions and architectural relevance — rubric 1.2–1.3

| Risk or constraint | Decision and remaining exposure |
|---|---|
| No independent consortium validators (R1) | Public anchoring rather than operating a permissioned BFT network; public-chain cost and finality remain. |
| One operator could rewrite or remove evidence (R2–R3) | Organisation signatures, public commitments and participant-held records/proofs expose changes to committed history; deletion can still make records unavailable. |
| Immutable personal or commercially sensitive records (R5) | No natural-person identifiers in canonical events; private evidence remains owner-held. Metadata persists. |
| Rural exclusion (R4) | PWA/offline submission; devices without viable signing capability must draft and sign later. |
| False, conflicting or collusive statements (R10) | Preserve provenance and competing claims; investigation, not automatic adjudication, determines business truth. |

ERP/WMS replacement, inventory settlement, payments, formal notices, private-document exchange and physical recall execution remain external because the tracker records evidence rather than operating participants' businesses. Platform-side raw telemetry, consumer-originated claims and generic marketing/BI are also excluded.

| Considered exclusion | Reason and architectural consequence |
|---|---|
| Customs authorities and certification issuers as direct users | Clearance and certificate issuance are outside initial NSW use cases; certificates may be referenced as owner-held evidence. |
| Mandatory participant-hosted servers or consortium validators | Rejected as deployment constraints because they conflict with rural access and small-team operation; browser/gateway access and public anchoring are selected. |
| Recovery after participant insolvency or permanent loss of owner-held evidence | Outside the platform recovery guarantee because participant archives are not operator-controlled; unavailable evidence remains labelled. |

Compromised onboarding, key theft, public-chain outages and advanced attackers remain residual risks, not scope exclusions; admission controls, audit, isolation and degraded operation limit their impact without guaranteeing prevention.

## 2. Requirements analysis

### 2.1 System qualities, scenarios and rejected approaches — rubric 2.1–2.2

The following qualities connect stakeholder needs to architecture tests. Numerical load and recovery targets are planning assumptions to validate, not brief-mandated thresholds.

| ID / stakeholder | Requirement and critical scenario | Risk and architectural consequence |
|---|---|---|
| SQ-1 Integrity / S6,S11 | Verify any CONFIRMED event against published proofs; QS-1 operator deletes a batch. | A broken batch sequence must be detectable; use chained Merkle commitments. |
| SQ-2 Attribution / S1–S3,S6 | QS-2 verify an accepted event after its organisation rotates or revokes a key. | Retain the original public key, signature and admission-time membership/key status; later revocation does not rewrite history. |
| SQ-3 Availability / S4,S6 | QS-3 recall during chain/proof-service outage never yields a false NO RECORD. | Read local projections and report missing verification material; chain outages leave new events pending. |
| SQ-4 Performance / S4,S5 | QS-4 public scans reach the planning load of 5,000/s; synchronous trace queries have a protective limit of 10,000 edges. | Use edge snapshots and indexed queries; label truncated traversals rather than imply complete recall coverage. |
| SQ-5 Recovery / S6,S9 | QS-5 restore operational data from managed backups: planned DB RPO ≤5 min and RTO ≤4 h. | Retain signed submissions and exportable proofs for independent verification; complete service reconstruction after operator-account loss is outside scope. |
| SQ-6 Accessibility / S1 | QS-6 a rural user captures events on a low-end device during intermittent connectivity and submits queued records after reconnection. | Lightweight forms, readable labels, explicit offline/pending states and a durable local queue with signing fallback. |
| SQ-7 Privacy / S1,S6 | QS-7 an investigator exports recall evidence; unrelated organisations’ records and private document contents must be excluded. | Scoped queries and export allowlists; no private plaintext or natural-person fields in shared canonical records. |
| SQ-8 Interoperability / S1–S4 | QS-10 participants exchange interpretable events across product lines using retained profile/canonicalisation versions. | EPCIS/CBV profiles preserve shared semantics while allowing approved product-specific extensions. |
| SQ-9 Auditability / S6,S11 | QS-9 two processors assert the same input lot; replay preserves both claims and provenance. | Non-collapsing evidence graph, versioned derivation and watermarks. |
| SQ-10 Operability / S9 | Small team operates one deployable application and managed database. | Avoid an orchestrated microservice estate without a scaling driver. |
| SQ-11 Real-time IoT integration / S3 | QS-12 a reefer exceeds limits during transport: connected users see current readings, excursions are prioritised and monitoring gaps remain visible. | Best-effort routine telemetry; signed journey summaries and retained abnormal-evidence windows enter the shared record. |
| SQ-13 Insights / S2–S6 | QS-13 an authorised user views product-line and cold-chain summaries, including excursions and monitoring gaps. | Scoped materialised projections support visualisation; watermarks identify the data version shown. |
| SQ-14 Regional scalability / S1–S4,S9 | QS-14 several regions submit seasonal bursts; accepted events are retained and confirmation lag is visible. | Queued work and scaling absorb bursts; database and batch capacity require validation. |

| Rejected approach | Reason for rejection / quality link |
|---|---|
| Backups alone as evidence of integrity | No independent commitment (SQ-1). |
| Per-employee immutable identities | Conflicts with personal-data minimisation (SQ-7). |
| Synchronous external reads | External outages and latency affect local queries (SQ-3/4). |
| Authoritative graph storage | Derived edges cease to be independently reconstructable (SQ-9). |
| ML-based admission | Introduces unauthorised adjudication. |

Section 4 traces these risks to tactics.

### 2.2 Data management, scenarios and storage — rubric 2.3–2.4

| ID | Data requirement |
|---|---|
| DM-1 | Events interpretable under their original profile. |
| DM-2 | No readable PRIVATE content on the platform. |
| DM-3 | Stored signed events distinguished from rebuildable query projections. |
| DM-4 | Per-class retention and legal hold. |
| DM-5 | No natural-person canonical identifiers. |

Derived queries and insights carry data watermarks for reproducibility. Critical architecture-specific elements are:

| Element | Format / max length | Description; source; need |
|---|---|---|
| `captureRecordId` | UUID v4 / 36 | Submission identity and idempotency; participant; DM-3/S1. |
| `eventTime` | ISO 8601 with offset / 30 | Publisher-asserted business time; publisher; DM-1/S6. |
| `observationWindowStart`, `observationWindowEnd` | ISO 8601 with offset / 30 each | IoT summary observation interval; gateway; SQ-11/S3. |
| `monitoringCoverage` | Decimal(5,2) / 6 | Percentage of the observation interval monitored, 0–100; gateway; SQ-11/S3. |
| `monitoringGaps` | JSON timestamp-pair array / ≤16 KiB | Unmonitored intervals within the observation window; gateway; SQ-11/S3. |
| `epcList`, `quantityList` | EPC URI / class, quantity, UOM; ≤255 per entry | Lot/instance and quantities; publisher; O3/S2. |
| `quantity`, `uom` | Decimal(18,6) / UN-CEFACT; 22 / 3 | Asserted amount and unit; publisher; S2. |
| `profileId`, `profileVersion` | Slug / semver; 64 / 20 | Frozen validation language; governance; DM-1/SQ-8. |
| `signerOrganisationId` | UUID v5 / 36 | Accountable organisation, not a person; registry; DM-5/SQ-2. |
| `keyId`, `publicKey` | UUID / base64-encoded public key; 36 / ≤1024 | Organisation-authorised key and retained verification material; organisation; SQ-2. |
| `admittedAt` | ISO 8601 UTC / 30 | Platform acceptance time and retained membership/key status; distinct from observation time and chain finality; platform; SQ-2/11. |
| `canonicalPayloadDigest` | SHA-256 hex / 64 | Signed canonical content; platform; SQ-1. |
| `receiptDigest` | SHA-256 hex / 64 | Acceptance evidence bound into the Merkle leaf; platform; SQ-1/2. |
| `plaintextCommitment` | Salted SHA-256 hex / 64 | Reference to owner-held evidence; owner; DM-2. |
| `dataWatermark` | uint64 / 20 | Fixed query/projection input version; projection worker; SQ-9/13 and S2–S6. |

The table covers the fields where architecture is decided; EPCIS 2.0/CBV supplies the standard business-event fields, and a retained versioned network profile constrains accepted extensions. Admission enforces typed, length-bounded profile fields. Profiles may add product-specific fields but cannot remove the core traceability floor, so a new product line changes approved validation rather than the shared event semantics.

The IoT profile defines these monitoring extensions and summary statistics; they remain in the existing canonical payload, not separate telemetry tables. Abnormal evidence reuses `ProtectedResourceRef` and `plaintextCommitment`.

`captureRecordId` is a transport idempotency identity, distinct from the EPCIS business event identifier. A correction does not overwrite the signed statement, and structural validity permits conflicting claims, whereas current organisation membership, signing-key status, required fields and idempotency collisions are admission checks. Admission checks membership and key status at platform receipt time; it does not establish the true signing time. Acceptance records retain that status and the original key for later verification. Key compromise may still require external investigation.

| ID | Data scenario and consequence |
|---|---|
| DS-1 | A seven-year recall requires indexed, versioned lineage. |
| DS-2 | Competing transformations require multiple provenance edges and never arbitrary deduplication. |
| DS-3 | A laboratory report is referenced by a commitment; its request and delivery remain outside the platform. |
| DS-4 | 5 000 scans per second requires CDN projections. |
| DS-5 | An expiring batch under legal hold requires an auditable retention transition. |
| DS-6 | An offline event arrives after its key is revoked: reject it and require resubmission with a new submission ID and a currently authorised key. Publisher event time does not prove signing time. |

One managed relational database provides typed EPCIS columns, exact decimals, referential checks, one transaction for event/idempotency/outbox, recursive bounded traversal, row-level scope predicates and point-in-time recovery. A document store weakens cross-event relational enforcement, a graph database should not become the canonical truth, and full-application event sourcing would needlessly event-source profiles and worker state. Private evidence is not stored as platform-readable blobs.

### 2.3 Cloud needs, adoption scenarios and service models — rubric 2.5–2.6

Participants need browser access rather than owned infrastructure; C6 rules out routine cluster patching. QS-4 requires edge rather than origin serving, while DS-3 keeps private documents with their owners. Regulators use scoped portal queries and exports. The resulting choices are:

| Capability | Model / selected responsibility | Rejected alternative |
|---|---|---|
| Application and workers | Managed container PaaS; application/worker roles from one image | Self-managed IaaS cluster and operational platform team. |
| PostgreSQL | Managed relational PaaS, primary and reader, PITR | Self-managed database administration. |
| Public delivery | CDN plus versioned object snapshots | Per-scan origin/API reads. |
| Recovery and encryption | Managed PITR, encrypted backup copies and managed KMS | A dedicated independent custodian and zero-loss account-rebuild protocol. |
| Chain | Paid public network, batched root submission | Consortium validators with no operators. |
| Identity | External IdP; platform organisation/role mapping and organisation key registry | In-house passwords and automated legal-identity verification. |

Australian deployment locations, standards-based PostgreSQL and portable canonical formats support residency and exit planning.

### 2.4 Security, privacy, regulation and device requirements — rubric 2.7–2.8 and 2.B

| ID | Security / privacy requirement |
|---|---|
| SP-1 | Bind every write to an approved organisation and authorised role. |
| SP-2 | Verify organisation signatures and retain admission-time key status. |
| SP-3 | Prevent platform decryption of owner-held evidence. |
| SP-4 | Exclude natural-person fields from immutable history. |
| SP-5 | Audit membership, role and key changes. |
| SP-6 | Audit reads, exports and privileged operations. |
| SP-8 | Record residual threats. |

| CIA | Critical scenarios |
|---|---|
| Confidentiality | QS-7: scoped evidence exports exclude unrelated records and owner-held document contents. |
| Integrity | QS-1/2: public commitments and key history. |
| Availability | QS-3/5: explicitly degraded reads and managed backup recovery. |

Australian Privacy Principles/Privacy Act, NSW privacy obligations, NSW Food Act and Food Standards Code inform minimisation, retention, recall evidence and controlled exports; Appendix B maps each obligation to its answer.

**IoT (2.B).** The delivered IoT adapter runs on participant-managed gateways, collecting readings in real time and showing current observations to authorised logistics users through a local interface while connected. Routine telemetry uses best-effort delivery and short-lived buffering; missing observations indicate monitoring gaps, not normal conditions. At journey completion, an organisation-signed EPCIS event records the summary, monitoring coverage and excursions. Routine raw readings may be deleted after platform acceptance of the final event; abnormal readings and their surrounding evidence window remain owner-held under the applicable retention policy. Reliable delivery and long-term retention of every reading were rejected as disproportionate to bandwidth, storage and rural-connectivity needs. Device provisioning and staff authorisation remain participant responsibilities.

## 3. Architecture views

Four views narrow in sequence: context fixes the boundary, containers show runtime roles, components and code specify responsibilities and contracts.

### 3.1 Context and containers — rubric 3.1–3.4

![Figure 1 — System context](docs/diagrams/preview/c4-context.png)

*Figure 1 — One traceability system, four groups of users and five external systems.*

Traceability Core holds shared canonical claims and supplies scoped investigation, export and insight views to authorised users, including regulators. Supply-chain analytics is built into the Tracker rather than provided by an external system; the Insights module uses worker-maintained projections for scoped product-line and cold-chain visualisations. The delivered IoT adapter runs on participant gateways, provides temporary live views and automatically submits EPCIS summaries and excursion events. Humans authenticate through an external IdP and map to an organisation and role. A designated governance body approves organisations before registration; automated legal-identity verification is outside scope. The public chain provides an independently checkable commitment. Managed storage encryption and backup services are deployment infrastructure; they do not attest business records.

![Figure 2 — Core containers](docs/diagrams/preview/core-container.png)

*Figure 2 — Containers of the platform control domain and the external systems they depend on.*

| Container | Responsibility and key interaction |
|---|---|
| Portal | PWA capture, handover, scoped recall investigation and export, QR/insight views; uses the application or public CDN. |
| IoT Adapter (participant gateway) | Real-time collection, temporary local views/buffering, signed summaries and excursion submission. |
| Traceability Application | Admission, confirmation gate, canonical event store, evidence graph and single read interface. |
| Ingestion/Projection Workers | Retries, lineage/projection rebuild, proof exports and retention. |
| Batch Builder/Relayer | Deterministic leaves, manifests, Merkle batches, chain submission, finality and proofs. |
| Operational PostgreSQL | Signed events, receipts, registries, outbox, manifests/proofs and rebuildable QueryStore. |
| Managed Backup Storage | Encrypted PITR/snapshot copies supporting conventional recovery. |
| Public Snapshot Delivery | Versioned public objects served by a CDN, not origin database joins. |

Admission commits the signed event, acceptance record and anchor intent atomically; workers operate asynchronously. QueryPort reads the scoped materialisation rather than contacting backup storage or chain per query. Only the relayer holds the chain wallet. Regulators use the same scoped read interface; insight projections are derived from canonical events and cannot rewrite their history.

### 3.2 Components and code — rubric 3.5–3.10

![Figure 3 — Traceability Core components](docs/diagrams/preview/core-component.png)

*Figure 3 — Core components with conceptual relationships, logical attributes and responsible components; anchoring entities belong to the separate relayer.*

![Figure 4 — Relayer components](docs/diagrams/preview/relayer-component.png)

*Figure 4 — Components of the relayer, the only container that touches a chain.*

The Core separates Capture API; Idempotency/Outbox Coordinator; Canonicalisation/Profile Validator; Signature/Membership Validator; Submission State Machine; Anchor Confirmation Coordinator; Evidence Graph Builder; Event Store; and QueryPort. The coordinator owns the gate, workers execute intents, and QueryPort exposes `edges()` and bounded `traverse()` but no business-truth verdict. The relayer isolates the single spending credential; deterministic leaves and persisted batch manifests support proof regeneration and export. The Insights module consumes QueryPort and presents scoped product-line and cold-chain summaries from worker-maintained projections.

Figure 3 embeds the conceptual/logical model: acceptance materialises an event and receipt; profiles constrain events; edges are derived; pending events may have no leaf. Bracketed entity labels identify responsible components, while container groups distinguish Core from Relayer. Figure 5 specifies code contracts.

![Figure 5 — Core code view](docs/diagrams/preview/core-code.png)

*Figure 5 — Core evidence contracts, organisation identity records and the scoped query interface.*

![Figure 6 — Physical data model](docs/diagrams/preview/core-physical-model.png)

*Figure 6 — Nine tables; the constraints that matter are named in §4.2.*

`SignatureEnvelope` binds an organisation and key, with no employee identity; mutable organisation, role, key and identity-audit records sit outside canonical business events; `AcceptanceReceipt` records durable platform acceptance, not chain confirmation; `ConfirmationProofBundle` exports signed content, admission evidence and inclusion material; `ProtectedResourceRef` contains a salted commitment and a storage mode rather than private content. `EvidenceEdge`, `EdgeQuery` and `EdgeGroup` carry provenance, scope and watermark.

Conceptually, submissions become canonical events linked to profile versions, evidence references, receipt, leaf and batch. Logically, derived edges and projections belong to query components, not to the signed canonical record. Across views each class has one owning component and container, external dependencies enter through ports, and enumerations are published contracts (Figures 3 and 5). Figure 6 resolves the same event, submission, leaf and batch identities into physical keys and relations — the deliberate bridge between the conceptual, logical and physical models.

## 4. Architectural rationale and decisions

### 4.1 Application structure, tactics, SOLID and design smells — rubric 4.1–4.5

The architecture adopts one modular application deployable, not one unstructured component. Admission has one write gate; all modules share one read entrance; append-only canonical claims feed replayable projections. This simultaneously serves SQ-1/3/4/8/9/10. The important decisions and alternatives are:

| Tactic / pattern | Why it serves a quality | Rejected instead |
|---|---|---|
| Modular monolith, layered inside | One release, bounded responsibilities at pilot scale (SQ-10) | Per-concern microservices, broker, sagas, platform team. |
| Transactional outbox | Signed event, receipt and anchor intent commit together (SQ-3/5) | Distributed two-phase commit or best-effort dual write. |
| CQRS-like derived read model + QueryPort | Indexed lineage and one scope/non-collapsing/watermark policy (SQ-4/7/9) | Per-module SQL filtering; decrypt on each traversal hop. |
| Append-only events + state machine | Corrections remain visible; CONFIRMED requires explicit gates (SQ-1/9) | Mutable event rows or a single `processed` flag. |
| Merkle batch anchoring | One root per 30-minute window with independent verification (SQ-1/10) | Per-event on-chain transactions or a platform timestamp. |
| Ports/adapters and versioned contracts | Storage/chain/identity can change without core rewrite (SQ-8) | Direct SDK dependencies and unversioned values. |

| SOLID | Design justification |
|---|---|
| SRP | Validation, graph construction and gate have distinct reasons to change. |
| OCP/DIP | A new chain adapter extends the port rather than changing the core. |
| LSP | Chain adapters preserve the root-submission and finality contract. |
| ISP | QueryPort’s narrow two-operation interface. |

The design also checks the five smells rather than merely naming them: one graph builder avoids scattered lineage; one read entrance avoids duplicate privacy policy; acyclic admission → outbox → worker direction avoids cycles; narrow components prevent concentration inside one deployable; vendor packages stop at adapters to avoid unstable dependencies. A modular monolith still concentrates deployment risk, accepted for C5/C6.

### 4.2 Data authority, models and analytics — rubric 4.6–4.10

**Signed canonical events in PostgreSQL are the platform record; QueryStore and lineage are derived.** Admission durably commits an event, its acceptance evidence and an outbox intent before returning a receipt. A receipt means accepted for anchoring, not CONFIRMED. Participants retain their signed submissions; scoped exports provide the event, signature, original public key, admission record, profile/canonicalisation versions, batch manifest, inclusion proof and chain reference. The leaf binds the event, signature and receipt digests. These materials support independent verification, not reconstruction of every account or service. PRIVATE documents remain owner-held; PUBLIC is a minimal projection.

| Data role | Placement and lifecycle |
|---|---|
| Signed canonical events and acceptance records | Append-only PostgreSQL records; protected by managed backups. |
| Admission, idempotency, registries, outbox and proof material | Managed PostgreSQL; PITR and encrypted backup copies. |
| QueryStore and derived lineage | PostgreSQL materialisation; rebuildable with replay/versioned derivation. |
| Public view and insight marts | Versioned snapshots/materialised views; rebuildable, watermark-labelled. |

Figure 6 identifies nine physical tables. Five decisive constraints bind the logical model: `capture_record_id` identifies submissions/canonical events; `merkle_leaf.capture_record_id` is unique; canonical events are append-only, with partitioning deferred until volume requires it; nonqueried payload remains separate; organisation predicates enforce the single scoped read path. Conceptual submission → event → profile/receipt/leaf/batch relationships reconcile with Figure 3's store, graph and gate. Corrections add EPCIS error/corrective records rather than altering signed history. Edge derivation is versioned and replayable; conflicting claims coexist instead of being reconciled by hidden business heuristics.

For a transformation, canonical event types carry the claimed input and output identifiers. `Evidence Graph Builder` derives versioned edges but does not impose uniqueness on consumed lots: the same input may appear in multiple competing assertions. A recall query uses a fixed watermark and includes provenance on every traversed edge, so an officer can reproduce the scope rather than silently relying on a later, changed dataset. The event record, edge derivation version and public projection remain separately identifiable during replay.

No warehouse or data lake is warranted at 10,000 events/day: materialised insights meet the initial use cases without duplicating private content or adding another consistency boundary. The projection workers are the only ELT step — canonical events in, versioned marts out — so nothing downstream becomes a second source of truth. Additional geographic regions share the event model and lineage store; entering another legal jurisdiction requires compliance assessment beyond the assumed initial NSW scope. New product profiles extend validation without rewriting the event model.

### 4.3 Cloud-native execution and deployment — rubric 4.11–4.15

![Figure 7 — Logical deployment](docs/diagrams/preview/c4-deployment.png)

*Figure 7 — Logical placement: which control domain owns which node.*

![Figure 8 — Reference deployment](docs/diagrams/preview/c4-reference-deployment.png)

*Figure 8 — A reference configuration that can be procured and built.*

Regional growth increases aggregate ingestion, storage and query demand. Cloud-native tactics are stateless application replicas, workers scaled by outbox lag, indexed lineage queries and independent CDN delivery. Merkle batching avoids one chain transaction per event. Application and worker roles share one image; declarative infrastructure and workload isolation support managed execution. PostgreSQL remains managed, avoiding a self-managed cluster under C6. Database write capacity and batch-processing time remain limits to measure; scale-out follows observed demand.

The platform operates the application, database, managed KMS and backups; the chain remains independently operated, and participants retain their own signed records and exported proofs. There is no required trustee, archive attestor or regulator-operated mirror.

The reference placement uses Sydney ECS Fargate tasks, a managed PostgreSQL writer and reader, PITR, encrypted backup copies in Melbourne, an isolated relayer with its wallet in KMS, S3 snapshot origin and CDN delivery. Ethereum mainnet hosts a non-upgradeable anchoring contract enforcing batch sequencing and prior-root linkage; the relayer waits for consensus finality before confirmation. Active-active writes, self-run validators and a warehouse are not justified at pilot scale.

Planned recovery targets require restore drills, including recovery of signing-key history and batch/proof records. Independent verification is separate from availability: roots cannot recover missing payloads, and participant copies do not guarantee complete service recovery. Separately administered backup copies could reduce account-loss exposure, but their extra operations and cost are deferred; they are not an acceptance or confirmation gate.

### 4.4 Dynamic evidence flows and trust boundaries — rubric 4.16–4.20

![Figure 9 — Dynamic view: event acceptance](docs/diagrams/preview/c4-dynamic.png)

*Figure 9 — One event from submission to confirmed visibility.*

![Figure 10 — Dynamic view: recall investigation](docs/diagrams/preview/c4-dynamic-recall.png)

*Figure 10 — Authorised trace query, verification and scoped evidence export.*

Figure 9:

| Step | Interaction |
|---|---|
| 1 | A participant submits a signed canonical event and idempotency key. |
| 2 | Admission validates profile, active membership and the current key, then atomically stores the event, receipt and anchor intent. |
| 3 | The platform returns the acceptance receipt. |
| 4 | The relayer builds a deterministic batch and persists its manifest, submits the chained root and observes finality. |
| 5 | Confirmation and proof material are recorded and workers update public projections. |
| 6 | The participant can export verification material. |

Chain failure leaves the event PENDING_ANCHOR; backup completion is not a write gate. No timeout promotes an event to CONFIRMED.

| Flow crossing | Classification | Enforced boundary |
|---|---|---|
| Participant → admission | CONSORTIUM canonical data/signature | Identity, acting organisation and profile checks. |
| Database → managed backup storage | Encrypted operational data, registries and proof material | Managed encryption, least-privilege restore access and retention policy. |
| Relayer → public chain | Batch root, sequence and transaction reference | Public commitment; no business payload. |
| Worker → public CDN | Versioned PUBLIC projection | Controlled disclosure/snapshot version. |

Figure 10 authorises the investigator, fixes a watermark and traverses scoped lineage using local query and proof records. Available signatures and inclusion proofs are checked; competing claims, provisional links, missing proof and coverage limits remain explicit. The investigator can export allowed records and verification material, with the export audited and private document contents excluded. Exported proofs support independent checking against public-chain commitments. Formal notices, private-document exchange and physical recall execution remain in existing external processes; degraded results never imply that no affected lot exists.

**STRIDE coverage** follows the actual entry points: participant API/onboarding, portal reads, staff access and scoped evidence exports, backup/KMS/chain access and authorised exports, and internal worker/wallet control.

| Category / threat | Mitigation and boundary | Residual risk |
|---|---|---|
| Spoofing: forged organisation/device | Approved organisation, IdP role mapping and currently authorised signing key | Stolen credentials, compromised organisation keys or erroneous member approval. |
| Tampering: altered/omitted batch | Signed digest, append-only events, chained roots, consistency/inclusion proof | Asynchronous finality and unavailable proofs. |
| Repudiation: denial of a submitted claim | Organisation signature, historical key registry, receipt bound into the anchored leaf | External key custody and disputed real-world facts. |
| Information disclosure: private evidence/out-of-scope query | Owner-held encryption and QueryPort enforcement | Metadata, access patterns and authorised runtime plaintext. |
| Denial of service: flood or chain outage | Quotas, bounded queues, backpressure, retry; local query projections | Sustained saturation or delayed confirmation. |
| Elevation of privilege: operator or wallet compromise | Least-privilege roles, audited member/key changes and privileged operations; isolated outbound relayer | Compromised administrator or KMS/wallet. |

These controls address SP-1–6 and SP-8 within stated trust boundaries. Anchoring proves a commitment, not physical truth. The platform runtime still reads CONSORTIUM plaintext; collusion, access metadata and partner insolvency remain risks. Participant-held signed events and exported proofs can expose changes to committed content, but cannot guarantee data availability or that all real-world events were submitted.

### 4.5 IoT integration and insight views — rubric 4.B, bonus

The Tracker-supplied IoT adapter collects real-time readings, exposes a temporary local view to authorised logistics staff and submits signed summaries and excursions through Capture API. Routine readings need neither anchoring nor strict delivery guarantees. Excursions receive priority submission with bounded retries and explicit acceptance status; unresolved delivery remains visible to participant staff. Observation and platform-receipt times distinguish delayed evidence from current readings. Final EPCIS events use existing admission, idempotency and anchoring; acceptance permits routine raw-data cleanup, while CONFIRMED still requires finality. Summaries include window, unit, min/max/mean, excursion duration and monitoring gaps. Commitments reference retained abnormal-evidence windows, not deleted routine samples. Local alarms and device control remain participant responsibilities.

Insight views use scoped, versioned lineage projections with visible watermarks. The portal provides role-specific capture, handover, investigation and visualisation entry points, with offline capture, readable labels and explicit lifecycle states.

## 5. Evaluation and feasible alternatives

### 5.1 Business-objective assessment — rubric 5.1–5.2

The Brief column names which of the brief's seven key requirements each row answers; privacy and pilot operability follow from the design rather than from the brief.

| Objective | Brief | Verdict and architectural evidence | Unclosed limitation |
|---|---|---|---|
| O1 Rural participation | 2, 7 | Conditional: PWA/offline queue and local identifiers | Some devices cannot sign until connected. |
| O2 Attributable history | 1 | Strong design: signed events, exportable proofs, Merkle finality | False/collusive assertions and governance remain. |
| O3 Recall scope | 5 | Supported: non-collapsing, watermarked indexed lineage | Completeness follows participants' event coverage. |
| O4 Consumer view | 2 | Supported: versioned CDN states and provenance | Cache propagation may lag a newly confirmed event. |
| O5 Evidence/privacy | implied | Supported: owner-held PRIVATE data; scoped consortium read | Metadata and runtime plaintext remain. |
| O6 Pilot operability | implied | Plausible: one deployable, managed services, batch anchoring | Backup restoration and proof export still require validation. |
| O7 Real-time monitoring and IoT evidence | 3 | Conditional: delivered gateway adapter provides live views, signed summaries and abnormal evidence | Connectivity limits live visibility; routine raw samples are not retained for later verification. |
| Product lines and insights | 4, 6 | Supported in design: profiles and materialised views | Front-end visual design remains work. |
| Regional growth | 4 | Supported in design: shared model, replicas, workers, CDN and batch anchoring | Seasonal bursts, database capacity and confirmation lag need load tests. |

### 5.2 ATAM: sensitivities, risks and trade-offs — rubric 5.3

ATAM is chosen over HAZOP because this platform records evidence rather than controlling physical processes. High-importance drivers are independent verification of committed records, non-repudiation across key rotations, recall under chain/proof-service outage, 5 000 public scans per second, offline capture and scoped evidence export.

Sensitivity points are the anchoring window (cost against confirmation delay), backup frequency (recovery-point loss against cost), the query traversal bound (recall completeness against latency) and visibility scope (regulatory authority against commercial confidentiality). Risks are an unavailable chain or missing proof material, a single relayer spending credential, inadequate admission governance, and an untested restore time.

Accepted trade-offs are provisional visibility before finality, metadata leakage instead of hosting private content, and small-team operability over independent scaling of every module. No benchmark or recovery drill has yet proved the targets; the reference deployment is a buildable proposal, not an operational result. Test priority follows from that: historical signature verification and revoked-key rejection, backup restore, exported-proof verification without platform queries, chain outage injection, non-collapsing recall under load, simultaneous regional submission bursts (ingestion latency, outbox lag and confirmation time), and low-end offline capture. A failed test reopens the requirement; it does not license a quietly weaker guarantee.

### 5.3 Alternative architectures — rubric 5.4

| Alternative | Feasibility and reason not selected | When it becomes preferable |
|---|---|---|
| A1 Permissioned BFT consortium ledger | Strong member governance and faster finality, but needs four or more independent validator operators, HSMs and on-call charter absent at launch. | Industry consortium funds sustained shared operations. |
| A2 Layer-2 anchoring | Retains chain-based verification with lower indicative transaction cost; adds sequencer, settlement/finality and longevity dependencies. | Mainnet cost or delay breaches a measured threshold. |
| A3 Microservices/event bus | Independent releases/scaling but adds broker, distributed state/sagas and a platform team at 10,000 events/day. | Workloads/teams acquire independent release or scaling requirements. |
| Conditional non-blockchain fallback: TSA + transparency log | Potentially cheaper with auditor co-signing, but violates the brief's mandatory blockchain constraint. | Only if C1 is formally relaxed. |

---

## Appendix A — Glossary

### A.1 Standards and domain terms

| Term | Meaning |
|---|---|
| GS1 | The standards body behind EPC product identifiers and the EPCIS event format. |
| EPC / [EPCIS 2.0](https://www.gs1.org/standards/epcis) / CBV | Electronic Product Code / Electronic Product Code Information Services / Core Business Vocabulary: identifiers, event exchange and shared business terms. |
| Product lot/batch / anchoring batch | A quantity of agricultural product / a group of event commitments sharing one Merkle root (`AnchorBatch`). |
| Aggregation / transformation / handover | Packing objects together / converting inputs into outputs / transferring custody. |
| Cold chain / excursion | Temperature-controlled logistics / a detected departure from a profile-defined acceptable range. |
| Provenance / lineage | Attribution and source history / derived relationships connecting products and events. |
| Observation window / coverage / gap | Monitored time interval / percentage actually monitored / an interval without observations. |
| UN/CEFACT / UOM | United Nations Centre for Trade Facilitation and Electronic Business / unit of measure; the unit-code vocabulary used for quantities. |

### A.2 System terms

| Term | Meaning |
|---|---|
| Attributable claim / canonicalisation / profile | Organisation-signed event / deterministic event representation for hashing / versioned validation and disclosure rules. |
| Acceptance receipt / confirmation gate | Evidence of durable admission / durable storage plus finality of the leaf's public-chain commitment. |
| Merkle leaf / root / inclusion proof | One event commitment / the batch commitment / evidence that a leaf belongs to that batch. |
| Finality / relayer / manifest | Chain consensus acceptance / root-submission worker / ordered batch contents used to regenerate proofs. |
| Confirmation proof bundle | Event, signature, key/admission evidence, versions, manifest and Merkle/chain verification material. |
| PUBLIC / CONSORTIUM / PRIVATE | Minimal public projection / scoped inter-organisation records / owner-held private evidence. |
| SUBMITTED / VALIDATED / PENDING_ANCHOR | Submission received / admission checks passed / durably accepted, awaiting anchoring or finality. |
| FINALISED / CONFIRMED / REJECTED | Chain finality observed / confirmation gate satisfied / admission refused. |
| PENDING / NO RECORD | Public pending-confirmation label / no record available within the query scope; neither denotes a service outage. |
| Watermark / non-collapsing | Fixed query-input version / preserving conflicting claims with their provenance. |
| QueryPort / QueryStore / projection | Scoped read interface / rebuildable query copy / derived representation of canonical events. |
| Commitment / ProtectedResourceRef | Content-binding digest / owner and availability reference to private evidence, without its plaintext. |
| Modular monolith / ports and adapters | One application deployable with internal modules / interfaces isolating external implementations. |
| Idempotency / transactional outbox / replay | Safe duplicate processing / atomic data-and-work-intent commit / rebuilding derived state from retained events. |
| Legal hold / PITR | Suspension of scheduled deletion / point-in-time recovery to a retained database state. |

### A.3 Notation and symbols

| Notation | Meaning |
|---|---|
| C4; person / system / external system | Context, Containers, Components, Code; user / system under design / external dependency. |
| Boundary / container / component / cylinder / deployment node | Scope or ownership / runtime application or store / internal responsibility / data store / execution infrastructure. Colours follow each diagram's legend. |
| C4 arrows | Directed relationships; labels state the interaction, data and protocol where relevant. |
| Dynamic diagrams: solid / dashed arrows; phases | Request or action / response or observation; phases and top-to-bottom order show sequence, not synchronous/asynchronous delivery guarantees. |
| Code diagram: solid / dashed arrows; multiplicity | Association / dependency; `1`, `0..*` mean one, zero or more. Packages group responsibilities; enums list allowed values. |
| Physical model: `PK`, `FK`, `UNIQUE`; crow's foot | Primary key, foreign key, uniqueness; bars mean one, circle means optional, crow's foot means many; `*` marks required attributes. |
| O / S / C / R; SQ / QS; DM / DS / SP; A | Objective / stakeholder / constraint / risk; system quality / quality scenario; data requirement / data scenario / security-privacy requirement; alternative. Numeric suffixes are identifiers. |
| `L`, `W`, `tx`; `≤`, `%`, `[]` | Investigated lot, fixed watermark, transaction; upper bound, percentage, array. |
| `uuid`, `text`, `jsonb`, `timestamptz`, `char(n)` | Database UUID, text, binary JSON, timestamp with time zone, fixed-length text. |
| `Decimal(p,s)`, `smallint`, `bigint`, `uint64`; hex / base64 / semver / KiB | Decimal precision/scale, small/large integer, unsigned 64-bit integer; base-16/base-64 encodings, semantic version, 1,024 bytes. |

### A.4 Acronyms

| Group | Expansions |
|---|---|
| Business systems | ERP: enterprise resource planning; WMS: warehouse management system; TMS: transport management system; BI: business intelligence; IoT: Internet of Things. |
| Interfaces | API: application programming interface; REST: representational state transfer; RPC: remote procedure call; SDK: software development kit; IdP: identity provider; OIDC: OpenID Connect. |
| Formats and protocols | JSON: JavaScript Object Notation; URI: Uniform Resource Identifier; UUID: universally unique identifier; UTC: Coordinated Universal Time; ISO: International Organization for Standardization; HTTPS: Hypertext Transfer Protocol Secure; TLS: Transport Layer Security; SQL: Structured Query Language. |
| Cloud and delivery | IaaS/PaaS/XaaS: infrastructure/platform/anything as a service; AWS: Amazon Web Services; ECS: Elastic Container Service; S3: Simple Storage Service; RDS: Relational Database Service; AZ: availability zone; PoP: point of presence; CDN: content delivery network; PWA: progressive web application; QR: Quick Response. |
| Data architecture | CQRS: command-query responsibility segregation; ELT: extract, load, transform; ETL: extract, transform, load; DB: database; ID: identifier. |
| Security and recovery | CIA: confidentiality, integrity, availability; KMS: key management service; IAM: identity and access management; HSM: hardware security module; SHA-256: Secure Hash Algorithm, 256-bit; BFT: Byzantine fault tolerance; TSA: timestamping authority; RPO/RTO: recovery point/time objective. |
| Assessment and jurisdiction | ATAM: Architecture Tradeoff Analysis Method; HAZOP: hazard and operability study; NFR: non-functional requirement; ML: machine learning; NSW: New South Wales; APPs: Australian Privacy Principles. |
| SOLID | SRP: single responsibility; OCP: open–closed; LSP: Liskov substitution; ISP: interface segregation; DIP: dependency inversion (principles). |
| STRIDE | Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege. |

## Appendix B — Regulatory considerations and architectural support

| Consideration | Architectural support |
|---|---|
| NSW Food Act / Food Standards Code | Conservative recall tracing, attributable event history and controlled evidence exports. |
| Privacy Act 1988 and the APPs; NSW privacy law | Minimises immutable identity, scopes reads, keeps evidence owner-held and retains a mutable correction path. |
| Records retention and legal hold | Class-based rules, logged transitions, controlled deletion and auditable retention evidence. |

This mapping identifies architectural support; it is not a comprehensive compliance assessment.
