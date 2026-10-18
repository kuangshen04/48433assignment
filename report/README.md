# Software Architecture Document — draft

Working draft of the group report for *Agricultural Supply Chain Tracker*. Written against the marking
criteria in `spec.md`, row by row.

## Status

| Section | Rows | Marks | Draft | File |
|---|---|---|---|---|
| 1. Project Context | 1.1 context, 1.2 relevance, 1.3 exclusions | 3 | **drafted** | [01-project-context.md](01-project-context.md) |
| 2. Requirements Analysis | 2.1–2.8, 2.B bonus | 8 + 2 | **drafted** | [02-requirements.md](02-requirements.md) |
| 3. Architecture Views | 3.1–3.10 | 10 | **drafted** | [03-architecture-views.md](03-architecture-views.md) |
| 4. Rationale and Decisions | 4.1–4.20, 4.B bonus | 20 + 5 | **drafted** | [04-rationale.md](04-rationale.md) |
| 5. Evaluation and Alternatives | 5.1–5.4 | 4 | **drafted** | [05-evaluation.md](05-evaluation.md) |

## Draft size vs final budget

The draft is deliberately untrimmed, per instruction. The 5,000-word guideline applies to the whole
document, so the trimming pass is substantial and should be planned rather than improvised:

| Section | Draft (words) | Proposed final |
|---|---|---|
| 1. Project Context | 3600 | 600 |
| 2. Requirements | 7214 | 1 400 |
| 3. Views | 2955 | 1 400 + 8 figures |
| 4. Rationale | 5791 | 2 000 + tables |
| 5. Evaluation | 2994 | 600 |
| Front matter, captions, appendix | — | 300 |
| **Total so far** | **22554** | **≈ 5 400** |

Two trimming decisions will need a call from the group:

1. **The data dictionary (2.3) is the single largest block** (~30 elements). The criterion asks for "each
   data element", so the final version should keep the dictionary but cut to the ~15 elements that carry a
   design decision (identity, quantity, versions, signature, archive, anchoring, evidence, regulatory
   output) and summarise the rest in a sentence. Cutting it to three rows would lose the mark.
2. **Scenario tables expand quickly.** Sections 2.7–2.8 and 2.B overlap in what they require; in the final
   version, CIA scenarios carry the security argument and 2.B should be compressed to two scenarios plus the
   rejected alternatives.

## Conventions

- **Language:** English. Diagrams also in English; they are also used by the Chinese design site under
  `docs/`.
- **Identifiers:** stakeholders `S1`–`S12`, objectives `O1`–`O8`, risks `R1`–`R10`, constraints `C1`–`C8`,
  quality requirements `SQ-n`, quality scenarios `QS-n`, data requirements `DM-n`, data scenarios `DS-n`,
  cloud requirements `CL-n`, cloud scenarios `CS-n`, security requirements `SP-n`, AI/IoT requirements
  `AI-n` / `IoT-n`. Section 3 and 4 should cite these instead of restating requirements.
- **Traceability:** every quality requirement in 2.1 must be picked up by a decision in Section 4, and every
  rejected alternative in Section 2 is a candidate for the Section 5 comparison.
- **No internal decision codes** (`B1`, `B21`, …) in the report. Those are the working labels in
  `docs/decisions/`; the report states the reasoning, not the ID.

## Figure sources

Thirteen figures are produced. Together they cover rows 3.1–3.10, 4.8–4.9 and 4.14–4.17.

| Figure | Serves rows | File |
|---|---|---|
| System context | 3.1 | `docs/public/diagrams/c4-context.svg` |
| Container view (whole system) | 3.2–3.4, 4.6 | `docs/public/diagrams/core-container.svg` |
| Component view (Traceability Core) | 3.5–3.7 | `docs/public/diagrams/core-component.svg` |
| Component view (Batch Builder & Relayer) | 3.5–3.7 | `docs/public/diagrams/relayer-component.svg` |
| Code view (Core classes and interfaces) | 3.8–3.10, 4.8–4.9 | `docs/public/diagrams/core-code.svg` |
| Container view (Analytics Workspace) | 3.2–3.4, 4.6 | `docs/public/diagrams/analytics-container.svg` |
| Component view (Analytics Workspace) | 3.5–3.7 | `docs/public/diagrams/analytics-component.svg` |
| Code view (Analytics classes) | 3.8–3.10, 4.9 | `docs/public/diagrams/analytics-code.svg` |
| Dynamic view — event acceptance | 4.16–4.17 | `docs/public/diagrams/c4-dynamic.svg` |
| Dynamic view — recall investigation | 4.17–4.18 | `docs/public/diagrams/c4-dynamic-recall.svg` |
| Physical data model | 4.8–4.9 | `docs/public/diagrams/core-physical-model.svg` |
| Deployment view — logical placement | 4.14–4.15 | `docs/public/diagrams/c4-deployment.svg` |
| Deployment view — reference configuration | 4.14–4.15 | `docs/public/diagrams/c4-reference-deployment.svg` |

Two caveats to keep in the report text:

1. **The deployment figure fixes control domains and regions, not products.** Managed database, container
   runtime and KMS products are closed as C1–C3; the figure says so in its own title so a marker does not
   read the abstraction as an omission.
2. **Cross-view consistency (3.10) needs one paragraph in Section 3**, not just the figures: map each
   component to the classes it produces or consumes. The mapping is written up in the Core code-view page.
## Regenerating figures

```powershell
pwsh -File docs/diagrams/render.ps1
```

Needs Java 11+. The PlantUML jar is downloaded on first run; the C4 macro library is vendored.

## Consistency pass (closed, 2026-10-18)

Two independent cold reads of the full draft (one rubric sweep, one adversarial architecture review) converged
on the same class of defect: the prose and the figures disagreed. All of the following were fixed before the
trimming pass, because trimming would otherwise preserve the errors:

| Defect | Fix |
|---|---|
| §4.6 claimed the analytics system appeared in Figure 1; it did not | Figure 1 now carries a `System_Boundary` with both peer subsystems, and §4.6 states the placement accurately |
| Archive / KMS / relayer ownership split between the orchestrator and the workers | §3.4.1, §3.3.2 and Figure 4 agree on one story: the orchestrator records the intent, the worker role executes it; Figure 4 no longer draws outbound edges to externals |
| `ConfirmationStatus` declared a five-value published contract, while three figures used `DRAFT`, `VALIDATED`, `VERIFIED_*` | Enum extended to the real lifecycle (`SUBMITTED`…`REJECTED`); figures and §3.5.1 now use those names; the unverifiable "eighteen lifecycle states" claim is gone |
| `ce \|\|--\|\| ack` (exactly one ack) against "one per event per holder" | Cardinality changed to `\|\|--o{` |
| `operatorSignature` on `ArchiveAck` against "signed by a holder outside the platform" | Renamed `holderSignature` / `holder_signature` |
| `QueryPort` had one method, yet recall needed a bounded recursive traversal | `traverse(EdgeQuery, depth)` added; §2.4.3, §3.5.1, §4.4 and Figure 4 now agree |
| Recall dynamic view had the application writing to the archive and the chain | Workers and relayer are now participants; the application only records intent |
| `RuleVersionManifest` called "the only artefact that leaves"; Figure 3 carries advisories too | Reworded to "the only artefact of the rule domain" |
| "Four flows, and nothing else crosses a boundary" against five further edges | Softened, and the remaining crossing edges are named |
| Relayer described with six components while Figure 5 and §4.5 count seven | `Finality Watcher` added to §3.4.2 |
| Deployment figures had three orphan nodes and a reversed origin-pull edge | `recovery`, `attestor` and `regmirror` are connected; `cdn → origin` and `pwa → cdn` directions fixed; `relayer → db` restored in the reference view |
| QS-3 and QS-4 had their quality attributes swapped in the ATAM utility tree | Corrected (`QS-3` availability, `QS-4` performance) |
| AN-1 said "measured workload" with no measurement in the report | Replaced with the pilot figure and its arithmetic |
| BO-9 cited the rubric in its Source column | Removed |
| §2 said objectives `O1`–`O6` while Section 1 defines `O1`–`O8` | Corrected |
| §4.7 named an `Insights mart` container that Figure 2 does not contain | Now the materialised views inside Operational PostgreSQL |
| §4.8 claimed the conceptual model was visible in Figures 4 and 7 | Now states what each figure actually contributes |

Still open from those reads, deliberately deferred to the trimming and closing passes: the portal's
role-specific screens are named but not specified (K3); §5.2 now has one `Partly met` verdict but still no
`Not met` (K4); cost is order-of-magnitude only; and the glossary appendix is not written.

## Brief coverage: the seven case-study bullets

Both cold reads checked the report against the case study's own bullet list, not only against the rubric. The
state after the closing pass:

| Bullet | Where it is answered | State |
|---|---|---|
| Immutable record-keeping | §1 O2/R3; §2 SQ-1, QS-1; §3 write path; §4.2, §4.19; BO-1 | Designed |
| Interfaces for four participant types | §3.3.1 portal row names the role-specific entry points; SQ-6; BO-2, BO-4 | Named per role, screens not specified (K3) |
| IoT integration | §3.2 device interface; SQ-11, QS-12; 4.B; BO-8 | Designed |
| Multiple product lines and regions | SQ-8; profiles; BO-6 | Product lines designed; regions are a governance and deployment step |
| Food-safety compliance | §2.8.4; SQ-9, SQ-12; BO-3, BO-9 | Designed as evidence and scope, not as a compliance mapping |
| **Data visualisation for insights** | **SQ-13, QS-13; §3.4.1 `Insights`; §4.1, §4.7; BO-10** | **Closed in the closing pass (K2): requirement, scenario, module and objective now exist; the presentation layer is deliberately a thin client** |
| Rural accessibility | SQ-6 (WCAG 2.2 AA, 200 % text, icon plus plain-language label, 2G-class capture); BO-2 | Closed as a measurable requirement |

## Known gaps in Section 2 (recorded, not yet fixed)

Assessed row by row against spec.md. None of these blocks Section 3; they are to be closed in the trimming pass or just before submission.

| ID | Row | Gap | Why it matters | Effort |
|---|---|---|---|---|
| G1 | 2.3 | The data dictionary's "Serves" column mixes requirement IDs and stakeholder IDs | 2.3 asks for a connection to *customer and stakeholder* needs; should be S-ids only, or two columns | small |
| G2 | 2.3 | Missing elements: organisation/key/delegation registries, profile document, batch manifest, acceptance receipt, inclusion proof, evidence-request audit record, watermark/health fields | These are the elements most of the security argument rests on | medium |
| G3 | 2.4 | No explicit retention period per data class (only a seven-year capacity assumption) | 2.4 requires retention to be defined, not just its terminal states | small |
| G4 | 2.4 | No data volume estimate (events, rows, GB over seven years) | Storage justification reads as opinion without magnitude | small |
| G5 | 2.2 | Risk table has no impact/likelihood rating | 2.2 asks to *evaluate* risks, not only list them | small |
| G6 | 2.2 | Some scenarios lack a measurable response (SQ-6 usability, SQ-4 partially) | "Moderated pilot session" is not a measure | small |
| G7 | 2.1 | SQ rows do not point back to objectives O1–O6 | Makes 4.1 (quality alignment) harder to write | small |
| G8 | 2.7 | Security requirements omit build and run concerns: secrets, dependency/image scanning, patching, log retention | Reviewers ask "who patches the platform" | small |
| G9 | 2.8 | Privacy is stated as minimisation, but there is no data-flow view (which field goes to which domain, for how long, readable by whom) | This is the artefact a privacy reviewer looks for | medium |
| G10 | 2.B | IoT requirements are qualitative: no sampling rate, reporting interval, summary window, device count or volume | 2.B asks for requirements through scenarios, which implies numbers | small |
| G11 | whole | No requirements traceability matrix (stakeholder → SQ/DM/CL/SP → design element) | 4.1 and 4.11 will otherwise re-derive it | medium |
| G12 | whole | Trimming plan not executed: 6 707 words against a 1 400 target; the "15 dictionary elements" decision is still open | Needed before submission | medium |
| G13 | 2.4 | Backup/PITR appears as DB-6 but without a restore-drill acceptance sentence | Pairs with the C3 validation scenarios | small |
| G14 | 2.6 | No order-of-magnitude cost (Aurora + gas + archive) | 4.11/4.13 will need one; cheaper-alternatives argument needs it too | small |

Priority for the next pass: **G12 (trimming) drives the rest** — decide the dictionary subset first, because G1/G2/G4 all shrink with it. G5/G6/G7 are quick wins; G8/G9 are the two a marker is most likely to probe.

## Known gaps in Section 4 (recorded, not yet fixed)

| ID | Row | Gap | Effort |
|---|---|---|---|
| H1 | 4.2 | Tactics are stated in prose per quality; a tactic-to-quality matrix would scan faster and is what a marker looks for | small |
| H2 | 4.5 | "Dense structure" is asserted with component counts; a dependency-direction figure or a small coupling table would prove it | small |
| H3 | 4.11/4.13 | No order-of-magnitude monthly cost (Aurora, Fargate, storage, gas), which 4.11 implicitly needs when justifying managed services | small |
| H4 | 4.17 | The recall data-flow is described in prose; a hop-by-hop table like the acceptance one would mirror it properly | small |
| H5 | 4.19 | STRIDE rows lack a likelihood/impact qualifier, so "residual" reads as a note rather than a rating | small |
| H6 | 4.B | The bonus section argues placement but cites no scenario number from 2.B; cross-referencing IS-1/IS-2 would tighten it | small |

Priority: H3 (cost) is the one a reviewer will ask for first, because the cloud argument and the cheaper-alternative argument both lean on it.

## Known gaps in Section 5 (recorded, not yet fixed)

| ID | Row | Gap | Effort |
|---|---|---|---|
| J1 | 5.2 | Verdicts are qualitative; a simple score per objective (met / partly / not) would make the evaluation scannable | small |
| J2 | 5.3 | The ATAM risk list is not cross-referenced to the risks in Section 1 (R1–R10), so a reader cannot tell which project risks became architectural risks | small |
| J3 | 5.4 | Alternatives carry indicative cost only for the chosen design; A1/A2/A4 need at least a magnitude so the comparison is fair | small |
| J4 | 5.4 | No "what would change our mind" threshold for A2 (e.g., if chain costs exceed X or policy forbids public networks) | small |

## Trimming guardrail: IoT and AI/ML must survive the cut

Both are **requirements**, not decoration, so they must not live only in the bonus subsections (2.B / 4.B). They are now anchored in the main body:

| Where | IoT | AI/ML (regulatory screening) |
|---|---|---|
| Section 1 | O7, S12, R4 | O8, S7 |
| Section 2 | SQ-11, QS-12, 2.B | SQ-12, QS-11, 2.B (AI-1…3) |
| Section 3 | Device interface in 3.2 (delegation, summary schema, three latency tiers) | Analytics at container, component and code level |
| Section 4 | 4.B (IoT-1…3) | 4.6, 4.B (AI-1…3) |
| Section 5 | BO-8 + verdict | BO-9 + verdict |

When trimming: keep **one requirement row, one scenario, one objective and one verdict** for each, plus the sentence that ML is optional while the capability is not. Do not delete the Section 3 sentence about devices attaching to participants — it is the design decision the brief actually asks about.

**K1 closed.** Section 3.2 now carries the device interface: delegation-based device identity, the profile-declared summary schema, the reference-plus-commitment treatment of raw data, and the three latency tiers with one owner each. IoT is now visible in the views chapter, not only in 2.B / 4.B.
