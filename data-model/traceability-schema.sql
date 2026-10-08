-- Agricultural Supply Chain Traceability Network
-- PostgreSQL 16+ physical model baseline for Week 10.
-- This schema is a design artifact. Provider-specific RLS, encryption and
-- partition sizes are deployment decisions, not omitted architectural duties.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS registry;
CREATE SCHEMA IF NOT EXISTS events;
CREATE SCHEMA IF NOT EXISTS projection;
CREATE SCHEMA IF NOT EXISTS operations;

-- ---------------------------------------------------------------------------
-- Registry schema
-- ---------------------------------------------------------------------------

CREATE TABLE registry.organisation (
    organisation_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organisation_code varchar(128) NOT NULL UNIQUE,
    legal_name varchar(255) NOT NULL,
    status varchar(16) NOT NULL
        CHECK (status IN ('ACTIVE', 'SUSPENDED', 'OFFBOARDED')),
    region_code varchar(32),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    version bigint NOT NULL DEFAULT 1 CHECK (version > 0)
);

CREATE TABLE registry.site (
    site_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organisation_id uuid NOT NULL
        REFERENCES registry.organisation (organisation_id),
    site_code varchar(128) NOT NULL,
    display_name varchar(255) NOT NULL,
    region_code varchar(32),
    jurisdiction_code varchar(32),
    timezone_name varchar(64) NOT NULL,
    status varchar(16) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'SUSPENDED', 'CLOSED')),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (organisation_id, site_code)
);

CREATE TABLE registry.identity (
    identity_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organisation_id uuid NOT NULL
        REFERENCES registry.organisation (organisation_id),
    subject_ref varchar(255) NOT NULL,
    identity_type varchar(16) NOT NULL
        CHECK (identity_type IN ('USER', 'SERVICE', 'DEVICE')),
    status varchar(16) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'SUSPENDED', 'REVOKED')),
    created_at timestamptz NOT NULL DEFAULT now(),
    revoked_at timestamptz,
    UNIQUE (organisation_id, subject_ref)
);

CREATE TABLE registry.signing_key (
    key_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    identity_id uuid NOT NULL
        REFERENCES registry.identity (identity_id),
    algorithm varchar(32) NOT NULL,
    public_key_pem text NOT NULL,
    key_fingerprint char(64) NOT NULL UNIQUE
        CHECK (key_fingerprint ~ '^[0-9a-f]{64}$'),
    valid_from timestamptz NOT NULL,
    valid_until timestamptz,
    revoked_at timestamptz,
    CHECK (valid_until IS NULL OR valid_until > valid_from)
);

CREATE TABLE registry.membership (
    membership_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    identity_id uuid NOT NULL
        REFERENCES registry.identity (identity_id),
    organisation_id uuid NOT NULL
        REFERENCES registry.organisation (organisation_id),
    site_id uuid REFERENCES registry.site (site_id),
    role_code varchar(64) NOT NULL,
    valid_from timestamptz NOT NULL,
    valid_until timestamptz,
    CHECK (valid_until IS NULL OR valid_until > valid_from)
);

CREATE TABLE registry.device (
    device_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_organisation_id uuid NOT NULL
        REFERENCES registry.organisation (organisation_id),
    signing_key_id uuid REFERENCES registry.signing_key (key_id),
    device_ref varchar(512) NOT NULL UNIQUE,
    status varchar(16) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'SUSPENDED', 'REVOKED', 'RETIRED')),
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE registry.product_profile (
    profile_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_code varchar(128) NOT NULL UNIQUE,
    display_name varchar(255) NOT NULL,
    status varchar(16) NOT NULL
        CHECK (status IN ('DRAFT', 'ACTIVE', 'DEPRECATED')),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE registry.profile_version (
    profile_version_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id uuid NOT NULL
        REFERENCES registry.product_profile (profile_id),
    version_label varchar(64) NOT NULL,
    schema_document jsonb NOT NULL,
    validation_rules jsonb NOT NULL,
    effective_from timestamptz NOT NULL,
    deprecated_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (profile_id, version_label),
    CHECK (deprecated_at IS NULL OR deprecated_at > effective_from)
);

CREATE TABLE registry.visibility_policy (
    visibility_policy_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_code varchar(128) NOT NULL,
    version_label varchar(64) NOT NULL,
    policy_document jsonb NOT NULL,
    effective_from timestamptz NOT NULL,
    retired_at timestamptz,
    UNIQUE (policy_code, version_label),
    CHECK (retired_at IS NULL OR retired_at > effective_from)
);

CREATE TABLE registry.retention_policy (
    retention_policy_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_code varchar(128) NOT NULL,
    version_label varchar(64) NOT NULL,
    jurisdiction_code varchar(32),
    data_category varchar(64) NOT NULL,
    retain_for interval,
    deletion_action varchar(32) NOT NULL
        CHECK (deletion_action IN ('DELETE', 'ANONYMISE', 'CRYPTO_SHRED', 'RETAIN_COMMITMENT')),
    legal_hold_supported boolean NOT NULL DEFAULT true,
    policy_document jsonb NOT NULL DEFAULT '{}'::jsonb,
    UNIQUE (policy_code, version_label)
);

-- ---------------------------------------------------------------------------
-- Events schema
-- ---------------------------------------------------------------------------

CREATE TABLE events.event_submission (
    submission_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id uuid NOT NULL UNIQUE,
    payload_commitment char(64) NOT NULL
        CHECK (payload_commitment ~ '^[0-9a-f]{64}$'),
    status varchar(24) NOT NULL
        CHECK (status IN (
            'RECEIVED', 'VALIDATED', 'PAYLOAD_STORED', 'PENDING_LEDGER',
            'LEDGER_RETRY', 'COMMITTED', 'PROJECTED', 'PROJECTION_RETRY',
            'REJECTED', 'SUPERSEDED'
        )),
    received_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    retry_count integer NOT NULL DEFAULT 0 CHECK (retry_count >= 0),
    rejection_code varchar(64),
    rejection_detail text,
    committed_at timestamptz,
    projected_at timestamptz
);

CREATE TABLE events.traceable_object (
    object_id varchar(512) PRIMARY KEY,
    object_type varchar(32) NOT NULL
        CHECK (object_type IN ('BATCH', 'LOGISTIC_UNIT', 'PRODUCT_CLASS', 'OTHER')),
    product_class_ref varchar(512),
    profile_version_id uuid NOT NULL
        REFERENCES registry.profile_version (profile_version_id),
    created_at timestamptz NOT NULL DEFAULT now(),
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE events.trace_event (
    event_id uuid PRIMARY KEY,
    submission_id uuid NOT NULL UNIQUE
        REFERENCES events.event_submission (submission_id),
    event_type varchar(32) NOT NULL
        CHECK (event_type IN ('OBJECT', 'AGGREGATION', 'TRANSFORMATION', 'ERROR_DECLARATION')),
    profile_version_id uuid NOT NULL
        REFERENCES registry.profile_version (profile_version_id),
    publisher_organisation_id uuid NOT NULL
        REFERENCES registry.organisation (organisation_id),
    signing_identity_id uuid NOT NULL
        REFERENCES registry.identity (identity_id),
    signing_key_id uuid NOT NULL
        REFERENCES registry.signing_key (key_id),
    event_time timestamptz NOT NULL,
    timezone_offset_minutes smallint NOT NULL
        CHECK (timezone_offset_minutes BETWEEN -840 AND 840),
    record_time timestamptz NOT NULL DEFAULT now(),
    biz_step varchar(255),
    disposition varchar(255),
    read_point_site_id uuid REFERENCES registry.site (site_id),
    business_location_site_id uuid REFERENCES registry.site (site_id),
    visibility_policy_id uuid NOT NULL
        REFERENCES registry.visibility_policy (visibility_policy_id),
    retention_policy_id uuid NOT NULL
        REFERENCES registry.retention_policy (retention_policy_id),
    retain_until timestamptz,
    legal_hold boolean NOT NULL DEFAULT false,
    canonicalisation_version varchar(32) NOT NULL,
    hash_algorithm varchar(32) NOT NULL DEFAULT 'SHA-256',
    payload_commitment char(64) NOT NULL
        CHECK (payload_commitment ~ '^[0-9a-f]{64}$'),
    signature_algorithm varchar(32) NOT NULL,
    signature bytea NOT NULL,
    canonical_event jsonb NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE events.event_object (
    event_id uuid NOT NULL
        REFERENCES events.trace_event (event_id),
    object_id varchar(512) NOT NULL
        REFERENCES events.traceable_object (object_id),
    object_role varchar(16) NOT NULL
        CHECK (object_role IN ('SUBJECT', 'PARENT', 'CHILD', 'INPUT', 'OUTPUT')),
    ordinal smallint NOT NULL DEFAULT 0 CHECK (ordinal >= 0),
    quantity numeric(20,6),
    uom varchar(12),
    PRIMARY KEY (event_id, object_id, object_role, ordinal),
    CHECK ((quantity IS NULL AND uom IS NULL) OR (quantity IS NOT NULL AND uom IS NOT NULL)),
    CHECK (quantity IS NULL OR quantity >= 0)
);

CREATE TABLE events.event_correction (
    original_event_id uuid NOT NULL
        REFERENCES events.trace_event (event_id),
    error_declaration_event_id uuid PRIMARY KEY
        REFERENCES events.trace_event (event_id),
    corrective_event_id uuid NOT NULL UNIQUE
        REFERENCES events.trace_event (event_id),
    reason_code varchar(64) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (original_event_id <> error_declaration_event_id),
    CHECK (original_event_id <> corrective_event_id),
    CHECK (error_declaration_event_id <> corrective_event_id)
);

CREATE TABLE events.external_artifact (
    artifact_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_organisation_id uuid NOT NULL
        REFERENCES registry.organisation (organisation_id),
    artifact_type varchar(32) NOT NULL
        CHECK (artifact_type IN (
            'IOT_RAW', 'CERTIFICATE', 'LAB_REPORT', 'IMAGE',
            'DOCUMENT', 'PRIVATE_EXTENSION', 'OTHER'
        )),
    provider_type varchar(32) NOT NULL,
    opaque_locator varchar(1024) NOT NULL,
    content_commitment char(64) NOT NULL
        CHECK (content_commitment ~ '^[0-9a-f]{64}$'),
    commitment_scheme varchar(64) NOT NULL,
    canonicalisation_version varchar(32) NOT NULL,
    hash_algorithm varchar(32) NOT NULL DEFAULT 'SHA-256',
    content_type varchar(255),
    content_size_bytes bigint CHECK (content_size_bytes IS NULL OR content_size_bytes >= 0),
    provider_signature bytea,
    signature_algorithm varchar(32),
    access_policy_id uuid NOT NULL
        REFERENCES registry.visibility_policy (visibility_policy_id),
    retention_policy_id uuid NOT NULL
        REFERENCES registry.retention_policy (retention_policy_id),
    retain_until timestamptz,
    legal_hold boolean NOT NULL DEFAULT false,
    availability_status varchar(16) NOT NULL
        CHECK (availability_status IN ('AVAILABLE', 'UNAVAILABLE', 'EXPIRED', 'REVOKED')),
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    revoked_at timestamptz,
    UNIQUE (owner_organisation_id, provider_type, opaque_locator)
);

CREATE TABLE events.event_artifact (
    event_id uuid NOT NULL
        REFERENCES events.trace_event (event_id),
    artifact_id uuid NOT NULL
        REFERENCES events.external_artifact (artifact_id),
    relationship_type varchar(32) NOT NULL
        CHECK (relationship_type IN ('SUPPORTS', 'RAW_SOURCE', 'CERTIFIES', 'EXTENDS')),
    PRIMARY KEY (event_id, artifact_id, relationship_type)
);

CREATE TABLE events.ledger_commitment (
    event_id uuid PRIMARY KEY
        REFERENCES events.trace_event (event_id),
    ledger_network_id varchar(128) NOT NULL,
    ledger_transaction_id varchar(256) NOT NULL UNIQUE,
    ledger_sequence bigint,
    committed_at timestamptz NOT NULL,
    canonicalisation_version varchar(32) NOT NULL,
    hash_algorithm varchar(32) NOT NULL,
    payload_commitment char(64) NOT NULL
        CHECK (payload_commitment ~ '^[0-9a-f]{64}$'),
    receipt jsonb NOT NULL
);

CREATE TABLE events.outbox_message (
    message_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_type varchar(32) NOT NULL,
    aggregate_id varchar(512) NOT NULL,
    message_type varchar(128) NOT NULL,
    payload jsonb NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    published_at timestamptz,
    retry_count integer NOT NULL DEFAULT 0 CHECK (retry_count >= 0),
    last_error text
);

-- ---------------------------------------------------------------------------
-- Projection schema. All tables are rebuildable from committed events.
-- ---------------------------------------------------------------------------

CREATE TABLE projection.trace_edge (
    edge_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    edge_type varchar(16) NOT NULL
        CHECK (edge_type IN ('CONTAINS', 'DERIVED_FROM')),
    from_object_id varchar(512) NOT NULL,
    to_object_id varchar(512) NOT NULL,
    source_event_id uuid NOT NULL,
    valid_from timestamptz NOT NULL,
    valid_until timestamptz,
    state varchar(16) NOT NULL DEFAULT 'ACTIVE'
        CHECK (state IN ('ACTIVE', 'ENDED', 'SUPERSEDED')),
    quantity numeric(20,6),
    uom varchar(12),
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    CHECK (from_object_id <> to_object_id),
    CHECK (valid_until IS NULL OR valid_until >= valid_from),
    CHECK ((quantity IS NULL AND uom IS NULL) OR (quantity IS NOT NULL AND uom IS NOT NULL)),
    CHECK (quantity IS NULL OR quantity >= 0),
    UNIQUE (edge_type, from_object_id, to_object_id, source_event_id)
);

CREATE TABLE projection.handover (
    handover_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    object_id varchar(512) NOT NULL,
    from_organisation_id uuid NOT NULL,
    to_organisation_id uuid NOT NULL,
    shipping_event_id uuid NOT NULL,
    receiving_event_id uuid,
    handover_state varchar(20) NOT NULL
        CHECK (handover_state IN ('PENDING', 'ACCEPTED', 'PARTIAL', 'REJECTED', 'DISPUTED')),
    shipped_quantity numeric(20,6),
    received_quantity numeric(20,6),
    uom varchar(12),
    shipping_time timestamptz NOT NULL,
    receiving_time timestamptz,
    discrepancy jsonb,
    projection_sequence bigint NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (from_organisation_id <> to_organisation_id),
    CHECK (shipped_quantity IS NULL OR shipped_quantity >= 0),
    CHECK (received_quantity IS NULL OR received_quantity >= 0),
    UNIQUE (object_id, shipping_event_id)
);

CREATE TABLE projection.current_object_state (
    object_id varchar(512) PRIMARY KEY,
    disposition varchar(255),
    custodian_organisation_id uuid,
    location_site_id uuid,
    last_event_id uuid NOT NULL,
    affected_status varchar(16) NOT NULL DEFAULT 'CLEAR'
        CHECK (affected_status IN ('CLEAR', 'HOLD', 'AFFECTED', 'RECALLED')),
    projection_sequence bigint NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE projection.consumer_projection (
    object_id varchar(512) PRIMARY KEY,
    public_document jsonb NOT NULL,
    projection_sequence bigint NOT NULL,
    generated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE projection.provenance_completeness (
    object_id varchar(512) PRIMARY KEY,
    completeness_score numeric(5,4) NOT NULL
        CHECK (completeness_score BETWEEN 0 AND 1),
    missing_requirements jsonb NOT NULL DEFAULT '[]'::jsonb,
    projection_sequence bigint NOT NULL,
    evaluated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE projection.risk_assessment (
    risk_assessment_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    object_id varchar(512) NOT NULL,
    model_id varchar(128) NOT NULL,
    model_version varchar(128) NOT NULL,
    risk_score numeric(5,4) NOT NULL CHECK (risk_score BETWEEN 0 AND 1),
    input_window_start timestamptz,
    input_window_end timestamptz,
    explanation jsonb NOT NULL DEFAULT '{}'::jsonb,
    generated_at timestamptz NOT NULL DEFAULT now(),
    CHECK (input_window_end IS NULL OR input_window_start IS NULL OR input_window_end >= input_window_start)
);

-- ---------------------------------------------------------------------------
-- Operations schema
-- ---------------------------------------------------------------------------

CREATE TABLE operations.projection_checkpoint (
    projection_name varchar(128) PRIMARY KEY,
    last_message_id uuid,
    last_ledger_sequence bigint,
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE operations.access_audit (
    audit_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_identity_id uuid,
    actor_organisation_id uuid,
    action varchar(128) NOT NULL,
    resource_type varchar(64) NOT NULL,
    resource_id varchar(512) NOT NULL,
    purpose varchar(128),
    decision varchar(16) NOT NULL CHECK (decision IN ('ALLOW', 'DENY')),
    occurred_at timestamptz NOT NULL DEFAULT now(),
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);

-- ---------------------------------------------------------------------------
-- Indexes for ingestion, audit and recursive trace traversal
-- ---------------------------------------------------------------------------

CREATE INDEX idx_membership_identity_validity
    ON registry.membership (identity_id, valid_from, valid_until);

CREATE INDEX idx_trace_event_publisher_record_time
    ON events.trace_event (publisher_organisation_id, record_time DESC);

CREATE INDEX idx_trace_event_profile_time
    ON events.trace_event (profile_version_id, event_time DESC);

CREATE INDEX idx_trace_event_biz_step
    ON events.trace_event (biz_step);

CREATE INDEX idx_trace_event_canonical_gin
    ON events.trace_event USING gin (canonical_event);

CREATE INDEX idx_event_object_object_event
    ON events.event_object (object_id, event_id);

CREATE INDEX idx_artifact_owner_type
    ON events.external_artifact (owner_organisation_id, artifact_type);

CREATE INDEX idx_outbox_unpublished
    ON events.outbox_message (created_at)
    WHERE published_at IS NULL;

CREATE INDEX idx_trace_edge_from
    ON projection.trace_edge (from_object_id, edge_type, state);

CREATE INDEX idx_trace_edge_to
    ON projection.trace_edge (to_object_id, edge_type, state);

CREATE INDEX idx_handover_object_state
    ON projection.handover (object_id, handover_state);

CREATE INDEX idx_handover_destination
    ON projection.handover (to_organisation_id, handover_state);

CREATE INDEX idx_access_audit_resource_time
    ON operations.access_audit (resource_type, resource_id, occurred_at DESC);

-- ---------------------------------------------------------------------------
-- Append-only protection for authoritative history
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION operations.reject_history_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION '% is append-only; append a correction instead', TG_TABLE_NAME;
END;
$$;

CREATE TRIGGER trace_event_append_only
BEFORE UPDATE OR DELETE ON events.trace_event
FOR EACH ROW EXECUTE FUNCTION operations.reject_history_mutation();

CREATE TRIGGER event_object_append_only
BEFORE UPDATE OR DELETE ON events.event_object
FOR EACH ROW EXECUTE FUNCTION operations.reject_history_mutation();

CREATE TRIGGER event_correction_append_only
BEFORE UPDATE OR DELETE ON events.event_correction
FOR EACH ROW EXECUTE FUNCTION operations.reject_history_mutation();

CREATE TRIGGER ledger_commitment_append_only
BEFORE UPDATE OR DELETE ON events.ledger_commitment
FOR EACH ROW EXECUTE FUNCTION operations.reject_history_mutation();

CREATE TRIGGER access_audit_append_only
BEFORE UPDATE OR DELETE ON operations.access_audit
FOR EACH ROW EXECUTE FUNCTION operations.reject_history_mutation();

-- ---------------------------------------------------------------------------
-- Constraints requiring cross-row or graph evaluation are enforced by the
-- domain modules and verified during projection:
--   * no CONTAINS or DERIVED_FROM cycles;
--   * one active logistic parent per child object;
--   * profile-specific quantity conversion, yield and loss rules;
--   * signing-key validity at the signed event time;
--   * ledger payload commitment equals event payload commitment;
--   * correction-chain authorisation and acyclicity.
-- ---------------------------------------------------------------------------

