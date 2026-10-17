-- run on the producer: commit 1,000 new sales rows
INSERT INTO dsdemo.sales
SELECT 50000000 + row_number() OVER (ORDER BY salesid), eventid, sellerid, buyerid, qtysold, pricepaid, commission, getdate()
FROM (SELECT * FROM dsdemo.sales LIMIT 1000);
SELECT count(*) AS producer_rows FROM dsdemo.sales;
