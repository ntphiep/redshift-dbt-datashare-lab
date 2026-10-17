select
    eventid,
    eventname,
    starttime,
    current_timestamp as etl_load_timestamp
from {{ source('ds', 'event') }}
