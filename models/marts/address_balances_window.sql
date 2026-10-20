-- one row per (window output, owner address)
with outputs as (
    select
        t.`hash`,
        o.index as output_index,
        address,
        o.value,
        t.is_coinbase
    from {{ ref('stg_transactions') }} as t,
        unnest(t.outputs) as o,
        unnest(o.addresses) as address
),

-- every outpoint that some input in the window spends (keys only, no address needed)
spent_in_window as (
    select
        i.spent_transaction_hash,
        i.spent_output_index
    from {{ ref('stg_transactions') }} as t,
        unnest(t.inputs) as i
),

-- owners of the coins spent in the window
input_addresses as (
    select address
    from {{ ref('stg_transactions') }} as t,
        unnest(t.inputs) as i,
        unnest(i.addresses) as address
),

-- every address that appears in the window, on outputs or inputs
address_universe as (
    select address from outputs
    union distinct
    select address from input_addresses
),

-- every address that received a coinbase output in the window
coinbase_receivers as (
    select distinct address
    from outputs
    where is_coinbase
),

-- balance from window outputs only: value not spent by any window input
unspent_balance as (
    select
        o.address,
        sum(o.value) as balance_window
    from outputs as o
    where not exists (
        select 1
        from spent_in_window as s
        where s.spent_transaction_hash = o.`hash`
          and s.spent_output_index = o.output_index
    )
    group by o.address
)

select
    u.address,
    coalesce(b.balance_window, 0) as balance_window
from address_universe as u
left join unspent_balance as b
    on b.address = u.address
where not exists (
    select 1
    from coinbase_receivers as c
    where c.address = u.address
)
