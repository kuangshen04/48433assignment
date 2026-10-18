# Software Architecture Document — draft

Working draft of the group report for *Agricultural Supply Chain Tracker*. Written against the marking
criteria in `spec.md`, row by row.

## Status

| Section | Rows | Marks | Draft | File |
|---|---|---|---|---|
| 1. Project Context | 1.1 context, 1.2 relevance, 1.3 exclusions | 3 | **drafted** | [01-project-context.md](01-project-context.md) |
| 2. Requirements Analysis | 2.1–2.8, 2.B bonus | 8 + 2 | **drafted** | [02-requirements.md](02-requirements.md) |
| 3. Architecture Views | 3.1–3.10 | 10 | figures exist, prose pending | see `docs/architecture/c4-*.md` |
| 4. Rationale and Decisions | 4.1–4.20, 4.B bonus | 20 + 5 | not started | — |
| 5. Evaluation and Alternatives | 5.1–5.4 | 4 | not started | — |

## Draft size vs final budget

The draft is deliberately untrimmed, per instruction. The 5,000-word guideline applies to the whole
document, so the trimming pass is substantial and should be planned rather than improvised:

| Section | Draft (words) | Proposed final |
|---|---|---|
| 1. Project Context | 3 536 | 600 |
| 2. Requirements | 6 707 | 1 400 |
| 3. Views | — | 1 200 + 6 figures |
| 4. Rationale | — | 1 400 + tables |
| 5. Evaluation | — | 500 |
| Front matter, captions, appendix | — | 300 |
| **Total** | **10 243** | **≈ 5 400** |

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
- **Identifiers:** stakeholders `S1`–`S12`, objectives `O1`–`O6`, risks `R1`–`R10`, constraints `C1`–`C8`,
  quality requirements `SQ-n`, quality scenarios `QS-n`, data requirements `DM-n`, data scenarios `DS-n`,
  cloud requirements `CL-n`, cloud scenarios `CS-n`, security requirements `SP-n`, AI/IoT requirements
  `AI-n` / `IoT-n`. Section 3 and 4 should cite these instead of restating requirements.
- **Traceability:** every quality requirement in 2.1 must be picked up by a decision in Section 4, and every
  rejected alternative in Section 2 is a candidate for the Section 5 comparison.
- **No internal decision codes** (`B1`, `B21`, …) in the report. Those are the working labels in
  `docs/decisions/`; the report states the reasoning, not the ID.

## Figure sources

Twelve C4 figures are produced. Together they cover rows 3.1–3.10 and 4.14–4.17.

| Figure | Serves rows | File |
|---|---|---|
| System context | 3.1 | `docs/public/diagrams/c4-context.svg` |
| Container view (whole system) | 3.2–3.4, 4.6 | `docs/public/diagrams/core-container.svg` |
| Component view (Traceability Core) | 3.5–3.7 | `docs/public/diagrams/core-component.svg` |
| Component view (Batch Builder & Relayer) | 3.5–3.7 | `docs/public/diagrams/relayer-component.svg` |
| Code view (Core classes and interfaces) | 3.8–3.10, 4.8–4.9 | `docs/public/diagrams/core-code.svg` |
| Container view (Regulatory Analytics) | 3.2–3.4, 4.6 | `docs/public/diagrams/analytics-container.svg` |
| Component view (Analytics Workspace) | 3.5–3.7 | `docs/public/diagrams/analytics-component.svg` |
| Code view (Analytics classes) | 3.8–3.10, 4.9 | `docs/public/diagrams/analytics-code.svg` |
| Dynamic view — event acceptance | 4.16–4.17 | `docs/public/diagrams/c4-dynamic.svg` |
| Dynamic view — recall investigation | 4.17–4.18 | `docs/public/diagrams/c4-dynamic-recall.svg` |
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
