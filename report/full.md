# 0. How it works — read this page first

The system is a shared, attributable record of what happened to a product as it moves between organisations. It
does not replace anyone's ERP; it records claims and makes them checkable.

**Writing a claim** (Figures 4 and 12). A participant signs an EPCIS event and submits it with a
client-generated identifier. The platform validates the profile and the signature, then persists the event and
enqueues an archive intent in one transaction. Workers encrypt the payload under a fresh data key, wrapped by a
consortium key held outside the platform, write the ciphertext to an archive in another control domain, and
record the holder's signature over the stored bytes. That acknowledgement is what allows a receipt to be issued.
Every thirty minutes the relayer commits a Merkle root over the receipted events to a public chain. An event
becomes `CONFIRMED` only when both have happened: an outside holder has signed for the bytes, and the root is
final.

**Reading a claim** (Figure 2). Every read goes through one entrance, `QueryPort`, which enforces scope,
non-collapsing and watermark. Lineage is derived once into an indexed table, so a recall traversal is a bounded
recursive query rather than a walk through the archive. Consumers never reach the application: they read
versioned snapshots from a CDN, which is why a media-driven burst costs the origin almost nothing.

**Who owns what.** Four accounts: the platform, the trustee (archive and keys), the regulator's analytics
workspace, and the regulator's evidence mirror. The operator can read consortium plaintext — an authorised
capability, not an accident — but it cannot read private evidence, forge a holder's signature, or rewrite a
confirmed batch without detection.

**What it deliberately does not do.** Decide whether a claim is true, execute recalls, or hold raw telemetry.

**The claim the rest of this report defends.** No single party — not the operator, not the archive, not a regulator —
can silently rewrite confirmed history. Sections 1–4 establish it; Section 5 tests it and names where it falls short.

# 1. Project context

An agricultural product moves through independent businesses, each keeping its own record of what it received, did
and passed on. Nothing joins those records: a regulator reconstructing a recall asks each business in turn and gets a
different identifier scheme, time zone and idea of "batch", so the answer arrives in weeks while the product is on
shelves. What is missing is a shared, attributable record a small producer can join cheaply and a regulator can trust
without trusting its host.

## 1.1 Who it serves, what it covers, and why that changes the design — rubric 1.1–1.3

**Objectives.** Publish a claim cheaply, including offline (O1); make confirmed history tamper-evident to parties who
distrust the operator (O2); let a regulator scope an incident quickly and defensibly (O3); give consumers a truthful
view (O4); keep commercial detail and private evidence off the record (O5); run on a small team (O6); take device
evidence without becoming a device platform (O7); screen regulatory risk with ML optional (O8).

**Counterparties.** Six parties exchange claims through the system; each constrains it.

| ID | Party | What they need |
|---|---|---|
| S1 | Producer, grower, packer | Low-cost offline capture; signing without a corporate PKI |
| S2 | Processor | Transformation claims with quantities; no imposed mass-balance verdict |
| S3 | Distributor, cold chain | Two-sided handover; summaries, not raw telemetry |
| S4 | Retailer | Fast, conservative recall scope; a cacheable public view |
| S5 | Consumer | QR entry; "confirmed", "pending" and "no record" kept distinct |
| S6 | Regulator officer | Read access, case-scoped evidence, signed findings, audit trail |

The rest are parties to the design, not users of it: analytics (S7), governance (S8), the operator (S9), archive and
key trustees (S10), courts and auditors (S11), device vendors (S12) — each surfacing once, where its interest bites
(§2.3, §4.5).

**Scope.** Six boundaries are easy to confuse, and each is deliberate.

| Mistaken for | It is instead |
|---|---|
| An ERP, WMS or quality system | A record of claims; participants keep their own systems |
| An adjudicator | It stores competing claims side by side and never picks one |
| A recall executor | It establishes scope and evidence; the businesses execute the recall |
| A device platform | Devices are organisation delegations publishing summaries |
| A payment or settlement system | No money moves; pricing and settlement are out of scope |
| A certification or customs system | Certificates enter as private evidence; a border adds a legal regime |

Consumers as data producers, recycling operators and marketing or BI are outside for the same reason: each would
change the system's category, or it is met inside the Insights module.

**Failure modes.** Five shape the architecture: no consortium exists to operate validators, so a permissioned ledger
cannot be built (R1, R3); the operator becomes the single point of trust unless history verifies from outside it
(R2); evidence may not survive a legal process (R3); an immutable log may breach privacy law (R5); scope creeps into
ERP, inventory or adjudication (R6). Two are stated, not solved: smallholders left out (R4) and false or collusive
claims (R10). Not attempted: state-level adversaries, build-pipeline and quantum attacks (a security programme, not
an architecture decision), bankruptcy, and fraudulent onboarding (a named residual risk).

**Constraints.** A blockchain is mandatory (C1); Australian and NSW law applies (C2); participants' systems must
interoperate (C3); connectivity is intermittent (C4); 200 organisations and 10 000 events/day (C5); a small operating
team (C6); no production access (C7). Delivery follows: one region, cloud only, PWA only, no contracted archive
operator at launch.

**Why these change the design.** The stakeholders fall into three clusters; device vendors (S12) are argued in §4.6.

**Participants (S1–S5) with C4 force an integration tier.** With only large manufacturers, an ERP integration and a
corporate key would do; because the smallest tier must publish, capture is browser-first, the queue survives offline,
the key never leaves the device and identifiers are client-generated.

**The regulator (S6, S7) forces a boundary that would otherwise be invisible.** Analytics inside the platform's
account would let the operator read every rule and finding.

**Trust infrastructure (S8–S11) takes the record out of the operator's hands.** Cost is served, unilateral control is
not: hence the external archive, the non-platform key holder and verification with no cooperation.

**R1 and R3** eliminate the permissioned ledger, which fits the evidence requirement but needs validators this project
lacks. **C1 and C2** are in tension — a public chain is mandatory, personal data must stay correctable — and the
resolution follows: commitments on chain, ciphertext off it, personal data in the mutable layer.

# 2. Requirements analysis

The three gaps of Section 1 become obligations here: what must be checkable, what must stay unreadable, and what
must survive loss.

*Identifiers trace to the stakeholders `S1`–`S12` and objectives `O1`–`O8` in Section 1.*

## 2.1 System qualities, and the scenarios that test them — rubric 2.1–2.2

Thirteen qualities drive the design. Four decide its shape — integrity (S6, S9, S11), privacy (S1, S5, S6),
availability (S4–S6) and analysability (S1–S4, S6); the other nine constrain how it is built. Each row states the
requirement as a measurable test, the scenario that exercises it, and the risk if it is not met.

| ID | Quality | Requirement and measure | Scenario | Risk if unaddressed |
|---|---|---|---|---|
| SQ-1 | Integrity | A confirmed event cannot be altered or removed undetectably; detectable from published proofs alone | QS-1: an operator deletes a batch, and the missing batch breaks the chain sequence | History is only as trustworthy as its host |
| SQ-2 | Non-repudiation | Attribution survives rotation, revocation and suspension; verifiable from event and registry history alone | QS-2: a three-year-old event is verified after two key rotations and a suspension | Old claims become unattributable after a key compromise |
| SQ-3 | Availability | One dependency lost degrades a capability, never to a false "no record"; fault injection yields a declared state | QS-3: a recall runs at 02:00 during an archive outage | A safety query answers "nothing found" exactly when it matters |
| SQ-4 | Performance | 5 000 requests/s at the CDN; 10 000 synchronous edges, exported beyond | QS-4: 5 000 scans/s arrive after a television item | The origin melts during the one incident everyone watches |
| SQ-5 | Recoverability | RPO 0 for receipted events; database ≤ 5 min; RTO ≤ 4 h; regional rebuild ≤ 24 h | QS-5: the platform account is lost after a receipt | Confirmed history dies with the platform |
| SQ-6 | Usability and accessibility | Under three minutes at 2G; WCAG 2.2 AA; 200 % text; label plus icon per field | QS-6: a grower with no signal for 36 hours captures four events on a low-end phone | Coverage collapses in exactly the tiers the regulator needs |
| SQ-7 | Privacy | No natural-person reference and no private content in the shared record | QS-7: a regulator requests a packer's lab report; QS-8: operations try to read findings | An immutable log becomes an unlawful personal-data store |
| SQ-8 | Interoperability | Interpretable from profile and canonicalisation version alone; replaceable chain | QS-10: the chosen chain becomes uneconomic | Every participant needs a lossy mapping, and migration becomes a rewrite |
| SQ-9 | Auditability | Every state change and disclosure attributable; replay reproduces derivation and advisories | QS-9: two processors claim one input lot | Conflicts cannot be defended or replayed |
| SQ-10 | Cost and operability | One application, one managed database, no self-managed cluster; topology and monthly estimate documented | Checked by inspection of the deployment views (§4.3) | The pilot needs a platform team per region |
| SQ-11 | Device evidence | Profile-required summaries with provenance; raw telemetry stays private | QS-12: a reefer exceeds its limit for 40 minutes | Raw telemetry enters the record, or evidence is missing where it matters |
| SQ-12 | Regulatory screening | Signed, versioned rules; ML optional; a rule runs at a watermark and traces to its version | QS-11: a case is opened while the workspace is under maintenance | Screening is either platform-owned or absent |
| SQ-13 | Analysability | Every insight view states its watermark and scope; figures reproduce from the projection | QS-13: a product line is reviewed at yesterday's watermark | Insight becomes a second, disagreeing read path |

Rejected while setting these requirements: database plus WORM backup (the operator stays sole verifier); a
permissioned ledger (no validators, R1); per-employee signing keys (natural persons in an immutable record, R5);
synchronous calls to every dependency on the read path; a graph database from day one; field-level encryption in the
shared record (the platform would still hold the keys); a separate dashboard database. Each risk is argued in §4.1;
surviving alternatives are revisited in §5.1.

## 2.2 The data: elements, scenarios, storage — rubric 2.3–2.4

Six requirements shape the data model: interpretable from its profile (DM-1); no readable private content on the
platform (DM-2); one authoritative source with rebuildable copies (DM-3); retention per class with a defensible
deletion record (DM-4); no natural-person identifiers (DM-5); reproducible regulatory outputs (DM-6). The
scenarios below then fix validation, storage, access and retention, so each is stated where it arises rather
than listed separately.

**Elements.** One or two per group are tabulated; the rest are named after the table and follow the same rules.
Format and length are enforced at admission, and source names the originating party.

| Element | Format | Length | Description | Source | Serves |
|---|---|---|---|---|---|
| `captureRecordId` | UUID v4 | 36 | Idempotency key for one submission | Participant | DM-3, S1 |
| `eventTime` | ISO 8601 with offset | 30 | Business time asserted by the publisher | Publisher | DM-1, SQ-9 |
| `epcList`, `quantityList` | EPC URIs / {class, quantity, uom} | ≤ 255 per entry | Instance and lot identifiers with quantities | Publisher | DM-1, O3 |
| `quantity`, `uom` | Decimal 18,6 / UN/CEFACT | 22 / 3 | Asserted quantity and unit | Publisher | S2 |
| `profileId`, `profileVersion` | Slug / semver | 64 / 20 | Validation profile and version | Governance | DM-1, SQ-8 |
| `signerOrganisationId` | UUID v5 | 36 | Organisation accountable for the claim | Registry | SQ-2, DM-5 |
| `canonicalPayloadDigest` | SHA-256 hex | 64 | The value actually signed | Platform | SQ-1 |
| `plaintextCommitment` | SHA-256 hex | 64 | Salted commitment to off-platform content | Owner | DM-2, SQ-7 |
| `findingId`, `ruleVersion`, `dataWatermark` | UUID, semver, uint64 | 36, 20, 20 | Finding identity and the inputs it used | Regulator | DM-6, SQ-9 |

Named but not tabulated: the EPCIS business fields (`action`, `bizStep`, `disposition`, locations, source and
destination lists, transaction lists, `parentID`, `transformationID`); the versioning pair; the four signature
fields; `custodyMode`; the seven anchoring fields; evidence state; and regulatory output. Each is EPCIS/CBV-defined
or profile-declared, typed and length-bounded at admission.

**Scenarios.**

- **DS-1 Seven-year recall.** A retail lot is traced to a farm block seven years later. *Forces:* append-only
  canonical tables, indexed lineage edges, and the profile version kept with the event (storage).
- **DS-2 Competing claims.** Two processors consume one lot. *Forces:* no uniqueness on lineage, and a query
  layer that returns both rather than picking one (representability, not validation).
- **DS-3 Laboratory report.** A regulator requests a packer's report. *Forces:* only a commitment and a storage
  mode on the platform, with content encrypted by its owner (access).
- **DS-4 Scan at peak.** 5 000 scans/s after a television item. *Forces:* public reads served from versioned
  objects at the edge, never by joining canonical tables (access, storage).
- **DS-5 Retention under hold.** A batch expires during a dispute. *Forces:* deletion as a recorded transition
  executed by three parties, with a signed record anchored (retention).
- **DS-6 Offline capture, revoked key.** Events arrive after a key rotation. *Forces:* idempotent ingestion and a
  review state, because "invalid" and "not yet established" are different facts (ingestion, validation).

DS-3 and DS-4 fix the three visibility classes — public projection, consortium trace, owner-held evidence, no middle
tier — with access bound per request to an acting organisation. DS-6 fixes validation: admission blocks the write,
while representability only shapes the projection. Business plausibility stays out of admission: rejecting an event
for an odd quantity would make the platform an adjudicator.

**Storage.** One managed relational database holds submission state, registries, the outbox, a queryable
materialisation and rebuildable projections. It is relational because EPCIS fields are typed and constrained,
admission needs one atomic step across event, idempotency claim and outbox, DS-1's traversal is a bounded
recursive query, and reporting is set-oriented; it must therefore provide exact decimal arithmetic, referential
integrity, semi-structured extension columns, point-in-time recovery and row-level predicates. Rejected: a
document store (loses cross-event constraints and multi-row transactions), a graph database as the record (the
graph is derived and must stay verifiable), and event sourcing for the whole application (profiles and job
state are not events).

## 2.3 Cloud adoption — rubric 2.5–2.6

Participants want no infrastructure and no capital spend: a browser is enough, and a small producer will not run a
server to join a supply chain. The operator wants the same — a small team (C6) cannot patch a cluster. The regulator wants its workspace to run where the platform cannot read it.

Four scenarios decide the model. QS-4 asks who serves the bytes — an origin cannot, so delivery is a CDN service.
DS-3 asks who holds the content — not the platform, so object storage sits under a separate provider. QS-8 asks who
operates the workspace; C6, how much is operated at all.

| Capability | Deciding scenario | Service model | What we do not run |
|---|---|---|---|
| Application and workers | C6 | PaaS, one managed container | Orchestrator, node patching |
| Relational database | C6 | PaaS, replica and storage autoscaling | Failover, backups, tuning |
| Public snapshot delivery | QS-4 | SaaS, CDN over object storage | Edge PoPs, certificates |
| Archive | DS-3 | SaaS, object storage under a separate provider | Media, replication |
| Key management | DS-3 | SaaS, managed KMS in the trustee's account | HSM estate, key ceremonies |
| Chain anchoring | QS-4 | Public network, paid per transaction | Validators, nodes |
| Analytics runtime | QS-8 | PaaS, in the regulator's account | Platform operational access |
| Identity | C6 | SaaS, external identity provider | Credential store, MFA estate |

Rejected: **IaaS with a self-managed cluster** — C6 makes it a second job; **a shared tenant for analytics** — QS-7
makes the separation unverifiable; **on-premises object storage** — it returns the archive to the operator's account
(D1); **origin-only delivery** — QS-4 makes the origin the bottleneck.

Residency, exit and cost follow from the same choices: Australian regions, standard PostgreSQL, portable formats.

## 2.4 Security, privacy and regulation — rubric 2.7–2.8

Every write is authorised against an organisation, a role and a delegation, bound per request (SP-1), and every
canonical event is non-repudiable across rotation and revocation (SP-2). High-impact governance changes need dual
control and apply only once anchored (SP-5); reads are audited per organisation and staff access needs recorded
break-glass (SP-6); analytics cannot pull arbitrary private evidence, and findings are private by default (SP-7).
The system states what it does not protect against (SP-8).

**Integrity is guaranteed by the public chain.** A Merkle root is committed every thirty minutes, and any third
party can verify an event against it without asking the platform (NSW Food Act 2003; Food Standards Code).

**Confidentiality is a three-tier tradeoff.** Public projection, consortium trace, owner-held private evidence, with
no middle tier. The platform reads consortium plaintext because recall traversal needs it, and never reads private
content (SP-3), while no natural-person identifier enters the immutable record (SP-4). Privacy Act 1988 and the APPs;
NSW PPIP Act 1998.

**Availability comes from read/write separation.** Writes fail closed and retry idempotently; reads come from the
materialised copy with an explicit degradation state, so a recall query during an archive or chain outage returns a
labelled partial result rather than a silent miss (Food Act 2003 recall powers).

Appendix B maps each obligation behind those citations to where the design answers it.

## 2.5 Device evidence and regulatory screening — rubric 2.B, bonus

**IoT-1 summaries, not telemetry; IoT-2 devices as organisation delegations, not accounts; IoT-3 collection at the
edge, availability at the platform, verifiability at the archive.** The cold-chain loop is local, so the platform's
alarm is post-confirmation.

**AI-1 deterministic rules first, versioned and signed by the regulator, with ML optional and never gating a write;
AI-2 every finding names its rule or model version and its input watermark; AI-3 no model output becomes a recall
decision without a signed assessment.**

**IS-1 Cold-chain excursion.** The participant's system alarms and acts; a summary and reference ride on the receiving
claim; the platform is not the alarm path. **IS-2 Cross-assertion anomaly.** The regulator's rules produce a private
finding over confirmed claims; the platform supplies minimised data and cannot read the rule.

| Alternative | Why rejected |
|---|---|
| Raw telemetry on the platform | Turns the trace into a time-series warehouse; privacy exposure; unmanageable retention |
| Platform-side real-time alerting | Adds a hard latency requirement and duplicates the participant's control loop |
| ML in the write path | Makes a model an adjudicator; training data belongs in the regulator's domain |

# 3. Architecture views

Each view answers one question and narrows the previous one: the context fixes the boundary, the container view
opens it, the component views open the two containers that carry the guarantees, and the code views show the
types that make those guarantees enforceable. Section 4 explains why; this section states what the structure is.

## 3.1 The view set — the roadmap for rubric 3.1–3.10

Four views, each narrowing the last: context (Figure 1), containers (Figures 2–3), components (4–6) and code (7–8).
Names are stable across views; relationships carry intent, and transport strings appear only where the protocol is
architecturally relevant. Diagrams are generated from versioned source, so report and repository cannot drift.

## 3.2 System context — rubric 3.1

![Figure 1 — System context](../docs/diagrams/preview/c4-context.png)

*Figure 1 — Two peer subsystems, four groups of users, eight external systems.*

**One boundary, two peer subsystems.** `Traceability Core` holds the shared record; `Regulatory Analytics` holds
the regulator's rule domain. They are peers: the platform cannot author rules, and analytics cannot rewrite the
trace. The archive, the consortium KMS, the chain and the regulator's case systems sit outside, because their
value comes from not being in the operator's account.

**Devices attach to participants, not to the platform.** Sensors feed the participant's own systems, which publish
EPCIS events. A device is a delegation of an organisation — allowed devices, locations and event types — not a
platform user. What enters the record is a profile-declared summary; raw readings stay with the participant behind a
reference and a salted commitment. Collection and alarming are local, availability is the platform's, verifiability
the archive's (IoT-1…3, 4.B).

**Identity arrives on two lines.** Humans authenticate through an external identity provider; an organisation's
legal identity is verified once against a business registry. Neither is issued by the platform — the organisation,
not the person, is the unit of accountability.

## 3.3 Containers — rubric 3.2–3.4

![Figure 2 — Container view](../docs/diagrams/preview/core-container.png)

*Figure 2 — Containers of the platform control domain, and the external systems they depend on.*

| Container | Responsibility |
|---|---|
| Participant & Regulator Portal | Role-specific capture, handover confirmation, recall execution, scan-to-trace, insight views, evidence requests |
| Traceability Application | Admission, the confirmation gate, evidence graph, the single read entrance |
| Ingestion & Projection Workers | Archive writes, projection rebuild, exports, retention, advisory intake |
| Batch Builder & Relayer | Leaf allocation, Merkle batching, root submission, inclusion proofs |
| Operational PostgreSQL | Submission state, registries, outbox, the plaintext query copy, projections |
| Public Snapshot Delivery | Versioned public snapshots at the edge |
| Analytics Workspace | Regulator's rules, screening, private findings, signed advisories |

Two boundaries are easy to misread. **The database holds a plaintext copy of confirmed events** (`QueryStore`),
not only indexes: online lineage cannot afford to decrypt on every hop. That copy is rebuildable, excluded from
the recovery guarantee and read-audited. **The Analytics Workspace sits inside the system boundary but outside
the platform control domain**, in the regulator's own account; only signed messages cross into it.

Four flows cross the boundary. *Capture*: a signed event reaches the application, which validates it and persists
state with an archive intent in one transaction; workers obtain a wrapped key, write the envelope and record the
acknowledgement; the relayer batches the leaf. *Read*: portal queries go through the query interface and the
plaintext copy only. *Public delivery*: workers publish versioned snapshots and the CDN serves them, so consumers
never reach the application. *Cross-tenant*: the application exports a minimised dataset and receives signed
advisories and rule manifests.

![Figure 3 — Analytics containers](../docs/diagrams/preview/analytics-container.png)

*Figure 3 — The workspace, its rule registry and its finding store.*

The separation is the point of this view: the platform can deploy artefacts into the regulator's account but
cannot read from or operate it, so "the platform cannot see the rules or the findings" is an IAM fact rather
than a promise. That contract — what dataset may leave, what may return — is why the subsystem is modelled to
component and code level instead of being drawn as a black box.

## 3.4 Components — rubric 3.5–3.7

![Figure 4 — Traceability Core](../docs/diagrams/preview/core-component.png)

*Figure 4 — Components of Traceability Core, with the modules that consume its read interface.*

The core has one write path and one read entrance. Nine components: `Capture API`, `Idempotency & Outbox
Coordinator`, `Canonicalisation & Profile Validator`, `Signature & Authority Validator`, `Submission State
Machine`, `Archive & Anchor Orchestrator`, `Evidence Graph Builder`, `Confirmed Event Store` and `QueryPort`.
Three properties carry the argument: the orchestrator owns the confirmation gate and records the archive intent,
while the worker role of the same image executes it; `QueryPort` exposes two graph-shaped operations, `edges()`
and a bounded `traverse()`, and nothing that returns a business status; the store is append-only, so a correction
is a new event.

![Figure 5 — Relayer components](../docs/diagrams/preview/relayer-component.png)

*Figure 5 — Components of the relayer, the only container that touches a chain.*

The relayer is drawn separately because it is the only container with a credential that can spend money. Six of its
seven components need no private key; only `Chain Submitter` does. Leaf allocation is deterministic, so a retry
cannot create a second leaf, and the manifest writer places the batch manifest beside the payload, which is what lets
recovery reconstruct which batch held an event without the platform database.

![Figure 6 — Analytics Workspace components](../docs/diagrams/preview/analytics-component.png)

*Figure 6 — Four components, inside the regulator's account.*

`Dataset Intake` is the only entrance; `Rule Loader & Validator` verifies the regulator's signature and the
rule's applicability, not its content; `Screening Runner` runs deterministic rules over one snapshot at one
watermark; `Advisory Publisher` applies the disclosure policy and signs. There is no model loader and no review
queue in the first release, because it runs deterministic rules only.

## 3.5 Code — rubric 3.8–3.9

![Figure 7 — Core code view](../docs/diagrams/preview/core-code.png)

*Figure 7 — Thirteen classes, one interface, three enumerations.*

Four properties are visible in the type model. `SignatureEnvelope` has no natural-person field, so attribution
cannot acquire an employee reference. `AcceptanceReceipt` binds the `ArchiveAck` digest, so a receipt can only exist
once an outside holder has confirmed persistence. `QueryPort` returns edge groups, never a business status, so no
caller bypasses scope, non-collapsing or watermark. `ProtectedResourceRef` holds a salted commitment and a storage
mode, never content. The three enumerations are published values: once in use, a value cannot be silently changed.

![Figure 8 — Analytics code view](../docs/diagrams/preview/analytics-code.png)

*Figure 8 — Eight classes.* `RuleVersionManifest` is the only artefact of the rule domain that leaves the
regulator's account, and it carries only a digest of the rule body. `Finding` and `AdvisoryFinding` share a
`findingId`, so an advisory is a disclosure of an existing finding and a retraction is the same identifier
re-signed; `DisclosurePolicy` constrains advisories, not findings.

## 3.6 Cross-view consistency — rubric 3.10

Every class is produced by one component and belongs to one container of Figure 2; Appendix A.2 is the full
mapping. Consistency is maintained by four rules rather than by review: one name per element across views, one
owning component per class, one interface per trust boundary, and enumerations treated as published contracts
rather than implementation detail.

# 4. Architectural rationale and decision-making

Section 3 says what the structure is. This section records the decisions behind it: one sentence each, the
reason, and — only where a plausible alternative existed — what was rejected instead.

## 4.1 How the application is cut — rubric 4.1–4.5

1. **One deployable, split by role rather than by service.** A service per concern would add a broker, sagas and
   an operational platform to serve 10 000 events/day.
2. **One write path, with an outbox.** State, idempotency claim and archive intent commit together, so a crash
   resumes instead of duplicating; the alternative is two-phase commit across services.
3. **One read entrance.** Modules read only through `QueryPort`, so scope, non-collapsing and watermark cannot be
   bypassed by a caller that reads tables directly.
4. **Append-only canonical records, everything else derived.** Lineage, recall and public views rebuild from the
   log, which is what makes the record verifiable and replayable.
5. **Notarised anchoring.** A public Merkle root every thirty minutes proves existence to anyone; it does not
   prove truth, and it is why a permissioned ledger was unnecessary.
6. **A port at every external edge.** Archive, KMS, chain and identity change through adapters, and the leaf binds
   digests rather than chain specifics — a direct SDK call would have locked both in.
7. **Signature and authority are separate checks.** A verifier checks the signature; a resolver decides whether
   that organisation was authorised *then*, so rotation never invalidates history.
8. **The signer is isolated.** Only the relayer holds the chain wallet, and it cannot read payloads; embedding the
   wallet in the application would enlarge the key-exposure surface.

Those decisions are tactics. The quality each serves (rubric 4.1) and the pattern it forms (rubric 4.2–4.3) are named
here, with the alternative the pattern replaced.

| Pattern | Where it appears | Quality served | Rejected instead |
|---|---|---|---|
| Modular monolith, layered inside | The one deployable | Operability (SQ-10), modifiability | Services (§5.1, A4) |
| Ports and adapters at every external edge | Archive, KMS, chain, identity | Replaceability (SQ-8) | A direct SDK call |
| Transactional outbox | Admission through to archive | Reliability, RPO 0 (SQ-5) | Two-phase commit |
| Read model derived from the log | `QueryStore`, public snapshots | Performance (SQ-4), privacy (SQ-7) | Per-hop decrypt |
| State machine with anchored transitions | `ConfirmationStatus` | Integrity (SQ-1), auditability (SQ-9) | A boolean flag |
| Versioned contracts, published enumerations | Profiles, code view | Interoperability (SQ-8) | Free-form strings |

Five named smells, checked one by one (rubric 4.5).

| Smell | Where it would appear | Evidence it does not |
|---|---|---|
| Feature concentration | One application holding admission, the gate, the graph and reads | Nine components split by reason to change: `Capture API` validates, the orchestrator gates, `QueryPort` reads |
| Scattered functionality | Lineage or scope rules computed per module | One `Evidence Graph Builder`; every read passes `QueryPort` |
| Dense structure | The core component graph | Acyclic; `QueryPort` is the only fan-in and the orchestrator the only gate |
| Cyclic dependency | Application and workers | One direction — admission enqueues, workers execute, no callback |
| Unstable dependency | Chain, archive and KMS SDKs | All behind ports; the core imports no vendor package |

SOLID is visible where it matters (rubric 4.4): responsibilities split by reason to change, a new custody mode arrives as
an addition, four modes share one envelope, the read interface has two operations, and dependencies point at
interfaces.

## 4.2 What is authoritative, what is rebuildable — rubric 4.6–4.10

**D1. The archive is the copy of record; the database is not.** No single party, including the operator, may be
able to destroy confirmed history, which is what makes RPO 0 possible (DM-3). A database plus WORM backup in the
operator's own account would leave the operator as the sole verifier.

| Data role | Container | Rebuildable? |
|---|---|---|
| Operational record | Operational PostgreSQL | Yes, from canonical events |
| Queryable canonical copy | PostgreSQL (`QueryStore`) | Yes; excluded from recovery |
| Authoritative payload | External archive | **No** — the copy of record |
| Public mart | Snapshot origin plus CDN | Yes |
| Analytical mart | Insights materialised views | Yes |
| Regulatory data | Analytics stores, regulator account | Rules signed; findings evidential |

**D2–D4. The read model, the classes and the deletion rule.** A plaintext copy stays in the platform because
lineage cannot decrypt per hop; three visibility classes exist and no middle tier, because per-field policy cannot
be enforced on an immutable record; retention is per class and deletion needs three parties, so nobody deletes
history alone (DM-4).

**D5. One relational database, append-only canonical tables.** Relational rather than document, graph or
event-sourced, for the reasons in §2.2; canonical tables are append-only and the lineage edges are indexed for
recursion (DM-1, SQ-4).

The model that follows: a submission materialises one canonical event; an event validates against one profile
version, is acknowledged by one or more holders, commits as one leaf and references zero or more evidence records;
a batch holds many leaves and chains to its predecessor.

![Figure 9 — Physical data model](../docs/diagrams/preview/core-physical-model.png)

*Figure 9 — Nine tables; the constraints that matter are named below.*

Five constraints matter: `capture_record_id` is the primary key of submission and canonical event, so idempotency
identity is identity; `merkle_leaf` is unique on `capture_record_id`, which makes anchoring idempotent;
`canonical_event` is partitioned monthly and append-only; `payload` holds only fields the platform does not query;
row-level predicates on `organisation_id` back the scope filter.

**D6. Analytics eats a minimised snapshot and returns messages.** The platform must not be able to read rules or
findings, and the regulator must not need raw tables (Figure 1). A platform-hosted tenant would give one
administrator both.

**D7. No warehouse or lake at pilot scale.** 10 000 events/day is served by materialised views; a warehouse adds a
second consistency boundary and a lake would duplicate private content. Revisit when volume or query mix changes.

These decisions satisfy DM-1 to DM-6: interpretability travels with the event, private content never lands, the
archive is authoritative, retention is a recorded state machine, no natural-person field exists, and findings
carry their rule version and watermark.

## 4.3 Where it runs, and who owns it — rubric 4.11–4.15

**C1. Managed services, one image running as application or worker.** A small team has no operations capacity; IaaS
with a self-managed cluster would move patching, HA and backup onto it.

**C2. Four accounts, delivered declaratively.** This is what makes "the platform can deploy into the regulator's
account but cannot read from or operate it" a property of the pipeline; one account would put an administrator in
reach of every control plane.

**C3. One region with warm copies, one primary with a reader, and an isolated relayer.** The availability target is
met without active-active; the relayer holds the only credential that can spend money, so it has no inbound path
and a single instance.

![Figure 10 — Logical deployment](../docs/diagrams/preview/c4-deployment.png)

*Figure 10 — Logical placement: which control domain owns which node.*

![Figure 11 — Reference deployment](../docs/diagrams/preview/c4-reference-deployment.png)

*Figure 11 — A configuration that can be procured and built.*

The logical view answers who owns what; the reference view answers what we would buy. Seven workloads, each with
one credential and one scaling unit: application and workers on request rate and outbox lag, the database as a
managed primary with a reader, archive and KMS in a trustee account, delivery behind a CDN.

## 4.4 The write path and the recall path — rubric 4.16–4.17

![Figure 12 — Dynamic view: event acceptance](../docs/diagrams/preview/c4-dynamic.png)

*Figure 12 — One event from submission to confirmed visibility, in five phases and sixteen steps.*

The ordering is the argument: a receipt follows an outside holder's signature, and confirmation follows finality.
No timeout promotes an event, and a failure suspends it where it stands.

| Steps | Data crossing | Classification | Boundary crossed |
|---|---|---|---|
| 1–2 | Canonical event, signature, identifiers | Consortium | Participant to platform |
| 4–7 | DEK, envelope, ciphertext, acknowledgement | Consortium (encrypted) | Platform to KMS and holder |
| 8–9 | Receipt; anchor intent and leaf | Consortium | Platform to participant |
| 10–13 | Merkle root, transaction reference, inclusion proof | Public commitment | Platform to chain |
| 14–15 | Versioned public projection | Public | Platform to CDN |
| 16 | Trace page for the submitter | Consortium | Application to portal |

Step 16 is the submitter reading back; the consumer read comes from the CDN at step 15 and never reaches the
application.

![Figure 13 — Dynamic view: recall investigation](../docs/diagrams/preview/c4-dynamic-recall.png)

*Figure 13 — Scope at a watermark, evidence request, signed notice.*

The recall path is where privacy is decided: scope at a fixed watermark with provisional claims kept apart, an
evidence request that becomes an audit record rather than a data pull, and a notice published as `PENDING_ANCHOR`
before it is `CONFIRMED`.

## 4.5 What is protected, and what is accepted — rubric 4.18–4.20

**S1. An event is confirmed only after a signature from outside the platform's account.** Otherwise the operator
can manufacture a confirmed claim; a platform-signed timestamp would do exactly that.

**S2. Each event has its own data key, wrapped by a consortium key held outside the platform.** The archive then
holds ciphertext it cannot read, so compromising the archive is not disclosing content; a platform-held KEK would
make the archive's independence decorative.

**S3. One envelope covers four custody modes, and authority is judged as of signing time.** Rotation or a later
compromise must not invalidate history; a format per mode and status-at-check-time would.

**S4. Private evidence never reaches the platform, and no natural-person field enters the record.** The platform
cannot be compelled to hand over what it does not hold, and deletion never has to negotiate with an immutable log;
field-level encryption on the platform would leave it holding the keys.

**S5. Staff have no standing access; break-glass is dual-approved, recorded and anchored.** The insider is the
highest-privilege threat, and a refusal is itself evidence.

**S6. Every principal that can write, read or disclose gets one enforced entry point.** Participant-facing (API,
portal, onboarding), leaving the account (archive, key service, chain, regulator) and internal (staff, evidence
owner) each cross once, which is why STRIDE is a coverage check rather than a generator.

| Category | Threat | Mitigation | Residual |
|---|---|---|---|
| Spoofing | A participant claims to be another; a device claims another's identity | Envelope bound to a verified organisation and key; acting organisation; device delegations | Compromised participant credentials |
| Tampering | A row or a batch is altered or skipped | Signed digest; append-only; roots commit to the previous root; consistency proofs | Finality is asynchronous |
| Repudiation | A publisher denies an event; the operator denies an advisory | Non-repudiable signatures; key history; issuer keeps its copy | Keys held by third parties shift the question |
| Information disclosure | Private evidence leaks; a member reads outside scope | Content never on platform; owner-encrypted recipients; scope at the single read entrance | Metadata and access patterns |
| Denial of service | Event flood; a holder set that never acknowledges | Quotas, backpressure, bounded queues; two configured holders | A sustained flood degrades others |
| Elevation of privilege | An operator reads plaintext; a regulator reaches evidence | No standing access; case-scoped grants; anchored access record | A compromised break-glass path is a high-severity incident |

Accepted, per requirement: compromised credentials (SP-1), provider-held keys (SP-2), metadata (SP-3), indirect
identification (SP-4), colluding approvers (SP-5), a runtime that reads consortium plaintext (SP-6), a compelled
regulator mirror (SP-7); SP-8 states the rest in the interface.

No personal field means deletion never negotiates with immutability; content off the platform means nothing can be
compelled; classification by construction means no "sensitive but shared" tier can appear. Three risks stay stated: a
compromised runtime, a resourced colluder, and a holder's own legal obligations.

## 4.6 Device evidence and screening, in the architecture — rubric 4.B, bonus

**AI.** Screening runs in the regulator's workspace over signed rule versions; a model is an alternative
implementation of the same interface, which is why the first release has no model loader. Every finding carries its
rule or model version and input watermark; no output becomes an action without an officer's signature. Rejected: ML
at admission, and training on the platform's own copy.

**IoT.** The boundary sits at the participant: profile-required summaries enter the record, raw readings stay behind a
commitment, and devices are organisation delegations, not users. Collection and alarming are local, availability is
the platform's, verifiability the archive's. Rejected: raw telemetry upload and platform-side alerting, which would
duplicate the participant's control loop.

# 5. Architecture evaluation and alternatives

This section tests the promises made in Sections 1–4 against what the architecture delivers, and names where they
fall short.

## 5.1 How well it does — rubric 5.1–5.4

### The objectives, and how each is met — rubric 5.1–5.2

| ID | Business objective | Source | Verdict | Evidence and residual gap |
|---|---|---|---|---|
| BO-1 | An immutable, attributable record of every stage | brief 1 | **Met** | Envelope, holder-signed acknowledgement, Merkle inclusion; collusion is detectable, not prevented |
| BO-2 | Farmers, distributors, retailers and consumers all act, not only read | brief 2, 7 | **Met, conditionally** | Browser capture, offline queue, device-bound signing, WCAG 2.2 AA; a keyless device drafts and signs later |
| BO-3 | A regulator establishes incident scope quickly and defensibly | brief 5 | **Met** | Traversal at a watermark with per-edge provenance, cited to the Food Act and Code (Appendix B) |
| BO-4 | Consumers see a truthful, current-enough view | brief 2 | **Met** | Versioned snapshots with explicit states; a cached snapshot can lag a notice |
| BO-5 | Commercial and personal data are not exposed | implied | **Met, with residual risk** | Content off-platform with owner-chosen recipients; metadata stays visible |
| BO-6 | Growth across products and regions without a rebuild | brief 4 | **Partly met** | Profiles are additive; a region still needs a deployment and governance step |
| BO-7 | Operable by a small team at pilot scale | C6 | **Met at pilot scale** | Managed services, one deployable; two more operated environments exist |
| BO-8 | Device evidence without handing over raw telemetry | brief 3 | **Met, conditionally** | Collection and alarming stay local; summaries are attributable, coverage follows instrumentation |
| BO-9 | Regulatory screening as a capability, ML optional | bonus | **Met structurally** | Analytics at all three C4 levels; depends on the regulator operating its runtime |
| BO-10 | Supply-chain insight is readable, not merely queryable | brief 6 | **Partly met** | Aggregation and scope designed; the view layer is a thin client, not specified |

The evidentiary objectives are met strongly. Both `Partly met` rows are what the design cannot close alone: a second
region is a governance act, and a view layer is a client this report does not specify.

### ATAM: what breaks, what does not, what trades off — rubric 5.3

ATAM rather than HAZOP: no physical process is controlled, and failure modes are already enumerated as lifecycle
states.

| Driver | Quality | Scenario | Importance | Difficulty |
|---|---|---|---|---|
| BO-1 | Integrity | QS-1 operator deletes a batch | H | H |
| BO-1 | Non-repudiation | QS-2 event verified after two rotations | H | M |
| BO-1 | Recoverability | QS-5 account lost after a receipt | H | H |
| BO-3 | Availability | QS-3 recall during an archive outage | H | H |
| BO-4 | Performance | QS-4 5 000 scans/s after a media story | H | M |
| BO-2 | Usability | QS-6 capture with 36 hours without signal | H | M |
| BO-5 | Confidentiality | QS-7 evidence request; QS-8 operations cannot read findings | H | H/M |
| BO-9 | Availability | QS-11 analytics down while a case is open | H | M |

**Risks.** The confirmation gate depends on parties outside the design: a holder or the chain can stall ingestion, and
one relayer holds the only wallet (quorum of one, outbox buffering, key in KMS, deterministic leaves). A flat read
scope leaves admission as the only confidentiality control. The regulator may not operate its runtime. A regional
loss can take 24 hours, a target proven only by drill. The field floor grows and burdens the smallest participants.

**Non-risks.** A monolith that will not scale — 10 000 events/day is one write every eight seconds. Chain cost
exploding — one transaction per window. A plaintext copy contradicting privacy — it holds what the platform may
already read, is rebuildable, and never holds private content. An immutable log defeating deletion — no
natural-person field enters it.

**Trade-offs.** Finality versus freshness: a shorter window improves visibility and raises cost; the provisional
plane is the compromise. Shared visibility versus confidentiality: a narrower scope would strengthen
confidentiality and weaken the recall-authority story. Evidentiary strength versus forensics: hosting private
content would help investigations and destroy the privacy claim.

### What else could have been built — rubric 5.4

**A1 — Permissioned consortium ledger.** Four to seven validators with BFT consensus give seconds-level finality and
finer privacy, but need four independent operators with HSMs, on-call and a charter; none exists (R1). It wins if an
industry body funds them.

**A2 — Trusted timestamping plus a transparency log.** WORM storage, RFC 3161 timestamps per batch digest and roots
in an auditor-co-signed append-only log: two or three trusted institutions instead of a public network, far cheaper,
and the strongest fallback. It wins only if C1 were relaxed — chain cost, finality variance or policy making a public
network untenable.

**A3 — Layer-2 anchoring.** The same envelope, leaves and proofs under a rollup: cost down by orders of magnitude and
faster confirmation, at the price of a sequencer and a seven-year bet on that L2.

**A4 — Microservices with an event bus.** The same responsibilities as separate services: independent scaling, paid
for with sagas, a broker, a registry and a platform team. Cost without benefit at 10 000 events/day.

| Criterion | Chosen | A1 | A2 | A3 | A4 |
|---|---|---|---|---|---|
| External verifiability | Any third party | Members only | TSA plus auditor | Public via L2 | Same as chosen |
| Independence | Holder, KMS, chain | Validator set | TSA and log operator | Same as chosen | Same as chosen |
| Operational burden | Low | **High** | **Lowest** | Low | **High** |
| Feasibility now (C6) | High | **Low** | High | High | Medium |
| Indicative annual cost | Cloud plus A$40–80k anchoring | Staff plus infrastructure | Cloud plus TSA fees | Cloud plus negligible anchoring | Cloud plus platform team |

The chosen design is not the best in the abstract but the cheapest that keeps BO-1's promise without institutions
that do not exist. Every alternative changes the edges, not the core.

# Appendix A — Traceability

This appendix carries the two matrices that the body refers to, because they are reference material: a reader
consults them to check a link, not to understand the design.

## A.1 Quality requirement to mechanism to component

| Requirement | Mechanism | Where it lives |
|---|---|---|
| SQ-1 Integrity | Append-only records, signed digest, external acknowledgement, Merkle inclusion, verifiable batch sequence | Orchestrator; relayer; archive |
| SQ-2 Non-repudiation | One envelope for all custody modes; key history retained; acceptance-time authority kept separate from cryptographic validity | Signature & Authority Validator |
| SQ-3 Availability | Fail-closed writes with idempotent retry; reads from materialised data; analytics never in the write path | State machine; workers; outbox |
| SQ-4 Performance | Edge snapshots; lineage from the plaintext query copy; bounded synchronous traversal | Snapshot delivery; `QueryStore`; `QueryPort` |
| SQ-5 Recoverability | The archive, not the database, is the copy of record; a recovery identity outside the platform rebuilds | Archive; recovery identity |
| SQ-6 Usability and accessibility | Browser-first capture, durable offline queue, client-generated identifiers, device-bound signing | Portal; `CaptureSubmission` |
| SQ-7 Privacy | Three visibility classes with no middle tier; content off-platform behind a salted commitment; no natural-person field | `ProtectedResourceRef`; `SignatureEnvelope` |
| SQ-8 Interoperability | EPCIS 2.0 / CBV; versioned profiles; chain-agnostic leaves | Canonicalisation; profile registry |
| SQ-9 Auditability | Watermarks on every projection; replayable derivation; findings bound to rule version and watermark | `QueryPort`; graph builder; manifest |
| SQ-10 Cost | One modular application, one managed database, no broker, batched anchoring | Container and deployment views |
| SQ-11 Device evidence | Summary fields declared by the profile, carried as extension fields, raw data behind a reference | Profile validator; `ProtectedResourceRef` |
| SQ-12 Regulatory screening | Signed rule versions run in the regulator's workspace; the advisory returns as a signed message | Analytics workspace |
| SQ-13 Analysability | Aggregates materialised over the confirmed projection at a watermark, under the same scope rules | `Insights` module |

## A.2 Class to component to container

| Component | Container | Classes |
|---|---|---|
| Capture API, Idempotency | Traceability Application | `CaptureSubmission`, `ProtectedResourceRef` |
| Canonicalisation, Signature Validator | Traceability Application | `CanonicalEvent`, `ProfileVersion`, `SignatureEnvelope` |
| Archive & Anchor Orchestrator | Traceability Application | `ArchiveEnvelope`, `ArchiveAck`, `MerkleLeaf`, `AnchorBatch`, `AcceptanceReceipt` |
| Store, Graph Builder, QueryPort | Traceability Application | `EvidenceEdge`, `EdgeType`, `EdgeQuery`, `EdgeGroup` |
| Anchor Intent Reader, Leaf Allocator, Batch Builder, Chain Submitter, Finality Watcher | Batch Builder & Relayer | — (operates on `MerkleLeaf`, `AnchorBatch`) |
| Analytics Workspace components | Analytics Workspace | `DatasetSnapshot`, `ScreeningRun`, `Rule`, `RuleVersion`, `RuleVersionManifest`, `Finding`, `AdvisoryFinding`, `DisclosurePolicy` |

# Appendix B — Regulation

The body cites obligations in passing. This appendix says what each citation requires and where the design
answers it.

| Obligation | What it requires | Where the design answers it |
|---|---|---|
| Food safety duties and recall powers (NSW Food Act 2003; Food Standards Code) | Conservative recall traversal, signed official notices, and a clear split between "possibly affected" and "confirmed unsafe" | Recall scope at a fixed watermark with provisional set labelled (BO-3); signed notices as canonical events |
| Australian Privacy Principles; NSW PPIP Act 1998 | No personal identifiers in an immutable trace, minimisation at ingestion, correction and deletion in the mutable layer | Three visibility classes; no natural-person field in the event model; private evidence off-platform (SP-3, SP-4) |
| Records retention and legal hold | Per-class retention, terminal deletion states, defensible deletion records | Retention state machine, three-party deletion, anchored deletion record (2.3–2.4) |
| Evidentiary expectations | Chain of custody, authentication, reproducible derivation | Signed declarations, holder acknowledgement, inclusion and consistency proofs, replayable derivation (SQ-1, SQ-9) |
| Government procurement and residency | Australian regions for non-public data; analytics in the regulator's own account | Sydney primary with Melbourne copies; four accounts (2.5–2.6, 4.14) |

