# 5. Architecture Evaluation and Alternatives

*Draft — untrimmed. Rows covered: 5.1–5.4.*

This section evaluates the architecture against the business objectives it was built for, extends the
evaluation with a lightweight ATAM, and compares it with four alternatives that could plausibly have been
chosen instead.

## 5.1 Business objectives to evaluate against

The objectives come from the case brief and from Section 1; they are restated here in the form they are
evaluated against.

| ID | Business objective | Source | Success measure | Where it is addressed |
|---|---|---|---|---|
| BO-1 | An immutable, attributable record of every supply-chain stage | Brief: "immutable record-keeping" | Any confirmed event can be shown to exist at a point in time and to have been published by a named organisation, without trusting the operator | SQ-1, SQ-2; Figures 4, 9, 12 |
| BO-2 | Every participant can contribute, including the smallest | Brief: interfaces for farmers, distributors, retailers; rural accessibility | A smallholder can capture offline and submit valid events without enterprise software | SQ-6; offline queue; device-bound custody |
| BO-3 | A regulator can establish the affected scope of an incident quickly and defensibly | Brief: food-safety compliance | A recall scope is produced from confirmed claims within minutes, with provenance for every edge | SQ-4, SQ-9; Figures 12, 13 |
| BO-4 | Consumers see a truthful, current-enough view | Brief: consumer interface; transparency | A scan returns an allowlisted projection that distinguishes confirmed, pending, stale and absent | SQ-3, SQ-7; snapshot delivery |
| BO-5 | Commercial and personal data are not exposed by the record | Brief: implied by privacy law and by commercial reality | Private content is never readable by the platform; no natural-person field in shared history | SQ-7, SP-3, SP-4 |
| BO-6 | The system can grow across products and regions without being rebuilt | Brief: "multiple product lines and regions" | A new product line is a new profile; a new region is a governance and deployment choice, not a redesign | SQ-8; profiles; per-jurisdiction requirements |
| BO-7 | It can be operated by a small team at pilot scale | Constraint C6 | One application, one managed database, no bespoke infrastructure | SQ-10; deployment view |

## 5.2 Evaluation

| Objective | Verdict | Evidence | Residual gap |
|---|---|---|---|
| BO-1 Immutable, attributable record | **Met** | Signature envelope plus holder-signed acknowledgement plus Merkle inclusion; nothing in the confirmed path is written by the platform alone | Collusion between a publisher and an archive holder is detected only by third-party comparison, not prevented |
| BO-2 Everyone can contribute | **Met, conditionally** | Browser-first capture, offline queue, device-bound signing on capable devices | On devices without reliable key storage, participants fall back to draft-and-sign-online, which is weaker than the claim |
| BO-3 Fast, defensible recall scope | **Met** | Traversal at a fixed watermark with per-edge provenance; provisional set for the recent window | Traversal cost grows with history; the graph-store trigger is defined but unmeasured |
| BO-4 Truthful consumer view | **Met** | Versioned snapshots; explicit states; no "no record" inference | A cached snapshot can lag a recall notice; the resolver rules are specified but not yet implemented |
| BO-5 No exposure of private data | **Met, with residual risk** | Content off-platform behind a commitment; content encrypted to recipients chosen by the owner | Metadata and access patterns are visible to the platform |
| BO-6 Growth by configuration | **Partly met** | Profiles and per-jurisdiction requirements are additive | Region growth still requires a deployment and governance step; multi-region active-active is out of scope |
| BO-7 Small-team operation | **Met at pilot scale** | Managed services; one deployable; batched anchoring | Two additional operated environments exist (regulator, trustee), which is a cost the pilot carries for independence |

The honest summary: the architecture meets its evidentiary objectives strongly, meets the growth objective by
configuration rather than by construction, and meets the coverage objective only where devices and connectivity
allow.

## 5.3 ATAM analysis

ATAM was chosen over HAZOP because the system does not control a physical process: its hazards are evidentiary
and informational (a record that cannot be trusted, a disclosure that should not happen), not physical. HAZOP's
guide words are designed to find deviations in a process flow; the closest analogue here would be the
confirmation pipeline, whose failure modes are already enumerated as lifecycle states and dependency failures.
The analysis is deliberately kept small: a large ATAM would produce a document longer than the report and add
no decisions.

### 5.3.1 Utility tree

| Business driver | Quality attribute | Scenario | Importance | Difficulty |
|---|---|---|---|---|
| BO-1 Evidentiary trust | Integrity | QS-1: operator deletes a batch; history still provable | H | H |
| BO-1 Evidentiary trust | Non-repudiation | QS-2: verify a three-year-old event after key rotation | H | M |
| BO-3 Recall speed | Performance | QS-3: recall traversal at 02:00 during an archive outage | H | H |
| BO-4 Consumer trust | Availability | QS-4: 5 000 scans/s after a media story | H | M |
| BO-1 Evidentiary trust | Recoverability | QS-5: database and account lost after a receipt | H | H |
| BO-2 Coverage | Usability | QS-6: capture in a paddock with no coverage for 36 hours | H | M |
| BO-5 Privacy | Confidentiality | QS-7: evidence request for a lab report | H | M |
| BO-5 Privacy | Confidentiality | QS-8: platform operations cannot read regulator findings | H | H |
| BO-3 Defensibility | Auditability | QS-9: two conflicting transformation claims | M | M |
| BO-6 Growth | Modifiability | QS-10: chain migration without re-signing history | M | M |

### 5.3.2 Risks

| ID | Risk (a decision that may not hold) | Quality affected | Response |
|---|---|---|---|
| AR-1 | Confirmation depends on external holders and a public chain; slow or unavailable holders stall ingestion | Availability | Holder set with quorum one; outbox buffering; backlog age as a monitored signal; the refusal is visible rather than silent |
| AR-2 | Flat read scope means admission strength is the only confidentiality control | Security | Entity verification, sponsor, dual approval, read audit; residual risk stated |
| AR-3 | The regulator must operate its own runtime; if it does not, baseline review disappears | Availability of a capability | Analytics is optional by design: trace, recall and manual investigation continue, and the gap is displayed |
| AR-4 | Chain fees and finality vary; confirmation latency and budget inherit that variance | Performance, cost | 30-minute windows, empty windows skipped, finality rule fixed, cost estimated with a range and a measurement plan |
| AR-5 | Single-region active-passive; a regional loss needs up to 24 hours to rebuild | Availability | Cross-region snapshot copies and archive replicas; target stated as a target, proven only by drill |
| AR-6 | The field floor grows as modules are added, increasing capture burden on the smallest participants | Usability, modifiability | Module manifests make growth explicit and governed; profile versions are additive; field retirement is a known gap |
| AR-7 | One relayer with one wallet: key loss or compromise stalls anchoring | Availability, security | Wallet key in KMS; isolated deployment; no inbound path; re-anchoring is possible because leaves are deterministic |
| AR-8 | Private evidence cannot be obtained by the platform, only requested | Investigation effectiveness | The request is an audit record; "not provided" is itself a finding; this is the price of BO-5 |

### 5.3.3 Non-risks

| ID | Looks risky, is addressed |
|---|---|
| AN-1 | "A modular monolith will not scale" — measured workload is three orders of magnitude below a single well-indexed database; scaling is by role, not by service |
| AN-2 | "Public-chain cost will explode" — one transaction per 30-minute window, and empty windows are skipped |
| AN-3 | "Keeping a plaintext query copy contradicts the privacy claim" — the copy holds consortium data the platform is authorised to read, is rebuildable, and never holds private content |
| AN-4 | "Six modules in one process will entangle" — the single read entrance and the dependency rules in Section 4.5 forbid the entanglements that matter |
| AN-5 | "An immutable record cannot satisfy deletion rights" — no natural-person field ever enters it, so deletion obligations are discharged in the mutable layer |

### 5.3.4 Trade-off and sensitivity points

| ID | Type | Point | What moves if the parameter changes |
|---|---|---|---|
| TP-1 | Trade-off | Finality vs freshness: visibility waits for anchoring | Shortening the window improves freshness and raises cost; the provisional plane is the compromise |
| TP-2 | Trade-off | Shared visibility vs confidentiality: flat consortium scope | Narrowing the scope improves confidentiality and weakens the recall-authority story |
| TP-3 | Trade-off | Evidentiary strength vs forensic capability: private content off-platform | Hosting content would help investigations and destroy the privacy claim |
| TP-4 | Trade-off | Independence vs availability: external gate before confirmation | Removing the gate improves uptime and removes the reason for the blockchain |
| SP-1 | Sensitivity | Anchor window (30 min) | Drives confirmation latency, gas cost and backlog risk |
| SP-2 | Sensitivity | Holder set size and quorum | Drives gate availability and the independence argument |
| SP-3 | Sensitivity | Composition of the field floor | Drives capture effort for smallholders and the completeness of recall |
| SP-4 | Sensitivity | Retention period | Drives storage cost, deletion complexity and legal exposure |
| SP-5 | Sensitivity | Scope model (flat vs per-trace) | Drives confidentiality, recall authority and query complexity |

## 5.4 Realistic alternatives

Each alternative is described as it would actually be built, then assessed for applicability and feasibility in
this project.

### A1 — Permissioned consortium ledger

**Shape.** Four to seven validators operated by the platform, a producer body, a retailer, the regulator and an
auditor; a BFT consensus (QBFT or equivalent); private transaction groups; membership and profiles governed
on-chain; no public chain, no gas, no external archive as a separate mechanism.

**Strengths.** Seconds-level deterministic finality; privacy groups can express "only these members" far more
finely than a public commitment; governance is expressible as code; no dependency on a public network's fee
market.

**Weaknesses.** Requires at least four genuinely independent operators with HSMs, on-call rotation, upgrade
procedures and a governance charter. It is also *not* publicly verifiable: the guarantee is "the members agree",
not "any third party can check". The operational cost is measured in staff, not in gas.

**Feasibility now.** Low. No consortium, no funded operators, no charter. This is the alternative that would be
chosen if the project were commissioned by an existing industry body with member commitments.

### A2 — No blockchain: trusted timestamping plus a transparency log

**Shape.** The platform writes encrypted payloads to WORM storage in a separate account; a commercial timestamp
authority (RFC 3161) signs the digest of each batch; an append-only Merkle transparency log, co-signed by an
independent auditor, publishes roots and accepts third-party monitoring; no chain.

**Strengths.** Uses institutions that already exist and can be procured today; much cheaper; the transparency
log provides append-only evidence and public monitoring, which is most of what the chain contributes.

**Weaknesses.** Existence proofs depend on the timestamp authority and on the log operator plus its auditor —
two or three trusted parties instead of a public network. "No single operator can rewrite history" becomes "no
single operator, and these two, can rewrite history". Public verifiability is weaker, and the log's liveness is
a contractual rather than an economic guarantee.

**Feasibility.** High. This is the strongest fallback and the alternative most likely to be proposed by a
procurement reviewer.

### A3 — Layer-2 anchoring

**Shape.** The same architecture with the anchoring step moved to an L2 rollup. Identical envelope, leaf and
proof semantics; the root is submitted to the rollup instead of L1.

**Strengths.** Anchoring cost falls by orders of magnitude; confirmation is faster; the design change is
confined to the relayer and the verification tool.

**Weaknesses.** Adds a dependency on the rollup's sequencer and on that L2's continued existence; verifying an
old inclusion proof may require L2 state or an L1 settlement proof. For a seven-year evidentiary horizon this is
a longevity bet.

**Feasibility.** High. It is a configuration variant, not a redesign — which is itself evidence that the leaf
format was chosen well.

### A4 — Microservices with an event bus

**Shape.** Capture, validation, archive orchestration, anchoring, projection and query as separate services on a
broker, with per-service databases.

**Strengths.** Independent scaling and deployment; team autonomy; failure isolation per service.

**Weaknesses.** Turns every in-process call into a distributed one, replaces transactions with sagas, and adds a
broker, a schema registry and an operational platform. At 10 000 events/day this is cost without benefit; the
same qualities are obtained in-process by the outbox and by role-based scaling.

**Feasibility.** Technically high, organisationally unnecessary: it solves a scaling problem the project does
not have and a team-topology problem a six-person team does not have.

### Comparison

| Criterion | Chosen design | A1 Permissioned ledger | A2 Timestamp + log | A3 L2 anchoring | A4 Microservices |
|---|---|---|---|---|---|
| External verifiability (BO-1) | Public chain, any third party | Members only | Timestamp authority + auditor | Public (via L2) | Same as chosen |
| Independence from the operator (BO-1) | Archive holder + KMS + chain | Validator set | TSA + log operator | Same as chosen | Same as chosen |
| Privacy control (BO-5) | Content off-platform | Private transaction groups | Same as chosen | Same as chosen | Same as chosen |
| Recall performance (BO-3) | Materialised copy | On-chain query is slow | Same as chosen | Same as chosen | Same, with network hops |
| Operational burden (BO-7) | Low: managed services | **High**: validator fleet + charter | **Lowest** | Low | **High**: broker + 6 services |
| Feasibility now (C6) | High | **Low** | High | High | Medium |
| Indicative annual cost | Cloud + ~A$40–80k anchoring | Staff + infrastructure | Cloud + TSA fees | Cloud + negligible anchoring | Cloud + platform team |

### When each alternative would win

- **A1** when an existing industry body commits at least five funded operators and a governance charter; the
  platform would then keep its envelope, event model and query interface and replace the anchoring module.
- **A2** when public-chain anchoring is rejected on cost or policy grounds, and the regulator accepts a
  timestamp authority plus an audited transparency log as sufficient evidence. It is the cheapest design that
  still produces third-party-verifiable existence proofs.
- **A3** when anchoring cost becomes material but longevity risk is acceptable, for example if the pilot is
  extended for two years rather than seven.
- **A4** only when write volume grows by two orders of magnitude and more than one team owns the services.

The chosen architecture is therefore not "the best" in the abstract; it is the cheapest design that still keeps
the promise in BO-1 — that no single party, including the operator, can silently rewrite confirmed history —
without requiring institutions that do not yet exist. Its most useful property is that the other three
alternatives change the edges of the design, not the core: the canonical event model, the query entrance and the
archive envelope survive all of them, which is why the alternatives remain genuinely available rather than
rhetorical.
