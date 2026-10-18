# 2. Requirements Analysis

*Identifiers trace to the stakeholders `S1`–`S12` and objectives `O1`–`O8` in Section 1.*

## 2.1 System qualities and quality requirements

### 2.1.1 From stakeholder interests to qualities

Eleven qualities drive the design. Four decide its shape — integrity (S6, S9, S11), privacy (S1, S5, S6),
availability (S4–S6) and analysability (S1–S4, S6); the other seven — non-repudiation, performance,
recoverability, usability and accessibility, interoperability, auditability, cost — constrain how it is built.
Stakeholder by stakeholder, the justification is in 1.2.

### 2.1.2 Quality requirements

| ID | Quality | Requirement | Measure / acceptance | Stakeholders |
|---|---|---|---|---|
| SQ-1 | Integrity | A confirmed event cannot be altered or removed without detection by a party that distrusts the operator | Detectable from published proofs alone | S6, S9, S11 |
| SQ-2 | Non-repudiation | Attribution survives rotation, revocation and suspension | Verifiable from the event and registry history alone | S1–S4, S6, S11 |
| SQ-3 | Availability | One dependency lost degrades a capability, never to a false "no record" | Fault injection yields a declared state and a visible marker | S4, S6 |
| SQ-4 | Performance | Reads at the edge; traversal bounded | 5 000 requests/s at the CDN; 10 000 synchronous edges | S5, S6 |
| SQ-5 | Recoverability | Trace rebuilt without the platform database | RPO 0 receipted; database RPO ≤ 5 min; RTO ≤ 4 h; region ≤ 24 h | S6, S10, S11 |
| SQ-6 | Usability and accessibility | A first-time smallholder captures without training; every screen works for low literacy or low vision | Under three minutes at 2G; WCAG 2.2 AA; 200 % text; label plus icon per field | S1, S4 |
| SQ-7 | Privacy | No natural-person reference, no private content in the shared record | Schema check at admission; privacy review of profiles | S1, S5, S6 |
| SQ-8 | Interoperability | EPCIS 2.0 / CBV; versioned profiles; replaceable chain | Interpretable from profile and canonicalisation version alone | S2, S3, S11 |
| SQ-9 | Auditability | Every state change and disclosure is attributable and reproducible | Replay reproduces derivation and advisories | S6, S7, S11 |
| SQ-10 | Cost and operability | One application, one managed database, no self-managed cluster | Topology and monthly estimate documented | S9 |
| SQ-11 | Device evidence | Profile-required summaries with provenance; raw telemetry private | A summary resolves to publisher and to private raw data | S1, S3, S12 |
| SQ-12 | Regulatory screening | Signed, versioned regulator rules; ML optional | A rule runs at a watermark and traces to its version | S6, S7 |
| SQ-13 | Analysability | Insight views over confirmed data, inside the scoped read path | Every view states watermark and scope | S1–S4, S6 |

## 2.2 Scenarios, risks and rejected alternatives

### 2.2.1 Quality attribute scenarios

Each is source, stimulus, artefact, environment, response and measure; the measure is what the design is judged
against.

- **QS-1 Tamper (SQ-1).** An operator deletes a batch; the missing batch breaks the chain sequence. *Measure:*
  detection without the platform's cooperation.
- **QS-2 Attribution (SQ-2).** An event is verified three years after its signer rotated twice and was
  suspended. *Measure:* current key status is irrelevant to verification.
- **QS-3 Degradation (SQ-3).** A recall runs at 02:00 during an archive outage. *Measure:* the window that
  cannot be confirmed is marked, never reported as "no record".
- **QS-4 Burst (SQ-4).** 5 000 scans/s arrive after a television item. *Measure:* the origin sees a fraction; no
  read touches canonical tables.
- **QS-5 Recovery (SQ-5).** The platform account is lost after a receipt. *Measure:* the trace rebuilds from
  archive and chain alone.
- **QS-6 Capture (SQ-6).** A grower with no signal for 36 hours captures four events on a low-end phone.
  *Measure:* queued, idempotent on reconnect, under three minutes.
- **QS-7 Evidence (SQ-7).** A regulator asks a packer for a laboratory report. *Measure:* delivery is provable
  against the commitment; the platform holds no plaintext.
- **QS-8 Isolation (SQ-7, SQ-9).** Operations try to read regulator findings. *Measure:* no credential path
  exists, and the attempt is recorded.
- **QS-9 Conflict (SQ-1, SQ-9).** Two processors claim one input lot. *Measure:* both appear with provenance.
- **QS-10 Migration (SQ-8).** The chosen chain becomes uneconomic. *Measure:* old proofs verify; nothing is
  re-signed.
- **QS-11 Analytics down (SQ-12).** A case is opened during maintenance. *Measure:* trace continues; risk shows
  as delayed, never "no risk".
- **QS-12 Cold chain (SQ-11).** A reefer exceeds its limit for 40 minutes. *Measure:* the summary is checkable
  against the owner's raw log.
- **QS-13 Review (SQ-13).** A category manager reviews a product line at yesterday's watermark. *Measure:*
  every figure resolves to confirmed events.

### 2.2.2 Risks, decisions and rejected alternatives

| Quality | Risk if unaddressed | Decision taken | Alternative rejected, and why |
|---|---|---|---|
| Integrity | The operator, or an attacker with its credentials, rewrites history silently | Public Merkle root plus an acknowledgement from outside the operator's account | **Database plus WORM backup** leaves the operator sole verifier; **permissioned ledger** needs validators we do not have (R1) |
| Non-repudiation | Rotation or compromise makes old claims unattributable | One envelope for all custody modes; key history retained; past events never rewritten | **Platform-held participant key** allows impersonation (R2); **per-employee keys** put people in an immutable record (R5) |
| Availability and performance | An outage returns "nothing found"; bursts overwhelm the origin | Declared failure states; reads from materialised data; edge snapshots; bounded traversal | **Synchronous dependency calls** make any outage a product outage; **graph database day one** has no workload evidence |
| Privacy | An immutable log becomes an unlawful personal-data store | No natural-person fields; private content off-platform behind a salted commitment | **Field-level encryption** leaves the platform holding keys; **per-event access lists** are unenforceable if it cannot read |
| Analysability | Insight views drift into a second, disagreeing read path | Views served from the confirmed projection at a named watermark | **A separate dashboard database** adds a consistency boundary where stale figures look authoritative |

Plausibility — yield, loss, mass balance, fraud — is not adjudicated at admission: a rule that rejected an event
because a quantity looked wrong would make the platform an adjudicator without authority or observation.

## 2.3 Data management requirements and dictionary

### 2.3.1 Data requirements

| ID | Requirement | Stakeholders |
|---|---|---|
| DM-1 | An event is interpretable from the event, its profile and its canonicalisation version | S2, S3, S11 |
| DM-2 | Private and commercial content never stored readable on the platform | S1, S4, S6 |
| DM-3 | One authoritative source per element; derived copies rebuildable | S6, S9, S11 |
| DM-4 | Retention per data class, with hold and a defensible deletion record | S6, C2 |
| DM-5 | No natural-person identifiers in the immutable trace | S1, S5, C2 |
| DM-6 | Regulatory outputs carry rule version and input watermark | S6, S7 |

### 2.3.2 Data dictionary

One or two elements per group are tabulated; the rest of each group is named below and follows the same rules.
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

The remaining elements are named only, grouped by what they carry: EPCIS business content (`action`, `bizStep`,
`disposition`, `bizLocation`, `readPoint`, `sourceList`/`destinationList`, `bizTransactionList`, `epcClass`,
`parentID`/`childEPCs`, `transformationID`); versioning (`canonicalisationVersion`, `edgeDerivationVersion`);
the signature pair (`keyId`, `signatureValue`, `signatureAlgorithm`, `assertedSignedAt`); custody
(`custodyMode`); anchoring (`ArchiveAckDigest`, `ciphertextDigest`, `merkleLeafIndex`, `batchId`, `merkleRoot`,
`transactionRef`, `inclusionProof`); evidence state (`availabilityStatus`, `retentionPolicyId`); and regulatory
output (`severity`/`reasonCodes`, `disclosureScope`, `expiresAt`, `regulatorSignature`). Each is EPCIS/CBV-defined
or profile-declared, typed and length-bounded at admission.

## 2.4 Data scenarios, storage, access and retention

### 2.4.1 Data scenarios

- **DS-1 Recall (DM-1, DM-3).** A retail lot traced to a farm block seven years on; every hop reproduces from
  canonical events and the versioned rules.
- **DS-2 Competing claims (DM-3).** Two processors consume one input; both edges are stored and returned side by
  side, never ranked.
- **DS-3 Disclosure (DM-2).** The owner encrypts a requested report to the regulator's key; the platform proves
  delivery without holding plaintext.
- **DS-4 Scan (DM-2).** 5 000 scans/s served from versioned objects, never by joining canonical tables.
- **DS-5 Retention hold (DM-4).** Deletion is a recorded transition after the hold lifts, proven by a signed
  record; premature deletion is externally visible.
- **DS-6 Revoked key (DM-3).** Events queued offline arrive after rotation and enter review, because "invalid"
  and "not yet established" are different facts.

### 2.4.2 Validation rules

| Class | Examples | Effect |
|---|---|---|
| Admission | Profile conformance, digest reproducibility, signature and authority, idempotency, transitions | **Blocks** the write |
| Structural representability | Two claims over one object, competing parents, unknown references, cycles in time | **Does not block**; shapes presentation |

### 2.4.3 Storage choice: relational, append-only canonical tables

One managed relational database holds submission state, registries, the outbox, a queryable materialisation and
rebuildable projections. EPCIS fields are typed and constrained, admission needs one atomic step across event,
idempotency claim and outbox, traversal is a bounded recursive query over 10 000 edges, and reporting is
set-oriented.

| Alternative | Why rejected |
|---|---|
| Document store per event | Gives up cross-event constraints, decimal exactness and multi-row transactions; JSON survives inside a relational column |
| Graph database as the record | The graph is derived; storing it as truth makes derivation unverifiable |
| Event sourcing for the application | Profiles and job state are not events |
| Lake or warehouse as primary store | 10 000 events/day does not justify it |

### 2.4.4 Access control

| Class | Content | Reader | Platform reads plaintext |
|---|---|---|---|
| Public | Allowlisted projection, signed notices | Anyone | Yes — it generates it |
| Consortium | Canonical trace, handover, sensor summaries | Consortium members | Yes, under audit |
| Private | Raw telemetry, reports, contracts | Owner and its chosen recipients | **No** |

There is no middle class: content queried by field joins the consortium class, content that must stay private
stays off the platform. Access binds per request to an explicit acting organisation.

### 2.4.5 Retention and deletion

Retention is set per data class, with seven years as the pilot's canonical-trace assumption, adjustable by
product, jurisdiction and hold. Deletion is a three-party process: the platform requests, the archive holder
verifies the policy and executes, and anything earlier needs dual control; the signed record is anchored, so a
premature deletion is visible rather than silent.

### 2.4.6 Ingestion requirements

Ingestion is idempotent on a client-generated identifier, persists state and enqueues side effects in one step,
produces a deterministic digest, and parks unverifiable authority in review rather than calling it invalid.

### 2.4.7 Data management system requirements

| ID | Requirement | Why |
|---|---|---|
| DB-1 | Multi-row ACID transactions and referential integrity | Event, idempotency claim and outbox commit together; corrections reference events and leaves reference batches |
| DB-2 | Exact decimal arithmetic and units | Quantities are never rounded silently (S2) |
| DB-3 | Recursive queries with index support | Bounded traversal (SQ-4) |
| DB-4 | Semi-structured columns for declared extensions | Profiles add fields without migration (DM-1) |
| DB-5 | Point-in-time recovery, row-level predicates, audited reads, managed operation | Rebuildable but not losable, scope at the data layer, no database fleet (SQ-5, SP-6, SQ-10) |

## 2.5 Cloud-adoption requirements

| ID | Requirement | Stakeholders |
|---|---|---|
| CL-1 | No capital expenditure, no infrastructure team | S1, S9 |
| CL-2 | Elastic capacity for consumer bursts | S4, S5 |
| CL-3 | Australian residency, cross-failure-domain durability | S6, C2 |
| CL-4 | Separable control domains for analytics, archive and keys | S6, S10, R2 |
| CL-5 | Managed identity, keys, audit logging, patching | S9 |
| CL-6 | Portable formats, replaceable chain | S9, R9 |

## 2.6 Cloud scenarios and XaaS choices

A harvest peak brings a 5–10× write and 100× read spike, absorbed by a managed database and a CDN. The regulator
requires analytics in its own account, deployed as artefacts and operated by the regulator. If the platform
account is lost, recovery runs on the archive, a trustee-held recovery identity and the chain.

| Capability | Service model | Why |
|---|---|---|
| Application and workers | Managed containers | No cluster operations; horizontal workers |
| Relational store | Managed database | Backup, PITR, patching, HA delegated |
| Public delivery | Object storage plus CDN | Absorbs bursts; immutable versioned objects |
| Archive and keys | WORM and KMS in a trustee account | Wrap and unwrap, never administer or delete |

| Alternative | Why rejected |
|---|---|
| IaaS with self-managed clustering | Patching, HA and backup onto a six-person team (CL-1, SQ-10) |
| Self-managed Kubernetes | No scaling requirement justifies a cluster (C5) |
| One account for everything | One administrator in reach of every control plane (R2, CL-4) |
| Managed blockchain service | Validator membership the project cannot populate (R1) |

## 2.7 Security and privacy requirements

| ID | Requirement | Stakeholders |
|---|---|---|
| SP-1 | Every write authorised against organisation, role and delegation, per request | S1–S4, S6 |
| SP-2 | Every canonical event non-repudiable across rotation and revocation | S6, S11 |
| SP-3 | Private content never readable by the platform; the owner grants sharing | S1, S4, S6 |
| SP-4 | No natural-person identifiers in the immutable record | S1, S5, C2 |
| SP-5 | High-impact governance changes need dual control and apply once anchored | S7, S8 |
| SP-6 | Reads audited per organisation; staff access needs recorded break-glass | S6, S9 |
| SP-7 | Analytics cannot read arbitrary private evidence; findings private by default | S6, S7, R8 |
| SP-8 | The system states what it does not protect against | S6, S11 |

## 2.8 CIA triad, critical scenarios and regulation

| Quality | Requirement | Mechanism | Stated limit |
|---|---|---|---|
| Confidentiality | Content readable only by the parties the owner chose | Three classes with no middle tier; owner-encrypted evidence; per-request organisation binding; audited reads | The runtime reads consortium plaintext, so a compromised runtime can leak it; least privilege narrows the window, not closes it |
| Integrity | A confirmed record cannot change without detection | Signed digests; holder-signed acknowledgement; deterministic Merkle batches; inclusion proofs | Detection needs someone to check; the design makes checking cheap, not automatic |
| Availability | Safety queries never return a false negative | Declared failure states; writes fail closed; reads from materialised data with a visible watermark | A long platform outage still stops ingestion; the archive preserves what was receipted |

**Regulation.** The NSW Food Act 2003 and the Food Standards Code require conservative recall traversal, signed
notices, and a clear split between "possibly affected" and "confirmed unsafe". The Australian Privacy Principles
and NSW PPIPs require no personal identifiers in the immutable trace, minimisation at ingestion, and correction
and deletion in the mutable layer. Records law requires per-class retention and anchored deletion records;
evidentiary expectations require chain of custody and reproducible derivation; government procurement requires
Australian regions for non-public data and analytics in the regulator's own account.

## 2.B AI/ML and IoT requirements (bonus)

**IoT-1 Summary, not telemetry.** Profile-required summaries only; raw readings stay private.
**IoT-2 Device identity without an account per sensor.** Devices are organisation delegations.
**IoT-3 Three latency tiers.** Collection at the edge, availability after receipt, verifiability after
confirmation; the cold-chain loop is local, the platform's alarm post-confirmation.
**AI-1 Deterministic rules first.** Versioned and signed by the regulator; ML optional, never gating a write.
**AI-2 Reproducibility.** Every finding names its rule or model version and its input watermark.
**AI-3 Human decision.** No model output becomes a recall decision without a signed assessment.

**IS-1 Cold-chain excursion.** The participant's system alarms and acts; a summary and reference ride on the
receiving claim; the platform is not the primary alarm path.
**IS-2 Cross-assertion anomaly.** The regulator's rules produce a private finding over confirmed claims; the
platform supplies minimised data and cannot read the rule.

| Alternative | Why rejected |
|---|---|
| Raw telemetry on the platform | Turns the trace into a time-series warehouse; privacy exposure; unmanageable retention |
| Platform-side real-time alerting | Adds a hard latency requirement and duplicates the participant's control loop |
| ML in the write path | Makes a model an adjudicator; training data is a purpose-bound snapshot in the regulator's domain |
