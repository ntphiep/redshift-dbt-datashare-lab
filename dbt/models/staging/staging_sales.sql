select
    salesid,
    eventid,
    sellerid,
    buyerid,
    qtysold,
    pricepaid,
    commission,
    saletime,
    current_timestamp as etl_load_timestamp
from {{ source('ds', 'sales') }}
