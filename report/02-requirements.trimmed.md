# 2. Requirements Analysis

*Identifiers trace to the stakeholders `S1`–`S12` and objectives `O1`–`O8` in Section 1.*

## 2.1–2.2 System qualities, scenarios and risks

Eleven qualities drive the design. Four decide its shape — integrity (S6, S9, S11), privacy (S1, S5, S6),
availability (S4–S6) and analysability (S1–S4, S6); the other seven constrain how it is built. Each row
states the requirement as a measurable test, the scenario that exercises it, and the risk if it is not met.

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
| SQ-10 | Cost and operability | One application, one managed database, no self-managed cluster; topology and monthly estimate documented | Checked by inspection of the deployment views (4.14–4.15) | The pilot needs a platform team per region |
| SQ-11 | Device evidence | Profile-required summaries with provenance; raw telemetry stays private | QS-12: a reefer exceeds its limit for 40 minutes | Raw telemetry enters the record, or evidence is missing where it matters |
| SQ-12 | Regulatory screening | Signed, versioned rules; ML optional; a rule runs at a watermark and traces to its version | QS-11: a case is opened while the workspace is under maintenance | Screening is either platform-owned or absent |
| SQ-13 | Analysability | Every insight view states its watermark and scope; figures reproduce from the projection | QS-13: a product line is reviewed at yesterday's watermark | Insight becomes a second, disagreeing read path |

Rejected while setting these requirements: database plus WORM backup (leaves the operator the sole verifier);
a permissioned ledger (needs validators this project does not have, R1); per-employee signing keys (puts
natural persons into an immutable record, R5); synchronous calls to every dependency on the read path; a
graph database from day one; field-level encryption inside the shared record (the platform would still hold
the keys); and a separate dashboard database. Business plausibility — yield, mass balance, fraud — is
deliberately not adjudicated at admission: a rule that rejected an event because a quantity looked wrong
would make the platform an adjudicator without authority. The decisions that address each risk are argued in
4.1–4.5, and the alternatives that survive as alternatives are revisited in 5.4.

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

## 2.5–2.6 Cloud adoption

The platform is PaaS: one managed container service running the application and the workers, a managed
relational database with a read replica and automatic scaling, object storage behind a CDN for public snapshots,
and a managed KMS in the trustee's account. Participants need no infrastructure — a browser is enough — and the
operator needs no cluster: no self-managed Kubernetes, no message broker, because at pilot scale both add
operations without adding capability. The regulator's analytics workspace is deployed as artefacts into its own
account and operated there, because the point of the separation is that the platform cannot read it. Residency,
exit and cost follow from the same choices: Australian regions, standard PostgreSQL, portable formats.

## 2.7 Security and privacy requirements

Every write is authorised against an organisation, a role and a delegation, bound per request (SP-1), and every
canonical event is non-repudiable across rotation and revocation (SP-2). The platform never reads private
content — the owner grants sharing (SP-3) — and no natural-person identifier enters the immutable record (SP-4).
High-impact governance changes need dual control and apply only once anchored (SP-5). Reads are audited per
organisation, and staff access needs recorded break-glass (SP-6). Analytics cannot pull arbitrary private
evidence, and findings are private by default (SP-7). The system states what it does not protect against (SP-8).

## 2.8 Confidentiality, integrity, availability and regulation

**Integrity is guaranteed by the public chain.** A Merkle root is committed every thirty minutes, and any third
party can verify an event against it without asking the platform (NSW Food Act 2003; Food Standards Code).

**Confidentiality is a three-tier tradeoff.** Public projections, consortium trace, and owner-held private
evidence; the platform reads consortium plaintext because recall traversal needs it, and cannot read private
content at all (Privacy Act 1988 and the APPs; NSW PPIP Act 1998).

**Availability comes from read/write separation.** Writes fail closed and retry idempotently; reads come from the
materialised copy with an explicit degradation state, so a recall query during an archive or chain outage returns
a labelled partial result rather than a silent miss (Food Act 2003 recall powers).

Appendix B maps each obligation behind those citations to where the design answers it.

## 2.B AI/ML and IoT requirements (bonus)

**IoT-1 summaries, not telemetry; IoT-2 devices as organisation delegations, not accounts; IoT-3 collection at
the edge, availability at the platform, verifiability at the archive.** The cold-chain loop is local, so the
platform's alarm is post-confirmation.

**AI-1 deterministic rules first, versioned and signed by the regulator, with ML optional and never gating a
write; AI-2 every finding names its rule or model version and its input watermark; AI-3 no model output becomes
a recall decision without a signed assessment.**

**IS-1 Cold-chain excursion.** The participant's system alarms and acts; a summary and reference ride on the
receiving claim; the platform is not the primary alarm path.
**IS-2 Cross-assertion anomaly.** The regulator's rules produce a private finding over confirmed claims; the
platform supplies minimised data and cannot read the rule.

| Alternative | Why rejected |
|---|---|
| Raw telemetry on the platform | Turns the trace into a time-series warehouse; privacy exposure; unmanageable retention |
| Platform-side real-time alerting | Adds a hard latency requirement and duplicates the participant's control loop |
| ML in the write path | Makes a model an adjudicator; training data belongs in the regulator's domain |
