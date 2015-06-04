#!/bin/bash

### LICENSE
  # Author: Vlad Dubovskiy, November 2014, DonorsChoose.org
  # Special thanks to: David Crane for code snippets on parsing command args
  # License: Copyright (c) This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

# Load settings, tables file
cd /dump/scripts/open-data-science/postgres2redshift
source ./p2r_settings.sh


########################################
#           Data Dump: Params
########################################

# Open lock file sentinal protection
# This section parses command line arguments when you execute the script with /path/to/p2r_main.sh -h source_db_host_name -p 5432 -U dbuser -d dbname 2>&1 >> /tmp/p2r.log

if [ ! -e $LOCKFILE ]; then
  echo "***********************************"
  echo $$ >$LOCKFILE

PROGNAME=`basename $0`

usage ()
{
  echo "usage:  $PROGNAME"
}

# Close lock file sentinal protection.
# If you are dumping from hot standby replication server, you can wrap the code here and move removing lockfile right before SHIPPPING TABLES TO S3
# This is here for your convenience, it's not a requirement to have this.
  rm $LOCKFILE
else
  echo "  +------------------------------------"
  echo -n "  | "
  date
  echo "  | critical-section is already running"
  echo "  +------------------------------------"
fi

########################################
#           Begin Data Dump
########################################

echo DUMPING TABLES
date

# dumping original tables
export PGPASSWORD=$PGPW
for table in $TABLES
do
  $PGSQL_BIN/psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDB -c \
    "\copy ${table} TO STDOUT (FORMAT csv, DELIMITER '|', HEADER 0)" \
    | gzip > $DATADIR/${table}.txt.gz
done

# dumping custom tables
export PGPASSWORD=$PGPW
for (( i = 0 ; i < ${#CTSQL[@]} ; i++ ))
do
  $PGSQL_BIN/psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDB -c \
    "\copy ( ${CTSQL[$i]} ) TO STDOUT (FORMAT csv, DELIMITER '|', HEADER 0)" \
    | gzip > $DATADIR/${CTNAMES[$i]}.txt.gz
done

echo DUMPING TABLES COMPLETE
date

########################################
#          SHIP TABLES TO S3
########################################

echo SHIP TO S3
date

# ship original tables
for table in $TABLES
do
  s3cmd put $DATADIR/${table}.txt.gz s3://$S3BUCKET/ --force 1>>$STDOUT 2>>$STDERR
done

# ship custom tables
for table in ${CTNAMES[@]}
do
  s3cmd put $DATADIR/${table}.txt.gz s3://$S3BUCKET/ --force 1>>$STDOUT 2>>$STDERR
done

echo SHIP TO S3 COMPLETE
date


########################################
#       Get and clean schema
########################################

echo GET/CLEAN/UPLOAD DB SCHEMA
date

# remove any schema* files from the directory
rm -rf $SCHEMADIR/schema*

# Dump DB's schema
export PGPASSWORD=$PGPW
$PGSQL_BIN/pg_dump -h $PGHOST -p $PGPORT -U $PGUSER --schema-only --schema=$DBSCHEMA $PGDB > $SCHEMADIR/schema.sql

##### 1. Cleanup the schema to conform to RedShift syntax

## Only keep CREATE TABLE statements
sed -n '/CREATE TABLE/,/);/p' $SCHEMADIR/schema.sql > $SCHEMADIR/schema_clean.sql
## Append ALTER TABLE statements
sed -n '/ALTER TABLE/,/;/p' $SCHEMADIR/schema.sql >> $SCHEMADIR/schema_clean.sql

## Cleanup ALTER TABLE statements
# Only keep PRIMARY KEYS, FOREIGN KEYS and UNIQUE. Current regex requires that the ALTER TABLE statement spaces two lines
# http://unix.stackexchange.com/questions/26284/how-can-i-use-sed-to-replace-a-multi-line-string
# http://stackoverflow.com/questions/6361312/negative-regex-for-perl-string-pattern-match
perl -0777 -i -pe 's/ALTER TABLE(?!UNIQUE|PRIMARY|FOREIGN).*;//g' $SCHEMADIR/schema_clean.sql
# Remove ONLY statement that is not supported
perl -0777 -i -pe 's/ALTER TABLE ONLY/ALTER TABLE/g' $SCHEMADIR/schema_clean.sql
# Remove CHECK CONSTRAINTS that Redshift doesn't support, along with last comma
perl -0777 -i -pe 's/,\n(\s*CONSTRAINT.*\n)*(?=\)\;)//g' $SCHEMADIR/schema_clean.sql
# Remove iterators on columns
sed -i.bak 's/DEFAULT nextval.*/NOT NULL,/g' $SCHEMADIR/schema_clean.sql
# Remove system DB tables
sed -i.bak '/CREATE TABLE dba_snapshot*/,/);/d' $SCHEMADIR/schema_clean.sql
sed -i.bak '/CREATE TABLE jbpm*/,/);/d' $SCHEMADIR/schema_clean.sql
sed -i.bak '/ALTER TABLE jbpm*/,/;/d' $SCHEMADIR/schema_clean.sql
# Remove unsupported types
sed -i.bak 's/geometry(.*)/text/g' $SCHEMADIR/schema_clean.sql
sed -i.bak 's/int4range/text/g' $SCHEMADIR/schema_clean.sql
sed -i.bak 's/integer\[\]/text/g' $SCHEMADIR/schema_clean.sql
# Remove unsupported commands and types (json, numeric(45)
sed -i.bak 's/ON DELETE CASCADE//g' $SCHEMADIR/schema_clean.sql
sed -i.bak 's/ON UPDATE CASCADE//g' $SCHEMADIR/schema_clean.sql
sed -i.bak 's/SET default.*//g' $SCHEMADIR/schema_clean.sql
sed -i.bak 's/ NOT NULL//g' $SCHEMADIR/schema_clean.sql
#convert any weakly defined numeric columns to numeric(19,6)
sed -i.bak 's/numeric(45/numeric(37/g' $SCHEMADIR/schema_clean.sql
sed -i.bak 's/numeric,/numeric(19,6),/g' $SCHEMADIR/schema_clean.sql
sed -i.bak 's/numeric /numeric(19,6) /g' $SCHEMADIR/schema_clean.sql
sed -i.bak 's/numeric$/numeric(19,6)/g' $SCHEMADIR/schema_clean.sql
#convert json column to text
sed -i.bak 's/json/text/g' $SCHEMADIR/schema_clean.sql
sed -i.bak 's/json NOT NULL/text NOT NULL/g' $SCHEMADIR/schema_clean.sql
# Replace columns named "open" with "open_date", as "open" is a reserved word. Other Redshift reserved words: time, user
sed -i.bak 's/open character/open_date character/g' $SCHEMADIR/schema_clean.sql
# TEXT type is not supported and auto converted, so need to enforce boundless varchar instead: http://docs.aws.amazon.com/redshift/latest/dg/r_Character_types.html
# Also, remove all NOT NULL constraints on varchar/text types that break import due to collision with Redshift's BLANKSASNULL AND EMPTYASNULL copy flags
# Removing NOT NULL on some tables may cause index errors in redshift.err log. If the issue cause problems, then just edit the regex to keep NOT NULL on columns that are supposed to be PRIMARY KEY
sed -i.bak -e 's/\(.*\) \(\btext\b\|\bcharacter varying\b.*\) NOT NULL/\1 \2/' \
      -e 's/\(.*\) \btext\b/\1 varchar(max)/' $SCHEMADIR/schema_clean.sql
# Custom Cleaning (add any regex to clean out other edge cases if your schema fails to build in Redshift)
sed -i.bak '/CREATE TABLE your_unwanted_table_name*/,/);/d' $SCHEMADIR/schema_clean.sql


##### 2. Add sortkeys to table definitions (python script)

$PYTHONBIN $SCRPTDIR/p2r_add_sortkeys.py -i $SCHEMADIR/schema_clean.sql -o $SCHEMADIR/schema_final.sql

# take a nap for 30 seconds while python script completes (there are better approaches in notes)
sleep 30

##### 3. Add ALTER TABLE statements back to the final schema file

sed -n '/ALTER TABLE/,/;/p' $SCHEMADIR/schema_clean.sql >> $SCHEMADIR/schema_final.sql

##### 4. Restore data into a new schema, instead of nuking current schema

# add search_path to temp_schema
sed -i "1 i SET search_path TO ${TMPSCHEMA};" $SCHEMADIR/schema_final.sql

echo CREATE NEW TEMP SCHEMA
export PGPASSWORD=$RSPW
$PGSQL_BIN/psql -h $RSHOST -p $RSHOSTPORT -U $RSADMIN -d $RSNAME -c \
  "CREATE SCHEMA $TMPSCHEMA;
  SET search_path TO $TMPSCHEMA;
  GRANT ALL ON SCHEMA $TMPSCHEMA TO $RSUSER;
  GRANT USAGE ON SCHEMA $TMPSCHEMA TO $RSUSER;
  GRANT SELECT ON ALL TABLES IN SCHEMA $TMPSCHEMA TO $RSUSER;
  COMMENT ON SCHEMA $TMPSCHEMA IS 'temporary refresh schema';" 1>>$STDOUT 2>>$STDERR

##### 5. Load schema file into TMPSCHEMA
export PGPASSWORD=$RSPW
$PGSQL_BIN/psql -h $RSHOST -p $RSHOSTPORT -U $RSADMIN -d $RSNAME -f $SCHEMADIR/schema_final.sql 1>>$STDOUT 2>>$STDERR


########################################
#        Restore in Redshift
########################################


echo START RESTORE TABLES IN REDSHIFT
date

# Copy a table into Redshift from S3 file:
  # To test without the data load, add NOLOAD to the copy command.
  # CSV cannot be used with FIXEDWIDTH, REMOVEQUOTES, or ESCAPE.
  # Remove MAXERROR from production. Analysize /tmp/p2r.err for error log
  # NULLify empties: BLANKSASNULL, EMPTYASNULL.

# restore original tables
export PGPASSWORD=$RSPW
for table in $TABLES
do
  $PGSQL_BIN/psql -h $RSHOST -p $RSHOSTPORT -U $RSADMIN -d $RSNAME -c \
    "SET search_path TO $TMPSCHEMA;
    copy ${table} from 's3://$S3BUCKET/${table}.txt.gz' \
      CREDENTIALS 'aws_access_key_id=$RSKEY;aws_secret_access_key=$RSSECRET' \
      CSV DELIMITER '|' IGNOREHEADER 0 ACCEPTINVCHARS TRUNCATECOLUMNS GZIP TRIMBLANKS BLANKSASNULL EMPTYASNULL DATEFORMAT 'auto' ACCEPTANYDATE COMPUPDATE ON MAXERROR 500;" 1>>$STDOUT 2>>$STDERR
done

# restore custom tables
export PGPASSWORD=$RSPW
for table in ${CTNAMES[@]}
do
  $PGSQL_BIN/psql -h $RSHOST -p $RSHOSTPORT -U $RSADMIN -d $RSNAME -c \
    "SET search_path TO $TMPSCHEMA;
    copy ${table} from 's3://$S3BUCKET/${table}.txt.gz' \
      CREDENTIALS 'aws_access_key_id=$RSKEY;aws_secret_access_key=$RSSECRET' \
      CSV DELIMITER '|' IGNOREHEADER 0 ACCEPTINVCHARS TRUNCATECOLUMNS GZIP TRIMBLANKS BLANKSASNULL EMPTYASNULL DATEFORMAT 'auto' ACCEPTANYDATE COMPUPDATE ON MAXERROR 100;" 1>>$STDOUT 2>>$STDERR
done

# Swap temp_schema for production schema
export PGPASSWORD=$RSPW
echo DROP $RSSCHEMA AND RENAME $TMPSCHEMA SCHEMA TO $RSSCHEMA
$PGSQL_BIN/psql -h $RSHOST -p $RSHOSTPORT -U $RSADMIN -d $RSNAME -c \
  "SET search_path TO $RSSCHEMA;
  DROP SCHEMA IF EXISTS $RSSCHEMA CASCADE;
  ALTER SCHEMA $TMPSCHEMA RENAME TO $RSSCHEMA;
  GRANT ALL ON SCHEMA $RSSCHEMA TO $RSUSER;
  GRANT USAGE ON SCHEMA $RSSCHEMA TO $RSUSER;
  GRANT SELECT ON ALL TABLES IN SCHEMA $RSSCHEMA TO $RSUSER;
  GRANT ALL ON SCHEMA $RSSCHEMA TO $LOOKERUSER;
  GRANT USAGE ON SCHEMA $RSSCHEMA TO $LOOKERUSER;
  GRANT SELECT ON ALL TABLES IN SCHEMA $RSSCHEMA TO $LOOKERUSER;
  COMMENT ON SCHEMA $RSSCHEMA IS 'analytics data schema';" 1>>$STDOUT 2>>$STDERR

echo RESTORE TABLES COMPLETE
date

echo START VACUUM ANALYZE
export PGPASSWORD=$RSPW
$PGSQL_BIN/psql -h $RSHOST -p $RSHOSTPORT -U $RSADMIN -d $RSNAME -c "vacuum; analyze;" 1>>$STDOUT 2>>$STDERR

echo BULK REFRESH COMPLETE

date
echo "***********************************"


########################################
#        COPY Error Management
########################################

# table.columnx has a wrong date format error:
  # solution: DATEFORMAT 'auto' ACCEPTANYDATE options, which NULLs any unrecognized date formats

# Query to check errors in redshift
  # select starttime, filename, line_number, colname, position, raw_line, raw_field_value, err_code, err_reason
  # from stl_load_errors
  # where filename like ('%table_name%')
  # order by starttime DESC
  # limit 110;

########################################
#        Future Improvements
########################################

  # replace wait with proper PIDs: http://stackoverflow.com/questions/356100/how-to-wait-in-bash-for-several-subprocesses-to-finish-and-return-exit-code-0
  # Iterative refresh: incremental inserts (say, every hour) instead of dumping the entire schema or individual tables. Remember to vacuum; analyze; afterwards
