\timing on
-- run as the admin user on the consumer workgroup
SET enable_result_cache_for_session TO off;

-- what dbt copied into the consumer
SELECT "table", tbl_rows, size AS size_mb FROM svv_table_info WHERE "schema" = 'analytics' ORDER BY size DESC;

\echo
\echo == report straight on the datashare, run 1
SELECT date_trunc('quarter', saletime)::date AS sale_quarter, count(*) AS sales, sum(pricepaid) AS revenue
FROM tickit.dsdemo.sales
GROUP BY 1 ORDER BY 1;
\echo == report straight on the datashare, run 2
SELECT date_trunc('quarter', saletime)::date AS sale_quarter, count(*) AS sales, sum(pricepaid) AS revenue
FROM tickit.dsdemo.sales
GROUP BY 1 ORDER BY 1;

\echo
\echo == same report on the table dbt copied, run 1
SELECT date_trunc('quarter', saletime)::date AS sale_quarter, count(*) AS sales, sum(pricepaid) AS revenue
FROM analytics.staging_sales
GROUP BY 1 ORDER BY 1;
\echo == same report on the table dbt copied, run 2
SELECT date_trunc('quarter', saletime)::date AS sale_quarter, count(*) AS sales, sum(pricepaid) AS revenue
FROM analytics.staging_sales
GROUP BY 1 ORDER BY 1;

\echo
\echo == same report on the late-binding view, run 1
SELECT date_trunc('quarter', saletime)::date AS sale_quarter, count(*) AS sales, sum(pricepaid) AS revenue
FROM analytics.staging_sales_live
GROUP BY 1 ORDER BY 1;
\echo == same report on the late-binding view, run 2
SELECT date_trunc('quarter', saletime)::date AS sale_quarter, count(*) AS sales, sum(pricepaid) AS revenue
FROM analytics.staging_sales_live
GROUP BY 1 ORDER BY 1;

