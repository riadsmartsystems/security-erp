--
-- PostgreSQL database dump
--

\restrict bciPvIy5rZXSnnxTCThqNOfc5kofuAO3rSlR94EFvBSjxhGTqhNTbyOTpjD2xxt

-- Dumped from database version 15.18
-- Dumped by pg_dump version 15.18

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: ai; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA ai;


ALTER SCHEMA ai OWNER TO postgres;

--
-- Name: audit; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA audit;


ALTER SCHEMA audit OWNER TO postgres;

--
-- Name: cmdb; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA cmdb;


ALTER SCHEMA cmdb OWNER TO postgres;

--
-- Name: fsm; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA fsm;


ALTER SCHEMA fsm OWNER TO postgres;

--
-- Name: integration; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA integration;


ALTER SCHEMA integration OWNER TO postgres;

--
-- Name: equipmentstatus; Type: TYPE; Schema: cmdb; Owner: cmdb_user
--

CREATE TYPE cmdb.equipmentstatus AS ENUM (
    'PLANNED',
    'IN_STOCK',
    'RESERVED',
    'INSTALLED',
    'ACTIVE',
    'SERVICE',
    'REPAIR',
    'REPLACED',
    'RETIRED'
);


ALTER TYPE cmdb.equipmentstatus OWNER TO cmdb_user;

--
-- Name: objectstatus; Type: TYPE; Schema: cmdb; Owner: cmdb_user
--

CREATE TYPE cmdb.objectstatus AS ENUM (
    'ACTIVE',
    'SUSPENDED',
    'ARCHIVED'
);


ALTER TYPE cmdb.objectstatus OWNER TO cmdb_user;

--
-- Name: relationtype; Type: TYPE; Schema: cmdb; Owner: cmdb_user
--

CREATE TYPE cmdb.relationtype AS ENUM (
    'CONNECTED_TO',
    'POWERED_BY',
    'DEPENDS_ON',
    'INSTALLED_IN',
    'BACKUP_OF'
);


ALTER TYPE cmdb.relationtype OWNER TO cmdb_user;

--
-- Name: ticketpriority; Type: TYPE; Schema: fsm; Owner: fsm_user
--

CREATE TYPE fsm.ticketpriority AS ENUM (
    'CRITICAL',
    'HIGH',
    'MEDIUM',
    'LOW'
);


ALTER TYPE fsm.ticketpriority OWNER TO fsm_user;

--
-- Name: ticketstatus; Type: TYPE; Schema: fsm; Owner: fsm_user
--

CREATE TYPE fsm.ticketstatus AS ENUM (
    'NEW',
    'TRIAGE',
    'ASSIGNED',
    'ACCEPTED',
    'ON_ROUTE',
    'WORKING',
    'WAITING_PARTS',
    'RESOLVED',
    'CLOSED',
    'CANCELLED'
);


ALTER TYPE fsm.ticketstatus OWNER TO fsm_user;

--
-- Name: tickettype; Type: TYPE; Schema: fsm; Owner: fsm_user
--

CREATE TYPE fsm.tickettype AS ENUM (
    'INCIDENT',
    'SERVICE_REQUEST',
    'PREVENTIVE_MAINTENANCE',
    'INSTALLATION',
    'WARRANTY',
    'INSPECTION',
    'EMERGENCY'
);


ALTER TYPE fsm.tickettype OWNER TO fsm_user;

--
-- Name: visitstatus; Type: TYPE; Schema: fsm; Owner: fsm_user
--

CREATE TYPE fsm.visitstatus AS ENUM (
    'PLANNED',
    'ACCEPTED',
    'ON_ROUTE',
    'ARRIVED',
    'WORKING',
    'COMPLETED'
);


ALTER TYPE fsm.visitstatus OWNER TO fsm_user;

--
-- Name: increment_workflow_version(); Type: FUNCTION; Schema: public; Owner: integration_user
--

CREATE FUNCTION public.increment_workflow_version() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
			BEGIN
				IF NEW."versionCounter" IS NOT DISTINCT FROM OLD."versionCounter"
					AND (NEW."nodes"::text IS DISTINCT FROM OLD."nodes"::text
						OR NEW."settings"::text IS DISTINCT FROM OLD."settings"::text) THEN
					NEW."versionCounter" = OLD."versionCounter" + 1;
				END IF;
				RETURN NEW;
			END;
			$$;


ALTER FUNCTION public.increment_workflow_version() OWNER TO integration_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_log; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.audit_log (
    id uuid NOT NULL,
    user_id uuid,
    action character varying(50) NOT NULL,
    entity_type character varying(100) NOT NULL,
    entity_id uuid,
    details character varying(2000),
    ip_address character varying(45),
    user_agent character varying(500),
    created_at timestamp with time zone
);


ALTER TABLE audit.audit_log OWNER TO postgres;

--
-- Name: buildings; Type: TABLE; Schema: cmdb; Owner: cmdb_user
--

CREATE TABLE cmdb.buildings (
    id uuid NOT NULL,
    object_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    floors_count integer,
    notes text,
    created_at timestamp with time zone,
    is_active boolean
);


ALTER TABLE cmdb.buildings OWNER TO cmdb_user;

--
-- Name: equipment; Type: TABLE; Schema: cmdb; Owner: cmdb_user
--

CREATE TABLE cmdb.equipment (
    id uuid NOT NULL,
    equipment_code character varying(20) NOT NULL,
    object_id uuid NOT NULL,
    room_id uuid,
    equipment_type_id uuid NOT NULL,
    vendor_id uuid NOT NULL,
    model character varying(255) NOT NULL,
    serial_number character varying(255),
    firmware_version character varying(100),
    ip_address inet,
    mac_address macaddr,
    install_date date,
    warranty_end_date date,
    status cmdb.equipmentstatus NOT NULL,
    lifecycle_project_id uuid,
    notes text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    created_by uuid,
    is_active boolean
);


ALTER TABLE cmdb.equipment OWNER TO cmdb_user;

--
-- Name: equipment_relations; Type: TABLE; Schema: cmdb; Owner: cmdb_user
--

CREATE TABLE cmdb.equipment_relations (
    id uuid NOT NULL,
    source_equipment_id uuid NOT NULL,
    target_equipment_id uuid NOT NULL,
    relation_type cmdb.relationtype NOT NULL,
    port_label character varying(50),
    notes text,
    created_at timestamp with time zone,
    is_active boolean
);


ALTER TABLE cmdb.equipment_relations OWNER TO cmdb_user;

--
-- Name: equipment_types; Type: TABLE; Schema: cmdb; Owner: cmdb_user
--

CREATE TABLE cmdb.equipment_types (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(50) NOT NULL,
    category character varying(100) NOT NULL,
    parent_id uuid,
    checklist_template_id uuid,
    created_at timestamp with time zone,
    is_active boolean
);


ALTER TABLE cmdb.equipment_types OWNER TO cmdb_user;

--
-- Name: floors; Type: TABLE; Schema: cmdb; Owner: cmdb_user
--

CREATE TABLE cmdb.floors (
    id uuid NOT NULL,
    building_id uuid NOT NULL,
    level integer NOT NULL,
    name character varying(100),
    created_at timestamp with time zone,
    is_active boolean
);


ALTER TABLE cmdb.floors OWNER TO cmdb_user;

--
-- Name: objects; Type: TABLE; Schema: cmdb; Owner: cmdb_user
--

CREATE TABLE cmdb.objects (
    id uuid NOT NULL,
    object_code character varying(20) NOT NULL,
    customer_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    address text,
    gps_lat double precision,
    gps_lon double precision,
    object_type character varying(50),
    service_level character varying(20),
    status cmdb.objectstatus NOT NULL,
    notes text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    created_by uuid,
    is_active boolean
);


ALTER TABLE cmdb.objects OWNER TO cmdb_user;

--
-- Name: rooms; Type: TABLE; Schema: cmdb; Owner: cmdb_user
--

CREATE TABLE cmdb.rooms (
    id uuid NOT NULL,
    floor_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    room_type character varying(50),
    area_sqm double precision,
    created_at timestamp with time zone,
    is_active boolean
);


ALTER TABLE cmdb.rooms OWNER TO cmdb_user;

--
-- Name: vendors; Type: TABLE; Schema: cmdb; Owner: cmdb_user
--

CREATE TABLE cmdb.vendors (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(50),
    website character varying(500),
    support_email character varying(255),
    support_phone character varying(50),
    notes text,
    created_at timestamp with time zone,
    is_active boolean
);


ALTER TABLE cmdb.vendors OWNER TO cmdb_user;

--
-- Name: maintenance_plans; Type: TABLE; Schema: fsm; Owner: fsm_user
--

CREATE TABLE fsm.maintenance_plans (
    id uuid NOT NULL,
    object_id uuid NOT NULL,
    customer_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    frequency character varying(50) NOT NULL,
    next_due_date timestamp with time zone NOT NULL,
    last_executed timestamp with time zone,
    checklist_template_id uuid,
    is_active boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE fsm.maintenance_plans OWNER TO fsm_user;

--
-- Name: sla_events; Type: TABLE; Schema: fsm; Owner: fsm_user
--

CREATE TABLE fsm.sla_events (
    id uuid NOT NULL,
    ticket_id uuid NOT NULL,
    event_type character varying(50) NOT NULL,
    timer_type character varying(50) NOT NULL,
    occurred_at timestamp with time zone,
    details text
);


ALTER TABLE fsm.sla_events OWNER TO fsm_user;

--
-- Name: tickets; Type: TABLE; Schema: fsm; Owner: fsm_user
--

CREATE TABLE fsm.tickets (
    id uuid NOT NULL,
    ticket_number character varying(20) NOT NULL,
    customer_id uuid NOT NULL,
    object_id uuid NOT NULL,
    contract_id uuid,
    ticket_type fsm.tickettype NOT NULL,
    priority fsm.ticketpriority NOT NULL,
    status fsm.ticketstatus NOT NULL,
    title character varying(500) NOT NULL,
    description text,
    assigned_engineer_id uuid,
    sla_response_due timestamp with time zone,
    sla_arrival_due timestamp with time zone,
    sla_resolution_due timestamp with time zone,
    sla_paused_at timestamp with time zone,
    sla_pause_minutes integer,
    sla_response_breached boolean,
    sla_arrival_breached boolean,
    sla_resolution_breached boolean,
    resolved_at timestamp with time zone,
    closed_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    created_by uuid,
    is_active boolean
);


ALTER TABLE fsm.tickets OWNER TO fsm_user;

--
-- Name: visit_materials; Type: TABLE; Schema: fsm; Owner: fsm_user
--

CREATE TABLE fsm.visit_materials (
    id uuid NOT NULL,
    visit_id uuid NOT NULL,
    item_code character varying(100) NOT NULL,
    item_name character varying(255) NOT NULL,
    serial_number character varying(255),
    quantity double precision NOT NULL,
    uom character varying(50),
    created_at timestamp with time zone,
    created_by uuid
);


ALTER TABLE fsm.visit_materials OWNER TO fsm_user;

--
-- Name: visit_photos; Type: TABLE; Schema: fsm; Owner: fsm_user
--

CREATE TABLE fsm.visit_photos (
    id uuid NOT NULL,
    visit_id uuid NOT NULL,
    photo_type character varying(50) NOT NULL,
    file_id uuid NOT NULL,
    file_path character varying(500) NOT NULL,
    caption character varying(500),
    gps_lat double precision,
    gps_lon double precision,
    created_at timestamp with time zone,
    created_by uuid
);


ALTER TABLE fsm.visit_photos OWNER TO fsm_user;

--
-- Name: visits; Type: TABLE; Schema: fsm; Owner: fsm_user
--

CREATE TABLE fsm.visits (
    id uuid NOT NULL,
    visit_number character varying(20) NOT NULL,
    ticket_id uuid NOT NULL,
    engineer_id uuid NOT NULL,
    status fsm.visitstatus NOT NULL,
    planned_start timestamp with time zone,
    actual_start timestamp with time zone,
    actual_finish timestamp with time zone,
    gps_checkin_lat double precision,
    gps_checkin_lon double precision,
    gps_checkout_lat double precision,
    gps_checkout_lon double precision,
    travel_minutes integer,
    work_minutes integer,
    notes text,
    customer_signature_file uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    created_by uuid,
    is_active boolean
);


ALTER TABLE fsm.visits OWNER TO fsm_user;

--
-- Name: warranty_cases; Type: TABLE; Schema: fsm; Owner: fsm_user
--

CREATE TABLE fsm.warranty_cases (
    id uuid NOT NULL,
    case_number character varying(20) NOT NULL,
    ticket_id uuid,
    equipment_id uuid NOT NULL,
    customer_id uuid NOT NULL,
    description text NOT NULL,
    status character varying(50),
    resolution text,
    manufacturer_claim boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    created_by uuid
);


ALTER TABLE fsm.warranty_cases OWNER TO fsm_user;

--
-- Name: users; Type: TABLE; Schema: integration; Owner: postgres
--

CREATE TABLE integration.users (
    id uuid NOT NULL,
    email character varying(255) NOT NULL,
    username character varying(100) NOT NULL,
    full_name character varying(255) NOT NULL,
    hashed_password character varying(255) NOT NULL,
    role character varying(50) NOT NULL,
    employee_id uuid,
    is_active boolean,
    mfa_enabled boolean,
    mfa_secret character varying(100),
    last_login timestamp with time zone,
    failed_login_attempts character varying(10),
    locked_until timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE integration.users OWNER TO postgres;

--
-- Name: agent_checkpoints; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.agent_checkpoints (
    "runId" character varying(255) NOT NULL,
    "agentId" character varying(255),
    state text,
    expired boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agent_checkpoints OWNER TO integration_user;

--
-- Name: agent_execution; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.agent_execution (
    id character varying(36) NOT NULL,
    "threadId" character varying(36) NOT NULL,
    status character varying(16) NOT NULL,
    "startedAt" timestamp(3) with time zone,
    "stoppedAt" timestamp(3) with time zone,
    duration integer DEFAULT 0 NOT NULL,
    "userMessage" text NOT NULL,
    "assistantResponse" text NOT NULL,
    model character varying(255),
    "promptTokens" integer,
    "completionTokens" integer,
    "totalTokens" integer,
    cost double precision,
    "toolCalls" json,
    timeline json,
    error text,
    "hitlStatus" character varying(16),
    source character varying(32),
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_agent_execution_hitlStatus" CHECK ((("hitlStatus")::text = ANY ((ARRAY['suspended'::character varying, 'resumed'::character varying])::text[]))),
    CONSTRAINT "CHK_agent_execution_status" CHECK (((status)::text = ANY ((ARRAY['success'::character varying, 'error'::character varying])::text[])))
);


ALTER TABLE public.agent_execution OWNER TO integration_user;

--
-- Name: agent_execution_threads; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.agent_execution_threads (
    id character varying(36) NOT NULL,
    "agentId" character varying(36) NOT NULL,
    "agentName" character varying(255) NOT NULL,
    "projectId" character varying(255) NOT NULL,
    "sessionNumber" integer DEFAULT 0 NOT NULL,
    "totalPromptTokens" integer DEFAULT 0 NOT NULL,
    "totalCompletionTokens" integer DEFAULT 0 NOT NULL,
    "totalCost" double precision DEFAULT 0 NOT NULL,
    "totalDuration" integer DEFAULT 0 NOT NULL,
    title character varying(255),
    emoji character varying(8),
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "taskId" character varying(32),
    "taskVersionId" character varying(36)
);


ALTER TABLE public.agent_execution_threads OWNER TO integration_user;

--
-- Name: COLUMN agent_execution_threads."taskId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_execution_threads."taskId" IS 'Published task ID that triggered this session; not an FK because published runs can outlive draft task definition rows';


--
-- Name: COLUMN agent_execution_threads."taskVersionId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_execution_threads."taskVersionId" IS 'Published agent_history version that supplied the task snapshot';


--
-- Name: agent_files; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.agent_files (
    id character varying(16) NOT NULL,
    "agentId" character varying(36) NOT NULL,
    "binaryDataId" text NOT NULL,
    "fileName" character varying(255) NOT NULL,
    "mimeType" character varying(255) NOT NULL,
    "fileSizeBytes" integer NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agent_files OWNER TO integration_user;

--
-- Name: COLUMN agent_files.id; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_files.id IS 'Application-generated n8n nano ID';


--
-- Name: COLUMN agent_files."agentId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_files."agentId" IS 'Agent that owns this uploaded file';


--
-- Name: COLUMN agent_files."binaryDataId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_files."binaryDataId" IS 'Opaque BinaryDataService reference (mode-prefixed, e.g. "filesystem-v2:<uuid>"); not an FK to binary_data, which only has rows in DB storage mode';


--
-- Name: COLUMN agent_files."fileSizeBytes"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_files."fileSizeBytes" IS 'Uploaded file size in bytes';


--
-- Name: agent_history; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.agent_history (
    "versionId" character varying(36) NOT NULL,
    "agentId" character varying(36) NOT NULL,
    schema json,
    tools json,
    skills json,
    "publishedById" uuid,
    author character varying(255) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agent_history OWNER TO integration_user;

--
-- Name: COLUMN agent_history.schema; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_history.schema IS 'Frozen snapshot of the published AgentJsonConfig';


--
-- Name: COLUMN agent_history.tools; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_history.tools IS 'Frozen map of `toolId → { code, descriptor }` at publish time';


--
-- Name: COLUMN agent_history.skills; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_history.skills IS 'Frozen map of `skillId → AgentSkill` at publish time';


--
-- Name: agent_task_definition; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.agent_task_definition (
    id character varying(32) NOT NULL,
    "agentId" character varying(36) NOT NULL,
    name character varying(128) NOT NULL,
    objective text NOT NULL,
    "cronExpression" character varying(128) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agent_task_definition OWNER TO integration_user;

--
-- Name: COLUMN agent_task_definition.id; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_task_definition.id IS 'Application-generated task ID referenced from agent JSON config';


--
-- Name: COLUMN agent_task_definition."agentId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_task_definition."agentId" IS 'Owning agent; task definitions are deleted when the agent is deleted';


--
-- Name: COLUMN agent_task_definition.objective; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_task_definition.objective IS 'User-authored instruction sent to the agent when this task runs';


--
-- Name: COLUMN agent_task_definition."cronExpression"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_task_definition."cronExpression" IS 'Cron schedule evaluated using the instance timezone';


--
-- Name: agent_task_run_lock; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.agent_task_run_lock (
    "agentId" character varying(36) NOT NULL,
    "taskId" character varying(32) NOT NULL,
    "holderId" uuid NOT NULL,
    "heldUntil" timestamp(3) with time zone NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agent_task_run_lock OWNER TO integration_user;

--
-- Name: COLUMN agent_task_run_lock."agentId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_task_run_lock."agentId" IS 'Published agent whose scheduled task run is locked';


--
-- Name: COLUMN agent_task_run_lock."taskId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_task_run_lock."taskId" IS 'Published task ID whose scheduled run is locked';


--
-- Name: COLUMN agent_task_run_lock."holderId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_task_run_lock."holderId" IS 'Ephemeral lock owner token generated by the running main';


--
-- Name: COLUMN agent_task_run_lock."heldUntil"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_task_run_lock."heldUntil" IS 'Time after which another main can claim this task run lock';


--
-- Name: agent_task_snapshot; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.agent_task_snapshot (
    "versionId" character varying(36) NOT NULL,
    "taskId" character varying(32) NOT NULL,
    enabled boolean NOT NULL,
    name character varying(128) NOT NULL,
    objective text NOT NULL,
    "cronExpression" character varying(128) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agent_task_snapshot OWNER TO integration_user;

--
-- Name: COLUMN agent_task_snapshot."versionId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_task_snapshot."versionId" IS 'Published agent_history version this task snapshot belongs to';


--
-- Name: COLUMN agent_task_snapshot."taskId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_task_snapshot."taskId" IS 'Stable task ID referenced from the published agent JSON config';


--
-- Name: COLUMN agent_task_snapshot.enabled; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_task_snapshot.enabled IS 'Published enabled state for this task at publish time';


--
-- Name: COLUMN agent_task_snapshot.objective; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_task_snapshot.objective IS 'User-authored instruction sent to the agent when this task runs';


--
-- Name: COLUMN agent_task_snapshot."cronExpression"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agent_task_snapshot."cronExpression" IS 'Cron schedule evaluated using the instance timezone';


--
-- Name: agents; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.agents (
    id character varying(36) NOT NULL,
    name character varying(128) NOT NULL,
    description character varying(512),
    "projectId" character varying(255) NOT NULL,
    integrations json DEFAULT '[]'::json NOT NULL,
    schema json,
    tools json DEFAULT '{}'::json NOT NULL,
    skills json DEFAULT '{}'::json NOT NULL,
    "versionId" character varying(36),
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "activeVersionId" character varying(36)
);


ALTER TABLE public.agents OWNER TO integration_user;

--
-- Name: agents_memory_entries; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.agents_memory_entries (
    id character varying(36) NOT NULL,
    "agentId" character varying(36) NOT NULL,
    "resourceId" character varying(255) NOT NULL,
    content text NOT NULL,
    "contentHash" character varying(64) NOT NULL,
    status character varying(16) NOT NULL,
    "supersededBy" character varying(36),
    "embeddingModel" character varying(128),
    embedding json,
    metadata json,
    "lastSeenAt" timestamp(3) with time zone NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_agents_memory_entries_status" CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'superseded'::character varying, 'dropped'::character varying])::text[])))
);


ALTER TABLE public.agents_memory_entries OWNER TO integration_user;

--
-- Name: COLUMN agents_memory_entries."agentId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_memory_entries."agentId" IS 'Agent that owns this episodic memory entry';


--
-- Name: COLUMN agents_memory_entries."resourceId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_memory_entries."resourceId" IS 'agents_resources.id partition used for episodic recall scope';


--
-- Name: COLUMN agents_memory_entries."supersededBy"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_memory_entries."supersededBy" IS 'Self-reference to replacement memory entry';


--
-- Name: COLUMN agents_memory_entries."embeddingModel"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_memory_entries."embeddingModel" IS 'Embedding model used to produce embedding';


--
-- Name: COLUMN agents_memory_entries.embedding; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_memory_entries.embedding IS 'Embedding vector for episodic recall';


--
-- Name: COLUMN agents_memory_entries.metadata; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_memory_entries.metadata IS 'Optional system metadata for ranking and debugging';


--
-- Name: COLUMN agents_memory_entries."lastSeenAt"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_memory_entries."lastSeenAt" IS 'Last time equivalent content was observed; updatedAt tracks row mutation time';


--
-- Name: agents_memory_entry_cursors; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.agents_memory_entry_cursors (
    "agentId" character varying(36) NOT NULL,
    "observationScopeId" character varying(255) NOT NULL,
    "lastIndexedObservationId" character varying(36) NOT NULL,
    "lastIndexedObservationCreatedAt" timestamp(3) with time zone NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agents_memory_entry_cursors OWNER TO integration_user;

--
-- Name: COLUMN agents_memory_entry_cursors."agentId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_memory_entry_cursors."agentId" IS 'Agent that owns this cursor';


--
-- Name: COLUMN agents_memory_entry_cursors."observationScopeId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_memory_entry_cursors."observationScopeId" IS 'agents_threads.id source stream indexed into episodic memory';


--
-- Name: COLUMN agents_memory_entry_cursors."lastIndexedObservationId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_memory_entry_cursors."lastIndexedObservationId" IS 'Last observation-log row indexed into episodic memory';


--
-- Name: COLUMN agents_memory_entry_cursors."lastIndexedObservationCreatedAt"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_memory_entry_cursors."lastIndexedObservationCreatedAt" IS 'Creation timestamp for the last indexed observation-log row';


--
-- Name: agents_memory_entry_locks; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.agents_memory_entry_locks (
    "agentId" character varying(36) NOT NULL,
    "resourceId" character varying(255) NOT NULL,
    "holderId" character varying(64) NOT NULL,
    "heldUntil" timestamp(3) with time zone NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agents_memory_entry_locks OWNER TO integration_user;

--
-- Name: COLUMN agents_memory_entry_locks."agentId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_memory_entry_locks."agentId" IS 'Agent that owns this lock';


--
-- Name: COLUMN agents_memory_entry_locks."resourceId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_memory_entry_locks."resourceId" IS 'agents_resources.id partition locked for episodic indexing';


--
-- Name: COLUMN agents_memory_entry_locks."holderId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_memory_entry_locks."holderId" IS 'Ephemeral background-task lock owner token';


--
-- Name: agents_memory_entry_sources; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.agents_memory_entry_sources (
    id character varying(36) NOT NULL,
    "agentId" character varying(36) NOT NULL,
    "memoryEntryId" character varying(36) NOT NULL,
    "observationId" character varying(36) NOT NULL,
    "threadId" character varying(255) NOT NULL,
    "evidenceHash" character varying(64) NOT NULL,
    "evidenceText" text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agents_memory_entry_sources OWNER TO integration_user;

--
-- Name: COLUMN agents_memory_entry_sources."agentId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_memory_entry_sources."agentId" IS 'Agent that owns the linked episodic memory entry source';


--
-- Name: COLUMN agents_memory_entry_sources."memoryEntryId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_memory_entry_sources."memoryEntryId" IS 'Episodic memory entry linked to this source evidence';


--
-- Name: COLUMN agents_memory_entry_sources."observationId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_memory_entry_sources."observationId" IS 'Observation-log row used as source evidence';


--
-- Name: COLUMN agents_memory_entry_sources."threadId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_memory_entry_sources."threadId" IS 'Source conversation thread that produced the linked observation';


--
-- Name: COLUMN agents_memory_entry_sources."evidenceHash"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_memory_entry_sources."evidenceHash" IS 'Bounded hash used to deduplicate exact evidence links';


--
-- Name: COLUMN agents_memory_entry_sources."evidenceText"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_memory_entry_sources."evidenceText" IS 'Exact source evidence text from the observation, not recall scope';


--
-- Name: agents_messages; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.agents_messages (
    id character varying(36) NOT NULL,
    "threadId" character varying(255) NOT NULL,
    "resourceId" character varying(255) NOT NULL,
    role character varying(36) NOT NULL,
    type character varying(36),
    content json NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agents_messages OWNER TO integration_user;

--
-- Name: agents_observation_cursors; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.agents_observation_cursors (
    "agentId" character varying(36) NOT NULL,
    "observationScopeId" character varying(255) NOT NULL,
    "lastObservedMessageId" character varying(36) NOT NULL,
    "lastObservedAt" timestamp(3) with time zone NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agents_observation_cursors OWNER TO integration_user;

--
-- Name: COLUMN agents_observation_cursors."agentId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_observation_cursors."agentId" IS 'Agent that owns this cursor';


--
-- Name: COLUMN agents_observation_cursors."observationScopeId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_observation_cursors."observationScopeId" IS 'agents_threads.id source stream checkpointed by this cursor';


--
-- Name: agents_observation_locks; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.agents_observation_locks (
    "agentId" character varying(36) NOT NULL,
    "observationScopeId" character varying(255) NOT NULL,
    "taskKind" character varying(20) NOT NULL,
    "holderId" character varying(64) NOT NULL,
    "heldUntil" timestamp(3) with time zone NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_agents_observation_locks_taskKind" CHECK ((("taskKind")::text = ANY ((ARRAY['observer'::character varying, 'reflector'::character varying])::text[])))
);


ALTER TABLE public.agents_observation_locks OWNER TO integration_user;

--
-- Name: COLUMN agents_observation_locks."agentId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_observation_locks."agentId" IS 'Agent that owns this lock';


--
-- Name: COLUMN agents_observation_locks."observationScopeId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_observation_locks."observationScopeId" IS 'agents_threads.id source stream locked for observation tasks';


--
-- Name: COLUMN agents_observation_locks."holderId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_observation_locks."holderId" IS 'Ephemeral background-task lock owner token, not a user ID';


--
-- Name: agents_observations; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.agents_observations (
    id character varying(36) NOT NULL,
    "agentId" character varying(36) NOT NULL,
    "observationScopeId" character varying(255) NOT NULL,
    marker character varying(16) NOT NULL,
    text text NOT NULL,
    "parentId" character varying(36),
    "tokenCount" integer DEFAULT 0 NOT NULL,
    status character varying(16) NOT NULL,
    "supersededBy" character varying(36),
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_agents_observations_marker" CHECK (((marker)::text = ANY ((ARRAY['critical'::character varying, 'important'::character varying, 'info'::character varying, 'completion'::character varying])::text[]))),
    CONSTRAINT "CHK_agents_observations_status" CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'superseded'::character varying, 'dropped'::character varying])::text[])))
);


ALTER TABLE public.agents_observations OWNER TO integration_user;

--
-- Name: COLUMN agents_observations.id; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_observations.id IS 'Application-generated n8n string ID, not a database UUID';


--
-- Name: COLUMN agents_observations."agentId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_observations."agentId" IS 'Agent that owns this observation row';


--
-- Name: COLUMN agents_observations."observationScopeId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.agents_observations."observationScopeId" IS 'agents_threads.id source stream for this observation log';


--
-- Name: agents_resources; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.agents_resources (
    id character varying(255) NOT NULL,
    metadata text,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agents_resources OWNER TO integration_user;

--
-- Name: agents_threads; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.agents_threads (
    id character varying(36) NOT NULL,
    "resourceId" character varying(255) NOT NULL,
    title character varying(255),
    metadata text,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agents_threads OWNER TO integration_user;

--
-- Name: ai_builder_temporary_workflow; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.ai_builder_temporary_workflow (
    "workflowId" character varying(36) NOT NULL,
    "threadId" uuid NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.ai_builder_temporary_workflow OWNER TO integration_user;

--
-- Name: annotation_tag_entity; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.annotation_tag_entity (
    id character varying(16) NOT NULL,
    name character varying(24) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.annotation_tag_entity OWNER TO integration_user;

--
-- Name: auth_identity; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.auth_identity (
    "userId" uuid,
    "providerId" character varying(255) NOT NULL,
    "providerType" character varying(32) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.auth_identity OWNER TO integration_user;

--
-- Name: auth_provider_sync_history; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.auth_provider_sync_history (
    id integer NOT NULL,
    "providerType" character varying(32) NOT NULL,
    "runMode" text NOT NULL,
    status text NOT NULL,
    "startedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "endedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    scanned integer NOT NULL,
    created integer NOT NULL,
    updated integer NOT NULL,
    disabled integer NOT NULL,
    error text
);


ALTER TABLE public.auth_provider_sync_history OWNER TO integration_user;

--
-- Name: auth_provider_sync_history_id_seq; Type: SEQUENCE; Schema: public; Owner: integration_user
--

CREATE SEQUENCE public.auth_provider_sync_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_provider_sync_history_id_seq OWNER TO integration_user;

--
-- Name: auth_provider_sync_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: integration_user
--

ALTER SEQUENCE public.auth_provider_sync_history_id_seq OWNED BY public.auth_provider_sync_history.id;


--
-- Name: binary_data; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.binary_data (
    "fileId" uuid NOT NULL,
    "sourceType" character varying(50) NOT NULL,
    "sourceId" character varying(255) NOT NULL,
    data bytea NOT NULL,
    "mimeType" character varying(255),
    "fileName" character varying(255),
    "fileSize" integer NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_binary_data_sourceType" CHECK ((("sourceType")::text = ANY ((ARRAY['execution'::character varying, 'chat_message_attachment'::character varying, 'agent_file'::character varying])::text[])))
);


ALTER TABLE public.binary_data OWNER TO integration_user;

--
-- Name: COLUMN binary_data."sourceType"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.binary_data."sourceType" IS 'Source the file belongs to, e.g. ''execution''';


--
-- Name: COLUMN binary_data."sourceId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.binary_data."sourceId" IS 'ID of the source, e.g. execution ID';


--
-- Name: COLUMN binary_data.data; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.binary_data.data IS 'Raw, not base64 encoded';


--
-- Name: COLUMN binary_data."fileSize"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.binary_data."fileSize" IS 'In bytes';


--
-- Name: chat_hub_agent_tools; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.chat_hub_agent_tools (
    "agentId" uuid NOT NULL,
    "toolId" uuid NOT NULL
);


ALTER TABLE public.chat_hub_agent_tools OWNER TO integration_user;

--
-- Name: chat_hub_agents; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.chat_hub_agents (
    id uuid NOT NULL,
    name character varying(256) NOT NULL,
    description character varying(512),
    "systemPrompt" text NOT NULL,
    "ownerId" uuid NOT NULL,
    "credentialId" character varying(36),
    provider character varying(16) NOT NULL,
    model character varying(64) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    icon json,
    files json DEFAULT '[]'::json NOT NULL,
    "suggestedPrompts" json DEFAULT '[]'::json NOT NULL
);


ALTER TABLE public.chat_hub_agents OWNER TO integration_user;

--
-- Name: COLUMN chat_hub_agents.provider; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.chat_hub_agents.provider IS 'ChatHubProvider enum: "openai", "anthropic", "google", "n8n"';


--
-- Name: COLUMN chat_hub_agents.model; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.chat_hub_agents.model IS 'Model name used at the respective Model node, ie. "gpt-4"';


--
-- Name: chat_hub_messages; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.chat_hub_messages (
    id uuid NOT NULL,
    "sessionId" uuid NOT NULL,
    "previousMessageId" uuid,
    "revisionOfMessageId" uuid,
    "retryOfMessageId" uuid,
    type character varying(16) NOT NULL,
    name character varying(128) NOT NULL,
    content text NOT NULL,
    provider character varying(16),
    model character varying(256),
    "workflowId" character varying(36),
    "executionId" integer,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "agentId" uuid,
    status character varying(16) DEFAULT 'success'::character varying NOT NULL,
    attachments json
);


ALTER TABLE public.chat_hub_messages OWNER TO integration_user;

--
-- Name: COLUMN chat_hub_messages.type; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.chat_hub_messages.type IS 'ChatHubMessageType enum: "human", "ai", "system", "tool", "generic"';


--
-- Name: COLUMN chat_hub_messages.provider; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.chat_hub_messages.provider IS 'ChatHubProvider enum: "openai", "anthropic", "google", "n8n"';


--
-- Name: COLUMN chat_hub_messages.model; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.chat_hub_messages.model IS 'Model name used at the respective Model node, ie. "gpt-4"';


--
-- Name: COLUMN chat_hub_messages."agentId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.chat_hub_messages."agentId" IS 'ID of the custom agent (if provider is "custom-agent")';


--
-- Name: COLUMN chat_hub_messages.status; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.chat_hub_messages.status IS 'ChatHubMessageStatus enum, eg. "success", "error", "running", "cancelled"';


--
-- Name: COLUMN chat_hub_messages.attachments; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.chat_hub_messages.attachments IS 'File attachments for the message (if any), stored as JSON. Files are stored as base64-encoded data URLs.';


--
-- Name: chat_hub_session_tools; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.chat_hub_session_tools (
    "sessionId" uuid NOT NULL,
    "toolId" uuid NOT NULL
);


ALTER TABLE public.chat_hub_session_tools OWNER TO integration_user;

--
-- Name: chat_hub_sessions; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.chat_hub_sessions (
    id uuid NOT NULL,
    title character varying(256) NOT NULL,
    "ownerId" uuid NOT NULL,
    "lastMessageAt" timestamp(3) with time zone NOT NULL,
    "credentialId" character varying(36),
    provider character varying(16),
    model character varying(256),
    "workflowId" character varying(36),
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "agentId" uuid,
    "agentName" character varying(128),
    type character varying(16) DEFAULT 'production'::character varying NOT NULL,
    CONSTRAINT "CHK_chat_hub_sessions_type" CHECK (((type)::text = ANY ((ARRAY['production'::character varying, 'manual'::character varying])::text[])))
);


ALTER TABLE public.chat_hub_sessions OWNER TO integration_user;

--
-- Name: COLUMN chat_hub_sessions.provider; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.chat_hub_sessions.provider IS 'ChatHubProvider enum: "openai", "anthropic", "google", "n8n"';


--
-- Name: COLUMN chat_hub_sessions.model; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.chat_hub_sessions.model IS 'Model name used at the respective Model node, ie. "gpt-4"';


--
-- Name: COLUMN chat_hub_sessions."agentId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.chat_hub_sessions."agentId" IS 'ID of the custom agent (if provider is "custom-agent")';


--
-- Name: COLUMN chat_hub_sessions."agentName"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.chat_hub_sessions."agentName" IS 'Cached name of the custom agent (if provider is "custom-agent")';


--
-- Name: chat_hub_tools; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.chat_hub_tools (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    "typeVersion" double precision NOT NULL,
    "ownerId" uuid NOT NULL,
    definition json NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.chat_hub_tools OWNER TO integration_user;

--
-- Name: credential_dependency; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.credential_dependency (
    id integer NOT NULL,
    "credentialId" character varying(36) NOT NULL,
    "dependencyType" character varying(64) NOT NULL,
    "dependencyId" character varying(255) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.credential_dependency OWNER TO integration_user;

--
-- Name: credential_dependency_id_seq; Type: SEQUENCE; Schema: public; Owner: integration_user
--

ALTER TABLE public.credential_dependency ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.credential_dependency_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: credentials_entity; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.credentials_entity (
    name character varying(128) NOT NULL,
    data text NOT NULL,
    type character varying(128) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    id character varying(36) NOT NULL,
    "isManaged" boolean DEFAULT false NOT NULL,
    "isGlobal" boolean DEFAULT false NOT NULL,
    "isResolvable" boolean DEFAULT false NOT NULL,
    "resolvableAllowFallback" boolean DEFAULT false NOT NULL,
    "resolverId" character varying(16)
);


ALTER TABLE public.credentials_entity OWNER TO integration_user;

--
-- Name: data_table; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.data_table (
    id character varying(36) NOT NULL,
    name character varying(128) NOT NULL,
    "projectId" character varying(36) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.data_table OWNER TO integration_user;

--
-- Name: data_table_column; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.data_table_column (
    id character varying(36) NOT NULL,
    name character varying(128) NOT NULL,
    type character varying(32) NOT NULL,
    index integer NOT NULL,
    "dataTableId" character varying(36) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.data_table_column OWNER TO integration_user;

--
-- Name: COLUMN data_table_column.type; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.data_table_column.type IS 'Expected: string, number, boolean, or date (not enforced as a constraint)';


--
-- Name: COLUMN data_table_column.index; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.data_table_column.index IS 'Column order, starting from 0 (0 = first column)';


--
-- Name: deployment_key; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.deployment_key (
    id character varying(36) NOT NULL,
    type character varying(64) NOT NULL,
    value text NOT NULL,
    algorithm character varying(20),
    status character varying(20) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.deployment_key OWNER TO integration_user;

--
-- Name: dynamic_credential_entry; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.dynamic_credential_entry (
    credential_id character varying(16) NOT NULL,
    subject_id character varying(2048) NOT NULL,
    resolver_id character varying(16) NOT NULL,
    data text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.dynamic_credential_entry OWNER TO integration_user;

--
-- Name: dynamic_credential_resolver; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.dynamic_credential_resolver (
    id character varying(16) NOT NULL,
    name character varying(128) NOT NULL,
    type character varying(128) NOT NULL,
    config text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.dynamic_credential_resolver OWNER TO integration_user;

--
-- Name: COLUMN dynamic_credential_resolver.config; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.dynamic_credential_resolver.config IS 'Encrypted resolver configuration (JSON encrypted as string)';


--
-- Name: dynamic_credential_user_entry; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.dynamic_credential_user_entry (
    "credentialId" character varying(16) NOT NULL,
    "userId" uuid NOT NULL,
    "resolverId" character varying(16) NOT NULL,
    data text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.dynamic_credential_user_entry OWNER TO integration_user;

--
-- Name: evaluation_collection; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.evaluation_collection (
    id character varying(36) NOT NULL,
    name character varying(128) NOT NULL,
    description text,
    "workflowId" character varying(36) NOT NULL,
    "evaluationConfigId" character varying(36) NOT NULL,
    "createdById" uuid,
    "insightsCache" json,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.evaluation_collection OWNER TO integration_user;

--
-- Name: evaluation_config; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.evaluation_config (
    id character varying(36) NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    name character varying(128) NOT NULL,
    status character varying(16) DEFAULT 'valid'::character varying NOT NULL,
    "invalidReason" character varying(64),
    "datasetSource" character varying(32) NOT NULL,
    "datasetRef" json NOT NULL,
    "startNodeName" character varying(255) NOT NULL,
    "endNodeName" character varying(255) NOT NULL,
    metrics json NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.evaluation_config OWNER TO integration_user;

--
-- Name: event_destinations; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.event_destinations (
    id uuid NOT NULL,
    destination jsonb NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.event_destinations OWNER TO integration_user;

--
-- Name: execution_annotation_tags; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.execution_annotation_tags (
    "annotationId" integer NOT NULL,
    "tagId" character varying(24) NOT NULL
);


ALTER TABLE public.execution_annotation_tags OWNER TO integration_user;

--
-- Name: execution_annotations; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.execution_annotations (
    id integer NOT NULL,
    "executionId" integer NOT NULL,
    vote character varying(6),
    note text,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.execution_annotations OWNER TO integration_user;

--
-- Name: execution_annotations_id_seq; Type: SEQUENCE; Schema: public; Owner: integration_user
--

CREATE SEQUENCE public.execution_annotations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.execution_annotations_id_seq OWNER TO integration_user;

--
-- Name: execution_annotations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: integration_user
--

ALTER SEQUENCE public.execution_annotations_id_seq OWNED BY public.execution_annotations.id;


--
-- Name: execution_data; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.execution_data (
    "executionId" integer NOT NULL,
    "workflowData" json NOT NULL,
    data text NOT NULL,
    "workflowVersionId" character varying(36)
);


ALTER TABLE public.execution_data OWNER TO integration_user;

--
-- Name: execution_entity; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.execution_entity (
    id integer NOT NULL,
    finished boolean NOT NULL,
    mode character varying NOT NULL,
    "retryOf" character varying,
    "retrySuccessId" character varying,
    "startedAt" timestamp(3) with time zone,
    "stoppedAt" timestamp(3) with time zone,
    "waitTill" timestamp(3) with time zone,
    status character varying NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    "deletedAt" timestamp(3) with time zone,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "storedAt" character varying(2) DEFAULT 'db'::character varying NOT NULL,
    "tracingContext" json,
    "deduplicationKey" character varying(255),
    CONSTRAINT "execution_entity_storedAt_check" CHECK ((("storedAt")::text = ANY ((ARRAY['db'::character varying, 'fs'::character varying, 's3'::character varying])::text[])))
);


ALTER TABLE public.execution_entity OWNER TO integration_user;

--
-- Name: execution_entity_id_seq; Type: SEQUENCE; Schema: public; Owner: integration_user
--

CREATE SEQUENCE public.execution_entity_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.execution_entity_id_seq OWNER TO integration_user;

--
-- Name: execution_entity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: integration_user
--

ALTER SEQUENCE public.execution_entity_id_seq OWNED BY public.execution_entity.id;


--
-- Name: execution_metadata; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.execution_metadata (
    id integer NOT NULL,
    "executionId" integer NOT NULL,
    key character varying(255) NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.execution_metadata OWNER TO integration_user;

--
-- Name: execution_metadata_temp_id_seq; Type: SEQUENCE; Schema: public; Owner: integration_user
--

CREATE SEQUENCE public.execution_metadata_temp_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.execution_metadata_temp_id_seq OWNER TO integration_user;

--
-- Name: execution_metadata_temp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: integration_user
--

ALTER SEQUENCE public.execution_metadata_temp_id_seq OWNED BY public.execution_metadata.id;


--
-- Name: folder; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.folder (
    id character varying(36) NOT NULL,
    name character varying(128) NOT NULL,
    "parentFolderId" character varying(36),
    "projectId" character varying(36) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.folder OWNER TO integration_user;

--
-- Name: folder_tag; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.folder_tag (
    "folderId" character varying(36) NOT NULL,
    "tagId" character varying(36) NOT NULL
);


ALTER TABLE public.folder_tag OWNER TO integration_user;

--
-- Name: insights_by_period; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.insights_by_period (
    id integer NOT NULL,
    "metaId" integer NOT NULL,
    type integer NOT NULL,
    value bigint NOT NULL,
    "periodUnit" integer NOT NULL,
    "periodStart" timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.insights_by_period OWNER TO integration_user;

--
-- Name: COLUMN insights_by_period.type; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.insights_by_period.type IS '0: time_saved_minutes, 1: runtime_milliseconds, 2: success, 3: failure';


--
-- Name: COLUMN insights_by_period."periodUnit"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.insights_by_period."periodUnit" IS '0: hour, 1: day, 2: week';


--
-- Name: insights_by_period_id_seq; Type: SEQUENCE; Schema: public; Owner: integration_user
--

ALTER TABLE public.insights_by_period ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.insights_by_period_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: insights_metadata; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.insights_metadata (
    "metaId" integer NOT NULL,
    "workflowId" character varying(36),
    "projectId" character varying(36),
    "workflowName" character varying(128) NOT NULL,
    "projectName" character varying(255) NOT NULL
);


ALTER TABLE public.insights_metadata OWNER TO integration_user;

--
-- Name: insights_metadata_metaId_seq; Type: SEQUENCE; Schema: public; Owner: integration_user
--

ALTER TABLE public.insights_metadata ALTER COLUMN "metaId" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public."insights_metadata_metaId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: insights_raw; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.insights_raw (
    id integer NOT NULL,
    "metaId" integer NOT NULL,
    type integer NOT NULL,
    value bigint NOT NULL,
    "timestamp" timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.insights_raw OWNER TO integration_user;

--
-- Name: COLUMN insights_raw.type; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.insights_raw.type IS '0: time_saved_minutes, 1: runtime_milliseconds, 2: success, 3: failure';


--
-- Name: insights_raw_id_seq; Type: SEQUENCE; Schema: public; Owner: integration_user
--

ALTER TABLE public.insights_raw ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.insights_raw_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: installed_nodes; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.installed_nodes (
    name character varying(200) NOT NULL,
    type character varying(200) NOT NULL,
    "latestVersion" integer DEFAULT 1 NOT NULL,
    package character varying(241) NOT NULL
);


ALTER TABLE public.installed_nodes OWNER TO integration_user;

--
-- Name: installed_packages; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.installed_packages (
    "packageName" character varying(214) NOT NULL,
    "installedVersion" character varying(50) NOT NULL,
    "authorName" character varying(70),
    "authorEmail" character varying(70),
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.installed_packages OWNER TO integration_user;

--
-- Name: instance_ai_checkpoints; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.instance_ai_checkpoints (
    key character varying(255) NOT NULL,
    "runId" character varying(255),
    "threadId" uuid NOT NULL,
    "resourceId" character varying(255),
    state json,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "expiredAt" timestamp(3) with time zone,
    CONSTRAINT instance_ai_checkpoints_state_tombstone_check CHECK (((("expiredAt" IS NOT NULL) AND (state IS NULL)) OR ("expiredAt" IS NULL)))
);


ALTER TABLE public.instance_ai_checkpoints OWNER TO integration_user;

--
-- Name: COLUMN instance_ai_checkpoints.key; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_checkpoints.key IS 'Opaque checkpoint key from the agent runtime.';


--
-- Name: COLUMN instance_ai_checkpoints."runId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_checkpoints."runId" IS 'Run ID parsed from the checkpoint key when available.';


--
-- Name: COLUMN instance_ai_checkpoints."threadId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_checkpoints."threadId" IS 'Instance AI thread that owns the checkpoint.';


--
-- Name: COLUMN instance_ai_checkpoints."resourceId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_checkpoints."resourceId" IS 'Resource ID recorded by the agent runtime.';


--
-- Name: COLUMN instance_ai_checkpoints.state; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_checkpoints.state IS 'Serializable agent state snapshot stored as JSON.';


--
-- Name: COLUMN instance_ai_checkpoints."expiredAt"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_checkpoints."expiredAt" IS 'Soft-delete timestamp: null means live; non-null marks the row as a tombstone.';


--
-- Name: instance_ai_iteration_logs; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.instance_ai_iteration_logs (
    id character varying(36) NOT NULL,
    "threadId" uuid NOT NULL,
    "taskKey" character varying NOT NULL,
    entry text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.instance_ai_iteration_logs OWNER TO integration_user;

--
-- Name: instance_ai_messages; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.instance_ai_messages (
    id character varying(36) NOT NULL,
    "threadId" uuid NOT NULL,
    content text NOT NULL,
    role character varying(16) NOT NULL,
    type character varying(32),
    "resourceId" character varying(255),
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.instance_ai_messages OWNER TO integration_user;

--
-- Name: instance_ai_observation_cursors; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.instance_ai_observation_cursors (
    "observationScopeId" uuid NOT NULL,
    "lastObservedMessageId" character varying(36) NOT NULL,
    "lastObservedAt" timestamp(3) with time zone NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.instance_ai_observation_cursors OWNER TO integration_user;

--
-- Name: COLUMN instance_ai_observation_cursors."observationScopeId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_observation_cursors."observationScopeId" IS 'instance_ai_threads.id source stream checkpointed by this cursor';


--
-- Name: instance_ai_observation_locks; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.instance_ai_observation_locks (
    "observationScopeId" uuid NOT NULL,
    "taskKind" character varying(20) NOT NULL,
    "holderId" character varying(64) NOT NULL,
    "heldUntil" timestamp(3) with time zone NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_instance_ai_observation_locks_taskKind" CHECK ((("taskKind")::text = ANY ((ARRAY['observer'::character varying, 'reflector'::character varying])::text[])))
);


ALTER TABLE public.instance_ai_observation_locks OWNER TO integration_user;

--
-- Name: COLUMN instance_ai_observation_locks."observationScopeId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_observation_locks."observationScopeId" IS 'instance_ai_threads.id source stream locked for observation tasks';


--
-- Name: COLUMN instance_ai_observation_locks."holderId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_observation_locks."holderId" IS 'Ephemeral background-task lock owner token, not a user ID';


--
-- Name: instance_ai_observational_memory; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.instance_ai_observational_memory (
    id character varying(36) NOT NULL,
    "lookupKey" character varying(255) NOT NULL,
    scope character varying(16) NOT NULL,
    "threadId" uuid,
    "resourceId" character varying(255) NOT NULL,
    "activeObservations" text DEFAULT ''::text NOT NULL,
    "originType" character varying(32) NOT NULL,
    config text NOT NULL,
    "generationCount" integer DEFAULT 0 NOT NULL,
    "lastObservedAt" timestamp(3) with time zone,
    "pendingMessageTokens" integer DEFAULT 0 NOT NULL,
    "totalTokensObserved" integer DEFAULT 0 NOT NULL,
    "observationTokenCount" integer DEFAULT 0 NOT NULL,
    "isObserving" boolean DEFAULT false NOT NULL,
    "isReflecting" boolean DEFAULT false NOT NULL,
    "observedMessageIds" json,
    "observedTimezone" character varying,
    "bufferedObservations" text,
    "bufferedObservationTokens" integer,
    "bufferedMessageIds" json,
    "bufferedReflection" text,
    "bufferedReflectionTokens" integer,
    "bufferedReflectionInputTokens" integer,
    "reflectedObservationLineCount" integer,
    "bufferedObservationChunks" json,
    "isBufferingObservation" boolean DEFAULT false NOT NULL,
    "isBufferingReflection" boolean DEFAULT false NOT NULL,
    "lastBufferedAtTokens" integer DEFAULT 0 NOT NULL,
    "lastBufferedAtTime" timestamp(3) with time zone,
    metadata json,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.instance_ai_observational_memory OWNER TO integration_user;

--
-- Name: instance_ai_observations; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.instance_ai_observations (
    id character varying(36) NOT NULL,
    "observationScopeId" uuid NOT NULL,
    marker character varying(16) NOT NULL,
    text text NOT NULL,
    "parentId" character varying(36),
    "tokenCount" integer DEFAULT 0 NOT NULL,
    status character varying(16) NOT NULL,
    "supersededBy" character varying(36),
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_instance_ai_observations_marker" CHECK (((marker)::text = ANY ((ARRAY['critical'::character varying, 'important'::character varying, 'info'::character varying, 'completion'::character varying])::text[]))),
    CONSTRAINT "CHK_instance_ai_observations_status" CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'superseded'::character varying, 'dropped'::character varying])::text[])))
);


ALTER TABLE public.instance_ai_observations OWNER TO integration_user;

--
-- Name: COLUMN instance_ai_observations.id; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_observations.id IS 'Application-generated n8n string ID, not a database UUID';


--
-- Name: COLUMN instance_ai_observations."observationScopeId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_observations."observationScopeId" IS 'instance_ai_threads.id source stream for this observation log';


--
-- Name: instance_ai_pending_confirmations; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.instance_ai_pending_confirmations (
    "requestId" character varying(36) NOT NULL,
    "threadId" uuid NOT NULL,
    "userId" uuid NOT NULL,
    kind character varying(16) NOT NULL,
    "runId" character varying(36) NOT NULL,
    "toolCallId" character varying(64),
    "messageGroupId" character varying(36),
    "checkpointKey" character varying(255),
    "checkpointTaskId" character varying(36),
    "expiresAt" timestamp(3) with time zone,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_instance_ai_pending_confirmations_kind" CHECK (((kind)::text = ANY ((ARRAY['suspended'::character varying, 'inline'::character varying])::text[])))
);


ALTER TABLE public.instance_ai_pending_confirmations OWNER TO integration_user;

--
-- Name: COLUMN instance_ai_pending_confirmations."requestId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_pending_confirmations."requestId" IS 'HITL confirmation request identifier.';


--
-- Name: COLUMN instance_ai_pending_confirmations."threadId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_pending_confirmations."threadId" IS 'Instance AI thread that owns the confirmation.';


--
-- Name: COLUMN instance_ai_pending_confirmations."userId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_pending_confirmations."userId" IS 'User who is expected to confirm or cancel.';


--
-- Name: COLUMN instance_ai_pending_confirmations.kind; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_pending_confirmations.kind IS '''suspended'' (resumable from checkpoint) or ''inline'' (orchestrator-held Promise).';


--
-- Name: COLUMN instance_ai_pending_confirmations."runId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_pending_confirmations."runId" IS 'External run ID; reused on resume for SSE correlation.';


--
-- Name: COLUMN instance_ai_pending_confirmations."toolCallId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_pending_confirmations."toolCallId" IS 'Suspended tool call awaiting confirmation.';


--
-- Name: COLUMN instance_ai_pending_confirmations."messageGroupId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_pending_confirmations."messageGroupId" IS 'SSE event correlation group.';


--
-- Name: COLUMN instance_ai_pending_confirmations."checkpointKey"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_pending_confirmations."checkpointKey" IS 'FK to instance_ai_checkpoints.key; also the SDK runId used to resume.';


--
-- Name: COLUMN instance_ai_pending_confirmations."checkpointTaskId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_pending_confirmations."checkpointTaskId" IS 'Set when the suspended run was a planned-task checkpoint follow-up.';


--
-- Name: COLUMN instance_ai_pending_confirmations."expiresAt"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_pending_confirmations."expiresAt" IS 'TTL for the leader-only sweep; null disables auto-expiry.';


--
-- Name: instance_ai_resources; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.instance_ai_resources (
    id character varying(255) NOT NULL,
    "workingMemory" text,
    metadata json,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.instance_ai_resources OWNER TO integration_user;

--
-- Name: instance_ai_run_snapshots; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.instance_ai_run_snapshots (
    "threadId" uuid NOT NULL,
    "runId" character varying(36) NOT NULL,
    "messageGroupId" character varying(36),
    "runIds" json,
    tree text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "langsmithRunId" character varying(36),
    "langsmithTraceId" character varying(36),
    "traceId" character varying(64),
    "spanId" character varying(64)
);


ALTER TABLE public.instance_ai_run_snapshots OWNER TO integration_user;

--
-- Name: COLUMN instance_ai_run_snapshots."langsmithRunId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_run_snapshots."langsmithRunId" IS 'LangSmith run ID (UUID v4, e.g. "f47ac10b-58cc-4372-a567-0e02b2c3d479").';


--
-- Name: COLUMN instance_ai_run_snapshots."langsmithTraceId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_run_snapshots."langsmithTraceId" IS 'LangSmith trace ID (UUID v4, e.g. "f47ac10b-58cc-4372-a567-0e02b2c3d479").';


--
-- Name: COLUMN instance_ai_run_snapshots."traceId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_run_snapshots."traceId" IS 'OpenTelemetry trace ID for the root Instance AI run.';


--
-- Name: COLUMN instance_ai_run_snapshots."spanId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.instance_ai_run_snapshots."spanId" IS 'OpenTelemetry span ID for the root Instance AI run.';


--
-- Name: instance_ai_threads; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.instance_ai_threads (
    id uuid NOT NULL,
    "resourceId" character varying(255) NOT NULL,
    title text DEFAULT ''::text NOT NULL,
    metadata json,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.instance_ai_threads OWNER TO integration_user;

--
-- Name: instance_ai_workflow_snapshots; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.instance_ai_workflow_snapshots (
    "runId" character varying(36) NOT NULL,
    "workflowName" character varying(255) NOT NULL,
    "resourceId" character varying(255),
    status character varying,
    snapshot text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.instance_ai_workflow_snapshots OWNER TO integration_user;

--
-- Name: instance_version_history; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.instance_version_history (
    id integer NOT NULL,
    major integer NOT NULL,
    minor integer NOT NULL,
    patch integer NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.instance_version_history OWNER TO integration_user;

--
-- Name: instance_version_history_id_seq; Type: SEQUENCE; Schema: public; Owner: integration_user
--

CREATE SEQUENCE public.instance_version_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.instance_version_history_id_seq OWNER TO integration_user;

--
-- Name: instance_version_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: integration_user
--

ALTER SEQUENCE public.instance_version_history_id_seq OWNED BY public.instance_version_history.id;


--
-- Name: invalid_auth_token; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.invalid_auth_token (
    token character varying(512) NOT NULL,
    "expiresAt" timestamp(3) with time zone NOT NULL
);


ALTER TABLE public.invalid_auth_token OWNER TO integration_user;

--
-- Name: mcp_registry_server; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.mcp_registry_server (
    slug character varying(255) NOT NULL,
    status character varying(50) NOT NULL,
    version character varying(50) NOT NULL,
    "registryUpdatedAt" timestamp(3) without time zone NOT NULL,
    data json DEFAULT '{}'::json NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_tmp_mcp_registry_server_status" CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'deprecated'::character varying])::text[])))
);


ALTER TABLE public.mcp_registry_server OWNER TO integration_user;

--
-- Name: COLUMN mcp_registry_server.status; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.mcp_registry_server.status IS 'Server status in the MCP registry. Deprecated servers are not surfaced to users.';


--
-- Name: COLUMN mcp_registry_server.data; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.mcp_registry_server.data IS 'JSON object containing server metadata (icons, remotes, tools, etc.)';


--
-- Name: migrations; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    "timestamp" bigint NOT NULL,
    name character varying NOT NULL
);


ALTER TABLE public.migrations OWNER TO integration_user;

--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: integration_user
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.migrations_id_seq OWNER TO integration_user;

--
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: integration_user
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- Name: oauth_access_tokens; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.oauth_access_tokens (
    token character varying NOT NULL,
    "clientId" character varying NOT NULL,
    "userId" uuid NOT NULL
);


ALTER TABLE public.oauth_access_tokens OWNER TO integration_user;

--
-- Name: oauth_authorization_codes; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.oauth_authorization_codes (
    code character varying(255) NOT NULL,
    "clientId" character varying NOT NULL,
    "userId" uuid NOT NULL,
    "redirectUri" character varying NOT NULL,
    "codeChallenge" character varying NOT NULL,
    "codeChallengeMethod" character varying(255) NOT NULL,
    "expiresAt" bigint NOT NULL,
    state character varying,
    used boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.oauth_authorization_codes OWNER TO integration_user;

--
-- Name: COLUMN oauth_authorization_codes."expiresAt"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.oauth_authorization_codes."expiresAt" IS 'Unix timestamp in milliseconds';


--
-- Name: oauth_clients; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.oauth_clients (
    id character varying NOT NULL,
    name character varying(255) NOT NULL,
    "redirectUris" json NOT NULL,
    "grantTypes" json NOT NULL,
    "clientSecret" character varying(255),
    "clientSecretExpiresAt" bigint,
    "tokenEndpointAuthMethod" character varying(255) DEFAULT 'none'::character varying NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.oauth_clients OWNER TO integration_user;

--
-- Name: COLUMN oauth_clients."tokenEndpointAuthMethod"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.oauth_clients."tokenEndpointAuthMethod" IS 'Possible values: none, client_secret_basic or client_secret_post';


--
-- Name: oauth_refresh_tokens; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.oauth_refresh_tokens (
    token character varying(255) NOT NULL,
    "clientId" character varying NOT NULL,
    "userId" uuid NOT NULL,
    "expiresAt" bigint NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.oauth_refresh_tokens OWNER TO integration_user;

--
-- Name: COLUMN oauth_refresh_tokens."expiresAt"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.oauth_refresh_tokens."expiresAt" IS 'Unix timestamp in milliseconds';


--
-- Name: oauth_user_consents; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.oauth_user_consents (
    id integer NOT NULL,
    "userId" uuid NOT NULL,
    "clientId" character varying NOT NULL,
    "grantedAt" bigint NOT NULL
);


ALTER TABLE public.oauth_user_consents OWNER TO integration_user;

--
-- Name: COLUMN oauth_user_consents."grantedAt"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.oauth_user_consents."grantedAt" IS 'Unix timestamp in milliseconds';


--
-- Name: oauth_user_consents_id_seq; Type: SEQUENCE; Schema: public; Owner: integration_user
--

ALTER TABLE public.oauth_user_consents ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.oauth_user_consents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: processed_data; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.processed_data (
    "workflowId" character varying(36) NOT NULL,
    context character varying(255) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.processed_data OWNER TO integration_user;

--
-- Name: project; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.project (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    type character varying(36) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    icon json,
    description character varying(512),
    "creatorId" uuid,
    "customTelemetryTags" json DEFAULT '[]'::json NOT NULL
);


ALTER TABLE public.project OWNER TO integration_user;

--
-- Name: COLUMN project."creatorId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.project."creatorId" IS 'ID of the user who created the project';


--
-- Name: project_relation; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.project_relation (
    "projectId" character varying(36) NOT NULL,
    "userId" uuid NOT NULL,
    role character varying NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.project_relation OWNER TO integration_user;

--
-- Name: project_secrets_provider_access; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.project_secrets_provider_access (
    "secretsProviderConnectionId" integer NOT NULL,
    "projectId" character varying(36) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    role character varying(128) DEFAULT 'secretsProviderConnection:user'::character varying NOT NULL,
    CONSTRAINT "CHK_project_secrets_provider_access_role" CHECK (((role)::text = ANY ((ARRAY['secretsProviderConnection:owner'::character varying, 'secretsProviderConnection:user'::character varying])::text[])))
);


ALTER TABLE public.project_secrets_provider_access OWNER TO integration_user;

--
-- Name: role; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.role (
    slug character varying(128) NOT NULL,
    "displayName" text,
    description text,
    "roleType" text,
    "systemRole" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.role OWNER TO integration_user;

--
-- Name: COLUMN role.slug; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.role.slug IS 'Unique identifier of the role for example: "global:owner"';


--
-- Name: COLUMN role."displayName"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.role."displayName" IS 'Name used to display in the UI';


--
-- Name: COLUMN role.description; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.role.description IS 'Text describing the scope in more detail of users';


--
-- Name: COLUMN role."roleType"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.role."roleType" IS 'Type of the role, e.g., global, project, or workflow';


--
-- Name: COLUMN role."systemRole"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.role."systemRole" IS 'Indicates if the role is managed by the system and cannot be edited';


--
-- Name: role_mapping_rule; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.role_mapping_rule (
    id character varying(16) NOT NULL,
    expression text NOT NULL,
    role character varying(128) NOT NULL,
    type character varying(64) NOT NULL,
    "order" integer NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.role_mapping_rule OWNER TO integration_user;

--
-- Name: COLUMN role_mapping_rule.type; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.role_mapping_rule.type IS 'Expected values: ''instance'' (maps to a global role) or ''project'' (maps to a project role; projects linked via role_mapping_rule_project).';


--
-- Name: role_mapping_rule_project; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.role_mapping_rule_project (
    "roleMappingRuleId" character varying(16) NOT NULL,
    "projectId" character varying(36) NOT NULL
);


ALTER TABLE public.role_mapping_rule_project OWNER TO integration_user;

--
-- Name: role_scope; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.role_scope (
    "roleSlug" character varying(128) NOT NULL,
    "scopeSlug" character varying(128) NOT NULL
);


ALTER TABLE public.role_scope OWNER TO integration_user;

--
-- Name: scope; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.scope (
    slug character varying(128) NOT NULL,
    "displayName" text,
    description text
);


ALTER TABLE public.scope OWNER TO integration_user;

--
-- Name: COLUMN scope.slug; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.scope.slug IS 'Unique identifier of the scope for example: "project:create"';


--
-- Name: COLUMN scope."displayName"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.scope."displayName" IS 'Name used to display in the UI';


--
-- Name: COLUMN scope.description; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.scope.description IS 'Text describing the scope in more detail of users';


--
-- Name: secrets_provider_connection; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.secrets_provider_connection (
    id integer NOT NULL,
    "providerKey" character varying(128) NOT NULL,
    type character varying(36) NOT NULL,
    "encryptedSettings" text NOT NULL,
    "isEnabled" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.secrets_provider_connection OWNER TO integration_user;

--
-- Name: COLUMN secrets_provider_connection.type; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.secrets_provider_connection.type IS 'Type of secrets provider. Possible values: awsSecretsManager, gcpSecretsManager, vault, azureKeyVault, infisical';


--
-- Name: secrets_provider_connection_id_seq; Type: SEQUENCE; Schema: public; Owner: integration_user
--

ALTER TABLE public.secrets_provider_connection ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.secrets_provider_connection_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: settings; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.settings (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    "loadOnStartup" boolean DEFAULT false NOT NULL
);


ALTER TABLE public.settings OWNER TO integration_user;

--
-- Name: shared_credentials; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.shared_credentials (
    "credentialsId" character varying(36) NOT NULL,
    "projectId" character varying(36) NOT NULL,
    role text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.shared_credentials OWNER TO integration_user;

--
-- Name: shared_workflow; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.shared_workflow (
    "workflowId" character varying(36) NOT NULL,
    "projectId" character varying(36) NOT NULL,
    role text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.shared_workflow OWNER TO integration_user;

--
-- Name: tag_entity; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.tag_entity (
    name character varying(24) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    id character varying(36) NOT NULL
);


ALTER TABLE public.tag_entity OWNER TO integration_user;

--
-- Name: test_case_execution; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.test_case_execution (
    id character varying(36) NOT NULL,
    "testRunId" character varying(36) NOT NULL,
    "executionId" integer,
    status character varying NOT NULL,
    "runAt" timestamp(3) with time zone,
    "completedAt" timestamp(3) with time zone,
    "errorCode" character varying,
    "errorDetails" json,
    metrics json,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    inputs json,
    outputs json,
    "runIndex" integer
);


ALTER TABLE public.test_case_execution OWNER TO integration_user;

--
-- Name: test_run; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.test_run (
    id character varying(36) NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    status character varying NOT NULL,
    "errorCode" character varying,
    "errorDetails" json,
    "runAt" timestamp(3) with time zone,
    "completedAt" timestamp(3) with time zone,
    metrics json,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "runningInstanceId" character varying(255),
    "cancelRequested" boolean DEFAULT false NOT NULL,
    "workflowVersionId" character varying(36),
    "evaluationConfigId" character varying(36),
    "evaluationConfigSnapshot" jsonb,
    "collectionId" character varying(36)
);


ALTER TABLE public.test_run OWNER TO integration_user;

--
-- Name: token_exchange_jti; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.token_exchange_jti (
    jti character varying(255) NOT NULL,
    "expiresAt" timestamp(3) with time zone NOT NULL,
    "createdAt" timestamp(3) with time zone NOT NULL
);


ALTER TABLE public.token_exchange_jti OWNER TO integration_user;

--
-- Name: trusted_key; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.trusted_key (
    "sourceId" character varying(36) NOT NULL,
    kid character varying(255) NOT NULL,
    data text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.trusted_key OWNER TO integration_user;

--
-- Name: trusted_key_source; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.trusted_key_source (
    id character varying(36) NOT NULL,
    type character varying(32) NOT NULL,
    config text NOT NULL,
    status character varying(32) DEFAULT 'pending'::character varying NOT NULL,
    "lastError" text,
    "lastRefreshedAt" timestamp(3) with time zone,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.trusted_key_source OWNER TO integration_user;

--
-- Name: user; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public."user" (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(255),
    "firstName" character varying(32),
    "lastName" character varying(32),
    password character varying(255),
    "personalizationAnswers" json,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    settings json,
    disabled boolean DEFAULT false NOT NULL,
    "mfaEnabled" boolean DEFAULT false NOT NULL,
    "mfaSecret" text,
    "mfaRecoveryCodes" text,
    "lastActiveAt" date,
    "roleSlug" character varying(128) DEFAULT 'global:member'::character varying NOT NULL
);


ALTER TABLE public."user" OWNER TO integration_user;

--
-- Name: user_api_keys; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.user_api_keys (
    id character varying(36) NOT NULL,
    "userId" uuid NOT NULL,
    label character varying(100) NOT NULL,
    "apiKey" character varying NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    scopes json,
    audience character varying DEFAULT 'public-api'::character varying NOT NULL,
    "lastUsedAt" timestamp(3) with time zone
);


ALTER TABLE public.user_api_keys OWNER TO integration_user;

--
-- Name: user_favorites; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.user_favorites (
    id integer NOT NULL,
    "userId" uuid NOT NULL,
    "resourceId" character varying(255) NOT NULL,
    "resourceType" character varying(64) NOT NULL
);


ALTER TABLE public.user_favorites OWNER TO integration_user;

--
-- Name: user_favorites_id_seq; Type: SEQUENCE; Schema: public; Owner: integration_user
--

ALTER TABLE public.user_favorites ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.user_favorites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: variables; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.variables (
    key character varying(50) NOT NULL,
    type character varying(50) DEFAULT 'string'::character varying NOT NULL,
    value text,
    id character varying(36) NOT NULL,
    "projectId" character varying(36),
    CONSTRAINT variables_value_max_len CHECK (((value IS NULL) OR (char_length(value) <= 1000)))
);


ALTER TABLE public.variables OWNER TO integration_user;

--
-- Name: webhook_entity; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.webhook_entity (
    "webhookPath" character varying NOT NULL,
    method character varying NOT NULL,
    node character varying NOT NULL,
    "webhookId" character varying,
    "pathLength" integer,
    "workflowId" character varying(36) NOT NULL
);


ALTER TABLE public.webhook_entity OWNER TO integration_user;

--
-- Name: workflow_builder_session; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.workflow_builder_session (
    id uuid NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    "userId" uuid NOT NULL,
    messages json DEFAULT '[]'::json NOT NULL,
    "previousSummary" text,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "activeVersionCardId" character varying(255),
    "resumeAfterRestoreMessageId" character varying(255)
);


ALTER TABLE public.workflow_builder_session OWNER TO integration_user;

--
-- Name: COLUMN workflow_builder_session."previousSummary"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.workflow_builder_session."previousSummary" IS 'Summary of prior conversation from compaction (/compact or auto-compact)';


--
-- Name: workflow_dependency; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.workflow_dependency (
    id integer NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    "workflowVersionId" integer NOT NULL,
    "dependencyType" character varying(32) NOT NULL,
    "dependencyKey" character varying(255) NOT NULL,
    "dependencyInfo" json,
    "indexVersionId" smallint DEFAULT 1 NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "publishedVersionId" character varying(36)
);


ALTER TABLE public.workflow_dependency OWNER TO integration_user;

--
-- Name: COLUMN workflow_dependency."workflowVersionId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.workflow_dependency."workflowVersionId" IS 'Version of the workflow';


--
-- Name: COLUMN workflow_dependency."dependencyType"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.workflow_dependency."dependencyType" IS 'Type of dependency: "credential", "nodeType", "webhookPath", or "workflowCall"';


--
-- Name: COLUMN workflow_dependency."dependencyKey"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.workflow_dependency."dependencyKey" IS 'ID or name of the dependency';


--
-- Name: COLUMN workflow_dependency."dependencyInfo"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.workflow_dependency."dependencyInfo" IS 'Additional info about the dependency, interpreted based on type';


--
-- Name: COLUMN workflow_dependency."indexVersionId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.workflow_dependency."indexVersionId" IS 'Version of the index structure';


--
-- Name: workflow_dependency_id_seq; Type: SEQUENCE; Schema: public; Owner: integration_user
--

ALTER TABLE public.workflow_dependency ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.workflow_dependency_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: workflow_entity; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.workflow_entity (
    name character varying(128) NOT NULL,
    active boolean NOT NULL,
    nodes json NOT NULL,
    connections json NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    settings json,
    "staticData" json,
    "pinData" json,
    "versionId" character(36) NOT NULL,
    "triggerCount" integer DEFAULT 0 NOT NULL,
    id character varying(36) NOT NULL,
    meta json,
    "parentFolderId" character varying(36) DEFAULT NULL::character varying,
    "isArchived" boolean DEFAULT false NOT NULL,
    "versionCounter" integer DEFAULT 1 NOT NULL,
    description text,
    "activeVersionId" character varying(36),
    "nodeGroups" json DEFAULT '[]'::json NOT NULL,
    "sourceWorkflowId" character varying
);


ALTER TABLE public.workflow_entity OWNER TO integration_user;

--
-- Name: workflow_history; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.workflow_history (
    "versionId" character varying(36) NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    authors character varying(255) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    nodes json NOT NULL,
    connections json NOT NULL,
    name character varying(128),
    autosaved boolean DEFAULT false NOT NULL,
    description text,
    "nodeGroups" json DEFAULT '[]'::json NOT NULL
);


ALTER TABLE public.workflow_history OWNER TO integration_user;

--
-- Name: workflow_publication_outbox; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.workflow_publication_outbox (
    id integer NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    "publishedVersionId" character varying(36) NOT NULL,
    status character varying(20) NOT NULL,
    "errorMessage" text,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_workflow_publication_outbox_status" CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'in_progress'::character varying, 'completed'::character varying, 'partial_success'::character varying, 'failed'::character varying])::text[])))
);


ALTER TABLE public.workflow_publication_outbox OWNER TO integration_user;

--
-- Name: COLUMN workflow_publication_outbox."workflowId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.workflow_publication_outbox."workflowId" IS 'References workflow_entity.id.';


--
-- Name: COLUMN workflow_publication_outbox."publishedVersionId"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.workflow_publication_outbox."publishedVersionId" IS 'References workflow_history.versionId.';


--
-- Name: COLUMN workflow_publication_outbox."errorMessage"; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.workflow_publication_outbox."errorMessage" IS 'Error details for surfacing failed publications to the user.';


--
-- Name: workflow_publication_outbox_id_seq; Type: SEQUENCE; Schema: public; Owner: integration_user
--

ALTER TABLE public.workflow_publication_outbox ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.workflow_publication_outbox_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: workflow_publish_history; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.workflow_publish_history (
    id integer NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    "versionId" character varying(36),
    event character varying(36) NOT NULL,
    "userId" uuid,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_workflow_publish_history_event" CHECK (((event)::text = ANY ((ARRAY['activated'::character varying, 'deactivated'::character varying])::text[])))
);


ALTER TABLE public.workflow_publish_history OWNER TO integration_user;

--
-- Name: COLUMN workflow_publish_history.event; Type: COMMENT; Schema: public; Owner: integration_user
--

COMMENT ON COLUMN public.workflow_publish_history.event IS 'Type of history record: activated (workflow is now active), deactivated (workflow is now inactive)';


--
-- Name: workflow_publish_history_id_seq; Type: SEQUENCE; Schema: public; Owner: integration_user
--

ALTER TABLE public.workflow_publish_history ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.workflow_publish_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: workflow_published_version; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.workflow_published_version (
    "workflowId" character varying(36) NOT NULL,
    "publishedVersionId" character varying(36) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.workflow_published_version OWNER TO integration_user;

--
-- Name: workflow_statistics; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.workflow_statistics (
    count bigint DEFAULT 0,
    "latestEvent" timestamp(3) with time zone,
    name character varying(128) NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    "rootCount" bigint DEFAULT 0,
    id integer NOT NULL,
    "workflowName" character varying(128)
);


ALTER TABLE public.workflow_statistics OWNER TO integration_user;

--
-- Name: workflow_statistics_id_seq; Type: SEQUENCE; Schema: public; Owner: integration_user
--

CREATE SEQUENCE public.workflow_statistics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.workflow_statistics_id_seq OWNER TO integration_user;

--
-- Name: workflow_statistics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: integration_user
--

ALTER SEQUENCE public.workflow_statistics_id_seq OWNED BY public.workflow_statistics.id;


--
-- Name: workflows_tags; Type: TABLE; Schema: public; Owner: integration_user
--

CREATE TABLE public.workflows_tags (
    "workflowId" character varying(36) NOT NULL,
    "tagId" character varying(36) NOT NULL
);


ALTER TABLE public.workflows_tags OWNER TO integration_user;

--
-- Name: auth_provider_sync_history id; Type: DEFAULT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.auth_provider_sync_history ALTER COLUMN id SET DEFAULT nextval('public.auth_provider_sync_history_id_seq'::regclass);


--
-- Name: execution_annotations id; Type: DEFAULT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.execution_annotations ALTER COLUMN id SET DEFAULT nextval('public.execution_annotations_id_seq'::regclass);


--
-- Name: execution_entity id; Type: DEFAULT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.execution_entity ALTER COLUMN id SET DEFAULT nextval('public.execution_entity_id_seq'::regclass);


--
-- Name: execution_metadata id; Type: DEFAULT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.execution_metadata ALTER COLUMN id SET DEFAULT nextval('public.execution_metadata_temp_id_seq'::regclass);


--
-- Name: instance_version_history id; Type: DEFAULT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_version_history ALTER COLUMN id SET DEFAULT nextval('public.instance_version_history_id_seq'::regclass);


--
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- Name: workflow_statistics id; Type: DEFAULT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_statistics ALTER COLUMN id SET DEFAULT nextval('public.workflow_statistics_id_seq'::regclass);


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: audit; Owner: postgres
--

COPY audit.audit_log (id, user_id, action, entity_type, entity_id, details, ip_address, user_agent, created_at) FROM stdin;
\.


--
-- Data for Name: buildings; Type: TABLE DATA; Schema: cmdb; Owner: cmdb_user
--

COPY cmdb.buildings (id, object_id, name, floors_count, notes, created_at, is_active) FROM stdin;
\.


--
-- Data for Name: equipment; Type: TABLE DATA; Schema: cmdb; Owner: cmdb_user
--

COPY cmdb.equipment (id, equipment_code, object_id, room_id, equipment_type_id, vendor_id, model, serial_number, firmware_version, ip_address, mac_address, install_date, warranty_end_date, status, lifecycle_project_id, notes, created_at, updated_at, created_by, is_active) FROM stdin;
\.


--
-- Data for Name: equipment_relations; Type: TABLE DATA; Schema: cmdb; Owner: cmdb_user
--

COPY cmdb.equipment_relations (id, source_equipment_id, target_equipment_id, relation_type, port_label, notes, created_at, is_active) FROM stdin;
\.


--
-- Data for Name: equipment_types; Type: TABLE DATA; Schema: cmdb; Owner: cmdb_user
--

COPY cmdb.equipment_types (id, name, code, category, parent_id, checklist_template_id, created_at, is_active) FROM stdin;
\.


--
-- Data for Name: floors; Type: TABLE DATA; Schema: cmdb; Owner: cmdb_user
--

COPY cmdb.floors (id, building_id, level, name, created_at, is_active) FROM stdin;
\.


--
-- Data for Name: objects; Type: TABLE DATA; Schema: cmdb; Owner: cmdb_user
--

COPY cmdb.objects (id, object_code, customer_id, name, address, gps_lat, gps_lon, object_type, service_level, status, notes, created_at, updated_at, created_by, is_active) FROM stdin;
34834de3-3112-4636-917d-700fc60ddd2d	OBJ-000001	a0000000-0000-0000-0000-000000000001	Тестовий об'єкт	\N	\N	\N	shop	standard	ACTIVE	\N	2026-06-13 14:30:17.063652+00	2026-06-13 14:30:17.063657+00	\N	t
\.


--
-- Data for Name: rooms; Type: TABLE DATA; Schema: cmdb; Owner: cmdb_user
--

COPY cmdb.rooms (id, floor_id, name, room_type, area_sqm, created_at, is_active) FROM stdin;
\.


--
-- Data for Name: vendors; Type: TABLE DATA; Schema: cmdb; Owner: cmdb_user
--

COPY cmdb.vendors (id, name, code, website, support_email, support_phone, notes, created_at, is_active) FROM stdin;
\.


--
-- Data for Name: maintenance_plans; Type: TABLE DATA; Schema: fsm; Owner: fsm_user
--

COPY fsm.maintenance_plans (id, object_id, customer_id, name, frequency, next_due_date, last_executed, checklist_template_id, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sla_events; Type: TABLE DATA; Schema: fsm; Owner: fsm_user
--

COPY fsm.sla_events (id, ticket_id, event_type, timer_type, occurred_at, details) FROM stdin;
33800d2e-9d61-4dbc-a2c3-aad7cc2bb328	82583a1e-a2be-4a0b-bf3c-3b0034f372fa	started	response	2026-06-13 14:30:17.154114+00	SLA timers started on ticket creation
bbfac2fe-85a2-4d99-b4be-83d707f182dc	1c62b9c6-ae42-408a-b744-0c248660bc6e	started	response	2026-06-13 15:16:33.295717+00	SLA timers started on ticket creation
43a87df7-a8d8-4eb5-b6af-aba8cf5abf19	23912ac3-1723-43e5-87b7-46db4c0c0a78	started	response	2026-06-13 15:23:54.405704+00	SLA timers started on ticket creation
ed8b97d6-12a9-474a-924f-8abb7e20b36b	c08aa147-6fa8-4120-8fd8-86629891112a	started	response	2026-06-13 15:32:15.385099+00	SLA timers started on ticket creation
35841c25-fd5d-404c-b135-609a47f5834f	82583a1e-a2be-4a0b-bf3c-3b0034f372fa	breached	response	2026-06-13 16:30:50.33725+00	Response SLA breached at 2026-06-13T16:30:50.328960+00:00
97ac2d6e-5245-4bbe-8f5d-cd2afca0278f	c08aa147-6fa8-4120-8fd8-86629891112a	breached	response	2026-06-13 17:32:50.332794+00	Response SLA breached at 2026-06-13T17:32:50.328863+00:00
78ec5d8c-f7a0-4645-b6c4-3b875ebbeead	843d5bfa-2a05-4502-a594-15441436f061	started	response	2026-06-13 21:22:49.703761+00	SLA timers started on ticket creation
18e8ae45-0272-41a1-a7ab-519346eef1be	2a8a0f81-20e6-4966-9285-6ac87647ec61	started	response	2026-06-13 22:08:44.16621+00	SLA timers started on ticket creation
dce9fce7-3698-47ba-bdcf-151c8f758095	82583a1e-a2be-4a0b-bf3c-3b0034f372fa	breached	arrival	2026-06-13 22:30:50.330406+00	Arrival SLA breached at 2026-06-13T22:30:50.327944+00:00
a4556df5-32fb-4c46-b1ce-a233d95dc8fc	d40082fd-15ea-4380-bd87-faa136cccd31	started	response	2026-06-13 23:03:20.501091+00	SLA timers started on ticket creation
a93e0b8c-5487-4007-9161-1c8930099ab7	1c62b9c6-ae42-408a-b744-0c248660bc6e	breached	response	2026-06-13 23:16:47.509148+00	Response SLA breached at 2026-06-13T23:16:47.499621+00:00
63a3df22-5b37-4811-b1c5-8abab1fbc92f	1c62b9c6-ae42-408a-b744-0c248660bc6e	breached	response	2026-06-13 23:16:47.498016+00	Response SLA breached at 2026-06-13T23:16:47.487067+00:00
cfb370d5-95d0-4d16-9b2e-576f37677695	23912ac3-1723-43e5-87b7-46db4c0c0a78	breached	response	2026-06-13 23:24:47.492691+00	Response SLA breached at 2026-06-13T23:24:47.487495+00:00
0a97a2e8-42c4-40f4-a516-90fd4e5c3acb	23912ac3-1723-43e5-87b7-46db4c0c0a78	breached	response	2026-06-13 23:24:47.501219+00	Response SLA breached at 2026-06-13T23:24:47.497860+00:00
54642e24-8711-45b7-ac31-43fc3fa4a756	c08aa147-6fa8-4120-8fd8-86629891112a	breached	arrival	2026-06-13 23:32:47.490467+00	Arrival SLA breached at 2026-06-13T23:32:47.487378+00:00
c4759e5d-96f5-470d-97d1-d826214c0793	d40082fd-15ea-4380-bd87-faa136cccd31	breached	response	2026-06-13 23:33:47.494266+00	Response SLA breached at 2026-06-13T23:33:47.486958+00:00
2393c95a-5f98-47c4-99d0-a01a78a5fb20	432c2b9a-386f-4cbb-a052-36ab2554ea69	started	response	2026-06-13 23:54:30.790636+00	SLA timers started on ticket creation
854981de-5ae8-4d1f-9c93-a88234560524	010dd8c4-6a70-41fb-ab87-1475e31fb0de	started	response	2026-06-13 23:56:35.928201+00	SLA timers started on ticket creation
3fa4df60-0ca6-4f06-b1d8-1295f79daf4a	c77e1f5e-4a28-45ca-99ae-b821aaa09992	started	response	2026-06-13 23:57:21.14263+00	SLA timers started on ticket creation
4b0642b6-ccb1-4cdd-b58e-e80f96637ac7	5b868be3-7647-4dd1-8435-74730179b678	started	response	2026-06-13 23:58:20.039206+00	SLA timers started on ticket creation
86994687-bdc5-4cb8-9589-2baa9758f8a1	40bf7d91-61db-4ebb-97b8-510f20fa4bfe	started	response	2026-06-14 00:11:09.681101+00	SLA timers started on ticket creation
\.


--
-- Data for Name: tickets; Type: TABLE DATA; Schema: fsm; Owner: fsm_user
--

COPY fsm.tickets (id, ticket_number, customer_id, object_id, contract_id, ticket_type, priority, status, title, description, assigned_engineer_id, sla_response_due, sla_arrival_due, sla_resolution_due, sla_paused_at, sla_pause_minutes, sla_response_breached, sla_arrival_breached, sla_resolution_breached, resolved_at, closed_at, created_at, updated_at, created_by, is_active) FROM stdin;
843d5bfa-2a05-4502-a594-15441436f061	TKT-000005	a0000000-0000-0000-0000-000000000001	a0000000-0000-0000-0000-000000000002	\N	SERVICE_REQUEST	MEDIUM	NEW	Тест | Темт | Тест	Тест	\N	2026-06-14 05:22:49.700514+00	2026-06-14 21:22:49.700514+00	2026-06-16 21:22:49.700514+00	\N	0	f	f	f	\N	\N	2026-06-13 21:22:49.702355+00	2026-06-13 21:22:49.702359+00	\N	t
82583a1e-a2be-4a0b-bf3c-3b0034f372fa	TKT-000001	a0000000-0000-0000-0000-000000000001	a0000000-0000-0000-0000-000000000002	\N	INCIDENT	HIGH	NEW	Камера не працює	\N	\N	2026-06-13 16:30:17.139753+00	2026-06-13 22:30:17.139753+00	2026-06-14 14:30:17.139753+00	\N	0	t	t	f	\N	\N	2026-06-13 14:30:17.149144+00	2026-06-13 22:30:50.331783+00	\N	t
1c62b9c6-ae42-408a-b744-0c248660bc6e	TKT-000002	a0000000-0000-0000-0000-000000000001	a0000000-0000-0000-0000-000000000002	\N	INCIDENT	MEDIUM	NEW	Test bot command	\N	\N	2026-06-13 23:16:33.292153+00	2026-06-14 15:16:33.292153+00	2026-06-16 15:16:33.292153+00	\N	0	t	f	f	\N	\N	2026-06-13 15:16:33.294106+00	2026-06-13 23:16:47.573897+00	\N	t
23912ac3-1723-43e5-87b7-46db4c0c0a78	TKT-000003	a0000000-0000-0000-0000-000000000001	a0000000-0000-0000-0000-000000000002	\N	SERVICE_REQUEST	MEDIUM	ACCEPTED	Магазин Хороший	\N	\N	2026-06-13 23:23:54.392809+00	2026-06-14 15:23:54.392809+00	2026-06-16 15:23:54.392809+00	\N	0	t	f	f	\N	\N	2026-06-13 15:23:54.400779+00	2026-06-13 23:24:47.507971+00	\N	t
c08aa147-6fa8-4120-8fd8-86629891112a	TKT-000004	a0000000-0000-0000-0000-000000000001	a0000000-0000-0000-0000-000000000002	\N	SERVICE_REQUEST	HIGH	NEW	Хороший | Українська 21 | Ірина +0988955555	Новий монтаж, 5 камер	\N	2026-06-13 17:32:15.381924+00	2026-06-13 23:32:15.381924+00	2026-06-14 15:32:15.381924+00	\N	0	t	t	f	\N	\N	2026-06-13 15:32:15.383768+00	2026-06-13 23:32:47.492194+00	\N	t
d40082fd-15ea-4380-bd87-faa136cccd31	TKT-000007	a0000000-0000-0000-0000-000000000001	a0000000-0000-0000-0000-000000000002	\N	INCIDENT	CRITICAL	NEW	Тест n8n webhook	\N	\N	2026-06-13 23:33:20.424943+00	2026-06-14 01:03:20.424943+00	2026-06-14 07:03:20.424943+00	\N	0	t	f	f	\N	\N	2026-06-13 23:03:20.462755+00	2026-06-13 23:33:47.496515+00	\N	t
5b868be3-7647-4dd1-8435-74730179b678	TKT-000011	a0000000-0000-0000-0000-000000000001	a0000000-0000-0000-0000-000000000002	\N	INCIDENT	CRITICAL	NEW	Тест з логуванням	\N	\N	2026-06-14 00:28:19.987793+00	2026-06-14 01:58:19.987793+00	2026-06-14 07:58:19.987793+00	\N	0	f	f	f	\N	\N	2026-06-13 23:58:20.014029+00	2026-06-13 23:58:20.014034+00	\N	t
40bf7d91-61db-4ebb-97b8-510f20fa4bfe	TKT-000012	a0000000-0000-0000-0000-000000000001	a0000000-0000-0000-0000-000000000002	\N	INCIDENT	CRITICAL	NEW	Debug test	\N	\N	2026-06-14 00:41:09.668315+00	2026-06-14 02:11:09.668315+00	2026-06-14 08:11:09.668315+00	\N	0	f	f	f	\N	\N	2026-06-14 00:11:09.675937+00	2026-06-14 00:11:09.675943+00	\N	t
2a8a0f81-20e6-4966-9285-6ac87647ec61	TKT-000006	a0000000-0000-0000-0000-000000000001	a0000000-0000-0000-0000-000000000002	\N	SERVICE_REQUEST	MEDIUM	ACCEPTED	1 | Й | Й	Й	\N	2026-06-14 06:08:44.161914+00	2026-06-14 22:08:44.161914+00	2026-06-16 22:08:44.161914+00	\N	0	f	f	f	\N	\N	2026-06-13 22:08:44.164394+00	2026-06-14 00:13:44.838146+00	\N	t
432c2b9a-386f-4cbb-a052-36ab2554ea69	TKT-000008	a0000000-0000-0000-0000-000000000001	a0000000-0000-0000-0000-000000000002	\N	INCIDENT	HIGH	ACCEPTED	Тест нотифікації	\N	\N	2026-06-14 01:54:30.737925+00	2026-06-14 07:54:30.737925+00	2026-06-14 23:54:30.737925+00	\N	0	f	f	f	\N	\N	2026-06-13 23:54:30.763527+00	2026-06-14 00:13:58.870825+00	\N	t
010dd8c4-6a70-41fb-ab87-1475e31fb0de	TKT-000009	a0000000-0000-0000-0000-000000000001	a0000000-0000-0000-0000-000000000002	\N	INCIDENT	CRITICAL	ACCEPTED	Повний тест нотифікації	\N	\N	2026-06-14 00:26:35.924179+00	2026-06-14 01:56:35.924179+00	2026-06-14 07:56:35.924179+00	\N	0	f	f	f	\N	\N	2026-06-13 23:56:35.926139+00	2026-06-14 00:14:03.377213+00	\N	t
c77e1f5e-4a28-45ca-99ae-b821aaa09992	TKT-000010	a0000000-0000-0000-0000-000000000001	a0000000-0000-0000-0000-000000000002	\N	INCIDENT	CRITICAL	ACCEPTED	Фінальний тест	\N	\N	2026-06-14 00:27:21.030874+00	2026-06-14 01:57:21.030874+00	2026-06-14 07:57:21.030874+00	\N	0	f	f	f	\N	\N	2026-06-13 23:57:21.109393+00	2026-06-14 00:14:06.474034+00	\N	t
\.


--
-- Data for Name: visit_materials; Type: TABLE DATA; Schema: fsm; Owner: fsm_user
--

COPY fsm.visit_materials (id, visit_id, item_code, item_name, serial_number, quantity, uom, created_at, created_by) FROM stdin;
d91b690b-ef7a-435c-90be-c97895d9f2ef	1ba8fa30-4fa6-4cc3-a092-4710fcbc76f7	Кабель UTP Cat6	Кабель UTP Cat6	\N	1	pcs	2026-06-14 00:13:01.487179+00	\N
\.


--
-- Data for Name: visit_photos; Type: TABLE DATA; Schema: fsm; Owner: fsm_user
--

COPY fsm.visit_photos (id, visit_id, photo_type, file_id, file_path, caption, gps_lat, gps_lon, created_at, created_by) FROM stdin;
\.


--
-- Data for Name: visits; Type: TABLE DATA; Schema: fsm; Owner: fsm_user
--

COPY fsm.visits (id, visit_number, ticket_id, engineer_id, status, planned_start, actual_start, actual_finish, gps_checkin_lat, gps_checkin_lon, gps_checkout_lat, gps_checkout_lon, travel_minutes, work_minutes, notes, customer_signature_file, created_at, updated_at, created_by, is_active) FROM stdin;
f3e5a4b5-d8e2-4d65-97c6-4e28f5bceda1	VIS-000001	1c62b9c6-ae42-408a-b744-0c248660bc6e	a0000000-0000-0000-0000-000000000001	COMPLETED	\N	2026-06-13 15:16:33.391671+00	2026-06-13 15:16:33.426547+00	50.45	30.52	50.45	30.52	\N	0	\N	\N	2026-06-13 15:16:33.335668+00	2026-06-13 15:16:33.426547+00	\N	t
fd8c10cd-fd2d-4f9d-ad55-e733fac03142	VIS-000002	82583a1e-a2be-4a0b-bf3c-3b0034f372fa	a0000000-0000-0000-0000-000000000001	COMPLETED	\N	2026-06-13 22:35:15.149633+00	2026-06-13 22:35:54.34105+00	0	0	0	0	\N	0	\N	\N	2026-06-13 22:35:12.160978+00	2026-06-13 22:35:54.34105+00	\N	t
3f424ada-c639-4e6c-89d5-94a851dceafe	VIS-000004	82583a1e-a2be-4a0b-bf3c-3b0034f372fa	a0000000-0000-0000-0000-000000000001	COMPLETED	\N	2026-06-14 00:12:11.201887+00	2026-06-14 00:12:13.48044+00	0	0	0	0	\N	0	\N	\N	2026-06-14 00:12:09.491149+00	2026-06-14 00:12:13.48044+00	\N	t
a7c7033b-bfc8-4fc9-b67f-d057f8b8905a	VIS-000003	c08aa147-6fa8-4120-8fd8-86629891112a	a0000000-0000-0000-0000-000000000001	COMPLETED	\N	2026-06-13 22:36:05.182644+00	2026-06-14 00:12:24.386156+00	0	0	0	0	\N	96	\N	\N	2026-06-13 22:36:02.726346+00	2026-06-14 00:12:24.386156+00	\N	t
1ba8fa30-4fa6-4cc3-a092-4710fcbc76f7	VIS-000005	23912ac3-1723-43e5-87b7-46db4c0c0a78	a0000000-0000-0000-0000-000000000001	COMPLETED	\N	2026-06-14 00:12:44.913776+00	2026-06-14 00:13:39.96824+00	0	0	0	0	\N	0	\N	\N	2026-06-14 00:12:41.347505+00	2026-06-14 00:13:39.96824+00	\N	t
a99a78f9-f9c6-4dad-8beb-a932e69dc35f	VIS-000006	d40082fd-15ea-4380-bd87-faa136cccd31	a0000000-0000-0000-0000-000000000001	COMPLETED	\N	2026-06-14 00:13:47.684752+00	2026-06-14 00:13:49.628246+00	0	0	0	0	\N	0	\N	\N	2026-06-14 00:13:46.600287+00	2026-06-14 00:13:49.628246+00	\N	t
1e3f75a7-423f-4db0-9e7c-13f96b96151c	VIS-000007	5b868be3-7647-4dd1-8435-74730179b678	a0000000-0000-0000-0000-000000000001	COMPLETED	\N	2026-06-14 00:14:12.343544+00	2026-06-14 00:14:19.106019+00	0	0	0	0	\N	0	\N	\N	2026-06-14 00:14:10.480424+00	2026-06-14 00:14:19.106019+00	\N	t
\.


--
-- Data for Name: warranty_cases; Type: TABLE DATA; Schema: fsm; Owner: fsm_user
--

COPY fsm.warranty_cases (id, case_number, ticket_id, equipment_id, customer_id, description, status, resolution, manufacturer_claim, created_at, updated_at, created_by) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: integration; Owner: postgres
--

COPY integration.users (id, email, username, full_name, hashed_password, role, employee_id, is_active, mfa_enabled, mfa_secret, last_login, failed_login_attempts, locked_until, created_at, updated_at) FROM stdin;
6981c22c-3a2b-4575-b403-132d1f083d0e	director@security-erp.local	director	Операційний Директор	$2b$12$FXzX9ITs3wilmmlioQOpp.gPvuq6gKDXMeiBP7FB2D2oeT4GEG/6e	director	\N	t	f	\N	2026-06-13 15:54:19.966363+00	0	\N	2026-06-13 15:52:56.729468+00	2026-06-13 15:54:19.968362+00
e054174f-5d8e-405e-8330-f0e468d28a24	sales@security-erp.local	sales	Менеджер з Продажу	$2b$12$wAaxBq3AS2sLIVikKLmJruVdVF5KhDZbPGIEDHrKLHck/o6dVxfJy	sales_manager	\N	t	f	\N	2026-06-13 15:54:20.37594+00	0	\N	2026-06-13 15:52:57.067815+00	2026-06-13 15:54:20.376376+00
f473f7af-fc50-4846-9a36-b9fcaa65799f	pm@security-erp.local	pm	Проєктний Менеджер	$2b$12$YXChBU7Hg5xD7FwDnBAH5u4LFP3HOE5PwXHfzCQjkB2PftnFynbwm	project_manager	\N	t	f	\N	2026-06-13 15:54:20.694929+00	0	\N	2026-06-13 15:52:57.429666+00	2026-06-13 15:54:20.695366+00
08380c18-1bbb-404e-af80-f7a609306586	service@security-erp.local	service	Сервіс Менеджер	$2b$12$wWFwtcTZS8YL4aMT4TWld.0ia9pZk7KniNNadJb7bA5YMPXbgT2HC	service_manager	\N	t	f	\N	2026-06-13 15:54:21.082053+00	0	\N	2026-06-13 15:52:57.761486+00	2026-06-13 15:54:21.08254+00
eed2fd00-b6af-433b-ac29-d6ccbcfe219d	engineer1@security-erp.local	engineer1	Інженер Петренко	$2b$12$ZFHj1oMNbt2Q0gW8m/A6WORU8wvdCBagOEtCBZ.vny/CeGvbqtRt.	engineer	\N	t	f	\N	2026-06-13 15:54:21.484691+00	0	\N	2026-06-13 15:52:58.11416+00	2026-06-13 15:54:21.485064+00
9d9fb4a9-295d-412c-ae99-59eeca524d20	warehouse@security-erp.local	warehouse	Комірник	$2b$12$.26I9lBP6MaQSpzcnWM.qu3Peu6fUR/hwVTPDECjw8ihpGc55zW2W	warehouse	\N	t	f	\N	2026-06-13 15:54:21.885559+00	0	\N	2026-06-13 15:52:58.805284+00	2026-06-13 15:54:21.886003+00
8e08da85-6e17-4f22-a0a1-52517b14c9ba	accountant@security-erp.local	accountant	Бухгалтер	$2b$12$6LnGbj8vxaSMiDrmHHmdnOrVVLBQibZpCljxZyfqXvI/jv5IstHhO	accountant	\N	t	f	\N	2026-06-13 15:54:22.25846+00	0	\N	2026-06-13 15:52:59.14579+00	2026-06-13 15:54:22.258823+00
4a23de1c-515c-4e99-9d8e-77ceb3de7d3e	viewer@security-erp.local	viewer	Переглядач	$2b$12$t9ZKRA5.4jcOE30sb6rekOZtkJGJXmO47EMFgZgcjYXqFbar7ct7q	viewer	\N	t	f	\N	2026-06-13 15:54:22.61215+00	0	\N	2026-06-13 15:52:59.495069+00	2026-06-13 15:54:22.612599+00
e4e5b2f6-471e-4a1e-b476-f9da8fb2fa50	engineer2@security-erp.local	engineer2	Інженер Коваленко	$2b$12$OoAgw9Hn7bIcjFc6PYiLE.FYGONoZXyQGlZmejm0RLaO//nPCGHxC	engineer	\N	t	f	\N	\N	0	\N	2026-06-13 15:52:58.443819+00	2026-06-13 15:52:58.443825+00
a0000000-0000-0000-0000-000000000001	admin@security-erp.local	joker	System Administrator	$2b$12$lUlcgN/0wXJ19slyE25bF.Pei8wn7e0L3AmFloLhXOAdIQtKpZtDy	owner	\N	t	\N	\N	2026-06-14 00:22:18.329031+00	0	\N	2026-06-13 14:23:50.449073+00	2026-06-14 00:22:18.32953+00
\.


--
-- Data for Name: agent_checkpoints; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.agent_checkpoints ("runId", "agentId", state, expired, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agent_execution; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.agent_execution (id, "threadId", status, "startedAt", "stoppedAt", duration, "userMessage", "assistantResponse", model, "promptTokens", "completionTokens", "totalTokens", cost, "toolCalls", timeline, error, "hitlStatus", source, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agent_execution_threads; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.agent_execution_threads (id, "agentId", "agentName", "projectId", "sessionNumber", "totalPromptTokens", "totalCompletionTokens", "totalCost", "totalDuration", title, emoji, "createdAt", "updatedAt", "taskId", "taskVersionId") FROM stdin;
\.


--
-- Data for Name: agent_files; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.agent_files (id, "agentId", "binaryDataId", "fileName", "mimeType", "fileSizeBytes", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agent_history; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.agent_history ("versionId", "agentId", schema, tools, skills, "publishedById", author, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agent_task_definition; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.agent_task_definition (id, "agentId", name, objective, "cronExpression", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agent_task_run_lock; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.agent_task_run_lock ("agentId", "taskId", "holderId", "heldUntil", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agent_task_snapshot; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.agent_task_snapshot ("versionId", "taskId", enabled, name, objective, "cronExpression", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agents; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.agents (id, name, description, "projectId", integrations, schema, tools, skills, "versionId", "createdAt", "updatedAt", "activeVersionId") FROM stdin;
\.


--
-- Data for Name: agents_memory_entries; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.agents_memory_entries (id, "agentId", "resourceId", content, "contentHash", status, "supersededBy", "embeddingModel", embedding, metadata, "lastSeenAt", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agents_memory_entry_cursors; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.agents_memory_entry_cursors ("agentId", "observationScopeId", "lastIndexedObservationId", "lastIndexedObservationCreatedAt", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agents_memory_entry_locks; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.agents_memory_entry_locks ("agentId", "resourceId", "holderId", "heldUntil", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agents_memory_entry_sources; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.agents_memory_entry_sources (id, "agentId", "memoryEntryId", "observationId", "threadId", "evidenceHash", "evidenceText", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agents_messages; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.agents_messages (id, "threadId", "resourceId", role, type, content, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agents_observation_cursors; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.agents_observation_cursors ("agentId", "observationScopeId", "lastObservedMessageId", "lastObservedAt", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agents_observation_locks; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.agents_observation_locks ("agentId", "observationScopeId", "taskKind", "holderId", "heldUntil", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agents_observations; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.agents_observations (id, "agentId", "observationScopeId", marker, text, "parentId", "tokenCount", status, "supersededBy", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agents_resources; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.agents_resources (id, metadata, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agents_threads; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.agents_threads (id, "resourceId", title, metadata, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: ai_builder_temporary_workflow; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.ai_builder_temporary_workflow ("workflowId", "threadId", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: annotation_tag_entity; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.annotation_tag_entity (id, name, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: auth_identity; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.auth_identity ("userId", "providerId", "providerType", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: auth_provider_sync_history; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.auth_provider_sync_history (id, "providerType", "runMode", status, "startedAt", "endedAt", scanned, created, updated, disabled, error) FROM stdin;
\.


--
-- Data for Name: binary_data; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.binary_data ("fileId", "sourceType", "sourceId", data, "mimeType", "fileName", "fileSize", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: chat_hub_agent_tools; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.chat_hub_agent_tools ("agentId", "toolId") FROM stdin;
\.


--
-- Data for Name: chat_hub_agents; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.chat_hub_agents (id, name, description, "systemPrompt", "ownerId", "credentialId", provider, model, "createdAt", "updatedAt", icon, files, "suggestedPrompts") FROM stdin;
\.


--
-- Data for Name: chat_hub_messages; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.chat_hub_messages (id, "sessionId", "previousMessageId", "revisionOfMessageId", "retryOfMessageId", type, name, content, provider, model, "workflowId", "executionId", "createdAt", "updatedAt", "agentId", status, attachments) FROM stdin;
\.


--
-- Data for Name: chat_hub_session_tools; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.chat_hub_session_tools ("sessionId", "toolId") FROM stdin;
\.


--
-- Data for Name: chat_hub_sessions; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.chat_hub_sessions (id, title, "ownerId", "lastMessageAt", "credentialId", provider, model, "workflowId", "createdAt", "updatedAt", "agentId", "agentName", type) FROM stdin;
\.


--
-- Data for Name: chat_hub_tools; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.chat_hub_tools (id, name, type, "typeVersion", "ownerId", definition, enabled, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: credential_dependency; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.credential_dependency (id, "credentialId", "dependencyType", "dependencyId", "createdAt") FROM stdin;
\.


--
-- Data for Name: credentials_entity; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.credentials_entity (name, data, type, "createdAt", "updatedAt", id, "isManaged", "isGlobal", "isResolvable", "resolvableAllowFallback", "resolverId") FROM stdin;
\.


--
-- Data for Name: data_table; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.data_table (id, name, "projectId", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: data_table_column; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.data_table_column (id, name, type, index, "dataTableId", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: deployment_key; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.deployment_key (id, type, value, algorithm, status, "createdAt", "updatedAt") FROM stdin;
ge5Oq7SwCJ5uL8Rf	instance.id	05129d2bdd4cf6664cb10b1bd5cf77221e5d43d51b8c2d2cad46e245a607a7d0	\N	active	2026-06-13 14:21:43.421+00	2026-06-13 14:21:43.421+00
SqlFs7KMdszUxomX	signing.hmac	a6a3ef2d5b13f779e51aa3411196118546ccdec3fcaeb23eda344a68ceec9fa6	\N	active	2026-06-13 14:21:43.46+00	2026-06-13 14:21:43.46+00
i9RkeuI5twswF5xx	signing.jwt	5b6c4993acd5c558f325b6a388840405b51cee278e1b780e5b7a3ab8e3775592	\N	active	2026-06-13 14:21:43.475+00	2026-06-13 14:21:43.475+00
rapt1AuMgYuqk7hL	signing.binary_data	/rviE+3IyY1VPZIDYCO1M93p417S+g+Nk2MPmhXmW7A=	\N	active	2026-06-13 14:21:43.484+00	2026-06-13 14:21:43.484+00
\.


--
-- Data for Name: dynamic_credential_entry; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.dynamic_credential_entry (credential_id, subject_id, resolver_id, data, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: dynamic_credential_resolver; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.dynamic_credential_resolver (id, name, type, config, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: dynamic_credential_user_entry; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.dynamic_credential_user_entry ("credentialId", "userId", "resolverId", data, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: evaluation_collection; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.evaluation_collection (id, name, description, "workflowId", "evaluationConfigId", "createdById", "insightsCache", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: evaluation_config; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.evaluation_config (id, "workflowId", name, status, "invalidReason", "datasetSource", "datasetRef", "startNodeName", "endNodeName", metrics, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: event_destinations; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.event_destinations (id, destination, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: execution_annotation_tags; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.execution_annotation_tags ("annotationId", "tagId") FROM stdin;
\.


--
-- Data for Name: execution_annotations; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.execution_annotations (id, "executionId", vote, note, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: execution_data; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.execution_data ("executionId", "workflowData", data, "workflowVersionId") FROM stdin;
34	{"id":"EEp4uU0yD27l6PaH","name":"WF-03: Нова заявка","active":true,"activeVersionId":"16bee57f-3623-4784-b59d-c9d03ff65a48","isArchived":false,"createdAt":"2026-06-14T00:22:27.528Z","updatedAt":"2026-06-14T00:22:27.528Z","nodes":[{"parameters":{"multipleMethods":false,"httpMethod":"POST","path":"new-ticket","authentication":"none","responseMode":"onReceived","responseCode":200,"contentTypeNotice":"","options":{}},"name":"Webhook","type":"n8n-nodes-base.webhook","typeVersion":1,"position":[250,300],"id":"694b9c98-d55c-4f81-ba2b-7eb6979e0f8a","webhookId":"8e2e3da5-6a55-4b2e-93c4-22f58f259544"},{"parameters":{"curlImport":"","method":"POST","url":"https://api.telegram.org/bot8718935753:AAFX_Jbc_wkQ6MSHX1p5SkU0NEFkPSWB7HY/sendMessage","authentication":"none","provideSslCertificates":false,"sendQuery":false,"sendHeaders":false,"sendBody":true,"contentType":"json","specifyBody":"keypair","bodyParameters":{"parameters":[{"name":"chat_id","value":"291657218"},{"name":"text","value":"📋 Нова заявка\\n\\n{{ $json.body.ticket_number }}: {{ $json.body.title }}\\nПріоритет: {{ $json.body.priority }}"}]},"options":{},"infoMessage":""},"name":"Send Telegram","type":"n8n-nodes-base.httpRequest","typeVersion":4,"position":[500,300],"id":"7e6b7873-c237-46db-bfd2-d381027262f7"}],"connections":{"Webhook":{"main":[[{"node":"Send Telegram","type":"main","index":0}]]}},"settings":null,"staticData":{},"pinData":null}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{},{"runData":"5","lastNodeExecuted":"6"},{"contextData":"7","nodeExecutionStack":"8","metadata":"9","waitingExecution":"10","waitingExecutionSource":"11","runtimeData":"12"},"614a5e11c2e85ba739a37a2def28100b7f70ba3ad7c1ba6a5dfc451583df411a",{"Webhook":"13","Send Telegram":"14"},"Send Telegram",{},[],{},{},{},{"version":1,"establishedAt":1781396553497,"source":"15","triggerNode":"16","redaction":"17"},["18"],["19"],"webhook",{"name":"20","type":"21"},{"version":1,"policy":"22"},{"startTime":1781396553579,"executionIndex":0,"source":"23","hints":"24","executionTime":4,"executionStatus":"25","data":"26"},{"startTime":1781396553585,"executionIndex":1,"source":"27","hints":"28","executionTime":258,"executionStatus":"25","data":"29"},"Webhook","n8n-nodes-base.webhook","none",[],[],"success",{"main":"30"},["31"],[],{"main":"32"},["33"],{"previousNode":"20","previousNodeOutput":0,"previousNodeRun":0},["34"],["35"],["36"],{"json":"37","pairedItem":"38"},{"json":"39","pairedItem":"40"},{"headers":"41","params":"42","query":"43","body":"44","webhookUrl":"45","executionMode":"46"},{"item":0},{"ok":true,"result":"47"},{"item":0},{"host":"48","user-agent":"49","accept":"50","content-type":"51","content-length":"52"},{},{},{"ticket_number":"53","title":"54","priority":"55"},"http://localhost:5678/webhook/new-ticket","production",{"message_id":237,"from":"56","chat":"57","date":1781396554,"text":"58"},"localhost:5678","curl/8.5.0","*/*","application/json","64","TKT-001","Test n8n","high",{"id":8718935753,"is_bot":true,"first_name":"59","username":"60"},{"id":291657218,"first_name":"61","last_name":"62","username":"63","type":"64"},"📋 Нова заявка\\n\\n{{ $json.body.ticket_number }}: {{ $json.body.title }}\\nПріоритет: {{ $json.body.priority }}","RIADbot","riad_ss_bot","Антон ꑭ","Кравченко","Joker_U_A","private"]	16bee57f-3623-4784-b59d-c9d03ff65a48
\.


--
-- Data for Name: execution_entity; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.execution_entity (id, finished, mode, "retryOf", "retrySuccessId", "startedAt", "stoppedAt", "waitTill", status, "workflowId", "deletedAt", "createdAt", "storedAt", "tracingContext", "deduplicationKey") FROM stdin;
34	t	webhook	\N	\N	2026-06-14 00:22:33.538+00	2026-06-14 00:22:33.844+00	\N	success	EEp4uU0yD27l6PaH	\N	2026-06-14 00:22:33.499+00	db	\N	\N
\.


--
-- Data for Name: execution_metadata; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.execution_metadata (id, "executionId", key, value) FROM stdin;
\.


--
-- Data for Name: folder; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.folder (id, name, "parentFolderId", "projectId", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: folder_tag; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.folder_tag ("folderId", "tagId") FROM stdin;
\.


--
-- Data for Name: insights_by_period; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.insights_by_period (id, "metaId", type, value, "periodUnit", "periodStart") FROM stdin;
\.


--
-- Data for Name: insights_metadata; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.insights_metadata ("metaId", "workflowId", "projectId", "workflowName", "projectName") FROM stdin;
1	\N	C56wJya6tXcF5Glv	WF-01: Новий Lead	Кравченко Антон <jokerla23@gmail.com>
2	\N	C56wJya6tXcF5Glv	WF-03: Нова заявка	Кравченко Антон <jokerla23@gmail.com>
4	\N	C56wJya6tXcF5Glv	WF-01: Новий Lead (API)	Кравченко Антон <jokerla23@gmail.com>
5	\N	C56wJya6tXcF5Glv	WF-01: Новий Lead	Кравченко Антон <jokerla23@gmail.com>
6	\N	C56wJya6tXcF5Glv	WF-03: Нова заявка	Кравченко Антон <jokerla23@gmail.com>
7	\N	C56wJya6tXcF5Glv	WF-05: Emergency	Кравченко Антон <jokerla23@gmail.com>
9	\N	C56wJya6tXcF5Glv	WF-03: Нова заявка	Кравченко Антон <jokerla23@gmail.com>
8	\N	C56wJya6tXcF5Glv	WF-01: Новий Lead	Кравченко Антон <jokerla23@gmail.com>
13	\N	C56wJya6tXcF5Glv	WF-01: Новий Lead	Кравченко Антон <jokerla23@gmail.com>
11	\N	C56wJya6tXcF5Glv	WF-05: Emergency	Кравченко Антон <jokerla23@gmail.com>
12	\N	C56wJya6tXcF5Glv	WF-03: Нова заявка	Кравченко Антон <jokerla23@gmail.com>
18	\N	C56wJya6tXcF5Glv	WF-03: Нова заявка	Кравченко Антон <jokerla23@gmail.com>
21	\N	C56wJya6tXcF5Glv	WF-04: SLA Breach	Кравченко Антон <jokerla23@gmail.com>
22	\N	C56wJya6tXcF5Glv	Test Telegram	Кравченко Антон <jokerla23@gmail.com>
23	\N	C56wJya6tXcF5Glv	WF-03: Нова заявка	Кравченко Антон <jokerla23@gmail.com>
24	\N	C56wJya6tXcF5Glv	Test Ticket	Кравченко Антон <jokerla23@gmail.com>
26	\N	C56wJya6tXcF5Glv	Test Ticket	Кравченко Антон <jokerla23@gmail.com>
27	EEp4uU0yD27l6PaH	C56wJya6tXcF5Glv	WF-03: Нова заявка	Кравченко Антон <jokerla23@gmail.com>
\.


--
-- Data for Name: insights_raw; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.insights_raw (id, "metaId", type, value, "timestamp") FROM stdin;
1	1	2	1	2026-06-13 21:20:39+00
2	1	1	78	2026-06-13 21:20:39+00
3	1	0	0	2026-06-13 21:20:39+00
4	2	2	1	2026-06-13 21:20:39+00
5	2	1	18	2026-06-13 21:20:39+00
6	2	0	0	2026-06-13 21:20:39+00
7	1	3	1	2026-06-13 21:31:35+00
8	1	1	151	2026-06-13 21:31:35+00
9	4	3	1	2026-06-13 22:05:20+00
10	4	1	605	2026-06-13 22:05:20+00
11	5	3	1	2026-06-13 22:05:54+00
12	5	1	216	2026-06-13 22:05:54+00
13	6	3	1	2026-06-13 22:05:54+00
14	6	1	166	2026-06-13 22:05:54+00
15	7	3	1	2026-06-13 22:05:54+00
16	7	1	159	2026-06-13 22:05:54+00
17	5	3	1	2026-06-13 22:38:53+00
18	5	1	203	2026-06-13 22:38:53+00
19	6	3	1	2026-06-13 22:38:53+00
20	6	1	165	2026-06-13 22:38:53+00
21	6	3	1	2026-06-13 22:38:53+00
22	6	1	160	2026-06-13 22:38:53+00
23	7	3	1	2026-06-13 22:38:53+00
24	7	1	161	2026-06-13 22:38:53+00
25	8	3	1	2026-06-13 22:42:23+00
26	8	1	399	2026-06-13 22:42:23+00
27	9	3	1	2026-06-13 23:03:21+00
28	9	1	49	2026-06-13 23:03:21+00
29	9	3	1	2026-06-13 23:05:36+00
30	9	1	65	2026-06-13 23:05:36+00
31	9	3	1	2026-06-13 23:06:08+00
32	9	1	11	2026-06-13 23:06:08+00
33	13	3	1	2026-06-13 23:07:22+00
34	13	1	317	2026-06-13 23:07:22+00
35	12	3	1	2026-06-13 23:07:22+00
36	12	1	284	2026-06-13 23:07:22+00
37	11	3	1	2026-06-13 23:07:22+00
38	11	1	288	2026-06-13 23:07:22+00
39	12	3	1	2026-06-13 23:08:26+00
40	12	1	485	2026-06-13 23:08:26+00
41	12	3	1	2026-06-13 23:09:29+00
42	12	1	342	2026-06-13 23:09:29+00
43	12	3	1	2026-06-13 23:10:46+00
44	12	1	72	2026-06-13 23:10:46+00
45	12	3	1	2026-06-13 23:11:58+00
46	12	1	76	2026-06-13 23:11:58+00
47	18	3	1	2026-06-13 23:13:18+00
48	18	1	342	2026-06-13 23:13:18+00
49	18	3	1	2026-06-13 23:14:40+00
50	18	1	390	2026-06-13 23:14:40+00
51	18	3	1	2026-06-13 23:16:23+00
52	18	1	715	2026-06-13 23:16:23+00
53	21	3	1	2026-06-13 23:16:48+00
54	21	1	174	2026-06-13 23:16:48+00
55	21	3	1	2026-06-13 23:16:48+00
56	21	1	150	2026-06-13 23:16:48+00
57	22	3	1	2026-06-13 23:18:00+00
58	22	1	399	2026-06-13 23:18:00+00
59	22	2	1	2026-06-13 23:21:32+00
60	22	1	243	2026-06-13 23:21:32+00
61	22	0	0	2026-06-13 23:21:32+00
62	23	3	1	2026-06-13 23:22:13+00
63	23	1	177	2026-06-13 23:22:13+00
64	24	3	1	2026-06-13 23:24:41+00
65	24	1	358	2026-06-13 23:24:41+00
66	24	3	1	2026-06-13 23:26:07+00
67	24	1	455	2026-06-13 23:26:07+00
68	26	3	1	2026-06-13 23:27:17+00
69	26	1	343	2026-06-13 23:27:17+00
70	27	2	1	2026-06-14 00:22:34+00
71	27	1	273	2026-06-14 00:22:34+00
72	27	0	0	2026-06-14 00:22:34+00
\.


--
-- Data for Name: installed_nodes; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.installed_nodes (name, type, "latestVersion", package) FROM stdin;
\.


--
-- Data for Name: installed_packages; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.installed_packages ("packageName", "installedVersion", "authorName", "authorEmail", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_checkpoints; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.instance_ai_checkpoints (key, "runId", "threadId", "resourceId", state, "createdAt", "updatedAt", "expiredAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_iteration_logs; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.instance_ai_iteration_logs (id, "threadId", "taskKey", entry, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_messages; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.instance_ai_messages (id, "threadId", content, role, type, "resourceId", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_observation_cursors; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.instance_ai_observation_cursors ("observationScopeId", "lastObservedMessageId", "lastObservedAt", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_observation_locks; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.instance_ai_observation_locks ("observationScopeId", "taskKind", "holderId", "heldUntil", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_observational_memory; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.instance_ai_observational_memory (id, "lookupKey", scope, "threadId", "resourceId", "activeObservations", "originType", config, "generationCount", "lastObservedAt", "pendingMessageTokens", "totalTokensObserved", "observationTokenCount", "isObserving", "isReflecting", "observedMessageIds", "observedTimezone", "bufferedObservations", "bufferedObservationTokens", "bufferedMessageIds", "bufferedReflection", "bufferedReflectionTokens", "bufferedReflectionInputTokens", "reflectedObservationLineCount", "bufferedObservationChunks", "isBufferingObservation", "isBufferingReflection", "lastBufferedAtTokens", "lastBufferedAtTime", metadata, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_observations; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.instance_ai_observations (id, "observationScopeId", marker, text, "parentId", "tokenCount", status, "supersededBy", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_pending_confirmations; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.instance_ai_pending_confirmations ("requestId", "threadId", "userId", kind, "runId", "toolCallId", "messageGroupId", "checkpointKey", "checkpointTaskId", "expiresAt", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_resources; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.instance_ai_resources (id, "workingMemory", metadata, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_run_snapshots; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.instance_ai_run_snapshots ("threadId", "runId", "messageGroupId", "runIds", tree, "createdAt", "updatedAt", "langsmithRunId", "langsmithTraceId", "traceId", "spanId") FROM stdin;
\.


--
-- Data for Name: instance_ai_threads; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.instance_ai_threads (id, "resourceId", title, metadata, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_workflow_snapshots; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.instance_ai_workflow_snapshots ("runId", "workflowName", "resourceId", status, snapshot, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_version_history; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.instance_version_history (id, major, minor, patch, "createdAt") FROM stdin;
1	2	25	7	2026-06-13 14:21:51.501+00
\.


--
-- Data for Name: invalid_auth_token; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.invalid_auth_token (token, "expiresAt") FROM stdin;
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjBmYTEwZDkwLTllNmQtNDhiYi05M2M4LWFmM2YyMGM1ZjBiNSIsImhhc2giOiJKeVc4Y3NQbFZzIiwiYnJvd3NlcklkIjoibmMxSzFYUnZDdWtHR3ZVUjNqclpVZWJNZ3UzUkZTY3hTTEE2QzZDMTJtaz0iLCJ1c2VkTWZhIjpmYWxzZSwiaWF0IjoxNzgxMzc0NTM2LCJleHAiOjE3ODE5NzkzMzZ9.vsBMnPaNS0t0bCt7HgG9kVwJATYmRN5-4sr87RbOKPU	2026-06-20 18:15:36+00
\.


--
-- Data for Name: mcp_registry_server; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.mcp_registry_server (slug, status, version, "registryUpdatedAt", data, "createdAt", "updatedAt") FROM stdin;
linear	active	1.0.0	2026-06-11 12:28:04.979	{"id":7,"name":"app.linear/linear","title":"Linear","tagline":"Connect to the Linear MCP Server","description":"MCP server for Linear project management and issue tracking","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:50:22.156Z","icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_P3_K9_Q_jj_6b6c66c6c7.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_P3_K9_Q_jj_7d409a8856.svg","mimeType":"image/svg+xml","theme":"light"}],"remotes":[{"id":11,"type":"sse","url":"https://mcp.linear.app/sse"},{"id":10,"type":"streamable-http","url":"https://mcp.linear.app/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null}	2026-06-13 14:21:53.388+00	2026-06-13 14:21:53.388+00
axiom	active	1.0.0	2026-06-11 12:28:11.99	{"id":17,"name":"co.axiom/mcp","title":"Axiom","tagline":"Connect to the Axiom MCP Server","description":"List datasets, schemas, run APL queries, and use prompts for exploration, anomalies, and monitoring.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:52:18.335Z","icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Xjr_Dncs4_d8a390ab33.jpeg","mimeType":"image/jpeg","theme":"light"}],"remotes":[{"id":30,"type":"sse","url":"https://mcp.axiom.co/sse"},{"id":29,"type":"streamable-http","url":"https://mcp.axiom.co/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null}	2026-06-13 14:21:53.388+00	2026-06-13 14:21:53.388+00
hugging-face	active	0.2.33	2026-06-11 12:28:18.177	{"id":18,"name":"co.huggingface/hf-mcp-server","title":"Hugging Face","tagline":"Connect to the Hugging Face MCP Server","description":"Connect to Hugging Face Hub and thousands of Gradio AI Applications","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:52:30.024Z","icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_S6h_Od6z2_c35cc34669.jpeg","mimeType":"image/jpeg","theme":"light"}],"remotes":[{"id":32,"type":"streamable-http","url":"https://huggingface.co/mcp?login"},{"id":31,"type":"streamable-http","url":"https://huggingface.co/mcp"},{"id":33,"type":"streamable-http","url":"https://huggingface.co/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null}	2026-06-13 14:21:53.388+00	2026-06-13 14:21:53.388+00
amplitude	active	1.0.0	2026-06-11 12:28:25.27	{"id":11,"name":"com.amplitude/mcp-server","title":"Amplitude","tagline":"Connect to the Amplitude MCP Server","description":"Search, access, and get insights on your Amplitude data","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:51:08.257Z","icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_G_Fjvl8_Pa_bd331a64fc.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_G_Fjvl8_Pa_a15896d97c.svg","mimeType":"image/svg+xml","theme":"light"}],"remotes":[{"id":17,"type":"streamable-http","url":"https://mcp.amplitude.com/mcp"},{"id":18,"type":"streamable-http","url":"https://mcp.eu.amplitude.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null}	2026-06-13 14:21:53.388+00	2026-06-13 14:21:53.388+00
apify	active	0.10.6	2026-06-11 12:28:32.446	{"id":3,"name":"com.apify/apify-mcp-server","title":"Apify","tagline":"Connect to the Apify MCP Server","description":"Extract data from any website with thousands of scrapers, crawlers, and automations on Apify Store ⚡","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:49:36.524Z","icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_S_Uz5c4rz_d01d21b490.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id6k3_J_n_Mi_ceeccc3a3e.svg","mimeType":"image/svg+xml","theme":"light"}],"remotes":[{"id":5,"type":"streamable-http","url":"https://mcp.apify.com/"}],"tools":[],"tags":{"data":[]},"extendsCredential":null}	2026-06-13 14:21:53.388+00	2026-06-13 14:21:53.388+00
atlassian	active	1.1.1	2026-06-11 12:28:42.32	{"id":2,"name":"com.atlassian/atlassian-mcp-server","title":"Atlassian","tagline":"Connect to the Atlassian MCP Server","description":"Atlassian Rovo MCP Server","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:49:24.904Z","icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_KV_Ejn_Mrk_716d407499.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_KV_Ejn_Mrk_1f404ecbfd.svg","mimeType":"image/svg+xml","theme":"light"}],"remotes":[{"id":3,"type":"streamable-http","url":"https://mcp.atlassian.com/v1/mcp"},{"id":4,"type":"sse","url":"https://mcp.atlassian.com/v1/sse"}],"tools":[],"tags":{"data":[]},"extendsCredential":null}	2026-06-13 14:21:53.388+00	2026-06-13 14:21:53.388+00
close	active	1.0.1	2026-06-11 12:28:50.223	{"id":13,"name":"com.close/close-mcp","title":"Close","tagline":"Connect to the Close MCP Server","description":"Close CRM to manage your sales pipeline. Learn more at https://close.com or https://mcp.close.com","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:51:32.979Z","icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idpghi9sa_C_14d2cba8bf.png","mimeType":"image/png","theme":"light"}],"remotes":[{"id":23,"type":"streamable-http","url":"https://mcp.close.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null}	2026-06-13 14:21:53.388+00	2026-06-13 14:21:53.388+00
git-lab	active	0.0.1	2026-06-11 12:28:56.391	{"id":6,"name":"com.gitlab/mcp","title":"GitLab","tagline":"Connect to the GitLab MCP Server","description":"Official GitLab MCP Server","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:50:10.745Z","icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idkt3_Cw41b_9f7043ad83.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_O_Daz_Q_Zbt_f76933a2e6.svg","mimeType":"image/svg+xml","theme":"light"}],"remotes":[{"id":9,"type":"streamable-http","url":"https://gitlab.com/api/v4/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null}	2026-06-13 14:21:53.388+00	2026-06-13 14:21:53.388+00
monday-com	active	0.0.1	2026-06-11 12:29:02.947	{"id":5,"name":"com.monday/monday.com","title":"monday.com","tagline":"Connect to the monday.com MCP Server","description":"MCP server for monday.com integration.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:49:59.434Z","icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idz_Vgm_C8_SV_4533eff3c2.svg","mimeType":"image/svg+xml","theme":"light"}],"remotes":[{"id":7,"type":"streamable-http","url":"https://mcp.monday.com/mcp"},{"id":8,"type":"sse","url":"https://mcp.monday.com/sse"}],"tools":[],"tags":{"data":[]},"extendsCredential":null}	2026-06-13 14:21:53.388+00	2026-06-13 14:21:53.388+00
notion	active	1.0.1	2026-06-11 12:29:07.703	{"id":1,"name":"com.notion/mcp","title":"Notion","tagline":"Connect to the Notion MCP Server","description":"Official Notion MCP server","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:49:13.571Z","icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idjb_Qg_E_jj_26d71d08b5.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idjb_Qg_E_jj_5fcfcab5f8.svg","mimeType":"image/svg+xml","theme":"light"}],"remotes":[{"id":1,"type":"streamable-http","url":"https://mcp.notion.com/mcp"},{"id":2,"type":"sse","url":"https://mcp.notion.com/sse"}],"tools":[],"tags":{"data":[]},"extendsCredential":null}	2026-06-13 14:21:53.388+00	2026-06-13 14:21:53.388+00
pay-pal	active	1.0.0	2026-06-11 12:29:23.307	{"id":9,"name":"com.paypal.mcp/mcp","title":"PayPal","tagline":"Connect to the PayPal MCP Server","description":"PayPal MCP server provides access to PayPal services and operations for AI assistants","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:50:45.127Z","icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_R_Wy_Aj_C_Dz_324a3b0a2e.svg","mimeType":"image/svg+xml","theme":"light"}],"remotes":[{"id":13,"type":"streamable-http","url":"https://mcp.paypal.com/mcp"},{"id":14,"type":"sse","url":"https://mcp.paypal.com/sse"}],"tools":[],"tags":{"data":[]},"extendsCredential":null}	2026-06-13 14:21:53.388+00	2026-06-13 14:21:53.388+00
postman	active	2.8.9	2026-06-11 12:29:28.445	{"id":12,"name":"com.postman/postman-mcp-server","title":"Postman","tagline":"Connect to the Postman MCP Server","description":"A basic MCP server to operate on the Postman API.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:51:20.254Z","icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idr_UU_WRCO_c111cb0dea.png","mimeType":"image/png","theme":"light"}],"remotes":[{"id":19,"type":"streamable-http","url":"https://mcp.postman.com/mcp"},{"id":20,"type":"streamable-http","url":"https://mcp.postman.com/minimal"},{"id":21,"type":"streamable-http","url":"https://mcp.eu.postman.com/mcp"},{"id":22,"type":"streamable-http","url":"https://mcp.eu.postman.com/minimal"}],"tools":[],"tags":{"data":[]},"extendsCredential":null}	2026-06-13 14:21:53.388+00	2026-06-13 14:21:53.388+00
stripe	active	0.2.4	2026-06-11 12:29:33.086	{"id":4,"name":"com.stripe/mcp","title":"Stripe","tagline":"Connect to the Stripe MCP Server","description":"MCP server integrating with Stripe - tools for customers, products, payments, and more.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:49:47.930Z","icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Bn9_1_Njr_e4279db01b.jpeg","mimeType":"image/jpeg","theme":"light"}],"remotes":[{"id":6,"type":"streamable-http","url":"https://mcp.stripe.com"}],"tools":[],"tags":{"data":[]},"extendsCredential":null}	2026-06-13 14:21:53.388+00	2026-06-13 14:21:53.388+00
webflow	active	2.0.0	2026-06-11 12:29:37.869	{"id":8,"name":"com.webflow/mcp","title":"Webflow","tagline":"Connect to the Webflow MCP Server","description":"AI-powered design and management for Webflow Sites","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:50:33.630Z","icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idx_GYKE_Fj1_b568d3380a.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Zp72_NUI_5_080d2c331c.svg","mimeType":"image/svg+xml","theme":"light"}],"remotes":[{"id":12,"type":"streamable-http","url":"https://mcp.webflow.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null}	2026-06-13 14:21:53.388+00	2026-06-13 14:21:53.388+00
wix	active	1.0.2	2026-06-11 12:29:47.22	{"id":14,"name":"com.wix/mcp","title":"Wix","tagline":"Connect to the Wix MCP Server","description":"A Model Context Protocol server for Wix AI tools","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:51:44.311Z","icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Qa_F_Jx_Orc_31d963143f.jpeg","mimeType":"image/jpeg","theme":"light"}],"remotes":[{"id":24,"type":"sse","url":"https://mcp.wix.com/sse"},{"id":25,"type":"streamable-http","url":"https://mcp.wix.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null}	2026-06-13 14:21:53.388+00	2026-06-13 14:21:53.388+00
post-hog	active	0.2.5	2026-06-11 12:29:53.047	{"id":10,"name":"io.github.PostHog/mcp","title":"PostHog","tagline":"Connect to the PostHog MCP Server","description":"Official PostHog MCP Server for product analytics, feature flags, experiments, and more.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:50:56.421Z","icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Yz0_Wt_S_Oc_8e4d0f0070.svg","mimeType":"image/svg+xml","theme":"light"}],"remotes":[{"id":16,"type":"streamable-http","url":"https://mcp.posthog.com/mcp"},{"id":15,"type":"sse","url":"https://mcp.posthog.com/sse"}],"tools":[],"tags":{"data":[]},"extendsCredential":null}	2026-06-13 14:21:53.388+00	2026-06-13 14:21:53.388+00
prisma	active	1.0.0	2026-06-11 12:30:05.827	{"id":15,"name":"io.prisma/mcp","title":"Prisma","tagline":"Connect to the Prisma MCP Server","description":"MCP server for managing Prisma Postgres.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:51:55.545Z","icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idz_L_5t_H6_B_e6163aea2d.jpg","mimeType":"image/jpeg","theme":"light"}],"remotes":[{"id":26,"type":"sse","url":"https://mcp.prisma.io/sse"},{"id":27,"type":"streamable-http","url":"https://mcp.prisma.io/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null}	2026-06-13 14:21:53.388+00	2026-06-13 14:21:53.388+00
sanity	active	2.19.0	2026-06-11 12:30:10.774	{"id":16,"name":"io.sanity.www/mcp","title":"Sanity","tagline":"Connect to the Sanity MCP Server","description":"Direct access to your Sanity projects (content, datasets, releases, schemas) and agent rules","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:52:07.029Z","icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Qr019q7c_e4c0ec82b7.png","mimeType":"image/png","theme":"light"}],"remotes":[{"id":28,"type":"streamable-http","url":"https://mcp.sanity.io"}],"tools":[],"tags":{"data":[]},"extendsCredential":null}	2026-06-13 14:21:53.388+00	2026-06-13 14:21:53.388+00
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.migrations (id, "timestamp", name) FROM stdin;
1	1587669153312	InitialMigration1587669153312
2	1589476000887	WebhookModel1589476000887
3	1594828256133	CreateIndexStoppedAt1594828256133
4	1607431743768	MakeStoppedAtNullable1607431743768
5	1611144599516	AddWebhookId1611144599516
6	1617270242566	CreateTagEntity1617270242566
7	1620824779533	UniqueWorkflowNames1620824779533
8	1626176912946	AddwaitTill1626176912946
9	1630419189837	UpdateWorkflowCredentials1630419189837
10	1644422880309	AddExecutionEntityIndexes1644422880309
11	1646834195327	IncreaseTypeVarcharLimit1646834195327
12	1646992772331	CreateUserManagement1646992772331
13	1648740597343	LowerCaseUserEmail1648740597343
14	1652254514002	CommunityNodes1652254514002
15	1652367743993	AddUserSettings1652367743993
16	1652905585850	AddAPIKeyColumn1652905585850
17	1654090467022	IntroducePinData1654090467022
18	1658932090381	AddNodeIds1658932090381
19	1659902242948	AddJsonKeyPinData1659902242948
20	1660062385367	CreateCredentialsUserRole1660062385367
21	1663755770893	CreateWorkflowsEditorRole1663755770893
22	1664196174001	WorkflowStatistics1664196174001
23	1665484192212	CreateCredentialUsageTable1665484192212
24	1665754637025	RemoveCredentialUsageTable1665754637025
25	1669739707126	AddWorkflowVersionIdColumn1669739707126
26	1669823906995	AddTriggerCountColumn1669823906995
27	1671535397530	MessageEventBusDestinations1671535397530
28	1671726148421	RemoveWorkflowDataLoadedFlag1671726148421
29	1673268682475	DeleteExecutionsWithWorkflows1673268682475
30	1674138566000	AddStatusToExecutions1674138566000
31	1674509946020	CreateLdapEntities1674509946020
32	1675940580449	PurgeInvalidWorkflowConnections1675940580449
33	1676996103000	MigrateExecutionStatus1676996103000
34	1677236854063	UpdateRunningExecutionStatus1677236854063
35	1677501636754	CreateVariables1677501636754
36	1679416281778	CreateExecutionMetadataTable1679416281778
37	1681134145996	AddUserActivatedProperty1681134145996
38	1681134145997	RemoveSkipOwnerSetup1681134145997
39	1690000000000	MigrateIntegerKeysToString1690000000000
40	1690000000020	SeparateExecutionData1690000000020
41	1690000000030	RemoveResetPasswordColumns1690000000030
42	1690000000030	AddMfaColumns1690000000030
43	1690787606731	AddMissingPrimaryKeyOnExecutionData1690787606731
44	1691088862123	CreateWorkflowNameIndex1691088862123
45	1692967111175	CreateWorkflowHistoryTable1692967111175
46	1693491613982	ExecutionSoftDelete1693491613982
47	1693554410387	DisallowOrphanExecutions1693554410387
48	1694091729095	MigrateToTimestampTz1694091729095
49	1695128658538	AddWorkflowMetadata1695128658538
50	1695829275184	ModifyWorkflowHistoryNodesAndConnections1695829275184
51	1700571993961	AddGlobalAdminRole1700571993961
52	1705429061930	DropRoleMapping1705429061930
53	1711018413374	RemoveFailedExecutionStatus1711018413374
54	1711390882123	MoveSshKeysToDatabase1711390882123
55	1712044305787	RemoveNodesAccess1712044305787
56	1714133768519	CreateProject1714133768519
57	1714133768521	MakeExecutionStatusNonNullable1714133768521
58	1717498465931	AddActivatedAtUserSetting1717498465931
59	1720101653148	AddConstraintToExecutionMetadata1720101653148
60	1721377157740	FixExecutionMetadataSequence1721377157740
61	1723627610222	CreateInvalidAuthTokenTable1723627610222
62	1723796243146	RefactorExecutionIndices1723796243146
63	1724753530828	CreateAnnotationTables1724753530828
64	1724951148974	AddApiKeysTable1724951148974
65	1726606152711	CreateProcessedDataTable1726606152711
66	1727427440136	SeparateExecutionCreationFromStart1727427440136
67	1728659839644	AddMissingPrimaryKeyOnAnnotationTagMapping1728659839644
68	1729607673464	UpdateProcessedDataValueColumnToText1729607673464
69	1729607673469	AddProjectIcons1729607673469
70	1730386903556	CreateTestDefinitionTable1730386903556
71	1731404028106	AddDescriptionToTestDefinition1731404028106
72	1731582748663	MigrateTestDefinitionKeyToString1731582748663
73	1732271325258	CreateTestMetricTable1732271325258
74	1732549866705	CreateTestRun1732549866705
75	1733133775640	AddMockedNodesColumnToTestDefinition1733133775640
76	1734479635324	AddManagedColumnToCredentialsTable1734479635324
77	1736172058779	AddStatsColumnsToTestRun1736172058779
78	1736947513045	CreateTestCaseExecutionTable1736947513045
79	1737715421462	AddErrorColumnsToTestRuns1737715421462
80	1738709609940	CreateFolderTable1738709609940
81	1739549398681	CreateAnalyticsTables1739549398681
82	1740445074052	UpdateParentFolderIdColumn1740445074052
83	1741167584277	RenameAnalyticsToInsights1741167584277
84	1742918400000	AddScopesColumnToApiKeys1742918400000
85	1745322634000	ClearEvaluation1745322634000
86	1745587087521	AddWorkflowStatisticsRootCount1745587087521
87	1745934666076	AddWorkflowArchivedColumn1745934666076
88	1745934666077	DropRoleTable1745934666077
89	1747824239000	AddProjectDescriptionColumn1747824239000
90	1750252139166	AddLastActiveAtColumnToUser1750252139166
91	1750252139166	AddScopeTables1750252139166
92	1750252139167	AddRolesTables1750252139167
93	1750252139168	LinkRoleToUserTable1750252139168
94	1750252139170	RemoveOldRoleColumn1750252139170
95	1752669793000	AddInputsOutputsToTestCaseExecution1752669793000
96	1753953244168	LinkRoleToProjectRelationTable1753953244168
97	1754475614601	CreateDataStoreTables1754475614601
98	1754475614602	ReplaceDataStoreTablesWithDataTables1754475614602
99	1756906557570	AddTimestampsToRoleAndRoleIndexes1756906557570
100	1758731786132	AddAudienceColumnToApiKeys1758731786132
101	1758794506893	AddProjectIdToVariableTable1758794506893
102	1759399811000	ChangeValueTypesForInsights1759399811000
103	1760019379982	CreateChatHubTables1760019379982
104	1760020000000	CreateChatHubAgentTable1760020000000
105	1760020838000	UniqueRoleNames1760020838000
106	1760116750277	CreateOAuthEntities1760116750277
107	1760314000000	CreateWorkflowDependencyTable1760314000000
108	1760965142113	DropUnusedChatHubColumns1760965142113
109	1761047826451	AddWorkflowVersionColumn1761047826451
110	1761655473000	ChangeDependencyInfoToJson1761655473000
111	1761773155024	AddAttachmentsToChatHubMessages1761773155024
112	1761830340990	AddToolsColumnToChatHubTables1761830340990
113	1762177736257	AddWorkflowDescriptionColumn1762177736257
114	1762763704614	BackfillMissingWorkflowHistoryRecords1762763704614
115	1762771264000	ChangeDefaultForIdInUserTable1762771264000
116	1762771954619	AddIsGlobalColumnToCredentialsTable1762771954619
117	1762847206508	AddWorkflowHistoryAutoSaveFields1762847206508
118	1763047800000	AddActiveVersionIdColumn1763047800000
119	1763048000000	ActivateExecuteWorkflowTriggerWorkflows1763048000000
120	1763572724000	ChangeOAuthStateColumnToUnboundedVarchar1763572724000
121	1763716655000	CreateBinaryDataTable1763716655000
122	1764167920585	CreateWorkflowPublishHistoryTable1764167920585
123	1764276827837	AddCreatorIdToProjectTable1764276827837
124	1764682447000	CreateDynamicCredentialResolverTable1764682447000
125	1764689388394	AddDynamicCredentialEntryTable1764689388394
126	1765448186933	BackfillMissingWorkflowHistoryRecords1765448186933
127	1765459448000	AddResolvableFieldsToCredentials1765459448000
128	1765788427674	AddIconToAgentTable1765788427674
129	1765804780000	ConvertAgentIdToUuid1765804780000
130	1765886667897	AddAgentIdForeignKeys1765886667897
131	1765892199653	AddWorkflowVersionIdToExecutionData1765892199653
132	1766064542000	AddWorkflowPublishScopeToProjectRoles1766064542000
133	1766068346315	AddChatMessageIndices1766068346315
134	1766500000000	ExpandInsightsWorkflowIdLength1766500000000
135	1767018516000	ChangeWorkflowStatisticsFKToNoAction1767018516000
136	1768402473068	ExpandModelColumnLength1768402473068
137	1768557000000	AddStoredAtToExecutionEntity1768557000000
138	1768901721000	AddDynamicCredentialUserEntryTable1768901721000
139	1769000000000	AddPublishedVersionIdToWorkflowDependency1769000000000
140	1769433700000	CreateSecretsProviderConnectionTables1769433700000
141	1769698710000	CreateWorkflowPublishedVersionTable1769698710000
142	1769784356000	ExpandSubjectIDColumnLength1769784356000
143	1769900001000	AddWorkflowUnpublishScopeToCustomRoles1769900001000
144	1770000000000	CreateChatHubToolsTable1770000000000
145	1770000000000	ExpandProviderIdColumnLength1770000000000
146	1770220686000	CreateWorkflowBuilderSessionTable1770220686000
147	1771417407753	AddScalingFieldsToTestRun1771417407753
148	1771500000000	MigrateExternalSecretsToEntityStorage1771500000000
149	1771500000001	AddUnshareScopeToCustomRoles1771500000001
150	1771500000002	AddFilesColumnToChatHubAgents1771500000002
151	1772000000000	AddSuggestedPromptsToAgentTable1772000000000
152	1772619247761	AddRoleColumnToProjectSecretsProviderAccess1772619247761
153	1772619247762	ChangeWorkflowPublishedVersionFKsToRestrict1772619247762
154	1772700000000	AddTypeToChatHubSessions1772700000000
155	1772800000000	CreateRoleMappingRuleTable1772800000000
156	1773000000000	CreateCredentialDependencyTable1773000000000
157	1774280963551	AddRestoreFieldsToWorkflowBuilderSession1774280963551
158	1774854660000	CreateInstanceVersionHistoryTable1774854660000
159	1775000000000	CreateInstanceAiTables1775000000000
160	1775116241000	CreateTokenExchangeJtiTable1775116241000
161	1775740765000	ChangeWorkflowPublishHistoryVersionIdToSetNull1775740765000
162	1776000000000	CreateTrustedKeyTables1776000000000
163	1776150756000	CreateFavoritesTable1776150756000
164	1777000000000	CreateDeploymentKeyTable1777000000000
165	1777023444000	AddJweKeyIndexesToDeploymentKey1777023444000
166	1777045000000	AddTracingContextToExecution1777045000000
167	1777100000000	AddLangsmithIdsToInstanceAiRunSnapshots1777100000000
168	1777281990043	CreateAiBuilderTemporaryWorkflowTable1777281990043
169	1777420800000	ExpandVariablesValueColumnToText1777420800000
170	1777996709110	AddRunIndexToTestCaseExecution1777996709110
171	1778000000000	AddExecutionDeduplicationKey1778000000000
172	1778100000000	CreateEvaluationConfig1778100000000
173	1778100001000	AddWorkflowVersionToTestRun1778100001000
174	1778100002000	AddEvaluationConfigColumnsToTestRun1778100002000
175	1778496086558	CreateEvaluationCollection1778496086558
176	1783000000000	CreateAgentTables1783000000000
177	1783000000001	CreateAgentExecutionTables1783000000001
178	1784000000000	CreateAgentObservationTables1784000000000
179	1784000000001	ReplaceAgentObservationTables1784000000001
180	1784000000002	DropAgentExecutionWorkingMemory1784000000002
181	1784000000003	LimitWorkflowVersionTriggerToContent1784000000003
182	1784000000004	AddInsightsRawTimestampIdIndex1784000000004
183	1784000000005	CreateMcpRegistryServerTable1784000000005
184	1784000000006	AddNodeGroupsColumnToWorkflowAndHistory1784000000006
185	1784000000007	CreateInstanceAiCheckpointTable1784000000007
186	1784000000008	ResetInstanceAiNativePersistence1784000000008
187	1784000000009	CreateAgentMemoryEntryTables1784000000009
188	1784000000010	RefactorAgentObservationScope1784000000010
189	1784000000011	CreateAgentHistoryTable1784000000011
190	1784000000012	CreateInstanceAiObservationTables1784000000012
191	1784000000013	SplitRedactionScopeInCustomRoles1784000000013
192	1784000000014	PersistInstanceAiPendingConfirmations1784000000014
193	1784000000015	AddSourceWorkflowIdToWorkflow1784000000015
194	1784000000016	UseSlugAsPrimaryKeyInMcpRegistryServer1784000000016
195	1784000000017	AddLastUsedAtToApiKey1784000000017
196	1784000000018	CreateAgentFilesTable1784000000018
197	1784000000019	AddCustomTelemetryTagsToProject1784000000019
198	1784000000020	CreateWorkflowPublicationOutboxTable1784000000020
200	1784000000021	CreateAgentTaskDefinitionTable1784000000021
\.


--
-- Data for Name: oauth_access_tokens; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.oauth_access_tokens (token, "clientId", "userId") FROM stdin;
\.


--
-- Data for Name: oauth_authorization_codes; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.oauth_authorization_codes (code, "clientId", "userId", "redirectUri", "codeChallenge", "codeChallengeMethod", "expiresAt", state, used, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.oauth_clients (id, name, "redirectUris", "grantTypes", "clientSecret", "clientSecretExpiresAt", "tokenEndpointAuthMethod", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: oauth_refresh_tokens; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.oauth_refresh_tokens (token, "clientId", "userId", "expiresAt", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: oauth_user_consents; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.oauth_user_consents (id, "userId", "clientId", "grantedAt") FROM stdin;
\.


--
-- Data for Name: processed_data; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.processed_data ("workflowId", context, "createdAt", "updatedAt", value) FROM stdin;
\.


--
-- Data for Name: project; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.project (id, name, type, "createdAt", "updatedAt", icon, description, "creatorId", "customTelemetryTags") FROM stdin;
C56wJya6tXcF5Glv	Кравченко Антон <jokerla23@gmail.com>	personal	2026-06-13 14:21:33.641+00	2026-06-13 18:15:36.268+00	\N	\N	0fa10d90-9e6d-48bb-93c8-af3f20c5f0b5	[]
\.


--
-- Data for Name: project_relation; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.project_relation ("projectId", "userId", role, "createdAt", "updatedAt") FROM stdin;
C56wJya6tXcF5Glv	0fa10d90-9e6d-48bb-93c8-af3f20c5f0b5	project:personalOwner	2026-06-13 14:21:33.641+00	2026-06-13 14:21:33.641+00
\.


--
-- Data for Name: project_secrets_provider_access; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.project_secrets_provider_access ("secretsProviderConnectionId", "projectId", "createdAt", "updatedAt", role) FROM stdin;
\.


--
-- Data for Name: role; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.role (slug, "displayName", description, "roleType", "systemRole", "createdAt", "updatedAt") FROM stdin;
global:chatUser	Chat User	Chat User	global	t	2026-06-13 14:21:43.561+00	2026-06-13 14:21:43.561+00
global:owner	Owner	Owner	global	t	2026-06-13 14:21:36.481+00	2026-06-13 14:21:43.8+00
global:admin	Admin	Admin	global	t	2026-06-13 14:21:36.481+00	2026-06-13 14:21:43.8+00
global:member	Member	Member	global	t	2026-06-13 14:21:36.481+00	2026-06-13 14:21:43.8+00
project:admin	Project Admin	Full control of settings, members, workflows, credentials and executions	project	t	2026-06-13 14:21:36.481+00	2026-06-13 14:21:43.965+00
project:personalOwner	Project Owner	Project Owner	project	t	2026-06-13 14:21:36.481+00	2026-06-13 14:21:43.965+00
project:editor	Project Editor	Create, edit, and delete workflows, credentials, and executions	project	t	2026-06-13 14:21:36.481+00	2026-06-13 14:21:43.965+00
project:viewer	Project Viewer	Read-only access to workflows, credentials, and executions	project	t	2026-06-13 14:21:36.481+00	2026-06-13 14:21:43.97+00
project:chatUser	Project Chat User	Chat-only access to chatting with workflows that have n8n Chat enabled	project	t	2026-06-13 14:21:36.481+00	2026-06-13 14:21:43.97+00
credential:owner	Credential Owner	Credential Owner	credential	t	2026-06-13 14:21:43.561+00	2026-06-13 14:21:43.561+00
credential:user	Credential User	Credential User	credential	t	2026-06-13 14:21:43.561+00	2026-06-13 14:21:43.561+00
workflow:owner	Workflow Owner	Workflow Owner	workflow	t	2026-06-13 14:21:43.561+00	2026-06-13 14:21:43.561+00
workflow:editor	Workflow Editor	Workflow Editor	workflow	t	2026-06-13 14:21:43.561+00	2026-06-13 14:21:43.561+00
secretsProviderConnection:owner	Secrets Provider Connection Owner	Full control of secrets provider connection settings and secrets	secretsProviderConnection	t	2026-06-13 14:21:43.561+00	2026-06-13 14:21:43.561+00
secretsProviderConnection:user	Secrets Provider Connection User	Read-only access to use secrets from the connection	secretsProviderConnection	t	2026-06-13 14:21:43.561+00	2026-06-13 14:21:43.561+00
\.


--
-- Data for Name: role_mapping_rule; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.role_mapping_rule (id, expression, role, type, "order", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: role_mapping_rule_project; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.role_mapping_rule_project ("roleMappingRuleId", "projectId") FROM stdin;
\.


--
-- Data for Name: role_scope; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.role_scope ("roleSlug", "scopeSlug") FROM stdin;
global:owner	workflow:unpublish
global:owner	workflow:unshare
global:owner	credential:unshare
global:owner	agent:create
global:owner	agent:read
global:owner	agent:update
global:owner	agent:delete
global:owner	agent:list
global:owner	agent:execute
global:owner	agent:publish
global:owner	agent:unpublish
global:owner	agent:manage
global:owner	aiAssistant:manage
global:owner	annotationTag:create
global:owner	annotationTag:read
global:owner	annotationTag:update
global:owner	annotationTag:delete
global:owner	annotationTag:list
global:owner	auditLogs:manage
global:owner	banner:dismiss
global:owner	community:register
global:owner	communityPackage:install
global:owner	communityPackage:uninstall
global:owner	communityPackage:update
global:owner	communityPackage:list
global:owner	credential:share
global:owner	credential:shareGlobally
global:owner	credential:move
global:owner	credential:create
global:owner	credential:read
global:owner	credential:update
global:owner	credential:delete
global:owner	credential:list
global:owner	externalSecretsProvider:sync
global:owner	externalSecretsProvider:create
global:owner	externalSecretsProvider:read
global:owner	externalSecretsProvider:update
global:owner	externalSecretsProvider:delete
global:owner	externalSecretsProvider:list
global:owner	externalSecret:list
global:owner	eventBusDestination:test
global:owner	eventBusDestination:create
global:owner	eventBusDestination:read
global:owner	eventBusDestination:update
global:owner	eventBusDestination:delete
global:owner	eventBusDestination:list
global:owner	ldap:sync
global:owner	ldap:manage
global:owner	license:manage
global:owner	logStreaming:manage
global:owner	orchestration:read
global:owner	project:create
global:owner	project:read
global:owner	project:update
global:owner	project:delete
global:owner	project:list
global:owner	saml:manage
global:owner	securityAudit:generate
global:owner	securitySettings:manage
global:owner	sourceControl:pull
global:owner	sourceControl:push
global:owner	sourceControl:manage
global:owner	tag:create
global:owner	tag:read
global:owner	tag:update
global:owner	tag:delete
global:owner	tag:list
global:owner	user:resetPassword
global:owner	user:changeRole
global:owner	user:enforceMfa
global:owner	user:generateInviteLink
global:owner	user:create
global:owner	user:read
global:owner	user:update
global:owner	user:delete
global:owner	user:list
global:owner	variable:create
global:owner	variable:read
global:owner	variable:update
global:owner	variable:delete
global:owner	variable:list
global:owner	projectVariable:create
global:owner	projectVariable:read
global:owner	projectVariable:update
global:owner	projectVariable:delete
global:owner	projectVariable:list
global:owner	workersView:manage
global:owner	workflow:share
global:owner	workflow:execute
global:owner	workflow:execute-chat
global:owner	workflow:export
global:owner	workflow:import
global:owner	workflow:move
global:owner	workflow:create
global:owner	workflow:read
global:owner	workflow:update
global:owner	workflow:delete
global:owner	workflow:list
global:owner	folder:create
global:owner	folder:read
global:owner	folder:update
global:owner	folder:delete
global:owner	folder:list
global:owner	folder:move
global:owner	insights:list
global:owner	insights:read
global:owner	oidc:manage
global:owner	provisioning:manage
global:owner	dataTable:create
global:owner	dataTable:read
global:owner	dataTable:update
global:owner	dataTable:delete
global:owner	dataTable:list
global:owner	dataTable:readRow
global:owner	dataTable:writeRow
global:owner	dataTable:readColumn
global:owner	dataTable:writeColumn
global:owner	dataTable:listProject
global:owner	execution:reveal
global:owner	role:manage
global:owner	mcp:manage
global:owner	mcp:oauth
global:owner	mcpApiKey:create
global:owner	mcpApiKey:rotate
global:owner	chatHub:manage
global:owner	chatHub:message
global:owner	chatHubAgent:create
global:owner	chatHubAgent:read
global:owner	chatHubAgent:update
global:owner	chatHubAgent:delete
global:owner	chatHubAgent:list
global:owner	breakingChanges:list
global:owner	apiKey:manage
global:owner	encryptionKey:manage
global:owner	credentialResolver:create
global:owner	credentialResolver:read
global:owner	credentialResolver:update
global:owner	credentialResolver:delete
global:owner	credentialResolver:list
global:owner	instanceAi:message
global:owner	instanceAi:manage
global:owner	instanceAi:gateway
global:owner	roleMappingRule:create
global:owner	roleMappingRule:read
global:owner	roleMappingRule:update
global:owner	roleMappingRule:delete
global:owner	roleMappingRule:list
global:owner	workflow:publish
global:owner	workflow:enableRedaction
global:owner	workflow:disableRedaction
global:admin	workflow:unpublish
global:admin	workflow:unshare
global:admin	credential:unshare
global:admin	agent:create
global:admin	agent:read
global:admin	agent:update
global:admin	agent:delete
global:admin	agent:list
global:admin	agent:execute
global:admin	agent:publish
global:admin	agent:unpublish
global:admin	agent:manage
global:admin	aiAssistant:manage
global:admin	annotationTag:create
global:admin	annotationTag:read
global:admin	annotationTag:update
global:admin	annotationTag:delete
global:admin	annotationTag:list
global:admin	auditLogs:manage
global:admin	banner:dismiss
global:admin	community:register
global:admin	communityPackage:install
global:admin	communityPackage:uninstall
global:admin	communityPackage:update
global:admin	communityPackage:list
global:admin	credential:share
global:admin	credential:shareGlobally
global:admin	credential:move
global:admin	credential:create
global:admin	credential:read
global:admin	credential:update
global:admin	credential:delete
global:admin	credential:list
global:admin	externalSecretsProvider:sync
global:admin	externalSecretsProvider:create
global:admin	externalSecretsProvider:read
global:admin	externalSecretsProvider:update
global:admin	externalSecretsProvider:delete
global:admin	externalSecretsProvider:list
global:admin	externalSecret:list
global:admin	eventBusDestination:test
global:admin	eventBusDestination:create
global:admin	eventBusDestination:read
global:admin	eventBusDestination:update
global:admin	eventBusDestination:delete
global:admin	eventBusDestination:list
global:admin	ldap:sync
global:admin	ldap:manage
global:admin	license:manage
global:admin	logStreaming:manage
global:admin	orchestration:read
global:admin	project:create
global:admin	project:read
global:admin	project:update
global:admin	project:delete
global:admin	project:list
global:admin	saml:manage
global:admin	securityAudit:generate
global:admin	securitySettings:manage
global:admin	sourceControl:pull
global:admin	sourceControl:push
global:admin	sourceControl:manage
global:admin	tag:create
global:admin	tag:read
global:admin	tag:update
global:admin	tag:delete
global:admin	tag:list
global:admin	user:resetPassword
global:admin	user:changeRole
global:admin	user:enforceMfa
global:admin	user:generateInviteLink
global:admin	user:create
global:admin	user:read
global:admin	user:update
global:admin	user:delete
global:admin	user:list
global:admin	variable:create
global:admin	variable:read
global:admin	variable:update
global:admin	variable:delete
global:admin	variable:list
global:admin	projectVariable:create
global:admin	projectVariable:read
global:admin	projectVariable:update
global:admin	projectVariable:delete
global:admin	projectVariable:list
global:admin	workersView:manage
global:admin	workflow:share
global:admin	workflow:execute
global:admin	workflow:execute-chat
global:admin	workflow:export
global:admin	workflow:import
global:admin	workflow:move
global:admin	workflow:create
global:admin	workflow:read
global:admin	workflow:update
global:admin	workflow:delete
global:admin	workflow:list
global:admin	folder:create
global:admin	folder:read
global:admin	folder:update
global:admin	folder:delete
global:admin	folder:list
global:admin	folder:move
global:admin	insights:list
global:admin	insights:read
global:admin	oidc:manage
global:admin	provisioning:manage
global:admin	dataTable:create
global:admin	dataTable:read
global:admin	dataTable:update
global:admin	dataTable:delete
global:admin	dataTable:list
global:admin	dataTable:readRow
global:admin	dataTable:writeRow
global:admin	dataTable:readColumn
global:admin	dataTable:writeColumn
global:admin	dataTable:listProject
global:admin	execution:reveal
global:admin	role:manage
global:admin	mcp:manage
global:admin	mcp:oauth
global:admin	mcpApiKey:create
global:admin	mcpApiKey:rotate
global:admin	chatHub:manage
global:admin	chatHub:message
global:admin	chatHubAgent:create
global:admin	chatHubAgent:read
global:admin	chatHubAgent:update
global:admin	chatHubAgent:delete
global:admin	chatHubAgent:list
global:admin	breakingChanges:list
global:admin	apiKey:manage
global:admin	encryptionKey:manage
global:admin	credentialResolver:create
global:admin	credentialResolver:read
global:admin	credentialResolver:update
global:admin	credentialResolver:delete
global:admin	credentialResolver:list
global:admin	instanceAi:message
global:admin	instanceAi:manage
global:admin	instanceAi:gateway
global:admin	roleMappingRule:create
global:admin	roleMappingRule:read
global:admin	roleMappingRule:update
global:admin	roleMappingRule:delete
global:admin	roleMappingRule:list
global:admin	workflow:publish
global:admin	workflow:enableRedaction
global:admin	workflow:disableRedaction
global:member	annotationTag:create
global:member	annotationTag:read
global:member	annotationTag:update
global:member	annotationTag:delete
global:member	annotationTag:list
global:member	eventBusDestination:test
global:member	eventBusDestination:list
global:member	tag:create
global:member	tag:read
global:member	tag:update
global:member	tag:list
global:member	user:list
global:member	variable:read
global:member	variable:list
global:member	dataTable:list
global:member	mcp:oauth
global:member	mcpApiKey:create
global:member	mcpApiKey:rotate
global:member	chatHub:message
global:member	chatHubAgent:create
global:member	chatHubAgent:read
global:member	chatHubAgent:update
global:member	chatHubAgent:delete
global:member	chatHubAgent:list
global:member	apiKey:manage
global:member	credentialResolver:list
global:member	instanceAi:message
global:member	instanceAi:gateway
global:chatUser	chatHub:message
global:chatUser	chatHubAgent:create
global:chatUser	chatHubAgent:read
global:chatUser	chatHubAgent:update
global:chatUser	chatHubAgent:delete
global:chatUser	chatHubAgent:list
project:admin	workflow:unpublish
project:admin	credential:unshare
project:admin	agent:create
project:admin	agent:read
project:admin	agent:update
project:admin	agent:delete
project:admin	agent:list
project:admin	agent:execute
project:admin	agent:publish
project:admin	agent:unpublish
project:admin	credential:share
project:admin	credential:move
project:admin	credential:create
project:admin	credential:read
project:admin	credential:update
project:admin	credential:delete
project:admin	credential:list
project:admin	project:read
project:admin	project:update
project:admin	project:delete
project:admin	project:list
project:admin	sourceControl:push
project:admin	projectVariable:create
project:admin	projectVariable:read
project:admin	projectVariable:update
project:admin	projectVariable:delete
project:admin	projectVariable:list
project:admin	workflow:execute
project:admin	workflow:execute-chat
project:admin	workflow:export
project:admin	workflow:import
project:admin	workflow:move
project:admin	workflow:create
project:admin	workflow:read
project:admin	workflow:update
project:admin	workflow:delete
project:admin	workflow:list
project:admin	folder:create
project:admin	folder:read
project:admin	folder:update
project:admin	folder:delete
project:admin	folder:list
project:admin	folder:move
project:admin	dataTable:create
project:admin	dataTable:read
project:admin	dataTable:update
project:admin	dataTable:delete
project:admin	dataTable:readRow
project:admin	dataTable:writeRow
project:admin	dataTable:readColumn
project:admin	dataTable:writeColumn
project:admin	dataTable:listProject
project:admin	execution:reveal
project:admin	workflow:publish
project:admin	workflow:enableRedaction
project:admin	workflow:disableRedaction
project:personalOwner	workflow:unpublish
project:personalOwner	workflow:unshare
project:personalOwner	credential:unshare
project:personalOwner	agent:create
project:personalOwner	agent:read
project:personalOwner	agent:update
project:personalOwner	agent:delete
project:personalOwner	agent:list
project:personalOwner	agent:execute
project:personalOwner	agent:publish
project:personalOwner	agent:unpublish
project:personalOwner	credential:share
project:personalOwner	credential:move
project:personalOwner	credential:create
project:personalOwner	credential:read
project:personalOwner	credential:update
project:personalOwner	credential:delete
project:personalOwner	credential:list
project:personalOwner	project:read
project:personalOwner	project:list
project:personalOwner	workflow:share
project:personalOwner	workflow:execute
project:personalOwner	workflow:execute-chat
project:personalOwner	workflow:export
project:personalOwner	workflow:import
project:personalOwner	workflow:move
project:personalOwner	workflow:create
project:personalOwner	workflow:read
project:personalOwner	workflow:update
project:personalOwner	workflow:delete
project:personalOwner	workflow:list
project:personalOwner	folder:create
project:personalOwner	folder:read
project:personalOwner	folder:update
project:personalOwner	folder:delete
project:personalOwner	folder:list
project:personalOwner	folder:move
project:personalOwner	dataTable:create
project:personalOwner	dataTable:read
project:personalOwner	dataTable:update
project:personalOwner	dataTable:delete
project:personalOwner	dataTable:readRow
project:personalOwner	dataTable:writeRow
project:personalOwner	dataTable:readColumn
project:personalOwner	dataTable:writeColumn
project:personalOwner	dataTable:listProject
project:personalOwner	execution:reveal
project:personalOwner	workflow:publish
project:personalOwner	workflow:enableRedaction
project:personalOwner	workflow:disableRedaction
project:editor	workflow:unpublish
project:editor	agent:create
project:editor	agent:read
project:editor	agent:update
project:editor	agent:delete
project:editor	agent:list
project:editor	agent:execute
project:editor	agent:publish
project:editor	agent:unpublish
project:editor	credential:create
project:editor	credential:read
project:editor	credential:update
project:editor	credential:delete
project:editor	credential:list
project:editor	project:read
project:editor	project:list
project:editor	projectVariable:create
project:editor	projectVariable:read
project:editor	projectVariable:update
project:editor	projectVariable:delete
project:editor	projectVariable:list
project:editor	workflow:execute
project:editor	workflow:execute-chat
project:editor	workflow:export
project:editor	workflow:import
project:editor	workflow:create
project:editor	workflow:read
project:editor	workflow:update
project:editor	workflow:delete
project:editor	workflow:list
project:editor	folder:create
project:editor	folder:read
project:editor	folder:update
project:editor	folder:delete
project:editor	folder:list
project:editor	dataTable:create
project:editor	dataTable:read
project:editor	dataTable:update
project:editor	dataTable:delete
project:editor	dataTable:readRow
project:editor	dataTable:writeRow
project:editor	dataTable:readColumn
project:editor	dataTable:writeColumn
project:editor	dataTable:listProject
project:editor	workflow:publish
project:viewer	agent:read
project:viewer	agent:list
project:viewer	agent:execute
project:viewer	credential:read
project:viewer	credential:list
project:viewer	project:read
project:viewer	project:list
project:viewer	projectVariable:read
project:viewer	projectVariable:list
project:viewer	workflow:execute-chat
project:viewer	workflow:export
project:viewer	workflow:read
project:viewer	workflow:list
project:viewer	folder:read
project:viewer	folder:list
project:viewer	dataTable:read
project:viewer	dataTable:readRow
project:viewer	dataTable:readColumn
project:viewer	dataTable:listProject
project:chatUser	agent:execute
project:chatUser	workflow:execute-chat
credential:owner	credential:unshare
credential:owner	credential:share
credential:owner	credential:move
credential:owner	credential:read
credential:owner	credential:update
credential:owner	credential:delete
credential:user	credential:read
workflow:owner	workflow:unpublish
workflow:owner	workflow:unshare
workflow:owner	workflow:share
workflow:owner	workflow:execute
workflow:owner	workflow:execute-chat
workflow:owner	workflow:export
workflow:owner	workflow:move
workflow:owner	workflow:read
workflow:owner	workflow:update
workflow:owner	workflow:delete
workflow:owner	execution:reveal
workflow:owner	workflow:publish
workflow:owner	workflow:enableRedaction
workflow:owner	workflow:disableRedaction
workflow:editor	workflow:unpublish
workflow:editor	workflow:execute
workflow:editor	workflow:execute-chat
workflow:editor	workflow:export
workflow:editor	workflow:read
workflow:editor	workflow:update
workflow:editor	workflow:publish
secretsProviderConnection:owner	externalSecretsProvider:sync
secretsProviderConnection:owner	externalSecretsProvider:read
secretsProviderConnection:owner	externalSecretsProvider:update
secretsProviderConnection:owner	externalSecretsProvider:delete
secretsProviderConnection:owner	externalSecretsProvider:list
secretsProviderConnection:owner	externalSecret:list
secretsProviderConnection:user	externalSecretsProvider:read
secretsProviderConnection:user	externalSecretsProvider:list
secretsProviderConnection:user	externalSecret:list
\.


--
-- Data for Name: scope; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.scope (slug, "displayName", description) FROM stdin;
workflow:unpublish	Unpublish Workflow	Allows unpublishing workflows.
workflow:unshare	Unshare Workflow	Allows removing workflow shares.
credential:unshare	Unshare Credential	Allows removing credential shares.
agent:create	Create Agent	Allows creating new agents in a project.
agent:read	Read Agent	Allows reading agent configuration and history.
agent:update	Update Agent	Allows updating, building, publishing, and managing integrations of agents.
agent:delete	Delete Agent	Allows deleting agents.
agent:list	List Agents	Allows listing agents in a project.
agent:execute	Execute Agent	Allows running agents in chat.
agent:publish	Publish Agent	Allows publishing agents.
agent:unpublish	Unpublish Agent	Allows unpublishing agents.
agent:manage	agent:manage	\N
agent:*	agent:*	\N
aiAssistant:manage	Manage AI Usage	Allows managing AI Usage settings.
aiAssistant:*	aiAssistant:*	\N
annotationTag:create	Create Annotation Tag	Allows creating new annotation tags.
annotationTag:read	annotationTag:read	\N
annotationTag:update	annotationTag:update	\N
annotationTag:delete	annotationTag:delete	\N
annotationTag:list	annotationTag:list	\N
annotationTag:*	annotationTag:*	\N
auditLogs:manage	auditLogs:manage	\N
auditLogs:*	auditLogs:*	\N
banner:dismiss	banner:dismiss	\N
banner:*	banner:*	\N
community:register	community:register	\N
community:*	community:*	\N
communityPackage:install	communityPackage:install	\N
communityPackage:uninstall	communityPackage:uninstall	\N
communityPackage:update	communityPackage:update	\N
communityPackage:list	communityPackage:list	\N
communityPackage:manage	communityPackage:manage	\N
communityPackage:*	communityPackage:*	\N
credential:share	credential:share	\N
credential:shareGlobally	credential:shareGlobally	\N
credential:move	credential:move	\N
credential:create	credential:create	\N
credential:read	credential:read	\N
credential:update	credential:update	\N
credential:delete	credential:delete	\N
credential:list	credential:list	\N
credential:*	credential:*	\N
externalSecretsProvider:sync	externalSecretsProvider:sync	\N
externalSecretsProvider:create	externalSecretsProvider:create	\N
externalSecretsProvider:read	externalSecretsProvider:read	\N
externalSecretsProvider:update	externalSecretsProvider:update	\N
externalSecretsProvider:delete	externalSecretsProvider:delete	\N
externalSecretsProvider:list	externalSecretsProvider:list	\N
externalSecretsProvider:*	externalSecretsProvider:*	\N
externalSecret:list	externalSecret:list	\N
externalSecret:*	externalSecret:*	\N
eventBusDestination:test	eventBusDestination:test	\N
eventBusDestination:create	eventBusDestination:create	\N
eventBusDestination:read	eventBusDestination:read	\N
eventBusDestination:update	eventBusDestination:update	\N
eventBusDestination:delete	eventBusDestination:delete	\N
eventBusDestination:list	eventBusDestination:list	\N
eventBusDestination:*	eventBusDestination:*	\N
ldap:sync	ldap:sync	\N
ldap:manage	ldap:manage	\N
ldap:*	ldap:*	\N
license:manage	license:manage	\N
license:*	license:*	\N
logStreaming:manage	logStreaming:manage	\N
logStreaming:*	logStreaming:*	\N
orchestration:read	orchestration:read	\N
orchestration:list	orchestration:list	\N
orchestration:*	orchestration:*	\N
project:create	project:create	\N
project:read	project:read	\N
project:update	project:update	\N
project:delete	project:delete	\N
project:list	project:list	\N
project:*	project:*	\N
saml:manage	saml:manage	\N
saml:*	saml:*	\N
securityAudit:generate	securityAudit:generate	\N
securityAudit:*	securityAudit:*	\N
securitySettings:manage	securitySettings:manage	\N
securitySettings:*	securitySettings:*	\N
sourceControl:pull	sourceControl:pull	\N
sourceControl:push	sourceControl:push	\N
sourceControl:manage	sourceControl:manage	\N
sourceControl:*	sourceControl:*	\N
tag:create	tag:create	\N
tag:read	tag:read	\N
tag:update	tag:update	\N
tag:delete	tag:delete	\N
tag:list	tag:list	\N
tag:*	tag:*	\N
user:resetPassword	user:resetPassword	\N
user:changeRole	user:changeRole	\N
user:enforceMfa	user:enforceMfa	\N
user:generateInviteLink	user:generateInviteLink	\N
user:create	user:create	\N
user:read	user:read	\N
user:update	user:update	\N
user:delete	user:delete	\N
user:list	user:list	\N
user:*	user:*	\N
variable:create	variable:create	\N
variable:read	variable:read	\N
variable:update	variable:update	\N
variable:delete	variable:delete	\N
variable:list	variable:list	\N
variable:*	variable:*	\N
projectVariable:create	projectVariable:create	\N
projectVariable:read	projectVariable:read	\N
projectVariable:update	projectVariable:update	\N
projectVariable:delete	projectVariable:delete	\N
projectVariable:list	projectVariable:list	\N
projectVariable:*	projectVariable:*	\N
workersView:manage	workersView:manage	\N
workersView:*	workersView:*	\N
workflow:share	workflow:share	\N
workflow:execute	workflow:execute	\N
workflow:execute-chat	workflow:execute-chat	\N
workflow:export	Export Workflow	Allows including workflows in a portable package export.
workflow:import	Import Workflow	Allows importing workflows from a portable package into the project.
workflow:move	workflow:move	\N
workflow:activate	workflow:activate	\N
workflow:deactivate	workflow:deactivate	\N
workflow:create	workflow:create	\N
workflow:read	workflow:read	\N
workflow:update	workflow:update	\N
workflow:delete	workflow:delete	\N
workflow:list	workflow:list	\N
workflow:*	workflow:*	\N
folder:create	folder:create	\N
folder:read	folder:read	\N
folder:update	folder:update	\N
folder:delete	folder:delete	\N
folder:list	folder:list	\N
folder:move	folder:move	\N
folder:*	folder:*	\N
insights:list	insights:list	\N
insights:read	Read Insights	Allows reading insights data.
insights:*	insights:*	\N
oidc:manage	oidc:manage	\N
oidc:*	oidc:*	\N
provisioning:manage	provisioning:manage	\N
provisioning:*	provisioning:*	\N
dataTable:create	dataTable:create	\N
dataTable:read	dataTable:read	\N
dataTable:update	dataTable:update	\N
dataTable:delete	dataTable:delete	\N
dataTable:list	dataTable:list	\N
dataTable:readRow	dataTable:readRow	\N
dataTable:writeRow	dataTable:writeRow	\N
dataTable:readColumn	dataTable:readColumn	\N
dataTable:writeColumn	dataTable:writeColumn	\N
dataTable:listProject	dataTable:listProject	\N
dataTable:*	dataTable:*	\N
execution:delete	execution:delete	\N
execution:read	execution:read	\N
execution:retry	execution:retry	\N
execution:list	execution:list	\N
execution:get	execution:get	\N
execution:reveal	execution:reveal	\N
execution:*	execution:*	\N
workflowTags:update	workflowTags:update	\N
workflowTags:list	workflowTags:list	\N
workflowTags:*	workflowTags:*	\N
role:manage	role:manage	\N
role:*	role:*	\N
mcp:manage	mcp:manage	\N
mcp:oauth	mcp:oauth	\N
mcp:*	mcp:*	\N
mcpApiKey:create	mcpApiKey:create	\N
mcpApiKey:rotate	mcpApiKey:rotate	\N
mcpApiKey:*	mcpApiKey:*	\N
chatHub:manage	chatHub:manage	\N
chatHub:message	chatHub:message	\N
chatHub:*	chatHub:*	\N
chatHubAgent:create	chatHubAgent:create	\N
chatHubAgent:read	chatHubAgent:read	\N
chatHubAgent:update	chatHubAgent:update	\N
chatHubAgent:delete	chatHubAgent:delete	\N
chatHubAgent:list	chatHubAgent:list	\N
chatHubAgent:*	chatHubAgent:*	\N
breakingChanges:list	breakingChanges:list	\N
breakingChanges:*	breakingChanges:*	\N
apiKey:manage	apiKey:manage	\N
apiKey:*	apiKey:*	\N
encryptionKey:manage	Manage Encryption Keys	Allows listing and rotating instance encryption keys.
encryptionKey:*	encryptionKey:*	\N
credentialResolver:create	credentialResolver:create	\N
credentialResolver:read	credentialResolver:read	\N
credentialResolver:update	credentialResolver:update	\N
credentialResolver:delete	credentialResolver:delete	\N
credentialResolver:list	credentialResolver:list	\N
credentialResolver:*	credentialResolver:*	\N
instanceAi:message	instanceAi:message	\N
instanceAi:manage	instanceAi:manage	\N
instanceAi:gateway	instanceAi:gateway	\N
instanceAi:*	instanceAi:*	\N
roleMappingRule:create	roleMappingRule:create	\N
roleMappingRule:read	roleMappingRule:read	\N
roleMappingRule:update	roleMappingRule:update	\N
roleMappingRule:delete	roleMappingRule:delete	\N
roleMappingRule:list	roleMappingRule:list	\N
roleMappingRule:*	roleMappingRule:*	\N
*	*	\N
workflow:publish	Publish Workflow	Allows publishing workflows.
workflow:enableRedaction	workflow:enableRedaction	\N
workflow:disableRedaction	workflow:disableRedaction	\N
\.


--
-- Data for Name: secrets_provider_connection; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.secrets_provider_connection (id, "providerKey", type, "encryptedSettings", "isEnabled", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: settings; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.settings (key, value, "loadOnStartup") FROM stdin;
ui.banners.dismissed	["V1"]	t
features.ldap	{"loginEnabled":false,"loginLabel":"","connectionUrl":"","allowUnauthorizedCerts":false,"connectionSecurity":"none","connectionPort":389,"baseDn":"","bindingAdminDn":"","bindingAdminPassword":"","firstNameAttribute":"","lastNameAttribute":"","emailAttribute":"","loginIdAttribute":"","ldapIdAttribute":"","userFilter":"","synchronizationEnabled":false,"synchronizationInterval":60,"searchPageSize":0,"searchTimeout":60,"enforceEmailUniqueness":true}	t
userManagement.isInstanceOwnerSetUp	true	t
instance.firstProductionFailure	{"workflowId":"17940cb9-aeb3-43b9-b404-e422452aa8c4","projectId":"C56wJya6tXcF5Glv","userId":"0fa10d90-9e6d-48bb-93c8-af3f20c5f0b5","timestamp":1781386294789}	f
\.


--
-- Data for Name: shared_credentials; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.shared_credentials ("credentialsId", "projectId", role, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: shared_workflow; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.shared_workflow ("workflowId", "projectId", role, "createdAt", "updatedAt") FROM stdin;
EEp4uU0yD27l6PaH	C56wJya6tXcF5Glv	workflow:owner	2026-06-14 00:22:27.528+00	2026-06-14 00:22:27.528+00
uwQ9vBYyg2J4vpRa	C56wJya6tXcF5Glv	workflow:owner	2026-06-14 00:22:28.03+00	2026-06-14 00:22:28.03+00
\.


--
-- Data for Name: tag_entity; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.tag_entity (name, "createdAt", "updatedAt", id) FROM stdin;
\.


--
-- Data for Name: test_case_execution; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.test_case_execution (id, "testRunId", "executionId", status, "runAt", "completedAt", "errorCode", "errorDetails", metrics, "createdAt", "updatedAt", inputs, outputs, "runIndex") FROM stdin;
\.


--
-- Data for Name: test_run; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.test_run (id, "workflowId", status, "errorCode", "errorDetails", "runAt", "completedAt", metrics, "createdAt", "updatedAt", "runningInstanceId", "cancelRequested", "workflowVersionId", "evaluationConfigId", "evaluationConfigSnapshot", "collectionId") FROM stdin;
\.


--
-- Data for Name: token_exchange_jti; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.token_exchange_jti (jti, "expiresAt", "createdAt") FROM stdin;
\.


--
-- Data for Name: trusted_key; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.trusted_key ("sourceId", kid, data, "createdAt") FROM stdin;
\.


--
-- Data for Name: trusted_key_source; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.trusted_key_source (id, type, config, status, "lastError", "lastRefreshedAt", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public."user" (id, email, "firstName", "lastName", password, "personalizationAnswers", "createdAt", "updatedAt", settings, disabled, "mfaEnabled", "mfaSecret", "mfaRecoveryCodes", "lastActiveAt", "roleSlug") FROM stdin;
0fa10d90-9e6d-48bb-93c8-af3f20c5f0b5	jokerla23@gmail.com	Кравченко	Антон	$2a$10$1FGyNYUoaRshRtjo8qHdjOnwGwxnWNxsHNmCkOuYHvE4VCQBAyyPe	{"version":"v4","personalization_survey_submitted_at":"2026-06-13T18:15:49.306Z","personalization_survey_n8n_version":"2.25.7"}	2026-06-13 14:21:31.213+00	2026-06-14 00:22:26.298+00	{"userActivated":true,"firstSuccessfulWorkflowId":"9c415889-9078-4e48-a83e-2c7a946bcbfc","userActivatedAt":1781385638582}	f	f	\N	\N	2026-06-14	global:owner
\.


--
-- Data for Name: user_api_keys; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.user_api_keys (id, "userId", label, "apiKey", "createdAt", "updatedAt", scopes, audience, "lastUsedAt") FROM stdin;
n8n-api-key	0fa10d90-9e6d-48bb-93c8-af3f20c5f0b5	Security ERP	n8n-b841a3c7e4e78c60eaad63c1bbdf8061	2026-06-13 21:15:59.673+00	2026-06-13 21:15:59.673+00	\N	public-api	\N
\.


--
-- Data for Name: user_favorites; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.user_favorites (id, "userId", "resourceId", "resourceType") FROM stdin;
\.


--
-- Data for Name: variables; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.variables (key, type, value, id, "projectId") FROM stdin;
\.


--
-- Data for Name: webhook_entity; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.webhook_entity ("webhookPath", method, node, "webhookId", "pathLength", "workflowId") FROM stdin;
new-ticket	POST	Webhook	\N	\N	EEp4uU0yD27l6PaH
emergency-ticket	POST	Webhook	\N	\N	uwQ9vBYyg2J4vpRa
\.


--
-- Data for Name: workflow_builder_session; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.workflow_builder_session (id, "workflowId", "userId", messages, "previousSummary", "createdAt", "updatedAt", "activeVersionCardId", "resumeAfterRestoreMessageId") FROM stdin;
\.


--
-- Data for Name: workflow_dependency; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.workflow_dependency (id, "workflowId", "workflowVersionId", "dependencyType", "dependencyKey", "dependencyInfo", "indexVersionId", "createdAt", "publishedVersionId") FROM stdin;
614	EEp4uU0yD27l6PaH	1	nodeType	n8n-nodes-base.webhook	{"nodeId":"694b9c98-d55c-4f81-ba2b-7eb6979e0f8a","nodeVersion":1}	1	2026-06-14 00:22:27.593+00	\N
615	EEp4uU0yD27l6PaH	1	webhookPath	new-ticket	{"nodeId":"694b9c98-d55c-4f81-ba2b-7eb6979e0f8a","nodeVersion":1}	1	2026-06-14 00:22:27.593+00	\N
616	EEp4uU0yD27l6PaH	1	nodeType	n8n-nodes-base.httpRequest	{"nodeId":"7e6b7873-c237-46db-bfd2-d381027262f7","nodeVersion":4}	1	2026-06-14 00:22:27.593+00	\N
617	EEp4uU0yD27l6PaH	1	nodeType	n8n-nodes-base.webhook	{"nodeId":"694b9c98-d55c-4f81-ba2b-7eb6979e0f8a","nodeVersion":1}	1	2026-06-14 00:22:27.962+00	16bee57f-3623-4784-b59d-c9d03ff65a48
618	EEp4uU0yD27l6PaH	1	webhookPath	new-ticket	{"nodeId":"694b9c98-d55c-4f81-ba2b-7eb6979e0f8a","nodeVersion":1}	1	2026-06-14 00:22:27.962+00	16bee57f-3623-4784-b59d-c9d03ff65a48
619	EEp4uU0yD27l6PaH	1	nodeType	n8n-nodes-base.httpRequest	{"nodeId":"7e6b7873-c237-46db-bfd2-d381027262f7","nodeVersion":4}	1	2026-06-14 00:22:27.962+00	16bee57f-3623-4784-b59d-c9d03ff65a48
620	uwQ9vBYyg2J4vpRa	1	nodeType	n8n-nodes-base.webhook	{"nodeId":"c0b785cb-e909-462d-8c2c-dee14e67a8be","nodeVersion":1}	1	2026-06-14 00:22:28.064+00	\N
621	uwQ9vBYyg2J4vpRa	1	webhookPath	emergency-ticket	{"nodeId":"c0b785cb-e909-462d-8c2c-dee14e67a8be","nodeVersion":1}	1	2026-06-14 00:22:28.064+00	\N
622	uwQ9vBYyg2J4vpRa	1	nodeType	n8n-nodes-base.httpRequest	{"nodeId":"38457ca6-7f94-4d47-b5e5-677a6c694de2","nodeVersion":4}	1	2026-06-14 00:22:28.064+00	\N
623	uwQ9vBYyg2J4vpRa	1	nodeType	n8n-nodes-base.webhook	{"nodeId":"c0b785cb-e909-462d-8c2c-dee14e67a8be","nodeVersion":1}	1	2026-06-14 00:22:28.308+00	78d66578-16a0-4c18-95ac-ef4d27505af5
624	uwQ9vBYyg2J4vpRa	1	webhookPath	emergency-ticket	{"nodeId":"c0b785cb-e909-462d-8c2c-dee14e67a8be","nodeVersion":1}	1	2026-06-14 00:22:28.308+00	78d66578-16a0-4c18-95ac-ef4d27505af5
625	uwQ9vBYyg2J4vpRa	1	nodeType	n8n-nodes-base.httpRequest	{"nodeId":"38457ca6-7f94-4d47-b5e5-677a6c694de2","nodeVersion":4}	1	2026-06-14 00:22:28.308+00	78d66578-16a0-4c18-95ac-ef4d27505af5
\.


--
-- Data for Name: workflow_entity; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.workflow_entity (name, active, nodes, connections, "createdAt", "updatedAt", settings, "staticData", "pinData", "versionId", "triggerCount", id, meta, "parentFolderId", "isArchived", "versionCounter", description, "activeVersionId", "nodeGroups", "sourceWorkflowId") FROM stdin;
WF-03: Нова заявка	t	[{"parameters":{"httpMethod":"POST","path":"new-ticket","responseMode":"onReceived"},"name":"Webhook","type":"n8n-nodes-base.webhook","typeVersion":1,"position":[250,300],"id":"694b9c98-d55c-4f81-ba2b-7eb6979e0f8a","webhookId":"8e2e3da5-6a55-4b2e-93c4-22f58f259544"},{"parameters":{"method":"POST","url":"https://api.telegram.org/bot8718935753:AAFX_Jbc_wkQ6MSHX1p5SkU0NEFkPSWB7HY/sendMessage","sendBody":true,"bodyParameters":{"parameters":[{"name":"chat_id","value":"291657218"},{"name":"text","value":"📋 Нова заявка\\n\\n{{ $json.body.ticket_number }}: {{ $json.body.title }}\\nПріоритет: {{ $json.body.priority }}"}]},"options":{}},"name":"Send Telegram","type":"n8n-nodes-base.httpRequest","typeVersion":4,"position":[500,300],"id":"7e6b7873-c237-46db-bfd2-d381027262f7"}]	{"Webhook":{"main":[[{"node":"Send Telegram","type":"main","index":0}]]}}	2026-06-14 00:22:27.528+00	2026-06-14 00:22:27.528+00	\N	\N	\N	16bee57f-3623-4784-b59d-c9d03ff65a48	1	EEp4uU0yD27l6PaH	\N	\N	f	1	\N	16bee57f-3623-4784-b59d-c9d03ff65a48	[]	\N
WF-05: Emergency	t	[{"parameters":{"httpMethod":"POST","path":"emergency-ticket","responseMode":"onReceived"},"name":"Webhook","type":"n8n-nodes-base.webhook","typeVersion":1,"position":[250,300],"id":"c0b785cb-e909-462d-8c2c-dee14e67a8be","webhookId":"071023ab-803a-4746-ba82-53f4e91fc146"},{"parameters":{"method":"POST","url":"https://api.telegram.org/bot8718935753:AAFX_Jbc_wkQ6MSHX1p5SkU0NEFkPSWB7HY/sendMessage","sendBody":true,"bodyParameters":{"parameters":[{"name":"chat_id","value":"291657218"},{"name":"text","value":"🚨 ЕКСТРЕНА!\\n\\n{{ $json.body.ticket_number }}: {{ $json.body.title }}\\n{{ $json.body.address }}"}]},"options":{}},"name":"Send Telegram","type":"n8n-nodes-base.httpRequest","typeVersion":4,"position":[500,300],"id":"38457ca6-7f94-4d47-b5e5-677a6c694de2"}]	{"Webhook":{"main":[[{"node":"Send Telegram","type":"main","index":0}]]}}	2026-06-14 00:22:28.03+00	2026-06-14 00:22:28.03+00	\N	\N	\N	78d66578-16a0-4c18-95ac-ef4d27505af5	1	uwQ9vBYyg2J4vpRa	\N	\N	f	1	\N	78d66578-16a0-4c18-95ac-ef4d27505af5	[]	\N
\.


--
-- Data for Name: workflow_history; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.workflow_history ("versionId", "workflowId", authors, "createdAt", "updatedAt", nodes, connections, name, autosaved, description, "nodeGroups") FROM stdin;
16bee57f-3623-4784-b59d-c9d03ff65a48	EEp4uU0yD27l6PaH	Кравченко Антон	2026-06-14 00:22:27.528+00	2026-06-14 00:22:27.528+00	[{"parameters":{"httpMethod":"POST","path":"new-ticket","responseMode":"onReceived"},"name":"Webhook","type":"n8n-nodes-base.webhook","typeVersion":1,"position":[250,300],"id":"694b9c98-d55c-4f81-ba2b-7eb6979e0f8a","webhookId":"8e2e3da5-6a55-4b2e-93c4-22f58f259544"},{"parameters":{"method":"POST","url":"https://api.telegram.org/bot8718935753:AAFX_Jbc_wkQ6MSHX1p5SkU0NEFkPSWB7HY/sendMessage","sendBody":true,"bodyParameters":{"parameters":[{"name":"chat_id","value":"291657218"},{"name":"text","value":"📋 Нова заявка\\n\\n{{ $json.body.ticket_number }}: {{ $json.body.title }}\\nПріоритет: {{ $json.body.priority }}"}]},"options":{}},"name":"Send Telegram","type":"n8n-nodes-base.httpRequest","typeVersion":4,"position":[500,300],"id":"7e6b7873-c237-46db-bfd2-d381027262f7"}]	{"Webhook":{"main":[[{"node":"Send Telegram","type":"main","index":0}]]}}	\N	f	\N	[]
78d66578-16a0-4c18-95ac-ef4d27505af5	uwQ9vBYyg2J4vpRa	Кравченко Антон	2026-06-14 00:22:28.03+00	2026-06-14 00:22:28.03+00	[{"parameters":{"httpMethod":"POST","path":"emergency-ticket","responseMode":"onReceived"},"name":"Webhook","type":"n8n-nodes-base.webhook","typeVersion":1,"position":[250,300],"id":"c0b785cb-e909-462d-8c2c-dee14e67a8be","webhookId":"071023ab-803a-4746-ba82-53f4e91fc146"},{"parameters":{"method":"POST","url":"https://api.telegram.org/bot8718935753:AAFX_Jbc_wkQ6MSHX1p5SkU0NEFkPSWB7HY/sendMessage","sendBody":true,"bodyParameters":{"parameters":[{"name":"chat_id","value":"291657218"},{"name":"text","value":"🚨 ЕКСТРЕНА!\\n\\n{{ $json.body.ticket_number }}: {{ $json.body.title }}\\n{{ $json.body.address }}"}]},"options":{}},"name":"Send Telegram","type":"n8n-nodes-base.httpRequest","typeVersion":4,"position":[500,300],"id":"38457ca6-7f94-4d47-b5e5-677a6c694de2"}]	{"Webhook":{"main":[[{"node":"Send Telegram","type":"main","index":0}]]}}	\N	f	\N	[]
\.


--
-- Data for Name: workflow_publication_outbox; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.workflow_publication_outbox (id, "workflowId", "publishedVersionId", status, "errorMessage", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: workflow_publish_history; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.workflow_publish_history (id, "workflowId", "versionId", event, "userId", "createdAt") FROM stdin;
189	EEp4uU0yD27l6PaH	16bee57f-3623-4784-b59d-c9d03ff65a48	activated	0fa10d90-9e6d-48bb-93c8-af3f20c5f0b5	2026-06-14 00:22:27.948+00
190	uwQ9vBYyg2J4vpRa	78d66578-16a0-4c18-95ac-ef4d27505af5	activated	0fa10d90-9e6d-48bb-93c8-af3f20c5f0b5	2026-06-14 00:22:28.301+00
\.


--
-- Data for Name: workflow_published_version; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.workflow_published_version ("workflowId", "publishedVersionId", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: workflow_statistics; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.workflow_statistics (count, "latestEvent", name, "workflowId", "rootCount", id, "workflowName") FROM stdin;
1	2026-06-13 21:20:38.074+00	data_loaded	17940cb9-aeb3-43b9-b404-e422452aa8c4	1	1	\N
1	2026-06-13 21:20:38.538+00	production_success	17940cb9-aeb3-43b9-b404-e422452aa8c4	1	2	WF-01: Новий Lead
1	2026-06-13 21:20:38.541+00	data_loaded	9c415889-9078-4e48-a83e-2c7a946bcbfc	1	3	\N
1	2026-06-13 21:20:38.609+00	production_success	9c415889-9078-4e48-a83e-2c7a946bcbfc	1	4	WF-03: Нова заявка
1	2026-06-13 21:31:34.954+00	production_error	17940cb9-aeb3-43b9-b404-e422452aa8c4	1	5	WF-01: Новий Lead
1	2026-06-13 22:05:19.01+00	data_loaded	dpjqAm2gRoUU8fY4	1	6	\N
1	2026-06-13 22:05:19.665+00	production_error	dpjqAm2gRoUU8fY4	1	7	WF-01: Новий Lead (API)
1	2026-06-13 22:05:53.508+00	data_loaded	jb5IgnLhDNsb2Mgc	1	8	\N
1	2026-06-13 22:05:53.61+00	data_loaded	rf086uKVvAPV38Th	1	9	\N
1	2026-06-13 22:05:53.701+00	data_loaded	MJoUgYHomlauVxcK	1	10	\N
2	2026-06-13 22:38:53.083+00	production_error	jb5IgnLhDNsb2Mgc	2	11	WF-01: Новий Lead
3	2026-06-13 22:38:53.165+00	production_error	rf086uKVvAPV38Th	3	12	WF-03: Нова заявка
2	2026-06-13 22:38:53.218+00	production_error	MJoUgYHomlauVxcK	2	13	WF-05: Emergency
1	2026-06-13 22:42:22.798+00	data_loaded	dfosC7MFuwNvrg8Q	1	18	\N
1	2026-06-13 22:42:23.238+00	production_error	dfosC7MFuwNvrg8Q	1	19	WF-01: Новий Lead
1	2026-06-13 23:03:20.743+00	data_loaded	nKZ0dlANNsFKal4B	1	20	\N
3	2026-06-13 23:06:08.301+00	production_error	nKZ0dlANNsFKal4B	3	21	WF-03: Нова заявка
1	2026-06-13 23:07:21.768+00	data_loaded	HjJj0OJHLZdO8omb	1	24	\N
1	2026-06-13 23:07:21.859+00	data_loaded	3RcJ0od26kWJ1ZPZ	1	25	\N
1	2026-06-13 23:07:21.914+00	data_loaded	WRGkn99zo8XpxYiC	1	26	\N
1	2026-06-13 23:07:22.178+00	production_error	HjJj0OJHLZdO8omb	1	27	WF-01: Новий Lead
1	2026-06-13 23:07:22.228+00	production_error	WRGkn99zo8XpxYiC	1	29	WF-05: Emergency
5	2026-06-13 23:11:57.542+00	production_error	3RcJ0od26kWJ1ZPZ	5	28	WF-03: Нова заявка
1	2026-06-13 23:13:17.6+00	data_loaded	bPQLYVp9RO3Kb2O1	1	34	\N
3	2026-06-13 23:16:22.655+00	production_error	bPQLYVp9RO3Kb2O1	3	35	WF-03: Нова заявка
1	2026-06-13 23:16:47.601+00	data_loaded	7EBcbqlHTgQAzqtD	1	38	\N
2	2026-06-13 23:16:47.899+00	production_error	7EBcbqlHTgQAzqtD	2	39	WF-04: SLA Breach
1	2026-06-13 23:17:59.299+00	data_loaded	90xGt1yA37ob6cfG	1	41	\N
1	2026-06-13 23:18:00.131+00	production_error	90xGt1yA37ob6cfG	1	42	Test Telegram
1	2026-06-13 23:21:31.695+00	production_success	90xGt1yA37ob6cfG	1	43	Test Telegram
1	2026-06-13 23:22:12.452+00	data_loaded	44zuTb7KRXseVriD	1	44	\N
1	2026-06-13 23:22:12.661+00	production_error	44zuTb7KRXseVriD	1	45	WF-03: Нова заявка
1	2026-06-13 23:24:40.241+00	data_loaded	aNtCmbpqSFUxKzKN	1	46	\N
2	2026-06-13 23:26:06.558+00	production_error	aNtCmbpqSFUxKzKN	2	47	Test Ticket
1	2026-06-13 23:27:17.011+00	data_loaded	pdJMv8vqb68cYQOj	1	49	\N
1	2026-06-13 23:27:17.453+00	production_error	pdJMv8vqb68cYQOj	1	50	Test Ticket
1	2026-06-14 00:22:33.504+00	data_loaded	EEp4uU0yD27l6PaH	1	51	\N
1	2026-06-14 00:22:33.877+00	production_success	EEp4uU0yD27l6PaH	1	52	WF-03: Нова заявка
\.


--
-- Data for Name: workflows_tags; Type: TABLE DATA; Schema: public; Owner: integration_user
--

COPY public.workflows_tags ("workflowId", "tagId") FROM stdin;
\.


--
-- Name: auth_provider_sync_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: integration_user
--

SELECT pg_catalog.setval('public.auth_provider_sync_history_id_seq', 1, false);


--
-- Name: credential_dependency_id_seq; Type: SEQUENCE SET; Schema: public; Owner: integration_user
--

SELECT pg_catalog.setval('public.credential_dependency_id_seq', 1, false);


--
-- Name: execution_annotations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: integration_user
--

SELECT pg_catalog.setval('public.execution_annotations_id_seq', 1, false);


--
-- Name: execution_entity_id_seq; Type: SEQUENCE SET; Schema: public; Owner: integration_user
--

SELECT pg_catalog.setval('public.execution_entity_id_seq', 34, true);


--
-- Name: execution_metadata_temp_id_seq; Type: SEQUENCE SET; Schema: public; Owner: integration_user
--

SELECT pg_catalog.setval('public.execution_metadata_temp_id_seq', 1, false);


--
-- Name: insights_by_period_id_seq; Type: SEQUENCE SET; Schema: public; Owner: integration_user
--

SELECT pg_catalog.setval('public.insights_by_period_id_seq', 1, false);


--
-- Name: insights_metadata_metaId_seq; Type: SEQUENCE SET; Schema: public; Owner: integration_user
--

SELECT pg_catalog.setval('public."insights_metadata_metaId_seq"', 27, true);


--
-- Name: insights_raw_id_seq; Type: SEQUENCE SET; Schema: public; Owner: integration_user
--

SELECT pg_catalog.setval('public.insights_raw_id_seq', 72, true);


--
-- Name: instance_version_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: integration_user
--

SELECT pg_catalog.setval('public.instance_version_history_id_seq', 1, true);


--
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: integration_user
--

SELECT pg_catalog.setval('public.migrations_id_seq', 200, true);


--
-- Name: oauth_user_consents_id_seq; Type: SEQUENCE SET; Schema: public; Owner: integration_user
--

SELECT pg_catalog.setval('public.oauth_user_consents_id_seq', 1, false);


--
-- Name: secrets_provider_connection_id_seq; Type: SEQUENCE SET; Schema: public; Owner: integration_user
--

SELECT pg_catalog.setval('public.secrets_provider_connection_id_seq', 1, false);


--
-- Name: user_favorites_id_seq; Type: SEQUENCE SET; Schema: public; Owner: integration_user
--

SELECT pg_catalog.setval('public.user_favorites_id_seq', 1, false);


--
-- Name: workflow_dependency_id_seq; Type: SEQUENCE SET; Schema: public; Owner: integration_user
--

SELECT pg_catalog.setval('public.workflow_dependency_id_seq', 625, true);


--
-- Name: workflow_publication_outbox_id_seq; Type: SEQUENCE SET; Schema: public; Owner: integration_user
--

SELECT pg_catalog.setval('public.workflow_publication_outbox_id_seq', 1, false);


--
-- Name: workflow_publish_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: integration_user
--

SELECT pg_catalog.setval('public.workflow_publish_history_id_seq', 190, true);


--
-- Name: workflow_statistics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: integration_user
--

SELECT pg_catalog.setval('public.workflow_statistics_id_seq', 52, true);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: buildings buildings_pkey; Type: CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.buildings
    ADD CONSTRAINT buildings_pkey PRIMARY KEY (id);


--
-- Name: equipment equipment_pkey; Type: CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.equipment
    ADD CONSTRAINT equipment_pkey PRIMARY KEY (id);


--
-- Name: equipment_relations equipment_relations_pkey; Type: CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.equipment_relations
    ADD CONSTRAINT equipment_relations_pkey PRIMARY KEY (id);


--
-- Name: equipment_types equipment_types_code_key; Type: CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.equipment_types
    ADD CONSTRAINT equipment_types_code_key UNIQUE (code);


--
-- Name: equipment_types equipment_types_pkey; Type: CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.equipment_types
    ADD CONSTRAINT equipment_types_pkey PRIMARY KEY (id);


--
-- Name: floors floors_pkey; Type: CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.floors
    ADD CONSTRAINT floors_pkey PRIMARY KEY (id);


--
-- Name: objects objects_pkey; Type: CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.objects
    ADD CONSTRAINT objects_pkey PRIMARY KEY (id);


--
-- Name: rooms rooms_pkey; Type: CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.rooms
    ADD CONSTRAINT rooms_pkey PRIMARY KEY (id);


--
-- Name: vendors vendors_code_key; Type: CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.vendors
    ADD CONSTRAINT vendors_code_key UNIQUE (code);


--
-- Name: vendors vendors_name_key; Type: CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.vendors
    ADD CONSTRAINT vendors_name_key UNIQUE (name);


--
-- Name: vendors vendors_pkey; Type: CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.vendors
    ADD CONSTRAINT vendors_pkey PRIMARY KEY (id);


--
-- Name: maintenance_plans maintenance_plans_pkey; Type: CONSTRAINT; Schema: fsm; Owner: fsm_user
--

ALTER TABLE ONLY fsm.maintenance_plans
    ADD CONSTRAINT maintenance_plans_pkey PRIMARY KEY (id);


--
-- Name: sla_events sla_events_pkey; Type: CONSTRAINT; Schema: fsm; Owner: fsm_user
--

ALTER TABLE ONLY fsm.sla_events
    ADD CONSTRAINT sla_events_pkey PRIMARY KEY (id);


--
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: fsm; Owner: fsm_user
--

ALTER TABLE ONLY fsm.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);


--
-- Name: visit_materials visit_materials_pkey; Type: CONSTRAINT; Schema: fsm; Owner: fsm_user
--

ALTER TABLE ONLY fsm.visit_materials
    ADD CONSTRAINT visit_materials_pkey PRIMARY KEY (id);


--
-- Name: visit_photos visit_photos_pkey; Type: CONSTRAINT; Schema: fsm; Owner: fsm_user
--

ALTER TABLE ONLY fsm.visit_photos
    ADD CONSTRAINT visit_photos_pkey PRIMARY KEY (id);


--
-- Name: visits visits_pkey; Type: CONSTRAINT; Schema: fsm; Owner: fsm_user
--

ALTER TABLE ONLY fsm.visits
    ADD CONSTRAINT visits_pkey PRIMARY KEY (id);


--
-- Name: visits visits_visit_number_key; Type: CONSTRAINT; Schema: fsm; Owner: fsm_user
--

ALTER TABLE ONLY fsm.visits
    ADD CONSTRAINT visits_visit_number_key UNIQUE (visit_number);


--
-- Name: warranty_cases warranty_cases_case_number_key; Type: CONSTRAINT; Schema: fsm; Owner: fsm_user
--

ALTER TABLE ONLY fsm.warranty_cases
    ADD CONSTRAINT warranty_cases_case_number_key UNIQUE (case_number);


--
-- Name: warranty_cases warranty_cases_pkey; Type: CONSTRAINT; Schema: fsm; Owner: fsm_user
--

ALTER TABLE ONLY fsm.warranty_cases
    ADD CONSTRAINT warranty_cases_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: integration; Owner: postgres
--

ALTER TABLE ONLY integration.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: test_run PK_011c050f566e9db509a0fadb9b9; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.test_run
    ADD CONSTRAINT "PK_011c050f566e9db509a0fadb9b9" PRIMARY KEY (id);


--
-- Name: project_secrets_provider_access PK_0402b7fcec5415246656f102f83; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.project_secrets_provider_access
    ADD CONSTRAINT "PK_0402b7fcec5415246656f102f83" PRIMARY KEY ("secretsProviderConnectionId", "projectId");


--
-- Name: installed_packages PK_08cc9197c39b028c1e9beca225940576fd1a5804; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.installed_packages
    ADD CONSTRAINT "PK_08cc9197c39b028c1e9beca225940576fd1a5804" PRIMARY KEY ("packageName");


--
-- Name: instance_ai_run_snapshots PK_0a5fc9690a84950ebf1416fb146; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_run_snapshots
    ADD CONSTRAINT "PK_0a5fc9690a84950ebf1416fb146" PRIMARY KEY ("threadId", "runId");


--
-- Name: mcp_registry_server PK_12fd89a1fb8489513b0a91f5d31; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.mcp_registry_server
    ADD CONSTRAINT "PK_12fd89a1fb8489513b0a91f5d31" PRIMARY KEY (slug);


--
-- Name: instance_ai_messages PK_156c6f287225e9befe0181bb02b; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_messages
    ADD CONSTRAINT "PK_156c6f287225e9befe0181bb02b" PRIMARY KEY (id);


--
-- Name: agent_task_definition PK_1756c11c637903e97629a7a784a; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agent_task_definition
    ADD CONSTRAINT "PK_1756c11c637903e97629a7a784a" PRIMARY KEY (id);


--
-- Name: execution_metadata PK_17a0b6284f8d626aae88e1c16e4; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.execution_metadata
    ADD CONSTRAINT "PK_17a0b6284f8d626aae88e1c16e4" PRIMARY KEY (id);


--
-- Name: role_mapping_rule_project PK_198c5b5aea509d139274efcaf9a; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.role_mapping_rule_project
    ADD CONSTRAINT "PK_198c5b5aea509d139274efcaf9a" PRIMARY KEY ("roleMappingRuleId", "projectId");


--
-- Name: project_relation PK_1caaa312a5d7184a003be0f0cb6; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.project_relation
    ADD CONSTRAINT "PK_1caaa312a5d7184a003be0f0cb6" PRIMARY KEY ("projectId", "userId");


--
-- Name: chat_hub_sessions PK_1eafef1273c70e4464fec703412; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_sessions
    ADD CONSTRAINT "PK_1eafef1273c70e4464fec703412" PRIMARY KEY (id);


--
-- Name: agent_task_snapshot PK_2142a8bcda2360c3c5e34f82640; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agent_task_snapshot
    ADD CONSTRAINT "PK_2142a8bcda2360c3c5e34f82640" PRIMARY KEY ("versionId", "taskId");


--
-- Name: instance_ai_iteration_logs PK_21c2b214b44bc6c34a6d3551c90; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_iteration_logs
    ADD CONSTRAINT "PK_21c2b214b44bc6c34a6d3551c90" PRIMARY KEY (id);


--
-- Name: agent_execution_threads PK_22373dbf6ba6929d8ac50093309; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agent_execution_threads
    ADD CONSTRAINT "PK_22373dbf6ba6929d8ac50093309" PRIMARY KEY (id);


--
-- Name: instance_ai_pending_confirmations PK_25c38179c8d45095b168adfff80; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_pending_confirmations
    ADD CONSTRAINT "PK_25c38179c8d45095b168adfff80" PRIMARY KEY ("requestId");


--
-- Name: agents_memory_entry_sources PK_278f05e98e74baaaa93f52b4bab; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_memory_entry_sources
    ADD CONSTRAINT "PK_278f05e98e74baaaa93f52b4bab" PRIMARY KEY (id);


--
-- Name: folder_tag PK_27e4e00852f6b06a925a4d83a3e; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.folder_tag
    ADD CONSTRAINT "PK_27e4e00852f6b06a925a4d83a3e" PRIMARY KEY ("folderId", "tagId");


--
-- Name: instance_ai_threads PK_35575100e45cdedeb89ae0643e9; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_threads
    ADD CONSTRAINT "PK_35575100e45cdedeb89ae0643e9" PRIMARY KEY (id);


--
-- Name: role PK_35c9b140caaf6da09cfabb0d675; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT "PK_35c9b140caaf6da09cfabb0d675" PRIMARY KEY (slug);


--
-- Name: secrets_provider_connection PK_4350ae85e76f9ba7df1370acb5d; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.secrets_provider_connection
    ADD CONSTRAINT "PK_4350ae85e76f9ba7df1370acb5d" PRIMARY KEY (id);


--
-- Name: instance_ai_resources PK_45b5b0b6f715dae4292b86603d8; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_resources
    ADD CONSTRAINT "PK_45b5b0b6f715dae4292b86603d8" PRIMARY KEY (id);


--
-- Name: agents_threads PK_4a3feb0a13ffe315c009cce64e5; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_threads
    ADD CONSTRAINT "PK_4a3feb0a13ffe315c009cce64e5" PRIMARY KEY (id);


--
-- Name: project PK_4d68b1358bb5b766d3e78f32f57; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT "PK_4d68b1358bb5b766d3e78f32f57" PRIMARY KEY (id);


--
-- Name: instance_ai_observations PK_4d9b514cdf0f0b577650caf2ac2; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_observations
    ADD CONSTRAINT "PK_4d9b514cdf0f0b577650caf2ac2" PRIMARY KEY (id);


--
-- Name: agent_checkpoints PK_50a27cbafa6806c9b162304b5fd; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agent_checkpoints
    ADD CONSTRAINT "PK_50a27cbafa6806c9b162304b5fd" PRIMARY KEY ("runId");


--
-- Name: dynamic_credential_entry PK_5135ffcabecad4727ff6b9b803d; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.dynamic_credential_entry
    ADD CONSTRAINT "PK_5135ffcabecad4727ff6b9b803d" PRIMARY KEY (credential_id, subject_id, resolver_id);


--
-- Name: workflow_dependency PK_52325e34cd7a2f0f67b0f3cad65; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_dependency
    ADD CONSTRAINT "PK_52325e34cd7a2f0f67b0f3cad65" PRIMARY KEY (id);


--
-- Name: instance_ai_checkpoints PK_5315a45f0846d1f9d128c18a2ed; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_checkpoints
    ADD CONSTRAINT "PK_5315a45f0846d1f9d128c18a2ed" PRIMARY KEY (key);


--
-- Name: invalid_auth_token PK_5779069b7235b256d91f7af1a15; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.invalid_auth_token
    ADD CONSTRAINT "PK_5779069b7235b256d91f7af1a15" PRIMARY KEY (token);


--
-- Name: evaluation_config PK_59c14dccf8989df94070c2dcfda; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.evaluation_config
    ADD CONSTRAINT "PK_59c14dccf8989df94070c2dcfda" PRIMARY KEY (id);


--
-- Name: instance_ai_observation_cursors PK_5b6319b2e9a37c1064a72428f9a; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_observation_cursors
    ADD CONSTRAINT "PK_5b6319b2e9a37c1064a72428f9a" PRIMARY KEY ("observationScopeId");


--
-- Name: shared_workflow PK_5ba87620386b847201c9531c58f; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.shared_workflow
    ADD CONSTRAINT "PK_5ba87620386b847201c9531c58f" PRIMARY KEY ("workflowId", "projectId");


--
-- Name: workflow_published_version PK_5c76fb7ee939fe2530374d3f75a; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_published_version
    ADD CONSTRAINT "PK_5c76fb7ee939fe2530374d3f75a" PRIMARY KEY ("workflowId");


--
-- Name: folder PK_6278a41a706740c94c02e288df8; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.folder
    ADD CONSTRAINT "PK_6278a41a706740c94c02e288df8" PRIMARY KEY (id);


--
-- Name: agent_history PK_65ffcfe7a8e112fb826311fb092; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agent_history
    ADD CONSTRAINT "PK_65ffcfe7a8e112fb826311fb092" PRIMARY KEY ("versionId");


--
-- Name: data_table_column PK_673cb121ee4a8a5e27850c72c51; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.data_table_column
    ADD CONSTRAINT "PK_673cb121ee4a8a5e27850c72c51" PRIMARY KEY (id);


--
-- Name: agent_files PK_692920e59217af7d124cd95106f; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agent_files
    ADD CONSTRAINT "PK_692920e59217af7d124cd95106f" PRIMARY KEY (id);


--
-- Name: chat_hub_tools PK_696d26426c704fba79b2c195ef5; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_tools
    ADD CONSTRAINT "PK_696d26426c704fba79b2c195ef5" PRIMARY KEY (id);


--
-- Name: annotation_tag_entity PK_69dfa041592c30bbc0d4b84aa00; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.annotation_tag_entity
    ADD CONSTRAINT "PK_69dfa041592c30bbc0d4b84aa00" PRIMARY KEY (id);


--
-- Name: user_favorites PK_6c472a19a7423cfbbf6b7c75939; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT "PK_6c472a19a7423cfbbf6b7c75939" PRIMARY KEY (id);


--
-- Name: instance_ai_observational_memory PK_7192dd00cddba039bf1d3e6a098; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_observational_memory
    ADD CONSTRAINT "PK_7192dd00cddba039bf1d3e6a098" PRIMARY KEY (id);


--
-- Name: oauth_refresh_tokens PK_74abaed0b30711b6532598b0392; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.oauth_refresh_tokens
    ADD CONSTRAINT "PK_74abaed0b30711b6532598b0392" PRIMARY KEY (token);


--
-- Name: dynamic_credential_user_entry PK_74f548e633abc66dc27c8f0ca77; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.dynamic_credential_user_entry
    ADD CONSTRAINT "PK_74f548e633abc66dc27c8f0ca77" PRIMARY KEY ("credentialId", "userId", "resolverId");


--
-- Name: chat_hub_messages PK_7704a5add6baed43eef835f0bfb; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "PK_7704a5add6baed43eef835f0bfb" PRIMARY KEY (id);


--
-- Name: execution_annotations PK_7afcf93ffa20c4252869a7c6a23; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.execution_annotations
    ADD CONSTRAINT "PK_7afcf93ffa20c4252869a7c6a23" PRIMARY KEY (id);


--
-- Name: agents_observation_locks PK_7e2e315162ac3d80587e15ac2c3; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_observation_locks
    ADD CONSTRAINT "PK_7e2e315162ac3d80587e15ac2c3" PRIMARY KEY ("agentId", "observationScopeId", "taskKind");


--
-- Name: credential_dependency PK_80212729ed0ffa0709417ab28f4; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.credential_dependency
    ADD CONSTRAINT "PK_80212729ed0ffa0709417ab28f4" PRIMARY KEY (id);


--
-- Name: agents_messages PK_81020dc608dfb0af1ede386d907; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_messages
    ADD CONSTRAINT "PK_81020dc608dfb0af1ede386d907" PRIMARY KEY (id);


--
-- Name: ai_builder_temporary_workflow PK_85a87a1ba0f61999fe11dc56325; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.ai_builder_temporary_workflow
    ADD CONSTRAINT "PK_85a87a1ba0f61999fe11dc56325" PRIMARY KEY ("workflowId");


--
-- Name: oauth_user_consents PK_85b9ada746802c8993103470f05; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.oauth_user_consents
    ADD CONSTRAINT "PK_85b9ada746802c8993103470f05" PRIMARY KEY (id);


--
-- Name: instance_version_history PK_874f58cb616935bf49d9dbd67e9; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_version_history
    ADD CONSTRAINT "PK_874f58cb616935bf49d9dbd67e9" PRIMARY KEY (id);


--
-- Name: chat_hub_session_tools PK_87aea76ff4c274c4a5ac838ebe3; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_session_tools
    ADD CONSTRAINT "PK_87aea76ff4c274c4a5ac838ebe3" PRIMARY KEY ("sessionId", "toolId");


--
-- Name: migrations PK_8c82d7f526340ab734260ea46be; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT "PK_8c82d7f526340ab734260ea46be" PRIMARY KEY (id);


--
-- Name: installed_nodes PK_8ebd28194e4f792f96b5933423fc439df97d9689; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.installed_nodes
    ADD CONSTRAINT "PK_8ebd28194e4f792f96b5933423fc439df97d9689" PRIMARY KEY (name);


--
-- Name: shared_credentials PK_8ef3a59796a228913f251779cff; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.shared_credentials
    ADD CONSTRAINT "PK_8ef3a59796a228913f251779cff" PRIMARY KEY ("credentialsId", "projectId");


--
-- Name: test_case_execution PK_90c121f77a78a6580e94b794bce; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.test_case_execution
    ADD CONSTRAINT "PK_90c121f77a78a6580e94b794bce" PRIMARY KEY (id);


--
-- Name: instance_ai_workflow_snapshots PK_93f2696eb321dfe1d7defe7073f; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_workflow_snapshots
    ADD CONSTRAINT "PK_93f2696eb321dfe1d7defe7073f" PRIMARY KEY ("runId", "workflowName");


--
-- Name: deployment_key PK_94bb7aeb5def5a0284a5fe9f9a0; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.deployment_key
    ADD CONSTRAINT "PK_94bb7aeb5def5a0284a5fe9f9a0" PRIMARY KEY (id);


--
-- Name: user_api_keys PK_978fa5caa3468f463dac9d92e69; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.user_api_keys
    ADD CONSTRAINT "PK_978fa5caa3468f463dac9d92e69" PRIMARY KEY (id);


--
-- Name: execution_annotation_tags PK_979ec03d31294cca484be65d11f; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.execution_annotation_tags
    ADD CONSTRAINT "PK_979ec03d31294cca484be65d11f" PRIMARY KEY ("annotationId", "tagId");


--
-- Name: trusted_key_source PK_99e8908ce2c2cdccce487db7fc6; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.trusted_key_source
    ADD CONSTRAINT "PK_99e8908ce2c2cdccce487db7fc6" PRIMARY KEY (id);


--
-- Name: agents_observations PK_9ad319654d12c2649f7caf27135; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_observations
    ADD CONSTRAINT "PK_9ad319654d12c2649f7caf27135" PRIMARY KEY (id);


--
-- Name: agents PK_9c653f28ae19c5884d5baf6a1d9; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT "PK_9c653f28ae19c5884d5baf6a1d9" PRIMARY KEY (id);


--
-- Name: agents_memory_entry_locks PK_a8e0f570d04a174292bea104ae6; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_memory_entry_locks
    ADD CONSTRAINT "PK_a8e0f570d04a174292bea104ae6" PRIMARY KEY ("agentId", "resourceId");


--
-- Name: webhook_entity PK_b21ace2e13596ccd87dc9bf4ea6; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.webhook_entity
    ADD CONSTRAINT "PK_b21ace2e13596ccd87dc9bf4ea6" PRIMARY KEY ("webhookPath", method);


--
-- Name: agents_memory_entry_cursors PK_b31a1d5c009a27f4cc5ef8f102a; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_memory_entry_cursors
    ADD CONSTRAINT "PK_b31a1d5c009a27f4cc5ef8f102a" PRIMARY KEY ("agentId", "observationScopeId");


--
-- Name: workflow_publication_outbox PK_b3e2eeee36a4bd044d56468d311; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_publication_outbox
    ADD CONSTRAINT "PK_b3e2eeee36a4bd044d56468d311" PRIMARY KEY (id);


--
-- Name: insights_by_period PK_b606942249b90cc39b0265f0575; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.insights_by_period
    ADD CONSTRAINT "PK_b606942249b90cc39b0265f0575" PRIMARY KEY (id);


--
-- Name: workflow_history PK_b6572dd6173e4cd06fe79937b58; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_history
    ADD CONSTRAINT "PK_b6572dd6173e4cd06fe79937b58" PRIMARY KEY ("versionId");


--
-- Name: dynamic_credential_resolver PK_b76cfb088dcdaf5275e9980bb64; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.dynamic_credential_resolver
    ADD CONSTRAINT "PK_b76cfb088dcdaf5275e9980bb64" PRIMARY KEY (id);


--
-- Name: agent_execution PK_ba438acc8532addc12d1ef17049; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agent_execution
    ADD CONSTRAINT "PK_ba438acc8532addc12d1ef17049" PRIMARY KEY (id);


--
-- Name: agents_memory_entries PK_bfbc45dc88f66fae4e4b4a15fec; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_memory_entries
    ADD CONSTRAINT "PK_bfbc45dc88f66fae4e4b4a15fec" PRIMARY KEY (id);


--
-- Name: scope PK_bfc45df0481abd7f355d6187da1; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.scope
    ADD CONSTRAINT "PK_bfc45df0481abd7f355d6187da1" PRIMARY KEY (slug);


--
-- Name: oauth_clients PK_c4759172d3431bae6f04e678e0d; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.oauth_clients
    ADD CONSTRAINT "PK_c4759172d3431bae6f04e678e0d" PRIMARY KEY (id);


--
-- Name: workflow_publish_history PK_c788f7caf88e91e365c97d6d04a; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_publish_history
    ADD CONSTRAINT "PK_c788f7caf88e91e365c97d6d04a" PRIMARY KEY (id);


--
-- Name: processed_data PK_ca04b9d8dc72de268fe07a65773; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.processed_data
    ADD CONSTRAINT "PK_ca04b9d8dc72de268fe07a65773" PRIMARY KEY ("workflowId", context);


--
-- Name: chat_hub_agent_tools PK_cc8806fdea48297a7d497035d72; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_agent_tools
    ADD CONSTRAINT "PK_cc8806fdea48297a7d497035d72" PRIMARY KEY ("agentId", "toolId");


--
-- Name: role_mapping_rule PK_d772c8ec1a89b52d31c882bc560; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.role_mapping_rule
    ADD CONSTRAINT "PK_d772c8ec1a89b52d31c882bc560" PRIMARY KEY (id);


--
-- Name: token_exchange_jti PK_d8e8a6f737d530fdd2dd716e89c; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.token_exchange_jti
    ADD CONSTRAINT "PK_d8e8a6f737d530fdd2dd716e89c" PRIMARY KEY (jti);


--
-- Name: settings PK_dc0fe14e6d9943f268e7b119f69ab8bd; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT "PK_dc0fe14e6d9943f268e7b119f69ab8bd" PRIMARY KEY (key);


--
-- Name: trusted_key PK_dc7d93798f3dbb6959f974c97e1; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.trusted_key
    ADD CONSTRAINT "PK_dc7d93798f3dbb6959f974c97e1" PRIMARY KEY ("sourceId", kid);


--
-- Name: oauth_access_tokens PK_dcd71f96a5d5f4bf79e67d322bf; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT "PK_dcd71f96a5d5f4bf79e67d322bf" PRIMARY KEY (token);


--
-- Name: data_table PK_e226d0001b9e6097cbfe70617cb; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.data_table
    ADD CONSTRAINT "PK_e226d0001b9e6097cbfe70617cb" PRIMARY KEY (id);


--
-- Name: workflow_builder_session PK_e69ef0d385986e273423b0e8695; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_builder_session
    ADD CONSTRAINT "PK_e69ef0d385986e273423b0e8695" PRIMARY KEY (id);


--
-- Name: evaluation_collection PK_e720b6efc1e45b878ebb0b2ca30; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.evaluation_collection
    ADD CONSTRAINT "PK_e720b6efc1e45b878ebb0b2ca30" PRIMARY KEY (id);


--
-- Name: user PK_ea8f538c94b6e352418254ed6474a81f; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT "PK_ea8f538c94b6e352418254ed6474a81f" PRIMARY KEY (id);


--
-- Name: agents_observation_cursors PK_eb777ac57ab872d38f8ebd19317; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_observation_cursors
    ADD CONSTRAINT "PK_eb777ac57ab872d38f8ebd19317" PRIMARY KEY ("agentId", "observationScopeId");


--
-- Name: insights_raw PK_ec15125755151e3a7e00e00014f; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.insights_raw
    ADD CONSTRAINT "PK_ec15125755151e3a7e00e00014f" PRIMARY KEY (id);


--
-- Name: chat_hub_agents PK_f39a3b36bbdf0e2979ddb21cf78; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_agents
    ADD CONSTRAINT "PK_f39a3b36bbdf0e2979ddb21cf78" PRIMARY KEY (id);


--
-- Name: insights_metadata PK_f448a94c35218b6208ce20cf5a1; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.insights_metadata
    ADD CONSTRAINT "PK_f448a94c35218b6208ce20cf5a1" PRIMARY KEY ("metaId");


--
-- Name: agent_task_run_lock PK_f593adaf7230e964d3c25deda64; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agent_task_run_lock
    ADD CONSTRAINT "PK_f593adaf7230e964d3c25deda64" PRIMARY KEY ("agentId", "taskId");


--
-- Name: agents_resources PK_fa6b20b2d31a9991529dbf8ef7d; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_resources
    ADD CONSTRAINT "PK_fa6b20b2d31a9991529dbf8ef7d" PRIMARY KEY (id);


--
-- Name: oauth_authorization_codes PK_fb91ab932cfbd694061501cc20f; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.oauth_authorization_codes
    ADD CONSTRAINT "PK_fb91ab932cfbd694061501cc20f" PRIMARY KEY (code);


--
-- Name: binary_data PK_fc3691585b39408bb0551122af6; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.binary_data
    ADD CONSTRAINT "PK_fc3691585b39408bb0551122af6" PRIMARY KEY ("fileId");


--
-- Name: instance_ai_observation_locks PK_fc491dd378b9448655c3c683f85; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_observation_locks
    ADD CONSTRAINT "PK_fc491dd378b9448655c3c683f85" PRIMARY KEY ("observationScopeId", "taskKind");


--
-- Name: role_scope PK_role_scope; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.role_scope
    ADD CONSTRAINT "PK_role_scope" PRIMARY KEY ("roleSlug", "scopeSlug");


--
-- Name: oauth_user_consents UQ_083721d99ce8db4033e2958ebb4; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.oauth_user_consents
    ADD CONSTRAINT "UQ_083721d99ce8db4033e2958ebb4" UNIQUE ("userId", "clientId");


--
-- Name: evaluation_config UQ_3c3c99a712e971835c52292e44c; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.evaluation_config
    ADD CONSTRAINT "UQ_3c3c99a712e971835c52292e44c" UNIQUE ("workflowId", name);


--
-- Name: data_table_column UQ_8082ec4890f892f0bc77473a123; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.data_table_column
    ADD CONSTRAINT "UQ_8082ec4890f892f0bc77473a123" UNIQUE ("dataTableId", name);


--
-- Name: data_table UQ_b23096ef747281ac944d28e8b0d; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.data_table
    ADD CONSTRAINT "UQ_b23096ef747281ac944d28e8b0d" UNIQUE ("projectId", name);


--
-- Name: role_mapping_rule UQ_b33ac896ad3099fc8de36fdc1c4; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.role_mapping_rule
    ADD CONSTRAINT "UQ_b33ac896ad3099fc8de36fdc1c4" UNIQUE (type, "order");


--
-- Name: user_favorites UQ_cf6ae658ead9ffc124723413c65; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT "UQ_cf6ae658ead9ffc124723413c65" UNIQUE ("userId", "resourceId", "resourceType");


--
-- Name: user UQ_e12875dfb3b1d92d7d7c5377e2; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT "UQ_e12875dfb3b1d92d7d7c5377e2" UNIQUE (email);


--
-- Name: workflow_builder_session UQ_ec2aa73632932d485a1d5192ce1; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_builder_session
    ADD CONSTRAINT "UQ_ec2aa73632932d485a1d5192ce1" UNIQUE ("workflowId", "userId");


--
-- Name: auth_identity auth_identity_pkey; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.auth_identity
    ADD CONSTRAINT auth_identity_pkey PRIMARY KEY ("providerId", "providerType");


--
-- Name: auth_provider_sync_history auth_provider_sync_history_pkey; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.auth_provider_sync_history
    ADD CONSTRAINT auth_provider_sync_history_pkey PRIMARY KEY (id);


--
-- Name: credentials_entity credentials_entity_pkey; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.credentials_entity
    ADD CONSTRAINT credentials_entity_pkey PRIMARY KEY (id);


--
-- Name: event_destinations event_destinations_pkey; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.event_destinations
    ADD CONSTRAINT event_destinations_pkey PRIMARY KEY (id);


--
-- Name: execution_data execution_data_pkey; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.execution_data
    ADD CONSTRAINT execution_data_pkey PRIMARY KEY ("executionId");


--
-- Name: execution_entity pk_e3e63bbf986767844bbe1166d4e; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.execution_entity
    ADD CONSTRAINT pk_e3e63bbf986767844bbe1166d4e PRIMARY KEY (id);


--
-- Name: workflows_tags pk_workflows_tags; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflows_tags
    ADD CONSTRAINT pk_workflows_tags PRIMARY KEY ("workflowId", "tagId");


--
-- Name: tag_entity tag_entity_pkey; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.tag_entity
    ADD CONSTRAINT tag_entity_pkey PRIMARY KEY (id);


--
-- Name: variables variables_pkey; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.variables
    ADD CONSTRAINT variables_pkey PRIMARY KEY (id);


--
-- Name: workflow_entity workflow_entity_pkey; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_entity
    ADD CONSTRAINT workflow_entity_pkey PRIMARY KEY (id);


--
-- Name: workflow_statistics workflow_statistics_pkey; Type: CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_statistics
    ADD CONSTRAINT workflow_statistics_pkey PRIMARY KEY (id);


--
-- Name: ix_audit_audit_log_entity_type; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX ix_audit_audit_log_entity_type ON audit.audit_log USING btree (entity_type);


--
-- Name: ix_audit_audit_log_user_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX ix_audit_audit_log_user_id ON audit.audit_log USING btree (user_id);


--
-- Name: ix_cmdb_equipment_equipment_code; Type: INDEX; Schema: cmdb; Owner: cmdb_user
--

CREATE UNIQUE INDEX ix_cmdb_equipment_equipment_code ON cmdb.equipment USING btree (equipment_code);


--
-- Name: ix_cmdb_equipment_object_id; Type: INDEX; Schema: cmdb; Owner: cmdb_user
--

CREATE INDEX ix_cmdb_equipment_object_id ON cmdb.equipment USING btree (object_id);


--
-- Name: ix_cmdb_equipment_serial_number; Type: INDEX; Schema: cmdb; Owner: cmdb_user
--

CREATE UNIQUE INDEX ix_cmdb_equipment_serial_number ON cmdb.equipment USING btree (serial_number);


--
-- Name: ix_cmdb_objects_customer_id; Type: INDEX; Schema: cmdb; Owner: cmdb_user
--

CREATE INDEX ix_cmdb_objects_customer_id ON cmdb.objects USING btree (customer_id);


--
-- Name: ix_cmdb_objects_object_code; Type: INDEX; Schema: cmdb; Owner: cmdb_user
--

CREATE UNIQUE INDEX ix_cmdb_objects_object_code ON cmdb.objects USING btree (object_code);


--
-- Name: ix_fsm_tickets_ticket_number; Type: INDEX; Schema: fsm; Owner: fsm_user
--

CREATE UNIQUE INDEX ix_fsm_tickets_ticket_number ON fsm.tickets USING btree (ticket_number);


--
-- Name: ix_integration_users_email; Type: INDEX; Schema: integration; Owner: postgres
--

CREATE UNIQUE INDEX ix_integration_users_email ON integration.users USING btree (email);


--
-- Name: ix_integration_users_username; Type: INDEX; Schema: integration; Owner: postgres
--

CREATE UNIQUE INDEX ix_integration_users_username ON integration.users USING btree (username);


--
-- Name: IDX_02751202c9a2ad75f2d8e14f5e; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_02751202c9a2ad75f2d8e14f5e" ON public.instance_ai_iteration_logs USING btree ("threadId", "taskKey", "createdAt");


--
-- Name: IDX_0468a9dc35597314e641d4722a; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_0468a9dc35597314e641d4722a" ON public.agent_execution_threads USING btree ("agentId");


--
-- Name: IDX_069e791e428391a5569e7a96b2; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_069e791e428391a5569e7a96b2" ON public.agents_memory_entry_cursors USING btree ("observationScopeId");


--
-- Name: IDX_070b5de842ece9ccdda0d9738b; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_070b5de842ece9ccdda0d9738b" ON public.workflow_publish_history USING btree ("workflowId", "versionId");


--
-- Name: IDX_07cb1e4a302629c5fa5d74d2bb; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_07cb1e4a302629c5fa5d74d2bb" ON public.agents_observations USING btree ("agentId", "observationScopeId", status);


--
-- Name: IDX_0babdf6e3b897a86fe4678355e; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_0babdf6e3b897a86fe4678355e" ON public.instance_ai_pending_confirmations USING btree ("checkpointKey");


--
-- Name: IDX_0d5db648188d338df7fb2a8064; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_0d5db648188d338df7fb2a8064" ON public.instance_ai_observations USING btree ("observationScopeId", status, "createdAt", id);


--
-- Name: IDX_0e2f8bf92a7a9c88b89670f701; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_0e2f8bf92a7a9c88b89670f701" ON public.agent_execution_threads USING btree ("projectId");


--
-- Name: IDX_0edf1226b77ddc525eae493807; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_0edf1226b77ddc525eae493807" ON public.agents_memory_entries USING btree ("supersededBy");


--
-- Name: IDX_127ee1078ffa952bb37b511efa; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_127ee1078ffa952bb37b511efa" ON public.agents_observations USING btree ("supersededBy");


--
-- Name: IDX_1443a75e59adbfb796071d6639; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_1443a75e59adbfb796071d6639" ON public.agents_memory_entries USING btree ("resourceId");


--
-- Name: IDX_14f68deffaf858465715995508; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_14f68deffaf858465715995508" ON public.folder USING btree ("projectId", id);


--
-- Name: IDX_1d11050a381548c42c32cc25c4; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_1d11050a381548c42c32cc25c4" ON public.user_favorites USING btree ("resourceType", "resourceId");


--
-- Name: IDX_1d8ab99d5861c9388d2dc1cf73; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_1d8ab99d5861c9388d2dc1cf73" ON public.insights_metadata USING btree ("workflowId");


--
-- Name: IDX_1dd5c393ad0517be3c31a7af83; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_1dd5c393ad0517be3c31a7af83" ON public.user_favorites USING btree ("userId");


--
-- Name: IDX_1e31657f5fe46816c34be7c1b4; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_1e31657f5fe46816c34be7c1b4" ON public.workflow_history USING btree ("workflowId");


--
-- Name: IDX_1eeb64cb9d66a927988de759e6; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_1eeb64cb9d66a927988de759e6" ON public.instance_ai_messages USING btree ("threadId");


--
-- Name: IDX_1ef35bac35d20bdae979d917a3; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_1ef35bac35d20bdae979d917a3" ON public.user_api_keys USING btree ("apiKey");


--
-- Name: IDX_2b23f3f24a70bebb990203b011; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_2b23f3f24a70bebb990203b011" ON public.instance_ai_checkpoints USING btree ("threadId");


--
-- Name: IDX_35a78869286c65d9330d02b88f; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_35a78869286c65d9330d02b88f" ON public.role_mapping_rule_project USING btree ("projectId");


--
-- Name: IDX_39b07732e819fb561d74c38763; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_39b07732e819fb561d74c38763" ON public.ai_builder_temporary_workflow USING btree ("threadId");


--
-- Name: IDX_451d387a182fa8dd8002dfc3a7; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_451d387a182fa8dd8002dfc3a7" ON public.agents_memory_entry_sources USING btree ("threadId");


--
-- Name: IDX_45dafc48fe2ce95eac30fc8ffd; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_45dafc48fe2ce95eac30fc8ffd" ON public.agent_files USING btree ("agentId", "createdAt");


--
-- Name: IDX_4c72ebdb265d1775bf61147af0; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_4c72ebdb265d1775bf61147af0" ON public.chat_hub_tools USING btree ("ownerId", name);


--
-- Name: IDX_4cfd8a70ebb0a5b0cf047dca3c; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_4cfd8a70ebb0a5b0cf047dca3c" ON public.agents_observations USING btree ("observationScopeId");


--
-- Name: IDX_501e2d1701a10e24fb69ab5fc5; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_501e2d1701a10e24fb69ab5fc5" ON public.agents_observations USING btree ("parentId");


--
-- Name: IDX_54fa1b94f34a409beafae567a4; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_54fa1b94f34a409beafae567a4" ON public.agents_threads USING btree ("resourceId");


--
-- Name: IDX_56900edc3cfd16612e2ef2c6a8; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_56900edc3cfd16612e2ef2c6a8" ON public.binary_data USING btree ("sourceType", "sourceId");


--
-- Name: IDX_5e31c210f896d539964bf99fe3; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_5e31c210f896d539964bf99fe3" ON public.agent_checkpoints USING btree ("agentId");


--
-- Name: IDX_5ec8e8c8d3539f3696cf73b43b; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_5ec8e8c8d3539f3696cf73b43b" ON public.credential_dependency USING btree ("credentialId");


--
-- Name: IDX_5f0643f6717905a05164090dde; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_5f0643f6717905a05164090dde" ON public.project_relation USING btree ("userId");


--
-- Name: IDX_60b6a84299eeb3f671dfec7693; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_60b6a84299eeb3f671dfec7693" ON public.insights_by_period USING btree ("periodStart", type, "periodUnit", "metaId");


--
-- Name: IDX_61448d56d61802b5dfde5cdb00; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_61448d56d61802b5dfde5cdb00" ON public.project_relation USING btree ("projectId");


--
-- Name: IDX_62476b94b56d9dc7ed9ed75d3d; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_62476b94b56d9dc7ed9ed75d3d" ON public.dynamic_credential_entry USING btree (subject_id);


--
-- Name: IDX_63d3c3a68b9cebf05f967f0b1c; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_63d3c3a68b9cebf05f967f0b1c" ON public.agent_execution USING btree ("threadId", "createdAt");


--
-- Name: IDX_63d7bbae72c767cf162d459fcc; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_63d7bbae72c767cf162d459fcc" ON public.user_api_keys USING btree ("userId", label);


--
-- Name: IDX_6b55089892e447c2f82e5ec60e; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_6b55089892e447c2f82e5ec60e" ON public.agents_observation_locks USING btree ("observationScopeId");


--
-- Name: IDX_6edec973a6450990977bb854c3; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_6edec973a6450990977bb854c3" ON public.dynamic_credential_user_entry USING btree ("resolverId");


--
-- Name: IDX_768189b506cc26c4fe878b87cb; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_768189b506cc26c4fe878b87cb" ON public.instance_ai_checkpoints USING btree ("runId");


--
-- Name: IDX_76e212c6867fbaa06bf0decd6f; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_76e212c6867fbaa06bf0decd6f" ON public.instance_ai_messages USING btree ("resourceId");


--
-- Name: IDX_87aa187d27ea67eafd16490515; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_87aa187d27ea67eafd16490515" ON public.agents_observation_cursors USING btree ("observationScopeId");


--
-- Name: IDX_87cd5a8da20304b089ea2f83fe; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_87cd5a8da20304b089ea2f83fe" ON public.agent_history USING btree ("agentId");


--
-- Name: IDX_8e4b4774db42f1e6dda3452b2a; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_8e4b4774db42f1e6dda3452b2a" ON public.test_case_execution USING btree ("testRunId");


--
-- Name: IDX_91ee85fa9619dd6776725e117b; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_91ee85fa9619dd6776725e117b" ON public.credential_dependency USING btree ("dependencyType", "dependencyId");


--
-- Name: IDX_92f13cb6bc694227e069447f7b; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_92f13cb6bc694227e069447f7b" ON public.instance_ai_observational_memory USING btree ("lookupKey");


--
-- Name: IDX_9594c0983cfee1c8ff49b05848; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_9594c0983cfee1c8ff49b05848" ON public.agents_memory_entry_locks USING btree ("resourceId");


--
-- Name: IDX_97f863fa83c4786f1956508496; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_97f863fa83c4786f1956508496" ON public.execution_annotations USING btree ("executionId");


--
-- Name: IDX_9c9ee9df586e60bb723234e499; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_9c9ee9df586e60bb723234e499" ON public.dynamic_credential_resolver USING btree (type);


--
-- Name: IDX_UniqueRoleDisplayName; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_UniqueRoleDisplayName" ON public.role USING btree ("displayName");


--
-- Name: IDX_a03e04e94bea8439dd166d4b52; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_a03e04e94bea8439dd166d4b52" ON public.agents_memory_entries USING btree ("agentId", "resourceId", "contentHash");


--
-- Name: IDX_a30d560207c4071d98aa03c179; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_a30d560207c4071d98aa03c179" ON public.agents USING btree ("projectId");


--
-- Name: IDX_a353ac251315ef0af6ad3c9f0a; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_a353ac251315ef0af6ad3c9f0a" ON public.agents_memory_entry_sources USING btree ("memoryEntryId", "observationId", "evidenceHash");


--
-- Name: IDX_a3697779b366e131b2bbdae297; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_a3697779b366e131b2bbdae297" ON public.execution_annotation_tags USING btree ("tagId");


--
-- Name: IDX_a36dc616fabc3f736bb82410a2; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_a36dc616fabc3f736bb82410a2" ON public.dynamic_credential_user_entry USING btree ("userId");


--
-- Name: IDX_a371ee6b8e0ebb5635f8baa46d; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_a371ee6b8e0ebb5635f8baa46d" ON public.instance_ai_workflow_snapshots USING btree ("workflowName", status);


--
-- Name: IDX_a48ce930c3bc7604894b8f0eaa; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_a48ce930c3bc7604894b8f0eaa" ON public.evaluation_collection USING btree ("workflowId");


--
-- Name: IDX_a4ff2d9b9628ea988fa9e7d0bf; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_a4ff2d9b9628ea988fa9e7d0bf" ON public.workflow_dependency USING btree ("workflowId");


--
-- Name: IDX_a680ac96aae02dc887bbaac512; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_a680ac96aae02dc887bbaac512" ON public.instance_ai_observational_memory USING btree (scope, "threadId", "resourceId");


--
-- Name: IDX_a80e0ee839a2f10ba4b86e1999; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_a80e0ee839a2f10ba4b86e1999" ON public.instance_ai_observations USING btree ("supersededBy");


--
-- Name: IDX_ae51b54c4bb430cf92f48b623f; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_ae51b54c4bb430cf92f48b623f" ON public.annotation_tag_entity USING btree (name);


--
-- Name: IDX_aff2807b31eccbafe59d0474f0; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_aff2807b31eccbafe59d0474f0" ON public.agents_memory_entries USING btree ("agentId", "resourceId", status, "createdAt", id);


--
-- Name: IDX_agent_execution_threads_taskVersionId; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_agent_execution_threads_taskVersionId" ON public.agent_execution_threads USING btree ("taskVersionId");


--
-- Name: IDX_agents_messages_threadId_createdAt; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_agents_messages_threadId_createdAt" ON public.agents_messages USING btree ("threadId", "createdAt");


--
-- Name: IDX_agents_projectId; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_agents_projectId" ON public.agents USING btree ("projectId");


--
-- Name: IDX_ba67ee8dc311830a2eea89b6e9; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_ba67ee8dc311830a2eea89b6e9" ON public.instance_ai_pending_confirmations USING btree ("threadId");


--
-- Name: IDX_bb66e404c35996b0d694617750; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_bb66e404c35996b0d694617750" ON public.role_mapping_rule USING btree (role);


--
-- Name: IDX_be9d0eca0b19fb93d4eb74b327; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_be9d0eca0b19fb93d4eb74b327" ON public.instance_ai_checkpoints USING btree ("resourceId");


--
-- Name: IDX_c1519757391996eb06064f0e7c; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_c1519757391996eb06064f0e7c" ON public.execution_annotation_tags USING btree ("annotationId");


--
-- Name: IDX_cb7c15d22fd068a0806aa57fc0; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_cb7c15d22fd068a0806aa57fc0" ON public.agents_memory_entry_sources USING btree ("observationId");


--
-- Name: IDX_cec8eea3bf49551482ccb4933e; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_cec8eea3bf49551482ccb4933e" ON public.execution_metadata USING btree ("executionId", key);


--
-- Name: IDX_chat_hub_messages_sessionId; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_chat_hub_messages_sessionId" ON public.chat_hub_messages USING btree ("sessionId");


--
-- Name: IDX_chat_hub_sessions_owner_lastmsg_id; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_chat_hub_sessions_owner_lastmsg_id" ON public.chat_hub_sessions USING btree ("ownerId", "lastMessageAt" DESC, id);


--
-- Name: IDX_credential_dependency_credentialId_dependencyType_dependenc; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_credential_dependency_credentialId_dependencyType_dependenc" ON public.credential_dependency USING btree ("credentialId", "dependencyType", "dependencyId");


--
-- Name: IDX_d3a2bc880e7a8626802e5474ad; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_d3a2bc880e7a8626802e5474ad" ON public.instance_ai_run_snapshots USING btree ("threadId", "createdAt");


--
-- Name: IDX_d61a12235d268a49af6a3c09c1; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_d61a12235d268a49af6a3c09c1" ON public.dynamic_credential_entry USING btree (resolver_id);


--
-- Name: IDX_d634a0c93fd7de68a87eab951b; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_d634a0c93fd7de68a87eab951b" ON public.evaluation_collection USING btree ("evaluationConfigId");


--
-- Name: IDX_d6870d3b6e4c185d33926f423c; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_d6870d3b6e4c185d33926f423c" ON public.test_run USING btree ("workflowId");


--
-- Name: IDX_d7a4aba7440449865e2b924377; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_d7a4aba7440449865e2b924377" ON public.instance_ai_pending_confirmations USING btree ("expiresAt");


--
-- Name: IDX_d926c16c2ad9728cb9a81790c0; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_d926c16c2ad9728cb9a81790c0" ON public.instance_ai_run_snapshots USING btree ("threadId", "messageGroupId");


--
-- Name: IDX_daef2195a4a846eb70eed15e03; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_daef2195a4a846eb70eed15e03" ON public.instance_ai_observations USING btree ("parentId");


--
-- Name: IDX_deployment_key_data_encryption_active; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_deployment_key_data_encryption_active" ON public.deployment_key USING btree (type) WHERE (((status)::text = 'active'::text) AND ((type)::text = 'data_encryption'::text));


--
-- Name: IDX_deployment_key_instance_id_active; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_deployment_key_instance_id_active" ON public.deployment_key USING btree (type) WHERE (((status)::text = 'active'::text) AND ((type)::text = 'instance.id'::text));


--
-- Name: IDX_deployment_key_jwe_private_key_active; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_deployment_key_jwe_private_key_active" ON public.deployment_key USING btree (type, algorithm) WHERE (((status)::text = 'active'::text) AND ((type)::text = 'jwe.private-key'::text));


--
-- Name: IDX_deployment_key_signing_binary_data_active; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_deployment_key_signing_binary_data_active" ON public.deployment_key USING btree (type) WHERE (((status)::text = 'active'::text) AND ((type)::text = 'signing.binary_data'::text));


--
-- Name: IDX_deployment_key_signing_hmac_active; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_deployment_key_signing_hmac_active" ON public.deployment_key USING btree (type) WHERE (((status)::text = 'active'::text) AND ((type)::text = 'signing.hmac'::text));


--
-- Name: IDX_deployment_key_signing_jwt_active; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_deployment_key_signing_jwt_active" ON public.deployment_key USING btree (type) WHERE (((status)::text = 'active'::text) AND ((type)::text = 'signing.jwt'::text));


--
-- Name: IDX_df5fd25c8bbfd2b042602600d8; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_df5fd25c8bbfd2b042602600d8" ON public.instance_ai_pending_confirmations USING btree ("userId");


--
-- Name: IDX_e48a201071ab85d9d09119d640; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_e48a201071ab85d9d09119d640" ON public.workflow_dependency USING btree ("dependencyKey");


--
-- Name: IDX_e7fe1cfda990c14a445937d0b9; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_e7fe1cfda990c14a445937d0b9" ON public.workflow_dependency USING btree ("dependencyType");


--
-- Name: IDX_execution_entity_deduplicationKey; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_execution_entity_deduplicationKey" ON public.execution_entity USING btree ("deduplicationKey") WHERE ("deduplicationKey" IS NOT NULL);


--
-- Name: IDX_execution_entity_deletedAt; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_execution_entity_deletedAt" ON public.execution_entity USING btree ("deletedAt");


--
-- Name: IDX_f36dea4d38fe92e0e8f44d5a56; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_f36dea4d38fe92e0e8f44d5a56" ON public.instance_ai_threads USING btree ("resourceId");


--
-- Name: IDX_f45d0535a2ed59b6c2dd6da98a; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_f45d0535a2ed59b6c2dd6da98a" ON public.agent_task_definition USING btree ("agentId");


--
-- Name: IDX_f9573af4ed653f13b0ba1f7b12; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_f9573af4ed653f13b0ba1f7b12" ON public.agents_memory_entry_sources USING btree ("agentId", "threadId");


--
-- Name: IDX_fc7bf858660bfafd19181e8e35; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_fc7bf858660bfafd19181e8e35" ON public.agents_messages USING btree ("threadId", "createdAt");


--
-- Name: IDX_fd7542bb123074760285dc1bbf; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_fd7542bb123074760285dc1bbf" ON public.evaluation_config USING btree ("workflowId");


--
-- Name: IDX_insights_raw_timestamp_id; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_insights_raw_timestamp_id" ON public.insights_raw USING btree ("timestamp", id);


--
-- Name: IDX_role_scope_scopeSlug; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_role_scope_scopeSlug" ON public.role_scope USING btree ("scopeSlug");


--
-- Name: IDX_secrets_provider_connection_providerKey; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_secrets_provider_connection_providerKey" ON public.secrets_provider_connection USING btree ("providerKey");


--
-- Name: IDX_shared_workflow_projectId; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_shared_workflow_projectId" ON public.shared_workflow USING btree ("projectId");


--
-- Name: IDX_test_run_collectionId; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_test_run_collectionId" ON public.test_run USING btree ("collectionId");


--
-- Name: IDX_test_run_evaluationConfigId; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_test_run_evaluationConfigId" ON public.test_run USING btree ("evaluationConfigId");


--
-- Name: IDX_workflow_dependency_publishedVersionId; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_workflow_dependency_publishedVersionId" ON public.workflow_dependency USING btree ("publishedVersionId");


--
-- Name: IDX_workflow_entity_name; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_workflow_entity_name" ON public.workflow_entity USING btree (name);


--
-- Name: IDX_workflow_entity_sourceWorkflowId; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX "IDX_workflow_entity_sourceWorkflowId" ON public.workflow_entity USING btree ("sourceWorkflowId") WHERE ("sourceWorkflowId" IS NOT NULL);


--
-- Name: IDX_workflow_publication_outbox_pending_workflow; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_workflow_publication_outbox_pending_workflow" ON public.workflow_publication_outbox USING btree ("workflowId") WHERE ((status)::text = 'pending'::text);


--
-- Name: IDX_workflow_statistics_workflow_name; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX "IDX_workflow_statistics_workflow_name" ON public.workflow_statistics USING btree ("workflowId", name);


--
-- Name: idx_07fde106c0b471d8cc80a64fc8; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX idx_07fde106c0b471d8cc80a64fc8 ON public.credentials_entity USING btree (type);


--
-- Name: idx_16f4436789e804e3e1c9eeb240; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX idx_16f4436789e804e3e1c9eeb240 ON public.webhook_entity USING btree ("webhookId", method, "pathLength");


--
-- Name: idx_812eb05f7451ca757fb98444ce; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX idx_812eb05f7451ca757fb98444ce ON public.tag_entity USING btree (name);


--
-- Name: idx_execution_entity_stopped_at_status_deleted_at; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX idx_execution_entity_stopped_at_status_deleted_at ON public.execution_entity USING btree ("stoppedAt", status, "deletedAt") WHERE (("stoppedAt" IS NOT NULL) AND ("deletedAt" IS NULL));


--
-- Name: idx_execution_entity_wait_till_status_deleted_at; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX idx_execution_entity_wait_till_status_deleted_at ON public.execution_entity USING btree ("waitTill", status, "deletedAt") WHERE (("waitTill" IS NOT NULL) AND ("deletedAt" IS NULL));


--
-- Name: idx_execution_entity_workflow_id_started_at; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX idx_execution_entity_workflow_id_started_at ON public.execution_entity USING btree ("workflowId", "startedAt") WHERE (("startedAt" IS NOT NULL) AND ("deletedAt" IS NULL));


--
-- Name: idx_workflows_tags_workflow_id; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX idx_workflows_tags_workflow_id ON public.workflows_tags USING btree ("workflowId");


--
-- Name: pk_credentials_entity_id; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX pk_credentials_entity_id ON public.credentials_entity USING btree (id);


--
-- Name: pk_tag_entity_id; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX pk_tag_entity_id ON public.tag_entity USING btree (id);


--
-- Name: pk_workflow_entity_id; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX pk_workflow_entity_id ON public.workflow_entity USING btree (id);


--
-- Name: project_relation_role_idx; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX project_relation_role_idx ON public.project_relation USING btree (role);


--
-- Name: project_relation_role_project_idx; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX project_relation_role_project_idx ON public.project_relation USING btree ("projectId", role);


--
-- Name: user_role_idx; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE INDEX user_role_idx ON public."user" USING btree ("roleSlug");


--
-- Name: variables_global_key_unique; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX variables_global_key_unique ON public.variables USING btree (key) WHERE ("projectId" IS NULL);


--
-- Name: variables_project_key_unique; Type: INDEX; Schema: public; Owner: integration_user
--

CREATE UNIQUE INDEX variables_project_key_unique ON public.variables USING btree ("projectId", key) WHERE ("projectId" IS NOT NULL);


--
-- Name: workflow_entity workflow_version_increment; Type: TRIGGER; Schema: public; Owner: integration_user
--

CREATE TRIGGER workflow_version_increment BEFORE UPDATE ON public.workflow_entity FOR EACH ROW EXECUTE FUNCTION public.increment_workflow_version();


--
-- Name: buildings buildings_object_id_fkey; Type: FK CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.buildings
    ADD CONSTRAINT buildings_object_id_fkey FOREIGN KEY (object_id) REFERENCES cmdb.objects(id);


--
-- Name: equipment equipment_equipment_type_id_fkey; Type: FK CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.equipment
    ADD CONSTRAINT equipment_equipment_type_id_fkey FOREIGN KEY (equipment_type_id) REFERENCES cmdb.equipment_types(id);


--
-- Name: equipment equipment_object_id_fkey; Type: FK CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.equipment
    ADD CONSTRAINT equipment_object_id_fkey FOREIGN KEY (object_id) REFERENCES cmdb.objects(id);


--
-- Name: equipment_relations equipment_relations_source_equipment_id_fkey; Type: FK CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.equipment_relations
    ADD CONSTRAINT equipment_relations_source_equipment_id_fkey FOREIGN KEY (source_equipment_id) REFERENCES cmdb.equipment(id);


--
-- Name: equipment_relations equipment_relations_target_equipment_id_fkey; Type: FK CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.equipment_relations
    ADD CONSTRAINT equipment_relations_target_equipment_id_fkey FOREIGN KEY (target_equipment_id) REFERENCES cmdb.equipment(id);


--
-- Name: equipment equipment_room_id_fkey; Type: FK CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.equipment
    ADD CONSTRAINT equipment_room_id_fkey FOREIGN KEY (room_id) REFERENCES cmdb.rooms(id);


--
-- Name: equipment_types equipment_types_parent_id_fkey; Type: FK CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.equipment_types
    ADD CONSTRAINT equipment_types_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES cmdb.equipment_types(id);


--
-- Name: equipment equipment_vendor_id_fkey; Type: FK CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.equipment
    ADD CONSTRAINT equipment_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES cmdb.vendors(id);


--
-- Name: floors floors_building_id_fkey; Type: FK CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.floors
    ADD CONSTRAINT floors_building_id_fkey FOREIGN KEY (building_id) REFERENCES cmdb.buildings(id);


--
-- Name: rooms rooms_floor_id_fkey; Type: FK CONSTRAINT; Schema: cmdb; Owner: cmdb_user
--

ALTER TABLE ONLY cmdb.rooms
    ADD CONSTRAINT rooms_floor_id_fkey FOREIGN KEY (floor_id) REFERENCES cmdb.floors(id);


--
-- Name: sla_events sla_events_ticket_id_fkey; Type: FK CONSTRAINT; Schema: fsm; Owner: fsm_user
--

ALTER TABLE ONLY fsm.sla_events
    ADD CONSTRAINT sla_events_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES fsm.tickets(id);


--
-- Name: visit_materials visit_materials_visit_id_fkey; Type: FK CONSTRAINT; Schema: fsm; Owner: fsm_user
--

ALTER TABLE ONLY fsm.visit_materials
    ADD CONSTRAINT visit_materials_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES fsm.visits(id);


--
-- Name: visit_photos visit_photos_visit_id_fkey; Type: FK CONSTRAINT; Schema: fsm; Owner: fsm_user
--

ALTER TABLE ONLY fsm.visit_photos
    ADD CONSTRAINT visit_photos_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES fsm.visits(id);


--
-- Name: visits visits_ticket_id_fkey; Type: FK CONSTRAINT; Schema: fsm; Owner: fsm_user
--

ALTER TABLE ONLY fsm.visits
    ADD CONSTRAINT visits_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES fsm.tickets(id);


--
-- Name: warranty_cases warranty_cases_ticket_id_fkey; Type: FK CONSTRAINT; Schema: fsm; Owner: fsm_user
--

ALTER TABLE ONLY fsm.warranty_cases
    ADD CONSTRAINT warranty_cases_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES fsm.tickets(id);


--
-- Name: workflow_builder_session FK_00290cdeee4d4d7db84709be936; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_builder_session
    ADD CONSTRAINT "FK_00290cdeee4d4d7db84709be936" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: agent_execution_threads FK_0468a9dc35597314e641d4722aa; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agent_execution_threads
    ADD CONSTRAINT "FK_0468a9dc35597314e641d4722aa" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: agents_memory_entry_cursors FK_069e791e428391a5569e7a96b20; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_memory_entry_cursors
    ADD CONSTRAINT "FK_069e791e428391a5569e7a96b20" FOREIGN KEY ("observationScopeId") REFERENCES public.agents_threads(id) ON DELETE CASCADE;


--
-- Name: processed_data FK_06a69a7032c97a763c2c7599464; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.processed_data
    ADD CONSTRAINT "FK_06a69a7032c97a763c2c7599464" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: workflow_entity FK_08d6c67b7f722b0039d9d5ed620; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_entity
    ADD CONSTRAINT "FK_08d6c67b7f722b0039d9d5ed620" FOREIGN KEY ("activeVersionId") REFERENCES public.workflow_history("versionId") ON DELETE RESTRICT;


--
-- Name: agents_observation_locks FK_093e44ae20f2518e97d83a95433; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_observation_locks
    ADD CONSTRAINT "FK_093e44ae20f2518e97d83a95433" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: agents_messages FK_0a8057a61afabd2999608ffd0d9; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_messages
    ADD CONSTRAINT "FK_0a8057a61afabd2999608ffd0d9" FOREIGN KEY ("threadId") REFERENCES public.agents_threads(id) ON DELETE CASCADE;


--
-- Name: instance_ai_pending_confirmations FK_0babdf6e3b897a86fe4678355eb; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_pending_confirmations
    ADD CONSTRAINT "FK_0babdf6e3b897a86fe4678355eb" FOREIGN KEY ("checkpointKey") REFERENCES public.instance_ai_checkpoints(key) ON DELETE CASCADE;


--
-- Name: agents_memory_entry_locks FK_0ccf6d9ea6f44fa1c264fc2f795; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_memory_entry_locks
    ADD CONSTRAINT "FK_0ccf6d9ea6f44fa1c264fc2f795" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: agent_execution_threads FK_0e2f8bf92a7a9c88b89670f701c; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agent_execution_threads
    ADD CONSTRAINT "FK_0e2f8bf92a7a9c88b89670f701c" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: agents_memory_entries FK_0edf1226b77ddc525eae4938079; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_memory_entries
    ADD CONSTRAINT "FK_0edf1226b77ddc525eae4938079" FOREIGN KEY ("supersededBy") REFERENCES public.agents_memory_entries(id);


--
-- Name: instance_ai_observation_locks FK_103e2e5f454860b28ea05a82c74; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_observation_locks
    ADD CONSTRAINT "FK_103e2e5f454860b28ea05a82c74" FOREIGN KEY ("observationScopeId") REFERENCES public.instance_ai_threads(id) ON DELETE CASCADE;


--
-- Name: agents_observations FK_127ee1078ffa952bb37b511efad; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_observations
    ADD CONSTRAINT "FK_127ee1078ffa952bb37b511efad" FOREIGN KEY ("supersededBy") REFERENCES public.agents_observations(id);


--
-- Name: agents_memory_entries FK_1443a75e59adbfb796071d66393; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_memory_entries
    ADD CONSTRAINT "FK_1443a75e59adbfb796071d66393" FOREIGN KEY ("resourceId") REFERENCES public.agents_resources(id) ON DELETE CASCADE;


--
-- Name: project_secrets_provider_access FK_18e5c27d2524b1638b292904e48; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.project_secrets_provider_access
    ADD CONSTRAINT "FK_18e5c27d2524b1638b292904e48" FOREIGN KEY ("secretsProviderConnectionId") REFERENCES public.secrets_provider_connection(id) ON DELETE CASCADE;


--
-- Name: agent_task_snapshot FK_1acedce6690392ef1611cca8b88; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agent_task_snapshot
    ADD CONSTRAINT "FK_1acedce6690392ef1611cca8b88" FOREIGN KEY ("versionId") REFERENCES public.agent_history("versionId") ON DELETE CASCADE;


--
-- Name: insights_metadata FK_1d8ab99d5861c9388d2dc1cf733; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.insights_metadata
    ADD CONSTRAINT "FK_1d8ab99d5861c9388d2dc1cf733" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE SET NULL;


--
-- Name: user_favorites FK_1dd5c393ad0517be3c31a7af836; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT "FK_1dd5c393ad0517be3c31a7af836" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: workflow_history FK_1e31657f5fe46816c34be7c1b4b; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_history
    ADD CONSTRAINT "FK_1e31657f5fe46816c34be7c1b4b" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: instance_ai_messages FK_1eeb64cb9d66a927988de759e6e; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_messages
    ADD CONSTRAINT "FK_1eeb64cb9d66a927988de759e6e" FOREIGN KEY ("threadId") REFERENCES public.instance_ai_threads(id) ON DELETE CASCADE;


--
-- Name: chat_hub_messages FK_1f4998c8a7dec9e00a9ab15550e; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "FK_1f4998c8a7dec9e00a9ab15550e" FOREIGN KEY ("revisionOfMessageId") REFERENCES public.chat_hub_messages(id) ON DELETE CASCADE;


--
-- Name: oauth_user_consents FK_21e6c3c2d78a097478fae6aaefa; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.oauth_user_consents
    ADD CONSTRAINT "FK_21e6c3c2d78a097478fae6aaefa" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: insights_metadata FK_2375a1eda085adb16b24615b69c; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.insights_metadata
    ADD CONSTRAINT "FK_2375a1eda085adb16b24615b69c" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE SET NULL;


--
-- Name: chat_hub_messages FK_25c9736e7f769f3a005eef4b372; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "FK_25c9736e7f769f3a005eef4b372" FOREIGN KEY ("retryOfMessageId") REFERENCES public.chat_hub_messages(id) ON DELETE CASCADE;


--
-- Name: agents_memory_entries FK_28e981fb675e9b44ce02f0ec1dd; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_memory_entries
    ADD CONSTRAINT "FK_28e981fb675e9b44ce02f0ec1dd" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: instance_ai_checkpoints FK_2b23f3f24a70bebb990203b011e; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_checkpoints
    ADD CONSTRAINT "FK_2b23f3f24a70bebb990203b011e" FOREIGN KEY ("threadId") REFERENCES public.instance_ai_threads(id) ON DELETE CASCADE;


--
-- Name: chat_hub_agent_tools FK_2b53d796b3dbae91b1a9553c048; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_agent_tools
    ADD CONSTRAINT "FK_2b53d796b3dbae91b1a9553c048" FOREIGN KEY ("agentId") REFERENCES public.chat_hub_agents(id) ON DELETE CASCADE;


--
-- Name: instance_ai_run_snapshots FK_2f63fa21d09d7918f347ddbdf70; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_run_snapshots
    ADD CONSTRAINT "FK_2f63fa21d09d7918f347ddbdf70" FOREIGN KEY ("threadId") REFERENCES public.instance_ai_threads(id) ON DELETE CASCADE;


--
-- Name: execution_metadata FK_31d0b4c93fb85ced26f6005cda3; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.execution_metadata
    ADD CONSTRAINT "FK_31d0b4c93fb85ced26f6005cda3" FOREIGN KEY ("executionId") REFERENCES public.execution_entity(id) ON DELETE CASCADE;


--
-- Name: instance_ai_observational_memory FK_34018c303885cd37093458e6409; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_observational_memory
    ADD CONSTRAINT "FK_34018c303885cd37093458e6409" FOREIGN KEY ("threadId") REFERENCES public.instance_ai_threads(id) ON DELETE SET NULL;


--
-- Name: role_mapping_rule_project FK_35a78869286c65d9330d02b88f5; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.role_mapping_rule_project
    ADD CONSTRAINT "FK_35a78869286c65d9330d02b88f5" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: ai_builder_temporary_workflow FK_39b07732e819fb561d74c38763f; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.ai_builder_temporary_workflow
    ADD CONSTRAINT "FK_39b07732e819fb561d74c38763f" FOREIGN KEY ("threadId") REFERENCES public.instance_ai_threads(id) ON DELETE CASCADE;


--
-- Name: shared_credentials FK_416f66fc846c7c442970c094ccf; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.shared_credentials
    ADD CONSTRAINT "FK_416f66fc846c7c442970c094ccf" FOREIGN KEY ("credentialsId") REFERENCES public.credentials_entity(id) ON DELETE CASCADE;


--
-- Name: variables FK_42f6c766f9f9d2edcc15bdd6e9b; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.variables
    ADD CONSTRAINT "FK_42f6c766f9f9d2edcc15bdd6e9b" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: chat_hub_agent_tools FK_43e70f04c53344f82483d0570f6; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_agent_tools
    ADD CONSTRAINT "FK_43e70f04c53344f82483d0570f6" FOREIGN KEY ("toolId") REFERENCES public.chat_hub_tools(id) ON DELETE CASCADE;


--
-- Name: chat_hub_agents FK_441ba2caba11e077ce3fbfa2cd8; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_agents
    ADD CONSTRAINT "FK_441ba2caba11e077ce3fbfa2cd8" FOREIGN KEY ("ownerId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: agents_memory_entry_sources FK_451d387a182fa8dd8002dfc3a77; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_memory_entry_sources
    ADD CONSTRAINT "FK_451d387a182fa8dd8002dfc3a77" FOREIGN KEY ("threadId") REFERENCES public.agents_threads(id) ON DELETE CASCADE;


--
-- Name: agents_memory_entry_sources FK_4706f6223313959b7437a2b48df; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_memory_entry_sources
    ADD CONSTRAINT "FK_4706f6223313959b7437a2b48df" FOREIGN KEY ("memoryEntryId") REFERENCES public.agents_memory_entries(id) ON DELETE CASCADE;


--
-- Name: agents_observations FK_4cfd8a70ebb0a5b0cf047dca3cf; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_observations
    ADD CONSTRAINT "FK_4cfd8a70ebb0a5b0cf047dca3cf" FOREIGN KEY ("observationScopeId") REFERENCES public.agents_threads(id) ON DELETE CASCADE;


--
-- Name: agents_observations FK_501e2d1701a10e24fb69ab5fc5f; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_observations
    ADD CONSTRAINT "FK_501e2d1701a10e24fb69ab5fc5f" FOREIGN KEY ("parentId") REFERENCES public.agents_observations(id);


--
-- Name: instance_ai_observation_cursors FK_5b6319b2e9a37c1064a72428f9a; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_observation_cursors
    ADD CONSTRAINT "FK_5b6319b2e9a37c1064a72428f9a" FOREIGN KEY ("observationScopeId") REFERENCES public.instance_ai_threads(id) ON DELETE CASCADE;


--
-- Name: workflow_published_version FK_5c76fb7ee939fe2530374d3f75a; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_published_version
    ADD CONSTRAINT "FK_5c76fb7ee939fe2530374d3f75a" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE RESTRICT;


--
-- Name: agent_checkpoints FK_5e31c210f896d539964bf99fe32; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agent_checkpoints
    ADD CONSTRAINT "FK_5e31c210f896d539964bf99fe32" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: credential_dependency FK_5ec8e8c8d3539f3696cf73b43bf; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.credential_dependency
    ADD CONSTRAINT "FK_5ec8e8c8d3539f3696cf73b43bf" FOREIGN KEY ("credentialId") REFERENCES public.credentials_entity(id) ON DELETE CASCADE;


--
-- Name: project_relation FK_5f0643f6717905a05164090dde7; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.project_relation
    ADD CONSTRAINT "FK_5f0643f6717905a05164090dde7" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: project_relation FK_61448d56d61802b5dfde5cdb002; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.project_relation
    ADD CONSTRAINT "FK_61448d56d61802b5dfde5cdb002" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: insights_by_period FK_6414cfed98daabbfdd61a1cfbc0; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.insights_by_period
    ADD CONSTRAINT "FK_6414cfed98daabbfdd61a1cfbc0" FOREIGN KEY ("metaId") REFERENCES public.insights_metadata("metaId") ON DELETE CASCADE;


--
-- Name: oauth_authorization_codes FK_64d965bd072ea24fb6da55468cd; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.oauth_authorization_codes
    ADD CONSTRAINT "FK_64d965bd072ea24fb6da55468cd" FOREIGN KEY ("clientId") REFERENCES public.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: agents_observation_cursors FK_64e92819f4b413661ed6e2c3c3d; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_observation_cursors
    ADD CONSTRAINT "FK_64e92819f4b413661ed6e2c3c3d" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: chat_hub_session_tools FK_6596a328affd8d4967ffb303eee; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_session_tools
    ADD CONSTRAINT "FK_6596a328affd8d4967ffb303eee" FOREIGN KEY ("toolId") REFERENCES public.chat_hub_tools(id) ON DELETE CASCADE;


--
-- Name: chat_hub_messages FK_6afb260449dd7a9b85355d4e0c9; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "FK_6afb260449dd7a9b85355d4e0c9" FOREIGN KEY ("executionId") REFERENCES public.execution_entity(id) ON DELETE SET NULL;


--
-- Name: agents_observation_locks FK_6b55089892e447c2f82e5ec60ed; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_observation_locks
    ADD CONSTRAINT "FK_6b55089892e447c2f82e5ec60ed" FOREIGN KEY ("observationScopeId") REFERENCES public.agents_threads(id) ON DELETE CASCADE;


--
-- Name: insights_raw FK_6e2e33741adef2a7c5d66befa4e; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.insights_raw
    ADD CONSTRAINT "FK_6e2e33741adef2a7c5d66befa4e" FOREIGN KEY ("metaId") REFERENCES public.insights_metadata("metaId") ON DELETE CASCADE;


--
-- Name: workflow_publish_history FK_6eab5bd9eedabe9c54bd879fc40; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_publish_history
    ADD CONSTRAINT "FK_6eab5bd9eedabe9c54bd879fc40" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: dynamic_credential_user_entry FK_6edec973a6450990977bb854c38; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.dynamic_credential_user_entry
    ADD CONSTRAINT "FK_6edec973a6450990977bb854c38" FOREIGN KEY ("resolverId") REFERENCES public.dynamic_credential_resolver(id) ON DELETE CASCADE;


--
-- Name: oauth_access_tokens FK_7234a36d8e49a1fa85095328845; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT "FK_7234a36d8e49a1fa85095328845" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: installed_nodes FK_73f857fc5dce682cef8a99c11dbddbc969618951; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.installed_nodes
    ADD CONSTRAINT "FK_73f857fc5dce682cef8a99c11dbddbc969618951" FOREIGN KEY (package) REFERENCES public.installed_packages("packageName") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: agents_memory_entry_cursors FK_746780fd115e5e4352457a3c617; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_memory_entry_cursors
    ADD CONSTRAINT "FK_746780fd115e5e4352457a3c617" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: oauth_access_tokens FK_78b26968132b7e5e45b75876481; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT "FK_78b26968132b7e5e45b75876481" FOREIGN KEY ("clientId") REFERENCES public.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: workflow_builder_session FK_7983c618db48f47bf5a4cc1e1e4; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_builder_session
    ADD CONSTRAINT "FK_7983c618db48f47bf5a4cc1e1e4" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: chat_hub_sessions FK_7bc13b4c7e6afbfaf9be326c189; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_sessions
    ADD CONSTRAINT "FK_7bc13b4c7e6afbfaf9be326c189" FOREIGN KEY ("credentialId") REFERENCES public.credentials_entity(id) ON DELETE SET NULL;


--
-- Name: folder FK_804ea52f6729e3940498bd54d78; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.folder
    ADD CONSTRAINT "FK_804ea52f6729e3940498bd54d78" FOREIGN KEY ("parentFolderId") REFERENCES public.folder(id) ON DELETE CASCADE;


--
-- Name: shared_credentials FK_812c2852270da1247756e77f5a4; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.shared_credentials
    ADD CONSTRAINT "FK_812c2852270da1247756e77f5a4" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: ai_builder_temporary_workflow FK_85a87a1ba0f61999fe11dc56325; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.ai_builder_temporary_workflow
    ADD CONSTRAINT "FK_85a87a1ba0f61999fe11dc56325" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: agent_history FK_8771675f44c58fb40e0feb9ee35; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agent_history
    ADD CONSTRAINT "FK_8771675f44c58fb40e0feb9ee35" FOREIGN KEY ("publishedById") REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: agents_observation_cursors FK_87aa187d27ea67eafd164905154; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_observation_cursors
    ADD CONSTRAINT "FK_87aa187d27ea67eafd164905154" FOREIGN KEY ("observationScopeId") REFERENCES public.agents_threads(id) ON DELETE CASCADE;


--
-- Name: agent_history FK_87cd5a8da20304b089ea2f83fec; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agent_history
    ADD CONSTRAINT "FK_87cd5a8da20304b089ea2f83fec" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: instance_ai_iteration_logs FK_8bfcc6c51fd3d69b1eae8aebd49; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_iteration_logs
    ADD CONSTRAINT "FK_8bfcc6c51fd3d69b1eae8aebd49" FOREIGN KEY ("threadId") REFERENCES public.instance_ai_threads(id) ON DELETE CASCADE;


--
-- Name: trusted_key FK_8c2938d746943dd8f608d23c891; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.trusted_key
    ADD CONSTRAINT "FK_8c2938d746943dd8f608d23c891" FOREIGN KEY ("sourceId") REFERENCES public.trusted_key_source(id) ON DELETE CASCADE;


--
-- Name: test_case_execution FK_8e4b4774db42f1e6dda3452b2af; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.test_case_execution
    ADD CONSTRAINT "FK_8e4b4774db42f1e6dda3452b2af" FOREIGN KEY ("testRunId") REFERENCES public.test_run(id) ON DELETE CASCADE;


--
-- Name: data_table_column FK_930b6e8faaf88294cef23484160; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.data_table_column
    ADD CONSTRAINT "FK_930b6e8faaf88294cef23484160" FOREIGN KEY ("dataTableId") REFERENCES public.data_table(id) ON DELETE CASCADE;


--
-- Name: agents FK_940597dfe9753375309ce6aeea0; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT "FK_940597dfe9753375309ce6aeea0" FOREIGN KEY ("activeVersionId") REFERENCES public.agent_history("versionId") ON DELETE SET NULL;


--
-- Name: dynamic_credential_user_entry FK_945ba70b342a066d1306b12ccd2; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.dynamic_credential_user_entry
    ADD CONSTRAINT "FK_945ba70b342a066d1306b12ccd2" FOREIGN KEY ("credentialId") REFERENCES public.credentials_entity(id) ON DELETE CASCADE;


--
-- Name: folder_tag FK_94a60854e06f2897b2e0d39edba; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.folder_tag
    ADD CONSTRAINT "FK_94a60854e06f2897b2e0d39edba" FOREIGN KEY ("folderId") REFERENCES public.folder(id) ON DELETE CASCADE;


--
-- Name: agents_memory_entry_locks FK_9594c0983cfee1c8ff49b05848b; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_memory_entry_locks
    ADD CONSTRAINT "FK_9594c0983cfee1c8ff49b05848b" FOREIGN KEY ("resourceId") REFERENCES public.agents_resources(id) ON DELETE CASCADE;


--
-- Name: execution_annotations FK_97f863fa83c4786f19565084960; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.execution_annotations
    ADD CONSTRAINT "FK_97f863fa83c4786f19565084960" FOREIGN KEY ("executionId") REFERENCES public.execution_entity(id) ON DELETE CASCADE;


--
-- Name: chat_hub_agents FK_9c61ad497dcbae499c96a6a78ba; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_agents
    ADD CONSTRAINT "FK_9c61ad497dcbae499c96a6a78ba" FOREIGN KEY ("credentialId") REFERENCES public.credentials_entity(id) ON DELETE SET NULL;


--
-- Name: chat_hub_sessions FK_9f9293d9f552496c40e0d1a8f80; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_sessions
    ADD CONSTRAINT "FK_9f9293d9f552496c40e0d1a8f80" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE SET NULL;


--
-- Name: agents FK_a30d560207c4071d98aa03c179c; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT "FK_a30d560207c4071d98aa03c179c" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: execution_annotation_tags FK_a3697779b366e131b2bbdae2976; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.execution_annotation_tags
    ADD CONSTRAINT "FK_a3697779b366e131b2bbdae2976" FOREIGN KEY ("tagId") REFERENCES public.annotation_tag_entity(id) ON DELETE CASCADE;


--
-- Name: dynamic_credential_user_entry FK_a36dc616fabc3f736bb82410a22; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.dynamic_credential_user_entry
    ADD CONSTRAINT "FK_a36dc616fabc3f736bb82410a22" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: shared_workflow FK_a45ea5f27bcfdc21af9b4188560; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.shared_workflow
    ADD CONSTRAINT "FK_a45ea5f27bcfdc21af9b4188560" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: evaluation_collection FK_a48ce930c3bc7604894b8f0eaad; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.evaluation_collection
    ADD CONSTRAINT "FK_a48ce930c3bc7604894b8f0eaad" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: workflow_dependency FK_a4ff2d9b9628ea988fa9e7d0bf8; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_dependency
    ADD CONSTRAINT "FK_a4ff2d9b9628ea988fa9e7d0bf8" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: oauth_user_consents FK_a651acea2f6c97f8c4514935486; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.oauth_user_consents
    ADD CONSTRAINT "FK_a651acea2f6c97f8c4514935486" FOREIGN KEY ("clientId") REFERENCES public.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_refresh_tokens FK_a699f3ed9fd0c1b19bc2608ac53; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.oauth_refresh_tokens
    ADD CONSTRAINT "FK_a699f3ed9fd0c1b19bc2608ac53" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: dynamic_credential_entry FK_a6d1dd080958304a47a02952aab; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.dynamic_credential_entry
    ADD CONSTRAINT "FK_a6d1dd080958304a47a02952aab" FOREIGN KEY (credential_id) REFERENCES public.credentials_entity(id) ON DELETE CASCADE;


--
-- Name: instance_ai_observations FK_a80e0ee839a2f10ba4b86e19998; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_observations
    ADD CONSTRAINT "FK_a80e0ee839a2f10ba4b86e19998" FOREIGN KEY ("supersededBy") REFERENCES public.instance_ai_observations(id);


--
-- Name: folder FK_a8260b0b36939c6247f385b8221; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.folder
    ADD CONSTRAINT "FK_a8260b0b36939c6247f385b8221" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: oauth_authorization_codes FK_aa8d3560484944c19bdf79ffa16; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.oauth_authorization_codes
    ADD CONSTRAINT "FK_aa8d3560484944c19bdf79ffa16" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: agent_files FK_aca4514cb500494b64356c2e164; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agent_files
    ADD CONSTRAINT "FK_aca4514cb500494b64356c2e164" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: chat_hub_messages FK_acf8926098f063cdbbad8497fd1; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "FK_acf8926098f063cdbbad8497fd1" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE SET NULL;


--
-- Name: agent_execution FK_add2432fb6034cc18b6af299dce; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agent_execution
    ADD CONSTRAINT "FK_add2432fb6034cc18b6af299dce" FOREIGN KEY ("threadId") REFERENCES public.agent_execution_threads(id) ON DELETE CASCADE;


--
-- Name: oauth_refresh_tokens FK_b388696ce4d8be7ffbe8d3e4b69; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.oauth_refresh_tokens
    ADD CONSTRAINT "FK_b388696ce4d8be7ffbe8d3e4b69" FOREIGN KEY ("clientId") REFERENCES public.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: workflow_publish_history FK_b4cfbc7556d07f36ca177f5e473; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_publish_history
    ADD CONSTRAINT "FK_b4cfbc7556d07f36ca177f5e473" FOREIGN KEY ("versionId") REFERENCES public.workflow_history("versionId") ON DELETE SET NULL;


--
-- Name: agent_task_run_lock FK_b57a2862ae869aab24e54cefd48; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agent_task_run_lock
    ADD CONSTRAINT "FK_b57a2862ae869aab24e54cefd48" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: chat_hub_tools FK_b8030b47af9213f1fd15450fb7f; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_tools
    ADD CONSTRAINT "FK_b8030b47af9213f1fd15450fb7f" FOREIGN KEY ("ownerId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: instance_ai_pending_confirmations FK_ba67ee8dc311830a2eea89b6e96; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_pending_confirmations
    ADD CONSTRAINT "FK_ba67ee8dc311830a2eea89b6e96" FOREIGN KEY ("threadId") REFERENCES public.instance_ai_threads(id) ON DELETE CASCADE;


--
-- Name: role_mapping_rule FK_bb66e404c35996b0d6946177501; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.role_mapping_rule
    ADD CONSTRAINT "FK_bb66e404c35996b0d6946177501" FOREIGN KEY (role) REFERENCES public.role(slug) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: project_secrets_provider_access FK_bd264b81209355b543878deedb1; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.project_secrets_provider_access
    ADD CONSTRAINT "FK_bd264b81209355b543878deedb1" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: workflow_publish_history FK_c01316f8c2d7101ec4fa9809267; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_publish_history
    ADD CONSTRAINT "FK_c01316f8c2d7101ec4fa9809267" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: execution_annotation_tags FK_c1519757391996eb06064f0e7c8; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.execution_annotation_tags
    ADD CONSTRAINT "FK_c1519757391996eb06064f0e7c8" FOREIGN KEY ("annotationId") REFERENCES public.execution_annotations(id) ON DELETE CASCADE;


--
-- Name: data_table FK_c2a794257dee48af7c9abf681de; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.data_table
    ADD CONSTRAINT "FK_c2a794257dee48af7c9abf681de" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: agents_memory_entry_sources FK_c38e8a57a36b880e39a52ada2e8; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_memory_entry_sources
    ADD CONSTRAINT "FK_c38e8a57a36b880e39a52ada2e8" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: project_relation FK_c6b99592dc96b0d836d7a21db91; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.project_relation
    ADD CONSTRAINT "FK_c6b99592dc96b0d836d7a21db91" FOREIGN KEY (role) REFERENCES public.role(slug);


--
-- Name: agents_memory_entry_sources FK_cb7c15d22fd068a0806aa57fc03; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_memory_entry_sources
    ADD CONSTRAINT "FK_cb7c15d22fd068a0806aa57fc03" FOREIGN KEY ("observationId") REFERENCES public.agents_observations(id) ON DELETE CASCADE;


--
-- Name: chat_hub_messages FK_chat_hub_messages_agentId; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "FK_chat_hub_messages_agentId" FOREIGN KEY ("agentId") REFERENCES public.chat_hub_agents(id) ON DELETE SET NULL;


--
-- Name: chat_hub_sessions FK_chat_hub_sessions_agentId; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_sessions
    ADD CONSTRAINT "FK_chat_hub_sessions_agentId" FOREIGN KEY ("agentId") REFERENCES public.chat_hub_agents(id) ON DELETE SET NULL;


--
-- Name: agents_observations FK_d206432be97b7ed88d187479b1b; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agents_observations
    ADD CONSTRAINT "FK_d206432be97b7ed88d187479b1b" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: instance_ai_observations FK_d54fc84a6c8ac91b5e0db0378a4; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_observations
    ADD CONSTRAINT "FK_d54fc84a6c8ac91b5e0db0378a4" FOREIGN KEY ("observationScopeId") REFERENCES public.instance_ai_threads(id) ON DELETE CASCADE;


--
-- Name: dynamic_credential_entry FK_d61a12235d268a49af6a3c09c13; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.dynamic_credential_entry
    ADD CONSTRAINT "FK_d61a12235d268a49af6a3c09c13" FOREIGN KEY (resolver_id) REFERENCES public.dynamic_credential_resolver(id) ON DELETE CASCADE;


--
-- Name: evaluation_collection FK_d634a0c93fd7de68a87eab951b2; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.evaluation_collection
    ADD CONSTRAINT "FK_d634a0c93fd7de68a87eab951b2" FOREIGN KEY ("evaluationConfigId") REFERENCES public.evaluation_config(id) ON DELETE CASCADE;


--
-- Name: test_run FK_d6870d3b6e4c185d33926f423c8; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.test_run
    ADD CONSTRAINT "FK_d6870d3b6e4c185d33926f423c8" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: shared_workflow FK_daa206a04983d47d0a9c34649ce; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.shared_workflow
    ADD CONSTRAINT "FK_daa206a04983d47d0a9c34649ce" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: instance_ai_observations FK_daef2195a4a846eb70eed15e039; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_observations
    ADD CONSTRAINT "FK_daef2195a4a846eb70eed15e039" FOREIGN KEY ("parentId") REFERENCES public.instance_ai_observations(id);


--
-- Name: folder_tag FK_dc88164176283de80af47621746; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.folder_tag
    ADD CONSTRAINT "FK_dc88164176283de80af47621746" FOREIGN KEY ("tagId") REFERENCES public.tag_entity(id) ON DELETE CASCADE;


--
-- Name: role_mapping_rule_project FK_dd7ce4dfa09e95b36a626bd9de3; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.role_mapping_rule_project
    ADD CONSTRAINT "FK_dd7ce4dfa09e95b36a626bd9de3" FOREIGN KEY ("roleMappingRuleId") REFERENCES public.role_mapping_rule(id) ON DELETE CASCADE;


--
-- Name: workflow_published_version FK_df3428a541b802d6a63ac56e330; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_published_version
    ADD CONSTRAINT "FK_df3428a541b802d6a63ac56e330" FOREIGN KEY ("publishedVersionId") REFERENCES public.workflow_history("versionId") ON DELETE RESTRICT;


--
-- Name: instance_ai_pending_confirmations FK_df5fd25c8bbfd2b042602600d8e; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.instance_ai_pending_confirmations
    ADD CONSTRAINT "FK_df5fd25c8bbfd2b042602600d8e" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: user_api_keys FK_e131705cbbc8fb589889b02d457; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.user_api_keys
    ADD CONSTRAINT "FK_e131705cbbc8fb589889b02d457" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: chat_hub_messages FK_e22538eb50a71a17954cd7e076c; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "FK_e22538eb50a71a17954cd7e076c" FOREIGN KEY ("sessionId") REFERENCES public.chat_hub_sessions(id) ON DELETE CASCADE;


--
-- Name: test_case_execution FK_e48965fac35d0f5b9e7f51d8c44; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.test_case_execution
    ADD CONSTRAINT "FK_e48965fac35d0f5b9e7f51d8c44" FOREIGN KEY ("executionId") REFERENCES public.execution_entity(id) ON DELETE SET NULL;


--
-- Name: chat_hub_messages FK_e5d1fa722c5a8d38ac204746662; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "FK_e5d1fa722c5a8d38ac204746662" FOREIGN KEY ("previousMessageId") REFERENCES public.chat_hub_messages(id) ON DELETE CASCADE;


--
-- Name: chat_hub_session_tools FK_e649bf1295f4ed8d4299ed290f9; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_session_tools
    ADD CONSTRAINT "FK_e649bf1295f4ed8d4299ed290f9" FOREIGN KEY ("sessionId") REFERENCES public.chat_hub_sessions(id) ON DELETE CASCADE;


--
-- Name: chat_hub_sessions FK_e9ecf8ede7d989fcd18790fe36a; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.chat_hub_sessions
    ADD CONSTRAINT "FK_e9ecf8ede7d989fcd18790fe36a" FOREIGN KEY ("ownerId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: user FK_eaea92ee7bfb9c1b6cd01505d56; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT "FK_eaea92ee7bfb9c1b6cd01505d56" FOREIGN KEY ("roleSlug") REFERENCES public.role(slug);


--
-- Name: agent_execution_threads FK_f00b52d74fe11838e1fe086deea; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agent_execution_threads
    ADD CONSTRAINT "FK_f00b52d74fe11838e1fe086deea" FOREIGN KEY ("taskVersionId") REFERENCES public.agent_history("versionId") ON DELETE SET NULL;


--
-- Name: evaluation_collection FK_f4561f38b5a22a4f090d5cd3eae; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.evaluation_collection
    ADD CONSTRAINT "FK_f4561f38b5a22a4f090d5cd3eae" FOREIGN KEY ("createdById") REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: agent_task_definition FK_f45d0535a2ed59b6c2dd6da98a0; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.agent_task_definition
    ADD CONSTRAINT "FK_f45d0535a2ed59b6c2dd6da98a0" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: evaluation_config FK_fd7542bb123074760285dc1bbf3; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.evaluation_config
    ADD CONSTRAINT "FK_fd7542bb123074760285dc1bbf3" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: role_scope FK_role; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.role_scope
    ADD CONSTRAINT "FK_role" FOREIGN KEY ("roleSlug") REFERENCES public.role(slug) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: role_scope FK_scope; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.role_scope
    ADD CONSTRAINT "FK_scope" FOREIGN KEY ("scopeSlug") REFERENCES public.scope(slug) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: test_run FK_test_run_collection_id; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.test_run
    ADD CONSTRAINT "FK_test_run_collection_id" FOREIGN KEY ("collectionId") REFERENCES public.evaluation_collection(id) ON DELETE SET NULL;


--
-- Name: test_run FK_test_run_evaluation_config_id; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.test_run
    ADD CONSTRAINT "FK_test_run_evaluation_config_id" FOREIGN KEY ("evaluationConfigId") REFERENCES public.evaluation_config(id) ON DELETE SET NULL;


--
-- Name: auth_identity auth_identity_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.auth_identity
    ADD CONSTRAINT "auth_identity_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."user"(id);


--
-- Name: credentials_entity credentials_entity_resolverId_foreign; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.credentials_entity
    ADD CONSTRAINT "credentials_entity_resolverId_foreign" FOREIGN KEY ("resolverId") REFERENCES public.dynamic_credential_resolver(id) ON DELETE SET NULL;


--
-- Name: execution_data execution_data_fk; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.execution_data
    ADD CONSTRAINT execution_data_fk FOREIGN KEY ("executionId") REFERENCES public.execution_entity(id) ON DELETE CASCADE;


--
-- Name: execution_entity fk_execution_entity_workflow_id; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.execution_entity
    ADD CONSTRAINT fk_execution_entity_workflow_id FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: webhook_entity fk_webhook_entity_workflow_id; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.webhook_entity
    ADD CONSTRAINT fk_webhook_entity_workflow_id FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: workflow_entity fk_workflow_parent_folder; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflow_entity
    ADD CONSTRAINT fk_workflow_parent_folder FOREIGN KEY ("parentFolderId") REFERENCES public.folder(id) ON DELETE CASCADE;


--
-- Name: workflows_tags fk_workflows_tags_tag_id; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflows_tags
    ADD CONSTRAINT fk_workflows_tags_tag_id FOREIGN KEY ("tagId") REFERENCES public.tag_entity(id) ON DELETE CASCADE;


--
-- Name: workflows_tags fk_workflows_tags_workflow_id; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.workflows_tags
    ADD CONSTRAINT fk_workflows_tags_workflow_id FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: project projects_creatorId_foreign; Type: FK CONSTRAINT; Schema: public; Owner: integration_user
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT "projects_creatorId_foreign" FOREIGN KEY ("creatorId") REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: SCHEMA ai; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA ai TO ai_user;


--
-- Name: SCHEMA audit; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA audit TO audit_user;


--
-- Name: SCHEMA cmdb; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA cmdb TO cmdb_user;


--
-- Name: SCHEMA fsm; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA fsm TO fsm_user;


--
-- Name: SCHEMA integration; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA integration TO integration_user;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT CREATE ON SCHEMA public TO fsm_user;
GRANT CREATE ON SCHEMA public TO cmdb_user;
GRANT CREATE ON SCHEMA public TO ai_user;
GRANT CREATE ON SCHEMA public TO integration_user;
GRANT CREATE ON SCHEMA public TO audit_user;


--
-- Name: TABLE audit_log; Type: ACL; Schema: audit; Owner: postgres
--

GRANT ALL ON TABLE audit.audit_log TO audit_user;


--
-- Name: TABLE users; Type: ACL; Schema: integration; Owner: postgres
--

GRANT ALL ON TABLE integration.users TO integration_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: ai; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA ai GRANT ALL ON SEQUENCES  TO ai_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: ai; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA ai GRANT ALL ON TABLES  TO ai_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: audit; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA audit GRANT ALL ON SEQUENCES  TO audit_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: audit; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA audit GRANT ALL ON TABLES  TO audit_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: cmdb; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA cmdb GRANT ALL ON SEQUENCES  TO cmdb_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: cmdb; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA cmdb GRANT ALL ON TABLES  TO cmdb_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: fsm; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA fsm GRANT ALL ON SEQUENCES  TO fsm_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: fsm; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA fsm GRANT ALL ON TABLES  TO fsm_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: integration; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA integration GRANT ALL ON SEQUENCES  TO integration_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: integration; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA integration GRANT ALL ON TABLES  TO integration_user;


--
-- PostgreSQL database dump complete
--

\unrestrict bciPvIy5rZXSnnxTCThqNOfc5kofuAO3rSlR94EFvBSjxhGTqhNTbyOTpjD2xxt

