--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: areas_area; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.areas_area (
    id integer NOT NULL,
    nombre character varying(120) NOT NULL,
    descripcion text NOT NULL,
    estado boolean NOT NULL,
    usuario_responsable_area_id bigint,
    trial174 character(1)
);


ALTER TABLE public.areas_area OWNER TO postgres;

--
-- Name: areas_area_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.areas_area_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.areas_area_id_seq OWNER TO postgres;

--
-- Name: areas_area_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.areas_area_id_seq OWNED BY public.areas_area.id;


--
-- Name: auth_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_group (
    id integer NOT NULL,
    name character varying(150) NOT NULL,
    trial177 character(1)
);


ALTER TABLE public.auth_group OWNER TO postgres;

--
-- Name: auth_group_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_group_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auth_group_id_seq OWNER TO postgres;

--
-- Name: auth_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_group_id_seq OWNED BY public.auth_group.id;


--
-- Name: auth_group_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_group_permissions (
    id integer NOT NULL,
    group_id integer NOT NULL,
    permission_id integer NOT NULL,
    trial177 character(1)
);


ALTER TABLE public.auth_group_permissions OWNER TO postgres;

--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_group_permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auth_group_permissions_id_seq OWNER TO postgres;

--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_group_permissions_id_seq OWNED BY public.auth_group_permissions.id;


--
-- Name: auth_permission; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_permission (
    id integer NOT NULL,
    content_type_id integer NOT NULL,
    codename character varying(100) NOT NULL,
    name character varying(255) NOT NULL,
    trial177 character(1)
);


ALTER TABLE public.auth_permission OWNER TO postgres;

--
-- Name: auth_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_permission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auth_permission_id_seq OWNER TO postgres;

--
-- Name: auth_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_permission_id_seq OWNED BY public.auth_permission.id;


--
-- Name: auth_user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_user (
    id integer NOT NULL,
    password character varying(128) NOT NULL,
    last_login timestamp without time zone,
    is_superuser boolean NOT NULL,
    username character varying(150) NOT NULL,
    last_name character varying(150) NOT NULL,
    email character varying(254) NOT NULL,
    is_staff boolean NOT NULL,
    is_active boolean NOT NULL,
    date_joined timestamp without time zone NOT NULL,
    first_name character varying(150) NOT NULL,
    trial180 character(1)
);


ALTER TABLE public.auth_user OWNER TO postgres;

--
-- Name: auth_user_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_user_groups (
    id integer NOT NULL,
    user_id integer NOT NULL,
    group_id integer NOT NULL,
    trial180 character(1)
);


ALTER TABLE public.auth_user_groups OWNER TO postgres;

--
-- Name: auth_user_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_user_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auth_user_groups_id_seq OWNER TO postgres;

--
-- Name: auth_user_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_user_groups_id_seq OWNED BY public.auth_user_groups.id;


--
-- Name: auth_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auth_user_id_seq OWNER TO postgres;

--
-- Name: auth_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_user_id_seq OWNED BY public.auth_user.id;


--
-- Name: auth_user_user_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_user_user_permissions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    permission_id integer NOT NULL,
    trial180 character(1)
);


ALTER TABLE public.auth_user_user_permissions OWNER TO postgres;

--
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_user_user_permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auth_user_user_permissions_id_seq OWNER TO postgres;

--
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_user_user_permissions_id_seq OWNED BY public.auth_user_user_permissions.id;


--
-- Name: backup_restore_activesession; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.backup_restore_activesession (
    id integer NOT NULL,
    last_activity timestamp without time zone NOT NULL,
    session_key character varying(64) NOT NULL,
    user_id bigint NOT NULL,
    trial180 character(1)
);


ALTER TABLE public.backup_restore_activesession OWNER TO postgres;

--
-- Name: backup_restore_activesession_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.backup_restore_activesession_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backup_restore_activesession_id_seq OWNER TO postgres;

--
-- Name: backup_restore_activesession_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.backup_restore_activesession_id_seq OWNED BY public.backup_restore_activesession.id;


--
-- Name: backup_restore_systemrestorelog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.backup_restore_systemrestorelog (
    id integer NOT NULL,
    backup_file character varying(255) NOT NULL,
    executed_at timestamp without time zone NOT NULL,
    ip_address character(39),
    user_id bigint,
    trial180 character(1)
);


ALTER TABLE public.backup_restore_systemrestorelog OWNER TO postgres;

--
-- Name: backup_restore_systemrestorelog_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.backup_restore_systemrestorelog_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.backup_restore_systemrestorelog_id_seq OWNER TO postgres;

--
-- Name: backup_restore_systemrestorelog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.backup_restore_systemrestorelog_id_seq OWNED BY public.backup_restore_systemrestorelog.id;


--
-- Name: django_admin_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_admin_log (
    id integer NOT NULL,
    object_id text,
    object_repr character varying(200) NOT NULL,
    action_flag smallint NOT NULL,
    change_message text NOT NULL,
    content_type_id integer,
    user_id integer NOT NULL,
    action_time timestamp without time zone NOT NULL,
    trial180 character(1)
);


ALTER TABLE public.django_admin_log OWNER TO postgres;

--
-- Name: django_admin_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.django_admin_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.django_admin_log_id_seq OWNER TO postgres;

--
-- Name: django_admin_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.django_admin_log_id_seq OWNED BY public.django_admin_log.id;


--
-- Name: django_content_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_content_type (
    id integer NOT NULL,
    app_label character varying(100) NOT NULL,
    model character varying(100) NOT NULL,
    trial180 character(1)
);


ALTER TABLE public.django_content_type OWNER TO postgres;

--
-- Name: django_content_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.django_content_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.django_content_type_id_seq OWNER TO postgres;

--
-- Name: django_content_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.django_content_type_id_seq OWNED BY public.django_content_type.id;


--
-- Name: django_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_migrations (
    id integer NOT NULL,
    app character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    applied timestamp without time zone NOT NULL,
    trial180 character(1)
);


ALTER TABLE public.django_migrations OWNER TO postgres;

--
-- Name: django_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.django_migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.django_migrations_id_seq OWNER TO postgres;

--
-- Name: django_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.django_migrations_id_seq OWNED BY public.django_migrations.id;


--
-- Name: django_session; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_session (
    session_key character varying(40) NOT NULL,
    session_data text NOT NULL,
    expire_date timestamp without time zone NOT NULL,
    trial183 character(1)
);


ALTER TABLE public.django_session OWNER TO postgres;

--
-- Name: projects_adjuntoauditlog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects_adjuntoauditlog (
    id integer NOT NULL,
    tipo character varying(20) NOT NULL,
    adjunto_id integer NOT NULL,
    accion character varying(20) NOT NULL,
    fecha timestamp without time zone NOT NULL,
    nombre_archivo character varying(255) NOT NULL,
    nombre_anterior character varying(255) NOT NULL,
    nombre_nuevo character varying(255) NOT NULL,
    proyecto_id integer,
    tarea_id integer,
    usuario_id bigint NOT NULL,
    trial183 character(1)
);


ALTER TABLE public.projects_adjuntoauditlog OWNER TO postgres;

--
-- Name: projects_adjuntoauditlog_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projects_adjuntoauditlog_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.projects_adjuntoauditlog_id_seq OWNER TO postgres;

--
-- Name: projects_adjuntoauditlog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projects_adjuntoauditlog_id_seq OWNED BY public.projects_adjuntoauditlog.id;


--
-- Name: projects_adjuntoproyecto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects_adjuntoproyecto (
    id integer NOT NULL,
    archivo character varying(100) NOT NULL,
    nombre_original character varying(255) NOT NULL,
    fecha timestamp without time zone NOT NULL,
    proyecto_id bigint NOT NULL,
    subido_por_id bigint NOT NULL,
    trial183 character(1)
);


ALTER TABLE public.projects_adjuntoproyecto OWNER TO postgres;

--
-- Name: projects_adjuntoproyecto_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projects_adjuntoproyecto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.projects_adjuntoproyecto_id_seq OWNER TO postgres;

--
-- Name: projects_adjuntoproyecto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projects_adjuntoproyecto_id_seq OWNED BY public.projects_adjuntoproyecto.id;


--
-- Name: projects_comentarioauditlog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects_comentarioauditlog (
    id integer NOT NULL,
    tipo character varying(20) NOT NULL,
    comentario_id integer NOT NULL,
    accion character varying(20) NOT NULL,
    fecha timestamp without time zone NOT NULL,
    texto_anterior text NOT NULL,
    texto_nuevo text NOT NULL,
    proyecto_id integer,
    tarea_id integer,
    usuario_id bigint NOT NULL,
    trial183 character(1)
);


ALTER TABLE public.projects_comentarioauditlog OWNER TO postgres;

--
-- Name: projects_comentarioauditlog_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projects_comentarioauditlog_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.projects_comentarioauditlog_id_seq OWNER TO postgres;

--
-- Name: projects_comentarioauditlog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projects_comentarioauditlog_id_seq OWNED BY public.projects_comentarioauditlog.id;


--
-- Name: projects_comentarioproyecto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects_comentarioproyecto (
    id integer NOT NULL,
    texto text NOT NULL,
    fecha timestamp without time zone NOT NULL,
    proyecto_id bigint NOT NULL,
    usuario_id bigint NOT NULL,
    editado_por_id bigint,
    fecha_edicion timestamp without time zone,
    trial183 character(1)
);


ALTER TABLE public.projects_comentarioproyecto OWNER TO postgres;

--
-- Name: projects_comentarioproyecto_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projects_comentarioproyecto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.projects_comentarioproyecto_id_seq OWNER TO postgres;

--
-- Name: projects_comentarioproyecto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projects_comentarioproyecto_id_seq OWNED BY public.projects_comentarioproyecto.id;


--
-- Name: projects_eje; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects_eje (
    id_eje integer NOT NULL,
    nombre_eje character varying(300) NOT NULL,
    trial187 character(1)
);


ALTER TABLE public.projects_eje OWNER TO postgres;

--
-- Name: projects_eje_id_eje_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projects_eje_id_eje_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.projects_eje_id_eje_seq OWNER TO postgres;

--
-- Name: projects_eje_id_eje_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projects_eje_id_eje_seq OWNED BY public.projects_eje.id_eje;


--
-- Name: projects_etapa; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects_etapa (
    id integer NOT NULL,
    nombre character varying(120) NOT NULL,
    orden integer NOT NULL,
    estado character varying(30) NOT NULL,
    porcentaje_avance numeric NOT NULL,
    proyecto_id bigint NOT NULL,
    trial187 character(1)
);


ALTER TABLE public.projects_etapa OWNER TO postgres;

--
-- Name: projects_etapa_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projects_etapa_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.projects_etapa_id_seq OWNER TO postgres;

--
-- Name: projects_etapa_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projects_etapa_id_seq OWNED BY public.projects_etapa.id;


--
-- Name: projects_indicador; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects_indicador (
    id integer NOT NULL,
    descripcion text NOT NULL,
    unidad_medida character varying(50) NOT NULL,
    frecuencia character varying(50) NOT NULL,
    proyecto_id bigint NOT NULL,
    trial187 character(1)
);


ALTER TABLE public.projects_indicador OWNER TO postgres;

--
-- Name: projects_indicador_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projects_indicador_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.projects_indicador_id_seq OWNER TO postgres;

--
-- Name: projects_indicador_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projects_indicador_id_seq OWNED BY public.projects_indicador.id;


--
-- Name: projects_objetivoestrategico; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects_objetivoestrategico (
    id integer NOT NULL,
    descripcion text NOT NULL,
    programa_id character varying(10) NOT NULL,
    trial187 character(1)
);


ALTER TABLE public.projects_objetivoestrategico OWNER TO postgres;

--
-- Name: projects_objetivoestrategico_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projects_objetivoestrategico_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.projects_objetivoestrategico_id_seq OWNER TO postgres;

--
-- Name: projects_objetivoestrategico_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projects_objetivoestrategico_id_seq OWNED BY public.projects_objetivoestrategico.id;


--
-- Name: projects_plan; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects_plan (
    id_plan integer NOT NULL,
    nombre_plan character varying(300) NOT NULL,
    proposito_politica_publica text NOT NULL,
    vision_estrategica text NOT NULL,
    eje_id integer NOT NULL,
    trial187 character(1)
);


ALTER TABLE public.projects_plan OWNER TO postgres;

--
-- Name: projects_plan_id_plan_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projects_plan_id_plan_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.projects_plan_id_plan_seq OWNER TO postgres;

--
-- Name: projects_plan_id_plan_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projects_plan_id_plan_seq OWNED BY public.projects_plan.id_plan;


--
-- Name: projects_programa; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects_programa (
    id_programa character varying(10) NOT NULL,
    nombre_programa character varying(500) NOT NULL,
    plan_id integer NOT NULL,
    trial187 character(1)
);


ALTER TABLE public.projects_programa OWNER TO postgres;

--
-- Name: projects_proyecto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects_proyecto (
    id integer NOT NULL,
    nombre character varying(150) NOT NULL,
    descripcion text NOT NULL,
    fecha_inicio date NOT NULL,
    fecha_fin_estimada date NOT NULL,
    fecha_fin_real date,
    estado character varying(20) NOT NULL,
    porcentaje_avance numeric NOT NULL,
    fecha_creacion timestamp without time zone NOT NULL,
    creado_por_id bigint NOT NULL,
    programa_id character varying(10),
    objetivo_estrategico_id bigint,
    secretaria_id bigint,
    usuario_responsable_id bigint,
    area_id bigint,
    trial187 character(1),
    fuente_financiamiento character varying(20) NOT NULL,
    presupuesto_total numeric(14,2) NOT NULL
);


ALTER TABLE public.projects_proyecto OWNER TO postgres;

--
-- Name: projects_proyecto_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projects_proyecto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.projects_proyecto_id_seq OWNER TO postgres;

--
-- Name: projects_proyecto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projects_proyecto_id_seq OWNED BY public.projects_proyecto.id;


--
-- Name: projects_proyectoarea; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects_proyectoarea (
    id integer NOT NULL,
    area_id bigint NOT NULL,
    proyecto_id bigint NOT NULL,
    trial187 character(1)
);


ALTER TABLE public.projects_proyectoarea OWNER TO postgres;

--
-- Name: projects_proyectoarea_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projects_proyectoarea_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.projects_proyectoarea_id_seq OWNER TO postgres;

--
-- Name: projects_proyectoarea_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projects_proyectoarea_id_seq OWNED BY public.projects_proyectoarea.id;


--
-- Name: projects_proyectoequipo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects_proyectoequipo (
    id integer NOT NULL,
    proyecto_id bigint NOT NULL,
    usuario_id bigint NOT NULL,
    trial190 character(1)
);


ALTER TABLE public.projects_proyectoequipo OWNER TO postgres;

--
-- Name: projects_proyectoequipo_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projects_proyectoequipo_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.projects_proyectoequipo_id_seq OWNER TO postgres;

--
-- Name: projects_proyectoequipo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projects_proyectoequipo_id_seq OWNED BY public.projects_proyectoequipo.id;


--
-- Name: projects_proyectopresupuestoitem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects_proyectopresupuestoitem (
    id bigint NOT NULL,
    categoria_gasto character varying(30) NOT NULL,
    monto numeric(14,2) NOT NULL,
    detalle character varying(255) NOT NULL,
    numero_expediente character varying(100) NOT NULL,
    es_viaticos boolean NOT NULL,
    dotacion_tipo character varying(30) NOT NULL,
    horas_hombre numeric(10,2),
    orden integer NOT NULL,
    proyecto_id bigint NOT NULL,
    CONSTRAINT projects_proyectopresupuestoitem_orden_check CHECK ((orden >= 0)),
    CONSTRAINT proy_pres_horas_gte_0 CHECK (((horas_hombre IS NULL) OR (horas_hombre >= (0)::numeric))),
    CONSTRAINT proy_pres_monto_gte_0 CHECK ((monto >= (0)::numeric))
);


ALTER TABLE public.projects_proyectopresupuestoitem OWNER TO postgres;

--
-- Name: projects_proyectopresupuestoitem_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.projects_proyectopresupuestoitem ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.projects_proyectopresupuestoitem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: secretarias_secretaria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.secretarias_secretaria (
    id integer NOT NULL,
    codigo character varying(20) NOT NULL,
    nombre character varying(150) NOT NULL,
    descripcion text NOT NULL,
    activa boolean NOT NULL,
    fecha_creacion timestamp without time zone NOT NULL,
    fecha_modificacion timestamp without time zone,
    usuario_creacion character varying(100) NOT NULL,
    usuario_modificacion character varying(100) NOT NULL,
    trial190 character(1)
);


ALTER TABLE public.secretarias_secretaria OWNER TO postgres;

--
-- Name: secretarias_secretaria_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.secretarias_secretaria_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.secretarias_secretaria_id_seq OWNER TO postgres;

--
-- Name: secretarias_secretaria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.secretarias_secretaria_id_seq OWNED BY public.secretarias_secretaria.id;


--
-- Name: sqlite_sequence; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sqlite_sequence (
    name text,
    seq text,
    trial190 character(1)
);


ALTER TABLE public.sqlite_sequence OWNER TO postgres;

--
-- Name: tasks_adjuntotarea; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tasks_adjuntotarea (
    id integer NOT NULL,
    archivo character varying(100) NOT NULL,
    nombre_original character varying(255) NOT NULL,
    fecha timestamp without time zone NOT NULL,
    subido_por_id bigint NOT NULL,
    tarea_id bigint NOT NULL,
    trial190 character(1)
);


ALTER TABLE public.tasks_adjuntotarea OWNER TO postgres;

--
-- Name: tasks_adjuntotarea_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tasks_adjuntotarea_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tasks_adjuntotarea_id_seq OWNER TO postgres;

--
-- Name: tasks_adjuntotarea_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tasks_adjuntotarea_id_seq OWNED BY public.tasks_adjuntotarea.id;


--
-- Name: tasks_comentariotarea; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tasks_comentariotarea (
    id integer NOT NULL,
    texto text NOT NULL,
    fecha timestamp without time zone NOT NULL,
    tarea_id bigint NOT NULL,
    usuario_id bigint NOT NULL,
    editado_por_id bigint,
    fecha_edicion timestamp without time zone,
    trial190 character(1)
);


ALTER TABLE public.tasks_comentariotarea OWNER TO postgres;

--
-- Name: tasks_comentariotarea_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tasks_comentariotarea_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tasks_comentariotarea_id_seq OWNER TO postgres;

--
-- Name: tasks_comentariotarea_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tasks_comentariotarea_id_seq OWNED BY public.tasks_comentariotarea.id;


--
-- Name: tasks_historialtarea; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tasks_historialtarea (
    id integer NOT NULL,
    comentario text NOT NULL,
    porcentaje_avance integer NOT NULL,
    fecha timestamp without time zone NOT NULL,
    tarea_id bigint NOT NULL,
    usuario_id bigint NOT NULL,
    porcentaje_anterior integer,
    trial193 character(1)
);


ALTER TABLE public.tasks_historialtarea OWNER TO postgres;

--
-- Name: tasks_historialtarea_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tasks_historialtarea_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tasks_historialtarea_id_seq OWNER TO postgres;

--
-- Name: tasks_historialtarea_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tasks_historialtarea_id_seq OWNED BY public.tasks_historialtarea.id;


--
-- Name: tasks_tarea; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tasks_tarea (
    id integer NOT NULL,
    titulo character varying(200) NOT NULL,
    descripcion text NOT NULL,
    fecha_inicio date NOT NULL,
    fecha_vencimiento date NOT NULL,
    estado character varying(20) NOT NULL,
    porcentaje_avance integer NOT NULL,
    prioridad character varying(20) NOT NULL,
    fecha_creacion timestamp without time zone NOT NULL,
    area_id bigint,
    etapa_id bigint,
    responsable_id bigint NOT NULL,
    secretaria_id bigint,
    proyecto_id bigint,
    tarea_padre_id bigint,
    trial193 character(1),
    orden integer NOT NULL,
    CONSTRAINT tasks_tarea_orden_check CHECK ((orden >= 0))
);


ALTER TABLE public.tasks_tarea OWNER TO postgres;

--
-- Name: tasks_tarea_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tasks_tarea_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tasks_tarea_id_seq OWNER TO postgres;

--
-- Name: tasks_tarea_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tasks_tarea_id_seq OWNED BY public.tasks_tarea.id;


--
-- Name: users_rol; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users_rol (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text NOT NULL,
    trial197 character(1)
);


ALTER TABLE public.users_rol OWNER TO postgres;

--
-- Name: users_rol_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_rol_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_rol_id_seq OWNER TO postgres;

--
-- Name: users_rol_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_rol_id_seq OWNED BY public.users_rol.id;


--
-- Name: users_usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users_usuario (
    id integer NOT NULL,
    nombre character varying(150) NOT NULL,
    email character varying(254) NOT NULL,
    password character varying(255) NOT NULL,
    estado boolean NOT NULL,
    fecha_creacion timestamp without time zone NOT NULL,
    rol_id bigint NOT NULL,
    area_id bigint,
    apellido character varying(150) NOT NULL,
    secretaria_id bigint,
    trial197 character(1),
    token_version integer NOT NULL,
    CONSTRAINT users_usuario_token_version_check CHECK ((token_version >= 0))
);


ALTER TABLE public.users_usuario OWNER TO postgres;

--
-- Name: users_usuario_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_usuario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_usuario_id_seq OWNER TO postgres;

--
-- Name: users_usuario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_usuario_id_seq OWNED BY public.users_usuario.id;


--
-- Name: areas_area id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.areas_area ALTER COLUMN id SET DEFAULT nextval('public.areas_area_id_seq'::regclass);


--
-- Name: auth_group id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group ALTER COLUMN id SET DEFAULT nextval('public.auth_group_id_seq'::regclass);


--
-- Name: auth_group_permissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group_permissions ALTER COLUMN id SET DEFAULT nextval('public.auth_group_permissions_id_seq'::regclass);


--
-- Name: auth_permission id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_permission ALTER COLUMN id SET DEFAULT nextval('public.auth_permission_id_seq'::regclass);


--
-- Name: auth_user id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user ALTER COLUMN id SET DEFAULT nextval('public.auth_user_id_seq'::regclass);


--
-- Name: auth_user_groups id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_groups ALTER COLUMN id SET DEFAULT nextval('public.auth_user_groups_id_seq'::regclass);


--
-- Name: auth_user_user_permissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_user_permissions ALTER COLUMN id SET DEFAULT nextval('public.auth_user_user_permissions_id_seq'::regclass);


--
-- Name: backup_restore_activesession id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backup_restore_activesession ALTER COLUMN id SET DEFAULT nextval('public.backup_restore_activesession_id_seq'::regclass);


--
-- Name: backup_restore_systemrestorelog id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backup_restore_systemrestorelog ALTER COLUMN id SET DEFAULT nextval('public.backup_restore_systemrestorelog_id_seq'::regclass);


--
-- Name: django_admin_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_admin_log ALTER COLUMN id SET DEFAULT nextval('public.django_admin_log_id_seq'::regclass);


--
-- Name: django_content_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_content_type ALTER COLUMN id SET DEFAULT nextval('public.django_content_type_id_seq'::regclass);


--
-- Name: django_migrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_migrations ALTER COLUMN id SET DEFAULT nextval('public.django_migrations_id_seq'::regclass);


--
-- Name: projects_adjuntoauditlog id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_adjuntoauditlog ALTER COLUMN id SET DEFAULT nextval('public.projects_adjuntoauditlog_id_seq'::regclass);


--
-- Name: projects_adjuntoproyecto id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_adjuntoproyecto ALTER COLUMN id SET DEFAULT nextval('public.projects_adjuntoproyecto_id_seq'::regclass);


--
-- Name: projects_comentarioauditlog id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_comentarioauditlog ALTER COLUMN id SET DEFAULT nextval('public.projects_comentarioauditlog_id_seq'::regclass);


--
-- Name: projects_comentarioproyecto id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_comentarioproyecto ALTER COLUMN id SET DEFAULT nextval('public.projects_comentarioproyecto_id_seq'::regclass);


--
-- Name: projects_eje id_eje; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_eje ALTER COLUMN id_eje SET DEFAULT nextval('public.projects_eje_id_eje_seq'::regclass);


--
-- Name: projects_etapa id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_etapa ALTER COLUMN id SET DEFAULT nextval('public.projects_etapa_id_seq'::regclass);


--
-- Name: projects_indicador id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_indicador ALTER COLUMN id SET DEFAULT nextval('public.projects_indicador_id_seq'::regclass);


--
-- Name: projects_objetivoestrategico id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_objetivoestrategico ALTER COLUMN id SET DEFAULT nextval('public.projects_objetivoestrategico_id_seq'::regclass);


--
-- Name: projects_plan id_plan; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_plan ALTER COLUMN id_plan SET DEFAULT nextval('public.projects_plan_id_plan_seq'::regclass);


--
-- Name: projects_proyecto id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_proyecto ALTER COLUMN id SET DEFAULT nextval('public.projects_proyecto_id_seq'::regclass);


--
-- Name: projects_proyectoarea id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_proyectoarea ALTER COLUMN id SET DEFAULT nextval('public.projects_proyectoarea_id_seq'::regclass);


--
-- Name: projects_proyectoequipo id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_proyectoequipo ALTER COLUMN id SET DEFAULT nextval('public.projects_proyectoequipo_id_seq'::regclass);


--
-- Name: secretarias_secretaria id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.secretarias_secretaria ALTER COLUMN id SET DEFAULT nextval('public.secretarias_secretaria_id_seq'::regclass);


--
-- Name: tasks_adjuntotarea id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks_adjuntotarea ALTER COLUMN id SET DEFAULT nextval('public.tasks_adjuntotarea_id_seq'::regclass);


--
-- Name: tasks_comentariotarea id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks_comentariotarea ALTER COLUMN id SET DEFAULT nextval('public.tasks_comentariotarea_id_seq'::regclass);


--
-- Name: tasks_historialtarea id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks_historialtarea ALTER COLUMN id SET DEFAULT nextval('public.tasks_historialtarea_id_seq'::regclass);


--
-- Name: tasks_tarea id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks_tarea ALTER COLUMN id SET DEFAULT nextval('public.tasks_tarea_id_seq'::regclass);


--
-- Name: users_rol id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users_rol ALTER COLUMN id SET DEFAULT nextval('public.users_rol_id_seq'::regclass);


--
-- Name: users_usuario id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users_usuario ALTER COLUMN id SET DEFAULT nextval('public.users_usuario_id_seq'::regclass);


--
-- Data for Name: areas_area; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.areas_area (id, nombre, descripcion, estado, usuario_responsable_area_id, trial174) FROM stdin;
1	Presidencia		t	\N	T
2	Desarrollo		t	\N	T
3	Infraestructura		t	\N	T
4	Comunicación		t	\N	T
5	Recursos Humanos		t	\N	T
\.


--
-- Data for Name: auth_group; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_group (id, name, trial177) FROM stdin;
\.


--
-- Data for Name: auth_group_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_group_permissions (id, group_id, permission_id, trial177) FROM stdin;
\.


--
-- Data for Name: auth_permission; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_permission (id, content_type_id, codename, name, trial177) FROM stdin;
1	1	add_logentry	Can add log entry	T
2	1	change_logentry	Can change log entry	T
3	1	delete_logentry	Can delete log entry	T
4	1	view_logentry	Can view log entry	T
5	2	add_permission	Can add permission	T
6	2	change_permission	Can change permission	T
7	2	delete_permission	Can delete permission	T
8	2	view_permission	Can view permission	T
9	3	add_group	Can add group	T
10	3	change_group	Can change group	T
11	3	delete_group	Can delete group	T
12	3	view_group	Can view group	T
13	4	add_user	Can add user	T
14	4	change_user	Can change user	T
15	4	delete_user	Can delete user	T
16	4	view_user	Can view user	T
17	5	add_contenttype	Can add content type	T
18	5	change_contenttype	Can change content type	T
19	5	delete_contenttype	Can delete content type	T
20	5	view_contenttype	Can view content type	T
21	6	add_session	Can add session	T
22	6	change_session	Can change session	T
23	6	delete_session	Can delete session	T
24	6	view_session	Can view session	T
25	7	add_rol	Can add rol	T
26	7	change_rol	Can change rol	T
27	7	delete_rol	Can delete rol	T
28	7	view_rol	Can view rol	T
29	8	add_usuario	Can add usuario	T
30	8	change_usuario	Can change usuario	T
31	8	delete_usuario	Can delete usuario	T
32	8	view_usuario	Can view usuario	T
33	9	add_area	Can add area	T
34	9	change_area	Can change area	T
35	9	delete_area	Can delete area	T
36	9	view_area	Can view area	T
37	10	add_secretaria	Can add Secretaría	T
38	10	change_secretaria	Can change Secretaría	T
39	10	delete_secretaria	Can delete Secretaría	T
40	10	view_secretaria	Can view Secretaría	T
41	11	add_proyecto	Can add proyecto	T
42	11	change_proyecto	Can change proyecto	T
43	11	delete_proyecto	Can delete proyecto	T
44	11	view_proyecto	Can view proyecto	T
45	12	add_etapa	Can add etapa	T
46	12	change_etapa	Can change etapa	T
47	12	delete_etapa	Can delete etapa	T
48	12	view_etapa	Can view etapa	T
49	13	add_proyectoarea	Can add proyecto area	T
50	13	change_proyectoarea	Can change proyecto area	T
51	13	delete_proyectoarea	Can delete proyecto area	T
52	13	view_proyectoarea	Can view proyecto area	T
53	14	add_comentarioproyecto	Can add comentario proyecto	T
54	14	change_comentarioproyecto	Can change comentario proyecto	T
55	14	delete_comentarioproyecto	Can delete comentario proyecto	T
56	14	view_comentarioproyecto	Can view comentario proyecto	T
57	15	add_eje	Can add Eje	T
58	15	change_eje	Can change Eje	T
59	15	delete_eje	Can delete Eje	T
60	15	view_eje	Can view Eje	T
61	16	add_plan	Can add Plan	T
62	16	change_plan	Can change Plan	T
63	16	delete_plan	Can delete Plan	T
64	16	view_plan	Can view Plan	T
65	17	add_programa	Can add Programa	T
66	17	change_programa	Can change Programa	T
67	17	delete_programa	Can delete Programa	T
68	17	view_programa	Can view Programa	T
69	18	add_objetivoestrategico	Can add Objetivo Estratégico	T
70	18	change_objetivoestrategico	Can change Objetivo Estratégico	T
71	18	delete_objetivoestrategico	Can delete Objetivo Estratégico	T
72	18	view_objetivoestrategico	Can view Objetivo Estratégico	T
73	19	add_indicador	Can add Indicador	T
74	19	change_indicador	Can change Indicador	T
75	19	delete_indicador	Can delete Indicador	T
76	19	view_indicador	Can view Indicador	T
77	20	add_proyectoequipo	Can add Miembro del equipo	T
78	20	change_proyectoequipo	Can change Miembro del equipo	T
79	20	delete_proyectoequipo	Can delete Miembro del equipo	T
80	20	view_proyectoequipo	Can view Miembro del equipo	T
81	21	add_tarea	Can add tarea	T
82	21	change_tarea	Can change tarea	T
83	21	delete_tarea	Can delete tarea	T
84	21	view_tarea	Can view tarea	T
85	22	add_historialtarea	Can add historial tarea	T
86	22	change_historialtarea	Can change historial tarea	T
87	22	delete_historialtarea	Can delete historial tarea	T
88	22	view_historialtarea	Can view historial tarea	T
89	23	add_systemrestorelog	Can add Log de Restore	T
90	23	change_systemrestorelog	Can change Log de Restore	T
91	23	delete_systemrestorelog	Can delete Log de Restore	T
92	23	view_systemrestorelog	Can view Log de Restore	T
93	24	add_activesession	Can add Sesión activa	T
94	24	change_activesession	Can change Sesión activa	T
95	24	delete_activesession	Can delete Sesión activa	T
96	24	view_activesession	Can view Sesión activa	T
97	25	add_adjuntoproyecto	Can add adjunto proyecto	T
98	25	change_adjuntoproyecto	Can change adjunto proyecto	T
99	25	delete_adjuntoproyecto	Can delete adjunto proyecto	T
100	25	view_adjuntoproyecto	Can view adjunto proyecto	T
101	26	add_adjuntotarea	Can add adjunto tarea	T
102	26	change_adjuntotarea	Can change adjunto tarea	T
103	26	delete_adjuntotarea	Can delete adjunto tarea	T
104	26	view_adjuntotarea	Can view adjunto tarea	T
105	27	add_comentariotarea	Can add comentario tarea	T
106	27	change_comentariotarea	Can change comentario tarea	T
107	27	delete_comentariotarea	Can delete comentario tarea	T
108	27	view_comentariotarea	Can view comentario tarea	T
109	28	add_comentarioauditlog	Can add comentario audit log	T
110	28	change_comentarioauditlog	Can change comentario audit log	T
111	28	delete_comentarioauditlog	Can delete comentario audit log	T
112	28	view_comentarioauditlog	Can view comentario audit log	T
113	29	add_adjuntoauditlog	Can add adjunto audit log	T
114	29	change_adjuntoauditlog	Can change adjunto audit log	T
115	29	delete_adjuntoauditlog	Can delete adjunto audit log	T
116	29	view_adjuntoauditlog	Can view adjunto audit log	T
117	30	add_proyectopresupuestoitem	Can add Item presupuestario	\N
118	30	change_proyectopresupuestoitem	Can change Item presupuestario	\N
119	30	delete_proyectopresupuestoitem	Can delete Item presupuestario	\N
120	30	view_proyectopresupuestoitem	Can view Item presupuestario	\N
\.


--
-- Data for Name: auth_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_user (id, password, last_login, is_superuser, username, last_name, email, is_staff, is_active, date_joined, first_name, trial180) FROM stdin;
\.


--
-- Data for Name: auth_user_groups; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_user_groups (id, user_id, group_id, trial180) FROM stdin;
\.


--
-- Data for Name: auth_user_user_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_user_user_permissions (id, user_id, permission_id, trial180) FROM stdin;
\.


--
-- Data for Name: backup_restore_activesession; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.backup_restore_activesession (id, last_activity, session_key, user_id, trial180) FROM stdin;
2	2026-02-26 19:40:13.021534	sess_1772125610984_anlenljbrw	6	T
4	2026-02-26 18:06:02.718335	sess_1772125960625_hh47lzyx5n	2	T
5	2026-02-27 19:01:33.207863	sess_1772195043775_dla59sz3qz	6	T
11	2026-02-27 19:02:42.252393	sess_1772215322624_8j91ee26up	2	T
15	2026-02-27 19:02:49.413703	sess_1772217253752_1o6m9st6zr	4	T
16	2026-03-02 13:43:30.916651	sess_1772457503127_8xprlvktam	6	T
19	2026-03-04 14:58:52.133546	sess_1772459016088_sb39d37tdw	6	T
26	2026-03-04 14:56:31.435378	sess_1772549823440_gg6zw8xvpc	6	T
29	2026-03-04 13:17:15.233946	sess_1772563082396_t7iey1h6ow	9	T
30	2026-03-04 17:24:53.394624	sess_1772638725413_2kancn7et0	6	T
124	2026-03-12 16:12:40.443692	sess_1773323120431_vmbf1ji3du	17	\N
123	2026-03-12 16:12:40.393228	sess_1773329003664_x4qrxhd7t7	6	\N
93	2026-03-11 20:16:50.493962	sess_1773260210241_akyvz12krt	6	\N
41	2026-03-09 16:40:09.710196	sess_1773073928663_wybull04fh	9	\N
42	2026-03-09 16:40:13.905929	sess_1773073932787_tnueix0sbb	6	\N
43	2026-03-10 14:23:44.533092	sess_1773152624039_xebi8qm8cc	6	\N
118	2026-03-12 12:24:44.107162	sess_1773317564010_t7gk88poaz	17	\N
117	2026-03-12 12:25:28.251954	sess_1773317488127_bcy5qxd92f	6	\N
64	2026-03-11 17:50:34.654841	sess_1773250834551_11m7kqv0bh	2	\N
62	2026-03-11 17:51:44.653872	sess_1773250304552_cfqe1lh8e4	6	\N
100	2026-03-11 20:35:41.558698	sess_1773261341172_j4qaiw30e8	6	\N
45	2026-03-10 15:01:04.827446	sess_1773154862844_hwhl4wbcl5	6	\N
101	2026-03-11 20:42:39.475049	sess_1773261399297_eyinswbslb	6	\N
151	2026-03-17 14:22:03.179312	sess_1773757322979_h7dree6fci	6	\N
52	2026-03-11 16:52:23.900107	sess_1773239155918_iuth7ei7y2	15	\N
51	2026-03-11 16:52:23.903705	sess_1773238546837_nf4e8h49n9	6	\N
34	2026-03-06 20:06:30.996916	sess_1772803124855_evbv1wk3ui	13	\N
36	2026-03-06 20:06:31.002088	sess_1772826488753_8ekgws76p	9	\N
128	2026-03-12 19:39:10.38341	sess_1773341230298_jk2ybgwupt	6	\N
31	2026-03-05 19:35:46.178276	sess_1772653896329_ce3khgrwy9	6	\N
129	2026-03-12 19:39:25.254191	sess_1773341238365_7e1ern3w41	17	\N
126	2026-03-12 17:30:47.520198	sess_1773336647319_1hgexmtjki	17	\N
47	2026-03-10 15:45:26.422857	sess_1773156298746_fqdwh57e0x	9	\N
56	2026-03-11 17:19:43.874076	sess_1773249575213_gbrskwut7d	6	\N
46	2026-03-11 14:13:37.19206	sess_1773155079455_mkgsme1ppt	6	\N
113	2026-03-11 21:08:23.601735	sess_1773262947925_ixinbyhnox	6	\N
130	2026-03-12 19:01:29.255542	sess_1773342089081_fi2mkzt5h9	17	\N
140	2026-03-16 13:35:38.266689	sess_1773663437419_4qmien59iz	6	\N
145	2026-03-17 12:21:23.36422	sess_1773749843289_01ddfhb6f5	6	\N
\.


--
-- Data for Name: backup_restore_systemrestorelog; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.backup_restore_systemrestorelog (id, backup_file, executed_at, ip_address, user_id, trial180) FROM stdin;
1	backup_20260305_135003.json	2026-03-06 13:01:42.422587	127.0.0.1/32                           	6	\N
2	backup_20260305_135003.json	2026-03-06 13:04:00.590503	127.0.0.1/32                           	6	\N
\.


--
-- Data for Name: django_admin_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_admin_log (id, object_id, object_repr, action_flag, change_message, content_type_id, user_id, action_time, trial180) FROM stdin;
\.


--
-- Data for Name: django_content_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_content_type (id, app_label, model, trial180) FROM stdin;
1	admin	logentry	T
2	auth	permission	T
3	auth	group	T
4	auth	user	T
5	contenttypes	contenttype	T
6	sessions	session	T
7	users	rol	T
8	users	usuario	T
9	areas	area	T
10	secretarias	secretaria	T
11	projects	proyecto	T
12	projects	etapa	T
13	projects	proyectoarea	T
14	projects	comentarioproyecto	T
15	projects	eje	T
16	projects	plan	T
17	projects	programa	T
18	projects	objetivoestrategico	T
19	projects	indicador	T
20	projects	proyectoequipo	T
21	tasks	tarea	T
22	tasks	historialtarea	T
23	backup_restore	systemrestorelog	T
24	backup_restore	activesession	T
25	projects	adjuntoproyecto	T
26	tasks	adjuntotarea	T
27	tasks	comentariotarea	T
28	projects	comentarioauditlog	T
29	projects	adjuntoauditlog	T
30	projects	proyectopresupuestoitem	\N
\.


--
-- Data for Name: django_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_migrations (id, app, name, applied, trial180) FROM stdin;
1	contenttypes	0001_initial	2026-02-26 17:01:20.702551	T
2	auth	0001_initial	2026-02-26 17:01:20.76889	T
3	admin	0001_initial	2026-02-26 17:01:20.814745	T
4	admin	0002_logentry_remove_auto_add	2026-02-26 17:01:20.853472	T
5	admin	0003_logentry_add_action_flag_choices	2026-02-26 17:01:20.883106	T
6	users	0001_initial	2026-02-26 17:01:20.946131	T
7	areas	0001_initial	2026-02-26 17:01:20.973558	T
8	areas	0002_area_responsable	2026-02-26 17:01:21.011065	T
9	contenttypes	0002_remove_content_type_name	2026-02-26 17:01:21.07383	T
10	auth	0002_alter_permission_name_max_length	2026-02-26 17:01:21.110469	T
11	auth	0003_alter_user_email_max_length	2026-02-26 17:01:21.142801	T
12	auth	0004_alter_user_username_opts	2026-02-26 17:01:21.169348	T
13	auth	0005_alter_user_last_login_null	2026-02-26 17:01:21.207063	T
14	auth	0006_require_contenttypes_0002	2026-02-26 17:01:21.229206	T
15	auth	0007_alter_validators_add_error_messages	2026-02-26 17:01:21.270778	T
16	auth	0008_alter_user_username_max_length	2026-02-26 17:01:21.305696	T
17	auth	0009_alter_user_last_name_max_length	2026-02-26 17:01:21.335633	T
18	auth	0010_alter_group_name_max_length	2026-02-26 17:01:21.372731	T
19	auth	0011_update_proxy_permissions	2026-02-26 17:01:21.403415	T
20	auth	0012_alter_user_first_name_max_length	2026-02-26 17:01:21.44643	T
21	users	0002_add_usuario_area	2026-02-26 17:01:21.489551	T
22	users	0003_usuario_apellido	2026-02-26 17:01:21.525288	T
23	users	0004_alter_usuario_apellido	2026-02-26 17:01:21.57235	T
24	secretarias	0001_inicial	2026-02-26 17:01:21.622247	T
25	users	0005_area_secretaria_tarea_usuario	2026-02-26 17:01:21.692614	T
26	backup_restore	0001_initial	2026-02-26 17:01:21.820344	T
27	projects	0001_initial	2026-02-26 17:01:22.033933	T
28	projects	0002_add_comentario_proyecto	2026-02-26 17:01:22.152245	T
29	projects	0003_planificacion_2026	2026-02-26 17:01:22.296343	T
30	projects	0004_indicadores_y_objetivo	2026-02-26 17:01:22.42958	T
31	projects	0005_agregar_secretaria	2026-02-26 17:01:22.537707	T
32	projects	0006_proyecto_responsable_area_equipo	2026-02-26 17:01:23.016007	T
33	sessions	0001_initial	2026-02-26 17:01:23.087009	T
34	tasks	0001_initial	2026-02-26 17:01:23.292987	T
35	tasks	0002_area_secretaria_tarea_usuario	2026-02-26 17:01:23.469798	T
36	tasks	0003_historial_porcentaje_anterior	2026-02-26 17:01:23.544613	T
37	tasks	0004_tarea_proyecto_opcional	2026-02-26 17:01:23.642168	T
38	tasks	0005_tarea_estado_index	2026-02-26 17:01:23.76833	T
39	tasks	0006_tarea_padre_subtareas	2026-02-27 18:54:01.142655	T
40	users	0006_hash_passwords	2026-03-03 13:23:10.944234	T
41	projects	0007_adjuntoproyecto	2026-03-03 17:45:01.713426	T
42	tasks	0007_adjuntotarea_comentariotarea_and_more	2026-03-03 17:45:02.297344	T
43	projects	0008_comentarioproyecto_editado_por_and_more	2026-03-03 18:54:07.106237	T
44	tasks	0008_comentariotarea_editado_por_and_more	2026-03-03 18:54:07.197936	T
45	projects	0009_adjuntoauditlog	2026-03-03 19:23:15.151944	T
46	tasks	0009_tarea_orden	2026-03-06 14:14:23.130191	\N
47	users	0007_usuario_token_version	2026-03-09 13:52:15.74769	\N
48	projects	0010_proyecto_estado_index	2026-03-11 13:51:55.720442	\N
49	tasks	0010_historial_fecha_index	2026-03-11 13:51:55.932317	\N
50	projects	0011_proyecto_compound_indexes	2026-03-11 19:51:20.659727	\N
51	tasks	0011_tarea_compound_indexes	2026-03-11 19:51:20.837271	\N
52	projects	0012_remove_proyecto_projects_proy_estado_idx	2026-03-16 14:23:48.135061	\N
53	projects	0013_proyectopresupuestoitem_and_more	2026-03-16 14:26:03.768656	\N
54	tasks	0012_remove_historialtarea_tasks_hist_tarea_fecha_idx_and_more	2026-03-16 14:26:03.822753	\N
\.


--
-- Data for Name: django_session; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_session (session_key, session_data, expire_date, trial183) FROM stdin;
\.


--
-- Data for Name: projects_adjuntoauditlog; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects_adjuntoauditlog (id, tipo, adjunto_id, accion, fecha, nombre_archivo, nombre_anterior, nombre_nuevo, proyecto_id, tarea_id, usuario_id, trial183) FROM stdin;
1	tarea	2	eliminar	2026-03-03 19:33:19.572301	web-iconos_-02.png			11	29	9	T
2	proyecto	1	eliminar	2026-03-03 19:42:44.648351	LOGO-COLOR-1536x403.png			11	\N	6	T
3	tarea	3	eliminar	2026-03-03 19:55:47.448869	Recurso-1.png			11	30	6	T
\.


--
-- Data for Name: projects_adjuntoproyecto; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects_adjuntoproyecto (id, archivo, nombre_original, fecha, proyecto_id, subido_por_id, trial183) FROM stdin;
\.


--
-- Data for Name: projects_comentarioauditlog; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects_comentarioauditlog (id, tipo, comentario_id, accion, fecha, texto_anterior, texto_nuevo, proyecto_id, tarea_id, usuario_id, trial183) FROM stdin;
1	tarea	3	eliminar	2026-03-03 19:13:44.913454	holisss		11	29	6	T
\.


--
-- Data for Name: projects_comentarioproyecto; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects_comentarioproyecto (id, texto, fecha, proyecto_id, usuario_id, editado_por_id, fecha_edicion, trial183) FROM stdin;
3	SE INICIO EL PROYECTO  DE PRATICAS CON Colegio antonio marte	2026-03-02 15:53:19.626874	11	9	\N	\N	T
\.


--
-- Data for Name: projects_eje; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects_eje (id_eje, nombre_eje, trial187) FROM stdin;
1	Fortalecimiento de la Economía del Conocimiento	T
2	Impulso a la Ciencia y Tecnología	T
3	Transformación Digital y Gobierno Abierto	T
4	Gestión y Fortalecimiento Institucional	T
5	Fortalecimiento del Acceso y Desarrollo Cultural	T
6	Monetización y Generación de Recursos Propios	T
\.


--
-- Data for Name: projects_etapa; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects_etapa (id, nombre, orden, estado, porcentaje_avance, proyecto_id, trial187) FROM stdin;
\.


--
-- Data for Name: projects_indicador; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects_indicador (id, descripcion, unidad_medida, frecuencia, proyecto_id, trial187) FROM stdin;
\.


--
-- Data for Name: projects_objetivoestrategico; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects_objetivoestrategico (id, descripcion, programa_id, trial187) FROM stdin;
1	Acelerar el desarrollo de startups fueguinas.	1.1	T
2	Reducir la brecha de talento en tecnologías clave.	1.2	T
3	Generar conocimiento y soluciones para desafíos provinciales.	1.3	T
4	Ampliar el ecosistema de empresas de la Economía del Conocimiento.	1.4	T
5	Sensibilización y transferencia de conocimiento.	1.5	T
6	Exportación de servicios basados en conocimiento.	1.6	T
7	Fomentar vocaciones científicas y promover la apropiación social del conocimiento.	2.1	T
8	Centralizar y coordinar vinculaciones con el sistema científico-tecnológico.	2.2	T
9	Fortalecer el sistema científico, tecnológico e innovador provincial.	2.3	T
10	Optimizar eficiencia y transparencia.	3.1	T
11	Garantizar transparencia y optimización de recursos.	3.2	T
12	Desarrollar marcos normativos y mejora continua en seguridad informática.	3.3	T
13	Actualizar telecomunicaciones, terminales, virtualización y almacenamiento.	3.4	T
14	Implementar procesos ágiles y eficientes.	3.9	T
15	Fortalecer capacidades institucionales del sector público.	4.1	T
16	Promover convenios y articulaciones interinstitucionales.	4.2	T
17	Fortalecer conectividad y resiliencia digital.	4.3	T
18	Modernizar el parque tecnológico.	4.4	T
19	Adoptar soluciones innovadoras e interoperables.	4.5	T
20	Garantizar disponibilidad y seguridad de datos.	4.6	T
21	Consolidar almacenamiento digital seguro y escalable.	4.7	T
22	Garantizar mejora continua y auditorías periódicas.	4.8	T
23	Reforzar normativa de protección y ciberseguridad.	4.9	T
24	Promover producción y acceso a contenidos culturales.	5.1	T
25	Impulsar comercialización de artistas locales.	5.2	T
26	Fortalecer redes y proyectos audiovisuales.	5.3	T
27	Ampliar acceso cultural a toda la población.	5.4	T
28	Revalorizar expresiones tradicionales.	5.5	T
29	Articular acuerdos estratégicos.	6.1	T
30	Desarrollar soluciones digitales rentables.	6.2	T
31	Generar y administrar recursos sostenibles.	6.3	T
\.


--
-- Data for Name: projects_plan; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects_plan (id_plan, nombre_plan, proposito_politica_publica, vision_estrategica, eje_id, trial187) FROM stdin;
1	1. Fortalecimiento de la Economía del Conocimiento	Posicionar a la provincia como hub tecnológico, fomentando el talento local y el crecimiento de empresas de base tecnológica.	Consolidar a la provincia como hub tecnológico de referencia, impulsando startups, talento especializado e internacionalización de servicios basados en conocimiento.	1	T
2	2. Impulso a la Ciencia y Tecnología	Fomentar la investigación aplicada al territorio y la divulgación científica.	Consolidar la soberanía del conocimiento mediante articulación institucional y apropiación social de la ciencia.	2	T
3	3. Transformación Digital y Gobierno Abierto	Modernizar la gestión pública con infraestructura digital centrada en el ciudadano.	Consolidar un Estado moderno, ágil y transparente.	3	T
4	4. Gestión y Fortalecimiento Institucional	Transformar la arquitectura operativa del Estado Provincial.	Consolidar un modelo de gestión pública resiliente y tecnológicamente robusto.	4	T
5	5. Fortalecimiento del Acceso y Desarrollo Cultural	Promover identidad fueguina y democratizar el acceso cultural.	Consolidar un ecosistema cultural inclusivo y participativo.	5	T
6	6. Monetización y Generación de Recursos Propios	Generar ingresos para sostenibilidad de la Agencia.	Garantizar autonomía financiera mediante articulación público-privada.	6	T
\.


--
-- Data for Name: projects_programa; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects_programa (id_programa, nombre_programa, plan_id, trial187) FROM stdin;
1.1	Impulso al Emprendedurismo Tech	1	T
1.2	Desarrollo de Talento	1	T
1.3	Proyectos de I+D Estratégica	1	T
1.4	Promoción y Radicación de Empresas	1	T
1.5	Actividades de Divulgación	1	T
1.6	Internacionalización de Servicios	1	T
2.1	Apropiación Social de la Ciencia, Tecnología e Innovación	2	T
2.2	Vinculación y Articulación Institucional	2	T
2.3	Desarrollo de Capacidades Científico-Tecnológicas	2	T
3.1	Modernización del Estado	3	T
3.2	Modernización Administrativa y Financiera	3	T
3.3	Fortalecimiento de la Ciberseguridad	3	T
3.4	Modernización y Fortalecimiento de Infraestructura Digital	3	T
3.9	Actualización y Mejora de Procesos	3	T
4.1	Desarrollo y Gestión del Talento Interno	4	T
4.2	Alianzas Estratégicas y Comunicación Institucional	4	T
4.3	Actualización de Infraestructura de Telecomunicaciones	4	T
4.4	Actualización de Terminales de Usuarios	4	T
4.5	Implementación de Herramientas de Software	4	T
4.6	Infraestructura de Virtualización	4	T
4.7	Infraestructura de Almacenamiento	4	T
4.8	Plan de Revisión y Mejora Continua	4	T
4.9	Marco Normativo en Ciberseguridad	4	T
5.1	Promoción y Circulación Cultural	5	T
5.2	Ferias y Mercados	5	T
5.3	Circulación Audiovisual	5	T
5.4	Democratización Cultural	5	T
5.5	Fortalecimiento del Patrimonio Cultural	5	T
6.1	Acuerdos Público-Privados	6	T
6.2	Plataformas y Servicios para Terceros	6	T
6.3	Administración Financiera Sustentable	6	T
\.


--
-- Data for Name: projects_proyecto; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects_proyecto (id, nombre, descripcion, fecha_inicio, fecha_fin_estimada, fecha_fin_real, estado, porcentaje_avance, fecha_creacion, creado_por_id, programa_id, objetivo_estrategico_id, secretaria_id, usuario_responsable_id, area_id, trial187, fuente_financiamiento, presupuesto_total) FROM stdin;
11	Prácticas Profesionalizantes Colegio antonio marte	Prácticas Profesionalizantes Colegio antonio marte , prácticas reales 2026 para los alumnos.	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 15:25:19.710802	6	\N	\N	7	9	\N	T	Provincial	0.00
12	Práctica profesionalizante en Producción Audiovisual y Streaming (Colegio Marte - Tutor Laura Funes)	Práctica profesionalizante en Producción Audiovisual y Streaming (Colegio Marte - Tutor Laura Funes)	2026-03-02	2026-07-30	\N	Activo	0	2026-03-02 17:10:04.602176	6	\N	\N	7	9	\N	T	Provincial	0.00
13	Práctica profesionalizante- Automatización de Huerta (Colegio Marte)	Práctica profesionalizante- Automatización de Huerta (Colegio Marte- Tutor Mauro Gonzalez)	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 17:20:52.653514	6	\N	\N	7	9	\N	T	Provincial	0.00
14	Pasantías No Rentadas 6to Año - Colegio kloketen	Pasantías No Rentadas 6to Año - Colegio kloketen	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 17:33:36.173093	6	\N	\N	7	9	\N	T	Provincial	0.00
16	Plan de Capacitación Cisco 2026	Plan de Capacitación Cisco 2026	2026-03-02	2026-12-31	\N	Activo	0	2026-03-02 17:44:39.641666	6	\N	\N	7	9	\N	T	Provincial	0.00
17	Centro de Economía y Conocimiento de China	Centro de Economía y Conocimiento de China	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 17:51:21.142834	6	\N	\N	7	9	\N	T	Provincial	0.00
18	PFI 2026: Proyecto Manejo del Fuego	PFI 2026: Proyecto Manejo del Fuego	2026-03-02	2026-03-28	\N	Activo	0	2026-03-02 17:58:38.251149	6	\N	\N	7	9	\N	T	Provincial	0.00
19	Regularización Administrativa IDE (Expediente)	Regularización Administrativa IDE (Expediente)	2026-03-02	2026-03-28	\N	Activo	0	2026-03-02 18:03:31.162	6	\N	\N	7	9	\N	T	Provincial	0.00
20	Resolución de Prestación de Servicios IDE	Resolución de Prestación de Servicios IDE (Carmen)	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 18:07:23.953707	6	\N	\N	7	9	\N	T	Provincial	0.00
21	Gestión de RRHH: Reducción Horaria	Gestión de RRHH: Reducción Horaria	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 18:15:37.012135	6	\N	\N	7	9	\N	T	Provincial	0.00
22	Revisión y Ajuste de Horarios Polos	Revisión y Ajuste de Horarios Polos	2026-03-02	2026-07-30	\N	Activo	0	2026-03-02 18:20:34.061778	6	\N	\N	7	9	\N	T	Provincial	0.00
24	Plataforma Educativa FP	Plataforma Educativa FP (Ever)	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 18:52:09.564819	6	\N	\N	7	9	\N	T	Provincial	0.00
25	TDR Formación Profesional Videojuegos	TDR Formación Profesional Videojuegos	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 18:56:03.314677	6	\N	\N	7	9	\N	T	Provincial	0.00
26	Convenio Marco de Educación	Convenio Marco de Educación (Fernanda)	2026-03-02	2026-03-28	\N	Activo	0	2026-03-02 18:58:35.011792	6	\N	\N	7	9	\N	T	Provincial	0.00
28	Simposio 2026 Agencia de Innovación	Simposio 2026 Agencia de Innovación	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 19:04:29.426983	6	\N	\N	7	9	\N	T	Provincial	0.00
29	Reunión IPAP 15 de Marzo (Egresados TS)	Reunión IPAP 15 de Marzo (Egresados TS)	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 19:07:27.471601	6	\N	\N	7	9	\N	T	Provincial	0.00
30	Ampliación de Prácticas Profesionales (Anexo 11)	Ampliación de Prácticas Profesionales (Anexo 11)	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 19:09:47.051391	6	\N	\N	7	9	\N	T	Provincial	0.00
31	Proyecto Biotecnología	Proyecto Biotecnología	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 19:13:13.26067	6	\N	\N	7	9	\N	T	Provincial	0.00
32	Agenda Semana de Malvinas	Agenda Semana de Malvinas	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 19:18:09.338998	6	\N	\N	7	9	\N	T	Provincial	0.00
33	Semana de la Creatividad e Innovación (21 de Abril)	Semana de la Creatividad e Innovación (21 de Abril)	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 19:22:23.539755	6	\N	\N	7	9	\N	T	Provincial	0.00
34	Convenio Jala University	Convenio Jala University	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 19:25:43.712152	6	\N	\N	7	9	\N	T	Provincial	0.00
35	Acción Comunitaria "Estudia con Malvinas"	Acción Comunitaria "Estudia con Malvinas"	2026-03-02	2026-03-28	\N	Activo	0	2026-03-02 19:28:27.901497	6	\N	\N	7	9	\N	T	Provincial	0.00
36	TDR Segunda Fase Matemática (Malvina)	TDR Segunda Fase Matemática (Malvina)	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 19:33:35.502441	6	\N	\N	7	9	\N	T	Provincial	0.00
37	Sistema de Rendiciones COFECYT	Sistema de Rendiciones COFECYT	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 19:36:41.418575	6	\N	\N	7	9	\N	T	Provincial	0.00
38	Aplicación Registro y Base de Datos	Aplicación Registro y Base de Datos (Horacio)	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 19:39:25.161394	6	\N	\N	7	9	\N	T	Provincial	0.00
39	Proyecto Piloto Jóvenes y Adultos (EPS)	Proyecto Piloto Jóvenes y Adultos (EPS)	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 19:42:11.504962	6	\N	\N	7	9	\N	T	Provincial	0.00
40	Formación en IA para Asesores Pedagógicos	Formación en IA para Asesores Pedagógicos	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 19:44:27.935789	6	\N	\N	7	9	\N	T	Provincial	0.00
41	Plan Provincial de Inteligencia Artificial (PIPIA)	Plan Provincial de Inteligencia Artificial (PIPIA)	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 19:47:17.957374	6	\N	\N	7	9	\N	T	Provincial	0.00
42	Plan de Turismo Científico 2026	Plan de Turismo Científico 2026	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 19:49:45.038871	6	\N	\N	7	9	\N	T	Provincial	0.00
43	Producción del Streaming "Ciencia en Fuego"	Producción del Streaming "Ciencia en Fuego"	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 19:52:09.764994	6	\N	\N	7	9	\N	T	Provincial	0.00
44	Actualización de diseño de los Diarios de Campo	Actualización de diseño de los Diarios de Campo	2026-03-02	2026-06-30	\N	Activo	0	2026-03-02 19:55:18.032123	6	\N	\N	7	9	\N	T	Provincial	0.00
54	Desembolso de fondos de Nación (2do)	Desembolso de fondos de Nación (2do)	2026-03-06	2026-06-30	\N	Activo	0	2026-03-06 13:51:27.196844	13	\N	\N	7	9	\N	\N	Provincial	0.00
52	Articulación con Instituciones - Talleres	Articulación con Instituciones - Talleres	2026-03-06	2026-06-30	\N	Activo	0	2026-03-06 16:26:27.936842	13	\N	\N	7	9	\N	\N	Provincial	0.00
53	Vinculación con BOUNDY EDTECH APP	Vinculación con BOUNDY EDTECH APP	2026-03-06	2026-06-30	\N	Activo	0	2026-03-06 16:43:57.397058	13	\N	\N	7	9	\N	\N	Provincial	0.00
55	RESOLVER CONVENIO CON CADIC	RESOLVER CONVENIO CON CADIC	2026-03-06	2026-06-30	\N	Activo	0	2026-03-06 14:09:32.826618	13	\N	\N	7	9	\N	\N	Provincial	0.00
69	Articulación con el Ministerio de Educación para la Transformación Educativa (Hito Central):	Articulación con el Ministerio de Educación para la Transformación Educativa (Hito Central):	2026-03-17	2026-03-21	\N	Activo	0	2026-03-16 14:50:21.329002	6	\N	\N	3	17	\N	\N	CFI	23552000.00
68	costos	costos de servidores 2026	2026-03-11	2026-03-14	\N	Activo	0	2026-03-11 22:11:42.930244	6	\N	\N	3	17	\N	\N	Otros	1000000.00
\.


--
-- Data for Name: projects_proyectoarea; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects_proyectoarea (id, area_id, proyecto_id, trial187) FROM stdin;
\.


--
-- Data for Name: projects_proyectoequipo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects_proyectoequipo (id, proyecto_id, usuario_id, trial190) FROM stdin;
\.


--
-- Data for Name: projects_proyectopresupuestoitem; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects_proyectopresupuestoitem (id, categoria_gasto, monto, detalle, numero_expediente, es_viaticos, dotacion_tipo, horas_hombre, orden, proyecto_id) FROM stdin;
1	Equipamiento	1000.00	sin erogación provincial		f		\N	0	69
2	Gastos operativos y logisticos	0.00	sin erogación provincial		f		\N	1	69
3	Dotacion	0.00	sin erogación provincial		f		\N	2	69
4	Equipamiento	500000.00	gastos de mas		f		\N	0	68
5	Gastos operativos y logisticos	100000.00	movilidad		f		\N	1	68
6	Dotacion	350000.00	personal de agencia		f		\N	2	68
\.


--
-- Data for Name: secretarias_secretaria; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.secretarias_secretaria (id, codigo, nombre, descripcion, activa, fecha_creacion, fecha_modificacion, usuario_creacion, usuario_modificacion, trial190) FROM stdin;
7	Econ-CyT	Economia del Conocimiento - Ciencia y Tecnologia	Secretaria de Economía del Conocimiento  y Secretaria de Ciencia y Tecnología.	t	2026-03-02 15:16:31.592737	2026-03-02 15:17:44.27395			T
9	SIA	SECRETARÍA DE INNOVACIÓN ADMINISTRATIVA	SECRETARÍA DE INNOVACIÓN ADMINISTRATIVA	t	2026-03-09 13:26:36.886775	2026-03-09 13:26:36.886804			\N
10	SSIA	SUBSECRETARIA DE INNOVACIÓN ADMINISTRATIVA	SUBSECRETARIA DE INNOVACIÓN ADMINISTRATIVA	t	2026-03-09 13:27:15.764454	2026-03-09 13:27:15.764466			\N
11	SPYFT	SECRETARÍA DE GESTIÓN, POLOS Y FÁBRICAS DE TALENTO	SECRETARÍA DE GESTIÓN, POLOS Y FÁBRICAS DE TALENTO	t	2026-03-09 13:28:33.312999	2026-03-09 13:28:33.313012			\N
12	SSGI	SUBSECRETARÍA DE GESTIÓN INSTITUCIONAL	SUBSECRETARÍA DE GESTIÓN INSTITUCIONAL	t	2026-03-09 13:29:13.747134	2026-03-09 13:29:13.747168			\N
13	SCYT	SECRETARÍA DE CIENCIA Y TECNOLOGÍA	SECRETARÍA DE CIENCIA Y TECNOLOGÍA	t	2026-03-09 13:30:39.758629	2026-03-09 13:30:39.758645			\N
14	SSDYEP	SUBSECRETARÍA DE DISEÑO Y EJECUCIÓN PROYECTOS	SUBSECRETARÍA DE DISEÑO Y EJECUCIÓN PROYECTOS	t	2026-03-09 13:31:01.559022	2026-03-09 13:31:01.559035			\N
15	SC	SECRETARÍA DE CULTURA	SECRETARÍA DE CULTURA	t	2026-03-09 13:31:28.471052	2026-03-09 13:31:28.471072			\N
16	SSIC	SUBSECRETARIA INDUSTRIAS CREATIVAS	SUBSECRETARIA INDUSTRIAS CREATIVAS	t	2026-03-09 13:31:47.102756	2026-03-09 13:31:47.10277			\N
17	SSD	SECRETARÍA DE SERVICIOS DIGITALES	SECRETARÍA DE SERVICIOS DIGITALES	t	2026-03-09 13:32:21.407902	2026-03-09 13:32:21.407914			\N
18	SSSD	SUBSECRETARIA DE SERVICIOS DIGITALES	SUBSECRETARIA DE SERVICIOS DIGITALES	t	2026-03-09 13:32:49.61362	2026-03-09 13:32:49.613633			\N
19	SSIT	SUBSECRETARIA DE INFRAESTRUCTURA TECNOLÓGICA	SUBSECRETARIA DE INFRAESTRUCTURA TECNOLÓGICA	t	2026-03-09 13:33:09.651896	2026-03-09 13:33:09.651907			\N
20	SEC	SECRETARÍA DE ECONOMÍA DEL CONOCIMIENTO	SECRETARÍA DE ECONOMÍA DEL CONOCIMIENTO	t	2026-03-09 13:33:29.495992	2026-03-09 13:33:29.49609			\N
21	SAI	AUDITOR INTERNO	AUDITOR INTERNO	t	2026-03-09 13:33:53.626596	2026-03-09 13:33:53.626616			\N
1	EC	Economía del Conocimiento	Secretaría orientada al desarrollo del sector tecnológico y economía basada en conocimiento	t	2026-03-01 20:05:44.17937	2026-03-17 12:16:38.457064			T
2	CYT	Ciencia y Tecnología	Secretaría orientada a la investigación científica y desarrollo tecnológico	t	2026-03-02 02:05:44.189295	2026-03-17 12:16:38.472701			T
3	TEC	Tecnología	Secretaría de innovación y transformación digital	t	2026-03-01 23:05:44.203253	2026-03-17 12:16:38.476522			T
4	CUL	Cultura	Secretaría de promoción cultural y desarrollo creativo	t	2026-03-01 23:05:44.214732	2026-03-17 12:16:38.482981			T
5	GOB	Gobierno Abierto	Secretaría de modernización y transparencia	t	2026-03-01 23:05:44.227855	2026-03-17 12:16:38.488299			T
6	ADM	Administración y Gestión	Secretaría de gestión institucional	t	2026-03-02 08:05:44.241324	2026-03-17 12:16:38.494506			T
\.


--
-- Data for Name: sqlite_sequence; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sqlite_sequence (name, seq, trial190) FROM stdin;
django_migrations	45	T
django_admin_log	0	T
django_content_type	29	T
auth_permission	116	T
auth_group	0	T
auth_user	0	T
users_usuario	9	T
tasks_tarea	160	T
users_rol	3	T
areas_area	5	T
projects_proyecto	48	T
projects_etapa	6	T
tasks_historialtarea	38	T
backup_restore_activesession	30	T
projects_objetivoestrategico	31	T
secretarias_secretaria	7	T
projects_proyectoequipo	3	T
projects_comentarioproyecto	3	T
projects_indicador	2	T
tasks_comentariotarea	4	T
tasks_adjuntotarea	3	T
projects_adjuntoproyecto	1	T
projects_comentarioauditlog	1	T
projects_adjuntoauditlog	3	T
\.


--
-- Data for Name: tasks_adjuntotarea; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tasks_adjuntotarea (id, archivo, nombre_original, fecha, subido_por_id, tarea_id, trial190) FROM stdin;
1	adjuntos/tareas/2026/03/LOGO-COLOR-1536x403.png	LOGO-COLOR-1536x403.png	2026-03-03 18:05:48.002688	2	29	T
\.


--
-- Data for Name: tasks_comentariotarea; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tasks_comentariotarea (id, texto, fecha, tarea_id, usuario_id, editado_por_id, fecha_edicion, trial190) FROM stdin;
1	demo!!!	2026-03-03 18:37:14.080832	28	4	\N	\N	T
4	holis	2026-03-03 19:19:12.782508	29	9	\N	\N	T
\.


--
-- Data for Name: tasks_historialtarea; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tasks_historialtarea (id, comentario, porcentaje_avance, fecha, tarea_id, usuario_id, porcentaje_anterior, trial193) FROM stdin;
31		1	2026-03-03 18:10:16.280847	29	4	1	T
32	sadsadasfaf	1	2026-03-03 18:10:35.307491	29	4	1	T
33	sdadasdasdadasdas	2	2026-03-03 18:10:46.089554	29	4	1	T
34	demos1	100	2026-03-03 18:40:48.603574	28	9	100	T
35	hola opcional	2	2026-03-03 18:41:08.438579	29	9	2	T
36	cometario opcional	2	2026-03-03 18:44:09.936713	29	9	2	T
37		2	2026-03-03 19:14:15.540216	29	9	2	T
38		1	2026-03-03 19:53:51.773544	30	9	1	T
\.


--
-- Data for Name: tasks_tarea; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tasks_tarea (id, titulo, descripcion, fecha_inicio, fecha_vencimiento, estado, porcentaje_avance, prioridad, fecha_creacion, area_id, etapa_id, responsable_id, secretaria_id, proyecto_id, tarea_padre_id, trial193, orden) FROM stdin;
28	Redactar nota de elevación con las 4 ofertas integradoras	Redactar nota de elevación con las 4 ofertas integradoras	2026-03-02	2026-03-06	Finalizada	100	Media	2026-03-02 15:31:43.229176	\N	\N	9	7	11	\N	T	0
29	Enviar el proyecto formal a la dirección de la escuela.	Enviar el proyecto formal a la dirección de la escuela.	2026-03-02	2026-03-06	En proceso	2	Media	2026-03-02 15:32:50.351297	\N	\N	9	7	11	\N	T	0
30	Definir topes de estudiantes por proyecto y criterios de renovación.	Definir topes de estudiantes por proyecto y criterios de renovación.	2026-03-02	2026-03-06	En proceso	1	Media	2026-03-02 15:33:29.692807	\N	\N	9	7	11	\N	T	0
31	Coordinar con la escuela la devolución del proyecto firmado.	Coordinar con la escuela la devolución del proyecto firmado.	2026-03-02	2026-03-07	Pendiente	1	Alta	2026-03-02 15:34:35.099752	\N	\N	9	7	11	\N	T	0
32	Fijar cronograma y fechas de inicio de las prácticas	Fijar cronograma y fechas de inicio de las prácticas	2026-03-02	2026-03-06	En proceso	1	Media	2026-03-02 15:35:20.612377	\N	\N	9	7	11	\N	T	0
33	Designar tutores internos para el seguimiento pedagógico y técnico.	Designar tutores internos para el seguimiento pedagógico y técnico.	2026-03-02	2026-03-06	En proceso	1	Media	2026-03-02 15:36:09.513373	\N	\N	9	7	11	\N	T	0
34	iniciar la inducción y capacitación redacción de cv y entrevistas laborales (a cargo de IPAP))	iniciar la inducción y capacitación redacción de cv y entrevistas laborales (a cargo de IPAP))	2026-03-02	2026-03-06	En proceso	1	Media	2026-03-02 15:36:55.55027	\N	\N	9	7	11	\N	T	0
35	Convocatoria y postulaciones a las prácticas	Convocatoria y postulaciones a las prácticas	2026-03-02	2026-03-06	En proceso	1	Baja	2026-03-02 15:37:51.784369	\N	\N	9	7	11	\N	T	0
36	Difusión institucional	Difusión institucional	2026-03-02	2026-03-06	En proceso	1	Media	2026-03-02 15:38:47.804495	\N	\N	9	7	11	35	T	0
38	Iniciar las prácticas	Iniciar las prácticas	2026-03-02	2026-03-06	En proceso	1	Media	2026-03-02 15:40:17.710521	\N	\N	9	7	11	\N	T	0
39	Presentación institucional y bienvenida	Presentación institucional y bienvenida	2026-03-02	2026-03-06	En proceso	1	Media	2026-03-02 15:42:16.918924	\N	\N	9	7	11	38	T	0
40	Realizar inventario técnico y validar disponibilidad de equipos en el Polo.	Realizar inventario técnico y validar disponibilidad de equipos en el Polo.	2026-03-02	2026-06-30	En proceso	1	Media	2026-03-02 17:10:52.510408	\N	\N	9	7	12	\N	T	0
41	Diseñar el plan de contenidos/guiones para las prácticas con alumnos.	Diseñar el plan de contenidos/guiones para las prácticas con alumnos.	2026-03-02	2026-03-21	En proceso	1	Media	2026-03-02 17:11:37.543968	\N	\N	9	7	12	\N	T	0
42	Establecer el cronograma de rodaje mensual.	Establecer el cronograma de rodaje mensual.	2026-03-02	2026-03-21	En proceso	1	Media	2026-03-02 17:12:13.830022	\N	\N	9	7	12	\N	T	0
43	Coordinar las etapas de postproducción y edición con los estudiantes	Coordinar las etapas de postproducción y edición con los estudiantes	2026-03-02	2026-03-21	En proceso	1	Media	2026-03-02 17:13:01.458616	\N	\N	9	7	12	\N	T	0
44	Realizar visita técnica a IPES FA para diagnóstico del estado de la huerta.	Realizar visita técnica a IPES FA para diagnóstico del estado de la huerta.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 17:22:44.616779	\N	\N	9	7	13	\N	T	0
45	Entrevistar a los responsables institucionales de la huerta sobre necesidades y expectativas.	Entrevistar a los responsables institucionales de la huerta sobre necesidades y expectativas.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 17:23:25.715799	\N	\N	9	7	13	\N	T	0
46	Elaborar propuesta técnica de sensibilización pedagógica.	Elaborar propuesta técnica de sensibilización pedagógica.	2026-03-02	2026-03-21	En proceso	1	Media	2026-03-02 17:23:58.367363	\N	\N	9	7	13	\N	T	0
47	Diseñar el plan técnico de automatización.	Diseñar el plan técnico de automatización.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 17:25:47.020428	\N	\N	9	7	13	\N	T	0
48	Presupuestar componentes tecnológicos y materiales requeridos	Presupuestar componentes tecnológicos y materiales requeridos	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 17:26:41.998573	\N	\N	9	7	13	\N	T	0
49	Relevar cupos y perfiles solicitados en las áreas de la Agencia	Relevar cupos y perfiles solicitados en las áreas de la Agencia	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 17:36:54.598509	\N	\N	9	7	14	\N	T	0
50	Identificar estudiantes interesados en el Colegio Kloketen (Anexo 11).	Identificar estudiantes interesados en el Colegio Kloketen (Anexo 11).	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 17:37:32.058556	\N	\N	9	7	14	\N	T	0
51	Armar el programa detallado de tareas y objetivos para el pasante.	Armar el programa detallado de tareas y objetivos para el pasante.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 17:38:00.156272	\N	\N	9	7	14	\N	T	0
52	Vincular los perfiles de los alumnos con la oferta formativa de Cisco	Vincular los perfiles de los alumnos con la oferta formativa de Cisco	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 17:38:27.499379	\N	\N	9	7	14	\N	T	0
55	Cruzar la base de datos de cursos con la oferta actual de los Polos (Azahala)	Cruzar la base de datos de cursos con la oferta actual de los Polos (Azahala)	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 17:45:13.811695	\N	\N	9	7	16	\N	T	0
56	Identificar contenidos para evitar superposiciones con trayectos existentes.	Identificar contenidos para evitar superposiciones con trayectos existentes.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 17:45:56.765116	\N	\N	9	7	16	\N	T	0
57	Definir los trayectos formativos específicos para 2026	Definir los trayectos formativos específicos para 2026	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 17:47:24.134952	\N	\N	9	7	16	\N	T	0
58	Elaborar el cronograma de activación gradual para validación de Abel	Elaborar el cronograma de activación gradual para validación de Abel	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 17:47:57.743534	\N	\N	9	7	16	\N	T	0
59	Recopilar antecedentes, convenios previos y objetivos estratégicos.	Recopilar antecedentes, convenios previos y objetivos estratégicos.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 17:52:40.149772	\N	\N	9	7	17	\N	T	0
60	Redactar el documento base del proyecto del Centro.	Redactar el documento base del proyecto del Centro.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 17:53:16.484214	\N	\N	9	7	17	\N	T	0
61	Definir y convocar a los actores interinstitucionales involucrados.	Definir y convocar a los actores interinstitucionales involucrados.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 17:53:44.193213	\N	\N	9	7	17	\N	T	0
62	Establecer una hoja de ruta de implementación a corto plazo.	Establecer una hoja de ruta de implementación a corto plazo.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 17:54:16.492672	\N	\N	9	7	17	\N	T	0
63	Integrar formalmente al equipo de la IDE al grupo de trabajo	Integrar formalmente al equipo de la IDE al grupo de trabajo	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 17:59:11.867728	\N	\N	9	7	18	\N	T	0
64	Coordinar con Abel el calendario de reuniones semanales de seguimiento.	Coordinar con Abel el calendario de reuniones semanales de seguimiento.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 17:59:43.62095	\N	\N	9	7	18	\N	T	0
65	Establecer plazos de entrega para el borrador del proyecto general	Establecer plazos de entrega para el borrador del proyecto general	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 18:00:17.203256	\N	\N	9	7	18	\N	T	0
66	Cuantificar recursos y presupuestar según requisitos de la convocatoria.	Cuantificar recursos y presupuestar según requisitos de la convocatoria.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 18:00:49.153847	\N	\N	9	7	18	\N	T	0
67	Recopilar la normativa vigente y redactar la carta de intención.	Recopilar la normativa vigente y redactar la carta de intención.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 18:04:38.704474	\N	\N	9	7	19	\N	T	0
68	Subir la documentación completa al sistema de expedientes electrónicos.	Subir la documentación completa al sistema de expedientes electrónicos.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 18:05:09.576081	\N	\N	9	7	19	\N	T	0
69	Gestionar el pase para firma de las autoridades (Secretaría/Agencia).	Gestionar el pase para firma de las autoridades (Secretaría/Agencia).	2026-03-02	2026-03-28	En proceso	11	Media	2026-03-02 18:05:49.969871	\N	\N	9	7	19	\N	T	0
70	Realizar seguimiento semanal del estado del expediente hasta su aprobación.	Realizar seguimiento semanal del estado del expediente hasta su aprobación.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 18:06:21.730169	\N	\N	9	7	19	\N	T	0
71	Redactar el cuerpo técnico de la resolución (tarifarios/servicios).	Redactar el cuerpo técnico de la resolución (tarifarios/servicios).	2026-03-02	2026-05-18	En proceso	1	Media	2026-03-02 18:07:58.786588	\N	\N	9	7	20	\N	T	0
72	Validar el borrador con el área legal de la Agencia.	Validar el borrador con el área legal de la Agencia.	2026-03-02	2026-04-27	En proceso	1	Media	2026-03-02 18:08:29.78985	\N	\N	9	7	20	\N	T	0
73	Gestionar la firma de la resolución.	Gestionar la firma de la resolución.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 18:09:37.507573	\N	\N	9	7	20	\N	T	0
74	Notificar formalmente a las áreas contables y administrativas.	Notificar formalmente a las áreas contables y administrativas.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 18:10:07.446052	\N	\N	9	7	20	\N	T	0
75	Evaluar la viabilidad técnica y operativa de la reducción de jornada.	Evaluar la viabilidad técnica y operativa de la reducción de jornada.	2026-03-02	2026-04-27	En proceso	1	Media	2026-03-02 18:16:10.950574	\N	\N	9	7	21	\N	T	0
76	Redactar la nota de notificación formal para Recursos Humanos.	Redactar la nota de notificación formal para Recursos Humanos.	2026-03-02	2026-04-30	En proceso	1	Media	2026-03-02 18:17:43.365516	\N	\N	9	7	21	\N	T	0
77	Solicitar al agente la actualización de su Declaración Jurada.	Solicitar al agente la actualización de su Declaración Jurada.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 18:18:13.488534	\N	\N	9	7	21	\N	T	0
78	Coordinar con liquidación de haberes el ajuste correspondiente.	Coordinar con liquidación de haberes el ajuste correspondiente.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 18:18:43.368355	\N	\N	9	7	21	\N	T	0
79	Analizar la carga horaria de Archie para garantizar la cobertura de sala.	Analizar la carga horaria de Archie para garantizar la cobertura de sala.	2026-03-02	2026-04-30	En proceso	1	Media	2026-03-02 18:21:15.528217	\N	\N	9	7	22	\N	T	0
80	Cotejar esquemas con la normativa vigente y los horarios de Gaby en Drive.	Cotejar esquemas con la normativa vigente y los horarios de Gaby en Drive.	2026-03-02	2026-04-04	En proceso	1	Media	2026-03-02 18:21:51.366384	\N	\N	9	7	22	\N	T	0
81	Definir el nuevo cuadro de rotación de personal.	Definir el nuevo cuadro de rotación de personal.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 18:22:16.700888	\N	\N	9	7	22	\N	T	0
82	Notificar el esquema final a los agentes involucrados.	Notificar el esquema final a los agentes involucrados.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 18:22:41.886908	\N	\N	9	7	22	\N	T	0
83	Evaluar técnica y funcionalmente la plataforma de inscripción de Polos.	Evaluar técnica y funcionalmente la plataforma de inscripción de Polos.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 18:52:56.213164	\N	\N	9	7	24	\N	T	0
84	Determinar si es posible integrar módulos de foros y seguimiento.	Determinar si es posible integrar módulos de foros y seguimiento.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 18:53:27.2949	\N	\N	9	7	24	\N	T	0
85	Gestionar, de ser necesario, acceso urgente al Campus Moodle existente.	Gestionar, de ser necesario, acceso urgente al Campus Moodle existente.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 18:53:55.074087	\N	\N	9	7	24	\N	T	0
86	Configurar el sistema de matriculación y seguimiento de alumnos.	Configurar el sistema de matriculación y seguimiento de alumnos.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 18:54:24.225692	\N	\N	9	7	24	\N	T	0
87	Realizar la revisión técnica final y dar cierre al TDR redactado.	Realizar la revisión técnica final y dar cierre al TDR redactado.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 18:56:42.071522	\N	\N	9	7	25	\N	T	0
88	Iniciar el circuito administrativo para la contratación/licitación.	Iniciar el circuito administrativo para la contratación/licitación.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 18:57:10.42423	\N	\N	9	7	25	\N	T	0
89	Estructurar y cargar los contenidos específicos en la plataforma virtual.	Estructurar y cargar los contenidos específicos en la plataforma virtual.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 18:57:39.920813	\N	\N	9	7	25	\N	T	0
90	Revisar el estado del borrador enviado a la contraparte (Fernanda).	Revisar el estado del borrador enviado a la contraparte (Fernanda).	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 18:59:19.700775	\N	\N	9	7	26	\N	T	0
91	Solicitar formalmente los aportes técnicos de Educación.	Solicitar formalmente los aportes técnicos de Educación.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 18:59:57.100651	\N	\N	9	7	26	\N	T	0
92	Elevar por urgencia si no hay respuesta en plazos establecidos.	Elevar por urgencia si no hay respuesta en plazos establecidos.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:00:23.358411	\N	\N	9	7	26	\N	T	0
93	Coordinar la logística para la firma protocolar del convenio.	Coordinar la logística para la firma protocolar del convenio.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:00:54.001209	\N	\N	9	7	26	\N	T	0
94	Definir el eje temático y los objetivos centrales del evento.	Definir el eje temático y los objetivos centrales del evento.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:04:58.707753	\N	\N	9	7	28	\N	T	0
95	Mapear y contactar a disertantes, actores externos y patrocinadores.	Mapear y contactar a disertantes, actores externos y patrocinadores.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:05:34.516152	\N	\N	9	7	28	\N	T	0
96	Elaborar el presupuesto detallado (logística, locación, técnica).	Elaborar el presupuesto detallado (logística, locación, técnica).	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:06:04.227016	\N	\N	9	7	28	\N	T	0
97	Incorporar la fecha oficial en la agenda institucional y de la Agencia.	Incorporar la fecha oficial en la agenda institucional y de la Agencia.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:06:33.773418	\N	\N	9	7	28	\N	T	0
98	Elaborar propuesta de actualización para perfiles de RRHH y Administración.	Elaborar propuesta de actualización para perfiles de RRHH y Administración.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:08:03.673323	\N	\N	9	7	29	\N	T	0
99	Relevar necesidades de formación tecnológica del cuerpo docente IPAP.	Relevar necesidades de formación tecnológica del cuerpo docente IPAP.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:08:35.132362	\N	\N	9	7	29	\N	T	0
100	Analizar la factibilidad jurídica de un convenio específico Agencia-IPAP.	Analizar la factibilidad jurídica de un convenio específico Agencia-IPAP.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:09:01.685346	\N	\N	9	7	29	\N	T	0
101	Identificar instituciones para prácticas de Desarrollo Web fuera del Martes.	Identificar instituciones para prácticas de Desarrollo Web fuera del Martes.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:11:11.614138	\N	\N	9	7	30	\N	T	0
102	Analizar perfiles de Técnico Superior que requieran plazas de práctica.	Analizar perfiles de Técnico Superior que requieran plazas de práctica.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:11:38.494972	\N	\N	9	7	30	\N	T	0
103	Validar con Supervisión de Educación Superior la viabilidad de las plazas.	Validar con Supervisión de Educación Superior la viabilidad de las plazas.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:12:07.940412	\N	\N	9	7	30	\N	T	0
104	Revisar el cronograma de ejecución y plazos de presentación formal.	Revisar el cronograma de ejecución y plazos de presentación formal.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:16:13.506086	\N	\N	9	7	31	\N	T	0
105	Coordinar con la Unidad de Contrataciones el seguimiento del expediente.	Coordinar con la Unidad de Contrataciones el seguimiento del expediente.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:16:46.429023	\N	\N	9	7	31	\N	T	0
106	Designar a los responsables técnicos para la certificación de hitos.	Designar a los responsables técnicos para la certificación de hitos.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:17:15.392895	\N	\N	9	7	31	\N	T	0
107	Diseñar la actividad central (Soberanía + Ciencia) de la Agencia.	Diseñar la actividad central (Soberanía + Ciencia) de la Agencia.	2026-03-02	2026-04-24	En proceso	1	Media	2026-03-02 19:19:01.061179	\N	\N	9	7	32	\N	T	0
108	Cargar el cronograma detallado de acciones en el Drive compartido.	Cargar el cronograma detallado de acciones en el Drive compartido.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:20:34.388752	\N	\N	9	7	32	\N	T	0
109	Coordinar con Prensa la difusión de las actividades programadas.	Coordinar con Prensa la difusión de las actividades programadas.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:21:15.062832	\N	\N	9	7	32	\N	T	0
110	Diseñar el calendario de actividades de la Agencia para toda la semana.	Diseñar el calendario de actividades de la Agencia para toda la semana.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:23:45.082573	\N	\N	9	7	33	\N	T	0
111	Convocar a otras Secretarías para integrar propuestas transversales.	Convocar a otras Secretarías para integrar propuestas transversales.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:24:13.935819	\N	\N	9	7	33	\N	T	0
112	Cargar el calendario final en la agenda mensual para evitar solapamientos.	Cargar el calendario final en la agenda mensual para evitar solapamientos.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:24:45.422813	\N	\N	9	7	33	\N	T	0
113	Analizar el rol y compromisos de la Agencia en el borrador (Maru/Emiliano).	Analizar el rol y compromisos de la Agencia en el borrador (Maru/Emiliano).	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:26:15.592583	\N	\N	9	7	34	\N	T	0
114	Segmentar los grupos de difusión (especialmente Colegio Martes).	Segmentar los grupos de difusión (especialmente Colegio Martes).	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:26:43.637396	\N	\N	9	7	34	\N	T	0
115	Solicitar a Jala el temario técnico del cursillo de admisión.	Solicitar a Jala el temario técnico del cursillo de admisión.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:27:12.005109	\N	\N	9	7	34	\N	T	0
116	Diseñar programa de tutoría/acompañamiento para los postulantes.	Diseñar programa de tutoría/acompañamiento para los postulantes.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:27:41.323074	\N	\N	9	7	34	\N	T	0
117	Gestionar el diseño y la impresión del banner para el aula en Tolhuin.	Gestionar el diseño y la impresión del banner para el aula en Tolhuin.	2026-03-02	2026-03-28	Pendiente	1	Media	2026-03-02 19:29:02.60102	\N	\N	9	7	35	\N	T	0
118	Definir el cronograma de apertura del espacio a la comunidad.	Definir el cronograma de apertura del espacio a la comunidad.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:29:46.115085	\N	\N	9	7	35	\N	T	0
119	Seleccionar las sesiones de Malvinas que actuarán como eje expositivo.	Seleccionar las sesiones de Malvinas que actuarán como eje expositivo.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:30:12.839309	\N	\N	9	7	35	\N	T	0
120	Incorporar los ajustes técnicos surgidos de la reunión presencial al TDR.	Incorporar los ajustes técnicos surgidos de la reunión presencial al TDR.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:34:10.444064	\N	\N	9	7	36	\N	T	0
121	Finalizar el presupuesto detallado y el cronograma de ejecución	Finalizar el presupuesto detallado y el cronograma de ejecución	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:34:40.967482	\N	\N	9	7	36	\N	T	0
122	Coordinar las pruebas de campo con alumnos del trayecto Quimiceros.	Coordinar las pruebas de campo con alumnos del trayecto Quimiceros.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:35:16.674156	\N	\N	9	7	36	\N	T	0
123	Verificar con Ema el alta efectiva de usuarios en la plataforma UNA.	Verificar con Ema el alta efectiva de usuarios en la plataforma UNA.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:37:14.417338	\N	\N	9	7	37	\N	T	0
124	Requerir a Mariel Navarro el informe actualizado de proyectos pendientes.	Requerir a Mariel Navarro el informe actualizado de proyectos pendientes.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:37:44.642996	\N	\N	9	7	37	\N	T	0
125	Designar al responsable operativo del seguimiento administrativo semanal.	Designar al responsable operativo del seguimiento administrativo semanal.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:38:15.671067	\N	\N	9	7	37	\N	T	0
126	Definir los campos y variables estandarizadas para la carga de datos.	Definir los campos y variables estandarizadas para la carga de datos.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:39:53.103753	\N	\N	9	7	38	\N	T	0
127	Validar el prototipo funcional de la aplicación con el equipo de gestión.	Validar el prototipo funcional de la aplicación con el equipo de gestión.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:40:22.682887	\N	\N	9	7	38	\N	T	0
128	Realizar la migración de datos desde los archivos Excel dispersos.	Realizar la migración de datos desde los archivos Excel dispersos.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:41:12.726204	\N	\N	9	7	38	\N	T	0
129	Revisar la articulación normativa bajo Resolución CFE 308/2016.	Revisar la articulación normativa bajo Resolución CFE 308/2016.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:42:43.334134	\N	\N	9	7	39	\N	T	0
130	Coordinar con el agente capacitador el plan de seguimiento escolar.	Coordinar con el agente capacitador el plan de seguimiento escolar.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:43:13.35618	\N	\N	9	7	39	\N	T	0
131	Completar la escritura del proyecto final en el Drive compartido.	Completar la escritura del proyecto final en el Drive compartido.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:43:41.112305	\N	\N	9	7	39	\N	T	0
132	Diseñar el programa formativo orientado a Inteligencia Artificial.	Diseñar el programa formativo orientado a Inteligencia Artificial.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:44:59.42133	\N	\N	9	7	40	\N	T	0
133	Definir modalidad (híbrida), carga horaria y cronograma de clases.	Definir modalidad (híbrida), carga horaria y cronograma de clases.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:45:35.342601	\N	\N	9	7	40	\N	T	0
134	Elaborar el kit de materiales pedagógicos para la réplica institucional.	Elaborar el kit de materiales pedagógicos para la réplica institucional.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:46:01.626675	\N	\N	9	7	40	\N	T	0
135	Actualizar el borrador del plan provincial integrando nuevas directrices.	Actualizar el borrador del plan provincial integrando nuevas directrices.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:48:00.722627	\N	\N	9	7	41	\N	T	0
136	Definir la participación de Industrias Culturales y la Bolsa de Talento.	Definir la participación de Industrias Culturales y la Bolsa de Talento.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:48:35.47006	\N	\N	9	7	41	\N	T	0
137	Coordinar reunión de vinculación con "Punto" y docente de biomateriales.	Coordinar reunión de vinculación con "Punto" y docente de biomateriales.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:49:02.646291	\N	\N	9	7	41	\N	T	0
138	Evaluar técnicamente la propuesta integral enviada por Estefi.	Evaluar técnicamente la propuesta integral enviada por Estefi.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:50:29.342291	\N	\N	9	7	42	\N	T	0
139	Validar los diseños pedagógicos de las bitácoras y diarios de campo.	Validar los diseños pedagógicos de las bitácoras y diarios de campo.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:50:53.833131	\N	\N	9	7	42	\N	T	0
140	Gestionar con la diseñadora de IPAP la impresión de las versiones 2026.	Gestionar con la diseñadora de IPAP la impresión de las versiones 2026.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:51:20.136706	\N	\N	9	7	42	\N	T	0
141	Establecer los ejes temáticos y la línea editorial de la temporada 2026.	Establecer los ejes temáticos y la línea editorial de la temporada 2026.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:52:36.892039	\N	\N	9	7	43	\N	T	0
142	Coordinar con Laura el cronograma de rodaje, locaciones y técnica.	Coordinar con Laura el cronograma de rodaje, locaciones y técnica.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:53:03.110953	\N	\N	9	7	43	\N	T	0
143	Relevar y convocar a científicos y referentes para las entrevistas.	Relevar y convocar a científicos y referentes para las entrevistas.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:53:27.337695	\N	\N	9	7	43	\N	T	0
144	Integrar a estudiantes del Colegio Martes en roles de asistencia técnica.	Integrar a estudiantes del Colegio Martes en roles de asistencia técnica.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:53:51.640944	\N	\N	9	7	43	\N	T	0
145	Ejecutar el plan de difusión (clips/redes) tras cada lanzamiento.	Ejecutar el plan de difusión (clips/redes) tras cada lanzamiento.	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:54:16.605198	\N	\N	9	7	43	\N	T	0
146	Revisar los aportes enviados por las profes	Revisar los aportes enviados por las profes	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:55:46.703438	\N	\N	9	7	44	\N	T	0
147	Coordinar con IPAP el diseño con las modificaciones	Coordinar con IPAP el diseño con las modificaciones	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:56:15.248562	\N	\N	9	7	44	\N	T	0
148	Compra de Insumos para la impresión	Compra de Insumos para la impresión	2026-03-02	2026-03-28	En proceso	1	Media	2026-03-02 19:56:45.627498	\N	\N	9	7	44	\N	T	0
175	Definir responsable de articulación	Definir responsable de articulación	2026-03-06	2026-03-31	En proceso	1	Media	2026-03-06 13:36:39.840664	\N	\N	9	7	52	\N	\N	0
177	Ver estado de cuenta con los transportes	Ver estado de cuenta con los transportes	2026-03-06	2026-03-31	En proceso	1	Media	2026-03-06 13:39:29.545276	\N	\N	9	7	52	\N	\N	0
176	Confeccionar listado de instituciones con sus respectivos contactos	Confeccionar listado de instituciones con sus respectivos contactos	2026-03-06	2026-03-31	En proceso	1	Media	2026-03-06 16:38:39.021367	\N	\N	9	7	52	\N	\N	0
178	Definir rol de la Agencia	Definir rol de la Agencia	2026-03-06	2026-03-31	En proceso	1	Media	2026-03-06 13:44:46.910356	\N	\N	9	7	53	\N	\N	0
179	Generar canales de comunicación con referentes institucionales secundarios	Generar canales de comunicación con referentes institucionales secundarios	2026-03-06	2026-03-31	En proceso	1	Media	2026-03-06 13:46:59.70426	\N	\N	9	7	53	\N	\N	0
180	Contribuir en la generación de Proyectos desde la Agencia	Contribuir en la generación de Proyectos desde la Agencia	2026-03-06	2026-03-31	En proceso	1	Media	2026-03-06 13:49:17.452338	\N	\N	9	7	53	\N	\N	0
37	Selección de perfiles y entrevistas (AIF)	Selección de perfiles y entrevistas (AIF)	2026-03-02	2026-03-30	En proceso	1	Baja	2026-03-02 18:39:32.560909	\N	\N	9	7	11	35	T	0
181	Solicitar a Mariel Navarro estado de proyectos PFI 22/23	Solicitar a Mariel Navarro estado de proyectos PFI 22/23	2026-03-06	2026-03-31	En proceso	1	Media	2026-03-06 22:52:01.950171	\N	\N	9	7	54	\N	\N	1
183	Articular con Paola Rojas (admin)	Articular con Paola Rojas (admin)	2026-03-06	2026-03-31	En proceso	1	Media	2026-03-07 02:08:15.824321	\N	\N	9	7	54	\N	\N	3
182	Informarnos sobre procedimiento administrativo	Informarnos sobre procedimiento administrativo	2026-03-06	2026-03-31	En proceso	1	Media	2026-03-06 19:54:01.722319	\N	\N	9	7	54	\N	\N	2
\.


--
-- Data for Name: users_rol; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users_rol (id, nombre, descripcion, trial197) FROM stdin;
1	Administrador	Acceso total al sistema	T
2	Carga	Puede crear y editar proyectos y tareas	T
3	Visualización	Solo lectura	T
\.


--
-- Data for Name: users_usuario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users_usuario (id, nombre, email, password, estado, fecha_creacion, rol_id, area_id, apellido, secretaria_id, trial197, token_version) FROM stdin;
1	Admin	admin@admin.com	pbkdf2_sha256$600000$TfYOMWEmCY1f0SVQKtsVqD$MwpMUwgCEgiz2aftiOplx73/XxdLvEXKGraAcFaMuf0=	t	2026-02-26 17:01:36.925218	1	\N	Sistema	\N	T	1
3	Usuario	carga@test.com	carga123	t	2026-02-26 17:01:37.059739	2	2	Carga	\N	T	1
4	Juancito	juancito@test.com	pbkdf2_sha256$600000$ThTwLvNzhyP0ktjqqULWbz$U/jY3F6MNZLO53uOICcc1KgPtwyG7MlxeBymsa5Ur4E=	t	2026-02-26 17:05:44.273047	2	\N	Perez	7	T	1
7	matias	mati@gmail.com	pbkdf2_sha256$600000$dxqdRhhasWQzijuxEOAeDB$ku9EoCWT2I/7zxTYycfgfQyE/XLzBKLf2wRcgD38CAo=	f	2026-02-27 13:13:04.832688	2	\N	araujo	4	T	1
8	maximiliano	maxitorres@gmail.com	Tdf3015**|	f	2026-03-02 16:56:31.154015	1	\N	Torres	\N	T	1
17	maxi	lopez@gmail.com	pbkdf2_sha256$600000$qdOXueZiHLnqTUE8sd3fD1$UjvfLAEKFo+XGHe+RQd5I23evyVpaQ9RAQYZigVCJQ0=	t	2026-03-11 19:10:53.418948	2	\N	lopez	3	\N	1
13	matias	matias@gmail.com	pbkdf2_sha256$600000$mlic0hQ6fHIbktOThJ5AOW$rC86qZ1430iNSh09OEeL0YkRI/39KgGYwyeF5DvpvR4=	t	2026-03-06 13:18:31.545959	1	\N	araujo	\N	\N	1
6	horacio david	bogarin1983@gmail.com	pbkdf2_sha256$600000$q7saaWw9aJA8t4TD4YQaRL$SH7QurTmZ4QIxtNVblZUztE3ByDk4FAW5sAa/CBotSQ=	t	2026-02-26 23:06:38.971716	1	\N	bogarin	\N	T	3
2	Usuario	visualizador@test.com	pbkdf2_sha256$600000$DLJb1IBNj4tXBkCra8puHF$YHar6qf9fW/kvmfaUs7kq2BCd25LkdnIw4ASRRSA8kg=	t	2026-02-26 17:01:37.041943	3	1	Visualizador	\N	T	1
14	Administrador	admin@sipra.local	pbkdf2_sha256$600000$BWZHCTaJ0AsYYF5l1vwzyd$Ku0dbz/Nmwnf6vLAf+IEweoxMvA4kzv+umYimhx2Xs4=	t	2026-03-09 13:54:23.161742	1	\N	SIPRA	\N	\N	1
16	Gestion	gestion.proyectos@sipra.local	pbkdf2_sha256$600000$KqFkuDCnHnsRxjLw0ELqjk$irmLldCLhJIO1QBpPH+RiiR+6epZDmfepERKv/VFUao=	t	2026-03-09 13:54:24.503472	2	2	Proyectos	\N	\N	1
9	Abel Omar	aocortez@aif.gob.ar	pbkdf2_sha256$600000$vro6p16rhCOjMdppY6j7LP$YKa+fYd0muG2SKLkGlN78bZceKYzUW3PBuCvLZ5DAQw=	t	2026-03-02 18:22:08.023561	2	\N	Cortez	7	T	2
15	Consulta	visualizacion@sipra.local	pbkdf2_sha256$600000$VjkZ0do522tq1t6Occvdjq$G29tILSZfKCElWaFoYtYUHcfbyb1Fw+tPhl11i5nBV8=	t	2026-03-09 16:54:23.854764	3	1	General	\N	\N	2
5	Pepe	pepe@test.com	carga123	f	2026-02-26 17:05:44.284897	2	2	García	\N	T	1
\.


--
-- Name: areas_area_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.areas_area_id_seq', 5, true);


--
-- Name: auth_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_group_id_seq', 1, false);


--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_group_permissions_id_seq', 1, false);


--
-- Name: auth_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_permission_id_seq', 120, true);


--
-- Name: auth_user_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_user_groups_id_seq', 1, false);


--
-- Name: auth_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_user_id_seq', 1, false);


--
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_user_user_permissions_id_seq', 1, false);


--
-- Name: backup_restore_activesession_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.backup_restore_activesession_id_seq', 151, true);


--
-- Name: backup_restore_systemrestorelog_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.backup_restore_systemrestorelog_id_seq', 2, true);


--
-- Name: django_admin_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_admin_log_id_seq', 1, false);


--
-- Name: django_content_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_content_type_id_seq', 30, true);


--
-- Name: django_migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_migrations_id_seq', 54, true);


--
-- Name: projects_adjuntoauditlog_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.projects_adjuntoauditlog_id_seq', 3, true);


--
-- Name: projects_adjuntoproyecto_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.projects_adjuntoproyecto_id_seq', 1, false);


--
-- Name: projects_comentarioauditlog_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.projects_comentarioauditlog_id_seq', 1, true);


--
-- Name: projects_comentarioproyecto_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.projects_comentarioproyecto_id_seq', 3, true);


--
-- Name: projects_eje_id_eje_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.projects_eje_id_eje_seq', 6, true);


--
-- Name: projects_etapa_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.projects_etapa_id_seq', 18, true);


--
-- Name: projects_indicador_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.projects_indicador_id_seq', 1, false);


--
-- Name: projects_objetivoestrategico_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.projects_objetivoestrategico_id_seq', 31, true);


--
-- Name: projects_plan_id_plan_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.projects_plan_id_plan_seq', 6, true);


--
-- Name: projects_proyecto_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.projects_proyecto_id_seq', 69, true);


--
-- Name: projects_proyectoarea_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.projects_proyectoarea_id_seq', 1, false);


--
-- Name: projects_proyectoequipo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.projects_proyectoequipo_id_seq', 1, false);


--
-- Name: projects_proyectopresupuestoitem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.projects_proyectopresupuestoitem_id_seq', 6, true);


--
-- Name: secretarias_secretaria_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.secretarias_secretaria_id_seq', 21, true);


--
-- Name: tasks_adjuntotarea_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tasks_adjuntotarea_id_seq', 2, true);


--
-- Name: tasks_comentariotarea_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tasks_comentariotarea_id_seq', 4, true);


--
-- Name: tasks_historialtarea_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tasks_historialtarea_id_seq', 113, true);


--
-- Name: tasks_tarea_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tasks_tarea_id_seq', 233, true);


--
-- Name: users_rol_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_rol_id_seq', 4, true);


--
-- Name: users_usuario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_usuario_id_seq', 17, true);


--
-- Name: projects_proyectopresupuestoitem projects_proyectopresupuestoitem_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_proyectopresupuestoitem
    ADD CONSTRAINT projects_proyectopresupuestoitem_pkey PRIMARY KEY (id);


--
-- Name: auth_group sqlite_autoindex_auth_group_1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT sqlite_autoindex_auth_group_1 PRIMARY KEY (name, id);


--
-- Name: auth_user sqlite_autoindex_auth_user_1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user
    ADD CONSTRAINT sqlite_autoindex_auth_user_1 PRIMARY KEY (username, id);


--
-- Name: backup_restore_activesession sqlite_autoindex_backup_restore_activesession_1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backup_restore_activesession
    ADD CONSTRAINT sqlite_autoindex_backup_restore_activesession_1 PRIMARY KEY (session_key, id);


--
-- Name: django_session sqlite_autoindex_django_session_1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_session
    ADD CONSTRAINT sqlite_autoindex_django_session_1 PRIMARY KEY (session_key);


--
-- Name: projects_programa sqlite_autoindex_projects_programa_1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects_programa
    ADD CONSTRAINT sqlite_autoindex_projects_programa_1 PRIMARY KEY (id_programa);


--
-- Name: secretarias_secretaria sqlite_autoindex_secretarias_secretaria_1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.secretarias_secretaria
    ADD CONSTRAINT sqlite_autoindex_secretarias_secretaria_1 PRIMARY KEY (codigo, id);


--
-- Name: users_usuario sqlite_autoindex_users_usuario_1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users_usuario
    ADD CONSTRAINT sqlite_autoindex_users_usuario_1 PRIMARY KEY (email, id);


--
-- Name: areas_area_usuario_responsable_area_id_61d7946c; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX areas_area_usuario_responsable_area_id_61d7946c ON public.areas_area USING btree (usuario_responsable_area_id);


--
-- Name: auth_group_permissions_group_id_b120cbf9; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_group_permissions_group_id_b120cbf9 ON public.auth_group_permissions USING btree (group_id);


--
-- Name: auth_group_permissions_group_id_permission_id_0cd325b0_uniq; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX auth_group_permissions_group_id_permission_id_0cd325b0_uniq ON public.auth_group_permissions USING btree (group_id, permission_id);


--
-- Name: auth_group_permissions_permission_id_84c5c92e; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_group_permissions_permission_id_84c5c92e ON public.auth_group_permissions USING btree (permission_id);


--
-- Name: auth_permission_content_type_id_2f476e4b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_permission_content_type_id_2f476e4b ON public.auth_permission USING btree (content_type_id);


--
-- Name: auth_permission_content_type_id_codename_01ab375a_uniq; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX auth_permission_content_type_id_codename_01ab375a_uniq ON public.auth_permission USING btree (content_type_id, codename);


--
-- Name: auth_user_groups_group_id_97559544; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_user_groups_group_id_97559544 ON public.auth_user_groups USING btree (group_id);


--
-- Name: auth_user_groups_user_id_6a12ed8b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_user_groups_user_id_6a12ed8b ON public.auth_user_groups USING btree (user_id);


--
-- Name: auth_user_groups_user_id_group_id_94350c0c_uniq; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX auth_user_groups_user_id_group_id_94350c0c_uniq ON public.auth_user_groups USING btree (user_id, group_id);


--
-- Name: auth_user_user_permissions_permission_id_1fbb5f2c; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_user_user_permissions_permission_id_1fbb5f2c ON public.auth_user_user_permissions USING btree (permission_id);


--
-- Name: auth_user_user_permissions_user_id_a95ead1b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_user_user_permissions_user_id_a95ead1b ON public.auth_user_user_permissions USING btree (user_id);


--
-- Name: auth_user_user_permissions_user_id_permission_id_14a6b632_uniq; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX auth_user_user_permissions_user_id_permission_id_14a6b632_uniq ON public.auth_user_user_permissions USING btree (user_id, permission_id);


--
-- Name: backup_restore_activesession_user_id_da9594d5; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX backup_restore_activesession_user_id_da9594d5 ON public.backup_restore_activesession USING btree (user_id);


--
-- Name: backup_restore_systemrestorelog_user_id_83ef17c4; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX backup_restore_systemrestorelog_user_id_83ef17c4 ON public.backup_restore_systemrestorelog USING btree (user_id);


--
-- Name: django_admin_log_content_type_id_c4bce8eb; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_admin_log_content_type_id_c4bce8eb ON public.django_admin_log USING btree (content_type_id);


--
-- Name: django_admin_log_user_id_c564eba6; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_admin_log_user_id_c564eba6 ON public.django_admin_log USING btree (user_id);


--
-- Name: django_content_type_app_label_model_76bd3d3b_uniq; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX django_content_type_app_label_model_76bd3d3b_uniq ON public.django_content_type USING btree (app_label, model);


--
-- Name: django_session_expire_date_a5c62663; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_session_expire_date_a5c62663 ON public.django_session USING btree (expire_date);


--
-- Name: projects_adjuntoauditlog_usuario_id_332abdef; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_adjuntoauditlog_usuario_id_332abdef ON public.projects_adjuntoauditlog USING btree (usuario_id);


--
-- Name: projects_adjuntoproyecto_proyecto_id_de04cd19; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_adjuntoproyecto_proyecto_id_de04cd19 ON public.projects_adjuntoproyecto USING btree (proyecto_id);


--
-- Name: projects_adjuntoproyecto_subido_por_id_1a5ac724; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_adjuntoproyecto_subido_por_id_1a5ac724 ON public.projects_adjuntoproyecto USING btree (subido_por_id);


--
-- Name: projects_comentarioauditlog_usuario_id_b82e5f78; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_comentarioauditlog_usuario_id_b82e5f78 ON public.projects_comentarioauditlog USING btree (usuario_id);


--
-- Name: projects_comentarioproyecto_editado_por_id_aa7bc9fb; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_comentarioproyecto_editado_por_id_aa7bc9fb ON public.projects_comentarioproyecto USING btree (editado_por_id);


--
-- Name: projects_comentarioproyecto_proyecto_id_23f0923a; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_comentarioproyecto_proyecto_id_23f0923a ON public.projects_comentarioproyecto USING btree (proyecto_id);


--
-- Name: projects_comentarioproyecto_usuario_id_3ff34849; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_comentarioproyecto_usuario_id_3ff34849 ON public.projects_comentarioproyecto USING btree (usuario_id);


--
-- Name: projects_etapa_proyecto_id_f06d9c85; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_etapa_proyecto_id_f06d9c85 ON public.projects_etapa USING btree (proyecto_id);


--
-- Name: projects_indicador_proyecto_id_7a71525d; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_indicador_proyecto_id_7a71525d ON public.projects_indicador USING btree (proyecto_id);


--
-- Name: projects_objetivoestrategico_programa_id_f657c766; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_objetivoestrategico_programa_id_f657c766 ON public.projects_objetivoestrategico USING btree (programa_id);


--
-- Name: projects_plan_eje_id_923ebf1b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_plan_eje_id_923ebf1b ON public.projects_plan USING btree (eje_id);


--
-- Name: projects_programa_plan_id_56d727dd; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_programa_plan_id_56d727dd ON public.projects_programa USING btree (plan_id);


--
-- Name: projects_proyecto_area_id_068a2ea0; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_proyecto_area_id_068a2ea0 ON public.projects_proyecto USING btree (area_id);


--
-- Name: projects_proyecto_creado_por_id_99d1eaa1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_proyecto_creado_por_id_99d1eaa1 ON public.projects_proyecto USING btree (creado_por_id);


--
-- Name: projects_proyecto_objetivo_estrategico_id_7a179b37; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_proyecto_objetivo_estrategico_id_7a179b37 ON public.projects_proyecto USING btree (objetivo_estrategico_id);


--
-- Name: projects_proyecto_programa_id_d20040ce; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_proyecto_programa_id_d20040ce ON public.projects_proyecto USING btree (programa_id);


--
-- Name: projects_proyecto_secretaria_id_3945fad2; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_proyecto_secretaria_id_3945fad2 ON public.projects_proyecto USING btree (secretaria_id);


--
-- Name: projects_proyecto_usuario_responsable_id_82b84ee8; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_proyecto_usuario_responsable_id_82b84ee8 ON public.projects_proyecto USING btree (usuario_responsable_id);


--
-- Name: projects_proyectoarea_area_id_fbd1799b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_proyectoarea_area_id_fbd1799b ON public.projects_proyectoarea USING btree (area_id);


--
-- Name: projects_proyectoarea_proyecto_id_978c5542; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_proyectoarea_proyecto_id_978c5542 ON public.projects_proyectoarea USING btree (proyecto_id);


--
-- Name: projects_proyectoarea_proyecto_id_area_id_6e06f787_uniq; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX projects_proyectoarea_proyecto_id_area_id_6e06f787_uniq ON public.projects_proyectoarea USING btree (proyecto_id, area_id);


--
-- Name: projects_proyectoequipo_proyecto_id_c21bce82; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_proyectoequipo_proyecto_id_c21bce82 ON public.projects_proyectoequipo USING btree (proyecto_id);


--
-- Name: projects_proyectoequipo_proyecto_id_usuario_id_6b2de8cb_uniq; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX projects_proyectoequipo_proyecto_id_usuario_id_6b2de8cb_uniq ON public.projects_proyectoequipo USING btree (proyecto_id, usuario_id);


--
-- Name: projects_proyectoequipo_usuario_id_1494461b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_proyectoequipo_usuario_id_1494461b ON public.projects_proyectoequipo USING btree (usuario_id);


--
-- Name: projects_proyectopresupuestoitem_proyecto_id_28637cf4; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX projects_proyectopresupuestoitem_proyecto_id_28637cf4 ON public.projects_proyectopresupuestoitem USING btree (proyecto_id);


--
-- Name: proy_area_estado_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX proy_area_estado_idx ON public.projects_proyecto USING btree (area_id, estado);


--
-- Name: proy_estado_fin_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX proy_estado_fin_idx ON public.projects_proyecto USING btree (estado, fecha_fin_estimada);


--
-- Name: proy_pres_cat_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX proy_pres_cat_idx ON public.projects_proyectopresupuestoitem USING btree (categoria_gasto);


--
-- Name: proy_pres_item_ord_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX proy_pres_item_ord_idx ON public.projects_proyectopresupuestoitem USING btree (proyecto_id, orden);


--
-- Name: proy_sec_estado_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX proy_sec_estado_idx ON public.projects_proyecto USING btree (secretaria_id, estado);


--
-- Name: tarea_estado_venc_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tarea_estado_venc_idx ON public.tasks_tarea USING btree (estado, fecha_vencimiento);


--
-- Name: tarea_proj_padre_ord_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tarea_proj_padre_ord_idx ON public.tasks_tarea USING btree (proyecto_id, tarea_padre_id, orden);


--
-- Name: tarea_resp_estado_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tarea_resp_estado_idx ON public.tasks_tarea USING btree (responsable_id, estado);


--
-- Name: tasks_adjuntotarea_subido_por_id_f6119e2b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tasks_adjuntotarea_subido_por_id_f6119e2b ON public.tasks_adjuntotarea USING btree (subido_por_id);


--
-- Name: tasks_adjuntotarea_tarea_id_c6e5c7c0; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tasks_adjuntotarea_tarea_id_c6e5c7c0 ON public.tasks_adjuntotarea USING btree (tarea_id);


--
-- Name: tasks_comentariotarea_editado_por_id_ebd4b676; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tasks_comentariotarea_editado_por_id_ebd4b676 ON public.tasks_comentariotarea USING btree (editado_por_id);


--
-- Name: tasks_comentariotarea_tarea_id_ff2fb2e9; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tasks_comentariotarea_tarea_id_ff2fb2e9 ON public.tasks_comentariotarea USING btree (tarea_id);


--
-- Name: tasks_comentariotarea_usuario_id_e8ae4163; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tasks_comentariotarea_usuario_id_e8ae4163 ON public.tasks_comentariotarea USING btree (usuario_id);


--
-- Name: tasks_historialtarea_tarea_id_5b5978f0; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tasks_historialtarea_tarea_id_5b5978f0 ON public.tasks_historialtarea USING btree (tarea_id);


--
-- Name: tasks_historialtarea_usuario_id_6902eef4; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tasks_historialtarea_usuario_id_6902eef4 ON public.tasks_historialtarea USING btree (usuario_id);


--
-- Name: tasks_tarea_area_id_c1228a74; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tasks_tarea_area_id_c1228a74 ON public.tasks_tarea USING btree (area_id);


--
-- Name: tasks_tarea_etapa_id_b53afac6; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tasks_tarea_etapa_id_b53afac6 ON public.tasks_tarea USING btree (etapa_id);


--
-- Name: tasks_tarea_orden_706f2ec5; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tasks_tarea_orden_706f2ec5 ON public.tasks_tarea USING btree (orden);


--
-- Name: tasks_tarea_proyecto_id_30439ac6; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tasks_tarea_proyecto_id_30439ac6 ON public.tasks_tarea USING btree (proyecto_id);


--
-- Name: tasks_tarea_responsable_id_4d92269c; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tasks_tarea_responsable_id_4d92269c ON public.tasks_tarea USING btree (responsable_id);


--
-- Name: tasks_tarea_secretaria_id_6060deb5; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tasks_tarea_secretaria_id_6060deb5 ON public.tasks_tarea USING btree (secretaria_id);


--
-- Name: tasks_tarea_tarea_padre_id_1e003706; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX tasks_tarea_tarea_padre_id_1e003706 ON public.tasks_tarea USING btree (tarea_padre_id);


--
-- Name: users_usuario_area_id_beb1f97d; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX users_usuario_area_id_beb1f97d ON public.users_usuario USING btree (area_id);


--
-- Name: users_usuario_rol_id_9bc301ef; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX users_usuario_rol_id_9bc301ef ON public.users_usuario USING btree (rol_id);


--
-- Name: users_usuario_secretaria_id_1940021a; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX users_usuario_secretaria_id_1940021a ON public.users_usuario USING btree (secretaria_id);


--
-- PostgreSQL database dump complete
--

