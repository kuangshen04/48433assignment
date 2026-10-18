# 4. Architectural Rationale and Decision-Making

Section 3 states what the structure is; this section states why it is that structure — which quality each
decision buys, which pattern carries it, and what was rejected.

## 4.1–4.5 Application architecture: the decisions

The application layer is eight decisions. Each was taken for a reason of its own; the qualities, tactics,
patterns and principles that 4.1–4.5 ask about are what those decisions happen to satisfy, not the other way
round.

1. **One deployable, split by role rather than by service.** The core holds mechanism, six modules hold business
   semantics, and one image runs as application or worker (modular monolith). A service per concern would add a
   broker, sagas and an operational platform to serve 10 000 events/day — cost without capability.
2. **One write path, with an outbox.** Admission validates, persists state, claims the idempotency key and
   enqueues the archive intent in a single transaction; workers drain the outbox (transactional outbox). A crash
   at any point resumes rather than duplicates.
3. **One read entrance.** Modules read only through `QueryPort`, which enforces scope, non-collapsing and a
   watermark and offers one-hop edges plus a bounded traversal, nothing else (single façade). Two cohesive
   operations, no method that returns a business status.
4. **Append-only canonical records, everything else derived.** Corrections are new events; lineage, recall and
   public views are rebuilt from the log, and every projection carries a watermark so derivation is replayable
   (CQRS-lite; observability).
5. **Notarised anchoring.** Every thirty minutes the relayer commits a Merkle root; the archive, not the
   database, is the copy of record. Anchoring is how the chain earns its place: it proves existence, not truth.
6. **Ports at every external edge.** Archive, KMS, chain and identity are interfaces with adapters, and the leaf
   binds digests rather than chain specifics (ports and adapters), so a provider or chain can change without a
   domain edit.
7. **Signature and authority are separate checks.** One envelope covers all custody modes; one verifier checks
   the signature, and a separate resolver decides whether that organisation was authorised *at signing time*
   (admission gates). Merging them would make a profile release look like a security change.
8. **The signer is isolated.** Only the relayer holds the chain wallet, and it has no inbound path and cannot
   read payloads (isolated signer). This is the one deliberate inversion: chain-specific code is confined there
   rather than hidden behind a port.

Read against the criteria, these decisions answer four questions at once. **4.1** — where each quality is met — is
visible in the decision that names it. **4.2** — tactics — are the mechanisms in italics above: fail closed and
retry, move work off the request path, localise change, enforce at one point. **4.3** — patterns — are the
parenthesised names, each chosen over a rejected alternative recorded in Section 5.4. **4.4** and **4.5** are the
properties the decisions were tested against: responsibilities split by reason to change (SRP: canonicalisation
separate from signature validation), new custody modes and profiles as additions rather than branches (OCP), four
custody modes behind one envelope (LSP), a two-operation read interface (ISP), dependencies pointing at
interfaces (DIP, with the relayer as its deliberate exception); and no feature concentration (the core is
mechanism), no scattered enforcement (one verifier, one state machine, one read entrance), no cycle (modules →
`QueryPort` → store), and no unstable dependency (vendors live in adapters).

## 4.6–4.10 Data: seven decisions

The data layer is seven decisions. Four are forks between plausible alternatives; three follow from the
requirements and are recorded only for their reason.

**D1. The archive is the copy of record; the database is not.** *Why:* no single party, including the operator,
may be able to destroy confirmed history, which is also what makes RPO 0 possible (DM-3). *Rejected:* database
plus WORM backup in the platform's own account, which leaves the operator as the sole verifier.

| Data role | Container | Rebuildable? |
|---|---|---|
| Operational record | Operational PostgreSQL | Yes, from canonical events |
| Queryable canonical copy | PostgreSQL (`QueryStore`) | Yes; excluded from the recovery guarantee |
| Authoritative payload | External archive | **No** — this is the copy of record |
| Public data mart | Snapshot origin plus CDN | Yes |
| Analytical mart | Insights materialised views inside PostgreSQL | Yes |
| Regulatory data | Analytics stores, regulator account | Rules signed and reproducible; findings evidential |

**D2. Keep a plaintext query copy inside the platform.** *Why:* lineage cannot decrypt on every hop, and scope has
to be enforced locally; the copy is rebuildable, read-audited and excluded from the recovery guarantee.

**D3. Three visibility classes, no middle tier.** *Why:* a middle tier would need per-field policy, which cannot be
enforced on an immutable record, so content that must be queried by field joins the consortium class instead.

**D4. Retention per data class, deletion executed by three parties.** *Why:* deletion has to be defensible and
never unilateral — the platform requests, the holder verifies and executes, anything earlier needs dual control,
and the signed record is anchored (DM-4).

**D5. One relational database, append-only canonical tables, everything else derived.** *Why:* EPCIS fields are
typed and constrained, admission needs one atomic step across event, idempotency claim and outbox, traversal is a
bounded recursive query, and reporting is set-oriented (DM-1, SQ-4). *Rejected:* a document store (loses
cross-event constraints and multi-row transactions), a graph database as the record (the graph is derived and
must stay verifiable), and event sourcing for the whole application (profiles and job state are not events).

The model that follows: a submission materialises exactly one canonical event; an event validates against one
profile version, is acknowledged by one or more holders, commits as one leaf, and references zero or more evidence
records; a batch contains many leaves and chains to its predecessor; a profile version governs many events and is
immutable.

![Figure 9 — Physical data model](../docs/public/diagrams/core-physical-model.svg)

*Figure 9 — Eight tables; the constraints that carry design meaning are named below.*

Five constraints matter. `capture_record_id` is the primary key of both submission and canonical event, so the
idempotency identity is the identity; `merkle_leaf` is keyed by `leaf_index` with a unique `capture_record_id`,
which is what makes anchoring idempotent; `canonical_event` is partitioned monthly on `event_time` and
append-only; `payload` is JSONB and holds only fields the platform does not query, validated at admission;
row-level predicates on `organisation_id` back the scope filter, so a coding mistake in one module cannot widen a
read.

**D6. Analytics consumes a minimised snapshot at a watermark and returns messages.** *Why:* the platform must not
be able to read rules or findings, and the regulator must not need raw tables; it is a peer subsystem in the
regulator's own account (Figure 1), not an external black box. *Rejected:* a platform-hosted tenant, which would
give one administrator read access to every rule and finding.

**D7. No warehouse or lake at pilot scale.** *Why:* 10 000 events/day is served by materialised views, a
warehouse would add a second consistency boundary, and a lake would duplicate private content. *Rejected:* a
warehouse from day one — revisit when volume or query mix changes.

## 4.11–4.15 Cloud: four decisions

**C1. Managed services, no cluster and no broker; one image that runs as application or worker.** *Why:* a
six-person team for one semester has no operations capacity, and 10 000 events/day does not need a broker.
*Rejected:* IaaS with a self-managed cluster, which moves patching, HA and backup onto the team.

**C2. Four accounts, delivered declaratively.** *Why:* it turns "the platform can deploy into the regulator's
account but cannot read from or operate it" into a property of the pipeline rather than a promise. *Rejected:* a
single account, where one administrator is in reach of every control plane.

**C3. One region with warm copies; one primary with a reader.** *Why:* the pilot's availability target is met
without active-active, which would multiply cost and consistency complexity. *Rejected:* active-active
multi-region and distributed SQL — both revisited only on measured pressure.

**C4. The relayer is isolated and does not scale horizontally.** *Why:* it holds the only credential that can
spend money and write to a public network, so it has no inbound path and cannot read payloads; a single wallet
also means a single instance. *Rejected:* the chain wallet inside the main application.

![Figure 10 — Logical deployment](../docs/public/diagrams/c4-deployment.svg)

*Figure 10 — Logical placement: which control domain owns which node.*

![Figure 11 — Reference deployment](../docs/public/diagrams/c4-reference-deployment.svg)

*Figure 11 — A configuration that can be procured and built.*

The two views are separate on purpose: the logical view answers who owns what, the reference view what we would
buy. Seven workloads, each with one credential and one scaling unit — the application and workers on request rate
and outbox lag, the database as a managed primary with a reader, archive and KMS provider-managed in a trustee
account, public delivery behind a CDN.

## 4.16–4.17 The write path and the recall path

![Figure 12 — Dynamic view: event acceptance](../docs/public/diagrams/c4-dynamic.svg)

*Figure 12 — One event from submission to confirmed visibility, in five phases and sixteen steps.*

Sixteen steps carry one event through five phases: receive and validate, encrypt and archive, receipt issued,
anchor to finality, confirm and project. The ordering is the argument — a receipt follows an outside holder's
signature, and confirmation follows finality; no timeout promotes an event, and a failure suspends it where it
stands.

| Steps | Data crossing | Classification | Boundary crossed |
|---|---|---|---|
| 1–2 | Canonical event, signature, identifiers | Consortium | Participant to platform |
| 4–6 | DEK, envelope, ciphertext | Consortium (encrypted) | Platform to KMS and holder |
| 6–7 | Signed acknowledgement over stored bytes | Consortium | Holder to platform |
| 8–9 | Receipt; anchor intent and leaf | Consortium | Platform to participant |
| 10–13 | Merkle root, transaction reference, inclusion proof | Public commitment | Platform to chain |
| 14–15 | Versioned public projection | Public | Platform to CDN |
| 16 | Trace page for the submitter | Consortium | Application to portal |

Step 16 is the submitter reading the event back; the consumer read comes from the CDN at step 15 and never
reaches the application.

![Figure 13 — Dynamic view: recall investigation](../docs/public/diagrams/c4-dynamic-recall.svg)

*Figure 13 — Scope at a watermark, evidence request, signed notice.*

The recall path is where privacy is decided. The platform produces a scope at a fixed watermark and returns
confirmed and provisional sets apart, never merged; an evidence request becomes an audit record rather than a
data pull, and the owner encrypts the content to the regulator's key so the platform never sees it. The formal
notice is written by the workers, acknowledged by the holder, anchored by the relayer, and published as
`PENDING_ANCHOR` before it is `CONFIRMED`.

## 4.18–4.20 Security: eight decisions, and what they accept

**S1. An event is confirmed only after a signature from outside the platform's account.** *Why:* the operator
must not be able to manufacture a confirmed claim on its own. *Rejected:* database plus WORM backup, where the
platform signs for itself.

**S2. Each event has its own data key, wrapped by a consortium key held outside the platform.** *Why:* the archive
holds ciphertext it cannot read, so a compromise of the archive is not a disclosure of content. *Rejected:* a
platform-held KEK.

**S3. One envelope covers all four custody modes; authority is judged as of signing time.** *Why:* rotation or a
later compromise must not retroactively invalidate history. *Rejected:* a format per custody mode, and judging
authority by a key's current status.

**S4. Private evidence never reaches the platform.** *Why:* the platform cannot be compelled to hand over what it
does not hold, and the owner decides who can decrypt. *Rejected:* field-level encryption on the platform, which
leaves it holding keys.

**S5. No natural-person field enters the immutable record.** *Why:* otherwise correction and deletion obligations
collide with the immutability the record exists for (SP-4).

**S6. Staff have no standing access; break-glass is dual-approved, recorded and anchored.** *Why:* the insider is
the highest-privilege threat, and a refusal is itself evidence (SP-6).

**S7. Analytics runs in the regulator's account and exchanges only signed messages.** *Why:* rules and findings
must be unreadable by the platform (D6). *Rejected:* a platform-hosted tenant.

**S8. Every principal that can write, read or disclose gets exactly one enforced entry point.** *Why:* the number
of entrances is the attack surface, so boundaries drive the model; STRIDE is then a coverage check rather than a
generator. Participant-facing: the API (signature, authority, organisation, rate limits; retryable rejection),
the portal (external IdP, per-request acting organisation) and onboarding (entity verification, sponsor, dual
approval). Leaving the account: the archive (the gate waits for the acknowledgement), the key service (wrap and
unwrap only), the chain (roots out, finality in, relayer-only wallet) and the regulator (signed messages, unsigned
rejected). Internal: staff (recorded break-glass) and the evidence owner (audited request, content the platform
cannot decrypt).

| Category | Threat | Mitigation | Residual |
|---|---|---|---|
| Spoofing | A participant claims to be another; a device claims another's identity | Envelope bound to a verified organisation and key; per-request acting organisation; device delegations | Compromised participant credentials |
| Tampering | A row or a batch is altered or skipped | Signed digest; append-only; roots commit to the previous root; consistency proofs | Requires finality to be observed, which is asynchronous |
| Repudiation | A publisher denies an event; the operator denies an advisory | Non-repudiable signatures; retained key history; issuer keeps its own copy | Keys held by third parties shift the question |
| Information disclosure | Private evidence leaks; a member reads outside scope | Content never on platform; owner-encrypted recipients; scope enforced at the single read entrance | Metadata and access patterns are visible |
| Denial of service | Event flood; a holder set that never acknowledges | Quotas, backpressure, bounded queues; at least two configured holders | A sustained flood degrades other participants |
| Elevation of privilege | An operator reads plaintext; a regulator reaches evidence outside a case | No standing access; case-scoped grants; anchored access record | A compromised break-glass path is a high-severity incident, not a silent one |

What is accepted, per requirement: compromised participant credentials (SP-1); provider-held signing keys
(SP-2); metadata and access patterns (SP-3); indirect identification through locations and small-farm identifiers
(SP-4); colluding approvers (SP-5); a runtime that reads consortium plaintext (SP-6); a regulator mirror that may
be compelled to disclose (SP-7). SP-8 says the rest in the interface.

The privacy argument rests on three moves: no personal field in the shared record, so deletion never negotiates
with an immutable log; content off the platform, so there is nothing to compel; classification by construction,
so no "sensitive but shared" middle tier can appear. What remains is metadata, treated as data with its own
minimisation. Three risks are stated rather than mitigated: a compromised runtime can read consortium plaintext,
a resourced colluder can assert a false reality, and a holder's copy may be disclosed under its own obligations.

## 4.B AI/ML and IoT architecture (bonus)

**AI-1…3.** Screening runs in the regulator's workspace over signed, deterministic rule versions; a model is an
alternative implementation of the same interface, not a second path, which is why the first release has no model
loader and loses nothing. Every finding carries its rule or model version and input watermark, and training data
is a purpose-bound snapshot, so a model is reproducible from the same inputs. No output becomes an action:
findings are private, advisories are reminders, and a consequence requires an officer's signature.

**IoT-1…3.** The boundary sits at the participant. The record carries profile-required summaries, and the owner
can prove at dispute time that a summary came from the raw data without publishing it. Devices are organisation
delegations, so a sensor fleet does not become a user fleet. Collection and alarming are local, availability is
the platform's, verifiability is the archive's — the platform deliberately does not own the cold-chain loop.

Rejected: raw telemetry upload, platform-side real-time alerting, ML at admission, training on the platform's own
copy, and edge ML for compliance. Both capabilities sit where their failure cannot break the record: an analytics
outage degrades advice, a sensor outage degrades evidence, and ingestion, confirmation and recovery continue.
