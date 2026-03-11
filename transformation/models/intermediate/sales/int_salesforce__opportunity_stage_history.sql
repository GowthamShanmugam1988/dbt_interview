{{ config(tags= ['intermediate','sales','opportunity']) }}

with opportunity_history as (
    select *
    from {{ ref('stg_salesforce__opportunity_history') }}
),
opportunity as (
    select opportunity_id,accountid as account_id,ownerid as owner_user_id
    from {{ ref('stg_salesforce__opportunity') }}
),
joined as (
    select 
        {{ sf_generate__surrogate_key(['opportunity_history.opportunity_history_id']) }} as stage_change_sk,
        opportunity_history.opportunity_history_id,
        opportunity_history.opportunityid as opportunity_id,
        opportunity.account_id,
        opportunity.owner_user_id,
        opportunity_history.stagename,
        opportunity_history.createddate as stage_changed_at,
        {{ sf_stage_bucket('opportunity_history.stagename') }} as stage_bucket,
        opportunity_history.amount,
        opportunity_history.expectedrevenue,
        opportunity_history.probability,
        opportunity_history.forecastcategory,
        opportunity_history.closedate,
        lag(opportunity_history.stagename) over (partition by opportunity_history.opportunityid 
            order by opportunity_history.createddate,opportunity_history.opportunity_history_id) as previous_stage_name,
        row_number() over (partition by opportunity_history.opportunityid 
            order by opportunity_history.createddate,opportunity_history.opportunity_history_id) as opportunity_stage_rank_desc,
        opportunity_history.systemmodstamp
    from opportunity_history
    left join opportunity
    on opportunity.opportunity_id = opportunity_history.opportunityid
),

final as (
    select
        stage_change_sk,
        opportunity_history_id,
        opportunity_id,
        account_id,
        owner_user_id,
        stagename,
        stage_changed_at,
        stage_bucket,
        previous_stage_name,
        case when previous_stage_name is null then false else opportunity_stage_rank_desc end as is_stage_transition,
        case when opportunity_stage_rank_desc = 1 then true else false end as is_latest_stage_record,
        amount,
        expectedrevenue,
        probability,
        forecastcategory,
        closedate,
        systemmodstamp
    from joined
        
)
select * from final