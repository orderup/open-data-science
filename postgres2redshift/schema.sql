--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

--
-- Name: _final_mode(anyarray); Type: FUNCTION; Schema: public; Owner: uc0o9etll61111
--

CREATE FUNCTION _final_mode(anyarray) RETURNS anyelement
    LANGUAGE sql IMMUTABLE
    AS $_$
          SELECT a
          FROM unnest($1) a
          GROUP BY 1
          ORDER BY COUNT(1) DESC, 1
          LIMIT 1;
      $_$;


ALTER FUNCTION public._final_mode(anyarray) OWNER TO uc0o9etll61111;

--
-- Name: distance(double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: uc0o9etll61111
--

CREATE FUNCTION distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
DECLARE                                                   
    x float = 69.1 * (lat2 - lat1);                           
    y float = 69.1 * (lon2 - lon1) * cos(lat1 / 57.3);        
BEGIN                                                     
    RETURN sqrt(x * x + y * y);                               
END  
$$;


ALTER FUNCTION public.distance(lat1 double precision, lon1 double precision, lat2 double precision, lon2 double precision) OWNER TO uc0o9etll61111;

--
-- Name: estimation_model_smart_number_of_drivers(bigint, bigint); Type: FUNCTION; Schema: public; Owner: uc0o9etll61111
--

CREATE FUNCTION estimation_model_smart_number_of_drivers(active_driver_count bigint, drivers_scheduled_for_next_shift bigint) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
      DECLARE
        minute_of_hour integer = extract(minute from now());
        x float = -10.7535095 + (0.2275859 * minute_of_hour);
        probability_of_dispatch_next_shift float = exp(x) / (1 + exp(x));
      BEGIN
        return (1-probability_of_dispatch_next_shift)*active_driver_count + probability_of_dispatch_next_shift*drivers_scheduled_for_next_shift;
      END
      $$;


ALTER FUNCTION public.estimation_model_smart_number_of_drivers(active_driver_count bigint, drivers_scheduled_for_next_shift bigint) OWNER TO uc0o9etll61111;

--
-- Name: fix_loyalty_cash(json); Type: FUNCTION; Schema: public; Owner: uc0o9etll61111
--

CREATE FUNCTION fix_loyalty_cash(totals json) RETURNS json
    LANGUAGE plv8
    AS $$
        totals.loyalty_cash = 0;
        return totals;
      $$;


ALTER FUNCTION public.fix_loyalty_cash(totals json) OWNER TO uc0o9etll61111;

--
-- Name: fix_non_prepaid_fees(json); Type: FUNCTION; Schema: public; Owner: uc0o9etll61111
--

CREATE FUNCTION fix_non_prepaid_fees(fees json) RETURNS json
    LANGUAGE plv8
    AS $$
        fees.restaurant_distribution = 0 - fees.commission;
        return fees;
      $$;


ALTER FUNCTION public.fix_non_prepaid_fees(fees json) OWNER TO uc0o9etll61111;

--
-- Name: fix_non_prepaid_totals(json); Type: FUNCTION; Schema: public; Owner: uc0o9etll61111
--

CREATE FUNCTION fix_non_prepaid_totals(totals json) RETURNS json
    LANGUAGE plv8
    AS $$
        totals.prepaid_total = 0;
        return totals;
      $$;


ALTER FUNCTION public.fix_non_prepaid_totals(totals json) OWNER TO uc0o9etll61111;

--
-- Name: fix_prepaid_fees(json, json); Type: FUNCTION; Schema: public; Owner: uc0o9etll61111
--

CREATE FUNCTION fix_prepaid_fees(totals json, fees json) RETURNS json
    LANGUAGE plv8
    AS $$
        fees.restaurant_distribution = totals.total - fees.commission - fees.credit_card_processing;
        return fees;
      $$;


ALTER FUNCTION public.fix_prepaid_fees(totals json, fees json) OWNER TO uc0o9etll61111;

--
-- Name: fix_prepaid_totals(json); Type: FUNCTION; Schema: public; Owner: uc0o9etll61111
--

CREATE FUNCTION fix_prepaid_totals(totals json) RETURNS json
    LANGUAGE plv8
    AS $$
        totals.prepaid_total = totals.total;
        return totals;
      $$;


ALTER FUNCTION public.fix_prepaid_totals(totals json) OWNER TO uc0o9etll61111;

--
-- Name: isnottruncated(json); Type: FUNCTION; Schema: public; Owner: uc0o9etll61111
--

CREATE FUNCTION isnottruncated(payment_details json) RETURNS boolean
    LANGUAGE plv8
    AS $$ return (payment_details.card_id||'').length > 5;
$$;


ALTER FUNCTION public.isnottruncated(payment_details json) OWNER TO uc0o9etll61111;

--
-- Name: makepolygonfromarea(text); Type: FUNCTION; Schema: public; Owner: uc0o9etll61111
--

CREATE FUNCTION makepolygonfromarea(text) RETURNS geometry
    LANGUAGE plpgsql
    AS $_$
        declare
          new_points Geometry array;
          points text array;
          point varchar;
          i integer;
        begin
          raise NOTICE 'Converting points: (%)', $1;
          points := string_to_array($1, '|');

          IF array_upper(points,1) < 3 THEN
            raise NOTICE 'Not enough points: %', $1;
          END IF;

          FOR i IN array_lower(points, 1) .. array_upper(points, 1)
          LOOP
            select array_append(new_points, ST_MakePoint(
              cast(substring(points[i], ',(.*)\)$') as double precision),
              cast(substring(points[i], '^\((.*),') as double precision)
            )) into new_points;
          END LOOP;

          select array_append(new_points, new_points[1]) into new_points;

          IF array_upper(points,1) < 3 THEN
              return ST_SetSRID(ST_MakeLine(new_points), 3785);
          ELSE
            return ST_SetSRID(ST_MakePolygon(ST_MakeLine(new_points)), 3785);
          END IF;
        end;
      $_$;


ALTER FUNCTION public.makepolygonfromarea(text) OWNER TO uc0o9etll61111;

--
-- Name: truncate1millioncardnumbers(integer); Type: FUNCTION; Schema: public; Owner: uc0o9etll61111
--

CREATE FUNCTION truncate1millioncardnumbers(orderid integer) RETURNS void
    LANGUAGE sql
    AS $$
update orders set payment_details=truncateCardNumber(payment_details)
where orderid < id AND id < orderid+1000000
and payment_type = 'transmit_credit_card_to_restaurant'  
$$;


ALTER FUNCTION public.truncate1millioncardnumbers(orderid integer) OWNER TO uc0o9etll61111;

--
-- Name: truncatecardnumber(json); Type: FUNCTION; Schema: public; Owner: uc0o9etll61111
--

CREATE FUNCTION truncatecardnumber(payment json) RETURNS json
    LANGUAGE plv8
    AS $$ payment.card_id = null; return payment;
$$;


ALTER FUNCTION public.truncatecardnumber(payment json) OWNER TO uc0o9etll61111;

--
-- Name: mode(anyelement); Type: AGGREGATE; Schema: public; Owner: uc0o9etll61111
--

CREATE AGGREGATE mode(anyelement) (
    SFUNC = array_append,
    STYPE = anyarray,
    INITCOND = '{}',
    FINALFUNC = _final_mode
);


ALTER AGGREGATE public.mode(anyelement) OWNER TO uc0o9etll61111;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: active_cart_counts; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE active_cart_counts (
    id integer NOT NULL,
    count integer,
    delivery_service_id integer NOT NULL,
    created_at timestamp without time zone,
    window_minutes integer
);


ALTER TABLE public.active_cart_counts OWNER TO uc0o9etll61111;

--
-- Name: active_cart_counts_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE active_cart_counts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.active_cart_counts_id_seq OWNER TO uc0o9etll61111;

--
-- Name: active_cart_counts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE active_cart_counts_id_seq OWNED BY active_cart_counts.id;


--
-- Name: adjustments; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE adjustments (
    id integer NOT NULL,
    memo character varying(255) NOT NULL,
    order_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    restaurant_id integer NOT NULL,
    credit_card_processing numeric(19,6) NOT NULL,
    commission numeric(19,6) NOT NULL,
    order_up_distribution numeric(19,6) NOT NULL,
    market_distribution numeric(19,6) NOT NULL,
    restaurant_distribution numeric(19,6) NOT NULL,
    subtotal numeric(19,2) NOT NULL,
    loyalty_cash numeric(19,2) NOT NULL,
    sales_tax numeric(19,2) NOT NULL,
    delivery_fee numeric(19,2) NOT NULL,
    tip numeric(19,2) NOT NULL,
    processing_fee numeric(19,2) NOT NULL,
    total numeric(19,2) NOT NULL,
    chargeable_sale numeric(19,2) NOT NULL,
    prepaid_total numeric(19,2) NOT NULL,
    commission_collected numeric(19,6) NOT NULL,
    commission_percentage numeric(19,6),
    commission_flat numeric(19,2),
    type character varying(255),
    adjusted_by character varying(255),
    transaction_id character varying(255),
    transaction_type character varying(255),
    driver_distribution numeric(19,6),
    order_up_delivery_distribution numeric(19,6),
    affiliate_id integer,
    affiliate_commission numeric(19,6),
    affiliate_commission_from_restaurant numeric(19,6),
    market_delivery_distribution numeric(19,6),
    refunded_at timestamp without time zone,
    requested_delivery_fee numeric(19,2),
    excess_restaurant_sales_tax_on_delivery_fee numeric(19,2),
    restaurant_delivery_fee numeric(19,2),
    market_delivery_fee numeric(19,2),
    voided_at timestamp without time zone,
    affects_market_owner boolean DEFAULT true NOT NULL,
    affects_restaurant boolean DEFAULT true NOT NULL,
    affects_driver boolean DEFAULT true NOT NULL
);


ALTER TABLE public.adjustments OWNER TO uc0o9etll61111;

--
-- Name: adjustments_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE adjustments_id_seq
    START WITH 40000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.adjustments_id_seq OWNER TO uc0o9etll61111;

--
-- Name: adjustments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE adjustments_id_seq OWNED BY adjustments.id;


--
-- Name: affiliates; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE affiliates (
    id integer NOT NULL,
    market_id integer NOT NULL,
    name character varying(255) NOT NULL,
    commission_percentage numeric(19,4) NOT NULL,
    active boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    restaurant_id integer
);


ALTER TABLE public.affiliates OWNER TO uc0o9etll61111;

--
-- Name: affiliates_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE affiliates_id_seq
    START WITH 300
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.affiliates_id_seq OWNER TO uc0o9etll61111;

--
-- Name: affiliates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE affiliates_id_seq OWNED BY affiliates.id;


--
-- Name: april_fools_responses; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE april_fools_responses (
    id integer NOT NULL,
    customer_id integer,
    data json DEFAULT '{}'::json NOT NULL,
    created_at timestamp without time zone
);


ALTER TABLE public.april_fools_responses OWNER TO uc0o9etll61111;

--
-- Name: april_fools_responses_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE april_fools_responses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.april_fools_responses_id_seq OWNER TO uc0o9etll61111;

--
-- Name: april_fools_responses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE april_fools_responses_id_seq OWNED BY april_fools_responses.id;


--
-- Name: audits; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE audits (
    id integer NOT NULL,
    market_id integer,
    restaurant_id integer,
    admin_email character varying(255),
    action character varying(255),
    subject_id integer NOT NULL,
    subject_type character varying(255) NOT NULL,
    change_data json,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    subject_name character varying(255)
);


ALTER TABLE public.audits OWNER TO uc0o9etll61111;

--
-- Name: audits_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE audits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.audits_id_seq OWNER TO uc0o9etll61111;

--
-- Name: audits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE audits_id_seq OWNED BY audits.id;


--
-- Name: banner_ads; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE banner_ads (
    id integer NOT NULL,
    market_id integer NOT NULL,
    restaurant_id integer,
    name character varying(255),
    target_url character varying(255),
    delivery_days integer DEFAULT 0 NOT NULL,
    takeout_days integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    image_file_name character varying(255),
    image_content_type character varying(255),
    image_file_size integer,
    image_updated_at timestamp without time zone,
    image_fingerprint character varying(255)
);


ALTER TABLE public.banner_ads OWNER TO uc0o9etll61111;

--
-- Name: banner_ads_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE banner_ads_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.banner_ads_id_seq OWNER TO uc0o9etll61111;

--
-- Name: banner_ads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE banner_ads_id_seq OWNED BY banner_ads.id;


--
-- Name: beacons; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE beacons (
    id integer NOT NULL,
    market_id integer,
    latitude numeric(9,6) DEFAULT 0 NOT NULL,
    longitude numeric(9,6) DEFAULT 0 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.beacons OWNER TO uc0o9etll61111;

--
-- Name: beacons_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE beacons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.beacons_id_seq OWNER TO uc0o9etll61111;

--
-- Name: beacons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE beacons_id_seq OWNED BY beacons.id;


--
-- Name: blacklisted_email_addresses; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE blacklisted_email_addresses (
    id integer NOT NULL,
    email character varying(255),
    memo character varying(255)
);


ALTER TABLE public.blacklisted_email_addresses OWNER TO uc0o9etll61111;

--
-- Name: blacklisted_email_addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE blacklisted_email_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.blacklisted_email_addresses_id_seq OWNER TO uc0o9etll61111;

--
-- Name: blacklisted_email_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE blacklisted_email_addresses_id_seq OWNED BY blacklisted_email_addresses.id;


--
-- Name: blacklisted_email_domains; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE blacklisted_email_domains (
    id integer NOT NULL,
    domain character varying(255),
    memo character varying(255)
);


ALTER TABLE public.blacklisted_email_domains OWNER TO uc0o9etll61111;

--
-- Name: blacklisted_email_domains_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE blacklisted_email_domains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.blacklisted_email_domains_id_seq OWNER TO uc0o9etll61111;

--
-- Name: blacklisted_email_domains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE blacklisted_email_domains_id_seq OWNED BY blacklisted_email_domains.id;


--
-- Name: blacklisted_ip_addresses; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE blacklisted_ip_addresses (
    id integer NOT NULL,
    ip_address character varying(255),
    memo character varying(255)
);


ALTER TABLE public.blacklisted_ip_addresses OWNER TO uc0o9etll61111;

--
-- Name: blacklisted_ip_addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE blacklisted_ip_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.blacklisted_ip_addresses_id_seq OWNER TO uc0o9etll61111;

--
-- Name: blacklisted_ip_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE blacklisted_ip_addresses_id_seq OWNED BY blacklisted_ip_addresses.id;


--
-- Name: blacklisted_phone_numbers; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE blacklisted_phone_numbers (
    id integer NOT NULL,
    phone character varying(255),
    memo character varying(255)
);


ALTER TABLE public.blacklisted_phone_numbers OWNER TO uc0o9etll61111;

--
-- Name: blacklisted_phone_numbers_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE blacklisted_phone_numbers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.blacklisted_phone_numbers_id_seq OWNER TO uc0o9etll61111;

--
-- Name: blacklisted_phone_numbers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE blacklisted_phone_numbers_id_seq OWNED BY blacklisted_phone_numbers.id;


--
-- Name: blazer_audits; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE blazer_audits (
    id integer NOT NULL,
    user_id integer,
    query_id integer,
    statement text,
    created_at timestamp without time zone
);


ALTER TABLE public.blazer_audits OWNER TO uc0o9etll61111;

--
-- Name: blazer_audits_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE blazer_audits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.blazer_audits_id_seq OWNER TO uc0o9etll61111;

--
-- Name: blazer_audits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE blazer_audits_id_seq OWNED BY blazer_audits.id;


--
-- Name: blazer_queries; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE blazer_queries (
    id integer NOT NULL,
    creator_id integer,
    name character varying(255),
    description text,
    statement text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.blazer_queries OWNER TO uc0o9etll61111;

--
-- Name: blazer_queries_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE blazer_queries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.blazer_queries_id_seq OWNER TO uc0o9etll61111;

--
-- Name: blazer_queries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE blazer_queries_id_seq OWNED BY blazer_queries.id;


--
-- Name: building_groups; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE building_groups (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    market_id integer
);


ALTER TABLE public.building_groups OWNER TO uc0o9etll61111;

--
-- Name: building_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE building_groups_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.building_groups_id_seq OWNER TO uc0o9etll61111;

--
-- Name: building_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE building_groups_id_seq OWNED BY building_groups.id;


--
-- Name: buildings; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE buildings (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    address_format character varying(255) NOT NULL,
    city character varying(255) NOT NULL,
    state character varying(255) NOT NULL,
    zip character varying(255) NOT NULL,
    latitude numeric(9,6) NOT NULL,
    longitude numeric(9,6) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    building_group_id integer
);


ALTER TABLE public.buildings OWNER TO uc0o9etll61111;

--
-- Name: buildings_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE buildings_id_seq
    START WITH 2000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.buildings_id_seq OWNER TO uc0o9etll61111;

--
-- Name: buildings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE buildings_id_seq OWNED BY buildings.id;


--
-- Name: campus_payment_cards; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE campus_payment_cards (
    id integer NOT NULL,
    name character varying(255),
    number_digits integer,
    pin_digits integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    enabled boolean DEFAULT true
);


ALTER TABLE public.campus_payment_cards OWNER TO uc0o9etll61111;

--
-- Name: campus_payment_cards_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE campus_payment_cards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.campus_payment_cards_id_seq OWNER TO uc0o9etll61111;

--
-- Name: campus_payment_cards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE campus_payment_cards_id_seq OWNED BY campus_payment_cards.id;


--
-- Name: canonicalized_json_menus; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE canonicalized_json_menus (
    id integer NOT NULL,
    restaurant_id integer,
    data json,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    last_queued_at timestamp without time zone,
    last_published_at timestamp without time zone,
    change_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.canonicalized_json_menus OWNER TO uc0o9etll61111;

--
-- Name: canonicalized_json_menus_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE canonicalized_json_menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.canonicalized_json_menus_id_seq OWNER TO uc0o9etll61111;

--
-- Name: canonicalized_json_menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE canonicalized_json_menus_id_seq OWNED BY canonicalized_json_menus.id;


--
-- Name: canonicalized_menus; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE canonicalized_menus (
    id integer NOT NULL,
    restaurant_id integer,
    data json,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    change_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.canonicalized_menus OWNER TO uc0o9etll61111;

--
-- Name: canonicalized_menus_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE canonicalized_menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.canonicalized_menus_id_seq OWNER TO uc0o9etll61111;

--
-- Name: canonicalized_menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE canonicalized_menus_id_seq OWNED BY canonicalized_menus.id;


--
-- Name: cart_coupons; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE cart_coupons (
    id integer NOT NULL,
    cart_id integer NOT NULL,
    coupon_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.cart_coupons OWNER TO uc0o9etll61111;

--
-- Name: cart_coupons_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE cart_coupons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cart_coupons_id_seq OWNER TO uc0o9etll61111;

--
-- Name: cart_coupons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE cart_coupons_id_seq OWNED BY cart_coupons.id;


--
-- Name: cart_item_options; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE cart_item_options (
    id integer NOT NULL,
    cart_item_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    quantity integer DEFAULT 1 NOT NULL,
    option_group_id character varying(255) NOT NULL,
    option_group_option_id character varying(255) NOT NULL,
    half integer DEFAULT 3 NOT NULL
);


ALTER TABLE public.cart_item_options OWNER TO uc0o9etll61111;

--
-- Name: cart_item_options_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE cart_item_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cart_item_options_id_seq OWNER TO uc0o9etll61111;

--
-- Name: cart_item_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE cart_item_options_id_seq OWNED BY cart_item_options.id;


--
-- Name: cart_items; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE cart_items (
    id integer NOT NULL,
    cart_id integer NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    special_instructions text,
    label_for character varying(255),
    size_id character varying(255) NOT NULL,
    coupon_id integer,
    menu_item_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    cart_participant_id integer
);


ALTER TABLE public.cart_items OWNER TO uc0o9etll61111;

--
-- Name: cart_items_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE cart_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cart_items_id_seq OWNER TO uc0o9etll61111;

--
-- Name: cart_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE cart_items_id_seq OWNED BY cart_items.id;


--
-- Name: cart_participants; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE cart_participants (
    id integer NOT NULL,
    done_ordering_at timestamp without time zone,
    cart_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    customer_id integer,
    device_id character varying(255)
);


ALTER TABLE public.cart_participants OWNER TO uc0o9etll61111;

--
-- Name: cart_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE cart_participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cart_participants_id_seq OWNER TO uc0o9etll61111;

--
-- Name: cart_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE cart_participants_id_seq OWNED BY cart_participants.id;


--
-- Name: carts; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE carts (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    customer_id integer,
    restaurant_id integer NOT NULL,
    device_id character varying(255),
    order_type character varying(255) DEFAULT 'delivery'::character varying NOT NULL,
    customer_address_id integer,
    order_id integer,
    token character varying(255),
    group_order boolean DEFAULT false,
    deliver_at timestamp without time zone
);


ALTER TABLE public.carts OWNER TO uc0o9etll61111;

--
-- Name: carts_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE carts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.carts_id_seq OWNER TO uc0o9etll61111;

--
-- Name: carts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE carts_id_seq OWNED BY carts.id;


--
-- Name: codes_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE codes_seq
    START WITH 3748096
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.codes_seq OWNER TO uc0o9etll61111;

--
-- Name: cohort_memberships; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE cohort_memberships (
    id integer NOT NULL,
    cohort_id integer NOT NULL,
    customer_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    variant_type character varying(255) NOT NULL
);


ALTER TABLE public.cohort_memberships OWNER TO uc0o9etll61111;

--
-- Name: cohort_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE cohort_memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cohort_memberships_id_seq OWNER TO uc0o9etll61111;

--
-- Name: cohort_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE cohort_memberships_id_seq OWNED BY cohort_memberships.id;


--
-- Name: cohort_service_cohorts; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE cohort_service_cohorts (
    id integer NOT NULL,
    cohort_id integer NOT NULL,
    cohort_service_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    a_variant_id bigint,
    b_variant_id bigint,
    control_variant_id bigint
);


ALTER TABLE public.cohort_service_cohorts OWNER TO uc0o9etll61111;

--
-- Name: cohort_service_cohorts_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE cohort_service_cohorts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cohort_service_cohorts_id_seq OWNER TO uc0o9etll61111;

--
-- Name: cohort_service_cohorts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE cohort_service_cohorts_id_seq OWNED BY cohort_service_cohorts.id;


--
-- Name: cohort_services; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE cohort_services (
    id integer NOT NULL,
    type character varying(255) NOT NULL,
    access_token text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.cohort_services OWNER TO uc0o9etll61111;

--
-- Name: cohort_services_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE cohort_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cohort_services_id_seq OWNER TO uc0o9etll61111;

--
-- Name: cohort_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE cohort_services_id_seq OWNED BY cohort_services.id;


--
-- Name: cohorts; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE cohorts (
    id integer NOT NULL,
    type character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.cohorts OWNER TO uc0o9etll61111;

--
-- Name: cohorts_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE cohorts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cohorts_id_seq OWNER TO uc0o9etll61111;

--
-- Name: cohorts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE cohorts_id_seq OWNED BY cohorts.id;


--
-- Name: content; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE content (
    key character varying(255) NOT NULL,
    value text
);


ALTER TABLE public.content OWNER TO uc0o9etll61111;

--
-- Name: coupons; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE coupons (
    id integer NOT NULL,
    name character varying(255),
    display_name character varying(255),
    code character varying(255),
    starts_at timestamp without time zone,
    ends_at timestamp without time zone,
    max_redemptions integer,
    redemptions_count integer DEFAULT 0 NOT NULL,
    redemptions_per_customer integer,
    redemptions_per_order integer,
    description text,
    coupon_type integer,
    restriction_type integer,
    order_minimum numeric(5,2),
    discount_amount numeric(5,2),
    discount_percentage numeric(5,4),
    item_id integer,
    restaurant_id integer,
    market_id integer,
    combinable boolean,
    valid_for_takeout boolean DEFAULT true,
    valid_for_delivery boolean DEFAULT true,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    credit_amount numeric,
    first_purchase_only boolean DEFAULT false,
    promoted boolean DEFAULT false,
    one_per_credit_card boolean DEFAULT false NOT NULL
);


ALTER TABLE public.coupons OWNER TO uc0o9etll61111;

--
-- Name: coupons_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE coupons_id_seq
    START WITH 5000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.coupons_id_seq OWNER TO uc0o9etll61111;

--
-- Name: coupons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE coupons_id_seq OWNED BY coupons.id;


--
-- Name: credit_batch_errors; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE credit_batch_errors (
    id integer NOT NULL,
    credit_batch_id integer,
    email character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.credit_batch_errors OWNER TO uc0o9etll61111;

--
-- Name: credit_batch_errors_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE credit_batch_errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.credit_batch_errors_id_seq OWNER TO uc0o9etll61111;

--
-- Name: credit_batch_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE credit_batch_errors_id_seq OWNED BY credit_batch_errors.id;


--
-- Name: credit_batches; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE credit_batches (
    id integer NOT NULL,
    market_id integer,
    reason character varying(255) NOT NULL,
    amount numeric(19,2) NOT NULL,
    memo character varying(255),
    expires_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    hq_funded boolean,
    customer_id integer
);


ALTER TABLE public.credit_batches OWNER TO uc0o9etll61111;

--
-- Name: credit_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE credit_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.credit_batches_id_seq OWNER TO uc0o9etll61111;

--
-- Name: credit_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE credit_batches_id_seq OWNED BY credit_batches.id;


--
-- Name: credit_cards; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE credit_cards (
    id integer NOT NULL,
    customer_id integer,
    external_id character varying(255),
    first_name character varying(255),
    last_name character varying(255),
    last_four character varying(255),
    expiration_date character varying(255),
    description character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    address_1 character varying(255),
    address_2 character varying(255),
    city character varying(255),
    state character varying(255),
    zip character varying(255),
    processor_type character varying(255),
    saved boolean,
    unique_number_identifier character varying(255)
);


ALTER TABLE public.credit_cards OWNER TO uc0o9etll61111;

--
-- Name: credit_cards_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE credit_cards_id_seq
    START WITH 500000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.credit_cards_id_seq OWNER TO uc0o9etll61111;

--
-- Name: credit_cards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE credit_cards_id_seq OWNED BY credit_cards.id;


--
-- Name: credit_items; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE credit_items (
    id integer NOT NULL,
    customer_id integer NOT NULL,
    credit_batch_id integer,
    market_id integer,
    order_id integer,
    reason character varying(255) NOT NULL,
    amount numeric(19,2) NOT NULL,
    memo character varying(255),
    expires_at timestamp without time zone,
    transaction_id character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    credit_source_id integer,
    hq_funded boolean,
    expiration_notification_sent_at timestamp without time zone,
    accounting_category character varying(255),
    accounting_reason character varying(255),
    market_specific_use boolean DEFAULT false NOT NULL
);


ALTER TABLE public.credit_items OWNER TO uc0o9etll61111;

--
-- Name: credit_items_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE credit_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.credit_items_id_seq OWNER TO uc0o9etll61111;

--
-- Name: credit_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE credit_items_id_seq OWNED BY credit_items.id;


--
-- Name: customer_addresses; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE customer_addresses (
    id integer NOT NULL,
    customer_id integer,
    building_id integer,
    address_1 character varying(255),
    address_2 character varying(255),
    city character varying(255),
    state character varying(255),
    zip character varying(255),
    latitude numeric(9,6),
    longitude numeric(9,6),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    device_id character varying(255),
    last_ordered_at timestamp without time zone,
    is_default boolean,
    market_id integer
);


ALTER TABLE public.customer_addresses OWNER TO uc0o9etll61111;

--
-- Name: customer_addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE customer_addresses_id_seq
    START WITH 2000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.customer_addresses_id_seq OWNER TO uc0o9etll61111;

--
-- Name: customer_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE customer_addresses_id_seq OWNED BY customer_addresses.id;


--
-- Name: customer_campus_cards; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE customer_campus_cards (
    id integer NOT NULL,
    campus_payment_card_name character varying(255),
    description character varying(255),
    campus_payment_card_id integer,
    customer_id integer,
    card_number character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.customer_campus_cards OWNER TO uc0o9etll61111;

--
-- Name: customer_campus_cards_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE customer_campus_cards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.customer_campus_cards_id_seq OWNER TO uc0o9etll61111;

--
-- Name: customer_campus_cards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE customer_campus_cards_id_seq OWNED BY customer_campus_cards.id;


--
-- Name: customer_coupon_uses; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE customer_coupon_uses (
    id integer NOT NULL,
    customer_id integer NOT NULL,
    coupon_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    uses integer
);


ALTER TABLE public.customer_coupon_uses OWNER TO uc0o9etll61111;

--
-- Name: customer_coupon_uses_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE customer_coupon_uses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.customer_coupon_uses_id_seq OWNER TO uc0o9etll61111;

--
-- Name: customer_coupon_uses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE customer_coupon_uses_id_seq OWNED BY customer_coupon_uses.id;


--
-- Name: customer_information_requests; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE customer_information_requests (
    id integer NOT NULL,
    email character varying(255),
    address1 character varying(255),
    city character varying(255),
    state character varying(255),
    zip character varying(255),
    latitude character varying(255),
    longitude character varying(255),
    market_id integer,
    rel character varying(255),
    created_at timestamp without time zone
);


ALTER TABLE public.customer_information_requests OWNER TO uc0o9etll61111;

--
-- Name: customer_information_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE customer_information_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.customer_information_requests_id_seq OWNER TO uc0o9etll61111;

--
-- Name: customer_information_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE customer_information_requests_id_seq OWNED BY customer_information_requests.id;


--
-- Name: customer_phones; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE customer_phones (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    message_id character varying(255),
    zip character varying(255),
    state character varying(255),
    city character varying(255),
    country character varying(255),
    phone character varying(255) NOT NULL,
    customer_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    sign_up_referrer_type character varying(255),
    sign_up_referrer_id integer
);


ALTER TABLE public.customer_phones OWNER TO uc0o9etll61111;

--
-- Name: customer_phones_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE customer_phones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.customer_phones_id_seq OWNER TO uc0o9etll61111;

--
-- Name: customer_phones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE customer_phones_id_seq OWNED BY customer_phones.id;


--
-- Name: customers; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE customers (
    id integer NOT NULL,
    first_name character varying(255),
    last_name character varying(255),
    phone character varying(255),
    email character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    import_version integer,
    order_count integer DEFAULT 0 NOT NULL,
    first_ordered_at timestamp without time zone,
    last_ordered_at timestamp without time zone,
    market_access integer[],
    restaurant_access integer[],
    role character varying(255),
    cim_customer_id bigint,
    born_on date,
    should_email_specials boolean,
    should_text_coupons boolean,
    hashed_password character varying(255),
    last_login timestamp without time zone,
    rel character varying(255),
    ip_address character varying(255),
    should_push_notifications boolean DEFAULT true NOT NULL,
    random character varying(255)
);


ALTER TABLE public.customers OWNER TO uc0o9etll61111;

--
-- Name: customers_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE customers_id_seq
    START WITH 1010000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.customers_id_seq OWNER TO uc0o9etll61111;

--
-- Name: customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE customers_id_seq OWNED BY customers.id;


--
-- Name: daily_order_counts; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE daily_order_counts (
    id integer NOT NULL,
    orderable_id integer NOT NULL,
    orderable_type character varying(255) NOT NULL,
    day date NOT NULL,
    orders integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.daily_order_counts OWNER TO uc0o9etll61111;

--
-- Name: daily_order_counts_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE daily_order_counts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.daily_order_counts_id_seq OWNER TO uc0o9etll61111;

--
-- Name: daily_order_counts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE daily_order_counts_id_seq OWNED BY daily_order_counts.id;


--
-- Name: deliveries; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE deliveries (
    id integer NOT NULL,
    order_id integer,
    access_token character varying(255) NOT NULL,
    estimated_prep_time integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    accepted_at timestamp without time zone,
    arrived_at timestamp without time zone,
    left_at timestamp without time zone,
    delivered_at timestamp without time zone,
    status integer DEFAULT 0 NOT NULL,
    accepted_at_latitude numeric(9,6),
    accepted_at_longitude numeric(9,6),
    arrived_at_latitude numeric(9,6),
    arrived_at_longitude numeric(9,6),
    left_at_latitude numeric(9,6),
    left_at_longitude numeric(9,6),
    delivered_at_latitude numeric(9,6),
    delivered_at_longitude numeric(9,6),
    canceled_at timestamp without time zone,
    distance numeric(10,6),
    estimated_driving_time integer,
    order_status_on_arrival integer,
    en_route_to_restaurant_at timestamp without time zone,
    en_route_to_restaurant_latitude numeric(9,6),
    en_route_to_restaurant_longitude numeric(9,6),
    en_route_to_customer_at timestamp without time zone,
    en_route_to_customer_latitude numeric(9,6),
    en_route_to_customer_longitude numeric(9,6),
    delivery_service_id integer,
    grouped_with_id integer,
    send_sms_updates boolean,
    near_customer_at timestamp without time zone,
    near_customer_latitude numeric(9,6),
    near_customer_longitude numeric(9,6),
    dispatch_count integer,
    dispatched_at timestamp without time zone,
    driver_id integer,
    should_dispatch_at timestamp without time zone,
    test_order boolean,
    receipt_required boolean DEFAULT false,
    driver_marketing_incentive numeric(19,4)
);


ALTER TABLE public.deliveries OWNER TO uc0o9etll61111;

--
-- Name: deliveries_hours; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE deliveries_hours (
    id integer NOT NULL,
    hour_at timestamp without time zone,
    delivery_id integer,
    percent_delivery_in_hour numeric,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.deliveries_hours OWNER TO uc0o9etll61111;

--
-- Name: deliveries_hours_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE deliveries_hours_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.deliveries_hours_id_seq OWNER TO uc0o9etll61111;

--
-- Name: deliveries_hours_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE deliveries_hours_id_seq OWNED BY deliveries_hours.id;


--
-- Name: deliveries_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE deliveries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.deliveries_id_seq OWNER TO uc0o9etll61111;

--
-- Name: deliveries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE deliveries_id_seq OWNED BY deliveries.id;


--
-- Name: delivery_comments; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE delivery_comments (
    id integer NOT NULL,
    delivery_step_id integer,
    note character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.delivery_comments OWNER TO uc0o9etll61111;

--
-- Name: delivery_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE delivery_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_comments_id_seq OWNER TO uc0o9etll61111;

--
-- Name: delivery_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE delivery_comments_id_seq OWNED BY delivery_comments.id;


--
-- Name: delivery_estimates; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE delivery_estimates (
    id integer NOT NULL,
    delivery_id integer NOT NULL,
    estimated_left_at timestamp without time zone,
    estimated_en_route_to_customer_at timestamp without time zone,
    estimated_near_customer_at timestamp without time zone,
    estimated_delivered_at timestamp without time zone,
    estimated_claimed_at timestamp without time zone,
    estimated_arrived_at timestamp without time zone,
    estimated_en_route_to_restaurant_at timestamp without time zone,
    estimated_dispatched_at timestamp without time zone,
    type character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    estimation_model_id integer,
    feature_values json
);


ALTER TABLE public.delivery_estimates OWNER TO uc0o9etll61111;

--
-- Name: delivery_estimates_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE delivery_estimates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_estimates_id_seq OWNER TO uc0o9etll61111;

--
-- Name: delivery_estimates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE delivery_estimates_id_seq OWNED BY delivery_estimates.id;


--
-- Name: delivery_log_entries; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE delivery_log_entries (
    id integer NOT NULL,
    delivery_id integer NOT NULL,
    customer_id integer,
    type character varying(255) NOT NULL,
    data json NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.delivery_log_entries OWNER TO uc0o9etll61111;

--
-- Name: delivery_log_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE delivery_log_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_log_entries_id_seq OWNER TO uc0o9etll61111;

--
-- Name: delivery_log_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE delivery_log_entries_id_seq OWNED BY delivery_log_entries.id;


--
-- Name: delivery_service_health_features; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE delivery_service_health_features (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    delivery_service_id integer NOT NULL,
    version integer NOT NULL,
    "values" json NOT NULL
);


ALTER TABLE public.delivery_service_health_features OWNER TO uc0o9etll61111;

--
-- Name: delivery_service_health_features_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE delivery_service_health_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_service_health_features_id_seq OWNER TO uc0o9etll61111;

--
-- Name: delivery_service_health_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE delivery_service_health_features_id_seq OWNED BY delivery_service_health_features.id;


--
-- Name: delivery_service_health_models; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE delivery_service_health_models (
    id integer NOT NULL,
    delivery_service_id integer NOT NULL,
    created_at timestamp without time zone,
    digest character varying(255)
);


ALTER TABLE public.delivery_service_health_models OWNER TO uc0o9etll61111;

--
-- Name: delivery_service_health_models_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE delivery_service_health_models_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_service_health_models_id_seq OWNER TO uc0o9etll61111;

--
-- Name: delivery_service_health_models_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE delivery_service_health_models_id_seq OWNED BY delivery_service_health_models.id;


--
-- Name: delivery_service_health_scores; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE delivery_service_health_scores (
    id integer NOT NULL,
    health_model_id integer,
    score numeric,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.delivery_service_health_scores OWNER TO uc0o9etll61111;

--
-- Name: delivery_service_health_scores_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE delivery_service_health_scores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_service_health_scores_id_seq OWNER TO uc0o9etll61111;

--
-- Name: delivery_service_health_scores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE delivery_service_health_scores_id_seq OWNED BY delivery_service_health_scores.id;


--
-- Name: delivery_service_random_forests; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE delivery_service_random_forests (
    id integer NOT NULL,
    delivery_service_id integer NOT NULL,
    created_at timestamp without time zone
);


ALTER TABLE public.delivery_service_random_forests OWNER TO uc0o9etll61111;

--
-- Name: delivery_service_random_forests_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE delivery_service_random_forests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_service_random_forests_id_seq OWNER TO uc0o9etll61111;

--
-- Name: delivery_service_random_forests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE delivery_service_random_forests_id_seq OWNED BY delivery_service_random_forests.id;


--
-- Name: delivery_services; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE delivery_services (
    id integer NOT NULL,
    name character varying(255),
    market_id integer,
    phone character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    contact_name character varying(255),
    email character varying(255),
    shutdown boolean DEFAULT false,
    operations_manager_name character varying(255),
    operations_manager_email character varying(255),
    operations_manager_phone character varying(255),
    shutdown_automatically boolean DEFAULT false,
    delivery_support_enabled boolean DEFAULT true,
    orderup_delivered boolean DEFAULT false,
    support_fast_and_slow_restaurants boolean DEFAULT false NOT NULL,
    max_orders_for_later_per_timeslot integer,
    warning_threshold numeric(4,0),
    shutdown_threshold numeric(4,0),
    warning_notification_sent_at timestamp without time zone,
    health_score numeric(5,2),
    health_score_computed_at timestamp without time zone,
    recent_health_scores json DEFAULT '[]'::json,
    dispatching_strategy character varying(255),
    canonical_hours_data json,
    hours_change_count integer
);


ALTER TABLE public.delivery_services OWNER TO uc0o9etll61111;

--
-- Name: delivery_services_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE delivery_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_services_id_seq OWNER TO uc0o9etll61111;

--
-- Name: delivery_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE delivery_services_id_seq OWNED BY delivery_services.id;


--
-- Name: delivery_sign_ups; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE delivery_sign_ups (
    id integer NOT NULL,
    first_name character varying(255),
    last_name character varying(255),
    email character varying(255),
    phone character varying(255),
    mobile_os character varying(255),
    market_id integer,
    vehicle_type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    notes text,
    status text,
    urgency character varying(255) DEFAULT 'primary'::character varying,
    hq_approved boolean DEFAULT false NOT NULL,
    blurb text
);


ALTER TABLE public.delivery_sign_ups OWNER TO uc0o9etll61111;

--
-- Name: delivery_sign_ups_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE delivery_sign_ups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_sign_ups_id_seq OWNER TO uc0o9etll61111;

--
-- Name: delivery_sign_ups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE delivery_sign_ups_id_seq OWNED BY delivery_sign_ups.id;


--
-- Name: delivery_status_updates; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE delivery_status_updates (
    id integer NOT NULL,
    delivery_id integer,
    driver_id integer,
    order_id integer,
    status_name character varying(255),
    customer_name character varying(255),
    driver_full_name character varying(255),
    driver_first_name character varying(255),
    driver_photo_url character varying(255),
    driver_possessive_pronoun character varying(255),
    driver_subjective_pronoun character varying(255),
    food_is_ready boolean,
    restaurant_name character varying(255),
    estimated_delivered_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    driver_marker_url character varying(255),
    estimated_left_at timestamp without time zone,
    estimated_en_route_to_customer_at timestamp without time zone,
    estimated_near_customer_at timestamp without time zone,
    estimated_claimed_at timestamp without time zone,
    estimated_arrived_at timestamp without time zone,
    estimated_en_route_to_restaurant_at timestamp without time zone,
    estimated_dispatched_at timestamp without time zone
);


ALTER TABLE public.delivery_status_updates OWNER TO uc0o9etll61111;

--
-- Name: delivery_status_updates_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE delivery_status_updates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_status_updates_id_seq OWNER TO uc0o9etll61111;

--
-- Name: delivery_status_updates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE delivery_status_updates_id_seq OWNED BY delivery_status_updates.id;


--
-- Name: delivery_steps; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE delivery_steps (
    id integer NOT NULL,
    delivery_id integer,
    driver_id integer,
    name character varying(255),
    completed_at timestamp without time zone,
    late_at timestamp without time zone,
    latitude numeric(9,6),
    longitude numeric(9,6),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    notified_at timestamp without time zone
);


ALTER TABLE public.delivery_steps OWNER TO uc0o9etll61111;

--
-- Name: delivery_steps_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE delivery_steps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_steps_id_seq OWNER TO uc0o9etll61111;

--
-- Name: delivery_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE delivery_steps_id_seq OWNED BY delivery_steps.id;


--
-- Name: delivery_zones; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE delivery_zones (
    id integer NOT NULL,
    area text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    name character varying(255),
    fee numeric(6,2) DEFAULT 0 NOT NULL,
    minimum numeric(6,2) DEFAULT 0 NOT NULL,
    display_order integer DEFAULT 0 NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    delivery_allowed boolean DEFAULT true NOT NULL,
    area_type integer,
    radius_miles numeric,
    area_geometry geometry(Geometry,3785),
    radius_geometry geometry(PointM,3785),
    owner_id integer,
    owner_type character varying(255)
);


ALTER TABLE public.delivery_zones OWNER TO uc0o9etll61111;

--
-- Name: delivery_zones_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE delivery_zones_id_seq
    START WITH 20000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_zones_id_seq OWNER TO uc0o9etll61111;

--
-- Name: delivery_zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE delivery_zones_id_seq OWNED BY delivery_zones.id;


--
-- Name: devices; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE devices (
    id integer NOT NULL,
    platform character varying(255) NOT NULL,
    uid character varying(255) NOT NULL,
    allowed_to_redeem boolean DEFAULT true NOT NULL,
    customer_id integer
);


ALTER TABLE public.devices OWNER TO uc0o9etll61111;

--
-- Name: devices_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE devices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.devices_id_seq OWNER TO uc0o9etll61111;

--
-- Name: devices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE devices_id_seq OWNED BY devices.id;


--
-- Name: dispatches; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE dispatches (
    id integer NOT NULL,
    driver_id integer,
    delivery_id integer,
    status character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    pex_card_funded_at timestamp without time zone
);


ALTER TABLE public.dispatches OWNER TO uc0o9etll61111;

--
-- Name: dispatches_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE dispatches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dispatches_id_seq OWNER TO uc0o9etll61111;

--
-- Name: dispatches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE dispatches_id_seq OWNED BY dispatches.id;


--
-- Name: driver_availabilities; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE driver_availabilities (
    id integer NOT NULL,
    driver_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    period_start timestamp without time zone,
    period_end timestamp without time zone,
    minimum integer DEFAULT 0 NOT NULL,
    maximum integer DEFAULT 40 NOT NULL,
    min_shift_length integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.driver_availabilities OWNER TO uc0o9etll61111;

--
-- Name: driver_availabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE driver_availabilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.driver_availabilities_id_seq OWNER TO uc0o9etll61111;

--
-- Name: driver_availabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE driver_availabilities_id_seq OWNED BY driver_availabilities.id;


--
-- Name: driver_availability_blocks; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE driver_availability_blocks (
    id integer NOT NULL,
    driver_availability_id integer,
    starts_at timestamp without time zone,
    ends_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.driver_availability_blocks OWNER TO uc0o9etll61111;

--
-- Name: driver_availability_blocks_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE driver_availability_blocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.driver_availability_blocks_id_seq OWNER TO uc0o9etll61111;

--
-- Name: driver_availability_blocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE driver_availability_blocks_id_seq OWNED BY driver_availability_blocks.id;


--
-- Name: driver_broadcasts; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE driver_broadcasts (
    id integer NOT NULL,
    message text,
    market_id integer,
    delivery_service_id integer,
    approved boolean,
    available boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.driver_broadcasts OWNER TO uc0o9etll61111;

--
-- Name: driver_broadcasts_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE driver_broadcasts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.driver_broadcasts_id_seq OWNER TO uc0o9etll61111;

--
-- Name: driver_broadcasts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE driver_broadcasts_id_seq OWNED BY driver_broadcasts.id;


--
-- Name: driver_locations; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE driver_locations (
    id integer NOT NULL,
    driver_id integer,
    latitude numeric(11,8),
    longitude numeric(11,8),
    distance numeric(10,6),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    platform character varying(255),
    hour integer,
    miles_per_hour numeric(5,2),
    update_interval integer
);


ALTER TABLE public.driver_locations OWNER TO uc0o9etll61111;

--
-- Name: driver_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE driver_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.driver_locations_id_seq OWNER TO uc0o9etll61111;

--
-- Name: driver_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE driver_locations_id_seq OWNED BY driver_locations.id;


--
-- Name: driver_messages; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE driver_messages (
    id integer NOT NULL,
    content text NOT NULL,
    driver_id integer NOT NULL,
    author_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    provider character varying(255),
    sid character varying(255),
    data json,
    read_at timestamp without time zone,
    read_by_id integer
);


ALTER TABLE public.driver_messages OWNER TO uc0o9etll61111;

--
-- Name: driver_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE driver_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.driver_messages_id_seq OWNER TO uc0o9etll61111;

--
-- Name: driver_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE driver_messages_id_seq OWNED BY driver_messages.id;


--
-- Name: driver_points; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE driver_points (
    id integer NOT NULL,
    driver_id integer NOT NULL,
    delivery_id integer,
    points integer NOT NULL,
    earned_at timestamp without time zone,
    reason character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.driver_points OWNER TO uc0o9etll61111;

--
-- Name: driver_points_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE driver_points_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.driver_points_id_seq OWNER TO uc0o9etll61111;

--
-- Name: driver_points_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE driver_points_id_seq OWNED BY driver_points.id;


--
-- Name: driver_restaurant_bans; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE driver_restaurant_bans (
    id integer NOT NULL,
    driver_id integer NOT NULL,
    restaurant_id integer NOT NULL,
    created_by integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.driver_restaurant_bans OWNER TO uc0o9etll61111;

--
-- Name: driver_restaurant_bans_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE driver_restaurant_bans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.driver_restaurant_bans_id_seq OWNER TO uc0o9etll61111;

--
-- Name: driver_restaurant_bans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE driver_restaurant_bans_id_seq OWNED BY driver_restaurant_bans.id;


--
-- Name: driver_work_hours; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE driver_work_hours (
    id integer NOT NULL,
    worked_at timestamp without time zone NOT NULL,
    scheduled boolean NOT NULL,
    number_of_deliveries double precision NOT NULL,
    earnings_from_deliveries numeric(19,4),
    guaranteed_wage numeric(19,4) NOT NULL,
    time_worked_minutes integer NOT NULL,
    earnings_from_guaranteed_wage numeric(19,4),
    distribution numeric(19,4) NOT NULL,
    driver_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    delivery_service_id integer,
    earnings numeric(19,4),
    cash_payments numeric(19,4),
    total_delivery_fees numeric(19,4),
    driver_delivery_fees numeric(19,4),
    tips numeric(19,4),
    mileage numeric(5,2),
    location_update_count integer,
    shift_assignment_id integer,
    driver_marketing_incentives numeric(19,4),
    number_of_request_deliveries numeric(19,4),
    total_dispatches integer,
    accepted_dispatches integer,
    idle_time_minutes integer,
    qualified_for_guaranteed_wage boolean,
    bonus_earnings numeric(19,4)
);


ALTER TABLE public.driver_work_hours OWNER TO uc0o9etll61111;

--
-- Name: driver_work_hours_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE driver_work_hours_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.driver_work_hours_id_seq OWNER TO uc0o9etll61111;

--
-- Name: driver_work_hours_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE driver_work_hours_id_seq OWNED BY driver_work_hours.id;


--
-- Name: drivers; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE drivers (
    id integer NOT NULL,
    customer_id integer,
    market_id integer,
    latitude numeric(11,8) DEFAULT 0 NOT NULL,
    longitude numeric(11,8) DEFAULT 0 NOT NULL,
    location_updated_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    available boolean,
    ach_routing character varying(255),
    ach_account character varying(255),
    phone character varying(255),
    "primary" boolean,
    pex_account_id character varying(255),
    born_on date,
    approved boolean NOT NULL,
    reliability_score numeric(7,6),
    email_availability_due boolean DEFAULT true NOT NULL,
    notify_for_schedule_changes boolean DEFAULT true NOT NULL,
    delivery_service_id integer,
    driver_agreement_signed boolean NOT NULL,
    background_check_completed boolean NOT NULL,
    grouping_orders integer,
    avatar_file_name character varying(255),
    avatar_content_type character varying(255),
    avatar_file_size integer,
    avatar_updated_at timestamp without time zone,
    gender integer,
    marker_url character varying(255),
    platform character varying(255),
    app_version character varying(255),
    gear_number text,
    gear_updated_at timestamp without time zone,
    deliveries_count_offset integer DEFAULT 0 NOT NULL,
    use_confirm_dialogs boolean DEFAULT true,
    default_map_app character varying(255),
    reliability_score_weekly numeric(7,6)
);


ALTER TABLE public.drivers OWNER TO uc0o9etll61111;

--
-- Name: drivers_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE drivers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.drivers_id_seq OWNER TO uc0o9etll61111;

--
-- Name: drivers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE drivers_id_seq OWNED BY drivers.id;


--
-- Name: estimation_model_feature_values; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE estimation_model_feature_values (
    id integer NOT NULL,
    estimation_model_feature_id integer,
    value numeric,
    created_at timestamp without time zone
);


ALTER TABLE public.estimation_model_feature_values OWNER TO uc0o9etll61111;

--
-- Name: estimation_model_feature_values_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE estimation_model_feature_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.estimation_model_feature_values_id_seq OWNER TO uc0o9etll61111;

--
-- Name: estimation_model_feature_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE estimation_model_feature_values_id_seq OWNED BY estimation_model_feature_values.id;


--
-- Name: estimation_model_features; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE estimation_model_features (
    id integer NOT NULL,
    delivery_service_id integer,
    estimation_model_id integer,
    name character varying(255),
    power integer,
    coefficient numeric,
    current_value numeric,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.estimation_model_features OWNER TO uc0o9etll61111;

--
-- Name: estimation_model_features_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE estimation_model_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.estimation_model_features_id_seq OWNER TO uc0o9etll61111;

--
-- Name: estimation_model_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE estimation_model_features_id_seq OWNED BY estimation_model_features.id;


--
-- Name: estimation_models; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE estimation_models (
    id integer NOT NULL,
    name character varying(255),
    version integer,
    active boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.estimation_models OWNER TO uc0o9etll61111;

--
-- Name: estimation_models_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE estimation_models_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.estimation_models_id_seq OWNER TO uc0o9etll61111;

--
-- Name: estimation_models_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE estimation_models_id_seq OWNED BY estimation_models.id;


--
-- Name: favorite_restaurants; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE favorite_restaurants (
    id integer NOT NULL,
    customer_id integer NOT NULL,
    restaurant_id integer NOT NULL
);


ALTER TABLE public.favorite_restaurants OWNER TO uc0o9etll61111;

--
-- Name: favorite_restaurants_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE favorite_restaurants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.favorite_restaurants_id_seq OWNER TO uc0o9etll61111;

--
-- Name: favorite_restaurants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE favorite_restaurants_id_seq OWNED BY favorite_restaurants.id;


--
-- Name: franchise_contacts; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE franchise_contacts (
    id integer NOT NULL,
    name character varying(255),
    email character varying(255),
    phone character varying(255),
    address1 character varying(255),
    city character varying(255),
    state character varying(255),
    zip character varying(255),
    referral_source character varying(255),
    reason_why text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.franchise_contacts OWNER TO uc0o9etll61111;

--
-- Name: franchise_contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE franchise_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.franchise_contacts_id_seq OWNER TO uc0o9etll61111;

--
-- Name: franchise_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE franchise_contacts_id_seq OWNED BY franchise_contacts.id;


--
-- Name: frequently_asked_question_categories; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE frequently_asked_question_categories (
    id integer NOT NULL,
    display_order integer,
    name character varying(255),
    show_on integer DEFAULT 0
);


ALTER TABLE public.frequently_asked_question_categories OWNER TO uc0o9etll61111;

--
-- Name: frequently_asked_question_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE frequently_asked_question_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.frequently_asked_question_categories_id_seq OWNER TO uc0o9etll61111;

--
-- Name: frequently_asked_question_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE frequently_asked_question_categories_id_seq OWNED BY frequently_asked_question_categories.id;


--
-- Name: frequently_asked_questions; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE frequently_asked_questions (
    id integer NOT NULL,
    question text,
    answer text,
    display_order integer,
    category character varying(255),
    frequently_asked_question_category_id integer
);


ALTER TABLE public.frequently_asked_questions OWNER TO uc0o9etll61111;

--
-- Name: frequently_asked_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE frequently_asked_questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.frequently_asked_questions_id_seq OWNER TO uc0o9etll61111;

--
-- Name: frequently_asked_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE frequently_asked_questions_id_seq OWNED BY frequently_asked_questions.id;


--
-- Name: gift_cards; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE gift_cards (
    id integer NOT NULL,
    credit_item_id integer,
    code character varying(255),
    amount integer,
    message text,
    delivery_method character varying(255),
    send_on date,
    sent_at timestamp without time zone,
    from_name character varying(255),
    from_email character varying(255),
    recipient_name character varying(255),
    recipient_email character varying(255),
    transaction_id character varying(255),
    voided_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    payment_id integer
);


ALTER TABLE public.gift_cards OWNER TO uc0o9etll61111;

--
-- Name: gift_cards_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE gift_cards_id_seq
    START WITH 6971
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.gift_cards_id_seq OWNER TO uc0o9etll61111;

--
-- Name: gift_cards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE gift_cards_id_seq OWNED BY gift_cards.id;


--
-- Name: hosted_sites; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE hosted_sites (
    id integer NOT NULL,
    domain_name character varying(255) NOT NULL,
    theme character varying(255) NOT NULL,
    palette character varying(255) NOT NULL,
    restaurant_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    icons text,
    registration_status character varying(255),
    auto_renew boolean DEFAULT true NOT NULL
);


ALTER TABLE public.hosted_sites OWNER TO uc0o9etll61111;

--
-- Name: hosted_sites_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE hosted_sites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.hosted_sites_id_seq OWNER TO uc0o9etll61111;

--
-- Name: hosted_sites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE hosted_sites_id_seq OWNED BY hosted_sites.id;


--
-- Name: jobs; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE jobs (
    id integer NOT NULL,
    external_job_id character varying(255),
    board_code character varying(255),
    title character varying(255),
    city character varying(255),
    state character varying(255),
    zip character varying(255),
    department character varying(255),
    job_type character varying(255),
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.jobs OWNER TO uc0o9etll61111;

--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.jobs_id_seq OWNER TO uc0o9etll61111;

--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE jobs_id_seq OWNED BY jobs.id;


--
-- Name: loyalty_cash_transactions; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE loyalty_cash_transactions (
    id integer NOT NULL,
    customer_id integer NOT NULL,
    restaurant_id integer NOT NULL,
    order_id integer,
    amount numeric(8,2),
    reason character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.loyalty_cash_transactions OWNER TO uc0o9etll61111;

--
-- Name: loyalty_cash_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE loyalty_cash_transactions_id_seq
    START WITH 10000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.loyalty_cash_transactions_id_seq OWNER TO uc0o9etll61111;

--
-- Name: loyalty_cash_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE loyalty_cash_transactions_id_seq OWNED BY loyalty_cash_transactions.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE orders (
    id integer NOT NULL,
    details json NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    restaurant_id integer NOT NULL,
    payment_type character varying(255) NOT NULL,
    status character varying(255) NOT NULL,
    source character varying(255) NOT NULL,
    test boolean DEFAULT false NOT NULL,
    customer_id integer,
    payment_details json,
    delivery_address json,
    special_instructions text,
    food_receipt_type character varying(255) NOT NULL,
    credit_card_processing numeric(19,6) NOT NULL,
    commission numeric(19,6) NOT NULL,
    order_up_distribution numeric(19,6) NOT NULL,
    market_distribution numeric(19,6) NOT NULL,
    restaurant_distribution numeric(19,6) NOT NULL,
    subtotal numeric(19,2) NOT NULL,
    loyalty_cash numeric(19,2) NOT NULL,
    sales_tax numeric(19,2) NOT NULL,
    delivery_fee numeric(19,2) NOT NULL,
    tip numeric(19,2) NOT NULL,
    processing_fee numeric(19,2) NOT NULL,
    total numeric(19,2) NOT NULL,
    chargeable_sale numeric(19,2) NOT NULL,
    prepaid_total numeric(19,2) NOT NULL,
    fax_notification_status character varying(255),
    email_notification_status character varying(255),
    phone_notification_status character varying(255),
    commission_collected numeric(19,6) NOT NULL,
    import_version integer,
    top_products json,
    commission_percentage numeric(19,6),
    commission_flat numeric(19,2),
    platform character varying(255) DEFAULT 'desktop'::character varying NOT NULL,
    customer_order_number integer DEFAULT 1 NOT NULL,
    credit_card_id integer,
    updated_by character varying(255),
    updated_reason text,
    first_name character varying(255),
    last_name character varying(255),
    phone character varying(255),
    orderup_delivered boolean,
    driver_distribution numeric(19,6),
    order_up_delivery_distribution numeric(19,6),
    affiliate_id integer,
    affiliate_commission numeric(19,6),
    affiliate_commission_from_restaurant numeric(19,6),
    market_delivery_distribution numeric(19,6),
    payment_required_on_pickup boolean,
    cart_id integer,
    credit_used numeric(19,2) DEFAULT 0,
    estimated_ready_at timestamp without time zone,
    has_drinks boolean,
    manual boolean,
    delivery_service_id integer,
    rel character varying(255),
    customer_feedback_url character varying(255),
    customer_feedback json,
    ip_address character varying(255),
    override_ready_at timestamp without time zone,
    requested_delivery_fee numeric(19,2),
    fulfilled_at timestamp without time zone NOT NULL,
    deliver_at timestamp without time zone,
    for_later_invalid boolean,
    for_later_invalid_reason character varying(255),
    excess_restaurant_sales_tax_on_delivery_fee numeric(19,2),
    related_order_id integer,
    restaurant_delivery_fee numeric(19,2),
    market_delivery_fee numeric(19,2),
    eatabit_notification_status character varying(255)
);


ALTER TABLE public.orders OWNER TO uc0o9etll61111;

--
-- Name: restaurants; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE restaurants (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    market_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    time_zone character varying(255) NOT NULL,
    commission_percentage numeric(19,4),
    commission_flat numeric(19,2),
    address_1 character varying(255),
    address_2 character varying(255),
    city character varying(255),
    state character varying(255),
    zip_code character varying(255),
    phone character varying(255),
    fax_1 character varying(255),
    fax_2 character varying(255),
    notification_phone character varying(255),
    notified_by_fax_1 boolean DEFAULT false NOT NULL,
    notified_by_fax_2 boolean DEFAULT false NOT NULL,
    notified_by_email boolean DEFAULT false NOT NULL,
    notified_by_phone boolean DEFAULT false NOT NULL,
    import_version integer,
    owner_email character varying(255),
    notification_email character varying(255)[] DEFAULT '{}'::character varying[] NOT NULL,
    delivery boolean DEFAULT false NOT NULL,
    takeout boolean DEFAULT false NOT NULL,
    top_products json DEFAULT '[]'::json NOT NULL,
    slug character varying(255),
    twitter_handle character varying(255),
    facebook_username character varying(255),
    delivery_service character varying(255),
    yelp_id character varying(255),
    promotional_message text,
    status integer,
    primary_color character varying(255),
    secondary_color character varying(255),
    processing_type integer,
    processing_fee numeric(4,2),
    sales_tax numeric(6,4),
    owner_name character varying(255),
    owner_emergency_contact character varying(255),
    loyalty_cash_minimum numeric(5,2),
    loyalty_cash_accrual_rate numeric(9,6),
    notification_includes_receipt boolean,
    accepts_cash boolean,
    credit_card_types_accepted integer DEFAULT 0 NOT NULL,
    accepts_site_wide_coupons boolean DEFAULT true NOT NULL,
    logo_content_type character varying(255),
    logo_file_size integer,
    logo_updated_at timestamp without time zone,
    logo_fingerprint character varying(255),
    logo_file_name character varying(255),
    delivery_service_id integer,
    average_orders_per_day integer DEFAULT 0 NOT NULL,
    processing_fee_rebate_percentage numeric(19,2),
    exposure integer,
    yelp_rating numeric(2,1),
    yelp_rating_img_url character varying(255),
    yelp_rating_img_url_small character varying(255),
    yelp_review_count integer,
    yelp_url character varying(255),
    yelp_cached_at timestamp without time zone,
    has_drinks_key_words text,
    cached_daily_order_counts_list character varying(255),
    delivery_instructions text,
    payment_required_on_pickup boolean,
    change_count integer DEFAULT 0 NOT NULL,
    hours_change_count integer DEFAULT 0 NOT NULL,
    latitude numeric(9,6) DEFAULT 0,
    longitude numeric(9,6) DEFAULT 0,
    menu_image_url character varying(8000),
    average_make_time integer,
    override_make_time integer,
    order_called_in boolean,
    delivery_fee_taxable character varying(255) DEFAULT 'default'::character varying,
    request_delivery boolean DEFAULT false NOT NULL,
    override_delivery_fee numeric(19,2),
    override_delivery_minimum numeric(19,2),
    notified_by_email_confirm boolean,
    request_delivery_flat_fee numeric(19,2) DEFAULT 0 NOT NULL,
    slow_make_time boolean DEFAULT false NOT NULL,
    large_order_threshold integer,
    minutes_to_increase_ready_time_of_large_orders integer,
    order_for_later_accepted boolean,
    order_for_later_max_days_ahead integer,
    order_for_later_min_minutes_from_open integer,
    order_for_later_max_orders_per_time_slot integer,
    commission_percentage_on_type_1_delivery numeric(19,6),
    commission_flat_on_type_1_delivery numeric(19,2),
    processing_fee_rebate_percentage_on_type_1_delivery numeric(19,6),
    commission_percentage_on_type_2_delivery numeric(19,6),
    commission_flat_on_type_2_delivery numeric(19,2),
    processing_fee_rebate_percentage_on_type_2_delivery numeric(19,6),
    commission_percentage_on_takeout numeric(19,6),
    commission_flat_on_takeout numeric(19,2),
    processing_fee_rebate_percentage_on_takeout numeric(19,6),
    map_image_file_name character varying(255),
    map_image_content_type character varying(255),
    map_image_file_size integer,
    map_image_updated_at timestamp without time zone,
    map_image_fingerprint character varying(255),
    estimated_delivery_time_minutes integer DEFAULT 0,
    delivery_info character varying(255),
    delivery_subsidy numeric(19,2) DEFAULT 0 NOT NULL,
    market_delivery_subsidy numeric(19,2) DEFAULT 0 NOT NULL,
    eatabit_printer_id character varying(255),
    notified_by_eatabit boolean,
    published_at timestamp without time zone,
    activated_at timestamp without time zone,
    published_by character varying(255),
    canonical_hours_data json,
    pex_account_id character varying(255),
    pex_payment_only boolean,
    ach_addenda character varying(255),
    nora_participant boolean DEFAULT false,
    ranking integer
);


ALTER TABLE public.restaurants OWNER TO uc0o9etll61111;

--
-- Name: make_times; Type: VIEW; Schema: public; Owner: uc0o9etll61111
--

CREATE VIEW make_times AS
 SELECT restaurants.market_id,
    orders.restaurant_id,
    orders.id AS order_id,
    deliveries.id AS delivery_id,
    timezone((restaurants.time_zone)::text, timezone('utc'::text, orders.created_at)) AS "time",
    orders.subtotal,
    (deliveries.left_at - orders.created_at) AS make_time
   FROM ((orders
     JOIN deliveries ON ((deliveries.order_id = orders.id)))
     JOIN restaurants ON ((restaurants.id = orders.restaurant_id)))
  WHERE ((((deliveries.left_at - orders.created_at) IS NOT NULL) AND (deliveries.order_status_on_arrival = 2)) AND (NOT orders.test));


ALTER TABLE public.make_times OWNER TO uc0o9etll61111;

--
-- Name: market_campus_payment_cards; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE market_campus_payment_cards (
    id integer NOT NULL,
    market_id integer NOT NULL,
    campus_payment_card_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.market_campus_payment_cards OWNER TO uc0o9etll61111;

--
-- Name: market_campus_payment_cards_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE market_campus_payment_cards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.market_campus_payment_cards_id_seq OWNER TO uc0o9etll61111;

--
-- Name: market_campus_payment_cards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE market_campus_payment_cards_id_seq OWNED BY market_campus_payment_cards.id;


--
-- Name: market_cities; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE market_cities (
    id integer NOT NULL,
    market_id integer NOT NULL,
    name character varying(255) NOT NULL,
    state character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.market_cities OWNER TO uc0o9etll61111;

--
-- Name: market_cities_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE market_cities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.market_cities_id_seq OWNER TO uc0o9etll61111;

--
-- Name: market_cities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE market_cities_id_seq OWNED BY market_cities.id;


--
-- Name: market_dispatch_notes; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE market_dispatch_notes (
    id integer NOT NULL,
    author_id integer NOT NULL,
    market_id integer NOT NULL,
    content text NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.market_dispatch_notes OWNER TO uc0o9etll61111;

--
-- Name: market_dispatch_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE market_dispatch_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.market_dispatch_notes_id_seq OWNER TO uc0o9etll61111;

--
-- Name: market_dispatch_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE market_dispatch_notes_id_seq OWNED BY market_dispatch_notes.id;


--
-- Name: market_scorecards; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE market_scorecards (
    id integer NOT NULL,
    scorecard_id integer NOT NULL,
    market_id integer,
    active_restaurants numeric,
    active_restaurants_goal numeric,
    new_bucket_list_restaurants numeric,
    new_bucket_list_restaurants_goal numeric,
    new_products numeric,
    new_products_goal numeric,
    new_users numeric,
    new_users_goal numeric,
    monthly_active_users numeric,
    monthly_active_users_goal numeric,
    monthly_orders_over_monthly_active_users numeric,
    monthly_orders_over_monthly_active_users_goal numeric,
    days_to_reorder numeric,
    days_to_reorder_goal numeric,
    incentivized_orders_percentage numeric,
    incentivized_orders_percentage_goal numeric,
    retention_percentage numeric,
    retention_percentage_goal numeric,
    persistence_percentage numeric,
    persistence_percentage_goal numeric,
    percent_deliveries_below_expected numeric,
    percent_deliveries_below_expected_goal numeric,
    driver_hourly_rate numeric,
    driver_hourly_rate_goal numeric,
    orders_per_driver_hour numeric,
    orders_per_driver_hour_goal numeric,
    coverage_per_order numeric,
    coverage_per_order_goal numeric,
    incentive_per_order numeric,
    incentive_per_order_goal numeric,
    shutdown_minutes numeric,
    shutdown_minutes_goal numeric,
    driver_tenure numeric,
    driver_tenure_goal numeric,
    orders_per_day numeric,
    orders_per_day_goal numeric,
    orders_per_capita numeric,
    orders_per_capita_goal numeric,
    type_two_percentage numeric,
    type_two_percentage_goal numeric,
    average_chargeable_sale numeric,
    average_chargeable_sale_goal numeric,
    revenue_per_order numeric,
    revenue_per_order_goal numeric,
    margin_per_order numeric,
    margin_per_order_goal numeric,
    ebitda numeric,
    ebitda_goal numeric,
    tickets_per_order numeric,
    tickets_per_order_goal numeric,
    response_time numeric,
    response_time_goal numeric,
    cost_per_order numeric,
    cost_per_order_goal numeric,
    total_orders numeric,
    total_repeat_customers numeric,
    total_new_customers_35_day numeric,
    total_customers_95_to_35 numeric,
    total_deliveries numeric,
    total_driver_hours numeric,
    total_drivers numeric,
    total_population numeric,
    total_ticket_count numeric,
    total_email_ticket_count numeric,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.market_scorecards OWNER TO uc0o9etll61111;

--
-- Name: market_scorecards_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE market_scorecards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.market_scorecards_id_seq OWNER TO uc0o9etll61111;

--
-- Name: market_scorecards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE market_scorecards_id_seq OWNED BY market_scorecards.id;


--
-- Name: market_weather_hours; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE market_weather_hours (
    id integer NOT NULL,
    temperature numeric,
    precipitation numeric,
    snowfall numeric,
    cloud_cover numeric,
    market_id integer NOT NULL,
    starts_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.market_weather_hours OWNER TO uc0o9etll61111;

--
-- Name: market_weather_hours_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE market_weather_hours_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.market_weather_hours_id_seq OWNER TO uc0o9etll61111;

--
-- Name: market_weather_hours_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE market_weather_hours_id_seq OWNED BY market_weather_hours.id;


--
-- Name: markets; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE markets (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    time_zone character varying(255) NOT NULL,
    market_style character varying(255) DEFAULT 'order_up'::character varying NOT NULL,
    commission_percentage numeric(19,4) DEFAULT 0 NOT NULL,
    commission_flat numeric(19,2),
    launched_at timestamp without time zone,
    domain character varying(255),
    tech_service_fee numeric(19,2) DEFAULT 0 NOT NULL,
    tech_service_fee_starts_at date,
    city character varying(255),
    state character varying(255),
    brand_color character varying(255),
    banner_color character varying(255),
    preview_mailing_list_campaign_monitor_code character varying(255),
    market_owner_name character varying(255),
    market_owner_title character varying(255),
    transition_blog_post_url character varying(255),
    forever_page_post_id character varying(255),
    facebook_url character varying(255),
    twitter_handle character varying(255),
    blog_url character varying(255),
    conversion_tracking_html text,
    alternate_discovery_view character varying(255),
    geocode_bounds text,
    enable_building_groups boolean,
    orderup_delivery boolean,
    market_owner_phone character varying(255),
    market_owner_email character varying(255),
    average_orders_per_day integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    order_copy_email character varying(255),
    market_owner_photo_file_name character varying(255),
    market_owner_photo_content_type character varying(255),
    market_owner_photo_file_size integer,
    market_owner_photo_updated_at timestamp without time zone,
    market_owner_photo_fingerprint character varying(255),
    default_sales_tax numeric(19,2),
    cached_daily_order_counts_list character varying(255),
    proximity_limit_1 numeric(4,2),
    proximity_limit_2 numeric(4,2),
    shipping_address_1 character varying(255),
    shipping_address_2 character varying(255),
    shipping_city character varying(255),
    shipping_state character varying(255),
    shipping_zip character varying(255),
    driver_commission_percentage_for_prepaid numeric(7,4) DEFAULT 0,
    driver_commission_percentage_for_driver_paid numeric(7,4) DEFAULT 0,
    market_delivery_commission_percentage_for_prepaid numeric(7,4) DEFAULT 0,
    market_delivery_commission_percentage_for_driver_paid numeric(7,4) DEFAULT 0,
    brand_logo_url character varying(255),
    slug character varying(255),
    availability_setting_range int4range DEFAULT '[1,4)'::int4range NOT NULL,
    dispatch_threshold integer,
    customer_survey_url text,
    grouping_restaurant_range double precision,
    grouping_destination_range double precision,
    grouping_ready_time_interval double precision,
    grouping_orders_per_driver integer,
    base_guaranteed_wage integer,
    driver_scheduling_enabled boolean DEFAULT false,
    delivery_fee_taxable boolean DEFAULT false,
    dispatch_late_warning_threshold integer,
    arrive_late_warning_threshold integer,
    deliver_late_warning_threshold integer,
    hourly_dispatch_rejection_off_shift_threshold integer,
    commission_percentage_on_delivery numeric(9,6),
    commission_flat_on_delivery numeric(9,2),
    background_photo_file_name character varying(255),
    background_photo_content_type character varying(255),
    background_photo_file_size integer,
    background_photo_updated_at timestamp without time zone,
    zip_code integer,
    drivers_can_call_support boolean DEFAULT true,
    receives_driver_summaries boolean,
    delivery_support_slack_channel character varying(255) DEFAULT '#driver'::character varying,
    delivery_support_slack_team character varying(255) DEFAULT 'orderup'::character varying NOT NULL,
    automatically_clock_in_drivers boolean DEFAULT false,
    automatically_copy_driver_availability_each_week boolean DEFAULT false,
    feature_referral_codes boolean DEFAULT false NOT NULL,
    prefer_full_utilization_over_grouping boolean DEFAULT false NOT NULL,
    company_owned boolean,
    mask_dispatcher_call_sign boolean DEFAULT false NOT NULL,
    referral_credit_amount integer,
    feature_redirect_to_landing_page boolean DEFAULT false NOT NULL,
    grouping_unique_restaurant_limit integer,
    dispatch_immediately_if_available_drivers boolean DEFAULT false,
    delivery_copy_sms character varying(255),
    promotional_delivery_fee numeric(19,2),
    ignore_order_notification_failure_alerts_for_type_2_restaurants boolean DEFAULT false,
    driver_ach_enabled boolean DEFAULT false,
    driver_schedule_editing_enabled boolean DEFAULT true,
    launch_date timestamp without time zone NOT NULL,
    driver_marketing_incentive numeric(19,4) DEFAULT 0.0,
    driver_commission_percentage_for_request_delivery numeric(5,2) DEFAULT 0,
    market_delivery_commission_percentage_for_request_delivery numeric(5,2) DEFAULT 0
);


ALTER TABLE public.markets OWNER TO uc0o9etll61111;

--
-- Name: markets_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE markets_id_seq
    START WITH 200
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.markets_id_seq OWNER TO uc0o9etll61111;

--
-- Name: markets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE markets_id_seq OWNED BY markets.id;


--
-- Name: maxmind_geolite_city_blocks; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE maxmind_geolite_city_blocks (
    start_ip_num bigint NOT NULL,
    end_ip_num bigint NOT NULL,
    loc_id bigint NOT NULL
);


ALTER TABLE public.maxmind_geolite_city_blocks OWNER TO uc0o9etll61111;

--
-- Name: maxmind_geolite_city_location; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE maxmind_geolite_city_location (
    loc_id bigint NOT NULL,
    country character varying(255) NOT NULL,
    region character varying(255) NOT NULL,
    city character varying(255),
    postal_code character varying(255) NOT NULL,
    latitude double precision,
    longitude double precision,
    metro_code integer,
    area_code integer
);


ALTER TABLE public.maxmind_geolite_city_location OWNER TO uc0o9etll61111;

--
-- Name: menu_categories; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE menu_categories (
    id integer NOT NULL,
    restaurant_id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    order_type character varying(255),
    display_order integer NOT NULL,
    parent_category_id integer,
    timesets json NOT NULL,
    inherit_option_groups boolean NOT NULL,
    visible boolean NOT NULL,
    available boolean NOT NULL,
    size_type character varying(255),
    fulfilled_by_delivery_service boolean NOT NULL,
    order_for_later_lead_time integer
);


ALTER TABLE public.menu_categories OWNER TO uc0o9etll61111;

--
-- Name: menu_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE menu_categories_id_seq
    START WITH 60000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_categories_id_seq OWNER TO uc0o9etll61111;

--
-- Name: menu_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE menu_categories_id_seq OWNED BY menu_categories.id;


--
-- Name: menu_category_option_group_option_prices; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE menu_category_option_group_option_prices (
    id integer NOT NULL,
    menu_category_option_group_option_id integer NOT NULL,
    option_group_option_price_id integer NOT NULL,
    whole_enabled boolean,
    half_enabled boolean,
    whole_price numeric(19,2),
    half_price numeric(19,2),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.menu_category_option_group_option_prices OWNER TO uc0o9etll61111;

--
-- Name: menu_category_option_group_option_prices_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE menu_category_option_group_option_prices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_category_option_group_option_prices_id_seq OWNER TO uc0o9etll61111;

--
-- Name: menu_category_option_group_option_prices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE menu_category_option_group_option_prices_id_seq OWNED BY menu_category_option_group_option_prices.id;


--
-- Name: menu_category_option_group_options; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE menu_category_option_group_options (
    id integer NOT NULL,
    menu_category_option_group_id integer NOT NULL,
    option_group_option_id integer NOT NULL,
    enabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.menu_category_option_group_options OWNER TO uc0o9etll61111;

--
-- Name: menu_category_option_group_options_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE menu_category_option_group_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_category_option_group_options_id_seq OWNER TO uc0o9etll61111;

--
-- Name: menu_category_option_group_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE menu_category_option_group_options_id_seq OWNED BY menu_category_option_group_options.id;


--
-- Name: menu_category_option_groups; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE menu_category_option_groups (
    id integer NOT NULL,
    menu_category_id integer NOT NULL,
    option_group_id integer NOT NULL,
    display_name character varying(255),
    half_sizes boolean,
    restriction json,
    allows_selection_repetition boolean,
    display_order integer NOT NULL,
    client_id character varying(255) NOT NULL
);


ALTER TABLE public.menu_category_option_groups OWNER TO uc0o9etll61111;

--
-- Name: menu_category_option_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE menu_category_option_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_category_option_groups_id_seq OWNER TO uc0o9etll61111;

--
-- Name: menu_category_option_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE menu_category_option_groups_id_seq OWNED BY menu_category_option_groups.id;


--
-- Name: menu_category_sizes; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE menu_category_sizes (
    id integer NOT NULL,
    menu_category_id integer NOT NULL,
    menu_size_id integer NOT NULL,
    display_order integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.menu_category_sizes OWNER TO uc0o9etll61111;

--
-- Name: menu_category_sizes_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE menu_category_sizes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_category_sizes_id_seq OWNER TO uc0o9etll61111;

--
-- Name: menu_category_sizes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE menu_category_sizes_id_seq OWNED BY menu_category_sizes.id;


--
-- Name: menu_descriptors; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE menu_descriptors (
    id integer NOT NULL,
    restaurant_id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    display_order integer NOT NULL
);


ALTER TABLE public.menu_descriptors OWNER TO uc0o9etll61111;

--
-- Name: menu_descriptors_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE menu_descriptors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_descriptors_id_seq OWNER TO uc0o9etll61111;

--
-- Name: menu_descriptors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE menu_descriptors_id_seq OWNED BY menu_descriptors.id;


--
-- Name: menu_item_descriptors; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE menu_item_descriptors (
    id integer NOT NULL,
    menu_item_id integer NOT NULL,
    menu_descriptor_id integer NOT NULL,
    display_order integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.menu_item_descriptors OWNER TO uc0o9etll61111;

--
-- Name: menu_item_descriptors_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE menu_item_descriptors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_item_descriptors_id_seq OWNER TO uc0o9etll61111;

--
-- Name: menu_item_descriptors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE menu_item_descriptors_id_seq OWNED BY menu_item_descriptors.id;


--
-- Name: menu_item_option_group_option_prices; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE menu_item_option_group_option_prices (
    id integer NOT NULL,
    menu_item_option_group_option_id integer NOT NULL,
    option_group_option_price_id integer NOT NULL,
    whole_enabled boolean,
    half_enabled boolean,
    whole_price numeric(19,2),
    half_price numeric(19,2),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.menu_item_option_group_option_prices OWNER TO uc0o9etll61111;

--
-- Name: menu_item_option_group_option_prices_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE menu_item_option_group_option_prices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_item_option_group_option_prices_id_seq OWNER TO uc0o9etll61111;

--
-- Name: menu_item_option_group_option_prices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE menu_item_option_group_option_prices_id_seq OWNED BY menu_item_option_group_option_prices.id;


--
-- Name: menu_item_option_group_options; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE menu_item_option_group_options (
    id integer NOT NULL,
    menu_item_option_group_id integer NOT NULL,
    option_group_option_id integer NOT NULL,
    enabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.menu_item_option_group_options OWNER TO uc0o9etll61111;

--
-- Name: menu_item_option_group_options_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE menu_item_option_group_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_item_option_group_options_id_seq OWNER TO uc0o9etll61111;

--
-- Name: menu_item_option_group_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE menu_item_option_group_options_id_seq OWNED BY menu_item_option_group_options.id;


--
-- Name: menu_item_option_groups; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE menu_item_option_groups (
    id integer NOT NULL,
    menu_item_id integer NOT NULL,
    option_group_id integer NOT NULL,
    display_name character varying(255),
    half_sizes boolean,
    restriction json,
    allows_selection_repetition boolean,
    display_order integer NOT NULL,
    client_id character varying(255) NOT NULL
);


ALTER TABLE public.menu_item_option_groups OWNER TO uc0o9etll61111;

--
-- Name: menu_item_option_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE menu_item_option_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_item_option_groups_id_seq OWNER TO uc0o9etll61111;

--
-- Name: menu_item_option_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE menu_item_option_groups_id_seq OWNED BY menu_item_option_groups.id;


--
-- Name: menu_item_sizes; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE menu_item_sizes (
    id integer NOT NULL,
    menu_item_id integer NOT NULL,
    price numeric(6,2),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    enabled boolean NOT NULL,
    menu_size_id integer NOT NULL,
    restaurant_price numeric
);


ALTER TABLE public.menu_item_sizes OWNER TO uc0o9etll61111;

--
-- Name: menu_item_sizes_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE menu_item_sizes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_item_sizes_id_seq OWNER TO uc0o9etll61111;

--
-- Name: menu_item_sizes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE menu_item_sizes_id_seq OWNED BY menu_item_sizes.id;


--
-- Name: menu_items; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE menu_items (
    id integer NOT NULL,
    category_id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    order_type character varying(255),
    inherit_option_groups boolean NOT NULL,
    display_order integer NOT NULL,
    taxable boolean,
    timesets json NOT NULL,
    visible boolean NOT NULL,
    available boolean NOT NULL,
    per_account_order_limit integer,
    per_order_limit integer,
    discountable boolean DEFAULT true NOT NULL,
    sales_tax numeric(19,2),
    special boolean DEFAULT false NOT NULL,
    upsell boolean DEFAULT false NOT NULL,
    coupon_only boolean NOT NULL,
    combinable boolean NOT NULL,
    order_for_later_lead_time integer
);


ALTER TABLE public.menu_items OWNER TO uc0o9etll61111;

--
-- Name: menu_items_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE menu_items_id_seq
    START WITH 600000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_items_id_seq OWNER TO uc0o9etll61111;

--
-- Name: menu_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE menu_items_id_seq OWNED BY menu_items.id;


--
-- Name: menu_options; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE menu_options (
    id integer NOT NULL,
    restaurant_id integer,
    name character varying(255),
    available boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.menu_options OWNER TO uc0o9etll61111;

--
-- Name: menu_options_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE menu_options_id_seq
    START WITH 500000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_options_id_seq OWNER TO uc0o9etll61111;

--
-- Name: menu_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE menu_options_id_seq OWNED BY menu_options.id;


--
-- Name: menu_sizes; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE menu_sizes (
    id integer NOT NULL,
    restaurant_id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    display_order integer NOT NULL
);


ALTER TABLE public.menu_sizes OWNER TO uc0o9etll61111;

--
-- Name: menu_sizes_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE menu_sizes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_sizes_id_seq OWNER TO uc0o9etll61111;

--
-- Name: menu_sizes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE menu_sizes_id_seq OWNED BY menu_sizes.id;


--
-- Name: menu_updates; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE menu_updates (
    id integer NOT NULL,
    restaurant_id integer NOT NULL,
    data json NOT NULL,
    change_count integer NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.menu_updates OWNER TO uc0o9etll61111;

--
-- Name: menu_updates_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE menu_updates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menu_updates_id_seq OWNER TO uc0o9etll61111;

--
-- Name: menu_updates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE menu_updates_id_seq OWNED BY menu_updates.id;


--
-- Name: monthly_order_counts; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE monthly_order_counts (
    id integer NOT NULL,
    market_id integer NOT NULL,
    year integer NOT NULL,
    month integer NOT NULL,
    orders integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.monthly_order_counts OWNER TO uc0o9etll61111;

--
-- Name: monthly_order_counts_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE monthly_order_counts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.monthly_order_counts_id_seq OWNER TO uc0o9etll61111;

--
-- Name: monthly_order_counts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE monthly_order_counts_id_seq OWNED BY monthly_order_counts.id;


--
-- Name: newbie_codes; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE newbie_codes (
    id integer NOT NULL,
    market_id integer NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255) NOT NULL,
    event_date timestamp without time zone NOT NULL,
    event_expires timestamp without time zone NOT NULL,
    credit_amount numeric(19,2) DEFAULT 0 NOT NULL,
    credit_expires_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    days_to_redeem_credit integer,
    use_days_to_redeem_credit_for_new_credit_items boolean DEFAULT false
);


ALTER TABLE public.newbie_codes OWNER TO uc0o9etll61111;

--
-- Name: newbie_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE newbie_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.newbie_codes_id_seq OWNER TO uc0o9etll61111;

--
-- Name: newbie_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE newbie_codes_id_seq OWNED BY newbie_codes.id;


--
-- Name: notification_schedule_changes; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE notification_schedule_changes (
    id integer NOT NULL,
    driver_id integer,
    performed_by_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.notification_schedule_changes OWNER TO uc0o9etll61111;

--
-- Name: notification_schedule_changes_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE notification_schedule_changes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notification_schedule_changes_id_seq OWNER TO uc0o9etll61111;

--
-- Name: notification_schedule_changes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE notification_schedule_changes_id_seq OWNED BY notification_schedule_changes.id;


--
-- Name: option_group_option_prices; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE option_group_option_prices (
    id integer NOT NULL,
    option_group_option_id integer NOT NULL,
    menu_size_id integer NOT NULL,
    whole_enabled boolean NOT NULL,
    half_enabled boolean NOT NULL,
    whole_price numeric(19,2),
    half_price numeric(19,2),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.option_group_option_prices OWNER TO uc0o9etll61111;

--
-- Name: option_group_option_prices_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE option_group_option_prices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.option_group_option_prices_id_seq OWNER TO uc0o9etll61111;

--
-- Name: option_group_option_prices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE option_group_option_prices_id_seq OWNED BY option_group_option_prices.id;


--
-- Name: option_group_options; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE option_group_options (
    id integer NOT NULL,
    option_group_id integer NOT NULL,
    name character varying(255) NOT NULL,
    enabled boolean NOT NULL,
    display_order integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    available boolean NOT NULL
);


ALTER TABLE public.option_group_options OWNER TO uc0o9etll61111;

--
-- Name: option_group_options_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE option_group_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.option_group_options_id_seq OWNER TO uc0o9etll61111;

--
-- Name: option_group_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE option_group_options_id_seq OWNED BY option_group_options.id;


--
-- Name: option_groups; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE option_groups (
    id integer NOT NULL,
    restaurant_id integer NOT NULL,
    name character varying(255) NOT NULL,
    display_name text,
    restriction json NOT NULL,
    half_sizes boolean NOT NULL,
    allows_selection_repetition boolean NOT NULL,
    display_order integer NOT NULL
);


ALTER TABLE public.option_groups OWNER TO uc0o9etll61111;

--
-- Name: option_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE option_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.option_groups_id_seq OWNER TO uc0o9etll61111;

--
-- Name: option_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE option_groups_id_seq OWNED BY option_groups.id;


--
-- Name: order_coupons; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE order_coupons (
    id integer NOT NULL,
    order_id integer,
    order_item_id integer,
    customer_id integer,
    coupon_id integer,
    discount_applied numeric(6,2),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.order_coupons OWNER TO uc0o9etll61111;

--
-- Name: order_coupons_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE order_coupons_id_seq
    START WITH 175000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.order_coupons_id_seq OWNER TO uc0o9etll61111;

--
-- Name: order_coupons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE order_coupons_id_seq OWNED BY order_coupons.id;


--
-- Name: order_notifications; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE order_notifications (
    id integer NOT NULL,
    type character varying(255),
    order_id integer,
    reason character varying(255),
    status character varying(255),
    provider character varying(255),
    provider_id character varying(255),
    provider_status character varying(255),
    provider_message text,
    provider_data json,
    recipient character varying(255),
    recipient_type character varying(255),
    template character varying(255),
    memo character varying(255),
    created_by character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    confirmation_token character varying(255)
);


ALTER TABLE public.order_notifications OWNER TO uc0o9etll61111;

--
-- Name: order_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE order_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.order_notifications_id_seq OWNER TO uc0o9etll61111;

--
-- Name: order_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE order_notifications_id_seq OWNED BY order_notifications.id;


--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE orders_id_seq
    START WITH 20000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.orders_id_seq OWNER TO uc0o9etll61111;

--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE orders_id_seq OWNED BY orders.id;


--
-- Name: orders_payments; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE orders_payments (
    order_id integer,
    payment_id integer
);


ALTER TABLE public.orders_payments OWNER TO uc0o9etll61111;

--
-- Name: pay_period_account_entries; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE pay_period_account_entries (
    id integer NOT NULL,
    account_owner_id integer NOT NULL,
    period_started_at timestamp without time zone NOT NULL,
    period_ended_at timestamp without time zone NOT NULL,
    amount numeric(19,6) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    account_owner_type character varying(255)
);


ALTER TABLE public.pay_period_account_entries OWNER TO uc0o9etll61111;

--
-- Name: pay_period_account_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE pay_period_account_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pay_period_account_entries_id_seq OWNER TO uc0o9etll61111;

--
-- Name: pay_period_account_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE pay_period_account_entries_id_seq OWNED BY pay_period_account_entries.id;


--
-- Name: payments; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE payments (
    id integer NOT NULL,
    payment_type character varying(255),
    description character varying(255),
    processor character varying(255),
    processor_transaction_id character varying(255),
    loyalty_cash_transaction_id integer,
    credit_item_id integer,
    credit_card_id integer,
    customer_campus_card_id integer,
    status character varying(255),
    amount numeric(19,2),
    settle_at timestamp without time zone,
    submitted_for_settlement_at timestamp without time zone,
    settled_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    order_id integer,
    gift_card_id integer
);


ALTER TABLE public.payments OWNER TO uc0o9etll61111;

--
-- Name: payments_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.payments_id_seq OWNER TO uc0o9etll61111;

--
-- Name: payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE payments_id_seq OWNED BY payments.id;


--
-- Name: pex_transactions; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE pex_transactions (
    id integer NOT NULL,
    order_id integer,
    transaction_id character varying(255),
    pex_account_id character varying(255),
    card_number character varying(255),
    spend_category character varying(255),
    description character varying(255),
    amount numeric(19,2),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.pex_transactions OWNER TO uc0o9etll61111;

--
-- Name: pex_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE pex_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pex_transactions_id_seq OWNER TO uc0o9etll61111;

--
-- Name: pex_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE pex_transactions_id_seq OWNED BY pex_transactions.id;


--
-- Name: print_menus; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE print_menus (
    id integer NOT NULL,
    restaurant_id integer,
    display_order integer,
    image_file_name character varying(255),
    image_content_type character varying(255),
    image_file_size integer,
    image_updated_at timestamp without time zone,
    image_fingerprint character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.print_menus OWNER TO uc0o9etll61111;

--
-- Name: print_menus_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE print_menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.print_menus_id_seq OWNER TO uc0o9etll61111;

--
-- Name: print_menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE print_menus_id_seq OWNED BY print_menus.id;


--
-- Name: promo_codes; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE promo_codes (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    promotable_type character varying(255) NOT NULL,
    promotable_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.promo_codes OWNER TO uc0o9etll61111;

--
-- Name: promo_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE promo_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.promo_codes_id_seq OWNER TO uc0o9etll61111;

--
-- Name: promo_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE promo_codes_id_seq OWNED BY promo_codes.id;


--
-- Name: receipts; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE receipts (
    id integer NOT NULL,
    order_id integer NOT NULL,
    image_path character varying(255) NOT NULL,
    settled_at timestamp without time zone,
    disputed_at timestamp without time zone,
    uploaded_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.receipts OWNER TO uc0o9etll61111;

--
-- Name: receipts_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE receipts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.receipts_id_seq OWNER TO uc0o9etll61111;

--
-- Name: receipts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE receipts_id_seq OWNED BY receipts.id;


--
-- Name: referral_codes; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE referral_codes (
    id integer NOT NULL,
    customer_id integer,
    market_id integer,
    code character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.referral_codes OWNER TO uc0o9etll61111;

--
-- Name: referral_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE referral_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.referral_codes_id_seq OWNER TO uc0o9etll61111;

--
-- Name: referral_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE referral_codes_id_seq OWNED BY referral_codes.id;


--
-- Name: referrals; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE referrals (
    id integer NOT NULL,
    inviter_id integer NOT NULL,
    invitee_id integer NOT NULL,
    ip_address character varying(255),
    fingerprint character varying(255),
    order_id integer,
    phone character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    device_id character varying(255),
    amount numeric(19,2)
);


ALTER TABLE public.referrals OWNER TO uc0o9etll61111;

--
-- Name: referrals_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE referrals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.referrals_id_seq OWNER TO uc0o9etll61111;

--
-- Name: referrals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE referrals_id_seq OWNED BY referrals.id;


--
-- Name: reliability_score_events; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE reliability_score_events (
    id integer NOT NULL,
    shift_assignment_id integer NOT NULL,
    event_type character varying(255) NOT NULL,
    score numeric(7,6) NOT NULL,
    message character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    customer_id integer
);


ALTER TABLE public.reliability_score_events OWNER TO uc0o9etll61111;

--
-- Name: reliability_score_events_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE reliability_score_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.reliability_score_events_id_seq OWNER TO uc0o9etll61111;

--
-- Name: reliability_score_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE reliability_score_events_id_seq OWNED BY reliability_score_events.id;


--
-- Name: restaurant_campus_payment_cards; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE restaurant_campus_payment_cards (
    id integer NOT NULL,
    restaurant_id integer,
    campus_payment_card_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.restaurant_campus_payment_cards OWNER TO uc0o9etll61111;

--
-- Name: restaurant_campus_payment_cards_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE restaurant_campus_payment_cards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.restaurant_campus_payment_cards_id_seq OWNER TO uc0o9etll61111;

--
-- Name: restaurant_campus_payment_cards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE restaurant_campus_payment_cards_id_seq OWNED BY restaurant_campus_payment_cards.id;


--
-- Name: restaurant_categories; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE restaurant_categories (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255),
    slug character varying(255) NOT NULL,
    visible boolean DEFAULT true NOT NULL
);


ALTER TABLE public.restaurant_categories OWNER TO uc0o9etll61111;

--
-- Name: restaurant_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE restaurant_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.restaurant_categories_id_seq OWNER TO uc0o9etll61111;

--
-- Name: restaurant_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE restaurant_categories_id_seq OWNED BY restaurant_categories.id;


--
-- Name: restaurant_categorizations; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE restaurant_categorizations (
    id integer NOT NULL,
    restaurant_id integer NOT NULL,
    restaurant_category_id integer NOT NULL
);


ALTER TABLE public.restaurant_categorizations OWNER TO uc0o9etll61111;

--
-- Name: restaurant_categorizations_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE restaurant_categorizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.restaurant_categorizations_id_seq OWNER TO uc0o9etll61111;

--
-- Name: restaurant_categorizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE restaurant_categorizations_id_seq OWNED BY restaurant_categorizations.id;


--
-- Name: restaurant_contacts; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE restaurant_contacts (
    id integer NOT NULL,
    market_id integer,
    name character varying(255),
    restaurant_name character varying(255),
    email character varying(255),
    phone character varying(255),
    other_market_name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.restaurant_contacts OWNER TO uc0o9etll61111;

--
-- Name: restaurant_contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE restaurant_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.restaurant_contacts_id_seq OWNER TO uc0o9etll61111;

--
-- Name: restaurant_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE restaurant_contacts_id_seq OWNED BY restaurant_contacts.id;


--
-- Name: restaurant_delivery_zones; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE restaurant_delivery_zones (
    id integer NOT NULL,
    restaurant_id integer,
    points polygon,
    fee numeric,
    minimum numeric,
    display_order integer,
    delivery_allowed boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.restaurant_delivery_zones OWNER TO uc0o9etll61111;

--
-- Name: restaurant_delivery_zones_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE restaurant_delivery_zones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.restaurant_delivery_zones_id_seq OWNER TO uc0o9etll61111;

--
-- Name: restaurant_delivery_zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE restaurant_delivery_zones_id_seq OWNED BY restaurant_delivery_zones.id;


--
-- Name: restaurant_drive_times; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE restaurant_drive_times (
    id integer NOT NULL,
    restaurant_id integer,
    beacon_id integer,
    drive_time_seconds integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.restaurant_drive_times OWNER TO uc0o9etll61111;

--
-- Name: restaurant_drive_times_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE restaurant_drive_times_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.restaurant_drive_times_id_seq OWNER TO uc0o9etll61111;

--
-- Name: restaurant_drive_times_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE restaurant_drive_times_id_seq OWNED BY restaurant_drive_times.id;


--
-- Name: restaurant_hours; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE restaurant_hours (
    id integer NOT NULL,
    restaurant_id integer,
    restaurant_temporary_hour_id integer,
    order_type character varying(255) NOT NULL,
    day_of_week integer NOT NULL,
    start_time character varying(255),
    end_time character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    hours_owner_id integer NOT NULL,
    hours_owner_type character varying(255) NOT NULL,
    temporary_hour_id integer
);


ALTER TABLE public.restaurant_hours OWNER TO uc0o9etll61111;

--
-- Name: restaurant_hours_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE restaurant_hours_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.restaurant_hours_id_seq OWNER TO uc0o9etll61111;

--
-- Name: restaurant_hours_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE restaurant_hours_id_seq OWNED BY restaurant_hours.id;


--
-- Name: restaurant_requests; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE restaurant_requests (
    id integer NOT NULL,
    restaurant text,
    market_id integer,
    customer_id integer,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.restaurant_requests OWNER TO uc0o9etll61111;

--
-- Name: restaurant_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE restaurant_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.restaurant_requests_id_seq OWNER TO uc0o9etll61111;

--
-- Name: restaurant_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE restaurant_requests_id_seq OWNED BY restaurant_requests.id;


--
-- Name: restaurant_temporary_hours; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE restaurant_temporary_hours (
    id integer NOT NULL,
    restaurant_id integer,
    order_type character varying(255),
    description text,
    starts_at timestamp without time zone,
    ends_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    hours_owner_id integer,
    hours_owner_type character varying(255)
);


ALTER TABLE public.restaurant_temporary_hours OWNER TO uc0o9etll61111;

--
-- Name: restaurant_temporary_hours_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE restaurant_temporary_hours_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.restaurant_temporary_hours_id_seq OWNER TO uc0o9etll61111;

--
-- Name: restaurant_temporary_hours_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE restaurant_temporary_hours_id_seq OWNED BY restaurant_temporary_hours.id;


--
-- Name: restaurant_types; Type: VIEW; Schema: public; Owner: uc0o9etll61111
--

CREATE VIEW restaurant_types AS
 SELECT restaurants.id AS restaurant_id,
        CASE
            WHEN (delivery_services.orderup_delivered = true) THEN 'O'::text
            ELSE 'R'::text
        END AS delivery_type,
        CASE
            WHEN (delivery_services.delivery_support_enabled = true) THEN 'S'::text
            ELSE 'N'::text
        END AS hq_supported_delivery_type,
        CASE
            WHEN (restaurants.order_called_in = true) THEN 'C'::text
            WHEN ((((restaurants.notified_by_phone OR restaurants.notified_by_fax_1) OR restaurants.notified_by_fax_2) OR restaurants.notified_by_email) OR restaurants.notified_by_eatabit) THEN 'E'::text
            WHEN (restaurants.payment_required_on_pickup = true) THEN 'D'::text
            ELSE '?'::text
        END AS restaurant_notification_method_type,
        CASE
            WHEN (restaurants.pex_payment_only = true) THEN 'X'::text
            WHEN (restaurants.payment_required_on_pickup = true) THEN 'P'::text
            WHEN (restaurants.processing_type = 1) THEN 'A'::text
            ELSE '?'::text
        END AS order_payment_method_type
   FROM (restaurants
     LEFT JOIN delivery_services ON ((restaurants.delivery_service_id = delivery_services.id)));


ALTER TABLE public.restaurant_types OWNER TO uc0o9etll61111;

--
-- Name: restaurant_users; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE restaurant_users (
    id integer NOT NULL,
    restaurant_id integer,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.restaurant_users OWNER TO uc0o9etll61111;

--
-- Name: restaurant_users_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE restaurant_users_id_seq
    START WITH 5000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.restaurant_users_id_seq OWNER TO uc0o9etll61111;

--
-- Name: restaurant_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE restaurant_users_id_seq OWNED BY restaurant_users.id;


--
-- Name: restaurants_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE restaurants_id_seq
    START WITH 50000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.restaurants_id_seq OWNER TO uc0o9etll61111;

--
-- Name: restaurants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE restaurants_id_seq OWNED BY restaurants.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO uc0o9etll61111;

--
-- Name: scorecards; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE scorecards (
    id integer NOT NULL,
    starts_at timestamp without time zone NOT NULL,
    ends_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    qa_score numeric,
    qa_score_goal numeric,
    cost_per_order numeric,
    cost_per_order_goal numeric,
    criticals_and_highs_opened numeric,
    criticals_and_highs_opened_goal numeric,
    criticals_and_highs_closed numeric,
    criticals_and_highs_closed_goal numeric,
    velocity numeric,
    velocity_goal numeric,
    downtime_minutes numeric,
    downtime_minutes_goal numeric
);


ALTER TABLE public.scorecards OWNER TO uc0o9etll61111;

--
-- Name: scorecards_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE scorecards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scorecards_id_seq OWNER TO uc0o9etll61111;

--
-- Name: scorecards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE scorecards_id_seq OWNED BY scorecards.id;


--
-- Name: serialized_menu_sizes; Type: VIEW; Schema: public; Owner: uc0o9etll61111
--

CREATE VIEW serialized_menu_sizes AS
 SELECT sizes.id,
    sizes.restaurant_id AS menu_id,
    sizes.display_order,
    row_to_json(x.*) AS json
   FROM menu_sizes sizes,
    LATERAL ( SELECT sizes.id,
            sizes.name) x;


ALTER TABLE public.serialized_menu_sizes OWNER TO uc0o9etll61111;

--
-- Name: serialized_category_option_group_option_prices; Type: VIEW; Schema: public; Owner: uc0o9etll61111
--

CREATE VIEW serialized_category_option_group_option_prices AS
 SELECT category_option_group_option_prices.menu_category_option_group_option_id AS category_option_group_option_id,
    row_to_json(x.*) AS json
   FROM ((menu_category_option_group_option_prices category_option_group_option_prices
     JOIN option_group_option_prices ON ((option_group_option_prices.id = category_option_group_option_prices.option_group_option_price_id)))
     JOIN serialized_menu_sizes ON ((serialized_menu_sizes.id = option_group_option_prices.menu_size_id))),
    LATERAL ( SELECT category_option_group_option_prices.half_enabled AS enabled,
            round((category_option_group_option_prices.half_price * (100)::numeric)) AS price_cents) half,
    LATERAL ( SELECT category_option_group_option_prices.whole_enabled AS enabled,
            round((category_option_group_option_prices.whole_price * (100)::numeric)) AS price_cents) whole,
    LATERAL ( SELECT serialized_menu_sizes.json AS size,
            half.*::record AS half,
            whole.*::record AS whole) x;


ALTER TABLE public.serialized_category_option_group_option_prices OWNER TO uc0o9etll61111;

--
-- Name: serialized_category_option_group_options; Type: VIEW; Schema: public; Owner: uc0o9etll61111
--

CREATE VIEW serialized_category_option_group_options AS
 SELECT category_option_group_options.menu_category_option_group_id AS category_option_group_id,
    row_to_json(x.*) AS json
   FROM (menu_category_option_group_options category_option_group_options
     JOIN option_group_options ON ((option_group_options.id = category_option_group_options.option_group_option_id))),
    LATERAL ( SELECT option_group_options.id,
            option_group_options.name,
            category_option_group_options.enabled,
            array_to_json(ARRAY( SELECT serialized_category_option_group_option_prices.json
                   FROM serialized_category_option_group_option_prices
                  WHERE (serialized_category_option_group_option_prices.category_option_group_option_id = category_option_group_options.id))) AS prices) x;


ALTER TABLE public.serialized_category_option_group_options OWNER TO uc0o9etll61111;

--
-- Name: serialized_category_option_groups; Type: VIEW; Schema: public; Owner: uc0o9etll61111
--

CREATE VIEW serialized_category_option_groups AS
 SELECT category_option_groups.menu_category_id AS category_id,
    category_option_groups.display_order,
    row_to_json(x.*) AS json
   FROM (menu_category_option_groups category_option_groups
     JOIN option_groups ON ((option_groups.id = category_option_groups.option_group_id))),
    LATERAL ( SELECT category_option_groups.client_id AS id,
            option_groups.id AS option_group_id,
            option_groups.name,
            category_option_groups.display_name,
            category_option_groups.half_sizes,
            category_option_groups.allows_selection_repetition,
            COALESCE(category_option_groups.restriction, '{"type":null,"amount":null}'::json) AS restriction,
            array_to_json(ARRAY( SELECT serialized_category_option_group_options.json
                   FROM serialized_category_option_group_options
                  WHERE (serialized_category_option_group_options.category_option_group_id = category_option_groups.id))) AS options) x;


ALTER TABLE public.serialized_category_option_groups OWNER TO uc0o9etll61111;

--
-- Name: serialized_category_sizes; Type: VIEW; Schema: public; Owner: uc0o9etll61111
--

CREATE VIEW serialized_category_sizes AS
 SELECT category_sizes.menu_category_id AS category_id,
    category_sizes.display_order,
    serialized_menu_sizes.json
   FROM (menu_category_sizes category_sizes
     JOIN serialized_menu_sizes ON ((serialized_menu_sizes.id = category_sizes.menu_size_id)));


ALTER TABLE public.serialized_category_sizes OWNER TO uc0o9etll61111;

--
-- Name: serialized_menu_descriptors; Type: VIEW; Schema: public; Owner: uc0o9etll61111
--

CREATE VIEW serialized_menu_descriptors AS
 SELECT descriptors.id,
    descriptors.restaurant_id AS menu_id,
    descriptors.display_order,
    row_to_json(x.*) AS json
   FROM menu_descriptors descriptors,
    LATERAL ( SELECT descriptors.id,
            descriptors.name) x;


ALTER TABLE public.serialized_menu_descriptors OWNER TO uc0o9etll61111;

--
-- Name: serialized_item_descriptors; Type: VIEW; Schema: public; Owner: uc0o9etll61111
--

CREATE VIEW serialized_item_descriptors AS
 SELECT menu_item_descriptors.menu_item_id AS item_id,
    menu_item_descriptors.display_order,
    serialized_menu_descriptors.json
   FROM (menu_item_descriptors
     JOIN serialized_menu_descriptors ON ((serialized_menu_descriptors.id = menu_item_descriptors.menu_descriptor_id)));


ALTER TABLE public.serialized_item_descriptors OWNER TO uc0o9etll61111;

--
-- Name: serialized_item_option_group_option_prices; Type: VIEW; Schema: public; Owner: uc0o9etll61111
--

CREATE VIEW serialized_item_option_group_option_prices AS
 SELECT item_option_group_option_prices.menu_item_option_group_option_id AS item_option_group_option_id,
    row_to_json(x.*) AS json
   FROM ((menu_item_option_group_option_prices item_option_group_option_prices
     JOIN option_group_option_prices ON ((option_group_option_prices.id = item_option_group_option_prices.option_group_option_price_id)))
     JOIN serialized_menu_sizes ON ((serialized_menu_sizes.id = option_group_option_prices.menu_size_id))),
    LATERAL ( SELECT item_option_group_option_prices.half_enabled AS enabled,
            round((item_option_group_option_prices.half_price * (100)::numeric)) AS price_cents) half,
    LATERAL ( SELECT item_option_group_option_prices.whole_enabled AS enabled,
            round((item_option_group_option_prices.whole_price * (100)::numeric)) AS price_cents) whole,
    LATERAL ( SELECT serialized_menu_sizes.json AS size,
            half.*::record AS half,
            whole.*::record AS whole) x;


ALTER TABLE public.serialized_item_option_group_option_prices OWNER TO uc0o9etll61111;

--
-- Name: serialized_item_option_group_options; Type: VIEW; Schema: public; Owner: uc0o9etll61111
--

CREATE VIEW serialized_item_option_group_options AS
 SELECT item_option_group_options.menu_item_option_group_id AS item_option_group_id,
    row_to_json(x.*) AS json
   FROM (menu_item_option_group_options item_option_group_options
     JOIN option_group_options ON ((option_group_options.id = item_option_group_options.option_group_option_id))),
    LATERAL ( SELECT option_group_options.id,
            option_group_options.name,
            item_option_group_options.enabled,
            array_to_json(ARRAY( SELECT serialized_item_option_group_option_prices.json
                   FROM serialized_item_option_group_option_prices
                  WHERE (serialized_item_option_group_option_prices.item_option_group_option_id = item_option_group_options.id))) AS prices) x;


ALTER TABLE public.serialized_item_option_group_options OWNER TO uc0o9etll61111;

--
-- Name: serialized_item_option_groups; Type: VIEW; Schema: public; Owner: uc0o9etll61111
--

CREATE VIEW serialized_item_option_groups AS
 SELECT item_option_groups.menu_item_id AS item_id,
    item_option_groups.display_order,
    row_to_json(x.*) AS json
   FROM (menu_item_option_groups item_option_groups
     JOIN option_groups ON ((option_groups.id = item_option_groups.option_group_id))),
    LATERAL ( SELECT item_option_groups.client_id AS id,
            option_groups.id AS option_group_id,
            option_groups.name,
            item_option_groups.display_name,
            item_option_groups.half_sizes,
            item_option_groups.allows_selection_repetition,
            COALESCE(item_option_groups.restriction, '{"type":null,"amount":null}'::json) AS restriction,
            array_to_json(ARRAY( SELECT serialized_item_option_group_options.json
                   FROM serialized_item_option_group_options
                  WHERE (serialized_item_option_group_options.item_option_group_id = item_option_groups.id))) AS options) x;


ALTER TABLE public.serialized_item_option_groups OWNER TO uc0o9etll61111;

--
-- Name: serialized_item_prices; Type: VIEW; Schema: public; Owner: uc0o9etll61111
--

CREATE VIEW serialized_item_prices AS
 SELECT menu_items.id AS item_id,
    row_to_json(x.*) AS json,
    menu_category_sizes.display_order
   FROM (((menu_items
     JOIN menu_category_sizes ON ((menu_category_sizes.menu_category_id = menu_items.category_id)))
     JOIN serialized_menu_sizes ON ((serialized_menu_sizes.id = menu_category_sizes.menu_size_id)))
     LEFT JOIN menu_item_sizes ON (((menu_item_sizes.menu_item_id = menu_items.id) AND (menu_item_sizes.menu_size_id = menu_category_sizes.menu_size_id)))),
    LATERAL ( SELECT serialized_menu_sizes.json AS size,
            COALESCE(menu_item_sizes.enabled, false) AS enabled,
            round((menu_item_sizes.price * (100)::numeric)) AS price_cents,
            round((menu_item_sizes.restaurant_price * (100)::numeric)) AS restaurant_price_cents) x;


ALTER TABLE public.serialized_item_prices OWNER TO uc0o9etll61111;

--
-- Name: serialized_items; Type: VIEW; Schema: public; Owner: uc0o9etll61111
--

CREATE VIEW serialized_items AS
 SELECT items.category_id,
    items.display_order,
    row_to_json(x.*) AS json
   FROM menu_items items,
    LATERAL ( SELECT items.id,
            items.category_id,
            items.name,
            items.description,
            items.visible,
            items.available,
            items.order_type,
            items.order_for_later_lead_time,
            items.sales_tax,
            items.discountable,
            items.combinable,
            items.special,
            items.upsell,
            items.coupon_only,
            items.per_order_limit,
            items.per_account_order_limit,
            items.timesets,
            array_to_json(ARRAY( SELECT serialized_item_descriptors.json
                   FROM serialized_item_descriptors
                  WHERE (serialized_item_descriptors.item_id = items.id)
                  ORDER BY serialized_item_descriptors.display_order)) AS descriptors,
            array_to_json(ARRAY( SELECT serialized_item_prices.json
                   FROM serialized_item_prices
                  WHERE (serialized_item_prices.item_id = items.id)
                  ORDER BY serialized_item_prices.display_order)) AS prices,
                CASE
                    WHEN items.inherit_option_groups THEN NULL::json
                    ELSE array_to_json(ARRAY( SELECT serialized_item_option_groups.json
                       FROM serialized_item_option_groups
                      WHERE (serialized_item_option_groups.item_id = items.id)
                      ORDER BY serialized_item_option_groups.display_order))
                END AS option_groups) x;


ALTER TABLE public.serialized_items OWNER TO uc0o9etll61111;

--
-- Name: serialized_subcategories; Type: VIEW; Schema: public; Owner: uc0o9etll61111
--

CREATE VIEW serialized_subcategories AS
 SELECT categories.restaurant_id AS menu_id,
    categories.parent_category_id AS category_id,
    categories.display_order,
    row_to_json(x.*) AS json
   FROM menu_categories categories,
    LATERAL ( SELECT categories.id,
            categories.parent_category_id AS category_id,
            categories.name,
            categories.fulfilled_by_delivery_service,
            categories.description,
            categories.size_type,
            categories.visible,
            categories.available,
            categories.order_type,
            categories.order_for_later_lead_time,
            categories.timesets,
            array_to_json(ARRAY( SELECT serialized_category_sizes.json
                   FROM serialized_category_sizes
                  WHERE (serialized_category_sizes.category_id = categories.id)
                  ORDER BY serialized_category_sizes.display_order)) AS sizes,
                CASE
                    WHEN categories.inherit_option_groups THEN NULL::json
                    ELSE array_to_json(ARRAY( SELECT serialized_category_option_groups.json
                       FROM serialized_category_option_groups
                      WHERE (serialized_category_option_groups.category_id = categories.id)
                      ORDER BY serialized_category_option_groups.display_order))
                END AS option_groups,
            array_to_json(ARRAY( SELECT serialized_items.json
                   FROM serialized_items
                  WHERE (serialized_items.category_id = categories.id)
                  ORDER BY serialized_items.display_order)) AS items) x
  WHERE (categories.parent_category_id IS NOT NULL);


ALTER TABLE public.serialized_subcategories OWNER TO uc0o9etll61111;

--
-- Name: serialized_categories; Type: VIEW; Schema: public; Owner: uc0o9etll61111
--

CREATE VIEW serialized_categories AS
 SELECT categories.restaurant_id AS menu_id,
    categories.display_order,
    row_to_json(x.*) AS json
   FROM menu_categories categories,
    LATERAL ( SELECT categories.id,
            categories.restaurant_id AS menu_id,
            categories.name,
            categories.fulfilled_by_delivery_service,
            categories.description,
            categories.size_type,
            categories.visible,
            categories.available,
            categories.order_type,
            categories.order_for_later_lead_time,
            categories.timesets,
            array_to_json(ARRAY( SELECT serialized_category_sizes.json
                   FROM serialized_category_sizes
                  WHERE (serialized_category_sizes.category_id = categories.id)
                  ORDER BY serialized_category_sizes.display_order)) AS sizes,
            array_to_json(ARRAY( SELECT serialized_category_option_groups.json
                   FROM serialized_category_option_groups
                  WHERE (serialized_category_option_groups.category_id = categories.id)
                  ORDER BY serialized_category_option_groups.display_order)) AS option_groups,
            array_to_json(ARRAY( SELECT serialized_subcategories.json
                   FROM serialized_subcategories
                  WHERE ((serialized_subcategories.menu_id = categories.restaurant_id) AND (serialized_subcategories.category_id = categories.id))
                  ORDER BY serialized_subcategories.display_order)) AS subcategories,
            array_to_json(ARRAY( SELECT serialized_items.json
                   FROM serialized_items
                  WHERE (serialized_items.category_id = categories.id)
                  ORDER BY serialized_items.display_order)) AS items) x
  WHERE (categories.parent_category_id IS NULL);


ALTER TABLE public.serialized_categories OWNER TO uc0o9etll61111;

--
-- Name: serialized_option_group_option_prices; Type: VIEW; Schema: public; Owner: uc0o9etll61111
--

CREATE VIEW serialized_option_group_option_prices AS
 SELECT prices.option_group_option_id,
    row_to_json(x.*) AS json
   FROM (option_group_option_prices prices
     JOIN serialized_menu_sizes sizes ON ((sizes.id = prices.menu_size_id))),
    LATERAL ( SELECT prices.half_enabled AS enabled,
            round((prices.half_price * (100)::numeric)) AS price_cents) half,
    LATERAL ( SELECT prices.whole_enabled AS enabled,
            round((prices.whole_price * (100)::numeric)) AS price_cents) whole,
    LATERAL ( SELECT sizes.json AS size,
            half.*::record AS half,
            whole.*::record AS whole) x;


ALTER TABLE public.serialized_option_group_option_prices OWNER TO uc0o9etll61111;

--
-- Name: serialized_option_group_options; Type: VIEW; Schema: public; Owner: uc0o9etll61111
--

CREATE VIEW serialized_option_group_options AS
 SELECT options.option_group_id,
    options.display_order,
    row_to_json(x.*) AS json
   FROM option_group_options options,
    LATERAL ( SELECT options.id,
            options.available,
            options.enabled,
            options.name,
            array_to_json(ARRAY( SELECT prices.json
                   FROM serialized_option_group_option_prices prices
                  WHERE (prices.option_group_option_id = options.id))) AS prices) x;


ALTER TABLE public.serialized_option_group_options OWNER TO uc0o9etll61111;

--
-- Name: serialized_option_groups; Type: VIEW; Schema: public; Owner: uc0o9etll61111
--

CREATE VIEW serialized_option_groups AS
 SELECT groups.restaurant_id AS menu_id,
    groups.display_order,
    row_to_json(x.*) AS json
   FROM option_groups groups,
    LATERAL ( SELECT groups.id,
            groups.restaurant_id AS menu_id,
            groups.name,
            groups.display_name,
            groups.half_sizes,
            groups.allows_selection_repetition,
            groups.restriction,
            array_to_json(ARRAY( SELECT options.json
                   FROM serialized_option_group_options options
                  WHERE (options.option_group_id = groups.id)
                  ORDER BY options.display_order)) AS options) x;


ALTER TABLE public.serialized_option_groups OWNER TO uc0o9etll61111;

--
-- Name: serialized_menus; Type: VIEW; Schema: public; Owner: uc0o9etll61111
--

CREATE VIEW serialized_menus AS
 SELECT menus.id,
    row_to_json(x.*) AS json,
    (row_to_json(x.*))::text AS json_text
   FROM ((restaurants menus
     LEFT JOIN canonicalized_menus ON ((canonicalized_menus.restaurant_id = menus.id)))
     LEFT JOIN canonicalized_json_menus ON ((canonicalized_json_menus.restaurant_id = menus.id))),
    LATERAL ( SELECT menus.id,
            menus.slug,
            menus.name,
            menus.time_zone,
            menus.change_count,
            canonicalized_menus.change_count AS published_change_count,
            canonicalized_json_menus.last_queued_at,
            canonicalized_json_menus.last_published_at,
            '{}'::json[] AS timesets,
                CASE
                    WHEN (menus.delivery AND menus.takeout) THEN 'Delivery & Takeout'::text
                    WHEN menus.delivery THEN 'Delivery'::text
                    WHEN menus.takeout THEN 'Takeout'::text
                    ELSE NULL::text
                END AS order_type,
            array_to_json(ARRAY( SELECT sizes.json
                   FROM serialized_menu_sizes sizes
                  WHERE (sizes.menu_id = menus.id)
                  ORDER BY sizes.display_order)) AS sizes,
            array_to_json(ARRAY( SELECT descriptors.json
                   FROM serialized_menu_descriptors descriptors
                  WHERE (descriptors.menu_id = menus.id)
                  ORDER BY descriptors.display_order)) AS descriptors,
            array_to_json(ARRAY( SELECT groups.json
                   FROM serialized_option_groups groups
                  WHERE (groups.menu_id = menus.id)
                  ORDER BY groups.display_order)) AS option_groups,
            array_to_json(ARRAY( SELECT categories.json
                   FROM serialized_categories categories
                  WHERE (categories.menu_id = menus.id)
                  ORDER BY categories.display_order)) AS categories) x;


ALTER TABLE public.serialized_menus OWNER TO uc0o9etll61111;

--
-- Name: settings; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE settings (
    id integer NOT NULL,
    fax_provider character varying(255) DEFAULT 'phaxio'::character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    system_online boolean,
    banner_message text,
    sms_provider character varying(255) DEFAULT 'twilio'::character varying NOT NULL,
    credit_card_processor character varying(255) DEFAULT 'braintree'::character varying,
    phone_provider character varying(255),
    giving_tuesday_additional_dollars numeric(19,3),
    geocoding_provider character varying(255),
    emma_synced_up_to timestamp without time zone,
    CONSTRAINT check_constraint_settings_only_one_row CHECK ((id = 1))
);


ALTER TABLE public.settings OWNER TO uc0o9etll61111;

--
-- Name: settings_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.settings_id_seq OWNER TO uc0o9etll61111;

--
-- Name: settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE settings_id_seq OWNED BY settings.id;


--
-- Name: shift_assignment_delivery_service_changes; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE shift_assignment_delivery_service_changes (
    id integer NOT NULL,
    shift_assignment_id integer NOT NULL,
    previous_delivery_service_id integer NOT NULL,
    current_delivery_service_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.shift_assignment_delivery_service_changes OWNER TO uc0o9etll61111;

--
-- Name: shift_assignment_delivery_service_changes_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE shift_assignment_delivery_service_changes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shift_assignment_delivery_service_changes_id_seq OWNER TO uc0o9etll61111;

--
-- Name: shift_assignment_delivery_service_changes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE shift_assignment_delivery_service_changes_id_seq OWNED BY shift_assignment_delivery_service_changes.id;


--
-- Name: shift_assignments; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE shift_assignments (
    id integer NOT NULL,
    driver_id integer,
    shift_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    rejected_at timestamp without time zone,
    delivery_service_id integer NOT NULL,
    shift_start_notification_sent boolean DEFAULT false,
    reliability_score numeric(7,6),
    reliability_score_weight numeric(7,6)
);


ALTER TABLE public.shift_assignments OWNER TO uc0o9etll61111;

--
-- Name: shift_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE shift_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shift_assignments_id_seq OWNER TO uc0o9etll61111;

--
-- Name: shift_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE shift_assignments_id_seq OWNED BY shift_assignments.id;


--
-- Name: shift_predictions; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE shift_predictions (
    id integer NOT NULL,
    shift_id integer NOT NULL,
    delivery_service_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    suggested_driver_hours numeric,
    estimated_delivery_count numeric,
    deliveries_per_hour_multiplier numeric
);


ALTER TABLE public.shift_predictions OWNER TO uc0o9etll61111;

--
-- Name: shift_predictions_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE shift_predictions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shift_predictions_id_seq OWNER TO uc0o9etll61111;

--
-- Name: shift_predictions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE shift_predictions_id_seq OWNED BY shift_predictions.id;


--
-- Name: shift_templates; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE shift_templates (
    id integer NOT NULL,
    start_hour integer,
    end_hour integer,
    needed_drivers integer,
    guaranteed_wage integer,
    market_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.shift_templates OWNER TO uc0o9etll61111;

--
-- Name: shift_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE shift_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shift_templates_id_seq OWNER TO uc0o9etll61111;

--
-- Name: shift_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE shift_templates_id_seq OWNED BY shift_templates.id;


--
-- Name: shifts; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE shifts (
    id integer NOT NULL,
    starts_at timestamp without time zone,
    ends_at timestamp without time zone,
    guaranteed_wage integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    market_id integer,
    needed_drivers integer DEFAULT 0 NOT NULL,
    published boolean DEFAULT false NOT NULL,
    correct_starts_at timestamp without time zone,
    correct_ends_at timestamp without time zone
);


ALTER TABLE public.shifts OWNER TO uc0o9etll61111;

--
-- Name: shifts_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE shifts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shifts_id_seq OWNER TO uc0o9etll61111;

--
-- Name: shifts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE shifts_id_seq OWNED BY shifts.id;


--
-- Name: shutdown_group_restaurants; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE shutdown_group_restaurants (
    id integer NOT NULL,
    shutdown_group_id integer,
    restaurant_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.shutdown_group_restaurants OWNER TO uc0o9etll61111;

--
-- Name: shutdown_group_restaurants_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE shutdown_group_restaurants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shutdown_group_restaurants_id_seq OWNER TO uc0o9etll61111;

--
-- Name: shutdown_group_restaurants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE shutdown_group_restaurants_id_seq OWNED BY shutdown_group_restaurants.id;


--
-- Name: shutdown_groups; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE shutdown_groups (
    id integer NOT NULL,
    market_id integer,
    name character varying(255) NOT NULL,
    shutdown boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    shutdown_message_id integer
);


ALTER TABLE public.shutdown_groups OWNER TO uc0o9etll61111;

--
-- Name: shutdown_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE shutdown_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shutdown_groups_id_seq OWNER TO uc0o9etll61111;

--
-- Name: shutdown_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE shutdown_groups_id_seq OWNED BY shutdown_groups.id;


--
-- Name: shutdown_messages; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE shutdown_messages (
    id integer NOT NULL,
    reason character varying(255) NOT NULL,
    body text NOT NULL,
    automatic boolean DEFAULT false NOT NULL,
    archived boolean DEFAULT false NOT NULL
);


ALTER TABLE public.shutdown_messages OWNER TO uc0o9etll61111;

--
-- Name: shutdown_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE shutdown_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shutdown_messages_id_seq OWNER TO uc0o9etll61111;

--
-- Name: shutdown_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE shutdown_messages_id_seq OWNED BY shutdown_messages.id;


--
-- Name: sign_up_links; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE sign_up_links (
    id integer NOT NULL,
    market_id integer NOT NULL,
    email_address character varying(255),
    phone_number character varying(255),
    memo character varying(255),
    amount integer NOT NULL,
    customer_id integer,
    accepted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.sign_up_links OWNER TO uc0o9etll61111;

--
-- Name: sign_up_links_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE sign_up_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sign_up_links_id_seq OWNER TO uc0o9etll61111;

--
-- Name: sign_up_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE sign_up_links_id_seq OWNED BY sign_up_links.id;


--
-- Name: sms_messages; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE sms_messages (
    id integer NOT NULL,
    type character varying(255) NOT NULL,
    sms_number_id integer NOT NULL,
    from_type character varying(255) NOT NULL,
    from_id integer NOT NULL,
    from_number character varying(255) NOT NULL,
    to_number character varying(255) NOT NULL,
    to_type character varying(255) NOT NULL,
    to_id integer NOT NULL,
    message text NOT NULL,
    external_id character varying(255),
    message_data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    order_id integer
);


ALTER TABLE public.sms_messages OWNER TO uc0o9etll61111;

--
-- Name: sms_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE sms_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sms_messages_id_seq OWNER TO uc0o9etll61111;

--
-- Name: sms_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE sms_messages_id_seq OWNED BY sms_messages.id;


--
-- Name: sms_number_reservations; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE sms_number_reservations (
    id integer NOT NULL,
    sms_number_id integer,
    from_number character varying(255) NOT NULL,
    from_type character varying(255) NOT NULL,
    from_id integer NOT NULL,
    to_number character varying(255) NOT NULL,
    to_type character varying(255) NOT NULL,
    to_id integer NOT NULL,
    hour timestamp without time zone NOT NULL,
    expires_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    order_id integer
);


ALTER TABLE public.sms_number_reservations OWNER TO uc0o9etll61111;

--
-- Name: sms_number_reservations_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE sms_number_reservations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sms_number_reservations_id_seq OWNER TO uc0o9etll61111;

--
-- Name: sms_number_reservations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE sms_number_reservations_id_seq OWNED BY sms_number_reservations.id;


--
-- Name: sms_numbers; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE sms_numbers (
    id integer NOT NULL,
    provider_type character varying(255) NOT NULL,
    number character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    reservation_expires_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    market_id integer,
    deleted_at timestamp without time zone
);


ALTER TABLE public.sms_numbers OWNER TO uc0o9etll61111;

--
-- Name: sms_numbers_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE sms_numbers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sms_numbers_id_seq OWNER TO uc0o9etll61111;

--
-- Name: sms_numbers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE sms_numbers_id_seq OWNED BY sms_numbers.id;


--
-- Name: specials; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE specials (
    id integer NOT NULL,
    restaurant_id integer NOT NULL,
    description character varying(255),
    delivery_days integer DEFAULT 0 NOT NULL,
    takeout_days integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.specials OWNER TO uc0o9etll61111;

--
-- Name: specials_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE specials_id_seq
    START WITH 10000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.specials_id_seq OWNER TO uc0o9etll61111;

--
-- Name: specials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE specials_id_seq OWNED BY specials.id;


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE subscriptions (
    id integer NOT NULL,
    subscriptionable_id integer NOT NULL,
    report_type character varying(255) NOT NULL,
    period character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    subscriptionable_type character varying(255) NOT NULL,
    next_run_at timestamp without time zone NOT NULL,
    subscriptionable_name character varying(255),
    recipients character varying(255)[] DEFAULT '{}'::character varying[] NOT NULL,
    last_ran_at timestamp without time zone
);


ALTER TABLE public.subscriptions OWNER TO uc0o9etll61111;

--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.subscriptions_id_seq OWNER TO uc0o9etll61111;

--
-- Name: subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE subscriptions_id_seq OWNED BY subscriptions.id;


--
-- Name: surveys; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE surveys (
    id integer NOT NULL,
    spreadsheet_key character varying(255),
    restaurant_list text,
    prize_image_link character varying(255),
    rules_link character varying(255),
    headline text,
    school_name character varying(255),
    thanks_image_link character varying(255),
    share_language text,
    email_subject character varying(255),
    prize_name character varying(255),
    market_id integer,
    version character varying(255),
    prompt text
);


ALTER TABLE public.surveys OWNER TO uc0o9etll61111;

--
-- Name: surveys_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE surveys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.surveys_id_seq OWNER TO uc0o9etll61111;

--
-- Name: surveys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE surveys_id_seq OWNED BY surveys.id;


--
-- Name: temporary_shutdowns; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE temporary_shutdowns (
    id integer NOT NULL,
    delivery_service_id integer,
    state character varying(255) DEFAULT 'scheduled'::character varying,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    shutdown_message_id integer,
    automatic boolean
);


ALTER TABLE public.temporary_shutdowns OWNER TO uc0o9etll61111;

--
-- Name: temporary_shutdowns_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE temporary_shutdowns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.temporary_shutdowns_id_seq OWNER TO uc0o9etll61111;

--
-- Name: temporary_shutdowns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE temporary_shutdowns_id_seq OWNED BY temporary_shutdowns.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    username character varying(255) NOT NULL,
    password character varying(255),
    first_name character varying(255),
    last_name character varying(255),
    role integer,
    email character varying(255),
    active boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.users OWNER TO uc0o9etll61111;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE users_id_seq
    START WITH 5000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO uc0o9etll61111;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: voice_calls; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE voice_calls (
    id integer NOT NULL,
    sms_number_id integer NOT NULL,
    sms_number_reservation_id integer NOT NULL,
    message_direction character varying(255),
    order_id integer NOT NULL,
    driver_id integer NOT NULL,
    customer_id integer NOT NULL,
    external_id character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.voice_calls OWNER TO uc0o9etll61111;

--
-- Name: voice_calls_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE voice_calls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.voice_calls_id_seq OWNER TO uc0o9etll61111;

--
-- Name: voice_calls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE voice_calls_id_seq OWNED BY voice_calls.id;


--
-- Name: work_segments; Type: TABLE; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE TABLE work_segments (
    id integer NOT NULL,
    driver_id integer,
    started_at timestamp without time zone,
    ended_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    delivery_service_id integer
);


ALTER TABLE public.work_segments OWNER TO uc0o9etll61111;

--
-- Name: work_segments_id_seq; Type: SEQUENCE; Schema: public; Owner: uc0o9etll61111
--

CREATE SEQUENCE work_segments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.work_segments_id_seq OWNER TO uc0o9etll61111;

--
-- Name: work_segments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: uc0o9etll61111
--

ALTER SEQUENCE work_segments_id_seq OWNED BY work_segments.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY active_cart_counts ALTER COLUMN id SET DEFAULT nextval('active_cart_counts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY adjustments ALTER COLUMN id SET DEFAULT nextval('adjustments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY affiliates ALTER COLUMN id SET DEFAULT nextval('affiliates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY april_fools_responses ALTER COLUMN id SET DEFAULT nextval('april_fools_responses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY audits ALTER COLUMN id SET DEFAULT nextval('audits_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY banner_ads ALTER COLUMN id SET DEFAULT nextval('banner_ads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY beacons ALTER COLUMN id SET DEFAULT nextval('beacons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY blacklisted_email_addresses ALTER COLUMN id SET DEFAULT nextval('blacklisted_email_addresses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY blacklisted_email_domains ALTER COLUMN id SET DEFAULT nextval('blacklisted_email_domains_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY blacklisted_ip_addresses ALTER COLUMN id SET DEFAULT nextval('blacklisted_ip_addresses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY blacklisted_phone_numbers ALTER COLUMN id SET DEFAULT nextval('blacklisted_phone_numbers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY blazer_audits ALTER COLUMN id SET DEFAULT nextval('blazer_audits_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY blazer_queries ALTER COLUMN id SET DEFAULT nextval('blazer_queries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY building_groups ALTER COLUMN id SET DEFAULT nextval('building_groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY buildings ALTER COLUMN id SET DEFAULT nextval('buildings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY campus_payment_cards ALTER COLUMN id SET DEFAULT nextval('campus_payment_cards_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY canonicalized_json_menus ALTER COLUMN id SET DEFAULT nextval('canonicalized_json_menus_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY canonicalized_menus ALTER COLUMN id SET DEFAULT nextval('canonicalized_menus_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY cart_coupons ALTER COLUMN id SET DEFAULT nextval('cart_coupons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY cart_item_options ALTER COLUMN id SET DEFAULT nextval('cart_item_options_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY cart_items ALTER COLUMN id SET DEFAULT nextval('cart_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY cart_participants ALTER COLUMN id SET DEFAULT nextval('cart_participants_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY carts ALTER COLUMN id SET DEFAULT nextval('carts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY cohort_memberships ALTER COLUMN id SET DEFAULT nextval('cohort_memberships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY cohort_service_cohorts ALTER COLUMN id SET DEFAULT nextval('cohort_service_cohorts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY cohort_services ALTER COLUMN id SET DEFAULT nextval('cohort_services_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY cohorts ALTER COLUMN id SET DEFAULT nextval('cohorts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY coupons ALTER COLUMN id SET DEFAULT nextval('coupons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY credit_batch_errors ALTER COLUMN id SET DEFAULT nextval('credit_batch_errors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY credit_batches ALTER COLUMN id SET DEFAULT nextval('credit_batches_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY credit_cards ALTER COLUMN id SET DEFAULT nextval('credit_cards_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY credit_items ALTER COLUMN id SET DEFAULT nextval('credit_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY customer_addresses ALTER COLUMN id SET DEFAULT nextval('customer_addresses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY customer_campus_cards ALTER COLUMN id SET DEFAULT nextval('customer_campus_cards_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY customer_coupon_uses ALTER COLUMN id SET DEFAULT nextval('customer_coupon_uses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY customer_information_requests ALTER COLUMN id SET DEFAULT nextval('customer_information_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY customer_phones ALTER COLUMN id SET DEFAULT nextval('customer_phones_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY customers ALTER COLUMN id SET DEFAULT nextval('customers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY daily_order_counts ALTER COLUMN id SET DEFAULT nextval('daily_order_counts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY deliveries ALTER COLUMN id SET DEFAULT nextval('deliveries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY deliveries_hours ALTER COLUMN id SET DEFAULT nextval('deliveries_hours_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY delivery_comments ALTER COLUMN id SET DEFAULT nextval('delivery_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY delivery_estimates ALTER COLUMN id SET DEFAULT nextval('delivery_estimates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY delivery_log_entries ALTER COLUMN id SET DEFAULT nextval('delivery_log_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY delivery_service_health_features ALTER COLUMN id SET DEFAULT nextval('delivery_service_health_features_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY delivery_service_health_models ALTER COLUMN id SET DEFAULT nextval('delivery_service_health_models_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY delivery_service_health_scores ALTER COLUMN id SET DEFAULT nextval('delivery_service_health_scores_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY delivery_service_random_forests ALTER COLUMN id SET DEFAULT nextval('delivery_service_random_forests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY delivery_services ALTER COLUMN id SET DEFAULT nextval('delivery_services_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY delivery_sign_ups ALTER COLUMN id SET DEFAULT nextval('delivery_sign_ups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY delivery_status_updates ALTER COLUMN id SET DEFAULT nextval('delivery_status_updates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY delivery_steps ALTER COLUMN id SET DEFAULT nextval('delivery_steps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY delivery_zones ALTER COLUMN id SET DEFAULT nextval('delivery_zones_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY devices ALTER COLUMN id SET DEFAULT nextval('devices_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY dispatches ALTER COLUMN id SET DEFAULT nextval('dispatches_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY driver_availabilities ALTER COLUMN id SET DEFAULT nextval('driver_availabilities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY driver_availability_blocks ALTER COLUMN id SET DEFAULT nextval('driver_availability_blocks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY driver_broadcasts ALTER COLUMN id SET DEFAULT nextval('driver_broadcasts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY driver_locations ALTER COLUMN id SET DEFAULT nextval('driver_locations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY driver_messages ALTER COLUMN id SET DEFAULT nextval('driver_messages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY driver_points ALTER COLUMN id SET DEFAULT nextval('driver_points_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY driver_restaurant_bans ALTER COLUMN id SET DEFAULT nextval('driver_restaurant_bans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY driver_work_hours ALTER COLUMN id SET DEFAULT nextval('driver_work_hours_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY drivers ALTER COLUMN id SET DEFAULT nextval('drivers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY estimation_model_feature_values ALTER COLUMN id SET DEFAULT nextval('estimation_model_feature_values_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY estimation_model_features ALTER COLUMN id SET DEFAULT nextval('estimation_model_features_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY estimation_models ALTER COLUMN id SET DEFAULT nextval('estimation_models_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY favorite_restaurants ALTER COLUMN id SET DEFAULT nextval('favorite_restaurants_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY franchise_contacts ALTER COLUMN id SET DEFAULT nextval('franchise_contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY frequently_asked_question_categories ALTER COLUMN id SET DEFAULT nextval('frequently_asked_question_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY frequently_asked_questions ALTER COLUMN id SET DEFAULT nextval('frequently_asked_questions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY gift_cards ALTER COLUMN id SET DEFAULT nextval('gift_cards_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY hosted_sites ALTER COLUMN id SET DEFAULT nextval('hosted_sites_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY jobs ALTER COLUMN id SET DEFAULT nextval('jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY loyalty_cash_transactions ALTER COLUMN id SET DEFAULT nextval('loyalty_cash_transactions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY market_campus_payment_cards ALTER COLUMN id SET DEFAULT nextval('market_campus_payment_cards_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY market_cities ALTER COLUMN id SET DEFAULT nextval('market_cities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY market_dispatch_notes ALTER COLUMN id SET DEFAULT nextval('market_dispatch_notes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY market_scorecards ALTER COLUMN id SET DEFAULT nextval('market_scorecards_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY market_weather_hours ALTER COLUMN id SET DEFAULT nextval('market_weather_hours_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY markets ALTER COLUMN id SET DEFAULT nextval('markets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_categories ALTER COLUMN id SET DEFAULT nextval('menu_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_category_option_group_option_prices ALTER COLUMN id SET DEFAULT nextval('menu_category_option_group_option_prices_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_category_option_group_options ALTER COLUMN id SET DEFAULT nextval('menu_category_option_group_options_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_category_option_groups ALTER COLUMN id SET DEFAULT nextval('menu_category_option_groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_category_sizes ALTER COLUMN id SET DEFAULT nextval('menu_category_sizes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_descriptors ALTER COLUMN id SET DEFAULT nextval('menu_descriptors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_item_descriptors ALTER COLUMN id SET DEFAULT nextval('menu_item_descriptors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_item_option_group_option_prices ALTER COLUMN id SET DEFAULT nextval('menu_item_option_group_option_prices_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_item_option_group_options ALTER COLUMN id SET DEFAULT nextval('menu_item_option_group_options_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_item_option_groups ALTER COLUMN id SET DEFAULT nextval('menu_item_option_groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_item_sizes ALTER COLUMN id SET DEFAULT nextval('menu_item_sizes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_items ALTER COLUMN id SET DEFAULT nextval('menu_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_options ALTER COLUMN id SET DEFAULT nextval('menu_options_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_sizes ALTER COLUMN id SET DEFAULT nextval('menu_sizes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_updates ALTER COLUMN id SET DEFAULT nextval('menu_updates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY monthly_order_counts ALTER COLUMN id SET DEFAULT nextval('monthly_order_counts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY newbie_codes ALTER COLUMN id SET DEFAULT nextval('newbie_codes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY notification_schedule_changes ALTER COLUMN id SET DEFAULT nextval('notification_schedule_changes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY option_group_option_prices ALTER COLUMN id SET DEFAULT nextval('option_group_option_prices_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY option_group_options ALTER COLUMN id SET DEFAULT nextval('option_group_options_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY option_groups ALTER COLUMN id SET DEFAULT nextval('option_groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY order_coupons ALTER COLUMN id SET DEFAULT nextval('order_coupons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY order_notifications ALTER COLUMN id SET DEFAULT nextval('order_notifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY orders ALTER COLUMN id SET DEFAULT nextval('orders_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY pay_period_account_entries ALTER COLUMN id SET DEFAULT nextval('pay_period_account_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY payments ALTER COLUMN id SET DEFAULT nextval('payments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY pex_transactions ALTER COLUMN id SET DEFAULT nextval('pex_transactions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY print_menus ALTER COLUMN id SET DEFAULT nextval('print_menus_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY promo_codes ALTER COLUMN id SET DEFAULT nextval('promo_codes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY receipts ALTER COLUMN id SET DEFAULT nextval('receipts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY referral_codes ALTER COLUMN id SET DEFAULT nextval('referral_codes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY referrals ALTER COLUMN id SET DEFAULT nextval('referrals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY reliability_score_events ALTER COLUMN id SET DEFAULT nextval('reliability_score_events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY restaurant_campus_payment_cards ALTER COLUMN id SET DEFAULT nextval('restaurant_campus_payment_cards_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY restaurant_categories ALTER COLUMN id SET DEFAULT nextval('restaurant_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY restaurant_categorizations ALTER COLUMN id SET DEFAULT nextval('restaurant_categorizations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY restaurant_contacts ALTER COLUMN id SET DEFAULT nextval('restaurant_contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY restaurant_delivery_zones ALTER COLUMN id SET DEFAULT nextval('restaurant_delivery_zones_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY restaurant_drive_times ALTER COLUMN id SET DEFAULT nextval('restaurant_drive_times_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY restaurant_hours ALTER COLUMN id SET DEFAULT nextval('restaurant_hours_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY restaurant_requests ALTER COLUMN id SET DEFAULT nextval('restaurant_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY restaurant_temporary_hours ALTER COLUMN id SET DEFAULT nextval('restaurant_temporary_hours_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY restaurant_users ALTER COLUMN id SET DEFAULT nextval('restaurant_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY restaurants ALTER COLUMN id SET DEFAULT nextval('restaurants_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY scorecards ALTER COLUMN id SET DEFAULT nextval('scorecards_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY settings ALTER COLUMN id SET DEFAULT nextval('settings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY shift_assignment_delivery_service_changes ALTER COLUMN id SET DEFAULT nextval('shift_assignment_delivery_service_changes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY shift_assignments ALTER COLUMN id SET DEFAULT nextval('shift_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY shift_predictions ALTER COLUMN id SET DEFAULT nextval('shift_predictions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY shift_templates ALTER COLUMN id SET DEFAULT nextval('shift_templates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY shifts ALTER COLUMN id SET DEFAULT nextval('shifts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY shutdown_group_restaurants ALTER COLUMN id SET DEFAULT nextval('shutdown_group_restaurants_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY shutdown_groups ALTER COLUMN id SET DEFAULT nextval('shutdown_groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY shutdown_messages ALTER COLUMN id SET DEFAULT nextval('shutdown_messages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY sign_up_links ALTER COLUMN id SET DEFAULT nextval('sign_up_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY sms_messages ALTER COLUMN id SET DEFAULT nextval('sms_messages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY sms_number_reservations ALTER COLUMN id SET DEFAULT nextval('sms_number_reservations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY sms_numbers ALTER COLUMN id SET DEFAULT nextval('sms_numbers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY specials ALTER COLUMN id SET DEFAULT nextval('specials_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY subscriptions ALTER COLUMN id SET DEFAULT nextval('subscriptions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY surveys ALTER COLUMN id SET DEFAULT nextval('surveys_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY temporary_shutdowns ALTER COLUMN id SET DEFAULT nextval('temporary_shutdowns_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY voice_calls ALTER COLUMN id SET DEFAULT nextval('voice_calls_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY work_segments ALTER COLUMN id SET DEFAULT nextval('work_segments_id_seq'::regclass);


--
-- Name: acquisition_events_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY newbie_codes
    ADD CONSTRAINT acquisition_events_pkey PRIMARY KEY (id);


--
-- Name: active_cart_counts_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY active_cart_counts
    ADD CONSTRAINT active_cart_counts_pkey PRIMARY KEY (id);


--
-- Name: adjustments_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY adjustments
    ADD CONSTRAINT adjustments_pkey PRIMARY KEY (id);


--
-- Name: affiliates_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY affiliates
    ADD CONSTRAINT affiliates_pkey PRIMARY KEY (id);


--
-- Name: april_fools_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY april_fools_responses
    ADD CONSTRAINT april_fools_responses_pkey PRIMARY KEY (id);


--
-- Name: audits_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY audits
    ADD CONSTRAINT audits_pkey PRIMARY KEY (id);


--
-- Name: banner_ads_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY banner_ads
    ADD CONSTRAINT banner_ads_pkey PRIMARY KEY (id);


--
-- Name: beacons_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY beacons
    ADD CONSTRAINT beacons_pkey PRIMARY KEY (id);


--
-- Name: blacklisted_email_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY blacklisted_email_addresses
    ADD CONSTRAINT blacklisted_email_addresses_pkey PRIMARY KEY (id);


--
-- Name: blacklisted_email_domains_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY blacklisted_email_domains
    ADD CONSTRAINT blacklisted_email_domains_pkey PRIMARY KEY (id);


--
-- Name: blacklisted_ip_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY blacklisted_ip_addresses
    ADD CONSTRAINT blacklisted_ip_addresses_pkey PRIMARY KEY (id);


--
-- Name: blacklisted_phone_numbers_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY blacklisted_phone_numbers
    ADD CONSTRAINT blacklisted_phone_numbers_pkey PRIMARY KEY (id);


--
-- Name: blazer_audits_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY blazer_audits
    ADD CONSTRAINT blazer_audits_pkey PRIMARY KEY (id);


--
-- Name: blazer_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY blazer_queries
    ADD CONSTRAINT blazer_queries_pkey PRIMARY KEY (id);


--
-- Name: building_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY building_groups
    ADD CONSTRAINT building_groups_pkey PRIMARY KEY (id);


--
-- Name: buildings_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY buildings
    ADD CONSTRAINT buildings_pkey PRIMARY KEY (id);


--
-- Name: campus_payment_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY campus_payment_cards
    ADD CONSTRAINT campus_payment_cards_pkey PRIMARY KEY (id);


--
-- Name: canonicalized_json_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY canonicalized_json_menus
    ADD CONSTRAINT canonicalized_json_menus_pkey PRIMARY KEY (id);


--
-- Name: canonicalized_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY canonicalized_menus
    ADD CONSTRAINT canonicalized_menus_pkey PRIMARY KEY (id);


--
-- Name: cart_coupons_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY cart_coupons
    ADD CONSTRAINT cart_coupons_pkey PRIMARY KEY (id);


--
-- Name: cart_item_options_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY cart_item_options
    ADD CONSTRAINT cart_item_options_pkey PRIMARY KEY (id);


--
-- Name: cart_items_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY cart_items
    ADD CONSTRAINT cart_items_pkey PRIMARY KEY (id);


--
-- Name: cart_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY cart_participants
    ADD CONSTRAINT cart_participants_pkey PRIMARY KEY (id);


--
-- Name: carts_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY carts
    ADD CONSTRAINT carts_pkey PRIMARY KEY (id);


--
-- Name: categories_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: category_option_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_category_option_groups
    ADD CONSTRAINT category_option_groups_pkey PRIMARY KEY (id);


--
-- Name: cohort_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY cohort_memberships
    ADD CONSTRAINT cohort_memberships_pkey PRIMARY KEY (id);


--
-- Name: cohort_service_cohorts_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY cohort_service_cohorts
    ADD CONSTRAINT cohort_service_cohorts_pkey PRIMARY KEY (id);


--
-- Name: cohort_services_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY cohort_services
    ADD CONSTRAINT cohort_services_pkey PRIMARY KEY (id);


--
-- Name: cohorts_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY cohorts
    ADD CONSTRAINT cohorts_pkey PRIMARY KEY (id);


--
-- Name: comments_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY delivery_comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: content_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY content
    ADD CONSTRAINT content_pkey PRIMARY KEY (key);


--
-- Name: coupons_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY coupons
    ADD CONSTRAINT coupons_pkey PRIMARY KEY (id);


--
-- Name: credit_batch_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY credit_batch_errors
    ADD CONSTRAINT credit_batch_errors_pkey PRIMARY KEY (id);


--
-- Name: credit_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY credit_batches
    ADD CONSTRAINT credit_batches_pkey PRIMARY KEY (id);


--
-- Name: credit_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY credit_cards
    ADD CONSTRAINT credit_cards_pkey PRIMARY KEY (id);


--
-- Name: credit_items_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY credit_items
    ADD CONSTRAINT credit_items_pkey PRIMARY KEY (id);


--
-- Name: customer_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY customer_addresses
    ADD CONSTRAINT customer_addresses_pkey PRIMARY KEY (id);


--
-- Name: customer_campus_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY customer_campus_cards
    ADD CONSTRAINT customer_campus_cards_pkey PRIMARY KEY (id);


--
-- Name: customer_coupon_uses_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY customer_coupon_uses
    ADD CONSTRAINT customer_coupon_uses_pkey PRIMARY KEY (id);


--
-- Name: customer_information_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY customer_information_requests
    ADD CONSTRAINT customer_information_requests_pkey PRIMARY KEY (id);


--
-- Name: customer_phones_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY customer_phones
    ADD CONSTRAINT customer_phones_pkey PRIMARY KEY (id);


--
-- Name: customers_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: daily_order_counts_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY daily_order_counts
    ADD CONSTRAINT daily_order_counts_pkey PRIMARY KEY (id);


--
-- Name: deliveries_hours_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY deliveries_hours
    ADD CONSTRAINT deliveries_hours_pkey PRIMARY KEY (id);


--
-- Name: deliveries_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY deliveries
    ADD CONSTRAINT deliveries_pkey PRIMARY KEY (id);


--
-- Name: delivery_estimates_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY delivery_estimates
    ADD CONSTRAINT delivery_estimates_pkey PRIMARY KEY (id);


--
-- Name: delivery_log_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY delivery_log_entries
    ADD CONSTRAINT delivery_log_entries_pkey PRIMARY KEY (id);


--
-- Name: delivery_service_health_features_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY delivery_service_health_features
    ADD CONSTRAINT delivery_service_health_features_pkey PRIMARY KEY (id);


--
-- Name: delivery_service_health_models_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY delivery_service_health_models
    ADD CONSTRAINT delivery_service_health_models_pkey PRIMARY KEY (id);


--
-- Name: delivery_service_health_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY delivery_service_health_scores
    ADD CONSTRAINT delivery_service_health_scores_pkey PRIMARY KEY (id);


--
-- Name: delivery_service_random_forests_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY delivery_service_random_forests
    ADD CONSTRAINT delivery_service_random_forests_pkey PRIMARY KEY (id);


--
-- Name: delivery_services_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY delivery_services
    ADD CONSTRAINT delivery_services_pkey PRIMARY KEY (id);


--
-- Name: delivery_sign_ups_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY delivery_sign_ups
    ADD CONSTRAINT delivery_sign_ups_pkey PRIMARY KEY (id);


--
-- Name: delivery_status_updates_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY delivery_status_updates
    ADD CONSTRAINT delivery_status_updates_pkey PRIMARY KEY (id);


--
-- Name: delivery_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY delivery_steps
    ADD CONSTRAINT delivery_steps_pkey PRIMARY KEY (id);


--
-- Name: delivery_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY delivery_zones
    ADD CONSTRAINT delivery_zones_pkey PRIMARY KEY (id);


--
-- Name: devices_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY devices
    ADD CONSTRAINT devices_pkey PRIMARY KEY (id);


--
-- Name: discovery_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY restaurant_categories
    ADD CONSTRAINT discovery_categories_pkey PRIMARY KEY (id);


--
-- Name: driver_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY dispatches
    ADD CONSTRAINT driver_assignments_pkey PRIMARY KEY (id);


--
-- Name: driver_availabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY driver_availabilities
    ADD CONSTRAINT driver_availabilities_pkey PRIMARY KEY (id);


--
-- Name: driver_availability_blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY driver_availability_blocks
    ADD CONSTRAINT driver_availability_blocks_pkey PRIMARY KEY (id);


--
-- Name: driver_broadcasts_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY driver_broadcasts
    ADD CONSTRAINT driver_broadcasts_pkey PRIMARY KEY (id);


--
-- Name: driver_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY driver_locations
    ADD CONSTRAINT driver_locations_pkey PRIMARY KEY (id);


--
-- Name: driver_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY driver_messages
    ADD CONSTRAINT driver_messages_pkey PRIMARY KEY (id);


--
-- Name: driver_points_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY driver_points
    ADD CONSTRAINT driver_points_pkey PRIMARY KEY (id);


--
-- Name: driver_restaurant_bans_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY driver_restaurant_bans
    ADD CONSTRAINT driver_restaurant_bans_pkey PRIMARY KEY (id);


--
-- Name: driver_shifts_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY shift_assignments
    ADD CONSTRAINT driver_shifts_pkey PRIMARY KEY (id);


--
-- Name: driver_work_hours_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY driver_work_hours
    ADD CONSTRAINT driver_work_hours_pkey PRIMARY KEY (id);


--
-- Name: drivers_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY drivers
    ADD CONSTRAINT drivers_pkey PRIMARY KEY (id);


--
-- Name: estimation_model_feature_values_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY estimation_model_feature_values
    ADD CONSTRAINT estimation_model_feature_values_pkey PRIMARY KEY (id);


--
-- Name: estimation_model_features_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY estimation_model_features
    ADD CONSTRAINT estimation_model_features_pkey PRIMARY KEY (id);


--
-- Name: estimation_models_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY estimation_models
    ADD CONSTRAINT estimation_models_pkey PRIMARY KEY (id);


--
-- Name: favorite_restaurants_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY favorite_restaurants
    ADD CONSTRAINT favorite_restaurants_pkey PRIMARY KEY (id);


--
-- Name: franchise_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY franchise_contacts
    ADD CONSTRAINT franchise_contacts_pkey PRIMARY KEY (id);


--
-- Name: frequently_asked_question_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY frequently_asked_question_categories
    ADD CONSTRAINT frequently_asked_question_categories_pkey PRIMARY KEY (id);


--
-- Name: frequently_asked_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY frequently_asked_questions
    ADD CONSTRAINT frequently_asked_questions_pkey PRIMARY KEY (id);


--
-- Name: gift_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY gift_cards
    ADD CONSTRAINT gift_cards_pkey PRIMARY KEY (id);


--
-- Name: hosted_sites_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY hosted_sites
    ADD CONSTRAINT hosted_sites_pkey PRIMARY KEY (id);


--
-- Name: index_categories_on_menu_and_display_order; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_categories
    ADD CONSTRAINT index_categories_on_menu_and_display_order EXCLUDE USING btree (restaurant_id WITH =, display_order WITH =) WHERE ((parent_category_id IS NULL)) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: index_categories_on_menu_and_parent_and_display_order; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_categories
    ADD CONSTRAINT index_categories_on_menu_and_parent_and_display_order EXCLUDE USING btree (restaurant_id WITH =, parent_category_id WITH =, display_order WITH =) WHERE ((parent_category_id IS NOT NULL)) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: index_category_option_groups_on_category_and_display_order; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_category_option_groups
    ADD CONSTRAINT index_category_option_groups_on_category_and_display_order UNIQUE (menu_category_id, display_order) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE menu_category_option_groups CLUSTER ON index_category_option_groups_on_category_and_display_order;


--
-- Name: index_category_sizes_on_category_and_display_order; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_category_sizes
    ADD CONSTRAINT index_category_sizes_on_category_and_display_order UNIQUE (menu_category_id, display_order) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE menu_category_sizes CLUSTER ON index_category_sizes_on_category_and_display_order;


--
-- Name: index_item_descriptors_on_category_and_display_order; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_item_descriptors
    ADD CONSTRAINT index_item_descriptors_on_category_and_display_order UNIQUE (menu_item_id, display_order) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: index_item_option_groups_on_category_and_display_order; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_item_option_groups
    ADD CONSTRAINT index_item_option_groups_on_category_and_display_order UNIQUE (menu_item_id, display_order) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE menu_item_option_groups CLUSTER ON index_item_option_groups_on_category_and_display_order;


--
-- Name: index_items_on_category_and_display_order; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_items
    ADD CONSTRAINT index_items_on_category_and_display_order UNIQUE (category_id, display_order) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE menu_items CLUSTER ON index_items_on_category_and_display_order;


--
-- Name: index_menu_descriptors_on_menu_and_display_order; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_descriptors
    ADD CONSTRAINT index_menu_descriptors_on_menu_and_display_order UNIQUE (restaurant_id, display_order) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE menu_descriptors CLUSTER ON index_menu_descriptors_on_menu_and_display_order;


--
-- Name: index_menu_sizes_on_menu_and_display_order; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_sizes
    ADD CONSTRAINT index_menu_sizes_on_menu_and_display_order UNIQUE (restaurant_id, display_order) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE menu_sizes CLUSTER ON index_menu_sizes_on_menu_and_display_order;


--
-- Name: index_option_group_options_on_option_group_and_display_order; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY option_group_options
    ADD CONSTRAINT index_option_group_options_on_option_group_and_display_order UNIQUE (option_group_id, display_order) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE option_group_options CLUSTER ON index_option_group_options_on_option_group_and_display_order;


--
-- Name: index_option_groups_on_menu_and_display_order; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY option_groups
    ADD CONSTRAINT index_option_groups_on_menu_and_display_order UNIQUE (restaurant_id, display_order) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE option_groups CLUSTER ON index_option_groups_on_menu_and_display_order;


--
-- Name: item_option_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_item_option_groups
    ADD CONSTRAINT item_option_groups_pkey PRIMARY KEY (id);


--
-- Name: jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: loyalty_cash_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY loyalty_cash_transactions
    ADD CONSTRAINT loyalty_cash_transactions_pkey PRIMARY KEY (id);


--
-- Name: market_campus_payment_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY market_campus_payment_cards
    ADD CONSTRAINT market_campus_payment_cards_pkey PRIMARY KEY (id);


--
-- Name: market_cities_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY market_cities
    ADD CONSTRAINT market_cities_pkey PRIMARY KEY (id);


--
-- Name: market_dispatch_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY market_dispatch_notes
    ADD CONSTRAINT market_dispatch_notes_pkey PRIMARY KEY (id);


--
-- Name: market_scorecards_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY market_scorecards
    ADD CONSTRAINT market_scorecards_pkey PRIMARY KEY (id);


--
-- Name: market_weather_hours_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY market_weather_hours
    ADD CONSTRAINT market_weather_hours_pkey PRIMARY KEY (id);


--
-- Name: markets_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY markets
    ADD CONSTRAINT markets_pkey PRIMARY KEY (id);


--
-- Name: menu_category_option_group_option_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_category_option_group_option_prices
    ADD CONSTRAINT menu_category_option_group_option_prices_pkey PRIMARY KEY (id);


--
-- Name: menu_category_option_group_options_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_category_option_group_options
    ADD CONSTRAINT menu_category_option_group_options_pkey PRIMARY KEY (id);


--
-- Name: menu_category_sizes_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_category_sizes
    ADD CONSTRAINT menu_category_sizes_pkey PRIMARY KEY (id);


--
-- Name: menu_descriptors_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_descriptors
    ADD CONSTRAINT menu_descriptors_pkey PRIMARY KEY (id);


--
-- Name: menu_item_descriptors_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_item_descriptors
    ADD CONSTRAINT menu_item_descriptors_pkey PRIMARY KEY (id);


--
-- Name: menu_item_option_group_option_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_item_option_group_option_prices
    ADD CONSTRAINT menu_item_option_group_option_prices_pkey PRIMARY KEY (id);


--
-- Name: menu_item_option_group_options_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_item_option_group_options
    ADD CONSTRAINT menu_item_option_group_options_pkey PRIMARY KEY (id);


--
-- Name: menu_item_sizes_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_item_sizes
    ADD CONSTRAINT menu_item_sizes_pkey PRIMARY KEY (id);


--
-- Name: menu_items_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_items
    ADD CONSTRAINT menu_items_pkey PRIMARY KEY (id);


--
-- Name: menu_options_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_options
    ADD CONSTRAINT menu_options_pkey PRIMARY KEY (id);


--
-- Name: menu_sizes_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_sizes
    ADD CONSTRAINT menu_sizes_pkey PRIMARY KEY (id);


--
-- Name: menu_updates_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY menu_updates
    ADD CONSTRAINT menu_updates_pkey PRIMARY KEY (id);


--
-- Name: monthly_order_counts_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY monthly_order_counts
    ADD CONSTRAINT monthly_order_counts_pkey PRIMARY KEY (id);


--
-- Name: notification_schedule_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY notification_schedule_changes
    ADD CONSTRAINT notification_schedule_changes_pkey PRIMARY KEY (id);


--
-- Name: option_group_option_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY option_group_option_prices
    ADD CONSTRAINT option_group_option_prices_pkey PRIMARY KEY (id);


--
-- Name: option_group_options_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY option_group_options
    ADD CONSTRAINT option_group_options_pkey PRIMARY KEY (id);


--
-- Name: option_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY option_groups
    ADD CONSTRAINT option_groups_pkey PRIMARY KEY (id);


--
-- Name: order_coupons_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY order_coupons
    ADD CONSTRAINT order_coupons_pkey PRIMARY KEY (id);


--
-- Name: order_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY order_notifications
    ADD CONSTRAINT order_notifications_pkey PRIMARY KEY (id);


--
-- Name: orders_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: payments_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: pex_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY pex_transactions
    ADD CONSTRAINT pex_transactions_pkey PRIMARY KEY (id);


--
-- Name: print_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY print_menus
    ADD CONSTRAINT print_menus_pkey PRIMARY KEY (id);


--
-- Name: promo_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY promo_codes
    ADD CONSTRAINT promo_codes_pkey PRIMARY KEY (id);


--
-- Name: receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY receipts
    ADD CONSTRAINT receipts_pkey PRIMARY KEY (id);


--
-- Name: referral_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY referral_codes
    ADD CONSTRAINT referral_codes_pkey PRIMARY KEY (id);


--
-- Name: referrals_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY referrals
    ADD CONSTRAINT referrals_pkey PRIMARY KEY (id);


--
-- Name: reliability_score_events_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY reliability_score_events
    ADD CONSTRAINT reliability_score_events_pkey PRIMARY KEY (id);


--
-- Name: restaurant_account_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY pay_period_account_entries
    ADD CONSTRAINT restaurant_account_entries_pkey PRIMARY KEY (id);


--
-- Name: restaurant_campus_payment_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY restaurant_campus_payment_cards
    ADD CONSTRAINT restaurant_campus_payment_cards_pkey PRIMARY KEY (id);


--
-- Name: restaurant_categorizations_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY restaurant_categorizations
    ADD CONSTRAINT restaurant_categorizations_pkey PRIMARY KEY (id);


--
-- Name: restaurant_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY restaurant_contacts
    ADD CONSTRAINT restaurant_contacts_pkey PRIMARY KEY (id);


--
-- Name: restaurant_delivery_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY restaurant_delivery_zones
    ADD CONSTRAINT restaurant_delivery_zones_pkey PRIMARY KEY (id);


--
-- Name: restaurant_drive_times_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY restaurant_drive_times
    ADD CONSTRAINT restaurant_drive_times_pkey PRIMARY KEY (id);


--
-- Name: restaurant_hours_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY restaurant_hours
    ADD CONSTRAINT restaurant_hours_pkey PRIMARY KEY (id);


--
-- Name: restaurant_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY restaurant_requests
    ADD CONSTRAINT restaurant_requests_pkey PRIMARY KEY (id);


--
-- Name: restaurant_temporary_hours_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY restaurant_temporary_hours
    ADD CONSTRAINT restaurant_temporary_hours_pkey PRIMARY KEY (id);


--
-- Name: restaurant_users_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY restaurant_users
    ADD CONSTRAINT restaurant_users_pkey PRIMARY KEY (id);


--
-- Name: restaurants_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY restaurants
    ADD CONSTRAINT restaurants_pkey PRIMARY KEY (id);


--
-- Name: scorecards_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY scorecards
    ADD CONSTRAINT scorecards_pkey PRIMARY KEY (id);


--
-- Name: settings_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: shift_assignment_delivery_service_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY shift_assignment_delivery_service_changes
    ADD CONSTRAINT shift_assignment_delivery_service_changes_pkey PRIMARY KEY (id);


--
-- Name: shift_calculations_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY shift_predictions
    ADD CONSTRAINT shift_calculations_pkey PRIMARY KEY (id);


--
-- Name: shift_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY shift_templates
    ADD CONSTRAINT shift_templates_pkey PRIMARY KEY (id);


--
-- Name: shifts_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY shifts
    ADD CONSTRAINT shifts_pkey PRIMARY KEY (id);


--
-- Name: shutdown_group_restaurants_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY shutdown_group_restaurants
    ADD CONSTRAINT shutdown_group_restaurants_pkey PRIMARY KEY (id);


--
-- Name: shutdown_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY shutdown_groups
    ADD CONSTRAINT shutdown_groups_pkey PRIMARY KEY (id);


--
-- Name: shutdown_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY shutdown_messages
    ADD CONSTRAINT shutdown_messages_pkey PRIMARY KEY (id);


--
-- Name: sign_up_links_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY sign_up_links
    ADD CONSTRAINT sign_up_links_pkey PRIMARY KEY (id);


--
-- Name: sms_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY sms_messages
    ADD CONSTRAINT sms_messages_pkey PRIMARY KEY (id);


--
-- Name: sms_number_reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY sms_number_reservations
    ADD CONSTRAINT sms_number_reservations_pkey PRIMARY KEY (id);


--
-- Name: sms_numbers_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY sms_numbers
    ADD CONSTRAINT sms_numbers_pkey PRIMARY KEY (id);


--
-- Name: specials_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY specials
    ADD CONSTRAINT specials_pkey PRIMARY KEY (id);


--
-- Name: subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: surveys_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY surveys
    ADD CONSTRAINT surveys_pkey PRIMARY KEY (id);


--
-- Name: temporary_shutdowns_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY temporary_shutdowns
    ADD CONSTRAINT temporary_shutdowns_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: voice_calls_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY voice_calls
    ADD CONSTRAINT voice_calls_pkey PRIMARY KEY (id);


--
-- Name: work_segments_pkey; Type: CONSTRAINT; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

ALTER TABLE ONLY work_segments
    ADD CONSTRAINT work_segments_pkey PRIMARY KEY (id);


--
-- Name: estimation_model_feature_values_fk_idx; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX estimation_model_feature_values_fk_idx ON estimation_model_feature_values USING btree (estimation_model_feature_id);


--
-- Name: idx_restaurant_delivery_zones_points; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX idx_restaurant_delivery_zones_points ON restaurant_delivery_zones USING gist (points);


--
-- Name: index_active_cart_counts_on_created_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_active_cart_counts_on_created_at ON active_cart_counts USING btree (created_at);


--
-- Name: index_active_cart_counts_on_delivery_service_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_active_cart_counts_on_delivery_service_id ON active_cart_counts USING btree (delivery_service_id);


--
-- Name: index_adjustments_on_order_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_adjustments_on_order_id ON adjustments USING btree (order_id);


--
-- Name: index_adjustments_on_restaurant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_adjustments_on_restaurant_id ON adjustments USING btree (restaurant_id);


--
-- Name: index_affiliates_on_market_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_affiliates_on_market_id ON affiliates USING btree (market_id);


--
-- Name: index_affiliates_on_market_id_and_name; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_affiliates_on_market_id_and_name ON affiliates USING btree (market_id, name);


--
-- Name: index_audits_on_market_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_audits_on_market_id ON audits USING btree (market_id);


--
-- Name: index_audits_on_restaurant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_audits_on_restaurant_id ON audits USING btree (restaurant_id);


--
-- Name: index_audits_on_subject_id_and_subject_type; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_audits_on_subject_id_and_subject_type ON audits USING btree (subject_id, subject_type);


--
-- Name: index_banner_ads_on_market_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_banner_ads_on_market_id ON banner_ads USING btree (market_id);


--
-- Name: index_banner_ads_on_market_id_and_name; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_banner_ads_on_market_id_and_name ON banner_ads USING btree (market_id, name);


--
-- Name: index_banner_ads_on_restaurant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_banner_ads_on_restaurant_id ON banner_ads USING btree (restaurant_id);


--
-- Name: index_blacklisted_email_addresses_on_email; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_blacklisted_email_addresses_on_email ON blacklisted_email_addresses USING btree (email);


--
-- Name: index_blacklisted_email_domains_on_domain; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_blacklisted_email_domains_on_domain ON blacklisted_email_domains USING btree (domain);


--
-- Name: index_blacklisted_ip_addresses_on_ip_address; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_blacklisted_ip_addresses_on_ip_address ON blacklisted_ip_addresses USING btree (ip_address);


--
-- Name: index_blacklisted_phone_numbers_on_phone; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_blacklisted_phone_numbers_on_phone ON blacklisted_phone_numbers USING btree (phone);


--
-- Name: index_building_groups_on_name; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_building_groups_on_name ON building_groups USING btree (name);


--
-- Name: index_buildings_on_building_group_id_and_name; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_buildings_on_building_group_id_and_name ON buildings USING btree (building_group_id, name);


--
-- Name: index_canonicalized_json_menus_on_restaurant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_canonicalized_json_menus_on_restaurant_id ON canonicalized_json_menus USING btree (restaurant_id);


--
-- Name: index_canonicalized_menus_on_restaurant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_canonicalized_menus_on_restaurant_id ON canonicalized_menus USING btree (restaurant_id);


--
-- Name: index_cart_coupons_on_cart_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_cart_coupons_on_cart_id ON cart_coupons USING btree (cart_id);


--
-- Name: index_cart_coupons_on_cart_id_and_coupon_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_cart_coupons_on_cart_id_and_coupon_id ON cart_coupons USING btree (cart_id, coupon_id);


--
-- Name: index_cart_item_options_on_cart_item_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_cart_item_options_on_cart_item_id ON cart_item_options USING btree (cart_item_id);


--
-- Name: index_cart_items_on_cart_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_cart_items_on_cart_id ON cart_items USING btree (cart_id);


--
-- Name: index_cart_items_on_cart_participant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_cart_items_on_cart_participant_id ON cart_items USING btree (cart_participant_id);


--
-- Name: index_cart_items_on_coupon_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_cart_items_on_coupon_id ON cart_items USING btree (coupon_id);


--
-- Name: index_cart_items_on_menu_item_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_cart_items_on_menu_item_id ON cart_items USING btree (menu_item_id);


--
-- Name: index_cart_items_on_updated_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_cart_items_on_updated_at ON cart_items USING btree (updated_at);


--
-- Name: index_carts_on_order_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_carts_on_order_id ON carts USING btree (order_id);


--
-- Name: index_carts_on_token; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_carts_on_token ON carts USING btree (token);


--
-- Name: index_categories_on_menu; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_categories_on_menu ON menu_categories USING btree (restaurant_id);

ALTER TABLE menu_categories CLUSTER ON index_categories_on_menu;


--
-- Name: index_category_option_groups_on_category_parent_client_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_category_option_groups_on_category_parent_client_id ON menu_category_option_groups USING btree (menu_category_id, option_group_id, client_id);


--
-- Name: index_category_option_price_on_category_option_and_option_price; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_category_option_price_on_category_option_and_option_price ON menu_category_option_group_option_prices USING btree (menu_category_option_group_option_id, option_group_option_price_id);

ALTER TABLE menu_category_option_group_option_prices CLUSTER ON index_category_option_price_on_category_option_and_option_price;


--
-- Name: index_category_options_on_category_option_group_and_option; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_category_options_on_category_option_group_and_option ON menu_category_option_group_options USING btree (menu_category_option_group_id, option_group_option_id);

ALTER TABLE menu_category_option_group_options CLUSTER ON index_category_options_on_category_option_group_and_option;


--
-- Name: index_cohort_memberships_on_cohort_id_and_customer_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_cohort_memberships_on_cohort_id_and_customer_id ON cohort_memberships USING btree (cohort_id, customer_id);


--
-- Name: index_cohort_service_cohorts_on_cohort_id_and_cohort_service_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_cohort_service_cohorts_on_cohort_id_and_cohort_service_id ON cohort_service_cohorts USING btree (cohort_id, cohort_service_id);


--
-- Name: index_cohort_services_on_type; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_cohort_services_on_type ON cohort_services USING btree (type);


--
-- Name: index_cohorts_on_type; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_cohorts_on_type ON cohorts USING btree (type);


--
-- Name: index_coupons_on_coupon_type; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_coupons_on_coupon_type ON coupons USING btree (coupon_type);


--
-- Name: index_credit_batch_errors_on_credit_batch_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_credit_batch_errors_on_credit_batch_id ON credit_batch_errors USING btree (credit_batch_id);


--
-- Name: index_credit_batches_on_market_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_credit_batches_on_market_id ON credit_batches USING btree (market_id);


--
-- Name: index_credit_cards_on_customer_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_credit_cards_on_customer_id ON credit_cards USING btree (customer_id);


--
-- Name: index_credit_cards_on_external_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_credit_cards_on_external_id ON credit_cards USING btree (external_id);


--
-- Name: index_credit_cards_on_saved; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_credit_cards_on_saved ON credit_cards USING btree (saved);


--
-- Name: index_credit_cards_on_unique_number_identifier; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_credit_cards_on_unique_number_identifier ON credit_cards USING btree (unique_number_identifier);


--
-- Name: index_credit_items_on_accounting_category; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_credit_items_on_accounting_category ON credit_items USING btree (accounting_category);


--
-- Name: index_credit_items_on_accounting_reason; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_credit_items_on_accounting_reason ON credit_items USING btree (accounting_reason);


--
-- Name: index_credit_items_on_credit_batch_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_credit_items_on_credit_batch_id ON credit_items USING btree (credit_batch_id);


--
-- Name: index_credit_items_on_customer_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_credit_items_on_customer_id ON credit_items USING btree (customer_id);


--
-- Name: index_credit_items_on_expires_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_credit_items_on_expires_at ON credit_items USING btree (expires_at);


--
-- Name: index_credit_items_on_market_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_credit_items_on_market_id ON credit_items USING btree (market_id);


--
-- Name: index_credit_items_on_order_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_credit_items_on_order_id ON credit_items USING btree (order_id);


--
-- Name: index_credit_items_on_reason; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_credit_items_on_reason ON credit_items USING btree (reason);


--
-- Name: index_customer_addresses_on_building_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_customer_addresses_on_building_id ON customer_addresses USING btree (building_id);


--
-- Name: index_customer_addresses_on_customer_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_customer_addresses_on_customer_id ON customer_addresses USING btree (customer_id);


--
-- Name: index_customer_addresses_on_customer_id_and_is_default; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_customer_addresses_on_customer_id_and_is_default ON customer_addresses USING btree (customer_id, is_default) WHERE (is_default IS TRUE);


--
-- Name: index_customer_addresses_on_device_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_customer_addresses_on_device_id ON customer_addresses USING btree (device_id);


--
-- Name: index_customer_addresses_on_last_ordered_at_and_updated_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_customer_addresses_on_last_ordered_at_and_updated_at ON customer_addresses USING btree (last_ordered_at, updated_at);


--
-- Name: index_customer_addresses_on_market_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_customer_addresses_on_market_id ON customer_addresses USING btree (market_id);


--
-- Name: index_customer_coupon_uses_on_coupon_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_customer_coupon_uses_on_coupon_id ON customer_coupon_uses USING btree (coupon_id);


--
-- Name: index_customer_coupon_uses_on_customer_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_customer_coupon_uses_on_customer_id ON customer_coupon_uses USING btree (customer_id);


--
-- Name: index_customer_coupon_uses_on_customer_id_and_coupon_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_customer_coupon_uses_on_customer_id_and_coupon_id ON customer_coupon_uses USING btree (customer_id, coupon_id);


--
-- Name: index_customer_phones_on_phone; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_customer_phones_on_phone ON customer_phones USING btree (phone);


--
-- Name: index_customer_phones_on_sign_up_referrer_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_customer_phones_on_sign_up_referrer_id ON customer_phones USING btree (sign_up_referrer_id);


--
-- Name: index_customers_on_email; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_customers_on_email ON customers USING btree (email);


--
-- Name: index_customers_on_ip_address; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_customers_on_ip_address ON customers USING btree (ip_address);


--
-- Name: index_customers_on_rel; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_customers_on_rel ON customers USING btree (rel);


--
-- Name: index_daily_order_counts_on_orderable_id_and_orderable_type; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_daily_order_counts_on_orderable_id_and_orderable_type ON daily_order_counts USING btree (orderable_id, orderable_type);


--
-- Name: index_deliveries_on_access_token; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_deliveries_on_access_token ON deliveries USING btree (access_token);


--
-- Name: index_deliveries_on_created_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_deliveries_on_created_at ON deliveries USING btree (created_at);


--
-- Name: index_deliveries_on_delivery_service_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_deliveries_on_delivery_service_id ON deliveries USING btree (delivery_service_id);


--
-- Name: index_deliveries_on_order_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_deliveries_on_order_id ON deliveries USING btree (order_id);


--
-- Name: index_deliveries_on_should_dispatch_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_deliveries_on_should_dispatch_at ON deliveries USING btree (should_dispatch_at);


--
-- Name: index_deliveries_on_status; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_deliveries_on_status ON deliveries USING btree (status);


--
-- Name: index_deliveries_on_test_order; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_deliveries_on_test_order ON deliveries USING btree (test_order);


--
-- Name: index_delivery_estimates_on_delivery_id_and_type; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_delivery_estimates_on_delivery_id_and_type ON delivery_estimates USING btree (delivery_id, type);


--
-- Name: index_delivery_log_entries_on_created_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_delivery_log_entries_on_created_at ON delivery_log_entries USING btree (created_at);


--
-- Name: index_delivery_log_entries_on_delivery_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_delivery_log_entries_on_delivery_id ON delivery_log_entries USING btree (delivery_id);


--
-- Name: index_delivery_service_changes_on_shift_assignment_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_delivery_service_changes_on_shift_assignment_id ON shift_assignment_delivery_service_changes USING btree (shift_assignment_id);


--
-- Name: index_delivery_service_health_models_on_created_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_delivery_service_health_models_on_created_at ON delivery_service_health_models USING btree (created_at);


--
-- Name: index_delivery_service_health_models_on_delivery_service_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_delivery_service_health_models_on_delivery_service_id ON delivery_service_health_models USING btree (delivery_service_id);


--
-- Name: index_delivery_service_health_scores_on_health_model_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_delivery_service_health_scores_on_health_model_id ON delivery_service_health_scores USING btree (health_model_id);


--
-- Name: index_delivery_service_random_forests_on_created_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_delivery_service_random_forests_on_created_at ON delivery_service_random_forests USING btree (created_at);


--
-- Name: index_delivery_service_random_forests_on_delivery_service_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_delivery_service_random_forests_on_delivery_service_id ON delivery_service_random_forests USING btree (delivery_service_id);


--
-- Name: index_delivery_status_updates_on_delivery_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_delivery_status_updates_on_delivery_id ON delivery_status_updates USING btree (delivery_id);


--
-- Name: index_delivery_status_updates_on_driver_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_delivery_status_updates_on_driver_id ON delivery_status_updates USING btree (driver_id);


--
-- Name: index_delivery_status_updates_on_order_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_delivery_status_updates_on_order_id ON delivery_status_updates USING btree (order_id);


--
-- Name: index_delivery_steps_on_completed_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_delivery_steps_on_completed_at ON delivery_steps USING btree (completed_at);


--
-- Name: index_delivery_steps_on_created_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_delivery_steps_on_created_at ON delivery_steps USING btree (created_at);


--
-- Name: index_delivery_steps_on_delivery_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_delivery_steps_on_delivery_id ON delivery_steps USING btree (delivery_id);


--
-- Name: index_delivery_steps_on_driver_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_delivery_steps_on_driver_id ON delivery_steps USING btree (driver_id);


--
-- Name: index_delivery_steps_on_late_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_delivery_steps_on_late_at ON delivery_steps USING btree (late_at);


--
-- Name: index_delivery_zones_on_area_geometry; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_delivery_zones_on_area_geometry ON delivery_zones USING gist (area_geometry);


--
-- Name: index_delivery_zones_on_radius_geometry; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_delivery_zones_on_radius_geometry ON delivery_zones USING gist (radius_geometry);


--
-- Name: index_devices_on_customer_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_devices_on_customer_id ON devices USING btree (customer_id);


--
-- Name: index_devices_on_uid; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_devices_on_uid ON devices USING btree (uid);


--
-- Name: index_dispatches_on_deleted_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_dispatches_on_deleted_at ON dispatches USING btree (deleted_at);


--
-- Name: index_dispatches_on_delivery_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_dispatches_on_delivery_id ON dispatches USING btree (delivery_id);


--
-- Name: index_dispatches_on_driver_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_dispatches_on_driver_id ON dispatches USING btree (driver_id);


--
-- Name: index_driver_availabilities_on_driver_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_driver_availabilities_on_driver_id ON driver_availabilities USING btree (driver_id);


--
-- Name: index_driver_availability_blocks_on_driver_availability_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_driver_availability_blocks_on_driver_availability_id ON driver_availability_blocks USING btree (driver_availability_id);


--
-- Name: index_driver_broadcasts_on_delivery_service_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_driver_broadcasts_on_delivery_service_id ON driver_broadcasts USING btree (delivery_service_id);


--
-- Name: index_driver_broadcasts_on_market_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_driver_broadcasts_on_market_id ON driver_broadcasts USING btree (market_id);


--
-- Name: index_driver_locations_on_driver_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_driver_locations_on_driver_id ON driver_locations USING btree (driver_id);


--
-- Name: index_driver_locations_on_hour; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_driver_locations_on_hour ON driver_locations USING btree (hour);


--
-- Name: index_driver_locations_on_platform; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_driver_locations_on_platform ON driver_locations USING btree (platform);


--
-- Name: index_driver_messages_on_created_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_driver_messages_on_created_at ON driver_messages USING btree (created_at);


--
-- Name: index_driver_messages_on_driver_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_driver_messages_on_driver_id ON driver_messages USING btree (driver_id);


--
-- Name: index_driver_messages_on_provider; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_driver_messages_on_provider ON driver_messages USING btree (provider);


--
-- Name: index_driver_messages_on_sid; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_driver_messages_on_sid ON driver_messages USING btree (sid);


--
-- Name: index_driver_points_on_driver_id_and_delivery_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_driver_points_on_driver_id_and_delivery_id ON driver_points USING btree (driver_id, delivery_id);


--
-- Name: index_driver_restaurant_bans_on_driver_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_driver_restaurant_bans_on_driver_id ON driver_restaurant_bans USING btree (driver_id);


--
-- Name: index_driver_restaurant_bans_on_restaurant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_driver_restaurant_bans_on_restaurant_id ON driver_restaurant_bans USING btree (restaurant_id);


--
-- Name: index_driver_work_hours_on_delivery_service_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_driver_work_hours_on_delivery_service_id ON driver_work_hours USING btree (delivery_service_id);


--
-- Name: index_driver_work_hours_on_shift_assignment_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_driver_work_hours_on_shift_assignment_id ON driver_work_hours USING btree (shift_assignment_id);


--
-- Name: index_driver_work_hours_on_worked_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_driver_work_hours_on_worked_at ON driver_work_hours USING btree (worked_at);


--
-- Name: index_drivers_on_customer_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_drivers_on_customer_id ON drivers USING btree (customer_id);


--
-- Name: index_drivers_on_delivery_service_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_drivers_on_delivery_service_id ON drivers USING btree (delivery_service_id);


--
-- Name: index_drivers_on_market_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_drivers_on_market_id ON drivers USING btree (market_id);


--
-- Name: index_estimation_model_feature_values_on_created_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_estimation_model_feature_values_on_created_at ON estimation_model_feature_values USING btree (created_at);


--
-- Name: index_estimation_model_features_on_delivery_service_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_estimation_model_features_on_delivery_service_id ON estimation_model_features USING btree (delivery_service_id);


--
-- Name: index_estimation_model_features_on_estimation_model_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_estimation_model_features_on_estimation_model_id ON estimation_model_features USING btree (estimation_model_id);


--
-- Name: index_faq_categories_on_display_order_and_show_on; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_faq_categories_on_display_order_and_show_on ON frequently_asked_question_categories USING btree (display_order, show_on);


--
-- Name: index_faqs_on_display_order_and_faq_category_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_faqs_on_display_order_and_faq_category_id ON frequently_asked_questions USING btree (display_order, frequently_asked_question_category_id);


--
-- Name: index_favorite_restaurants_on_customer_id_and_restaurant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_favorite_restaurants_on_customer_id_and_restaurant_id ON favorite_restaurants USING btree (customer_id, restaurant_id);


--
-- Name: index_gift_cards_on_code; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_gift_cards_on_code ON gift_cards USING btree (code);


--
-- Name: index_gift_cards_on_credit_item_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_gift_cards_on_credit_item_id ON gift_cards USING btree (credit_item_id);


--
-- Name: index_hosted_sites_on_restaurant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_hosted_sites_on_restaurant_id ON hosted_sites USING btree (restaurant_id);


--
-- Name: index_item_descriptor_on_item_and_menu_descriptor; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_item_descriptor_on_item_and_menu_descriptor ON menu_item_descriptors USING btree (menu_item_id, menu_descriptor_id);

ALTER TABLE menu_item_descriptors CLUSTER ON index_item_descriptor_on_item_and_menu_descriptor;


--
-- Name: index_item_option_groups_on_item_parent_client_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_item_option_groups_on_item_parent_client_id ON menu_item_option_groups USING btree (menu_item_id, option_group_id, client_id);


--
-- Name: index_item_option_price_on_item_option_and_option_price; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_item_option_price_on_item_option_and_option_price ON menu_item_option_group_option_prices USING btree (menu_item_option_group_option_id, option_group_option_price_id);

ALTER TABLE menu_item_option_group_option_prices CLUSTER ON index_item_option_price_on_item_option_and_option_price;


--
-- Name: index_item_options_on_item_option_group_and_option; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_item_options_on_item_option_group_and_option ON menu_item_option_group_options USING btree (menu_item_option_group_id, option_group_option_id);

ALTER TABLE menu_item_option_group_options CLUSTER ON index_item_options_on_item_option_group_and_option;


--
-- Name: index_loyalty_cash_transactions_on_customer_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_loyalty_cash_transactions_on_customer_id ON loyalty_cash_transactions USING btree (customer_id);


--
-- Name: index_loyalty_cash_transactions_on_order_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_loyalty_cash_transactions_on_order_id ON loyalty_cash_transactions USING btree (order_id);


--
-- Name: index_loyalty_cash_transactions_on_restaurant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_loyalty_cash_transactions_on_restaurant_id ON loyalty_cash_transactions USING btree (restaurant_id);


--
-- Name: index_market_campus_payment_cards_on_campus_payment_card_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_market_campus_payment_cards_on_campus_payment_card_id ON market_campus_payment_cards USING btree (campus_payment_card_id);


--
-- Name: index_market_campus_payment_cards_on_market_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_market_campus_payment_cards_on_market_id ON market_campus_payment_cards USING btree (market_id);


--
-- Name: index_market_cities_on_market_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_market_cities_on_market_id ON market_cities USING btree (market_id);


--
-- Name: index_market_cities_on_market_id_and_name; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_market_cities_on_market_id_and_name ON market_cities USING btree (market_id, name);


--
-- Name: index_market_cities_on_market_id_and_slug; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_market_cities_on_market_id_and_slug ON market_cities USING btree (market_id, slug);


--
-- Name: index_market_dispatch_notes_on_market_id_and_created_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_market_dispatch_notes_on_market_id_and_created_at ON market_dispatch_notes USING btree (market_id, created_at);


--
-- Name: index_market_weather_hours_on_market_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_market_weather_hours_on_market_id ON market_weather_hours USING btree (market_id);


--
-- Name: index_markets_on_domain; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_markets_on_domain ON markets USING btree (domain);


--
-- Name: index_markets_on_name; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_markets_on_name ON markets USING btree (name);


--
-- Name: index_markets_on_slug; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_markets_on_slug ON markets USING btree (slug);


--
-- Name: index_maxmind_geolite_city_blocks_on_end_ip_num_range; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_maxmind_geolite_city_blocks_on_end_ip_num_range ON maxmind_geolite_city_blocks USING btree (end_ip_num, start_ip_num);


--
-- Name: index_maxmind_geolite_city_blocks_on_loc_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_maxmind_geolite_city_blocks_on_loc_id ON maxmind_geolite_city_blocks USING btree (loc_id);


--
-- Name: index_maxmind_geolite_city_blocks_on_start_ip_num; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_maxmind_geolite_city_blocks_on_start_ip_num ON maxmind_geolite_city_blocks USING btree (start_ip_num);


--
-- Name: index_maxmind_geolite_city_location_on_loc_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_maxmind_geolite_city_location_on_loc_id ON maxmind_geolite_city_location USING btree (loc_id);


--
-- Name: index_menu_category_sizes_on_menu_category_id_and_menu_size_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_menu_category_sizes_on_menu_category_id_and_menu_size_id ON menu_category_sizes USING btree (menu_category_id, menu_size_id);


--
-- Name: index_menu_descriptors_on_restaurant_id_and_name; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_menu_descriptors_on_restaurant_id_and_name ON menu_descriptors USING btree (restaurant_id, name);


--
-- Name: index_menu_item_sizes_on_menu_item_id_and_menu_size_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_menu_item_sizes_on_menu_item_id_and_menu_size_id ON menu_item_sizes USING btree (menu_item_id, menu_size_id);

ALTER TABLE menu_item_sizes CLUSTER ON index_menu_item_sizes_on_menu_item_id_and_menu_size_id;


--
-- Name: index_menu_options_on_restaurant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_menu_options_on_restaurant_id ON menu_options USING btree (restaurant_id);


--
-- Name: index_menu_sizes_on_restaurant_id_and_name; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_menu_sizes_on_restaurant_id_and_name ON menu_sizes USING btree (restaurant_id, name);


--
-- Name: index_monthly_order_counts_on_market_id_and_year_and_month; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_monthly_order_counts_on_market_id_and_year_and_month ON monthly_order_counts USING btree (market_id, year, month);


--
-- Name: index_notification_schedule_changes_on_driver_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_notification_schedule_changes_on_driver_id ON notification_schedule_changes USING btree (driver_id);


--
-- Name: index_notification_schedule_changes_on_performed_by_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_notification_schedule_changes_on_performed_by_id ON notification_schedule_changes USING btree (performed_by_id);


--
-- Name: index_option_group_option_prices_on_option_id_and_menu_size_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_option_group_option_prices_on_option_id_and_menu_size_id ON option_group_option_prices USING btree (option_group_option_id, menu_size_id);

ALTER TABLE option_group_option_prices CLUSTER ON index_option_group_option_prices_on_option_id_and_menu_size_id;


--
-- Name: index_option_group_options_on_option_group_id_and_name; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_option_group_options_on_option_group_id_and_name ON option_group_options USING btree (option_group_id, name);


--
-- Name: index_option_groups_on_restaurant_id_and_name; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_option_groups_on_restaurant_id_and_name ON option_groups USING btree (restaurant_id, name);


--
-- Name: index_order_coupons_on_coupon_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_order_coupons_on_coupon_id ON order_coupons USING btree (coupon_id);


--
-- Name: index_order_coupons_on_customer_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_order_coupons_on_customer_id ON order_coupons USING btree (customer_id);


--
-- Name: index_order_coupons_on_order_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_order_coupons_on_order_id ON order_coupons USING btree (order_id);


--
-- Name: index_order_coupons_on_order_item_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_order_coupons_on_order_item_id ON order_coupons USING btree (order_item_id);


--
-- Name: index_order_notifications_on_confirmation_token; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_order_notifications_on_confirmation_token ON order_notifications USING btree (confirmation_token);


--
-- Name: index_order_notifications_on_created_at_and_status; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_order_notifications_on_created_at_and_status ON order_notifications USING btree (created_at, status);


--
-- Name: index_order_notifications_on_order_id_and_type; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_order_notifications_on_order_id_and_type ON order_notifications USING btree (order_id, type);


--
-- Name: index_order_notifications_on_provider; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_order_notifications_on_provider ON order_notifications USING btree (provider);


--
-- Name: index_order_notifications_on_provider_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_order_notifications_on_provider_id ON order_notifications USING btree (provider_id);


--
-- Name: index_order_notifications_on_type; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_order_notifications_on_type ON order_notifications USING btree (type);


--
-- Name: index_orders_on_cart_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_orders_on_cart_id ON orders USING btree (cart_id);


--
-- Name: index_orders_on_created_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_orders_on_created_at ON orders USING btree (created_at);


--
-- Name: index_orders_on_customer_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_orders_on_customer_id ON orders USING btree (customer_id);


--
-- Name: index_orders_on_deliver_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_orders_on_deliver_at ON orders USING btree (deliver_at);


--
-- Name: index_orders_on_delivery_address_zip_code; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_orders_on_delivery_address_zip_code ON orders USING btree (((delivery_address ->> 'zip_code'::text)));


--
-- Name: index_orders_on_fulfilled_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_orders_on_fulfilled_at ON orders USING btree (fulfilled_at);


--
-- Name: index_orders_on_ip_address; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_orders_on_ip_address ON orders USING btree (ip_address);


--
-- Name: index_orders_on_orderup_delivered; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_orders_on_orderup_delivered ON orders USING btree (orderup_delivered);


--
-- Name: index_orders_on_rel; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_orders_on_rel ON orders USING btree (rel);


--
-- Name: index_orders_on_restaurant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_orders_on_restaurant_id ON orders USING btree (restaurant_id);


--
-- Name: index_orders_on_source; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_orders_on_source ON orders USING btree (source);


--
-- Name: index_orders_on_status; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_orders_on_status ON orders USING btree (status);


--
-- Name: index_orders_on_test; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_orders_on_test ON orders USING btree (test);


--
-- Name: index_orders_payments_on_order_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_orders_payments_on_order_id ON orders_payments USING btree (order_id);


--
-- Name: index_orders_payments_on_payment_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_orders_payments_on_payment_id ON orders_payments USING btree (payment_id);


--
-- Name: index_pay_period_account_entries_on_account_owner_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_pay_period_account_entries_on_account_owner_id ON pay_period_account_entries USING btree (account_owner_id);


--
-- Name: index_pex_transactions_on_transaction_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_pex_transactions_on_transaction_id ON pex_transactions USING btree (transaction_id);


--
-- Name: index_print_menus_on_restaurant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_print_menus_on_restaurant_id ON print_menus USING btree (restaurant_id);


--
-- Name: index_print_menus_on_restaurant_id_and_display_order; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_print_menus_on_restaurant_id_and_display_order ON print_menus USING btree (restaurant_id, display_order);


--
-- Name: index_promo_codes_on_code; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_promo_codes_on_code ON promo_codes USING btree (code);


--
-- Name: index_promo_codes_on_promotable_id_and_promotable_type; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_promo_codes_on_promotable_id_and_promotable_type ON promo_codes USING btree (promotable_id, promotable_type);


--
-- Name: index_receipts_on_order_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_receipts_on_order_id ON receipts USING btree (order_id);


--
-- Name: index_referral_codes_on_code; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_referral_codes_on_code ON referral_codes USING btree (code);


--
-- Name: index_referral_codes_on_customer_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_referral_codes_on_customer_id ON referral_codes USING btree (customer_id);


--
-- Name: index_referral_codes_on_market_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_referral_codes_on_market_id ON referral_codes USING btree (market_id);


--
-- Name: index_referrals_on_fingerprint; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_referrals_on_fingerprint ON referrals USING btree (fingerprint);


--
-- Name: index_referrals_on_invitee_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_referrals_on_invitee_id ON referrals USING btree (invitee_id);


--
-- Name: index_referrals_on_inviter_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_referrals_on_inviter_id ON referrals USING btree (inviter_id);


--
-- Name: index_referrals_on_ip_address; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_referrals_on_ip_address ON referrals USING btree (ip_address);


--
-- Name: index_referrals_on_order_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_referrals_on_order_id ON referrals USING btree (order_id);


--
-- Name: index_referrals_on_phone; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_referrals_on_phone ON referrals USING btree (phone);


--
-- Name: index_reliability_score_events_on_shift_assignment_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_reliability_score_events_on_shift_assignment_id ON reliability_score_events USING btree (shift_assignment_id);


--
-- Name: index_restaurant_campus_payment_cards_on_campus_payment_card_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_restaurant_campus_payment_cards_on_campus_payment_card_id ON restaurant_campus_payment_cards USING btree (campus_payment_card_id);


--
-- Name: index_restaurant_campus_payment_cards_on_restaurant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_restaurant_campus_payment_cards_on_restaurant_id ON restaurant_campus_payment_cards USING btree (restaurant_id);


--
-- Name: index_restaurant_categories_on_slug; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_restaurant_categories_on_slug ON restaurant_categories USING btree (slug);


--
-- Name: index_restaurant_categorizations; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_restaurant_categorizations ON restaurant_categorizations USING btree (restaurant_id, restaurant_category_id);


--
-- Name: index_restaurant_categorizations_on_restaurant_category_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_restaurant_categorizations_on_restaurant_category_id ON restaurant_categorizations USING btree (restaurant_category_id);


--
-- Name: index_restaurant_categorizations_on_restaurant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_restaurant_categorizations_on_restaurant_id ON restaurant_categorizations USING btree (restaurant_id);


--
-- Name: index_restaurant_contacts_on_market_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_restaurant_contacts_on_market_id ON restaurant_contacts USING btree (market_id);


--
-- Name: index_restaurant_delivery_zones_on_restaurant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_restaurant_delivery_zones_on_restaurant_id ON restaurant_delivery_zones USING btree (restaurant_id);


--
-- Name: index_restaurant_hours_on_hours_owner_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_restaurant_hours_on_hours_owner_id ON restaurant_hours USING btree (hours_owner_id);


--
-- Name: index_restaurant_hours_on_hours_owner_type; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_restaurant_hours_on_hours_owner_type ON restaurant_hours USING btree (hours_owner_type);


--
-- Name: index_restaurant_hours_on_restaurant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_restaurant_hours_on_restaurant_id ON restaurant_hours USING btree (restaurant_id);


--
-- Name: index_restaurant_hours_on_restaurant_temporary_hour_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_restaurant_hours_on_restaurant_temporary_hour_id ON restaurant_hours USING btree (restaurant_temporary_hour_id);


--
-- Name: index_restaurant_temporary_hours_on_hours_owner_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_restaurant_temporary_hours_on_hours_owner_id ON restaurant_temporary_hours USING btree (hours_owner_id);


--
-- Name: index_restaurant_temporary_hours_on_hours_owner_type; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_restaurant_temporary_hours_on_hours_owner_type ON restaurant_temporary_hours USING btree (hours_owner_type);


--
-- Name: index_restaurant_temporary_hours_on_restaurant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_restaurant_temporary_hours_on_restaurant_id ON restaurant_temporary_hours USING btree (restaurant_id);


--
-- Name: index_restaurant_users_on_restaurant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_restaurant_users_on_restaurant_id ON restaurant_users USING btree (restaurant_id);


--
-- Name: index_restaurant_users_on_user_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_restaurant_users_on_user_id ON restaurant_users USING btree (user_id);


--
-- Name: index_restaurants_on_delivery_service_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_restaurants_on_delivery_service_id ON restaurants USING btree (delivery_service_id);


--
-- Name: index_restaurants_on_market_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_restaurants_on_market_id ON restaurants USING btree (market_id);


--
-- Name: index_restaurants_on_name; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_restaurants_on_name ON restaurants USING btree (name);


--
-- Name: index_restaurants_on_slug; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_restaurants_on_slug ON restaurants USING btree (slug);


--
-- Name: index_shift_assignments_on_driver_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_shift_assignments_on_driver_id ON shift_assignments USING btree (driver_id);


--
-- Name: index_shift_assignments_on_driver_id_and_shift_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_shift_assignments_on_driver_id_and_shift_id ON shift_assignments USING btree (driver_id, shift_id);


--
-- Name: index_shift_assignments_on_shift_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_shift_assignments_on_shift_id ON shift_assignments USING btree (shift_id);


--
-- Name: index_shift_predictions_on_shift_id_and_delivery_service_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_shift_predictions_on_shift_id_and_delivery_service_id ON shift_predictions USING btree (shift_id, delivery_service_id);


--
-- Name: index_shift_templates_on_market_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_shift_templates_on_market_id ON shift_templates USING btree (market_id);


--
-- Name: index_shifts_on_correct_ends_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_shifts_on_correct_ends_at ON shifts USING btree (correct_ends_at);


--
-- Name: index_shifts_on_correct_starts_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_shifts_on_correct_starts_at ON shifts USING btree (correct_starts_at);


--
-- Name: index_shifts_on_market_id_and_starts_at_and_ends_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_shifts_on_market_id_and_starts_at_and_ends_at ON shifts USING btree (market_id, starts_at, ends_at);


--
-- Name: index_shifts_on_starts_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_shifts_on_starts_at ON shifts USING btree (starts_at);


--
-- Name: index_shutdown_group_restaurants_on_restaurant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_shutdown_group_restaurants_on_restaurant_id ON shutdown_group_restaurants USING btree (restaurant_id);


--
-- Name: index_shutdown_group_restaurants_on_shutdown_group_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_shutdown_group_restaurants_on_shutdown_group_id ON shutdown_group_restaurants USING btree (shutdown_group_id);


--
-- Name: index_shutdown_messages_on_archived; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_shutdown_messages_on_archived ON shutdown_messages USING btree (archived);


--
-- Name: index_shutdown_messages_on_automatic; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_shutdown_messages_on_automatic ON shutdown_messages USING btree (automatic);


--
-- Name: index_sign_up_links_on_customer_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_sign_up_links_on_customer_id ON sign_up_links USING btree (customer_id);


--
-- Name: index_sign_up_links_on_email_address; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_sign_up_links_on_email_address ON sign_up_links USING btree (email_address);


--
-- Name: index_sign_up_links_on_phone_number; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_sign_up_links_on_phone_number ON sign_up_links USING btree (phone_number);


--
-- Name: index_sms_messages_on_sms_number_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_sms_messages_on_sms_number_id ON sms_messages USING btree (sms_number_id);


--
-- Name: index_sms_number_reservations_on_sms_number_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_sms_number_reservations_on_sms_number_id ON sms_number_reservations USING btree (sms_number_id);


--
-- Name: index_sms_number_reservations_on_sms_number_id_and_hour; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_sms_number_reservations_on_sms_number_id_and_hour ON sms_number_reservations USING btree (sms_number_id, hour);


--
-- Name: index_sms_numbers_on_number; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_sms_numbers_on_number ON sms_numbers USING btree (number);


--
-- Name: index_specials_on_restaurant_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_specials_on_restaurant_id ON specials USING btree (restaurant_id);


--
-- Name: index_subscriptions_on_subscriptionable; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_subscriptions_on_subscriptionable ON subscriptions USING btree (subscriptionable_id, subscriptionable_type);


--
-- Name: index_subscriptions_on_uniqueness_keys; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX index_subscriptions_on_uniqueness_keys ON subscriptions USING btree (subscriptionable_id, subscriptionable_type, report_type);


--
-- Name: index_temporary_shutdowns_on_deleted_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_temporary_shutdowns_on_deleted_at ON temporary_shutdowns USING btree (deleted_at);


--
-- Name: index_work_segments_on_delivery_service_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_work_segments_on_delivery_service_id ON work_segments USING btree (delivery_service_id);


--
-- Name: index_work_segments_on_driver_id; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_work_segments_on_driver_id ON work_segments USING btree (driver_id);


--
-- Name: index_work_segments_on_ended_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_work_segments_on_ended_at ON work_segments USING btree (ended_at);


--
-- Name: index_work_segments_on_started_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX index_work_segments_on_started_at ON work_segments USING btree (started_at);


--
-- Name: market_campus_payment_cards_unique; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX market_campus_payment_cards_unique ON market_campus_payment_cards USING btree (market_id, campus_payment_card_id);


--
-- Name: orders_coalesce_override_ready_at_estimated_ready_at; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX orders_coalesce_override_ready_at_estimated_ready_at ON orders USING btree ((COALESCE(override_ready_at, estimated_ready_at)));


--
-- Name: orders_coalesce_ready_time_idx; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE INDEX orders_coalesce_ready_time_idx ON orders USING btree ((COALESCE(override_ready_at, estimated_ready_at)));


--
-- Name: pay_period_account_entries_unique; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX pay_period_account_entries_unique ON pay_period_account_entries USING btree (account_owner_id, account_owner_type, period_started_at, period_ended_at);


--
-- Name: restaurant_campus_payment_cards_unique; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX restaurant_campus_payment_cards_unique ON restaurant_campus_payment_cards USING btree (restaurant_id, campus_payment_card_id);


--
-- Name: restaurant_hours_unique; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX restaurant_hours_unique ON restaurant_hours USING btree (restaurant_id, restaurant_temporary_hour_id, order_type, day_of_week, start_time);


--
-- Name: restaurant_temporary_hours_unique; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX restaurant_temporary_hours_unique ON restaurant_temporary_hours USING btree (restaurant_id, order_type, starts_at);


--
-- Name: temporary_shutdowns_prevent_overlap; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX temporary_shutdowns_prevent_overlap ON temporary_shutdowns USING btree (date_trunc('minute'::text, (start_time + '00:00:30'::interval)), delivery_service_id, deleted_at) WHERE ((state)::text = ANY ((ARRAY['effective'::character varying, 'scheduled'::character varying])::text[]));


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: uc0o9etll61111; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: cart_coupons_cart_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY cart_coupons
    ADD CONSTRAINT cart_coupons_cart_id_fk FOREIGN KEY (cart_id) REFERENCES carts(id);


--
-- Name: cart_coupons_coupon_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY cart_coupons
    ADD CONSTRAINT cart_coupons_coupon_id_fk FOREIGN KEY (coupon_id) REFERENCES coupons(id);


--
-- Name: cart_items_cart_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY cart_items
    ADD CONSTRAINT cart_items_cart_id_fk FOREIGN KEY (cart_id) REFERENCES carts(id);


--
-- Name: cart_items_coupon_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY cart_items
    ADD CONSTRAINT cart_items_coupon_id_fk FOREIGN KEY (coupon_id) REFERENCES coupons(id);


--
-- Name: categories_restaurant_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_categories
    ADD CONSTRAINT categories_restaurant_id_fk FOREIGN KEY (restaurant_id) REFERENCES restaurants(id);


--
-- Name: category_option_group_option_price_category_option_group_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_category_option_group_option_prices
    ADD CONSTRAINT category_option_group_option_price_category_option_group_fk FOREIGN KEY (menu_category_option_group_option_id) REFERENCES menu_category_option_group_options(id) ON DELETE CASCADE;


--
-- Name: category_option_group_option_price_option_price_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_category_option_group_option_prices
    ADD CONSTRAINT category_option_group_option_price_option_price_fk FOREIGN KEY (option_group_option_price_id) REFERENCES option_group_option_prices(id);


--
-- Name: category_option_group_options_category_option_group_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_category_option_group_options
    ADD CONSTRAINT category_option_group_options_category_option_group_fk FOREIGN KEY (menu_category_option_group_id) REFERENCES menu_category_option_groups(id) ON DELETE CASCADE;


--
-- Name: category_option_group_options_option_group_option_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_category_option_group_options
    ADD CONSTRAINT category_option_group_options_option_group_option_fk FOREIGN KEY (option_group_option_id) REFERENCES option_group_options(id);


--
-- Name: category_option_groups_option_group_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_category_option_groups
    ADD CONSTRAINT category_option_groups_option_group_id_fk FOREIGN KEY (option_group_id) REFERENCES option_groups(id);


--
-- Name: cohort_memberships_cohort_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY cohort_memberships
    ADD CONSTRAINT cohort_memberships_cohort_id_fk FOREIGN KEY (cohort_id) REFERENCES cohorts(id) ON DELETE CASCADE;


--
-- Name: cohort_memberships_customer_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY cohort_memberships
    ADD CONSTRAINT cohort_memberships_customer_id_fk FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE;


--
-- Name: cohort_service_cohorts_cohort_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY cohort_service_cohorts
    ADD CONSTRAINT cohort_service_cohorts_cohort_id_fk FOREIGN KEY (cohort_id) REFERENCES cohorts(id) ON DELETE CASCADE;


--
-- Name: cohort_service_cohorts_cohort_service_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY cohort_service_cohorts
    ADD CONSTRAINT cohort_service_cohorts_cohort_service_id_fk FOREIGN KEY (cohort_service_id) REFERENCES cohort_services(id) ON DELETE CASCADE;


--
-- Name: customer_coupon_uses_coupon_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY customer_coupon_uses
    ADD CONSTRAINT customer_coupon_uses_coupon_id_fk FOREIGN KEY (coupon_id) REFERENCES coupons(id);


--
-- Name: customer_coupon_uses_customer_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY customer_coupon_uses
    ADD CONSTRAINT customer_coupon_uses_customer_id_fk FOREIGN KEY (customer_id) REFERENCES customers(id);


--
-- Name: delivery_estimates_delivery_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY delivery_estimates
    ADD CONSTRAINT delivery_estimates_delivery_id_fk FOREIGN KEY (delivery_id) REFERENCES deliveries(id) ON DELETE CASCADE;


--
-- Name: driver_messages_author_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY driver_messages
    ADD CONSTRAINT driver_messages_author_id_fk FOREIGN KEY (author_id) REFERENCES customers(id);


--
-- Name: driver_messages_driver_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY driver_messages
    ADD CONSTRAINT driver_messages_driver_id_fk FOREIGN KEY (driver_id) REFERENCES drivers(id);


--
-- Name: drivers_delivery_service_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY drivers
    ADD CONSTRAINT drivers_delivery_service_id_fk FOREIGN KEY (delivery_service_id) REFERENCES delivery_services(id);


--
-- Name: favorite_restaurants_customer_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY favorite_restaurants
    ADD CONSTRAINT favorite_restaurants_customer_id_fk FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE;


--
-- Name: favorite_restaurants_restaurant_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY favorite_restaurants
    ADD CONSTRAINT favorite_restaurants_restaurant_id_fk FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE;


--
-- Name: hosted_sites_restaurant_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY hosted_sites
    ADD CONSTRAINT hosted_sites_restaurant_id_fk FOREIGN KEY (restaurant_id) REFERENCES restaurants(id);


--
-- Name: item_option_group_option_price_item_option_group_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_item_option_group_option_prices
    ADD CONSTRAINT item_option_group_option_price_item_option_group_fk FOREIGN KEY (menu_item_option_group_option_id) REFERENCES menu_item_option_group_options(id) ON DELETE CASCADE;


--
-- Name: item_option_group_option_price_option_price_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_item_option_group_option_prices
    ADD CONSTRAINT item_option_group_option_price_option_price_fk FOREIGN KEY (option_group_option_price_id) REFERENCES option_group_option_prices(id);


--
-- Name: item_option_group_options_item_option_group_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_item_option_group_options
    ADD CONSTRAINT item_option_group_options_item_option_group_fk FOREIGN KEY (menu_item_option_group_id) REFERENCES menu_item_option_groups(id) ON DELETE CASCADE;


--
-- Name: item_option_group_options_option_group_option_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_item_option_group_options
    ADD CONSTRAINT item_option_group_options_option_group_option_fk FOREIGN KEY (option_group_option_id) REFERENCES option_group_options(id);


--
-- Name: item_option_groups_option_group_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_item_option_groups
    ADD CONSTRAINT item_option_groups_option_group_id_fk FOREIGN KEY (option_group_id) REFERENCES option_groups(id);


--
-- Name: menu_categories_parent_category_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_categories
    ADD CONSTRAINT menu_categories_parent_category_id_fk FOREIGN KEY (parent_category_id) REFERENCES menu_categories(id) ON DELETE CASCADE;


--
-- Name: menu_category_option_groups_menu_category_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_category_option_groups
    ADD CONSTRAINT menu_category_option_groups_menu_category_id_fk FOREIGN KEY (menu_category_id) REFERENCES menu_categories(id) ON DELETE CASCADE;


--
-- Name: menu_category_sizes_menu_category_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_category_sizes
    ADD CONSTRAINT menu_category_sizes_menu_category_id_fk FOREIGN KEY (menu_category_id) REFERENCES menu_categories(id) ON DELETE CASCADE;


--
-- Name: menu_category_sizes_menu_size_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_category_sizes
    ADD CONSTRAINT menu_category_sizes_menu_size_id_fk FOREIGN KEY (menu_size_id) REFERENCES menu_sizes(id);


--
-- Name: menu_descriptors_restaurant_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_descriptors
    ADD CONSTRAINT menu_descriptors_restaurant_id_fk FOREIGN KEY (restaurant_id) REFERENCES restaurants(id);


--
-- Name: menu_item_descriptors_menu_descriptor_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_item_descriptors
    ADD CONSTRAINT menu_item_descriptors_menu_descriptor_id_fk FOREIGN KEY (menu_descriptor_id) REFERENCES menu_descriptors(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: menu_item_descriptors_menu_item_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_item_descriptors
    ADD CONSTRAINT menu_item_descriptors_menu_item_id_fk FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE;


--
-- Name: menu_item_option_groups_menu_item_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_item_option_groups
    ADD CONSTRAINT menu_item_option_groups_menu_item_id_fk FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE;


--
-- Name: menu_item_sizes_menu_item_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_item_sizes
    ADD CONSTRAINT menu_item_sizes_menu_item_id_fk FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE;


--
-- Name: menu_item_sizes_menu_size_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_item_sizes
    ADD CONSTRAINT menu_item_sizes_menu_size_id_fk FOREIGN KEY (menu_size_id) REFERENCES menu_sizes(id);


--
-- Name: menu_items_category_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_items
    ADD CONSTRAINT menu_items_category_id_fk FOREIGN KEY (category_id) REFERENCES menu_categories(id) ON DELETE CASCADE;


--
-- Name: menu_options_restaurant_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_options
    ADD CONSTRAINT menu_options_restaurant_id_fk FOREIGN KEY (restaurant_id) REFERENCES restaurants(id);


--
-- Name: menu_sizes_restaurant_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY menu_sizes
    ADD CONSTRAINT menu_sizes_restaurant_id_fk FOREIGN KEY (restaurant_id) REFERENCES restaurants(id);


--
-- Name: option_group_option_prices_menu_size_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY option_group_option_prices
    ADD CONSTRAINT option_group_option_prices_menu_size_id_fk FOREIGN KEY (menu_size_id) REFERENCES menu_sizes(id);


--
-- Name: option_group_option_prices_option_group_option_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY option_group_option_prices
    ADD CONSTRAINT option_group_option_prices_option_group_option_id_fk FOREIGN KEY (option_group_option_id) REFERENCES option_group_options(id) ON DELETE CASCADE;


--
-- Name: option_group_options_option_group_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY option_group_options
    ADD CONSTRAINT option_group_options_option_group_id_fk FOREIGN KEY (option_group_id) REFERENCES option_groups(id) ON DELETE CASCADE;


--
-- Name: option_groups_restaurant_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY option_groups
    ADD CONSTRAINT option_groups_restaurant_id_fk FOREIGN KEY (restaurant_id) REFERENCES restaurants(id);


--
-- Name: orders_customer_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY orders
    ADD CONSTRAINT orders_customer_id_fk FOREIGN KEY (customer_id) REFERENCES customers(id);


--
-- Name: orders_restaurant_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY orders
    ADD CONSTRAINT orders_restaurant_id_fk FOREIGN KEY (restaurant_id) REFERENCES restaurants(id);


--
-- Name: restaurants_market_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY restaurants
    ADD CONSTRAINT restaurants_market_id_fk FOREIGN KEY (market_id) REFERENCES markets(id);


--
-- Name: shift_calculations_delivery_service_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY shift_predictions
    ADD CONSTRAINT shift_calculations_delivery_service_id_fk FOREIGN KEY (delivery_service_id) REFERENCES delivery_services(id) ON DELETE CASCADE;


--
-- Name: shift_calculations_shift_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: uc0o9etll61111
--

ALTER TABLE ONLY shift_predictions
    ADD CONSTRAINT shift_calculations_shift_id_fk FOREIGN KEY (shift_id) REFERENCES shifts(id) ON DELETE CASCADE;


--
-- Name: public; Type: ACL; Schema: -; Owner: uc0o9etll61111
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM uc0o9etll61111;
GRANT ALL ON SCHEMA public TO uc0o9etll61111;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

