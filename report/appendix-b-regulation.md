# Appendix B — Regulation

The body cites obligations in passing. This appendix says what each citation requires and where the design
answers it.

| Obligation | What it requires | Where the design answers it |
|---|---|---|
| Food safety duties and recall powers (NSW Food Act 2003; Food Standards Code) | Conservative recall traversal, signed official notices, and a clear split between "possibly affected" and "confirmed unsafe" | Recall scope at a fixed watermark with provisional set labelled (BO-3); signed notices as canonical events |
| Australian Privacy Principles; NSW PPIP Act 1998 | No personal identifiers in an immutable trace, minimisation at ingestion, correction and deletion in the mutable layer | Three visibility classes; no natural-person field in the event model; private evidence off-platform (SP-3, SP-4) |
| Records retention and legal hold | Per-class retention, terminal deletion states, defensible deletion records | Retention state machine, three-party deletion, anchored deletion record (2.4.5) |
| Evidentiary expectations | Chain of custody, authentication, reproducible derivation | Signed declarations, holder acknowledgement, inclusion and consistency proofs, replayable derivation (SQ-1, SQ-9) |
| Government procurement and residency | Australian regions for non-public data; analytics in the regulator's own account | Sydney primary with Melbourne copies; four accounts (2.5–2.6, 4.14) |
