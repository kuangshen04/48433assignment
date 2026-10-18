## A1 Problem, objectives and stakeholders

An agricultural product moves through independent businesses, each keeping its own record of what it received, did
and passed on. Nothing joins those records: a regulator reconstructing a recall asks each business in turn and gets a
different identifier scheme, time zone and idea of "batch", so the answer arrives in weeks while the product is on
shelves. What is missing is a shared, attributable record a small producer can join cheaply and a regulator can trust
without trusting its host.

**Objectives.** Publish a claim cheaply, including offline (O1); make confirmed history tamper-evident to parties who
distrust the operator (O2); let a regulator scope an incident quickly and defensibly (O3); give consumers a truthful
view (O4); keep commercial detail and private evidence off the record (O5); run on a small team (O6); take device
evidence without becoming a device platform (O7); screen regulatory risk with ML optional (O8).

| ID | Party | What they need |
|---|---|---|
| S1 | Producer, grower, packer | Low-cost offline capture; signing without a corporate PKI |
| S2 | Processor | Transformation claims with quantities; no imposed mass-balance verdict |
| S3 | Distributor, cold chain | Two-sided handover; summaries, not raw telemetry |
| S4 | Retailer | Fast, conservative recall scope; a cacheable public view |
| S5 | Consumer | QR entry; "confirmed", "pending" and "no record" kept distinct |
| S6 | Regulator officer | Read access, case-scoped evidence, signed findings, audit trail |

The rest are parties to the design, not users of it: analytics (S7), governance (S8), the operator (S9), trustees
(S10), courts and auditors (S11), device vendors (S12).

## A2 Why these change the design, and what was excluded

Participants (S1–S5) with C4 force an integration tier: with only large manufacturers an ERP integration and a
corporate key would do, but because the smallest tier must publish, capture is browser-first, the queue survives
offline, the key never leaves the device and identifiers are client-generated. The regulator (S6, S7) forces a
boundary that would otherwise be invisible: analytics inside the platform's account would let the operator read every
rule and finding. Trust infrastructure (S8–S11) takes the record out of the operator's hands — cost is served,
unilateral control is not.

R1 and R3 eliminate the permissioned ledger, which fits the evidence requirement but needs validators this project
lacks. C1 and C2 are in tension — a public chain is mandatory, personal data must stay correctable — and the
resolution follows: commitments on chain, ciphertext off it, personal data in the mutable layer.

Out of scope, each because serving it would change the system's category: banks and insurers (pricing and settlement),
customs (a second legal regime), consumers as data producers (marketing, and personal data), certification bodies
(their certificates enter as private evidence), recycling operators (unvalidated event semantics), and marketing or BI
(served, if at all, inside the Insights module).

## A3 Quality scenarios, and the alternatives rejected

Four scenarios test the qualities that decide the shape. **QS-1** an operator deletes a batch and the missing batch
breaks the chain sequence — integrity must be detectable from published proofs alone. **QS-2** a three-year-old event
is verified after two key rotations and a suspension — attribution must survive rotation. **QS-3** a recall runs at
02:00 during an archive outage — a lost dependency must degrade a capability, never to a false "no record". **QS-6** a
grower with no signal for 36 hours captures four events on a low-end phone — under three minutes at 2G, WCAG 2.2 AA.

Rejected while setting these: a database plus WORM backup (the operator stays sole verifier); a permissioned ledger
(no validators, R1); per-employee signing keys (natural persons in an immutable record, R5); synchronous calls to every
dependency on the read path; a graph database from day one; field-level encryption in the shared record (the platform
would still hold the keys).

## A4 Security, privacy and regulation

Every write is authorised against an organisation, a role and a delegation, bound per request; every canonical event
is non-repudiable across rotation and revocation; governance changes need dual control and apply only once anchored;
reads are audited per organisation and staff access needs recorded break-glass; analytics cannot pull arbitrary
private evidence, and findings are private by default.

**Integrity** rests on the public chain: a Merkle root every thirty minutes that any third party can verify without
asking the platform (NSW Food Act 2003; Food Standards Code). **Confidentiality** is a three-tier tradeoff — public
projection, consortium trace, owner-held evidence, with no middle tier; the platform reads consortium plaintext
because traversal needs it and never private content, and no natural-person identifier enters the immutable record
(Privacy Act 1988 and the APPs; NSW PPIP Act 1998). **Availability** comes from read/write separation: writes fail
closed and retry idempotently, reads come from the materialised copy with an explicit degradation state, so a recall
during an outage returns a labelled partial result rather than a silent miss.

## A5 Data scenarios, and the relational choice

**DS-1** a retail lot is traced to a farm block seven years later — forces append-only canonical tables and indexed
lineage edges. **DS-2** two processors consume one lot — forces no uniqueness on lineage and a query layer that
returns both rather than picking one. **DS-3** a regulator requests a packer's report — forces only a commitment and a
storage mode on the platform. **DS-5** a batch expires during a dispute — forces deletion as a recorded transition
executed by three parties. **DS-6** events arrive after a key rotation — forces idempotent ingestion and a review
state, because "invalid" and "not yet established" are different facts.

One managed relational database holds submission state, registries, the outbox, a queryable materialisation and
rebuildable projections. It is relational because EPCIS fields are typed and constrained, admission needs one atomic
step across event, idempotency claim and outbox, traversal is a bounded recursive query and reporting is set-oriented.
Rejected: a document store (loses cross-event constraints), a graph database as the record (the graph is derived), and
event sourcing for the whole application (profiles and job state are not events).

## A6 The data model: conceptual, logical, physical

Conceptually, a submission materialises one canonical event; an event validates against one profile version, is
acknowledged by one or more holders, commits as one leaf and references zero or more evidence records; a batch holds
many leaves and chains to its predecessor. Logically, the copy of record is the external archive; the database holds a
plaintext queryable copy that is rebuildable and excluded from the recovery guarantee, because lineage cannot decrypt
per hop.

Physically, eight tables. Five constraints matter: `capture_record_id` is the primary key of submission and canonical
event, so idempotency identity is identity; `merkle_leaf` is unique on `capture_record_id`, which makes anchoring
idempotent; `canonical_event` is partitioned monthly and append-only; `payload` holds only fields the platform does not
query; row-level predicates on `organisation_id` back the scope filter.

## A7 Components, code and cross-view consistency

The core has one write path and one read entrance: `Capture API`, `Idempotency & Outbox Coordinator`, `Canonicalisation
& Profile Validator`, `Signature & Authority Validator`, `Submission State Machine`, `Archive & Anchor Orchestrator`,
`Evidence Graph Builder`, `Confirmed Event Store` and `QueryPort`. The orchestrator owns the confirmation gate and
records the archive intent while the worker role of the same image executes it; `QueryPort` exposes `edges()` and a
bounded `traverse()`, and nothing that returns a business status; the store is append-only, so a correction is a new
event. The relayer is drawn separately because it holds the only credential that can spend money: six of its seven
components need no private key, leaf allocation is deterministic, and the manifest writer places the manifest beside
the payload so recovery can reconstruct a batch without the database. The analytics workspace has four components,
with `Dataset Intake` as its only entrance.

In the type model, `SignatureEnvelope` has no natural-person field; `AcceptanceReceipt` binds the `ArchiveAck` digest,
so a receipt can only exist once an outside holder has confirmed persistence; `ProtectedResourceRef` holds a
commitment and a storage mode, never content. The three enumerations are published values. Consistency is maintained
by four rules rather than by review: one name per element across views, one owning component per class, one interface
per trust boundary, and enumerations as published contracts.

## A8 Quality tactics, patterns and SOLID

Each tactic names the quality it serves. Batching keeps cost and latency inside budget; the outbox and retry keep
recoverability; the single read entrance keeps privacy and auditability; the external signature keeps integrity;
derived projections keep performance. The patterns are a modular monolith layered inside, ports and adapters at every
external edge, a transactional outbox, a read model derived from the log, a state machine with anchored transitions,
and versioned contracts with published enumerations. Services, a direct SDK call, two-phase commit and per-hop
decryption were each rejected.

SOLID is visible where it matters: responsibilities split by reason to change, a new custody mode arrives as an
addition rather than a modification, four modes share one envelope, the read interface has two operations, and
dependencies point at interfaces. The five named smells are absent: no feature concentration (nine components split by
reason to change), no scattered functionality (one graph builder, one read entrance), no dense structure (acyclic,
single fan-in), no cycle (admission enqueues, workers execute), no unstable dependency (the core imports no vendor
package).

## A9 Cloud-native principles, and the deployment

The platform is PaaS: one managed container service running the application and the workers, a managed relational
database with a reader, object storage behind a CDN, and a managed KMS in a trustee's account. The principles applied
are managed services over infrastructure, one deployable scaled by role, twelve-factor configuration, stateless
application instances with state in managed stores, and infrastructure defined declaratively so the four accounts are a
property of the pipeline rather than of a checklist. Four scenarios decide the service model: QS-4 asks who serves the
bytes (a CDN, not a server); DS-3 asks who holds the content (a separate provider); QS-8 asks who operates the
analytics workspace (the regulator); C6 asks how much is operated at all (as little as possible). Rejected: IaaS with
a self-managed cluster, a shared tenant for analytics, on-premises object storage, origin-only delivery.

## A10 Alternative architectures

**A1 permissioned consortium ledger.** Four to seven validators with BFT consensus give seconds-level finality and
finer privacy, but need independent operators with HSMs, on-call and a charter; none exists, so it wins only if an
industry body funds them. **A2 trusted timestamping plus a transparency log.** WORM storage, RFC 3161 timestamps and
roots in an auditor-co-signed log: two or three trusted institutions instead of a public network, far cheaper, and the
strongest fallback — it wins only if C1 were relaxed. **A3 layer-2 anchoring.** The same envelope, leaves and proofs
under a rollup: cost down by orders of magnitude, at the price of a sequencer and a seven-year bet on that L2. **A4
microservices with an event bus.** Independent scaling, paid for with sagas, a broker, a registry and a platform team;
cost without benefit at 10 000 events/day.

| Criterion | Chosen | A1 | A2 | A3 | A4 |
|---|---|---|---|---|---|
| External verifiability | Any third party | Members only | TSA plus auditor | Public via L2 | Same as chosen |
| Operational burden | Low | High | Lowest | Low | High |
| Feasibility now | High | Low | High | High | Medium |

The chosen design is not the best in the abstract but the cheapest that keeps the first objective without institutions
that do not yet exist. Every alternative changes the edges, not the core: the event model, the query entrance and the
archive envelope survive each of them.

## A11 What this workbook still does not contain

The sheets are analysis scaffolding. A submitted report still needs the thirteen diagrams, the component and code
views, the data models, and the justification that turns each row into an argument.
