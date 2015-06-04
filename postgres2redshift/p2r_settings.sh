#!/bin/sh

### LICENSE
  # Author: Vlad Dubovskiy, November 2014.
  # License: Copyright (c) This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

# Export $PATH to work with crontab if you need to, example:
# export PATH="/bin/s3cmd-1.5.0-rc1:/usr/local/pgsql/bin"

##########
## ALL COMMENTED VARIABLES STORED IN HEROKU ENVIRONMENT
##########

# SOURCE DB (Postgres)
#PGHOST=
#PGUSER=
#PGPW=
#DBSCHEMA=public # source schema on your postgres DB. Public is default
# TARGET DB (Redshift)
#RSHOST=your_instance_name.redshift.amazonaws.com
#RSHOSTPORT=5439
#RSADMIN=your_superuser
#RSNAME=your_db_name
#RSKEY=redshift_api_key
#RSSECRET=redshift_api_secret
#RSUSER=your_user_name # name of the non-superuser! who will get read/write access to your schemas and tables. It's critical that you create this user that is not sudo to avoid concurrent connection limits
#RSPW=password for Redshift DB
#RSSCHEMA=public # target schema on your redshift cluster. You could change this, but public is the default schema.
#TMPSCHEMA=temp_refresh
# DIRECTORIES
#PGSQL_BIN=path_to_your_pgsql_bin # your postgres bin directory. Tested with psql 9.3.1
#PYTHONBIN=path_to_your_python_bin # location of your python 2.7.8 executable. Other python version will likely work as well. We install anaconda distribution. Quick and easy
#SCRPTDIR=path_to_your_script_directory where p2r_* scripts live
#SCHEMADIR=path were *.sql schemas should be dumped before cleaning/uploading
#DATADIR=path_to_where_to_dump_db_tables # a place to store table dumps. Make sure it's larger than all the DB tables of interest
#S3BUCKET=name_of_s3_bucket # S3 bucket to which your machine has API read/write privileges to. Must install s3cmd and configure it
# LOGGING
STDERR=/tmp/p2r.err
STDOUT=/tmp/p2r.out
LOCKFILE=/tmp/p2r.lock

# do not add views or functions to redshift. These are actual names of tables in your Postgres database
TABLES='active_cart_counts \
adjustments \
affiliates \
beacons \
building_groups \
buildings \
campus_payment_cards \
canonicalized_json_menus \
canonicalized_menus \
cart_coupons \
cart_item_options \
cart_items \
cart_participants \
carts \
cohort_memberships \
cohort_service_cohorts \
cohort_services \
cohorts \
content \
coupons \
credit_batches \
credit_cards \
credit_items \
customer_addresses \
customer_campus_cards \
customer_coupon_uses \
customer_information_requests \
customer_phones \
customers \
daily_order_counts \
deliveries \
deliveries_hours \
delivery_comments \
delivery_estimates \
delivery_log_entries \
delivery_service_health_features \
delivery_service_health_models \
delivery_service_health_scores \
delivery_service_random_forests \
delivery_services \
delivery_sign_ups \
delivery_status_updates \
delivery_steps \
delivery_zones \
devices \
dispatches \
driver_availabilities \
driver_availability_blocks \
driver_broadcasts \
driver_messages \
driver_points \
driver_restaurant_bans \
driver_work_hours \
drivers \
estimation_model_feature_values \
estimation_model_features \
estimation_models \
franchise_contacts \
gift_cards \
hosted_sites \
jobs \
loyalty_cash_transactions \
market_campus_payment_cards \
market_cities \
market_dispatch_notes \
market_scorecards \
market_weather_hours \
markets \
menu_categories \
menu_category_option_group_option_prices \
menu_category_option_group_options \
menu_category_option_groups \
menu_category_sizes \
menu_descriptors \
menu_item_descriptors \
menu_item_option_group_option_prices \
menu_item_option_group_options \
menu_item_option_groups \
menu_item_sizes \
menu_items \
menu_options \
menu_sizes \
menu_updates \
monthly_order_counts \
newbie_codes \
notification_schedule_changes \
numbers \
option_group_option_prices \
option_group_options \
option_groups \
order_coupons \
order_notifications \
orders \
orders_payments \
pay_period_account_entries \
payments \
pex_cards \
pex_transactions \
print_menus \
promo_codes \
receipts \
referral_codes \
referrals \
reliability_score_events \
restaurant_campus_payment_cards \
restaurant_categories \
restaurant_categorizations \
restaurant_contacts \
restaurant_drive_times \
restaurant_hours \
restaurant_temporary_hours \
restaurant_users \
restaurants \
scorecards \
settings \
shift_assignment_delivery_service_changes \
shift_assignments \
shift_predictions \
shift_templates \
shifts \
shutdown_group_restaurants \
shutdown_groups \
shutdown_messages \
sign_up_links \
sms_messages \
sms_number_reservations \
sms_numbers \
specials \
surveys \
temporary_shutdowns \
users \
voice_calls \
work_segments \
worker_dependency_logs'

# Custom Tables [CT] (some tables are huge due to text data, so you can define custom SQL to either munge your tables or only select certain columns for migration)
# The names of the variables must match actual tables names in the schema. Order commands inside CTSQL list and table names inside CTNAMES list so the indexes of the list match.
# Custom tables must have all the same columns as defined in schema, or you'll have to define a dummy table in your DB or adjust python schema part of the script to accomdate your new table structures
  # If you are just dropping columns (like me), then fill them in with something

## declare an array variable
declare -a CTSQL=( )
CTNAMES=( )
