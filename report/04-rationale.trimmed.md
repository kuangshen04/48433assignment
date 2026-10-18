# 4. Architectural Rationale and Decision-Making

Section 3 states what the structure is; this section states why it is that structure — which quality each
decision buys, which pattern carries it, and what was rejected.

## 4.1 Quality requirements and where they are met

Section 2 states thirteen quality requirements, and Appendix A.1 maps each to its mechanism and component. Five
of them decide the shape of the system rather than constrain how it is built; the rest of this section explains
the decisions behind those five.

| Requirement | Structural mechanism | Where it lives |
|---|---|---|
| SQ-1 Integrity | Append-only records, signed digest, external acknowledgement, Merkle inclusion, verifiable batch sequence | Orchestrator; relayer; archive |
| SQ-3 Availability | Fail-closed writes with idempotent retry; reads from materialised data; analytics never in the write path | State machine; workers; outbox |
| SQ-4 Performance | Edge snapshots; lineage from the plaintext query copy; bounded synchronous traversal | Snapshot delivery; `QueryStore`; `QueryPort` |
| SQ-7 Privacy | Three visibility classes with no middle tier; content off-platform behind a salted commitment; no natural-person field | `ProtectedResourceRef`; `SignatureEnvelope` |
| SQ-13 Analysability | Aggregates materialised over the confirmed projection at a watermark, served under the same scope rules | `Insights` module |

## 4.2 Quality tactics

| Quality | Tactic | Concrete mechanism |
|---|---|---|
| Integrity | Detect tampering rather than prevent it | Append-only rows; signed canonical digest; holder-signed acknowledgement over stored bytes; roots committing to the previous root; inclusion proofs |
| Non-repudiation | Separate three questions usually conflated | Was it signed by that key; was that organisation allowed to sign then; when was it signed — three independent checks, none implying another |
| Availability | Fail closed on writes, degrade explicitly on reads | Idempotent retry on a stable identifier; outbox committing state and side effect together; reads from the local copy; analytics outside the write path |
| Performance | Move work off the request path | Versioned snapshots on the CDN; lineage derived once and read from indexes; fixed edge budget with export beyond it |
| Modifiability | Localise change | New profile version instead of a core change; ports and adapters for archive, KMS, chain and identity; chain-agnostic leaf |
| Security | Enforce at one point, audit at the boundary | `QueryPort` as the only read entrance; one signature verifier; key separation; time-boxed, dual-approved break-glass |
| Observability | Make state and derivation inspectable | Watermarks on every projection; platform liveness kept separate from the regulator's self-reported health; replayable derivation |

## 4.3 Architectural patterns

| Pattern | Applied as | Serves |
|---|---|---|
| Modular monolith | One deployable, core plus six modules, called through ports | SQ-10; modifiability |
| Ports and adapters | Archive, key service, chain, identity and time are ports; SDKs live in adapters | SQ-8; testability |
| Transactional outbox | Submission state and archive intent commit together; workers drain | SQ-3, SQ-1 |
| Append-only log with derived projections | Canonical events are the write model; lineage, recall and public views are rebuildable | SQ-1, SQ-4 |
| Admission gate pipeline | Validation is a sequence of gates, each adding a stated guarantee | SQ-1, SQ-2 |
| Notarisation | Periodic Merkle roots provide an external existence checkpoint | SQ-1 |
| Two control domains | Analytics and archive custody in accounts the platform cannot operate | SQ-7, SP-5 |
| Isolated signer | The only chain-wallet holder is a separate deployment | SP-1, SP-5 |
| Single read façade | `QueryPort` is the only entrance; nothing else reads canonical tables | SQ-1, SQ-7 |

Rejected where they did not earn their cost: microservices per concern, two-phase commit, full event sourcing,
and a permissioned ledger (Section 5 revisits the last).

## 4.4 SOLID principles

**Single responsibility.** One verb per component: accept, deduplicate, canonicalise, verify, advance state,
orchestrate, derive, serve. Schema conformance and cryptographic attribution change for different reasons, which
is why canonicalisation and signature validation are separate.

**Open/closed.** A new custody mode is a new envelope producer plus a registry entry; a new profile is a new
immutable version; a new archive holder is a new signer behind the same contract. The core gains no branch.

**Liskov substitution.** All four custody modes produce the same envelope and pass the same verifier. What is
*not* flattened is the assurance level: the interface is uniform, the trust claim is not.

**Interface segregation.** `QueryPort` exposes two graph-shaped operations and nothing else; a method returning
handover status or compliance state would let a caller bypass the rules the port exists to enforce.

**Dependency inversion.** The core depends on an archive port, a key port, a verifier and a clock, never on a
provider SDK — which is what allows the holder set, the KMS and the chain to change without domain edits. The
relayer is the deliberate exception, and confining chain code there is the point.

## 4.5 Avoidance of poor design

Each smell has one answer, and the answers are the patterns above. *Feature concentration*: the core is
mechanism and business semantics live in six modules with declared dependencies. *Scattered functionality*: one
verifier, one state machine, one read entrance, one orchestrator that touches externals. *Dense structure*:
bounded component counts (core 9, relayer 7, workspace 4). *Cyclic dependency*: modules → `QueryPort` → store,
core → ports → adapters, and the graph is derived so there is no back edge. *Unstable dependency*: domain code
depends on interfaces, and SDKs and provider formats are confined to adapters and the relayer.

The rules are what keep the picture from decaying: modules may call `QueryPort` and never the canonical tables;
the core does not know modules exist; the core reaches providers only through ports.

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

Figure 9 shows eight tables. Five constraints carry design meaning: `capture_record_id` is the primary key of
both submission and canonical event, so the idempotency identity is the identity; `merkle_leaf` is keyed by
`leaf_index` with a unique `capture_record_id`, which is what makes anchoring idempotent; `canonical_event` is
partitioned monthly on `event_time` and append-only; `payload` is JSONB and holds only fields the platform does
not query, validated at admission; row-level predicates on `organisation_id` back the scope filter, so a coding
mistake in one module cannot widen a read.

## 4.10 Data architecture justification

| Requirement | Satisfied by |
|---|---|
| DM-1 interpretability | Canonical event stores profile and canonicalisation versions; extensions are profile-declared |
| DM-2 private content off-platform | Only a commitment and a storage mode are stored |
| DM-3 one source, rebuildable copies | Archive is the copy of record; the schema states which tables rebuild |
| DM-4 retention and deletion | A state machine with three-party execution and an anchored deletion record |
| DM-5 no personal data | No such field in the event model; the envelope carries no actor identity |
| DM-6 reproducible outputs | Findings carry rule version and input watermark; derivation is versioned |

## 4.11–4.13 Cloud requirements, principles and justification

| Principle | Requirement | Cost accepted |
|---|---|---|
| Managed services over servers | no capital expenditure, no infrastructure team (2.5) | Higher unit cost, bought instead of a team |
| Stateless compute, externalised state | failover without local state (SQ-3) | A hydration cost on every request |
| One immutable image, role by configuration | no configuration drift (SQ-8) | A role change needs a redeploy |
| Declarative infrastructure for accounts, buckets, policies and keys | the platform can deploy into the regulator's account but cannot read from or operate it | Account topology becomes code that must be reviewed |
| Horizontal scale by role | worker lag drives scale; the relayer does not scale (SQ-4) | Outbox concurrency complexity |
| Resilience by multi-AZ, retry and stable identifiers | degradation, not loss (SQ-3, SQ-5) | Idempotency is a design obligation on every side effect |
| Observability as an output | watermarks, lag, two health signals (SQ-9) | Instrumentation is built, not assumed |
| Least privilege with accounts as boundaries | residency and separation (SP-5) | Four accounts to operate |
| Portable formats and standard SQL | exit and portability | Some provider features are left unused |

Two deviations are deliberate and recorded: a single managed primary with a reader rather than distributed SQL,
and one region with warm copies rather than active-active. Both follow from pilot scale and are revisited only on
measured pressure.

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

## 4.16 Dynamic view

![Figure 12 — Dynamic view: event acceptance](../docs/public/diagrams/c4-dynamic.svg)

*Figure 12 — One event from submission to confirmed visibility, in five phases and sixteen steps.*

The scenario exercises every boundary: participant to platform, platform to holder, to key service, to chain and
to the public. Sixteen steps carry one event through five phases — receive and validate, encrypt and archive,
receipt issued, anchor to finality, confirm and project. The ordering is the argument: a receipt is issued only
after an outside holder has signed for the bytes, and confirmation only after finality. No timeout promotes an
event; a failure suspends it where it stands and retries idempotently.

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

## 4.18 Threat-model boundaries and entry points

| Boundary or entry point | What crosses | Enforcement | Failure mode |
|---|---|---|---|
| Participant API | Signed events, queries | Signature and authority; organisation binding; rate limits | Reject with a retryable error; no partial acceptance |
| Portal | Sessions, capture forms | External IdP; per-request acting organisation | Session invalid; offline queue keeps drafts |
| Cross-tenant channel | Snapshots, advisories, manifests | Signed messages both ways; transport identity is not authority | Unsigned messages rejected; analytics loss degrades advice only |
| Archive holder | Envelope out, acknowledgement in | Capability contract; eligibility and independence tests | Event stays pending-archive; the gate does not advance |
| Key service | Wrapped keys, unwrap requests | Policy denies delete and admin | Writes stop at pending-archive; reads continue |
| Chain | Roots out, finality in | Immutable contract; relayer-only wallet | Events stay pending-anchor; notices publish as pending |
| Platform staff | Operational access | No standing access; dual-approved break-glass, recorded and anchored | Refusal is itself recorded |
| Onboarding | Identity and keys | Entity verification, sponsor, dual approval | Registration delayed; no partial membership |
| Evidence owner | Request out, content in | Request audited; platform cannot decrypt | "Cannot confirm", never "not provided" |

Three boundaries leave the platform's account — archive, key service and regulator — and each is crossed only
with a signed message whose verification does not depend on the platform's own claims.

## 4.19 STRIDE threats and mitigations

| Category | Threat | Mitigation | Residual |
|---|---|---|---|
| Spoofing | A participant claims to be another; a device claims another's identity | Envelope bound to a verified organisation and key; per-request acting organisation; device delegations | Compromised participant credentials |
| Tampering | A row or a batch is altered or skipped | Signed digest; append-only; roots commit to the previous root; consistency proofs | Requires finality to be observed, which is asynchronous |
| Repudiation | A publisher denies an event; the operator denies an advisory | Non-repudiable signatures; retained key history; issuer keeps its own copy | Keys held by third parties shift the question |
| Information disclosure | Private evidence leaks; a member reads outside scope | Content never on platform; owner-encrypted recipients; scope enforced at the single read entrance | Metadata and access patterns are visible |
| Denial of service | Event flood; a holder set that never acknowledges | Quotas, backpressure, bounded queues; at least two configured holders | A sustained flood degrades other participants |
| Elevation of privilege | An operator reads plaintext; a regulator reaches evidence outside a case | No standing access; case-scoped grants; anchored access record | A compromised break-glass path is a high-severity incident, not a silent one |

## 4.20 Security and privacy justification

| Requirement | Met by | Residual risk accepted |
|---|---|---|
| SP-1 authenticated, bound writes | Envelope plus per-request acting organisation | Compromised participant credentials |
| SP-2 non-repudiation across rotation | Key history retained; acceptance-time authority recorded | Keys delegated to providers |
| SP-3 platform cannot read private content | Content off-platform; owner-chosen recipients; commitment only | Metadata and access patterns |
| SP-4 no personal data in immutable history | No such field; personal data only in the mutable layer | Indirect identification through locations and small-farm identifiers |
| SP-5 dual control | Dual-control list; anchoring before effect | Colluding approvers |
| SP-6 audited reads, break-glass | Read audit per organisation; break-glass path | The runtime reads consortium plaintext |
| SP-7 analytics cannot pull evidence | Dataset snapshots; owner-encrypted evidence | The regulator holds a mirror and may be compelled |
| SP-8 explicit non-guarantees | Stated in the context and data views | None claimed |

The privacy argument rests on three moves: no personal fields in the shared record, so deletion never negotiates
with an immutable log; content not on the platform, so it cannot be compelled to hand over what it does not
hold; and classification by construction, so there is no "sensitive but shared" middle tier. What remains is
metadata, treated as data with its own minimisation and retention. Three residual risks are stated rather than
mitigated: a compromised runtime can read consortium plaintext, a resourced colluder can assert a false reality,
and a holder's copy may be disclosed under its own legal obligations.

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
