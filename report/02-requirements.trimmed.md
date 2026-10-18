# 2. Requirements analysis

The three gaps of Section 1 become obligations here: what must be checkable, what must stay unreadable, and what
must survive loss.

*Identifiers trace to the stakeholders `S1`–`S12` and objectives `O1`–`O8` in Section 1.*

## 2.1 System qualities, and the scenarios that test them — rubric 2.1–2.2

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
| SQ-10 | Cost and operability | One application, one managed database, no self-managed cluster; topology and monthly estimate documented | Checked by inspection of the deployment views (§4.3) | The pilot needs a platform team per region |
| SQ-11 | Device evidence | Profile-required summaries with provenance; raw telemetry stays private | QS-12: a reefer exceeds its limit for 40 minutes | Raw telemetry enters the record, or evidence is missing where it matters |
| SQ-12 | Regulatory screening | Signed, versioned rules; ML optional; a rule runs at a watermark and traces to its version | QS-11: a case is opened while the workspace is under maintenance | Screening is either platform-owned or absent |
| SQ-13 | Analysability | Every insight view states its watermark and scope; figures reproduce from the projection | QS-13: a product line is reviewed at yesterday's watermark | Insight becomes a second, disagreeing read path |

Rejected while setting these requirements: database plus WORM backup (leaves the operator the sole verifier);
a permissioned ledger (needs validators this project does not have, R1); per-employee signing keys (puts
natural persons into an immutable record, R5); synchronous calls to every dependency on the read path; a
graph database from day one; field-level encryption inside the shared record (the platform would still hold
the keys); and a separate dashboard database. Business plausibility — yield, mass balance, fraud — is
deliberately not adjudicated at admission: a rule that rejected an event because a quantity looked wrong
would make the platform an adjudicator without authority. The decisions that address each risk are argued in §4.1,
and the alternatives that survive as alternatives are revisited in §5.1.

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

Named but not tabulated: the EPCIS business fields (`action`, `bizStep`, `disposition`, `bizLocation`,
`readPoint`, `sourceList`/`destinationList`, `bizTransactionList`, `epcClass`, `parentID`, `transformationID`);
the versioning pair (`canonicalisationVersion`, `edgeDerivationVersion`); the signature set (`keyId`,
`signatureValue`, `signatureAlgorithm`, `assertedSignedAt`); `custodyMode`; the anchoring set (`ArchiveAckDigest`,
`ciphertextDigest`, `merkleLeafIndex`, `batchId`, `merkleRoot`, `transactionRef`, `inclusionProof`); evidence
state (`availabilityStatus`, `retentionPolicyId`); and regulatory output (`severity`, `disclosureScope`,
`expiresAt`, `regulatorSignature`). Each is EPCIS/CBV-defined or profile-declared, typed and length-bounded at
admission.

**Scenarios.** Each one fixes a requirement that would otherwise be a design preference.

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

DS-3 and DS-4 fix the three visibility classes — public projection, consortium trace, owner-held private
evidence, with no middle tier — and access binds per request to an explicit acting organisation. DS-6 fixes
validation's two classes: admission blocks the write, while structural representability only shapes how the
projection presents the data. Business plausibility stays out of admission, because a rule that rejected an
event for an odd quantity would make the platform an adjudicator.

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

Four scenarios decide the service model. QS-4 (5 000 scans/s after a television item) asks who serves the bytes: an
origin cannot, so delivery is a CDN service, not a server. DS-3 (a regulator requests a packer's report) asks who
holds the content: not the platform, so object storage sits under a separate provider. QS-8 asks who operates the
workspace, and C6 how much is operated at all.

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

**Confidentiality is a three-tier tradeoff.** Public projection, consortium trace, owner-held private evidence,
with no middle tier. The platform reads consortium plaintext because recall traversal needs it, and never reads
private content — the owner grants sharing (SP-3) — while no natural-person identifier enters the immutable
record (SP-4). Privacy Act 1988 and the APPs; NSW PPIP Act 1998.

**Availability comes from read/write separation.** Writes fail closed and retry idempotently; reads come from the
materialised copy with an explicit degradation state, so a recall query during an archive or chain outage returns
a labelled partial result rather than a silent miss (Food Act 2003 recall powers).

Appendix B maps each obligation behind those citations to where the design answers it.

## 2.5 Device evidence and regulatory screening — rubric 2.B, bonus

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
