# Appendix A — Traceability

This appendix carries the two matrices that the body refers to, because they are reference material: a reader
consults them to check a link, not to understand the design.

## A.1 Quality requirement to mechanism to component

| Requirement | Mechanism | Where it lives |
|---|---|---|
| SQ-1 Integrity | Append-only records, signed digest, external acknowledgement, Merkle inclusion, verifiable batch sequence | Orchestrator; relayer; archive |
| SQ-2 Non-repudiation | One envelope for all custody modes; key history retained; acceptance-time authority kept separate from cryptographic validity | Signature & Authority Validator |
| SQ-3 Availability | Fail-closed writes with idempotent retry; reads from materialised data; analytics never in the write path | State machine; workers; outbox |
| SQ-4 Performance | Edge snapshots; lineage from the plaintext query copy; bounded synchronous traversal | Snapshot delivery; `QueryStore`; `QueryPort` |
| SQ-5 Recoverability | The archive, not the database, is the copy of record; a recovery identity outside the platform rebuilds | Archive; recovery identity |
| SQ-6 Usability and accessibility | Browser-first capture, durable offline queue, client-generated identifiers, device-bound signing | Portal; `CaptureSubmission` |
| SQ-7 Privacy | Three visibility classes with no middle tier; content off-platform behind a salted commitment; no natural-person field | `ProtectedResourceRef`; `SignatureEnvelope` |
| SQ-8 Interoperability | EPCIS 2.0 / CBV; versioned profiles; chain-agnostic leaves | Canonicalisation; profile registry |
| SQ-9 Auditability | Watermarks on every projection; replayable derivation; findings bound to rule version and watermark | `QueryPort`; graph builder; manifest |
| SQ-10 Cost | One modular application, one managed database, no broker, batched anchoring | Container and deployment views |
| SQ-11 Device evidence | Summary fields declared by the profile, carried as extension fields, raw data behind a reference | Profile validator; `ProtectedResourceRef` |
| SQ-12 Regulatory screening | Signed rule versions run in the regulator's workspace; the advisory returns as a signed message | Analytics workspace |
| SQ-13 Analysability | Aggregates materialised over the confirmed projection at a watermark, under the same scope rules | `Insights` module |

## A.2 Class to component to container

| Component | Container | Classes |
|---|---|---|
| Capture API, Idempotency | Traceability Application | `CaptureSubmission`, `ProtectedResourceRef` |
| Canonicalisation, Signature Validator | Traceability Application | `CanonicalEvent`, `ProfileVersion`, `SignatureEnvelope` |
| Archive & Anchor Orchestrator | Traceability Application | `ArchiveEnvelope`, `ArchiveAck`, `MerkleLeaf`, `AnchorBatch`, `AcceptanceReceipt` |
| Store, Graph Builder, QueryPort | Traceability Application | `EvidenceEdge`, `EdgeType`, `EdgeQuery`, `EdgeGroup` |
| Anchor Intent Reader, Leaf Allocator, Batch Builder, Chain Submitter, Finality Watcher | Batch Builder & Relayer | — (operates on `MerkleLeaf`, `AnchorBatch`) |
| Analytics Workspace components | Analytics Workspace | `DatasetSnapshot`, `ScreeningRun`, `Rule`, `RuleVersion`, `RuleVersionManifest`, `Finding`, `AdvisoryFinding`, `DisclosurePolicy` |
