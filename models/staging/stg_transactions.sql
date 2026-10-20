{%- set window_end = var('window_end_date') -%}
select
    `hash`,
    block_timestamp,
    is_coinbase,
    inputs,
    outputs
from {{ source('crypto_bitcoin_cash', 'transactions') }}
-- constant month bounds: BigQuery prunes to the 4 partitions of the window
where block_timestamp_month >= date_trunc(date_sub(date '{{ window_end }}', interval 3 month), month)
  and block_timestamp_month <= date_trunc(date '{{ window_end }}', month)
-- exact window in UTC: [end - 3 months, end + 1 day)
  and block_timestamp >= timestamp(date_sub(date '{{ window_end }}', interval 3 month), 'UTC')
  and block_timestamp < timestamp(date_add(date '{{ window_end }}', interval 1 day), 'UTC')
