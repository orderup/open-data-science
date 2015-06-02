import os

from subprocess import call
call(["postgres2redshift/p2r_main.sh", "-h", os.environ['PGHOST'], "-p", os.environ['PGPORT'], "-d", os.environ['PGDB'], "-U", os.environ['PGUSER']])
