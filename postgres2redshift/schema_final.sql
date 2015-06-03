SET search_path TO migration_temp;


 CREATE TABLE active_cart_counts (
     id integer NOT NULL,
     count integer,
     delivery_service_id integer NOT NULL,
     created_at timestamp without time zone,
     window_minutes integer
 ) sortkey(id);

 CREATE TABLE adjustments (
     id integer NOT NULL,
     memo character varying(255),
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
 ) sortkey(id);

 CREATE TABLE affiliates (
     id integer NOT NULL,
     market_id integer NOT NULL,
     name character varying(255),
     commission_percentage numeric(19,4) NOT NULL,
     active boolean NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     restaurant_id integer
 ) sortkey(id);

 CREATE TABLE april_fools_responses (
     id integer NOT NULL,
     customer_id integer,
     data json DEFAULT '{}'::text NOT NULL,
     created_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE audits (
     id integer NOT NULL,
     market_id integer,
     restaurant_id integer,
     admin_email character varying(255),
     action character varying(255),
     subject_id integer NOT NULL,
     subject_type character varying(255),
     change_data json,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     subject_name character varying(255)
 ) sortkey(id);

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
 ) sortkey(id);

 CREATE TABLE beacons (
     id integer NOT NULL,
     market_id integer,
     latitude numeric(9,6) DEFAULT 0 NOT NULL,
     longitude numeric(9,6) DEFAULT 0 NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE blacklisted_email_addresses (
     id integer NOT NULL,
     email character varying(255),
     memo character varying(255)
 ) sortkey(id);

 CREATE TABLE blacklisted_email_domains (
     id integer NOT NULL,
     domain character varying(255),
     memo character varying(255)
 ) sortkey(id);

 CREATE TABLE blacklisted_ip_addresses (
     id integer NOT NULL,
     ip_address character varying(255),
     memo character varying(255)
 ) sortkey(id);

 CREATE TABLE blacklisted_phone_numbers (
     id integer NOT NULL,
     phone character varying(255),
     memo character varying(255)
 ) sortkey(id);

 CREATE TABLE blazer_audits (
     id integer NOT NULL,
     user_id integer,
     query_id integer,
     statement varchar(max),
     created_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE blazer_queries (
     id integer NOT NULL,
     creator_id integer,
     name character varying(255),
     description varchar(max),
     statement varchar(max),
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE building_groups (
     id integer NOT NULL,
     name character varying(255),
     market_id integer
 ) sortkey(id);

 CREATE TABLE buildings (
     id integer NOT NULL,
     name character varying(255),
     address_format character varying(255),
     city character varying(255),
     state character varying(255),
     zip character varying(255),
     latitude numeric(9,6) NOT NULL,
     longitude numeric(9,6) NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     building_group_id integer
 ) sortkey(id);

 CREATE TABLE campus_payment_cards (
     id integer NOT NULL,
     name character varying(255),
     number_digits integer,
     pin_digits integer,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     enabled boolean DEFAULT true
 ) sortkey(id);

 CREATE TABLE canonicalized_json_menus (
     id integer NOT NULL,
     restaurant_id integer,
     data json,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     last_queued_at timestamp without time zone,
     last_published_at timestamp without time zone,
     change_count integer DEFAULT 0 NOT NULL
 ) sortkey(id);

 CREATE TABLE canonicalized_menus (
     id integer NOT NULL,
     restaurant_id integer,
     data json,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     change_count integer DEFAULT 0 NOT NULL
 ) sortkey(id);

 CREATE TABLE cart_coupons (
     id integer NOT NULL,
     cart_id integer NOT NULL,
     coupon_id integer NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(coupon_id, id, cart_id);

 CREATE TABLE cart_item_options (
     id integer NOT NULL,
     cart_item_id integer NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     quantity integer DEFAULT 1 NOT NULL,
     option_group_id character varying(255),
     option_group_option_id character varying(255),
     half integer DEFAULT 3 NOT NULL
 ) sortkey(id);

 CREATE TABLE cart_items (
     id integer NOT NULL,
     cart_id integer NOT NULL,
     quantity integer DEFAULT 1 NOT NULL,
     special_instructions varchar(max),
     label_for character varying(255),
     size_id character varying(255),
     coupon_id integer,
     menu_item_id integer NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     cart_participant_id integer
 ) sortkey(coupon_id, id, cart_id);

 CREATE TABLE cart_participants (
     id integer NOT NULL,
     done_ordering_at timestamp without time zone,
     cart_id integer,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     customer_id integer,
     device_id character varying(255)
 ) sortkey(id);

 CREATE TABLE carts (
     id integer NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     customer_id integer,
     restaurant_id integer NOT NULL,
     device_id character varying(255),
     order_type character varying(255) DEFAULT 'delivery'::character varying,
     customer_address_id integer,
     order_id integer,
     token character varying(255),
     group_order boolean DEFAULT false,
     deliver_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE cohort_memberships (
     id integer NOT NULL,
     cohort_id integer NOT NULL,
     customer_id integer NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     variant_type character varying(255)
 ) sortkey(cohort_id, customer_id, id);

 CREATE TABLE cohort_service_cohorts (
     id integer NOT NULL,
     cohort_id integer NOT NULL,
     cohort_service_id integer NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     a_variant_id bigint,
     b_variant_id bigint,
     control_variant_id bigint
 ) sortkey(cohort_id, cohort_service_id, id);

 CREATE TABLE cohort_services (
     id integer NOT NULL,
     type character varying(255),
     access_token varchar(max),
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE cohorts (
     id integer NOT NULL,
     type character varying(255),
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE content (
     key character varying(255),
     value varchar(max)
 ) sortkey(key);

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
     description varchar(max),
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
 ) sortkey(id);

 CREATE TABLE credit_batch_errors (
     id integer NOT NULL,
     credit_batch_id integer,
     email character varying(255),
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE credit_batches (
     id integer NOT NULL,
     market_id integer,
     reason character varying(255),
     amount numeric(19,2) NOT NULL,
     memo character varying(255),
     expires_at timestamp without time zone,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     hq_funded boolean,
     customer_id integer
 ) sortkey(id);

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
 ) sortkey(id);

 CREATE TABLE credit_items (
     id integer NOT NULL,
     customer_id integer NOT NULL,
     credit_batch_id integer,
     market_id integer,
     order_id integer,
     reason character varying(255),
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
 ) sortkey(id);

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
 ) sortkey(id);

 CREATE TABLE customer_campus_cards (
     id integer NOT NULL,
     campus_payment_card_name character varying(255),
     description character varying(255),
     campus_payment_card_id integer,
     customer_id integer,
     card_number character varying(255),
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE customer_coupon_uses (
     id integer NOT NULL,
     customer_id integer NOT NULL,
     coupon_id integer NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     uses integer
 ) sortkey(customer_id, id, coupon_id);

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
 ) sortkey(id);

 CREATE TABLE customer_phones (
     id integer NOT NULL,
     code character varying(255),
     message_id character varying(255),
     zip character varying(255),
     state character varying(255),
     city character varying(255),
     country character varying(255),
     phone character varying(255),
     customer_id integer NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     sign_up_referrer_type character varying(255),
     sign_up_referrer_id integer
 ) sortkey(id);

 CREATE TABLE customers (
     id integer NOT NULL,
     first_name character varying(255),
     last_name character varying(255),
     phone character varying(255),
     email character varying(255),
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
 ) sortkey(id);

 CREATE TABLE daily_order_counts (
     id integer NOT NULL,
     orderable_id integer NOT NULL,
     orderable_type character varying(255),
     day date NOT NULL,
     orders integer NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE deliveries (
     id integer NOT NULL,
     order_id integer,
     access_token character varying(255),
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
 ) sortkey(id);

 CREATE TABLE deliveries_hours (
     id integer NOT NULL,
     hour_at timestamp without time zone,
     delivery_id integer,
     percent_delivery_in_hour numeric,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE delivery_comments (
     id integer NOT NULL,
     delivery_step_id integer,
     note character varying(255),
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

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
     type character varying(255),
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     estimation_model_id integer,
     feature_values json
 ) sortkey(delivery_id, id);

 CREATE TABLE delivery_log_entries (
     id integer NOT NULL,
     delivery_id integer NOT NULL,
     customer_id integer,
     type character varying(255),
     data varchar(max),
     created_at timestamp without time zone NOT NULL
 ) sortkey(id);

 CREATE TABLE delivery_service_health_features (
     id integer NOT NULL,
     created_at timestamp without time zone NOT NULL,
     updated_at timestamp without time zone NOT NULL,
     delivery_service_id integer NOT NULL,
     version integer NOT NULL,
     "values" varchar(max)
 ) sortkey(id);

 CREATE TABLE delivery_service_health_models (
     id integer NOT NULL,
     delivery_service_id integer NOT NULL,
     created_at timestamp without time zone,
     digest character varying(255)
 ) sortkey(id);

 CREATE TABLE delivery_service_health_scores (
     id integer NOT NULL,
     health_model_id integer,
     score numeric,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE delivery_service_random_forests (
     id integer NOT NULL,
     delivery_service_id integer NOT NULL,
     created_at timestamp without time zone
 ) sortkey(id);

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
 ) sortkey(id);

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
     notes varchar(max),
     status varchar(max),
     urgency character varying(255) DEFAULT 'primary'::character varying,
     hq_approved boolean DEFAULT false NOT NULL,
     blurb varchar(max)
 ) sortkey(id);

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
 ) sortkey(id);

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
 ) sortkey(id);

 CREATE TABLE delivery_zones (
     id integer NOT NULL,
     area varchar(max),
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
 ) sortkey(id);

 CREATE TABLE devices (
     id integer NOT NULL,
     platform character varying(255),
     uid character varying(255),
     allowed_to_redeem boolean DEFAULT true NOT NULL,
     customer_id integer
 ) sortkey(id);

 CREATE TABLE dispatches (
     id integer NOT NULL,
     driver_id integer,
     delivery_id integer,
     status character varying(255),
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     deleted_at timestamp without time zone,
     pex_card_funded_at timestamp without time zone
 ) sortkey(id);

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
 ) sortkey(id);

 CREATE TABLE driver_availability_blocks (
     id integer NOT NULL,
     driver_availability_id integer,
     starts_at timestamp without time zone,
     ends_at timestamp without time zone,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE driver_broadcasts (
     id integer NOT NULL,
     message varchar(max),
     market_id integer,
     delivery_service_id integer,
     approved boolean,
     available boolean,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

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
 ) sortkey(id);

 CREATE TABLE driver_messages (
     id integer NOT NULL,
     content varchar(max),
     driver_id integer NOT NULL,
     author_id integer,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     provider character varying(255),
     sid character varying(255),
     data json,
     read_at timestamp without time zone,
     read_by_id integer
 ) sortkey(author_id, driver_id, id);

 CREATE TABLE driver_points (
     id integer NOT NULL,
     driver_id integer NOT NULL,
     delivery_id integer,
     points integer NOT NULL,
     earned_at timestamp without time zone,
     reason character varying(255),
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE driver_restaurant_bans (
     id integer NOT NULL,
     driver_id integer NOT NULL,
     restaurant_id integer NOT NULL,
     created_by integer NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

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
 ) sortkey(id);

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
     gear_number varchar(max),
     gear_updated_at timestamp without time zone,
     deliveries_count_offset integer DEFAULT 0 NOT NULL,
     use_confirm_dialogs boolean DEFAULT true,
     default_map_app character varying(255),
     reliability_score_weekly numeric(7,6)
 ) sortkey(id, delivery_service_id);

 CREATE TABLE estimation_model_feature_values (
     id integer NOT NULL,
     estimation_model_feature_id integer,
     value numeric,
     created_at timestamp without time zone
 ) sortkey(id);

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
 ) sortkey(id);

 CREATE TABLE estimation_models (
     id integer NOT NULL,
     name character varying(255),
     version integer,
     active boolean,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE favorite_restaurants (
     id integer NOT NULL,
     customer_id integer NOT NULL,
     restaurant_id integer NOT NULL
 ) sortkey(restaurant_id, customer_id, id);

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
     reason_why varchar(max),
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE frequently_asked_question_categories (
     id integer NOT NULL,
     display_order integer,
     name character varying(255),
     show_on integer DEFAULT 0
 ) sortkey(id);

 CREATE TABLE frequently_asked_questions (
     id integer NOT NULL,
     question varchar(max),
     answer varchar(max),
     display_order integer,
     category character varying(255),
     frequently_asked_question_category_id integer
 ) sortkey(id);

 CREATE TABLE gift_cards (
     id integer NOT NULL,
     credit_item_id integer,
     code character varying(255),
     amount integer,
     message varchar(max),
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
 ) sortkey(id);

 CREATE TABLE hosted_sites (
     id integer NOT NULL,
     domain_name character varying(255),
     theme character varying(255),
     palette character varying(255),
     restaurant_id integer,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     icons varchar(max),
     registration_status character varying(255),
     auto_renew boolean DEFAULT true NOT NULL
 ) sortkey(restaurant_id, id);

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
     description varchar(max),
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE loyalty_cash_transactions (
     id integer NOT NULL,
     customer_id integer NOT NULL,
     restaurant_id integer NOT NULL,
     order_id integer,
     amount numeric(8,2),
     reason character varying(255),
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE orders (
     id integer NOT NULL,
     details varchar(max),
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     restaurant_id integer NOT NULL,
     payment_type character varying(255),
     status character varying(255),
     source character varying(255),
     test boolean DEFAULT false NOT NULL,
     customer_id integer,
     payment_details json,
     delivery_address json,
     special_instructions varchar(max),
     food_receipt_type character varying(255),
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
     platform character varying(255) DEFAULT 'desktop'::character varying,
     customer_order_number integer DEFAULT 1 NOT NULL,
     credit_card_id integer,
     updated_by character varying(255),
     updated_reason varchar(max),
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
 ) sortkey(restaurant_id, customer_id, id);

 CREATE TABLE restaurants (
     id integer NOT NULL,
     name character varying(255),
     market_id integer NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     time_zone character varying(255),
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
     notification_email character varying(255)[] DEFAULT '{}'::character varying[],
     delivery boolean DEFAULT false NOT NULL,
     takeout boolean DEFAULT false NOT NULL,
     top_products json DEFAULT '[]'::text NOT NULL,
     slug character varying(255),
     twitter_handle character varying(255),
     facebook_username character varying(255),
     delivery_service character varying(255),
     yelp_id character varying(255),
     promotional_message varchar(max),
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
     has_drinks_key_words varchar(max),
     cached_daily_order_counts_list character varying(255),
     delivery_instructions varchar(max),
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
 ) sortkey(market_id, id);

 CREATE TABLE market_campus_payment_cards (
     id integer NOT NULL,
     market_id integer NOT NULL,
     campus_payment_card_id integer NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE market_cities (
     id integer NOT NULL,
     market_id integer NOT NULL,
     name character varying(255),
     state character varying(255),
     slug character varying(255),
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE market_dispatch_notes (
     id integer NOT NULL,
     author_id integer NOT NULL,
     market_id integer NOT NULL,
     content varchar(max),
     created_at timestamp without time zone NOT NULL
 ) sortkey(id);

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
 ) sortkey(id);

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
 ) sortkey(id);

 CREATE TABLE markets (
     id integer NOT NULL,
     name character varying(255),
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     time_zone character varying(255),
     market_style character varying(255) DEFAULT 'order_up'::character varying,
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
     conversion_tracking_html varchar(max),
     alternate_discovery_view character varying(255),
     geocode_bounds varchar(max),
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
     customer_survey_url varchar(max),
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
     delivery_support_slack_team character varying(255) DEFAULT 'orderup'::character varying,
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
 ) sortkey(id);

 CREATE TABLE maxmind_geolite_city_blocks (
     start_ip_num bigint NOT NULL,
     end_ip_num bigint NOT NULL,
     loc_id bigint NOT NULL
 );

 CREATE TABLE maxmind_geolite_city_location (
     loc_id bigint NOT NULL,
     country character varying(255),
     region character varying(255),
     city character varying(255),
     postal_code character varying(255),
     latitude double precision,
     longitude double precision,
     metro_code integer,
     area_code integer
 );

 CREATE TABLE menu_categories (
     id integer NOT NULL,
     restaurant_id integer NOT NULL,
     name character varying(255),
     description varchar(max),
     order_type character varying(255),
     display_order integer NOT NULL,
     parent_category_id integer,
     timesets varchar(max),
     inherit_option_groups boolean NOT NULL,
     visible boolean NOT NULL,
     available boolean NOT NULL,
     size_type character varying(255),
     fulfilled_by_delivery_service boolean NOT NULL,
     order_for_later_lead_time integer
 ) sortkey(restaurant_id, id, parent_category_id);

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
 ) sortkey(menu_category_option_group_option_id, option_group_option_price_id, id);

 CREATE TABLE menu_category_option_group_options (
     id integer NOT NULL,
     menu_category_option_group_id integer NOT NULL,
     option_group_option_id integer NOT NULL,
     enabled boolean,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(option_group_option_id, id, menu_category_option_group_id);

 CREATE TABLE menu_category_option_groups (
     id integer NOT NULL,
     menu_category_id integer NOT NULL,
     option_group_id integer NOT NULL,
     display_name character varying(255),
     half_sizes boolean,
     restriction json,
     allows_selection_repetition boolean,
     display_order integer NOT NULL,
     client_id character varying(255)
 ) sortkey(menu_category_id, display_order, id, option_group_id);

 CREATE TABLE menu_category_sizes (
     id integer NOT NULL,
     menu_category_id integer NOT NULL,
     menu_size_id integer NOT NULL,
     display_order integer NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(menu_category_id, menu_size_id, display_order, id);

 CREATE TABLE menu_descriptors (
     id integer NOT NULL,
     restaurant_id integer NOT NULL,
     name character varying(255),
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     display_order integer NOT NULL
 ) sortkey(restaurant_id, display_order, id);

 CREATE TABLE menu_item_descriptors (
     id integer NOT NULL,
     menu_item_id integer NOT NULL,
     menu_descriptor_id integer NOT NULL,
     display_order integer NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(display_order, menu_item_id, id, menu_descriptor_id);

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
 ) sortkey(option_group_option_price_id, menu_item_option_group_option_id, id);

 CREATE TABLE menu_item_option_group_options (
     id integer NOT NULL,
     menu_item_option_group_id integer NOT NULL,
     option_group_option_id integer NOT NULL,
     enabled boolean,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(menu_item_option_group_id, id, option_group_option_id);

 CREATE TABLE menu_item_option_groups (
     id integer NOT NULL,
     menu_item_id integer NOT NULL,
     option_group_id integer NOT NULL,
     display_name character varying(255),
     half_sizes boolean,
     restriction json,
     allows_selection_repetition boolean,
     display_order integer NOT NULL,
     client_id character varying(255)
 ) sortkey(display_order, menu_item_id, id, option_group_id);

 CREATE TABLE menu_item_sizes (
     id integer NOT NULL,
     menu_item_id integer NOT NULL,
     price numeric(6,2),
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     enabled boolean NOT NULL,
     menu_size_id integer NOT NULL,
     restaurant_price numeric
 ) sortkey(menu_size_id, menu_item_id, id);

 CREATE TABLE menu_items (
     id integer NOT NULL,
     category_id integer NOT NULL,
     name character varying(255),
     description varchar(max),
     order_type character varying(255),
     inherit_option_groups boolean NOT NULL,
     display_order integer NOT NULL,
     taxable boolean,
     timesets varchar(max),
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
 ) sortkey(display_order, category_id, id);

 CREATE TABLE menu_options (
     id integer NOT NULL,
     restaurant_id integer,
     name character varying(255),
     available boolean,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(restaurant_id, id);

 CREATE TABLE menu_sizes (
     id integer NOT NULL,
     restaurant_id integer NOT NULL,
     name character varying(255),
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     display_order integer NOT NULL
 ) sortkey(restaurant_id, display_order, id);

 CREATE TABLE menu_updates (
     id integer NOT NULL,
     restaurant_id integer NOT NULL,
     data varchar(max),
     change_count integer NOT NULL,
     created_at timestamp without time zone NOT NULL
 ) sortkey(id);

 CREATE TABLE monthly_order_counts (
     id integer NOT NULL,
     market_id integer NOT NULL,
     year integer NOT NULL,
     month integer NOT NULL,
     orders integer NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE newbie_codes (
     id integer NOT NULL,
     market_id integer NOT NULL,
     name character varying(255),
     code character varying(255),
     event_date timestamp without time zone NOT NULL,
     event_expires timestamp without time zone NOT NULL,
     credit_amount numeric(19,2) DEFAULT 0 NOT NULL,
     credit_expires_at timestamp without time zone,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     days_to_redeem_credit integer,
     use_days_to_redeem_credit_for_new_credit_items boolean DEFAULT false
 ) sortkey(id);

 CREATE TABLE notification_schedule_changes (
     id integer NOT NULL,
     driver_id integer,
     performed_by_id integer,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

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
 ) sortkey(menu_size_id, id, option_group_option_id);

 CREATE TABLE option_group_options (
     id integer NOT NULL,
     option_group_id integer NOT NULL,
     name character varying(255),
     enabled boolean NOT NULL,
     display_order integer NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     available boolean NOT NULL
 ) sortkey(display_order, id, option_group_id);

 CREATE TABLE option_groups (
     id integer NOT NULL,
     restaurant_id integer NOT NULL,
     name character varying(255),
     display_name varchar(max),
     restriction varchar(max),
     half_sizes boolean NOT NULL,
     allows_selection_repetition boolean NOT NULL,
     display_order integer NOT NULL
 ) sortkey(restaurant_id, display_order, id);

 CREATE TABLE order_coupons (
     id integer NOT NULL,
     order_id integer,
     order_item_id integer,
     customer_id integer,
     coupon_id integer,
     discount_applied numeric(6,2),
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE order_notifications (
     id integer NOT NULL,
     type character varying(255),
     order_id integer,
     reason character varying(255),
     status character varying(255),
     provider character varying(255),
     provider_id character varying(255),
     provider_status character varying(255),
     provider_message varchar(max),
     provider_data json,
     recipient character varying(255),
     recipient_type character varying(255),
     template character varying(255),
     memo character varying(255),
     created_by character varying(255),
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     confirmation_token character varying(255)
 ) sortkey(id);

 CREATE TABLE orders_payments (
     order_id integer,
     payment_id integer
 );

 CREATE TABLE pay_period_account_entries (
     id integer NOT NULL,
     account_owner_id integer NOT NULL,
     period_started_at timestamp without time zone NOT NULL,
     period_ended_at timestamp without time zone NOT NULL,
     amount numeric(19,6) NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     account_owner_type character varying(255)
 ) sortkey(id);

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
 ) sortkey(id);

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
 ) sortkey(id);

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
 ) sortkey(id);

 CREATE TABLE promo_codes (
     id integer NOT NULL,
     code character varying(255),
     promotable_type character varying(255),
     promotable_id integer NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE receipts (
     id integer NOT NULL,
     order_id integer NOT NULL,
     image_path character varying(255),
     settled_at timestamp without time zone,
     disputed_at timestamp without time zone,
     uploaded_at timestamp without time zone,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE referral_codes (
     id integer NOT NULL,
     customer_id integer,
     market_id integer,
     code character varying(255),
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

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
 ) sortkey(id);

 CREATE TABLE reliability_score_events (
     id integer NOT NULL,
     shift_assignment_id integer NOT NULL,
     event_type character varying(255),
     score numeric(7,6) NOT NULL,
     message character varying(255),
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     customer_id integer
 ) sortkey(id);

 CREATE TABLE restaurant_campus_payment_cards (
     id integer NOT NULL,
     restaurant_id integer,
     campus_payment_card_id integer,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE restaurant_categories (
     id integer NOT NULL,
     name character varying(255),
     description character varying(255),
     slug character varying(255),
     visible boolean DEFAULT true NOT NULL
 ) sortkey(id);

 CREATE TABLE restaurant_categorizations (
     id integer NOT NULL,
     restaurant_id integer NOT NULL,
     restaurant_category_id integer NOT NULL
 ) sortkey(id);

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
 ) sortkey(id);

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
 ) sortkey(id);

 CREATE TABLE restaurant_drive_times (
     id integer NOT NULL,
     restaurant_id integer,
     beacon_id integer,
     drive_time_seconds integer,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE restaurant_hours (
     id integer NOT NULL,
     restaurant_id integer,
     restaurant_temporary_hour_id integer,
     order_type character varying(255),
     day_of_week integer NOT NULL,
     start_time character varying(255),
     end_time character varying(255),
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     hours_owner_id integer NOT NULL,
     hours_owner_type character varying(255),
     temporary_hour_id integer
 ) sortkey(id);

 CREATE TABLE restaurant_requests (
     id integer NOT NULL,
     restaurant varchar(max),
     market_id integer,
     customer_id integer,
     created_at timestamp without time zone NOT NULL
 ) sortkey(id);

 CREATE TABLE restaurant_temporary_hours (
     id integer NOT NULL,
     restaurant_id integer,
     order_type character varying(255),
     description varchar(max),
     starts_at timestamp without time zone,
     ends_at timestamp without time zone,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     hours_owner_id integer,
     hours_owner_type character varying(255)
 ) sortkey(id);

 CREATE TABLE restaurant_users (
     id integer NOT NULL,
     restaurant_id integer,
     user_id integer,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE schema_migrations (
     version character varying(255)
 );

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
 ) sortkey(id);

 CREATE TABLE settings (
     id integer NOT NULL,
     fax_provider character varying(255) DEFAULT 'phaxio'::character varying,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     system_online boolean,
     banner_message varchar(max),
     sms_provider character varying(255) DEFAULT 'twilio'::character varying,
     credit_card_processor character varying(255) DEFAULT 'braintree'::character varying,
     phone_provider character varying(255),
     giving_tuesday_additional_dollars numeric(19,3),
     geocoding_provider character varying(255),
     emma_synced_up_to timestamp without time zone) sortkey(id);

 CREATE TABLE shift_assignment_delivery_service_changes (
     id integer NOT NULL,
     shift_assignment_id integer NOT NULL,
     previous_delivery_service_id integer NOT NULL,
     current_delivery_service_id integer NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

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
 ) sortkey(id);

 CREATE TABLE shift_predictions (
     id integer NOT NULL,
     shift_id integer NOT NULL,
     delivery_service_id integer NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     suggested_driver_hours numeric,
     estimated_delivery_count numeric,
     deliveries_per_hour_multiplier numeric
 ) sortkey(shift_id, id, delivery_service_id);

 CREATE TABLE shift_templates (
     id integer NOT NULL,
     start_hour integer,
     end_hour integer,
     needed_drivers integer,
     guaranteed_wage integer,
     market_id integer,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

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
 ) sortkey(id);

 CREATE TABLE shutdown_group_restaurants (
     id integer NOT NULL,
     shutdown_group_id integer,
     restaurant_id integer,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE shutdown_groups (
     id integer NOT NULL,
     market_id integer,
     name character varying(255),
     shutdown boolean DEFAULT false NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     shutdown_message_id integer
 ) sortkey(id);

 CREATE TABLE shutdown_messages (
     id integer NOT NULL,
     reason character varying(255),
     body varchar(max),
     automatic boolean DEFAULT false NOT NULL,
     archived boolean DEFAULT false NOT NULL
 ) sortkey(id);

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
 ) sortkey(id);

 CREATE TABLE sms_messages (
     id integer NOT NULL,
     type character varying(255),
     sms_number_id integer NOT NULL,
     from_type character varying(255),
     from_id integer NOT NULL,
     from_number character varying(255),
     to_number character varying(255),
     to_type character varying(255),
     to_id integer NOT NULL,
     message varchar(max),
     external_id character varying(255),
     message_data varchar(max),
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     order_id integer
 ) sortkey(id);

 CREATE TABLE sms_number_reservations (
     id integer NOT NULL,
     sms_number_id integer,
     from_number character varying(255),
     from_type character varying(255),
     from_id integer NOT NULL,
     to_number character varying(255),
     to_type character varying(255),
     to_id integer NOT NULL,
     hour timestamp without time zone NOT NULL,
     expires_at timestamp without time zone,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     order_id integer
 ) sortkey(id);

 CREATE TABLE sms_numbers (
     id integer NOT NULL,
     provider_type character varying(255),
     number character varying(255),
     type character varying(255),
     reservation_expires_at timestamp without time zone,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     market_id integer,
     deleted_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE specials (
     id integer NOT NULL,
     restaurant_id integer NOT NULL,
     description character varying(255),
     delivery_days integer DEFAULT 0 NOT NULL,
     takeout_days integer DEFAULT 0 NOT NULL,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE subscriptions (
     id integer NOT NULL,
     subscriptionable_id integer NOT NULL,
     report_type character varying(255),
     period character varying(255),
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     subscriptionable_type character varying(255),
     next_run_at timestamp without time zone NOT NULL,
     subscriptionable_name character varying(255),
     recipients character varying(255)[] DEFAULT '{}'::character varying[],
     last_ran_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE surveys (
     id integer NOT NULL,
     spreadsheet_key character varying(255),
     restaurant_list varchar(max),
     prize_image_link character varying(255),
     rules_link character varying(255),
     headline varchar(max),
     school_name character varying(255),
     thanks_image_link character varying(255),
     share_language varchar(max),
     email_subject character varying(255),
     prize_name character varying(255),
     market_id integer,
     version character varying(255),
     prompt varchar(max)
 ) sortkey(id);

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
 ) sortkey(id);

 CREATE TABLE users (
     id integer NOT NULL,
     username character varying(255),
     password character varying(255),
     first_name character varying(255),
     last_name character varying(255),
     role integer,
     email character varying(255),
     active boolean,
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE voice_calls (
     id integer NOT NULL,
     sms_number_id integer NOT NULL,
     sms_number_reservation_id integer NOT NULL,
     message_direction character varying(255),
     order_id integer NOT NULL,
     driver_id integer NOT NULL,
     customer_id integer NOT NULL,
     external_id character varying(255),
     created_at timestamp without time zone,
     updated_at timestamp without time zone
 ) sortkey(id);

 CREATE TABLE work_segments (
     id integer NOT NULL,
     driver_id integer,
     started_at timestamp without time zone,
     ended_at timestamp without time zone,
     created_at timestamp without time zone,
     updated_at timestamp without time zone,
     delivery_service_id integer
 ) sortkey(id);

ALTER TABLE newbie_codes
    ADD CONSTRAINT acquisition_events_pkey PRIMARY KEY (id);
ALTER TABLE active_cart_counts
    ADD CONSTRAINT active_cart_counts_pkey PRIMARY KEY (id);
ALTER TABLE adjustments
    ADD CONSTRAINT adjustments_pkey PRIMARY KEY (id);
ALTER TABLE affiliates
    ADD CONSTRAINT affiliates_pkey PRIMARY KEY (id);
ALTER TABLE april_fools_responses
    ADD CONSTRAINT april_fools_responses_pkey PRIMARY KEY (id);
ALTER TABLE audits
    ADD CONSTRAINT audits_pkey PRIMARY KEY (id);
ALTER TABLE banner_ads
    ADD CONSTRAINT banner_ads_pkey PRIMARY KEY (id);
ALTER TABLE beacons
    ADD CONSTRAINT beacons_pkey PRIMARY KEY (id);
ALTER TABLE blacklisted_email_addresses
    ADD CONSTRAINT blacklisted_email_addresses_pkey PRIMARY KEY (id);
ALTER TABLE blacklisted_email_domains
    ADD CONSTRAINT blacklisted_email_domains_pkey PRIMARY KEY (id);
ALTER TABLE blacklisted_ip_addresses
    ADD CONSTRAINT blacklisted_ip_addresses_pkey PRIMARY KEY (id);
ALTER TABLE blacklisted_phone_numbers
    ADD CONSTRAINT blacklisted_phone_numbers_pkey PRIMARY KEY (id);
ALTER TABLE blazer_audits
    ADD CONSTRAINT blazer_audits_pkey PRIMARY KEY (id);
ALTER TABLE blazer_queries
    ADD CONSTRAINT blazer_queries_pkey PRIMARY KEY (id);
ALTER TABLE building_groups
    ADD CONSTRAINT building_groups_pkey PRIMARY KEY (id);
ALTER TABLE buildings
    ADD CONSTRAINT buildings_pkey PRIMARY KEY (id);
ALTER TABLE campus_payment_cards
    ADD CONSTRAINT campus_payment_cards_pkey PRIMARY KEY (id);
ALTER TABLE canonicalized_json_menus
    ADD CONSTRAINT canonicalized_json_menus_pkey PRIMARY KEY (id);
ALTER TABLE canonicalized_menus
    ADD CONSTRAINT canonicalized_menus_pkey PRIMARY KEY (id);
ALTER TABLE cart_coupons
    ADD CONSTRAINT cart_coupons_pkey PRIMARY KEY (id);
ALTER TABLE cart_item_options
    ADD CONSTRAINT cart_item_options_pkey PRIMARY KEY (id);
ALTER TABLE cart_items
    ADD CONSTRAINT cart_items_pkey PRIMARY KEY (id);
ALTER TABLE cart_participants
    ADD CONSTRAINT cart_participants_pkey PRIMARY KEY (id);
ALTER TABLE carts
    ADD CONSTRAINT carts_pkey PRIMARY KEY (id);
ALTER TABLE menu_categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);
ALTER TABLE menu_category_option_groups
    ADD CONSTRAINT category_option_groups_pkey PRIMARY KEY (id);
ALTER TABLE cohort_memberships
    ADD CONSTRAINT cohort_memberships_pkey PRIMARY KEY (id);
ALTER TABLE cohort_service_cohorts
    ADD CONSTRAINT cohort_service_cohorts_pkey PRIMARY KEY (id);
ALTER TABLE cohort_services
    ADD CONSTRAINT cohort_services_pkey PRIMARY KEY (id);
ALTER TABLE cohorts
    ADD CONSTRAINT cohorts_pkey PRIMARY KEY (id);
ALTER TABLE delivery_comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);
ALTER TABLE content
    ADD CONSTRAINT content_pkey PRIMARY KEY (key);
ALTER TABLE coupons
    ADD CONSTRAINT coupons_pkey PRIMARY KEY (id);
ALTER TABLE credit_batch_errors
    ADD CONSTRAINT credit_batch_errors_pkey PRIMARY KEY (id);
ALTER TABLE credit_batches
    ADD CONSTRAINT credit_batches_pkey PRIMARY KEY (id);
ALTER TABLE credit_cards
    ADD CONSTRAINT credit_cards_pkey PRIMARY KEY (id);
ALTER TABLE credit_items
    ADD CONSTRAINT credit_items_pkey PRIMARY KEY (id);
ALTER TABLE customer_addresses
    ADD CONSTRAINT customer_addresses_pkey PRIMARY KEY (id);
ALTER TABLE customer_campus_cards
    ADD CONSTRAINT customer_campus_cards_pkey PRIMARY KEY (id);
ALTER TABLE customer_coupon_uses
    ADD CONSTRAINT customer_coupon_uses_pkey PRIMARY KEY (id);
ALTER TABLE customer_information_requests
    ADD CONSTRAINT customer_information_requests_pkey PRIMARY KEY (id);
ALTER TABLE customer_phones
    ADD CONSTRAINT customer_phones_pkey PRIMARY KEY (id);
ALTER TABLE customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);
ALTER TABLE daily_order_counts
    ADD CONSTRAINT daily_order_counts_pkey PRIMARY KEY (id);
ALTER TABLE deliveries_hours
    ADD CONSTRAINT deliveries_hours_pkey PRIMARY KEY (id);
ALTER TABLE deliveries
    ADD CONSTRAINT deliveries_pkey PRIMARY KEY (id);
ALTER TABLE delivery_estimates
    ADD CONSTRAINT delivery_estimates_pkey PRIMARY KEY (id);
ALTER TABLE delivery_log_entries
    ADD CONSTRAINT delivery_log_entries_pkey PRIMARY KEY (id);
ALTER TABLE delivery_service_health_features
    ADD CONSTRAINT delivery_service_health_features_pkey PRIMARY KEY (id);
ALTER TABLE delivery_service_health_models
    ADD CONSTRAINT delivery_service_health_models_pkey PRIMARY KEY (id);
ALTER TABLE delivery_service_health_scores
    ADD CONSTRAINT delivery_service_health_scores_pkey PRIMARY KEY (id);
ALTER TABLE delivery_service_random_forests
    ADD CONSTRAINT delivery_service_random_forests_pkey PRIMARY KEY (id);
ALTER TABLE delivery_services
    ADD CONSTRAINT delivery_services_pkey PRIMARY KEY (id);
ALTER TABLE delivery_sign_ups
    ADD CONSTRAINT delivery_sign_ups_pkey PRIMARY KEY (id);
ALTER TABLE delivery_status_updates
    ADD CONSTRAINT delivery_status_updates_pkey PRIMARY KEY (id);
ALTER TABLE delivery_steps
    ADD CONSTRAINT delivery_steps_pkey PRIMARY KEY (id);
ALTER TABLE delivery_zones
    ADD CONSTRAINT delivery_zones_pkey PRIMARY KEY (id);
ALTER TABLE devices
    ADD CONSTRAINT devices_pkey PRIMARY KEY (id);
ALTER TABLE restaurant_categories
    ADD CONSTRAINT discovery_categories_pkey PRIMARY KEY (id);
ALTER TABLE dispatches
    ADD CONSTRAINT driver_assignments_pkey PRIMARY KEY (id);
ALTER TABLE driver_availabilities
    ADD CONSTRAINT driver_availabilities_pkey PRIMARY KEY (id);
ALTER TABLE driver_availability_blocks
    ADD CONSTRAINT driver_availability_blocks_pkey PRIMARY KEY (id);
ALTER TABLE driver_broadcasts
    ADD CONSTRAINT driver_broadcasts_pkey PRIMARY KEY (id);
ALTER TABLE driver_locations
    ADD CONSTRAINT driver_locations_pkey PRIMARY KEY (id);
ALTER TABLE driver_messages
    ADD CONSTRAINT driver_messages_pkey PRIMARY KEY (id);
ALTER TABLE driver_points
    ADD CONSTRAINT driver_points_pkey PRIMARY KEY (id);
ALTER TABLE driver_restaurant_bans
    ADD CONSTRAINT driver_restaurant_bans_pkey PRIMARY KEY (id);
ALTER TABLE shift_assignments
    ADD CONSTRAINT driver_shifts_pkey PRIMARY KEY (id);
ALTER TABLE driver_work_hours
    ADD CONSTRAINT driver_work_hours_pkey PRIMARY KEY (id);
ALTER TABLE drivers
    ADD CONSTRAINT drivers_pkey PRIMARY KEY (id);
ALTER TABLE estimation_model_feature_values
    ADD CONSTRAINT estimation_model_feature_values_pkey PRIMARY KEY (id);
ALTER TABLE estimation_model_features
    ADD CONSTRAINT estimation_model_features_pkey PRIMARY KEY (id);
ALTER TABLE estimation_models
    ADD CONSTRAINT estimation_models_pkey PRIMARY KEY (id);
ALTER TABLE favorite_restaurants
    ADD CONSTRAINT favorite_restaurants_pkey PRIMARY KEY (id);
ALTER TABLE franchise_contacts
    ADD CONSTRAINT franchise_contacts_pkey PRIMARY KEY (id);
ALTER TABLE frequently_asked_question_categories
    ADD CONSTRAINT frequently_asked_question_categories_pkey PRIMARY KEY (id);
ALTER TABLE frequently_asked_questions
    ADD CONSTRAINT frequently_asked_questions_pkey PRIMARY KEY (id);
ALTER TABLE gift_cards
    ADD CONSTRAINT gift_cards_pkey PRIMARY KEY (id);
ALTER TABLE hosted_sites
    ADD CONSTRAINT hosted_sites_pkey PRIMARY KEY (id);
ALTER TABLE menu_categories
    ADD CONSTRAINT index_categories_on_menu_and_display_order EXCLUDE USING btree (restaurant_id WITH =, display_order WITH =) WHERE ((parent_category_id IS NULL)) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE menu_categories
    ADD CONSTRAINT index_categories_on_menu_and_parent_and_display_order EXCLUDE USING btree (restaurant_id WITH =, parent_category_id WITH =, display_order WITH =) WHERE ((parent_category_id IS NOT NULL)) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE menu_category_option_groups
    ADD CONSTRAINT index_category_option_groups_on_category_and_display_order UNIQUE (menu_category_id, display_order) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE menu_category_sizes
    ADD CONSTRAINT index_category_sizes_on_category_and_display_order UNIQUE (menu_category_id, display_order) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE menu_item_descriptors
    ADD CONSTRAINT index_item_descriptors_on_category_and_display_order UNIQUE (menu_item_id, display_order) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE menu_item_option_groups
    ADD CONSTRAINT index_item_option_groups_on_category_and_display_order UNIQUE (menu_item_id, display_order) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE menu_items
    ADD CONSTRAINT index_items_on_category_and_display_order UNIQUE (category_id, display_order) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE menu_descriptors
    ADD CONSTRAINT index_menu_descriptors_on_menu_and_display_order UNIQUE (restaurant_id, display_order) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE menu_sizes
    ADD CONSTRAINT index_menu_sizes_on_menu_and_display_order UNIQUE (restaurant_id, display_order) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE option_group_options
    ADD CONSTRAINT index_option_group_options_on_option_group_and_display_order UNIQUE (option_group_id, display_order) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE option_groups
    ADD CONSTRAINT index_option_groups_on_menu_and_display_order UNIQUE (restaurant_id, display_order) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE menu_item_option_groups
    ADD CONSTRAINT item_option_groups_pkey PRIMARY KEY (id);
ALTER TABLE jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);
ALTER TABLE loyalty_cash_transactions
    ADD CONSTRAINT loyalty_cash_transactions_pkey PRIMARY KEY (id);
ALTER TABLE market_campus_payment_cards
    ADD CONSTRAINT market_campus_payment_cards_pkey PRIMARY KEY (id);
ALTER TABLE market_cities
    ADD CONSTRAINT market_cities_pkey PRIMARY KEY (id);
ALTER TABLE market_dispatch_notes
    ADD CONSTRAINT market_dispatch_notes_pkey PRIMARY KEY (id);
ALTER TABLE market_scorecards
    ADD CONSTRAINT market_scorecards_pkey PRIMARY KEY (id);
ALTER TABLE market_weather_hours
    ADD CONSTRAINT market_weather_hours_pkey PRIMARY KEY (id);
ALTER TABLE markets
    ADD CONSTRAINT markets_pkey PRIMARY KEY (id);
ALTER TABLE menu_category_option_group_option_prices
    ADD CONSTRAINT menu_category_option_group_option_prices_pkey PRIMARY KEY (id);
ALTER TABLE menu_category_option_group_options
    ADD CONSTRAINT menu_category_option_group_options_pkey PRIMARY KEY (id);
ALTER TABLE menu_category_sizes
    ADD CONSTRAINT menu_category_sizes_pkey PRIMARY KEY (id);
ALTER TABLE menu_descriptors
    ADD CONSTRAINT menu_descriptors_pkey PRIMARY KEY (id);
ALTER TABLE menu_item_descriptors
    ADD CONSTRAINT menu_item_descriptors_pkey PRIMARY KEY (id);
ALTER TABLE menu_item_option_group_option_prices
    ADD CONSTRAINT menu_item_option_group_option_prices_pkey PRIMARY KEY (id);
ALTER TABLE menu_item_option_group_options
    ADD CONSTRAINT menu_item_option_group_options_pkey PRIMARY KEY (id);
ALTER TABLE menu_item_sizes
    ADD CONSTRAINT menu_item_sizes_pkey PRIMARY KEY (id);
ALTER TABLE menu_items
    ADD CONSTRAINT menu_items_pkey PRIMARY KEY (id);
ALTER TABLE menu_options
    ADD CONSTRAINT menu_options_pkey PRIMARY KEY (id);
ALTER TABLE menu_sizes
    ADD CONSTRAINT menu_sizes_pkey PRIMARY KEY (id);
ALTER TABLE menu_updates
    ADD CONSTRAINT menu_updates_pkey PRIMARY KEY (id);
ALTER TABLE monthly_order_counts
    ADD CONSTRAINT monthly_order_counts_pkey PRIMARY KEY (id);
ALTER TABLE notification_schedule_changes
    ADD CONSTRAINT notification_schedule_changes_pkey PRIMARY KEY (id);
ALTER TABLE option_group_option_prices
    ADD CONSTRAINT option_group_option_prices_pkey PRIMARY KEY (id);
ALTER TABLE option_group_options
    ADD CONSTRAINT option_group_options_pkey PRIMARY KEY (id);
ALTER TABLE option_groups
    ADD CONSTRAINT option_groups_pkey PRIMARY KEY (id);
ALTER TABLE order_coupons
    ADD CONSTRAINT order_coupons_pkey PRIMARY KEY (id);
ALTER TABLE order_notifications
    ADD CONSTRAINT order_notifications_pkey PRIMARY KEY (id);
ALTER TABLE orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);
ALTER TABLE payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);
ALTER TABLE pex_transactions
    ADD CONSTRAINT pex_transactions_pkey PRIMARY KEY (id);
ALTER TABLE print_menus
    ADD CONSTRAINT print_menus_pkey PRIMARY KEY (id);
ALTER TABLE promo_codes
    ADD CONSTRAINT promo_codes_pkey PRIMARY KEY (id);
ALTER TABLE receipts
    ADD CONSTRAINT receipts_pkey PRIMARY KEY (id);
ALTER TABLE referral_codes
    ADD CONSTRAINT referral_codes_pkey PRIMARY KEY (id);
ALTER TABLE referrals
    ADD CONSTRAINT referrals_pkey PRIMARY KEY (id);
ALTER TABLE reliability_score_events
    ADD CONSTRAINT reliability_score_events_pkey PRIMARY KEY (id);
ALTER TABLE pay_period_account_entries
    ADD CONSTRAINT restaurant_account_entries_pkey PRIMARY KEY (id);
ALTER TABLE restaurant_campus_payment_cards
    ADD CONSTRAINT restaurant_campus_payment_cards_pkey PRIMARY KEY (id);
ALTER TABLE restaurant_categorizations
    ADD CONSTRAINT restaurant_categorizations_pkey PRIMARY KEY (id);
ALTER TABLE restaurant_contacts
    ADD CONSTRAINT restaurant_contacts_pkey PRIMARY KEY (id);
ALTER TABLE restaurant_delivery_zones
    ADD CONSTRAINT restaurant_delivery_zones_pkey PRIMARY KEY (id);
ALTER TABLE restaurant_drive_times
    ADD CONSTRAINT restaurant_drive_times_pkey PRIMARY KEY (id);
ALTER TABLE restaurant_hours
    ADD CONSTRAINT restaurant_hours_pkey PRIMARY KEY (id);
ALTER TABLE restaurant_requests
    ADD CONSTRAINT restaurant_requests_pkey PRIMARY KEY (id);
ALTER TABLE restaurant_temporary_hours
    ADD CONSTRAINT restaurant_temporary_hours_pkey PRIMARY KEY (id);
ALTER TABLE restaurant_users
    ADD CONSTRAINT restaurant_users_pkey PRIMARY KEY (id);
ALTER TABLE restaurants
    ADD CONSTRAINT restaurants_pkey PRIMARY KEY (id);
ALTER TABLE scorecards
    ADD CONSTRAINT scorecards_pkey PRIMARY KEY (id);
ALTER TABLE settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);
ALTER TABLE shift_assignment_delivery_service_changes
    ADD CONSTRAINT shift_assignment_delivery_service_changes_pkey PRIMARY KEY (id);
ALTER TABLE shift_predictions
    ADD CONSTRAINT shift_calculations_pkey PRIMARY KEY (id);
ALTER TABLE shift_templates
    ADD CONSTRAINT shift_templates_pkey PRIMARY KEY (id);
ALTER TABLE shifts
    ADD CONSTRAINT shifts_pkey PRIMARY KEY (id);
ALTER TABLE shutdown_group_restaurants
    ADD CONSTRAINT shutdown_group_restaurants_pkey PRIMARY KEY (id);
ALTER TABLE shutdown_groups
    ADD CONSTRAINT shutdown_groups_pkey PRIMARY KEY (id);
ALTER TABLE shutdown_messages
    ADD CONSTRAINT shutdown_messages_pkey PRIMARY KEY (id);
ALTER TABLE sign_up_links
    ADD CONSTRAINT sign_up_links_pkey PRIMARY KEY (id);
ALTER TABLE sms_messages
    ADD CONSTRAINT sms_messages_pkey PRIMARY KEY (id);
ALTER TABLE sms_number_reservations
    ADD CONSTRAINT sms_number_reservations_pkey PRIMARY KEY (id);
ALTER TABLE sms_numbers
    ADD CONSTRAINT sms_numbers_pkey PRIMARY KEY (id);
ALTER TABLE specials
    ADD CONSTRAINT specials_pkey PRIMARY KEY (id);
ALTER TABLE subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);
ALTER TABLE surveys
    ADD CONSTRAINT surveys_pkey PRIMARY KEY (id);
ALTER TABLE temporary_shutdowns
    ADD CONSTRAINT temporary_shutdowns_pkey PRIMARY KEY (id);
ALTER TABLE users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
ALTER TABLE voice_calls
    ADD CONSTRAINT voice_calls_pkey PRIMARY KEY (id);
ALTER TABLE work_segments
    ADD CONSTRAINT work_segments_pkey PRIMARY KEY (id);
ALTER TABLE cart_coupons
    ADD CONSTRAINT cart_coupons_cart_id_fk FOREIGN KEY (cart_id) REFERENCES carts(id);
ALTER TABLE cart_coupons
    ADD CONSTRAINT cart_coupons_coupon_id_fk FOREIGN KEY (coupon_id) REFERENCES coupons(id);
ALTER TABLE cart_items
    ADD CONSTRAINT cart_items_cart_id_fk FOREIGN KEY (cart_id) REFERENCES carts(id);
ALTER TABLE cart_items
    ADD CONSTRAINT cart_items_coupon_id_fk FOREIGN KEY (coupon_id) REFERENCES coupons(id);
ALTER TABLE menu_categories
    ADD CONSTRAINT categories_restaurant_id_fk FOREIGN KEY (restaurant_id) REFERENCES restaurants(id);
ALTER TABLE menu_category_option_group_option_prices
    ADD CONSTRAINT category_option_group_option_price_category_option_group_fk FOREIGN KEY (menu_category_option_group_option_id) REFERENCES menu_category_option_group_options(id) ;
ALTER TABLE menu_category_option_group_option_prices
    ADD CONSTRAINT category_option_group_option_price_option_price_fk FOREIGN KEY (option_group_option_price_id) REFERENCES option_group_option_prices(id);
ALTER TABLE menu_category_option_group_options
    ADD CONSTRAINT category_option_group_options_category_option_group_fk FOREIGN KEY (menu_category_option_group_id) REFERENCES menu_category_option_groups(id) ;
ALTER TABLE menu_category_option_group_options
    ADD CONSTRAINT category_option_group_options_option_group_option_fk FOREIGN KEY (option_group_option_id) REFERENCES option_group_options(id);
ALTER TABLE menu_category_option_groups
    ADD CONSTRAINT category_option_groups_option_group_id_fk FOREIGN KEY (option_group_id) REFERENCES option_groups(id);
ALTER TABLE cohort_memberships
    ADD CONSTRAINT cohort_memberships_cohort_id_fk FOREIGN KEY (cohort_id) REFERENCES cohorts(id) ;
ALTER TABLE cohort_memberships
    ADD CONSTRAINT cohort_memberships_customer_id_fk FOREIGN KEY (customer_id) REFERENCES customers(id) ;
ALTER TABLE cohort_service_cohorts
    ADD CONSTRAINT cohort_service_cohorts_cohort_id_fk FOREIGN KEY (cohort_id) REFERENCES cohorts(id) ;
ALTER TABLE cohort_service_cohorts
    ADD CONSTRAINT cohort_service_cohorts_cohort_service_id_fk FOREIGN KEY (cohort_service_id) REFERENCES cohort_services(id) ;
ALTER TABLE customer_coupon_uses
    ADD CONSTRAINT customer_coupon_uses_coupon_id_fk FOREIGN KEY (coupon_id) REFERENCES coupons(id);
ALTER TABLE customer_coupon_uses
    ADD CONSTRAINT customer_coupon_uses_customer_id_fk FOREIGN KEY (customer_id) REFERENCES customers(id);
ALTER TABLE delivery_estimates
    ADD CONSTRAINT delivery_estimates_delivery_id_fk FOREIGN KEY (delivery_id) REFERENCES deliveries(id) ;
ALTER TABLE driver_messages
    ADD CONSTRAINT driver_messages_author_id_fk FOREIGN KEY (author_id) REFERENCES customers(id);
ALTER TABLE driver_messages
    ADD CONSTRAINT driver_messages_driver_id_fk FOREIGN KEY (driver_id) REFERENCES drivers(id);
ALTER TABLE drivers
    ADD CONSTRAINT drivers_delivery_service_id_fk FOREIGN KEY (delivery_service_id) REFERENCES delivery_services(id);
ALTER TABLE favorite_restaurants
    ADD CONSTRAINT favorite_restaurants_customer_id_fk FOREIGN KEY (customer_id) REFERENCES customers(id) ;
ALTER TABLE favorite_restaurants
    ADD CONSTRAINT favorite_restaurants_restaurant_id_fk FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ;
ALTER TABLE hosted_sites
    ADD CONSTRAINT hosted_sites_restaurant_id_fk FOREIGN KEY (restaurant_id) REFERENCES restaurants(id);
ALTER TABLE menu_item_option_group_option_prices
    ADD CONSTRAINT item_option_group_option_price_item_option_group_fk FOREIGN KEY (menu_item_option_group_option_id) REFERENCES menu_item_option_group_options(id) ;
ALTER TABLE menu_item_option_group_option_prices
    ADD CONSTRAINT item_option_group_option_price_option_price_fk FOREIGN KEY (option_group_option_price_id) REFERENCES option_group_option_prices(id);
ALTER TABLE menu_item_option_group_options
    ADD CONSTRAINT item_option_group_options_item_option_group_fk FOREIGN KEY (menu_item_option_group_id) REFERENCES menu_item_option_groups(id) ;
ALTER TABLE menu_item_option_group_options
    ADD CONSTRAINT item_option_group_options_option_group_option_fk FOREIGN KEY (option_group_option_id) REFERENCES option_group_options(id);
ALTER TABLE menu_item_option_groups
    ADD CONSTRAINT item_option_groups_option_group_id_fk FOREIGN KEY (option_group_id) REFERENCES option_groups(id);
ALTER TABLE menu_categories
    ADD CONSTRAINT menu_categories_parent_category_id_fk FOREIGN KEY (parent_category_id) REFERENCES menu_categories(id) ;
ALTER TABLE menu_category_option_groups
    ADD CONSTRAINT menu_category_option_groups_menu_category_id_fk FOREIGN KEY (menu_category_id) REFERENCES menu_categories(id) ;
ALTER TABLE menu_category_sizes
    ADD CONSTRAINT menu_category_sizes_menu_category_id_fk FOREIGN KEY (menu_category_id) REFERENCES menu_categories(id) ;
ALTER TABLE menu_category_sizes
    ADD CONSTRAINT menu_category_sizes_menu_size_id_fk FOREIGN KEY (menu_size_id) REFERENCES menu_sizes(id);
ALTER TABLE menu_descriptors
    ADD CONSTRAINT menu_descriptors_restaurant_id_fk FOREIGN KEY (restaurant_id) REFERENCES restaurants(id);
ALTER TABLE menu_item_descriptors
    ADD CONSTRAINT menu_item_descriptors_menu_descriptor_id_fk FOREIGN KEY (menu_descriptor_id) REFERENCES menu_descriptors(id) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE menu_item_descriptors
    ADD CONSTRAINT menu_item_descriptors_menu_item_id_fk FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ;
ALTER TABLE menu_item_option_groups
    ADD CONSTRAINT menu_item_option_groups_menu_item_id_fk FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ;
ALTER TABLE menu_item_sizes
    ADD CONSTRAINT menu_item_sizes_menu_item_id_fk FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ;
ALTER TABLE menu_item_sizes
    ADD CONSTRAINT menu_item_sizes_menu_size_id_fk FOREIGN KEY (menu_size_id) REFERENCES menu_sizes(id);
ALTER TABLE menu_items
    ADD CONSTRAINT menu_items_category_id_fk FOREIGN KEY (category_id) REFERENCES menu_categories(id) ;
ALTER TABLE menu_options
    ADD CONSTRAINT menu_options_restaurant_id_fk FOREIGN KEY (restaurant_id) REFERENCES restaurants(id);
ALTER TABLE menu_sizes
    ADD CONSTRAINT menu_sizes_restaurant_id_fk FOREIGN KEY (restaurant_id) REFERENCES restaurants(id);
ALTER TABLE option_group_option_prices
    ADD CONSTRAINT option_group_option_prices_menu_size_id_fk FOREIGN KEY (menu_size_id) REFERENCES menu_sizes(id);
ALTER TABLE option_group_option_prices
    ADD CONSTRAINT option_group_option_prices_option_group_option_id_fk FOREIGN KEY (option_group_option_id) REFERENCES option_group_options(id) ;
ALTER TABLE option_group_options
    ADD CONSTRAINT option_group_options_option_group_id_fk FOREIGN KEY (option_group_id) REFERENCES option_groups(id) ;
ALTER TABLE option_groups
    ADD CONSTRAINT option_groups_restaurant_id_fk FOREIGN KEY (restaurant_id) REFERENCES restaurants(id);
ALTER TABLE orders
    ADD CONSTRAINT orders_customer_id_fk FOREIGN KEY (customer_id) REFERENCES customers(id);
ALTER TABLE orders
    ADD CONSTRAINT orders_restaurant_id_fk FOREIGN KEY (restaurant_id) REFERENCES restaurants(id);
ALTER TABLE restaurants
    ADD CONSTRAINT restaurants_market_id_fk FOREIGN KEY (market_id) REFERENCES markets(id);
ALTER TABLE shift_predictions
    ADD CONSTRAINT shift_calculations_delivery_service_id_fk FOREIGN KEY (delivery_service_id) REFERENCES delivery_services(id) ;
ALTER TABLE shift_predictions
    ADD CONSTRAINT shift_calculations_shift_id_fk FOREIGN KEY (shift_id) REFERENCES shifts(id) ;
