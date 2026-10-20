{{ config(severity='error') }}

-- Fails with one row per mart address that received a coinbase output in the window.
-- Rebuilt straight from staging, independently of the mart's own exclusion.
with coinbase_outputs as (
    select coinbase_address
    from {{ ref('stg_transactions') }} as t,
        unnest(t.outputs) as o,
        unnest(o.addresses) as coinbase_address
    where t.is_coinbase
)

select distinct
    m.address
from {{ ref('address_balances_window') }} as m
inner join coinbase_outputs as c
    on c.coinbase_address = m.address
