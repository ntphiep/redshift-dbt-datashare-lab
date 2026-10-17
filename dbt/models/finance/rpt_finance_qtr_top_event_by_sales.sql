select sale_quarter, eventname, revenue, event_rank
from (
    select
        sale_quarter,
        eventname,
        revenue,
        row_number() over (partition by sale_quarter order by revenue desc) as event_rank
    from {{ ref('rpt_finance_qtr_total_sales_by_event') }}
)
where event_rank <= 3
