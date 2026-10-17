\timing on
-- run as the admin user on the consumer workgroup
CREATE USER dbt_user PASSWORD :'dbt_pw';

SELECT share_name, share_type, producer_namespace FROM svv_datashares;

CREATE DATABASE tickit WITH PERMISSIONS FROM DATASHARE dbtdsdemo OF NAMESPACE :'producer_ns';

GRANT USAGE ON DATABASE tickit TO dbt_user;
GRANT USAGE ON SCHEMA tickit.dsdemo TO dbt_user;
GRANT SELECT ON tickit.dsdemo.event, tickit.dsdemo.sales, tickit.dsdemo.users TO dbt_user;
-- dbt_user builds its models in the local database
GRANT CREATE ON DATABASE dev TO dbt_user;

SELECT count(*) AS sales_rows FROM tickit.dsdemo.sales;
