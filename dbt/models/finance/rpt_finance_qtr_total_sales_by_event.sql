select
    date_trunc('quarter', s.saletime)::date as sale_quarter,
    e.eventname,
    count(*) as sales,
    sum(s.qtysold) as tickets,
    sum(s.pricepaid) as revenue,
    sum(s.commission) as commission,
    sum(s.commission) / nullif(sum(s.pricepaid), 0) as commission_rate
from {{ ref('staging_sales') }} s
join {{ ref('staging_event') }} e on e.eventid = s.eventid
group by 1, 2
