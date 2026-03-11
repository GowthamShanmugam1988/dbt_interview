{{ config(tags= ['intermediate','sales','opportunity']) }}

{% set lifecycle_flags = ['isclosed','iswon']%}

with opportunity as (
    select *
    from {{ ref('stg_salesforce__opportunity') }}
),
account as (
    select account_id,
           name as account_name,
           industry,
           type as account_type
    from {{ ref('stg_salesforce__account') }}
),
contact as (
    select contact_id,
           firstname,
           lastname,
           email
    from {{ ref('stg_salesforce__contact') }}
),
campaign as (
    select campaign_id,
           name as campaign_name,
           type as campaign_type
    from {{ ref('stg_salesforce__campaign') }}
),
owner as (
    select user_id,
           firstname,
           lastname
    from {{ ref('stg_salesforce__user') }}
),

enriched as (
    select 
        {{ sf_generate__surrogate_key(['opportunity.opportunity_id']) }} as opportunity_sk,
        opportunity.opportunity_id,
        opportunity.name as opportunity_name,
        opportunity.accountid as account_id,
        opportunity.contactid as contact_id,
        opportunity.campaignid as campaign_id,
        opportunity.ownerid as owner_user_id,
        opportunity.name as opportunity_name,
        opportunity.stagename,
        {{ sf_stage_bucket('opportunity.stagename') }} as stage_bucket,
        opportunity.stagesortorder,
        opportunity.amount,
        opportunity.expectedrevenue,
        opportunity.probability,
        opportunity.closedate,
        opportunity.createddate,
        opportunity.laststagechangedate,
        opportunity.forecastcategoryname,
        opportunity.deliveryinstallationstatus__c,
        opportunity.currentgenerators__c,
        opportunity.maincompetitors__c,
        {% for flag in lifecycle_flags %}
        cast(coalesce(opportunity.{{ flag }}, false) as boolean) as {{ flag }},
        {% endfor %}
        row_number() over (partition by opportunity.accountid order by opportunity.createddate desc,opportunity.opportunity_id) as account_opportunity_rank_desc,
        account.account_name,
        account.industry as account_industry,
        account.account_type,
        {{ sf_clean_text("coalesce(contact.firstname,'') || ' ' || coalesce(contact.lastname,'')") }} as contact_full_name,
        contact.email as contact_email,
        campaign.campaign_name,
        campaign.campaign_type,
        {{ sf_clean_text("coalesce(owner.firstname,'') || ' ' || coalesce(owner.lastname,'')") }} as owner_full_name
    from opportunity
    left join account on opportunity.accountid = account.account_id
    left join contact on opportunity.contactid = contact.contact_id
    left join campaign on opportunity.campaignid = campaign.campaign_id
    left join owner on opportunity.ownerid = owner.user_id
)
select * from enriched