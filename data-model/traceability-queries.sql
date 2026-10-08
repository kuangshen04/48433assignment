-- Reference PostgreSQL queries for the Week 10 data-architecture prototype.
-- Edge direction is fixed as:
--   CONTAINS:     from_object_id = parent logistic unit, to_object_id = child
--   DERIVED_FROM: from_object_id = output,               to_object_id = input

-- ---------------------------------------------------------------------------
-- 1. Upstream provenance: starting from an output, find every contributing
-- input across an arbitrary number of transformations.
-- Bind :start_object_id in the application or SQL client.
-- ---------------------------------------------------------------------------

WITH RECURSIVE upstream (object_id, depth, path) AS (
    SELECT
        CAST(:start_object_id AS varchar(512)),
        0,
        ARRAY[CAST(:start_object_id AS varchar(512))]

    UNION ALL

    SELECT
        edge.to_object_id,
        upstream.depth + 1,
        upstream.path || edge.to_object_id
    FROM upstream
    JOIN projection.trace_edge AS edge
      ON edge.edge_type = 'DERIVED_FROM'
     AND edge.from_object_id = upstream.object_id
     AND edge.state = 'ACTIVE'
    WHERE NOT edge.to_object_id = ANY (upstream.path)
)
SELECT object_id, MIN(depth) AS minimum_depth
FROM upstream
GROUP BY object_id
ORDER BY minimum_depth, object_id;

-- ---------------------------------------------------------------------------
-- 2. Downstream impact: starting from an input, find every output that is
-- directly or indirectly derived from it.
-- ---------------------------------------------------------------------------

WITH RECURSIVE downstream (object_id, depth, path) AS (
    SELECT
        CAST(:start_object_id AS varchar(512)),
        0,
        ARRAY[CAST(:start_object_id AS varchar(512))]

    UNION ALL

    SELECT
        edge.from_object_id,
        downstream.depth + 1,
        downstream.path || edge.from_object_id
    FROM downstream
    JOIN projection.trace_edge AS edge
      ON edge.edge_type = 'DERIVED_FROM'
     AND edge.to_object_id = downstream.object_id
     AND edge.state = 'ACTIVE'
    WHERE NOT edge.from_object_id = ANY (downstream.path)
)
SELECT object_id, MIN(depth) AS minimum_depth
FROM downstream
GROUP BY object_id
ORDER BY minimum_depth, object_id;

-- ---------------------------------------------------------------------------
-- 3. Find logistic units that currently or historically contained affected
-- objects. Containment does not imply that every co-contained object is
-- affected; that decision belongs to the product profile and recall policy.
-- ---------------------------------------------------------------------------

WITH RECURSIVE downstream (object_id, path) AS (
    SELECT
        CAST(:start_object_id AS varchar(512)),
        ARRAY[CAST(:start_object_id AS varchar(512))]

    UNION ALL

    SELECT
        edge.from_object_id,
        downstream.path || edge.from_object_id
    FROM downstream
    JOIN projection.trace_edge AS edge
      ON edge.edge_type = 'DERIVED_FROM'
     AND edge.to_object_id = downstream.object_id
    WHERE NOT edge.from_object_id = ANY (downstream.path)
),
affected_objects AS (
    SELECT DISTINCT object_id FROM downstream
)
SELECT DISTINCT
    contains_edge.from_object_id AS logistic_unit_id,
    contains_edge.to_object_id AS affected_child_id,
    contains_edge.valid_from,
    contains_edge.valid_until,
    contains_edge.source_event_id
FROM projection.trace_edge AS contains_edge
JOIN affected_objects
  ON affected_objects.object_id = contains_edge.to_object_id
WHERE contains_edge.edge_type = 'CONTAINS';

-- ---------------------------------------------------------------------------
-- 4. Destinations that received an affected object or an affected object's
-- containing logistic unit.
-- ---------------------------------------------------------------------------

WITH RECURSIVE downstream (object_id, path) AS (
    SELECT
        CAST(:start_object_id AS varchar(512)),
        ARRAY[CAST(:start_object_id AS varchar(512))]

    UNION ALL

    SELECT
        edge.from_object_id,
        downstream.path || edge.from_object_id
    FROM downstream
    JOIN projection.trace_edge AS edge
      ON edge.edge_type = 'DERIVED_FROM'
     AND edge.to_object_id = downstream.object_id
    WHERE NOT edge.from_object_id = ANY (downstream.path)
),
affected_objects AS (
    SELECT DISTINCT object_id FROM downstream
),
affected_logistic_units AS (
    SELECT DISTINCT edge.from_object_id AS object_id
    FROM projection.trace_edge AS edge
    JOIN affected_objects
      ON affected_objects.object_id = edge.to_object_id
    WHERE edge.edge_type = 'CONTAINS'
),
all_handover_subjects AS (
    SELECT object_id FROM affected_objects
    UNION
    SELECT object_id FROM affected_logistic_units
)
SELECT DISTINCT
    handover.object_id,
    handover.to_organisation_id,
    handover.handover_state,
    handover.shipping_event_id,
    handover.receiving_event_id,
    handover.shipping_time,
    handover.receiving_time
FROM projection.handover AS handover
JOIN all_handover_subjects AS subject
  ON subject.object_id = handover.object_id
WHERE handover.handover_state IN ('ACCEPTED', 'PARTIAL', 'DISPUTED')
ORDER BY handover.shipping_time;

-- ---------------------------------------------------------------------------
-- 5. Projection freshness for an API response.
-- ---------------------------------------------------------------------------

SELECT
    projection_name,
    last_message_id,
    last_ledger_sequence,
    updated_at,
    now() - updated_at AS projection_age
FROM operations.projection_checkpoint
WHERE projection_name = :projection_name;

