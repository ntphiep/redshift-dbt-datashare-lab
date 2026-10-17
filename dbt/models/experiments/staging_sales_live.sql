{{ config(materialized='view', bind=False, tags=['experiment']) }}
select salesid, eventid, qtysold, pricepaid, commission, saletime
from {{ source('ds', 'sales') }}
