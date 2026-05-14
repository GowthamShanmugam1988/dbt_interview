--  Singular test : every closed-won opportunity must have a postive enount.
--  Returns falling rows, (test passes when result set is empty).

select
    opportunity_id, 
    current_stage_name, 
    amount
from {{ ref('fct_salesforce__opportunity') }}
where iswon = true
and (amount is null or amount < 0)