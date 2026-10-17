\timing on
-- synthetic TICKIT-like tables: 50M sales, 20k events, 200k users
CREATE SCHEMA dsdemo;

CREATE TEMP TABLE n AS
WITH RECURSIVE t(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM t WHERE i < 1000)
SELECT i FROM t;

CREATE TABLE dsdemo.users AS
SELECT ((a.i - 1) * 200 + b.i)::int AS userid,
       'user' || ((a.i - 1) * 200 + b.i) AS username,
       decode((random() * 7)::int, 0,'CA', 1,'NY', 2,'TX', 3,'WA', 4,'FL', 5,'IL', 6,'CO', 'MA') AS state
FROM n a, n b WHERE a.i <= 1000 AND b.i <= 200;

CREATE TABLE dsdemo.event AS
SELECT ((a.i - 1) * 20 + b.i)::int AS eventid,
       'event ' || ((a.i - 1) * 20 + b.i) AS eventname,
       dateadd(day, (random() * 700)::int, '2024-01-01'::timestamp) AS starttime
FROM n a, n b WHERE a.i <= 1000 AND b.i <= 20;

CREATE TABLE dsdemo.sales AS
SELECT salesid, eventid, sellerid, buyerid, qtysold, pricepaid,
       (pricepaid * 0.15)::decimal(8,2) AS commission, saletime
FROM (
  SELECT ((c.i - 1) * 1000000 + (a.i - 1) * 1000 + b.i)::bigint AS salesid,
         (random() * 19999)::int + 1 AS eventid,
         (random() * 199999)::int + 1 AS sellerid,
         (random() * 199999)::int + 1 AS buyerid,
         (random() * 7)::int + 1 AS qtysold,
         ((random() * 900)::int + 20)::decimal(8,2) AS pricepaid,
         dateadd(second, (random() * 63072000)::int, '2024-01-01'::timestamp) AS saletime
  FROM n a, n b, n c WHERE c.i <= 50
);

SELECT 'sales' AS tbl, count(*) FROM dsdemo.sales
UNION ALL SELECT 'event', count(*) FROM dsdemo.event
UNION ALL SELECT 'users', count(*) FROM dsdemo.users;

SELECT current_namespace;

-- the datashare, as in the AWS post
CREATE DATASHARE dbtdsdemo SET PUBLICACCESSIBLE TRUE;
ALTER DATASHARE dbtdsdemo ADD SCHEMA dsdemo;
ALTER DATASHARE dbtdsdemo ADD TABLE dsdemo.event, dsdemo.sales, dsdemo.users;
GRANT USAGE ON DATASHARE dbtdsdemo TO NAMESPACE :'consumer_ns';
