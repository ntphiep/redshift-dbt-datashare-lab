-- run on the consumer: row count as seen through each access path
SELECT 'datashare' AS source, count(*) AS rows FROM tickit.dsdemo.sales
UNION ALL SELECT 'dbt table copy', count(*) FROM analytics.staging_sales
UNION ALL SELECT 'late-binding view', count(*) FROM analytics.staging_sales_live;
