# Traceability Data Dictionary

The lengths below are physical working assumptions for the PostgreSQL model. URI fields use bounded text for indexability; exact external standards remain governed by the selected product profile.

| Data element | PostgreSQL format | Length or precision | Description | Source | Stakeholder need |
|---|---|---:|---|---|---|
| organisation_id | uuid | 36 characters when rendered | Internal identifier for a consortium organisation | Registry | Attributes events, keys, policies and access to a legal participant |
| organisation_status | varchar | 16 | ACTIVE, SUSPENDED or OFFBOARDED | Consortium administrator | Prevents unauthorised new submissions while preserving history |
| site_id | uuid | 36 | Registered business or observation site | Organisation administrator | Supports location-aware provenance without embedding unrestricted address data |
| identity_id | uuid | 36 | User, service or device-signing identity | Identity provider or registry | Identifies the actor that signs or requests data |
| key_id | uuid | 36 | Public signing-key record | Organisation or KMS | Verifies historical publisher signatures and revocation status |
| key_fingerprint | char | 64 | SHA-256 fingerprint of the public key | Registry | Detects key substitution and supports audit |
| profile_id | uuid | 36 | Product-profile family identifier | Consortium administrator | Supports multiple product lines with a stable core model |
| profile_version_id | uuid | 36 | Immutable version of product validation rules | Consortium administrator | Reproduces validation and interpretation of historical events |
| visibility_policy_id | uuid | 36 | Versioned disclosure-policy identifier | Consortium administrator | Controls consumer, participant and auditor views |
| retention_policy_id | uuid | 36 | Versioned retention-policy identifier | Product or regional profile | Applies retention without inventing a universal legal duration |
| event_id | uuid | 36 | Globally unique trace-event identifier | Client or enterprise system | Enables idempotency, signatures, ledger commitment and audit |
| submission_id | uuid | 36 | Server-side record of one canonical submission lifecycle | Traceability Application | Tracks validation, retry, ledger and projection state |
| event_type | varchar | 32 | OBJECT, AGGREGATION, TRANSFORMATION or ERROR_DECLARATION | Publisher | Selects domain semantics and validation rules |
| event_time | timestamptz | 8 bytes | Time the physical-world event occurred | Publisher | Preserves actual business chronology |
| timezone_offset_minutes | smallint | -840 to 840 | Local offset at the event location | Publisher | Preserves the event's local-time context |
| record_time | timestamptz | 8 bytes | Time the repository accepted the event record | Repository | Distinguishes offline occurrence from later ingestion |
| publisher_organisation_id | uuid | 36 | Organisation responsible for the assertion | Authenticated publisher | Establishes accountability and access scope |
| signing_identity_id | uuid | 36 | Identity whose key signed the event | Authenticated publisher | Supports non-repudiation and key-history verification |
| biz_step | varchar | 255 | Controlled business-step URI or code | Publisher/profile | Describes commissioning, shipping, receiving, packing or processing |
| disposition | varchar | 255 | Controlled post-event business status URI or code | Publisher/profile | Supports derived state and consumer or auditor interpretation |
| read_point_site_id | uuid | 36 | Site where the event was observed | Publisher | Supports evidence and operational trace |
| business_location_site_id | uuid | 36 | Business location attributed after the event | Publisher | Supports custody and last-known-location projection |
| object_id | varchar | 512 | GS1-compatible or platform URI for a batch, pallet or other traceable object | Publisher or registry | Connects events into provenance |
| object_type | varchar | 32 | BATCH, LOGISTIC_UNIT, PRODUCT_CLASS or supported extension | Product profile | Applies appropriate event and relationship rules |
| object_role | varchar | 16 | SUBJECT, PARENT, CHILD, INPUT or OUTPUT | Event normaliser | Defines the object's meaning within an event |
| quantity | numeric | 20,6 | Quantity attributed to an event-object role | Publisher | Supports partial handover and split or merge validation |
| uom | varchar | 12 | Profile-approved unit code | Publisher/profile | Makes quantities interpretable and convertible |
| payload_commitment | char | 64 | Hex SHA-256 commitment of canonical event content | Commitment builder | Detects any post-commitment content change |
| canonicalisation_version | varchar | 32 | Version of the canonicalisation algorithm | Traceability Application | Allows future systems to reproduce the commitment |
| signature_algorithm | varchar | 32 | Algorithm identifier for event signature | Signing identity/profile | Enables algorithm agility and verification |
| signature | bytea | Variable | Digital signature over canonical event and required envelope | Publisher | Proves attribution and detects modification |
| submission_status | varchar | 24 | RECEIVED, VALIDATED, PAYLOAD_STORED, PENDING_LEDGER, LEDGER_RETRY, COMMITTED, PROJECTED, PROJECTION_RETRY, REJECTED or SUPERSEDED | Traceability Application | Makes partial failure explicit |
| correction_reason | varchar | 64 | Controlled reason for an Error Declaration | Correcting organisation | Explains why a historical assertion is superseded |
| original_event_id | uuid | 36 | Event being corrected | Correcting event | Preserves correction chain |
| corrective_event_id | uuid | 36 | Event providing the effective interpretation | Correcting organisation | Resolves current interpretation without deletion |
| artifact_id | uuid | 36 | Platform identifier for an external artifact reference | Publisher or evidence provider | Links evidence without copying sensitive content |
| artifact_type | varchar | 32 | IOT_RAW, CERTIFICATE, LAB_REPORT, IMAGE, DOCUMENT or PRIVATE_EXTENSION | Evidence provider/profile | Selects policy and presentation behaviour |
| provider_type | varchar | 32 | DMS, S3_COMPATIBLE, SHAREPOINT, IOT_PLATFORM, LAB_API or OTHER | Artifact owner | Routes resolution to the correct adapter |
| opaque_locator | varchar | 1024 | Stable provider-specific identifier with no credentials | Artifact owner | Locates content without storing permanent access tokens |
| content_commitment | char | 64 | Hex commitment to nonce and canonicalised artifact | Artifact owner | Detects replacement or modification of external content |
| commitment_scheme | varchar | 64 | For example SHA256_NONCE_CANONICAL_V1 | Artifact owner/profile | Defines how authorised verification is performed |
| artifact_availability_status | varchar | 16 | AVAILABLE, UNAVAILABLE, EXPIRED or REVOKED | Provider adapter | Separates availability from integrity |
| ledger_network_id | varchar | 128 | Logical consortium-ledger identifier | Ledger adapter | Distinguishes commitments across networks |
| ledger_transaction_id | varchar | 256 | Unique ledger transaction or receipt identifier | Consortium ledger | Locates independently verifiable commitment |
| ledger_sequence | bigint | 64-bit | Monotonic sequence when supported by ledger implementation | Consortium ledger | Orders projections and audit checkpoints |
| committed_at | timestamptz | 8 bytes | Ledger-confirmation time | Consortium ledger | Distinguishes payload persistence from shared acceptance |
| edge_id | uuid | 36 | Identifier for a derived provenance edge | Projection Worker | Supports replay, audit and recursive traversal |
| edge_type | varchar | 16 | CONTAINS or DERIVED_FROM in `trace_edge`; HANDOVER in handover projection | Projection Worker | Represents provenance structure |
| from_object_id | varchar | 512 | Source or parent object of a derived edge | Projection Worker | Supports upstream and downstream traversal |
| to_object_id | varchar | 512 | Output or child object of a derived edge | Projection Worker | Supports upstream and downstream traversal |
| handover_id | uuid | 36 | Derived identifier correlating shipping and receiving assertions | Projection Worker | Represents multi-party transfer state |
| handover_state | varchar | 20 | PENDING, ACCEPTED, PARTIAL, REJECTED or DISPUTED | Projection Worker | Preserves both parties' assertions and discrepancy state |
| projection_sequence | bigint | 64-bit | Last committed sequence represented by a projection | Projection Worker | Exposes projection freshness and supports replay |
| risk_score | numeric | 5,4 | Optional advisory risk score from 0 to 1 | Risk Analysis Service | Supports human review without changing source facts |
| model_version | varchar | 128 | Identifier and version of the model generating a risk score | Risk Analysis Service | Enables reproducibility and governance of derived AI data |

