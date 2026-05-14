
{{ config(tags=['marts','dimension', 'contact']) }}

with contact as (
select *
from  {{ ref('stg_salesforce__contact') }}
),

account as (
select account_id, name as account_name from {{ ref('stg_salesforce__account') }}
),

final as (
    select
        {{ sf_generate__surrogate_key(['contact.contact_id'])}} as contact_sk,
        contact.contact_id,
        contact.accountid as account_id,
        account.account_name, 
        contact.salutation, 
        contact.firstname, 
        contact.lastname,
        {{ sf_clean_text("coalesce(contact.firstname, '') || ' ' || coalesce(contact.lastname, '')") }} as contact_full_name,
        contact.email,
        contact.phone,
        contact.mobilephone as mobile_phone, 
        contact.title, 
        contact.department,
        contact.leadsource as lead_source,
        contact.mailingcity as mailing_city, 
        contact.mailingstate as mailing_state,
        contact.mailingcountry as mailing_country,
        contact.level__c as contact_level,
        contact.languages__c as languages,
        cast(coalesce(contact.hasoptedoutofemail, false) as boolean) as has_opted_out_of_email,
        cast(coalesce(contact.donotcall, false) as boolean) as do_not_call,
        cast(coalesce(contact.isdeleted, false) as boolean) as is_deleted,
        contact.createddate as contact_created_at, 
        contact.lastmodifieddate as contact_last_modified_at
    from contact 
    left join account
        on contact.accountid = account.account_id
)

select * from final