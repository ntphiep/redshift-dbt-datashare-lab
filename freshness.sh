#!/usr/bin/env bash
# Counts rows on the consumer, commits 1,000 rows on the producer, counts again right away.
set -euo pipefail
cd "$(dirname "$0")"
echo "== before"; ./run.sh consumer sql/06_freshness.sql
echo "== insert on the producer"; ./run.sh producer sql/06_insert_rows.sql
echo "== after"; ./run.sh consumer sql/06_freshness.sql
