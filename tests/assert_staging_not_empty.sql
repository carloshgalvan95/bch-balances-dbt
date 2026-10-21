select n_rows
from (select count(*) as n_rows from {{ ref('stg_transactions') }})
where n_rows = 0
