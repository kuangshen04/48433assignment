# 2. Requirements Analysis

*Draft — untrimmed. Rows covered: 2.1–2.8 and the 2.B bonus.*

Requirements carry identifiers (`SQ`, `DM`, `CL`, `SP`, `AI`, `IoT`) and are traced to the stakeholders
`S1`–`S12` defined in Section 1.1.3 and to the objectives `O1`–`O8`. Later sections refer back to these
identifiers rather than restating the requirement.

## 2.1 System quality requirements

### 2.1.1 From stakeholder interests to qualities

| Quality | Driven by | Because |
|---|---|---|
| Integrity and tamper-evidence | S6, S9, S11, R2, O2 | The record is only useful if the party hosting it cannot rewrite it unnoticed |
| Non-repudiation and attribution | S1–S4, S6, S11, R3 | A claim must be traceable to the organisation that made it, years later |
| Availability and graceful degradation | S4, S5, S6 | A recall must not be blocked by a dependency outage; consumers must never see a false "no record" |
| Performance and scalability | S5, S6 | Consumer scans arrive in bursts; recall traversal is a multi-hop graph query |
| Recoverability | S6, S10, S11 | Confirmed history must survive the loss of the platform's own database |
| Usability and rural accessibility | S1, S4, C4 | If capture is hard, coverage collapses where it matters most |
| Privacy and confidentiality | S1, S5, S6, C2, R5 | Commercial and personal information must not leak into a permanent shared record |
| Interoperability and evolvability | S2, S3, S11, C3, R9 | Participants keep their systems; the record must outlive a vendor or a chain |
| Auditability and regulatory compliance | S6, S7, C2 | Evidence must be defensible; analytics must be attributable and reproducible |
| Analysability | S1–S4, S6 | Volume, movement and dwell are what participants act on; an event log alone is not a supply-chain tool |
| Cost efficiency and operability | S9, C5, C6 | A pilot that needs a platform team per region will not run |

### 2.1.2 Quality requirements

| ID | Quality | Requirement | Measure / acceptance | Stakeholders |
|---|---|---|---|---|
| SQ-1 | Integrity | Once an event is presented as confirmed, no participant, holder or operator can alter or remove it without detection by an independent party | A modified or missing record is detectable from published proofs alone (inclusion proof, batch consistency, signature chain) | S6, S9, S11 |
| SQ-2 | Non-repudiation | Every canonical event carries a verifiable signature from the organisation that published it, and attribution survives key rotation and revocation | A verifier can establish publisher identity and signing validity from the event and public registry history only | S1–S4, S6, S11 |
| SQ-3 | Availability | Loss of any single dependency degrades a defined capability but never produces a false negative in a safety query | Fault injection per dependency produces a declared state and a visible degradation marker, never "no record" | S4, S6 |
| SQ-4 | Performance | Consumer reads are served from a CDN; interactive recall queries return within the interaction budget; larger traversals are exported at a fixed watermark | 5 000 consumer requests/s at the edge; synchronous traversal bounded (10 000 edges) with asynchronous export beyond it | S5, S6 |
| SQ-5 | Recoverability | Confirmed trace can be rebuilt without the platform's database | Logical RPO 0 for receipted confirmed events; operational database RPO ≤ 5 min; core RTO ≤ 4 h; regional rebuild ≤ 24 h | S6, S10 |
| SQ-6 | Usability and accessibility | A first-time smallholder can submit a complete, valid event without training, on a low-end phone in poor coverage, and every screen is usable by people with low literacy or low vision | Capture completes in under three minutes at 2G-class bandwidth; every screen meets WCAG 2.2 AA, works at 200 % text size, and each field carries a plain-language label and an icon | S1, S4 |
| SQ-7 | Privacy | The immutable shared record contains no natural-person reference and no private commercial content | Schema check at admission; a privacy review of the profile allowlist | S1, S5, S6 |
| SQ-8 | Interoperability | Events use the EPCIS 2.0 / CBV vocabulary; profiles are versioned and published; chain and vendor choices are replaceable | A third party can interpret an event from its profile and canonicalisation version alone | S2, S3, S11 |
| SQ-9 | Auditability | Every state change and every disclosure decision is attributable and reproducible; analytics outputs are traceable to a rule version and an input watermark | Independent replay of edge derivation and advisory generation reproduces the same result | S6, S7, S11 |
| SQ-10 | Cost / operability | The pilot runs as one modular application and one managed database, with no self-managed cluster | Deployment topology and monthly cost estimate documented; no per-region node fleet | S9 |
| SQ-11 | Device evidence integration | Device-sourced evidence (cold chain, weights, scans) reaches the shared record as profile-required summaries with provenance, without the platform hosting raw telemetry | A profile can require a sensor summary; the summary is traceable to its publisher and to private raw data without publishing it | S1, S3, S12 |
| SQ-12 | Regulatory screening capability | The system provides screening over confirmed claims, with rules owned and signed by the regulator; ML is optional, the capability is not | A rule version can be published, run at a watermark, and its output traced to that version; disabling it degrades advice, not trace | S6, S7 |
| SQ-13 | Analysability | Confirmed data can be read as insight views — volume, movement and dwell by product line, location and period — without leaving the scoped, watermarked read path | Every view states its watermark and scope; the same figures are reproducible from the confirmed projection; no view includes an unconfirmed claim | S1–S4, S6 |

## 2.2 Quality scenarios, risk evaluation, decisions and rejected alternatives

### 2.2.1 Quality attribute scenarios

Each scenario uses the six-part form: source, stimulus, artefact, environment, response, measure.

**QS-1 — Tamper-evidence (SQ-1).** A platform operator, under pressure, deletes a batch of events from the
production database. *Artefact:* confirmed event history. *Environment:* normal operation. *Response:* the
events remain recoverable from the external archive, and the batch's absence from the chain is detected by a
consistency proof. *Measure:* detection without cooperation from the platform; recovery of exact archived
bytes.

**QS-2 — Attribution under key rotation (SQ-2).** A regulator verifies an event signed three years ago by a
distributor that has since rotated its key twice and suspended one of its organisations. *Artefact:* event,
signature envelope, key registry history. *Environment:* post-incident audit. *Response:* verification
succeeds against the historical key, with the acceptance-time authority status made explicit. *Measure:*
verification does not depend on the key's current status.

**QS-3 — Safety query during degradation (SQ-3).** A recall begins at 02:00 while the archive provider is
unavailable. *Artefact:* recall traversal over confirmed claims. *Environment:* degraded dependency.
*Response:* traversal proceeds over materialised confirmed data; the result is labelled with its watermark
and the degradation; no object is reported as "not affected" on the basis of missing data. *Measure:* zero
false negatives attributable to the outage; the label is visible on the result.

**QS-4 — Consumer burst (SQ-4).** A television news item shows a product's QR code; 5 000 scans/s arrive
within a minute. *Artefact:* public projection delivery. *Environment:* peak load. *Response:* the CDN serves
the versioned snapshot; origin sees a small fraction of the traffic. *Measure:* origin requests ≤ ~250/s;
p95 edge latency within the CDN's cache-hit profile.

**QS-5 — Loss of the platform (SQ-5).** The platform's database, IAM and DNS are lost entirely, while a
receipt was issued and the event has not yet been anchored. *Artefact:* receipted, unanchored event.
*Environment:* disaster. *Response:* a trustee-controlled recovery client enumerates the archive, restores
the receipt and anchor intent, and resumes anchoring without duplicating a receipt or a leaf. *Measure:* no
duplicate receipt or leaf; anchoring resumes within the recovery objective.

**QS-6 — Rural capture (SQ-6).** A picker records a harvest in a paddock with no coverage, then moves to
coverage 36 hours later. *Artefact:* capture client and submission path. *Environment:* intermittent
connectivity. *Response:* the event is drafted locally, signed where the device supports it, queued, and
submitted idempotently on reconnect. *Measure:* exactly one canonical event; no duplicate receipts.

**QS-7 — Private evidence sharing (SQ-7).** A lab report is requested during an investigation. *Artefact:*
evidence reference and the report itself. *Environment:* investigation. *Response:* the report is provided
by its owner, encrypted to the regulator's key; the platform stores only a record and never the plaintext.
*Measure:* the platform cannot read the content, and can nevertheless show that the commitment matches.

**QS-8 — Regulatory analytics isolation (SQ-7, SQ-9).** The platform's operations team wants to debug a
screening rule that produced an unexpected advisory. *Artefact:* rule set and findings. *Environment:*
operations. *Response:* the team can inspect the signed advisory and the rule version manifest, but cannot
read the rule body or the regulator's private findings, because both live in the regulator's account.
*Measure:* no path from platform credentials to finding content.

**QS-9 — Conflicting claims (SQ-1, SQ-9).** Two processors each publish a transformation claim consuming the
same input lot. *Artefact:* lineage and recall views. *Environment:* dispute. *Response:* both claims are
retained; every default view shows both with provenance; neither is ranked or selected. *Measure:* the
conflict is visible in the view, and an independent replay of edge derivation reproduces both edges.

**QS-10 — Chain migration (SQ-8).** The chosen public network becomes uneconomic two years into operation.
*Artefact:* anchoring pipeline and verification path. *Environment:* planned migration. *Response:* new
batches anchor on a new chain while old proofs remain verifiable; batch metadata records the migration
boundary. *Measure:* old inclusion proofs still verify; no canonical event is re-signed or rewritten.

**QS-11 — Analytics unavailable during an investigation (SQ-12).** A regulator opens a case while the analytics workspace is down for maintenance. *Artefact:* trace query, recall traversal, advisory feed. *Environment:* one subsystem unavailable. *Response:* trace and recall continue; the UI shows risk assessment as delayed and marks advisories as possibly incomplete; no "no risk found" is displayed. *Measure:* case work continues and the degradation is visible on the same screen as the result.

**QS-12 — Cold-chain excursion evidence (SQ-11).** A reefer exceeds its temperature limit for 40 minutes in transit. *Artefact:* receiving claim, sensor summary, private raw log. *Environment:* normal operation, intermittent device connectivity. *Response:* the participant's own system alarms and acts; the receiving claim carries a profile-required excursion summary and a reference to private raw data; the regulator can later check the summary against the raw data through the owner. *Measure:* the summary is present and attributable; the raw log never reaches the platform.

**QS-13 — Quarterly review (SQ-13).** A category manager reviews one product line across a region. *Artefact:* confirmed projection. *Environment:* normal operation, a fixed watermark one day behind. *Response:* volume, movement and dwell are shown per location and period, labelled with their watermark; every figure resolves to the confirmed events behind it. *Measure:* the same figures can be reproduced from the projection, and no figure includes a provisional claim.

### 2.2.2 Risks by quality, the decisions taken, and the alternatives rejected

| Quality | Risk if unaddressed | Decision taken | Alternative rejected, and why |
|---|---|---|---|
| Integrity | The operator, or an attacker with operator credentials, silently rewrites history | Commit to a public chain; require a copy outside the operator's control domain before an event counts as confirmed; publish consistency proofs for batch sequences | **Database plus WORM backup** — keeps the operator as sole verifier, which defeats the requirement. **Permissioned ledger with validator set** — needs independent operators that this project does not have (R1) |
| Non-repudiation | Claims become unattributable after key rotation, or a key compromise invalidates old evidence retroactively | One signature envelope for all custody modes, with key history retained; separate cryptographic validity from acceptance-time authority; never rewrite past events on later compromise | **A single platform-managed key per participant** — makes the platform able to impersonate the participant, contradicting R2. **Per-employee keys** — creates natural-person data in an immutable record (R5) |
| Availability | A dependency outage makes a safety query return "nothing found" | Explicit degradation states; safety queries fail closed and are labelled; advisory and analytics never sit in the write path | **Synchronous calls to every dependency on the read path** — turns any outage into an outage of the whole product. **Fallback to the archive for every read** — latency and cost prohibitive |
| Performance | Consumer bursts overwhelm the origin; recall traversal times out | Versioned public snapshots on a CDN; bounded synchronous traversal at a fixed watermark; asynchronous export beyond the bound | **Live queries against canonical tables for consumers** — exposes internal schema and cannot absorb bursts. **A dedicated graph database from day one** — no workload evidence at pilot scale |
| Recoverability | Confirmed history dies with the platform's database | External archive as the authoritative copy; recovery identity outside the platform; restore drills as an acceptance test | **Database backups only** — the same trust domain, and no independent catalogue |
| Usability | Coverage gaps in the tiers that matter | PWA first; offline queue; device-bound signing where the platform supports it; no native app requirement | **Native apps per platform** — cost without architectural benefit. **Assume enterprise integration everywhere** — excludes S1 |
| Privacy | An immutable log becomes an unlawful personal-data store | No natural-person references in the immutable trace; private evidence off-platform with salted commitments; personal data only in the mutable registry | **Field-level encryption inside the shared record** — the platform still holds keys, so it can still read. **Per-event access lists** — unenforceable when the platform cannot read the content |
| Interoperability | Vendor and chain lock-in | EPCIS/CBV; versioned profiles and canonicalisation; chain-agnostic leaves; portable archive envelope | **Custom event model** — cheaper to design, but every participant needs a lossy mapping and third parties cannot interpret events |
| Auditability | Findings cannot be defended; derivation cannot be checked | Rules signed and versioned by the regulator; edge derivation published and replayable; advisories carry rule version and watermark | **Advisory stored as platform opinion** — no attributable author. **Derived status stored as truth** — hides the evidence trail |
| Analysability | Insight views become a second read path that silently disagrees with the trace | Views served from the same confirmed projection at a named watermark, through the same scope rules | **A separate dashboard database loaded by ETL** — a second consistency boundary, and a place where stale or unconfirmed figures can look authoritative |
| Cost | The pilot cannot be run by a small team | Modular monolith, one managed database, no broker, managed services, batched anchoring | **Microservices and a broker per concern** — operational cost without a scaling need; revisit only on measured pressure |

## 2.3 Data management requirements and data dictionary

### 2.3.1 Data requirements

| ID | Requirement | Stakeholders |
|---|---|---|
| DM-1 | Event data must be interpretable by a third party using only the event, its profile version and its canonicalisation version | S2, S3, S11 |
| DM-2 | Commercial documents and private content must not be stored on the platform in readable form | S1, S4, S6 |
| DM-3 | Every data element must have exactly one authoritative source, and derived copies must be rebuildable | S6, S9, S11 |
| DM-4 | Retention must be expressible per data class, with legal hold and a defensible deletion record | S6, C2 |
| DM-5 | The immutable trace must contain no natural-person identifiers | S1, S5, C2 |
| DM-6 | Regulatory outputs must carry their rule version and input watermark so that they are reproducible | S6, S7 |

### 2.3.2 Data dictionary

Format and length are the constraints enforced at admission. "Source" names the party that originates the
value; where the platform derives a value, the derivation is stated.

**Event identity and lifecycle**

| Element | Format | Length | Description | Source | Serves |
|---|---|---|---|---|---|
| `captureRecordId` | UUID v4 | 36 | Client-generated idempotency key for one submission attempt | Participant device or system | DM-3, S1, S9 |
| `epcisEventId` | URI (RFC 3986) | ≤ 255 | Publisher-assigned business identity of the event; nullable | Publisher | DM-1, S2, S3 |
| `eventType` | Enum: Object, Aggregation, Transformation, Association, Transaction | ≤ 20 | EPCIS event type | Publisher | DM-1 |
| `action` | Enum: ADD, OBSERVE, DELETE | 8 | EPCIS action | Publisher | DM-1 |
| `recordTime` | ISO 8601 UTC, ms | 24 | Platform's trusted capture timestamp; client-supplied values are ignored | Platform | SQ-1, DM-3 |
| `receivedAt` | ISO 8601 UTC, ms | 24 | Time the submission entered the platform | Platform | SQ-9 |
| `confirmationStatus` | Enum | ≤ 32 | Lifecycle state of the submission | Platform | SQ-3 |
| `handoverStatus` | Enum (7 values) | ≤ 24 | Derived pairing state of a transfer | Derived module | DM-3 |

**EPCIS business content**

| Element | Format | Length | Description | Source | Serves |
|---|---|---|---|---|---|
| `eventTime` | ISO 8601 with offset | 30 | Time the business event occurred, as asserted by the publisher | Publisher | DM-1, SQ-9 |
| `eventTimeZoneOffset` | ±hh:mm | 6 | Offset in force at the event location | Publisher | DM-1 |
| `bizStep` | CBV URI | ≤ 255 | Business step (commissioning, shipping, receiving, …) | Publisher | DM-1, S3 |
| `disposition` | CBV URI | ≤ 255 | Business condition (in progress, sellable, recalled, …) | Publisher | DM-1, S4 |
| `bizLocation` | SGLN URI or GLN | 13–255 | Business location where the event occurred | Publisher | DM-1, S6 |
| `readPoint` | SGLN URI | 13–255 | Physical read point; optional when no module requires it | Publisher | DM-1 |
| `sourceList` / `destinationList` | Array of {type, party/location} | ≤ 255 each | Parties or locations the goods came from or went to | Publisher | O3, S6 |
| `bizTransactionList` | Array of {type, identifier} | ≤ 255 each | Business documents connecting events; carries the handover pairing key (`desadv`) | Publisher | S3, DM-3 |

**Object identification and quantity**

| Element | Format | Length | Description | Source | Serves |
|---|---|---|---|---|---|
| `epcList` | Array of EPC URI | ≤ 255 each | Instance-level identifiers (e.g. SSCC) | Publisher | DM-1, O3 |
| `quantityList` | Array of {`epcClass`, `quantity`, `uom`} | — | Lot/class-level identifiers with quantities | Publisher | O3, S2 |
| `epcClass` | GTIN or GTIN + lot URI | ≤ 255 | Class or lot identifier | Publisher | DM-1 |
| `quantity` | Decimal | 18,6 | Asserted quantity; the platform never derives a balance | Publisher | S2 |
| `uom` | UN/CEFACT code | 3 | Unit of measure | Publisher | S2, DM-1 |
| `parentID` / `childEPCs` | EPC URI / array | ≤ 255 | Aggregation parent and children | Publisher | O3 |
| `inputEPCList` / `outputEPCList` | Array of EPC URI | ≤ 255 each | Transformation inputs and outputs | Publisher | S2, O3 |
| `transformationID` | URI | ≤ 255 | Identity of the transformation | Publisher | S2 |

**Version and validation context**

| Element | Format | Length | Description | Source | Serves |
|---|---|---|---|---|---|
| `profileId` / `profileVersion` | Slug / semver | 64 / 20 | Validation profile governing schema and required fields | Consortium governance | DM-1, SQ-8 |
| `canonicalisationVersion` | Semver | 20 | Deterministic digest contract used for the payload | Platform (frozen per version) | DM-1, SQ-9 |
| `edgeDerivationVersion` | Semver | 20 | Rules used to derive lineage edges from canonical events | Platform (frozen per version) | SQ-9 |
| Extension fields (`ilmd`, profile extras) | Declared per profile field | Declared | Business attributes beyond the core floor | Publisher | DM-1 |

**Signature and attribution**

| Element | Format | Length | Description | Source | Serves |
|---|---|---|---|---|---|
| `signerOrganisationId` | UUID v5 (derived from legal identifier) | 36 | Organisation accountable for the assertion | Registry | SQ-2, DM-5 |
| `keyId` | UUID | 36 | Signing key used | Participant | SQ-2 |
| `signatureAlgorithm` | Enum (ES256, EdDSA) | 16 | Signature algorithm | Participant | SQ-2 |
| `signatureValue` | Base64url | ≤ 1024 | Detached signature over the canonical payload digest | Participant | SQ-2 |
| `custodyMode` | Enum (4 values) | ≤ 32 | Enterprise self-custody, device-bound, assisted external, delegated platform | Participant | SQ-2 |
| `assuranceLevel` | Enum (A1–A3) | 4 | Assurance tier implied by custody mode and evidence | Platform | SQ-2 |
| `assertedSignedAt`, `signingTimeEvidence` | ISO 8601 / provider receipt | 24 / ≤ 2048 | Asserted signing time and optional trusted evidence | Participant / provider | SQ-2 |

**Archive and anchoring**

| Element | Format | Length | Description | Source | Serves |
|---|---|---|---|---|---|
| `canonicalPayloadDigest` | SHA-256 hex | 64 | Digest of the canonical payload; the signed value | Platform | SQ-1 |
| `archiveObjectId` | UUID or URI | 36–255 | Identity of the stored archive object | Archive holder | SQ-5 |
| `ArchiveAckDigest`, `archiveEnvelopeDigest`, `ciphertextDigest` | SHA-256 hex | 64 | Digests binding the acknowledgement, envelope and stored bytes | Archive holder / platform | SQ-1, SQ-5 |
| `merkleLeafIndex`, `batchId`, `merkleRoot` | uint64, UUID, hex | 20, 36, 64 | Position in a batch, batch identity, batch root | Platform / relayer | SQ-1 |
| `transactionRef`, `inclusionProof` | Chain-specific / array of hex siblings | ≤ 128 / ≤ 40 entries | External existence proof | Public chain | SQ-1, S11 |

**Private evidence references**

| Element | Format | Length | Description | Source | Serves |
|---|---|---|---|---|---|
| `resourceId`, `ownerOrganisationId` | UUID | 36 | Identity of the evidence record and its owner | Platform | DM-2 |
| `plaintextCommitment` | SHA-256 hex | 64 | Salted commitment `H(content ‖ nonce)`; nonce held only by the owner | Owner | DM-2, SQ-7 |
| `storageMode` | Enum: participant-hosted, platform-hosted zero-knowledge | ≤ 40 | Where the ciphertext lives | Owner | DM-2 |
| `availabilityStatus` | Enum: owner-asserted, object-present, unknown | ≤ 24 | Two independent facts about availability, never collapsed to a boolean | Platform + owner | SQ-3, S6 |
| `recipientKeyRefs` | Array of `keyId` | ≤ 10 × 36 | Encryption keys the owner chose for sharing | Owner | SQ-7 |
| `retentionPolicyId` | Slug | ≤ 64 | Retention rule that applies to this record | Governance | DM-4 |

**Regulatory outputs**

| Element | Format | Length | Description | Source | Serves |
|---|---|---|---|---|---|
| `findingId` | UUID | 36 | Identity of a finding; reused for its advisory and for retraction | Regulator | DM-6 |
| `ruleId`, `ruleVersion` | Slug, semver | 64, 20 | Rule that produced the finding | Regulator | DM-6, SQ-9 |
| `dataWatermark` | uint64 | 20 | Input position the finding was computed against | Regulator | DM-6 |
| `severity`, `reasonCodes` | Enum / array | ≤ 32 | Interpretation and machine-readable reasons | Regulator | S6 |
| `disclosureScope` | Enum: regulator-only, subject organisation, consortium advisory, public-by-separate-signature | ≤ 40 | Who may see the output | Regulator | SQ-7 |
| `expiresAt` | ISO 8601 UTC | 24 | End of the advisory's current-state validity | Regulator | S6 |
| `regulatorSignature` | Base64url | ≤ 1024 | Signature over the finding or rule manifest | Regulator | SQ-2, SQ-9 |

## 2.4 Data scenarios, validation, storage, access, retention and ingestion

### 2.4.1 Data scenarios

**DS-1 — Seven-year recall reconstruction (DM-1, DM-3).** A regulator must establish which retail lots
contain product from a specific farm block, seven years after harvest. *Path:* confirmed claims at a fixed
watermark → transformation edges → aggregation edges → handover edges, each carrying publisher and time.
*Requirement:* every hop is reproducible from canonical events and the versioned derivation rules; the
result is a set of claims with provenance, not a verdict.

**DS-2 — Two claims for one lot (DM-3).** Two processors assert consumption of the same input lot.
*Path:* both edges retained; default views group competing edges and show them side by side; no ranking, no
score, no representative path. *Requirement:* the data model must be able to store two edges with identical
endpoints and different publishers, and the query layer must not collapse them.

**DS-3 — Lab report disclosure (DM-2).** A regulator requests a laboratory report held by a packer.
*Path:* the request is recorded as an audit record; the owner encrypts the content to the regulator's
encryption key and supplies it; the regulator decrypts and checks it against the salted commitment.
*Requirement:* the platform can prove that what the regulator received matches what was committed, without
ever holding the plaintext.

**DS-4 — Consumer scan at peak (DM-2).** 5 000 scans/s. *Path:* CDN edge serves a versioned public
snapshot; origin is hit on cache miss. *Requirement:* public data must be materialisable as versioned
objects, with an explicit publication timestamp, and must never require joining canonical tables at request
time.

**DS-5 — Retention expiry with a hold (DM-4).** A batch reaches the end of its retention period while a
dispute places it on legal hold. *Path:* retention state machine holds the record; after the hold is lifted
and the period elapses, the archive ciphertext and wrapped key are deleted, a signed minimal deletion record
is anchored, and the non-personal commitment remains. *Requirement:* deletion must be a recorded transition,
not an implicit side effect; the deletion proof must be verifiable externally.

**DS-6 — Offline capture with a revoked key (DM-3).** A device captures 40 events in a dead zone while
its organisation's key is rotated. *Path:* the events are queued and signed with the old key; on receipt the
platform finds the key revoked and no trusted pre-revocation time evidence, so the events enter a review
state and do not receive receipts. *Requirement:* the platform must distinguish "invalid" from "not yet
established", and a safety query must be able to show that events exist in that state.

### 2.4.2 Validation rules

Validation is split into two classes, and the distinction is a requirement, not an implementation detail:

| Class | Examples | Effect |
|---|---|---|
| Admission validation | Profile conformance; canonical digest reproducibility; signature validity; organisation/key/delegation authority; idempotency; permitted state transitions; correction relationships | **Blocks** the write |
| Structural representability | The same object consumed by two transformation claims; competing parents; references to unknown identifiers; lineage cycles in time | **Does not block**; determines how the projection presents the data |

Business plausibility (yield, loss, mass balance, fraud) is *not* a validation class. There is no rule in the
platform that rejects an event because its quantity looks wrong, because that would make the platform an
adjudicator without authority or observational ability.

### 2.4.3 Storage choice: relational, with append-only canonical tables

**Decision.** One managed relational database holds submission state, current registries, an outbox, a
queryable materialisation of confirmed events and rebuildable projections. Canonical records are append-only;
application state (profiles, jobs, retry state, UI settings) uses ordinary transactions.

**Why relational.**

1. The data is highly structured and rule-bound: EPCIS fields are typed, quantities are decimal, identifiers
   are constrained, and referential integrity between events, corrections and batches is exactly what a
   relational engine enforces.
2. Admissibility decisions require multi-row transactions: an event is persisted, its outbox intent is
   enqueued, and its idempotency key is claimed in one atomic step. A document store would push that
   coordination into application code.
3. Recall traversal is a recursive query over a modest graph, and the pilot's bound (10 000 synchronous
   edges) is within what a recursive CTE with proper indexing handles. Traversal is a query, not a workload
   that justifies a separate engine.
4. Reporting and retention queries are set-oriented and benefit from SQL, indexes and constraints.
5. Vendor portability: a managed PostgreSQL service is replaceable; a specialised store is not.

**Alternatives rejected.**

| Alternative | Why rejected |
|---|---|
| Document store (e.g. JSON documents per event) | Tempting because EPCIS payloads are nested, but it gives up cross-event constraints, decimal exactness and multi-row transactions, which are needed for admission. Extension fields still use JSON *inside* a relational column, which is the part where schemaless is actually useful |
| Graph database as the system of record | The graph is derived, not primary: edges are a deterministic function of canonical events. Storing the graph as truth would make the derivation unverifiable and the record non-replayable. A graph engine may later be added as a read optimisation if traversal latency demands it |
| Event store / event sourcing for the whole application | Canonical events are already append-only, but user profiles, job state and retry state are not events. Full event sourcing would add projection complexity without a requirement |
| Permissioned ledger as the database | Rejected for the reasons in 1.1.4 (R1) and revisited as an alternative in Section 5 |
| Data lake or warehouse as the primary store | The pilot's volume (10 000 events/day) does not justify it; analytical serving is a separate, rebuildable consumer |

### 2.4.4 Access control

Three visibility classes, enforced at one entry point:

| Class | Content | Reader | Platform can read plaintext |
|---|---|---|---|
| Public | Allowlisted product and trace projection, signed safety notices | Anyone | Yes (it generates it) |
| Consortium | Canonical EPCIS trace, handover and lineage, sensor summaries | Active consortium members | Yes, in the runtime, under audit |
| Private | Raw telemetry, reports, contracts, investigation notes | Owner, plus recipients the owner encrypted for | **No** |

Two rules make this enforceable. First, there is no middle class: content that must be queried by field must
enter the consortium class, and content that must stay private stays off the platform. Second, access is
bound per request to an explicit acting organisation, because a person may act for several organisations and
the token alone cannot say which.

### 2.4.5 Retention and deletion

Retention is defined per data class (canonical trace; profile and key history; private evidence; regulatory
exports; consumer scan logs) rather than as one global period. The pilot's default for the canonical trace
is a seven-year capacity assumption, adjustable by product, jurisdiction and legal hold.

Deletion is a three-party process by design: the platform *requests* it on the basis of a published policy,
the external archive holder *verifies the policy and executes* it and signs a deletion record, and any
deletion earlier than the policy allows requires dual control. The deletion record is anchored, so a
premature deletion is externally visible rather than silent.

### 2.4.6 Ingestion requirements

Ingestion must be idempotent, ordered only where the business requires it, and tolerant of offline clients:
client-generated identifiers, one atomic step that persists state and enqueues side effects, deterministic
digests so that a retry produces the same value, and a review state for events whose authority cannot be
established at receipt time.

### 2.4.7 Data management system requirements

Derived from the scenarios above, the data management system itself must provide:

| ID | Requirement | Why it follows from the scenarios |
|---|---|---|
| DB-1 | Multi-row ACID transactions | An event, its idempotency claim and its outbox intent must commit or fail together (DS-6) |
| DB-2 | Exact decimal arithmetic and units | Quantities are asserted by participants and must never be silently rounded (DS-1, S2) |
| DB-3 | Referential integrity between events, corrections and batches | A correction must reference an existing event; a leaf must reference a batch (DS-2) |
| DB-4 | Recursive queries with index support | Recall traversal is a bounded recursive query over lineage (DS-1, SQ-4) |
| DB-5 | Semi-structured column support for extension fields | Profiles add fields without schema migration, but only inside the declared profile (DS-1, DM-1) |
| DB-6 | Point-in-time recovery and cross-failure-domain backup | Operational state is rebuildable but must not be lost (SQ-5) |
| DB-7 | Row-level access predicates and audited reads | Organisation-scoped reads and break-glass access must be enforceable at the data layer, not only in application code (SP-1, SP-6) |
| DB-8 | Managed operation: patching, HA, backup, monitoring | The team operates the pilot, not a database fleet (SQ-10, CL-1) |

A relational engine satisfies all eight directly. A document store satisfies DB-5 and DB-8 well, but requires
application-level work for DB-1 to DB-4; that cost is what decided the storage choice in 2.4.3.

## 2.5 Cloud-adoption requirements

| ID | Requirement | Stakeholders |
|---|---|---|
| CL-1 | No capital expenditure and no infrastructure team for participants or for the operator | S1, S9 |
| CL-2 | Elastic capacity for consumer bursts without provisioning for peak | S4, S5 |
| CL-3 | Data residency in Australia, with cross-failure-domain durability | S6, C2 |
| CL-4 | Independent control domains: the regulator's analytics and the archive/KMS custody must be separable from the platform's account | S6, S10, R2 |
| CL-5 | Managed security operations: identity, key management, audit logging, patching | S9 |
| CL-6 | Exit and portability: portable data formats and replaceable chain | S9, R9 |

## 2.6 Cloud scenarios and XaaS choices

**CS-1 — Seasonal peak.** Harvest and retail promotions produce a 5–10× write peak and a 100× consumer read
peak. *Response:* managed database scales vertically and by read replica; CDN absorbs reads.

**CS-2 — Regulatory tenant separation.** The regulator requires its analytics to run in its own account.
*Response:* the analytics runtime is deployed by the platform as artefacts but operated in the regulator's
account, under the regulator's identity and billing.

**CS-3 — Disaster.** The platform's account is lost. *Response:* recovery uses the archive, a trustee-held
recovery identity and the public chain, not the platform's cloud account.

**CS-4 — Audit request.** A regulator asks for evidence that no one read a dataset out of purpose.
*Response:* managed audit logging plus application-level read auditing by organisation.

| Capability | Chosen service model | Why |
|---|---|---|
| The traceability service itself | SaaS for participants (PWA, API) | Participants must not operate infrastructure (CL-1) |
| Application runtime | PaaS/containers, managed by the operator | No cluster operations; horizontal scaling for workers |
| Relational store | Managed database service (PaaS) | Backups, PITR, patching, HA delegated to the provider |
| Public delivery | Object storage + CDN | Absorbs read bursts; versioned immutable objects |
| Archive | Managed WORM object storage, held outside the platform account | Immutability and retention with an independent signature over stored bytes |
| Key management | Managed KMS, in an account controlled by the consortium or a trustee | Platform may wrap/unwrap, may not administer or delete keys |
| Chain | Public network, consumed as an external utility | No validator operations; existence proofs only |
| Identity | External identity provider (OIDC) | Enterprise federation and MFA without building a directory |

**Alternatives rejected.**

| Alternative | Why rejected |
|---|---|
| IaaS virtual machines with self-managed database and clustering | Moves patching, HA and backup into a student team; violates CL-1 and SQ-10 |
| Self-managed Kubernetes | No scaling requirement justifies a cluster; the pilot is one modular application and a few workers (C5) |
| On-premises deployment at the regulator or a consortium member | Conflicts with multi-party access, elasticity and the public chain model; would need a new operating model |
| A single cloud account for platform, analytics and archive | Simplest operationally, but it puts one administrator in reach of every control plane, which contradicts R2 and CL-4 |
| Managed blockchain service (consortium edition) | Reintroduces validator membership and a permissioned governance model the project cannot populate (R1); also ties verification to one vendor |
| Self-hosted archive (platform's own bucket) | Cheapest, but the platform would hold the only copy and could destroy history, which is the risk the design exists to remove |

## 2.7 Security and privacy requirements

| ID | Requirement | Stakeholders |
|---|---|---|
| SP-1 | Every write is authenticated and authorised against an organisation, a role and a delegation scope, bound per request | S1–S4, S6 |
| SP-2 | Every canonical event is non-repudiable and its attribution survives rotation and revocation | S6, S11 |
| SP-3 | Private content is never readable by the platform; sharing is granted by the owner, not by the platform | S1, S4, S6 |
| SP-4 | The immutable record contains no natural-person identifiers; personal data lives only in the mutable layer | S1, S5, C2 |
| SP-5 | High-impact governance changes require dual control and take effect only after they are anchored | S7, S8 |
| SP-6 | Read access to consortium data is audited per organisation; platform staff access requires break-glass with recording | S6, S9 |
| SP-7 | Regulatory analytics cannot read arbitrary private evidence, and findings are private by default | S6, S7, R8 |
| SP-8 | The system states what it does not protect against, rather than implying universal security | S6, S11 |

## 2.8 CIA triad, critical scenarios and regulatory requirements

### 2.8.1 Confidentiality

**Requirement.** Content is readable only by the parties the owner chose, and by the platform only for
consortium-class data under audit. **Scenarios.** A competitor must not read another participant's volumes;
a journalist must not obtain raw telemetry; a platform engineer must not read private findings.
**Mechanism.** Three classes with no middle tier; content encryption by the owner for private evidence;
consortium plaintext encrypted at rest in an archive outside the operator's account; per-request
organisation binding; audited reads; break-glass for platform staff.

**Limits, stated explicitly.** The platform's runtime is authorised to read consortium plaintext, so a
compromised runtime can leak consortium data. The design does not claim to prevent that; it reduces the
window with least privilege, short-lived credentials, audit and rate limits.

### 2.8.2 Integrity

**Requirement.** A confirmed record cannot be altered or removed without detection by a party that does not
trust the operator. **Scenarios.** Operator pressure to delete a batch; a storage provider silently
replacing bytes; a participant repudiating a claim. **Mechanism.** Signed payload digests; an archive
acknowledgement signed by an independent holder over the exact stored bytes; deterministic Merkle batching
with a verifiable sequence; inclusion proofs; append-only correction rather than update.

### 2.8.3 Availability

**Requirement.** Safety-relevant queries never return a false negative because a dependency is down.
**Scenarios.** Archive outage during a recall; public chain congestion; analytics unavailable.
**Mechanism.** Failure semantics declared per dependency; writes fail closed and resume idempotently; reads
continue from materialised data with a visible watermark; safety queries fail closed when freshness cannot
be established; analytics is an optional dependency that is never in the write path.

### 2.8.4 Regulatory requirements

| Obligation | Architectural consequence |
|---|---|
| Food safety duties and recall powers (NSW Food Act 2003; Food Standards Code) | Conservative recall traversal, signed official notices, publication of pending-anchor notices, clear separation of "possibly affected" from "confirmed unsafe" |
| Australian Privacy Principles / NSW PPIPs | No personal identifiers in the immutable trace; minimisation at ingestion; correction and deletion in the mutable layer; breach-notification-ready audit |
| Records retention and legal hold | Per-class retention, terminal deletion states, anchored deletion records |
| Evidentiary expectations (chain of custody, authentication) | Signed declarations, independent acknowledgement, inclusion and consistency proofs, reproducible derivation |
| Procurement and residency expectations for government data | Australian regions for non-public data; analytics in the regulator's own account |

## 2.B AI/ML and IoT requirements (bonus)

### 2.B.1 Requirements and scenarios

**IoT-1 — Sensor summary, not telemetry.** The shared record carries summaries required by the product
profile (min/max/mean, excursion duration, source-reported alarm); raw readings stay private.
**IoT-2 — Device identity without a platform account per sensor.** Devices are registered as organisation
delegations, not as platform users.
**IoT-3 — Three latency tiers.** Real-time collection at the edge; near-real-time availability after
receipt; final verifiability after confirmation. Cold-chain response is local, at the participant, and the
platform's alarm is post-confirmation.
**AI-1 — Deterministic rules first.** Screening rules are deterministic, versioned and signed by the
regulator; ML is optional and never gates a write.
**AI-2 — Explainability and reproducibility.** Every finding names its rule or model version and its input
watermark; a finding cannot be produced from data the platform cannot reproduce.
**AI-3 — Human decision.** No model output becomes a recall decision without a signed assessment by an
authorised officer.

**IS-1 — Cold-chain excursion.** A reefer's temperature exceeds the limit for 40 minutes in transit. *Path:*
the participant's IoT platform raises the local alarm and acts; a summary and reference are attached to the
receiving claim; the regulator's analytics may later flag the lot. *Requirement:* the platform must not be
the primary alarm path, and the summary must be reproducible from the private raw data at dispute time.

**IS-2 — Cross-assertion anomaly.** A packer's output volumes exceed plausible inputs across a season.
*Path:* the regulator's deterministic rules over confirmed claims produce a private finding; an officer
reviews it; optionally a signed advisory goes to the subject organisation. *Requirement:* the platform must
supply enough minimised data for the rule, and must not be able to read the rule.

**IS-3 — Model-assisted screening (later).** A classifier prioritises handover anomaly review. *Path:*
trained on a snapshot, evaluated offline, run in the regulator's domain, with a human review queue; no
automated action. *Requirement:* model version, training snapshot identity and evaluation result must be
recorded and reproducible.

### 2.B.2 Alternatives rejected

| Alternative | Why rejected |
|---|---|
| Uploading raw telemetry to the platform | Would turn the traceability layer into a time-series warehouse, create privacy exposure and make retention unmanageable; summary plus commitment satisfies the requirement |
| Real-time platform-side cold-chain alerting | Adds a hard latency requirement to the write path and duplicates the participant's own control loop; the platform's role is assurance, not process control |
| ML in the write path (auto-reject or auto-flag events at admission) | Makes a model an adjudicator, contradicts the requirement that the core records assertions, and makes admission non-deterministic and unreproducible |
| Training models on the platform's own copy of consortium data | The platform would need to read data it should not own as a training asset; training data is produced as a minimised, purpose-bound snapshot in the regulator's domain |
| Edge ML on participant gateways for compliance decisions | Puts the compliance logic where it cannot be versioned, audited or signed by the regulator |
