# 5. Architecture Evaluation and Alternatives

## 5.1–5.2 Business objectives and how well they are met

| ID | Objective | Source | Verdict | Evidence and residual gap |
|---|---|---|---|---|
| BO-1 | An immutable, attributable record of every stage | Brief | **Met** | Envelope, holder-signed acknowledgement, Merkle inclusion; collusion is detected only by third-party comparison, not prevented |
| BO-2 | Every participant can contribute, including the smallest | Brief | **Met, conditionally** | Browser capture, offline queue, device-bound signing; devices without key storage fall back to draft-and-sign-online |
| BO-3 | A regulator establishes incident scope quickly and defensibly | Brief | **Met** | Traversal at a watermark with per-edge provenance; cost grows with history and the graph-store trigger is unmeasured |
| BO-4 | Consumers see a truthful, current-enough view | Brief | **Met** | Versioned snapshots with explicit states; a cached snapshot can lag a notice, and the resolver rules are specified but not implemented |
| BO-5 | Commercial and personal data are not exposed | Implied | **Met, with residual risk** | Content off-platform with owner-chosen recipients; metadata and access patterns remain visible |
| BO-6 | Growth across products and regions without a rebuild | Brief | **Partly met** | Profiles and per-jurisdiction requirements are additive; a region still needs a deployment and governance step |
| BO-7 | Operable by a small team at pilot scale | C6 | **Met at pilot scale** | Managed services, one deployable, batched anchoring; two more operated environments exist |
| BO-8 | Device evidence without handing over raw telemetry | Brief | **Met, conditionally** | Summaries are attributable and raw data stays private; coverage depends on participant instrumentation |
| BO-9 | Regulatory screening as a capability, ML optional | Brief | **Met structurally** | Analytics at all three C4 levels with signed rule versions; depends on the regulator operating its runtime |
| BO-10 | Supply-chain insight is readable, not merely queryable | Brief | **Partly met** | Aggregation, watermark and scope designed; the view layer is a thin client named, not specified |

The honest summary: the evidentiary objectives are met strongly, growth is met by configuration rather than
construction, coverage depends on devices and connectivity, and insight is met at the data layer with the
presentation layer left to the client.

## 5.3 ATAM analysis

ATAM was chosen over HAZOP because the system controls no physical process: its hazards are evidentiary and
informational, not physical, and its failure modes are already enumerated as lifecycle states and dependency
failures.

**Utility tree.**

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

**Risks.**

| ID | Risk | Response |
|---|---|---|
| AR-1 | External holders or the chain stall ingestion | Quorum one; outbox buffering; backlog age monitored; refusal is visible |
| AR-2 | Flat read scope makes admission the only confidentiality control | Entity verification, sponsor, dual approval, read audit; residual risk stated |
| AR-3 | The regulator may not operate its runtime | Analytics is optional; trace and manual investigation continue |
| AR-4 | Chain fees and finality vary | Fixed windows, empty windows skipped, cost estimated with a range and a measurement plan |
| AR-5 | Single-region active-passive; a regional loss takes up to 24 hours | Cross-region copies; target proven only by drill |
| AR-6 | The field floor grows and burdens the smallest participants | Module manifests make growth governed; retirement is a known gap |
| AR-7 | One relayer, one wallet | Key in KMS; isolated deployment; deterministic leaves allow re-anchoring |

**Non-risks.** "A monolith will not scale" — 10 000 events/day is about one write every eight seconds, three
orders of magnitude below one indexed database. "Chain cost will explode" — one transaction per window, empty
windows skipped. "A plaintext copy contradicts the privacy claim" — it holds consortium data the platform is
authorised to read, is rebuildable, and never holds private content. "An immutable log defeats deletion" — no
natural-person field ever enters it, so deletion is discharged in the mutable layer.

**Trade-offs and sensitivities.**

| Type | Point | What moves |
|---|---|---|
| Trade-off | Finality versus freshness | Shorter windows improve freshness and raise cost; the provisional plane is the compromise |
| Trade-off | Shared visibility versus confidentiality | Narrower scope improves confidentiality and weakens the recall-authority story |
| Trade-off | Evidentiary strength versus forensics | Hosting private content would help investigations and destroy the privacy claim |
| Sensitivity | Anchor window (30 min) | Confirmation latency, gas cost, backlog risk |
| Sensitivity | Holder set and quorum | Gate availability and the independence argument |
| Sensitivity | Field floor and scope model | Capture effort, recall completeness, confidentiality |

## 5.4 Realistic alternatives

**A1 — Permissioned consortium ledger.** Four to seven validators (platform, producer body, retailer, regulator,
auditor) running BFT consensus with private groups and on-chain membership. *Strengths:* seconds-level
deterministic finality, finer privacy groups, governance as code, no fee market. *Weaknesses:* needs at least
four genuinely independent operators with HSMs, on-call and a charter, and it is not publicly verifiable — the
guarantee is "the members agree". *Feasibility now:* low; no consortium, no funded operators. It wins if an
existing industry body commits operators and a charter.

**A2 — No blockchain: trusted timestamping plus a transparency log.** Encrypted payloads in WORM storage, each
batch digest timestamped (RFC 3161) and roots published to an append-only Merkle log co-signed by an auditor.
*Strengths:* uses institutions that exist today, much cheaper, and the log supplies append-only evidence and
public monitoring — most of what the chain contributes. *Weaknesses:* two or three trusted parties instead of a
public network, so "no single operator can rewrite history" becomes "not without these two as well".
*Feasibility:* high; the strongest fallback and the one a procurement reviewer would propose.

**A3 — Layer-2 anchoring.** The same architecture with roots submitted to a rollup: identical envelope, leaf and
proof semantics, change confined to the relayer and the verifier. *Strengths:* cost falls by orders of
magnitude, confirmation is faster. *Weaknesses:* depends on a sequencer and on that L2 surviving a seven-year
horizon. *Feasibility:* high — a configuration variant, which is itself evidence the leaf format was chosen
well.

**A4 — Microservices with an event bus.** Capture, validation, orchestration, anchoring, projection and query as
separate services with per-service databases. *Strengths:* independent scaling, team autonomy, failure
isolation. *Weaknesses:* every in-process call becomes distributed, transactions become sagas, and a broker,
registry and operational platform appear — cost without benefit at 10 000 events/day. *Feasibility:*
technically high, organisationally unnecessary for a six-person team.

| Criterion | Chosen | A1 | A2 | A3 | A4 |
|---|---|---|---|---|---|
| External verifiability | Any third party | Members only | TSA plus auditor | Public via L2 | Same as chosen |
| Independence | Holder, KMS, chain | Validator set | TSA and log operator | Same as chosen | Same as chosen |
| Privacy control | Content off-platform | Private groups | Same as chosen | Same as chosen | Same as chosen |
| Operational burden | Low | **High** | **Lowest** | Low | **High** |
| Feasibility now (C6) | High | **Low** | High | High | Medium |
| Indicative annual cost | Cloud plus A$40–80k anchoring | Staff plus infrastructure | Cloud plus TSA fees | Cloud plus negligible anchoring | Cloud plus platform team |

**When each would win.** A1 when an industry body funds five operators and a charter. A2 when public-chain
anchoring is rejected on cost or policy and a timestamp authority plus audited log is accepted as sufficient
evidence — the cheapest design that still produces third-party-verifiable existence proofs. A3 when anchoring
cost becomes material and a shorter horizon is acceptable. A4 when volume grows by two orders of magnitude and
more than one team owns the services.

The chosen design is therefore not "the best" in the abstract but the cheapest that keeps the promise in BO-1 —
no single party can silently rewrite confirmed history — without requiring institutions that do not yet exist.
Its useful property is that all three alternatives change the edges of the design, not the core: the event
model, the query entrance and the archive envelope survive each of them, which is what makes the alternatives
genuinely available rather than rhetorical.
