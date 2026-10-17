{{ config(materialized='view', tags=['experiment']) }}
select salesid, eventid, qtysold, pricepaid, commission, saletime
from {{ source('ds', 'sales') }}
