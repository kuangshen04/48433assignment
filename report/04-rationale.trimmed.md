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
| Modular monolith, layered inside | The one deployable | Operability (SQ-10), modifiability | Services: broker, sagas, platform team (§5.1, A4) |
| Ports and adapters at every external edge | Archive, KMS, chain, identity | Replaceability (SQ-8) | Direct SDK calls bind the leaf to one chain |
| Transactional outbox | Admission through to archive | Reliability, RPO 0 (SQ-5) | Two-phase commit across services |
| Read model derived from the log | `QueryStore`, public snapshots | Performance (SQ-4), privacy (SQ-7) | Decrypt per hop; per-field policy on immutable records |
| State machine with anchored transitions | `ConfirmationStatus` | Integrity (SQ-1), auditability (SQ-9) | A boolean `processed` flag |
| Versioned contracts, published enumerations | Profiles, code view | Interoperability (SQ-8) | Free-form strings, silent value drift |

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

**D5. One relational database, append-only canonical tables.** EPCIS fields are typed, admission needs one atomic
step, traversal is a bounded recursive query and reporting is set-oriented (DM-1, SQ-4). A document store would
lose cross-event constraints and multi-row transactions, a graph database would make the derived graph the truth,
and event sourcing would model profiles and job state as events they are not.

The model that follows: a submission materialises one canonical event; an event validates against one profile
version, is acknowledged by one or more holders, commits as one leaf and references zero or more evidence records;
a batch holds many leaves and chains to its predecessor.

![Figure 9 — Physical data model](../docs/public/diagrams/core-physical-model.svg)

*Figure 9 — Eight tables; the constraints that matter are named below.*

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

**C1. Managed services, one image running as application or worker.** A six-person team for one semester has no
operations capacity; IaaS with a self-managed cluster would move patching, HA and backup onto it.

**C2. Four accounts, delivered declaratively.** This is what makes "the platform can deploy into the regulator's
account but cannot read from or operate it" a property of the pipeline; one account would put an administrator in
reach of every control plane.

**C3. One region with warm copies, one primary with a reader, and an isolated relayer.** The availability target is
met without active-active; the relayer holds the only credential that can spend money, so it has no inbound path
and a single instance.

![Figure 10 — Logical deployment](../docs/public/diagrams/c4-deployment.svg)

*Figure 10 — Logical placement: which control domain owns which node.*

![Figure 11 — Reference deployment](../docs/public/diagrams/c4-reference-deployment.svg)

*Figure 11 — A configuration that can be procured and built.*

The logical view answers who owns what; the reference view answers what we would buy. Seven workloads, each with
one credential and one scaling unit: application and workers on request rate and outbox lag, the database as a
managed primary with a reader, archive and KMS in a trustee account, public delivery behind a CDN.

## 4.4 The write path and the recall path — rubric 4.16–4.17

![Figure 12 — Dynamic view: event acceptance](../docs/public/diagrams/c4-dynamic.svg)

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

Step 16 is the submitter reading the event back; the consumer read comes from the CDN at step 15 and never reaches
the application.

![Figure 13 — Dynamic view: recall investigation](../docs/public/diagrams/c4-dynamic-recall.svg)

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
regulator mirror (SP-7). SP-8 states the rest in the interface.

No personal field in the record means deletion never negotiates with immutability; content off the platform means
there is nothing to compel; classification by construction means no "sensitive but shared" tier can appear. Three
risks remain stated rather than mitigated: a compromised runtime, a resourced colluder, and a holder's own legal
obligations.

## 4.6 Device evidence and screening, in the architecture — rubric 4.B, bonus

**AI.** Screening runs in the regulator's workspace over signed rule versions: a model is an alternative
implementation of the same interface, which is why the first release has no model loader. Every finding carries
its rule or model version and input watermark, so it reproduces; no output becomes an action without an officer's
signature. Rejected: ML at admission (makes a model an adjudicator) and training on the platform's own copy.

**IoT.** The boundary sits at the participant: profile-required summaries enter the record, raw readings stay
behind a commitment, and devices are organisation delegations rather than users. Collection and alarming are
local, availability is the platform's, verifiability is the archive's. Rejected: raw telemetry upload and
platform-side real-time alerting, which would duplicate the participant's control loop.
