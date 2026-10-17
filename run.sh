#!/usr/bin/env bash
# usage: ./run.sh producer|consumer file.sql [user]
# Runs a SQL file with psql (from the postgres docker image) against one of the two workgroups.
set -euo pipefail
cd "$(dirname "$0")"
. "${LAB_ENV:-./lab.env}"
role=$1; file=$2; user=${3:-$ADMIN_USER}
up=$(echo "$role" | tr a-z A-Z); host_var=${up}_HOST
pw=$ADMIN_PW; [ "$user" = dbt_user ] && pw=${DBT_PASSWORD:?set DBT_PASSWORD}
conn="host=${!host_var} port=5439 dbname=dev user=$user sslmode=require connect_timeout=8"
psql() { docker run --rm --network host -e PGPASSWORD="$pw" -v "$PWD:/w" -w /w postgres:16.14 psql "$@"; }

# the public endpoint of a new workgroup sometimes drops the first connection attempts
for i in 1 2 3 4 5 6 7 8; do
  psql "$conn" -qAt -c 'select 1' >/dev/null 2>&1 && break
  [ "$i" = 8 ] && { echo "cannot connect to $role" >&2; exit 1; }
done

psql -v consumer_ns="$CONSUMER_NAMESPACE" -v producer_ns="$PRODUCER_NAMESPACE" -v dbt_pw="${DBT_PASSWORD:-}" "$conn" -e -f "$file"
