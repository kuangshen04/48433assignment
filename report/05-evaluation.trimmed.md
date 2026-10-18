# 5. Architecture Evaluation and Alternatives

This section tests the promises made in Sections 1–4 against what the architecture delivers, and names where they
fall short.

## 5.1–5.2 Business objectives and how well they are met

| ID | Objective | Source | Verdict | Evidence and residual gap |
|---|---|---|---|---|
| BO-1 | An immutable, attributable record of every stage | Brief | **Met** | Envelope, holder-signed acknowledgement, Merkle inclusion; collusion is detected only by comparison, not prevented |
| BO-2 | Every participant can contribute, including the smallest | Brief | **Met, conditionally** | Browser capture, offline queue, device-bound signing; devices without key storage fall back to draft-and-sign-online |
| BO-3 | A regulator establishes incident scope quickly and defensibly | Brief | **Met** | Traversal at a watermark with per-edge provenance; cost grows with history |
| BO-4 | Consumers see a truthful, current-enough view | Brief | **Met** | Versioned snapshots with explicit states; a cached snapshot can lag a notice |
| BO-5 | Commercial and personal data are not exposed | Implied | **Met, with residual risk** | Content off-platform with owner-chosen recipients; metadata remains visible |
| BO-6 | Growth across products and regions without a rebuild | Brief | **Partly met** | Profiles are additive; a region still needs a deployment and governance step |
| BO-7 | Operable by a small team at pilot scale | C6 | **Met at pilot scale** | Managed services, one deployable; two more operated environments exist |
| BO-8 | Device evidence without handing over raw telemetry | Brief | **Met, conditionally** | Summaries are attributable; coverage depends on participant instrumentation |
| BO-9 | Regulatory screening as a capability, ML optional | Brief | **Met structurally** | Analytics at all three C4 levels; depends on the regulator operating its runtime |
| BO-10 | Supply-chain insight is readable, not merely queryable | Brief | **Partly met** | Aggregation and scope designed; the view layer is a thin client, not specified |

The evidentiary objectives are met strongly, growth by configuration rather than construction, coverage only where
devices and connectivity allow, and insight at the data layer with presentation left to the client.

## 5.3 ATAM

ATAM rather than HAZOP: the system controls no physical process, and its failure modes are already enumerated as
lifecycle states and dependency failures.

| Driver | Quality | Scenario | Importance | Difficulty |
|---|---|---|---|---|
| BO-1 | Integrity | QS-1 operator deletes a batch | H | H |
| BO-1 | Non-repudiation | QS-2 three-year-old event after rotation | H | M |
| BO-1 | Recoverability | QS-5 account lost after a receipt | H | H |
| BO-3 | Availability | QS-3 recall during an archive outage | H | H |
| BO-4 | Performance | QS-4 5 000 scans/s after a media story | H | M |
| BO-2 | Usability | QS-6 capture with 36 hours without signal | H | M |
| BO-5 | Confidentiality | QS-7 evidence request; QS-8 operations cannot read findings | H | H/M |
| BO-9 | Availability | QS-11 analytics down while a case is open | H | M |

**Risks.** External holders or the chain stalling ingestion (quorum one, outbox buffering, backlog age monitored);
flat read scope making admission the only confidentiality control (entity verification, sponsor, dual approval);
the regulator not operating its runtime (analytics is optional, trace continues); chain fee and finality variance
(fixed windows, cost range, measurement plan); a regional loss taking up to 24 hours (cross-region copies, target
proven only by drill); growth of the field floor burdening the smallest participants (governed module manifests,
retirement still a gap); one relayer with one wallet (key in KMS, deterministic leaves allow re-anchoring).

**Non-risks.** A monolith that will not scale — 10 000 events/day is one write every eight seconds. Chain cost that
will explode — one transaction per window, empty windows skipped. A plaintext copy that contradicts privacy — it
holds consortium data the platform may read, is rebuildable, and never holds private content. An immutable log
that defeats deletion — no natural-person field ever enters it.

**Trade-offs.** Finality versus freshness: a shorter window improves visibility and raises cost, and the
provisional plane is the compromise. Shared visibility versus confidentiality: a narrower scope would improve
confidentiality and weaken the recall-authority story. Evidentiary strength versus forensics: hosting private
content would help investigations and destroy the privacy claim.

## 5.4 Realistic alternatives

**A1 — Permissioned consortium ledger.** Four to seven validators with BFT consensus, private transaction groups
and on-chain membership. Seconds-level deterministic finality and finer privacy control, but it needs at least
four genuinely independent operators with HSMs, on-call and a charter, and it is not publicly verifiable: the
guarantee is "the members agree". Feasibility now is low — no consortium, no funded operators — and it wins if an
industry body commits both.

**A2 — No blockchain: trusted timestamping plus a transparency log.** Payloads in WORM storage, each batch digest
timestamped (RFC 3161) and roots published to an append-only log co-signed by an auditor. Uses institutions that
exist today and is much cheaper; the transparency log supplies most of what the chain contributes. The cost is two
or three trusted parties instead of a public network. The strongest fallback, and the one a procurement reviewer
would propose.

**A3 — Layer-2 anchoring.** Identical envelope, leaf and proof semantics, with roots submitted to a rollup. Cost
falls by orders of magnitude and confirmation is faster, at the price of a sequencer and of that L2 surviving a
seven-year horizon. A configuration variant, which is itself evidence the leaf format was chosen well.

**A4 — Microservices with an event bus.** Capture, validation, orchestration, anchoring, projection and query as
services with per-service databases. Independent scaling and failure isolation, paid for with sagas, a broker, a
schema registry and an operational platform — cost without benefit at 10 000 events/day and for one team.

| Criterion | Chosen | A1 | A2 | A3 | A4 |
|---|---|---|---|---|---|
| External verifiability | Any third party | Members only | TSA plus auditor | Public via L2 | Same as chosen |
| Independence | Holder, KMS, chain | Validator set | TSA and log operator | Same as chosen | Same as chosen |
| Operational burden | Low | **High** | **Lowest** | Low | **High** |
| Feasibility now (C6) | High | **Low** | High | High | Medium |
| Indicative annual cost | Cloud plus A$40–80k anchoring | Staff plus infrastructure | Cloud plus TSA fees | Cloud plus negligible anchoring | Cloud plus platform team |

The chosen design is not "the best" in the abstract but the cheapest that keeps the promise in BO-1 — no single
party can silently rewrite confirmed history — without requiring institutions that do not yet exist. All three
alternatives change the edges of the design, not the core: the event model, the query entrance and the archive
envelope survive each of them.
