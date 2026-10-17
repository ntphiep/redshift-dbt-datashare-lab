# redshift-dbt-datashare-lab

A small lab for the AWS post
[dbt and Amazon Redshift Data Sharing: Multi-cluster pipelines without moving a byte](https://aws.amazon.com/blogs/big-data/dbt-and-amazon-redshift-data-sharing-multi-cluster-pipelines-without-moving-a-byte/).
It checks what the different dbt materializations cost when the source is a datashare.

The setup is two Redshift Serverless workgroups at 4 RPU each, in one account. The producer holds a
synthetic `dsdemo.sales` table with 50M rows, plus `event` (20k rows) and `users` (200k rows), and shares
them as `dbtdsdemo`. The consumer creates a database `tickit` from the datashare. dbt Core 1.12 with
dbt-redshift 1.11 runs on a laptop and builds models into the consumer's `dev` database.

## What I found

| Check | Result | File |
|---|---|---|
| dbt `table` model on the share (`staging_sales`) | copies 50M rows, 1,792 MB on the consumer | `results/05_compare.out` |
| Time to build that model | 43.9 s, then 19.7 s on a second run | `results/03_dbt_build.log`, `results/07_dbt_refresh.log` |
| dbt `view` model on the share | fails with "External tables are not supported in views" | `results/04_dbt_views.log` |
| dbt `view` with `bind=False` (late-binding view) | works, stores nothing, 9.6 s | `results/04_dbt_views.log` |
| Quarterly report on the share, the copied table, the late-binding view | 0.7 to 0.9 s on all three | `results/05_compare.out` |
| 1,000 rows committed on the producer | the share and the late-binding view return them on the next query, the copied table does not until dbt runs again | `results/06_freshness.out` |

The AWS post says the same about `table` (data is copied at build time) and lists `bind=false` as the live
option. The lab puts numbers on that choice.

Two other things worth knowing:

- `datasharing: true` is a profile option of dbt-redshift. In my run a `table` model on the share also
  built with it set to false, so I can't say what it changes for other model types.
- `CREATE DATABASE ... WITH PERMISSIONS FROM DATASHARE` needs explicit `GRANT USAGE` on the database and
  schema, and `GRANT SELECT` on each table, for `dbt_user`, see `sql/02_consumer.sql`.

These numbers are from one pair of workgroups and synthetic data. Treat them as relative.

## Running it

You need the AWS CLI with permissions for Redshift Serverless and EC2 security groups, a default VPC in
the region, Docker (for `psql`) and [uv](https://docs.astral.sh/uv/).

```bash
./setup.sh                                  # about 2 minutes, writes lab.env
./run.sh producer sql/01_producer.sql       # data and the datashare
export DBT_PASSWORD=...                     # any password that meets the Redshift rules
./run.sh consumer sql/02_consumer.sql       # needs DBT_PASSWORD, creates dbt_user and the tickit database

cd dbt
set -a; . ../lab.env; set +a
export DBT_PROFILES_DIR=$PWD
uv run --with dbt-redshift==1.11.1 --with dbt-core==1.12.6 dbt build --exclude tag:experiment
uv run --with dbt-redshift==1.11.1 --with dbt-core==1.12.6 dbt run --select tag:experiment
cd ..

./run.sh consumer sql/05_compare.sql
./freshness.sh
./teardown.sh                               # deletes everything setup.sh created
```

`setup.sh` opens port 5439 only to your current public IP. Settings such as `REGION`, `NAME` and
`BASE_RPU` can be overridden with environment variables. Workgroups bill per second of compute, so run
`teardown.sh` when you are done.

## Layout

```
setup.sh, teardown.sh     create and delete the AWS resources
run.sh, freshness.sh      run a SQL file with psql, commit rows and compare counts
sql/                      the Redshift side, files are numbered in the order they run
dbt/                      the dbt project, staging and finance models like the AWS post, plus two experiments
results/                  output of my run
```
