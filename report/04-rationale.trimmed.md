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

## 4.6 Context-level data architecture

`Regulatory Analytics` appears in Figure 1 as the second peer subsystem inside the system boundary, running in
the regulator's own account. Two facts follow: it consumes a minimised, purpose-bound snapshot rather than raw
tables, and it returns messages rather than rows. The archive is the authoritative store for encrypted payloads,
the KMS holds the keys that make it readable, and the chain holds only commitments.

## 4.7 Container-level data architecture

| Data role | Container | Rebuildable? |
|---|---|---|
| Operational record | Operational PostgreSQL | Yes, from canonical events |
| Queryable canonical copy | PostgreSQL (`QueryStore`) | Yes; excluded from the recovery guarantee |
| Authoritative payload | External archive | **No** — this is the copy of record |
| Public data mart | Snapshot origin plus CDN | Yes |
| Analytical mart | Insights materialised views inside PostgreSQL | Yes |
| Regulatory data | Analytics stores, regulator account | Rules signed and reproducible; findings evidential |

Three flows exist and no more: a scheduled purpose-bound export of a minimised snapshot; a nightly materialisation
of aggregates from the confirmed projection; an on-demand, case-bound export at a fixed watermark. A warehouse is
out of scope at 10 000 events/day, and a lake is rejected because raw files would duplicate private content.

## 4.8 Component-level conceptual model

Figure 4 fixes which component owns each entity. The concepts are submission, canonical event, evidence edge,
evidence reference, archive acknowledgement, leaf and batch, and profile version. A submission materialises
exactly one canonical event; an event validates against one profile version, is acknowledged by one or more
holders, commits as one leaf, and references zero or more evidence records; a batch contains many leaves and
chains to its predecessor; a profile version governs many events and is immutable.

## 4.9 Code-level physical model

![Figure 9 — Physical data model](../docs/public/diagrams/core-physical-model.svg)

*Figure 9 — Eight tables; the constraints that carry design meaning are named below.*

Five constraints matter. `capture_record_id` is the primary key of both submission and canonical event, so the
idempotency identity is the identity; `merkle_leaf` is keyed by `leaf_index` with a unique `capture_record_id`,
which is what makes anchoring idempotent; `canonical_event` is partitioned monthly on `event_time` and
append-only; `payload` is JSONB and holds only fields the platform does not query, validated at admission;
row-level predicates on `organisation_id` back the scope filter, so a coding mistake in one module cannot widen a
read.

## 4.10 Data architecture justification

The event stores its profile and canonicalisation versions, so it stays interpretable (DM-1). Private content is
never stored: only a commitment and a storage mode (DM-2), which is also why the archive — not the database — is
the copy of record (DM-3). Retention is a state machine executed by three parties with an anchored deletion
record (DM-4). No natural-person field exists in the model and the envelope carries no actor identity (DM-5),
and findings carry rule version and watermark so they reproduce (DM-6).

## 4.11–4.13 Cloud principles and what they cost

The design uses managed services instead of servers, stateless compute with externalised state, one immutable
image whose role is chosen by configuration, and declarative infrastructure for accounts, buckets, policies and
keys. Declarative delivery is what makes "the platform can deploy into the regulator's account but cannot read
from or operate it" a property of the pipeline rather than a promise. Scaling is by role: workers follow outbox
lag, the application follows request rate, and the relayer deliberately does not scale. Resilience comes from
multi-AZ, retry and stable identifiers; observability from watermarks, lag and two independent health signals;
privilege from accounts treated as boundaries rather than billing labels.

Each choice has a price, paid deliberately: managed services cost more per unit than servers the team cannot
operate; stateless compute adds a hydration cost per request; immutable images require a redeploy to change a
role; horizontal workers add outbox concurrency. Two deviations from fashion are recorded rather than hidden — a
single primary with a reader rather than distributed SQL, and one region with warm copies rather than
active-active — both consequences of pilot scale.

## 4.14 Deployment infrastructure

![Figure 10 — Logical deployment](../docs/public/diagrams/c4-deployment.svg)

*Figure 10 — Logical placement: which control domain owns which node.*

![Figure 11 — Reference deployment](../docs/public/diagrams/c4-reference-deployment.svg)

*Figure 11 — A configuration that can be procured and built.*

The views are separate on purpose: the logical view answers "who owns what", the reference view answers "what
would we buy". Devices sit outside both; the platform, trustee, regulator analytics and regulator evidence are
four accounts; the chain is an external utility with no validator operation.

## 4.15 Execution environments

Seven workloads, each with one credential and one scaling unit. The application and workers run the same image
in managed containers, scaling on request rate and outbox lag; the relayer is an isolated container that
deliberately does not scale; the database is a managed primary with a reader under IAM authentication; the
archive and KMS are provider-managed in a trustee account, reachable only through a role that can write and wrap
but not delete or administer; public delivery is object storage behind a CDN. The relayer is the only workload
whose credential can spend money and publish to a public network, so it has no inbound path and no ability to
read canonical payloads.

## 4.16 Dynamic views

![Figure 12 — Dynamic view: event acceptance](../docs/public/diagrams/c4-dynamic.svg)

*Figure 12 — One event from submission to confirmed visibility, in five phases and sixteen steps.*

The acceptance scenario exercises every boundary: participant to platform, platform to holder, to key service, to
chain and to the public. Sixteen steps carry one event through five phases — receive and validate, encrypt and
archive, receipt issued, anchor to finality, confirm and project. The ordering is the argument: a receipt is
issued only after an outside holder has signed for the bytes, and confirmation only after finality. No timeout
promotes an event; a failure suspends it where it stands and retries idempotently.

![Figure 13 — Dynamic view: recall investigation](../docs/public/diagrams/c4-dynamic-recall.svg)

*Figure 13 — Scope at a watermark, evidence request, signed notice.*

The recall path is where privacy is decided, so it is drawn separately. The platform produces a scope at a fixed
watermark and returns confirmed and provisional sets apart, never merged. An evidence request becomes an audit
record rather than a data pull: the owner encrypts the content to the regulator's key and the platform never sees
it. The formal notice is written to the archive by the workers, acknowledged by the holder, anchored by the
relayer, and published as `PENDING_ANCHOR` before it is `CONFIRMED` — publication does not wait for finality, and
it never claims more than the evidence supports.

## 4.17 Data flow through the dynamic view

| Steps | Data crossing | Classification | Boundary crossed |
|---|---|---|---|
| 1–2 | Canonical event, signature, identifiers | Consortium | Participant to platform |
| 4–6 | DEK, envelope, ciphertext | Consortium (encrypted) | Platform to KMS and holder |
| 6–7 | Signed acknowledgement over stored bytes | Consortium | Holder to platform |
| 8–9 | Receipt; anchor intent and leaf | Consortium | Platform to participant |
| 10–13 | Merkle root, transaction reference, inclusion proof | Public commitment | Platform to chain |
| 14–15 | Versioned public projection | Public | Platform to CDN |
| 16 | Trace page for the submitter | Consortium | Application to portal |

Step 16 is the submitter reading the event back; the consumer read is served by the CDN from step 15 and is not a
step in this figure, because consumers never reach the application.

## 4.18–4.20 Threat model: boundaries, threats and accepted risk

The model starts from boundaries rather than from a threat catalogue: every principal that can cause a write, a
read or a disclosure gets exactly one enforced entry point, and STRIDE is then used as a coverage check.

**Participant-facing.** The API takes signed events, enforcing signature, authority, organisation binding and
rate limits, and rejects with a retryable error rather than a partial acceptance; the portal takes sessions and
forms behind an external IdP with a per-request acting organisation, and loses only the session, because drafts
stay queued; onboarding verifies identity and keys with a sponsor and dual approval, so no partial membership
exists.

**Leaving the account.** The archive takes an envelope and returns an acknowledgement, and the gate simply does
not advance until one arrives; the key service wraps and unwraps but cannot delete or administer, so writes stop
at pending-archive while reads continue; the chain takes roots and returns finality through a wallet only the
relayer holds; the regulator receives signed snapshots and advisories, and rejects anything unsigned.

**Internal.** Staff have no standing access, and a refused break-glass is itself recorded and anchored; the
evidence owner receives an audited request and returns content the platform cannot decrypt, so absence is
recorded as "cannot confirm", never "not provided".

| Category | Threat | Mitigation | Residual |
|---|---|---|---|
| Spoofing | A participant claims to be another; a device claims another's identity | Envelope bound to a verified organisation and key; per-request acting organisation; device delegations | Compromised participant credentials |
| Tampering | A row or a batch is altered or skipped | Signed digest; append-only; roots commit to the previous root; consistency proofs | Requires finality to be observed, which is asynchronous |
| Repudiation | A publisher denies an event; the operator denies an advisory | Non-repudiable signatures; retained key history; issuer keeps its own copy | Keys held by third parties shift the question |
| Information disclosure | Private evidence leaks; a member reads outside scope | Content never on platform; owner-encrypted recipients; scope enforced at the single read entrance | Metadata and access patterns are visible |
| Denial of service | Event flood; a holder set that never acknowledges | Quotas, backpressure, bounded queues; at least two configured holders | A sustained flood degrades other participants |
| Elevation of privilege | An operator reads plaintext; a regulator reaches evidence outside a case | No standing access; case-scoped grants; anchored access record | A compromised break-glass path is a high-severity incident, not a silent one |

**What is accepted, per requirement.** Compromised participant credentials (SP-1); provider-held signing keys
(SP-2); metadata and access patterns (SP-3); indirect identification through locations and small-farm identifiers
(SP-4); colluding approvers (SP-5); a runtime that reads consortium plaintext (SP-6); a regulator mirror that may
be compelled to disclose (SP-7). Nothing beyond that is claimed, and SP-8 says so in the interface.

The privacy argument rests on three moves rather than one control: no personal field in the shared record, so
deletion never has to negotiate with an immutable log; content off the platform, so there is nothing to compel;
classification by construction, so no "sensitive but shared" middle tier can appear. What remains is metadata,
treated as data with its own minimisation and retention. Three risks are stated rather than mitigated: a
compromised runtime can read consortium plaintext, a resourced colluder can assert a false reality, and a
holder's copy may be disclosed under its own legal obligations.


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
