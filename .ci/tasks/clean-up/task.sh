#!/bin/sh
set -eu
export DIR="${PWD}"
cd ${DIR}/secret-source/examples/${directory}
DB_INDENTIFIER=`grep name_prefix main.tf | sed 's/^[^"]*"\([^"]*\)".*/\1/'`-final-none
rds delete-db-snapshot --db-snapshot-identifier $DB_INDENTIFIER