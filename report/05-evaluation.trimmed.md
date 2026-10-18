# 5. Architecture evaluation and alternatives

This section tests the promises made in Sections 1–4 against what the architecture delivers, and names where they
fall short.

## 5.1 How well it does — rubric 5.1–5.4

### The objectives, and how each is met — rubric 5.1–5.2

| ID | Business objective | Source | Verdict | Evidence and residual gap |
|---|---|---|---|---|
| BO-1 | An immutable, attributable record of every stage | brief 1 | **Met** | Envelope, holder-signed acknowledgement, Merkle inclusion; collusion is detectable, not prevented |
| BO-2 | Farmers, distributors, retailers and consumers all act, not only read | brief 2, 7 | **Met, conditionally** | Browser capture, offline queue, device-bound signing, WCAG 2.2 AA; a keyless device drafts and signs later |
| BO-3 | A regulator establishes incident scope quickly and defensibly | brief 5 | **Met** | Traversal at a watermark with per-edge provenance, cited to the Food Act and Code (Appendix B) |
| BO-4 | Consumers see a truthful, current-enough view | brief 2 | **Met** | Versioned snapshots with explicit states; a cached snapshot can lag a notice |
| BO-5 | Commercial and personal data are not exposed | implied | **Met, with residual risk** | Content off-platform with owner-chosen recipients; metadata stays visible |
| BO-6 | Growth across products and regions without a rebuild | brief 4 | **Partly met** | Profiles are additive; a region still needs a deployment and governance step |
| BO-7 | Operable by a small team at pilot scale | C6 | **Met at pilot scale** | Managed services, one deployable; two more operated environments exist |
| BO-8 | Device evidence without handing over raw telemetry | brief 3 | **Met, conditionally** | Collection and alarming stay local; summaries are attributable, coverage follows instrumentation |
| BO-9 | Regulatory screening as a capability, ML optional | bonus | **Met structurally** | Analytics at all three C4 levels; depends on the regulator operating its runtime |
| BO-10 | Supply-chain insight is readable, not merely queryable | brief 6 | **Partly met** | Aggregation and scope designed; the view layer is a thin client, not specified |

The evidentiary objectives are met strongly; both `Partly met` rows are what the design cannot close alone — a second
region is a governance act, and a view layer is a client this report does not specify.

### ATAM: what breaks, what does not, what trades off — rubric 5.3

ATAM rather than HAZOP: no physical process is controlled, and failure modes are already enumerated as lifecycle
states.

| Driver | Quality | Scenario | Importance | Difficulty |
|---|---|---|---|---|
| BO-1 | Integrity | QS-1 operator deletes a batch | H | H |
| BO-1 | Non-repudiation | QS-2 event verified after two rotations | H | M |
| BO-1 | Recoverability | QS-5 account lost after a receipt | H | H |
| BO-3 | Availability | QS-3 recall during an archive outage | H | H |
| BO-4 | Performance | QS-4 5 000 scans/s after a media story | H | M |
| BO-2 | Usability | QS-6 capture with 36 hours without signal | H | M |
| BO-5 | Confidentiality | QS-7 evidence request; QS-8 operations cannot read findings | H | H/M |
| BO-9 | Availability | QS-11 analytics down while a case is open | H | M |

**Risks.** The confirmation gate depends on parties outside the design: a holder or the chain can stall ingestion,
and one relayer holds the only wallet (quorum of one, outbox buffering, key in KMS, deterministic leaves allow
re-anchoring). A flat read scope leaves admission as the only confidentiality control (entity verification,
sponsor, dual approval). The regulator may not operate its runtime (analytics is optional). A regional loss can take
24 hours, a target proven only by drill. The field floor grows and burdens the smallest participants; retirement is
a gap.

**Non-risks.** A monolith that will not scale — 10 000 events/day is one write every eight seconds. Chain cost
exploding — one transaction per window. A plaintext copy contradicting privacy — it holds what the platform may
already read, is rebuildable, and never holds private content. An immutable log defeating deletion — no
natural-person field enters it.

**Trade-offs.** Finality versus freshness: a shorter window improves visibility and raises cost; the provisional
plane is the compromise. Shared visibility versus confidentiality: a narrower scope would strengthen
confidentiality and weaken the recall-authority story. Evidentiary strength versus forensics: hosting private
content would help investigations and destroy the privacy claim.

### What else could have been built — rubric 5.4

**A1 — Permissioned consortium ledger.** Four to seven validators with BFT consensus give seconds-level finality and
finer privacy, but need four independent operators with HSMs, on-call and a charter; none exists (R1). It wins if an
industry body funds them.

**A2 — Trusted timestamping plus a transparency log.** WORM storage, RFC 3161 timestamps per batch digest and roots
in an auditor-co-signed append-only log: two or three trusted institutions instead of a public network, far cheaper,
and the strongest fallback. It wins if chain cost, finality variance or policy makes a public network untenable.

**A3 — Layer-2 anchoring.** The same envelope, leaves and proofs under a rollup: cost down by orders of magnitude and
faster confirmation, at the price of a sequencer and a seven-year bet on that L2.

**A4 — Microservices with an event bus.** The same responsibilities as separate services with per-service databases:
independent scaling, paid for with sagas, a broker, a registry and a platform team. Cost without benefit at 10 000
events/day.

| Criterion | Chosen | A1 | A2 | A3 | A4 |
|---|---|---|---|---|---|
| External verifiability | Any third party | Members only | TSA plus auditor | Public via L2 | Same as chosen |
| Independence | Holder, KMS, chain | Validator set | TSA and log operator | Same as chosen | Same as chosen |
| Operational burden | Low | **High** | **Lowest** | Low | **High** |
| Feasibility now (C6) | High | **Low** | High | High | Medium |
| Indicative annual cost | Cloud plus A$40–80k anchoring | Staff plus infrastructure | Cloud plus TSA fees | Cloud plus negligible anchoring | Cloud plus platform team |

The chosen design is not the best in the abstract but the cheapest that keeps BO-1's promise without institutions
that do not exist. Every alternative changes the edges, not the core.
