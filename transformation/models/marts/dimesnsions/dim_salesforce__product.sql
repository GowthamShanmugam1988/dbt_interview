{{ config(tags=['marts','dimension', 'product']) }}

with product as (
select *
from {{ ref('stg_salesforce__product_2') }}
),
pricebook_entry as (
    select product2id,
            unitprice, 
            row_number() over (partition by product2id order by lastmodifieddate desc) as rn
    from {{ ref('stg_salesforce__pricebook_entry') }}
    where cast(coalesce(isdeleted, false) as boolean) = false
),
latest_price as (
select product2id, unitprice from pricebook_entry
where rn = 1
),
final as ( 
    select
        {{ sf_generate__surrogate_key(['product.product_id']) }} as product_sk,
        product.product_id,
        product.name as product_name,
        product.productcode as product_code,
        product.family as product_family,
        product.description as product_description,
        product.quantityunitofmeasure as unit_of_measure,
        product.stockkeepingunit as sku,
        latest_price.unitprice as list_price,
        cast(coalesce(product.isactive, false) as boolean) as is_active,
        cast(coalesce(product.isarchived, false) as boolean) as is_archived,
        cast(coalesce(product.isdeleted, false) as boolean) as is_deleted,
        product.createddate as product_created_at,
        product.lastmodifieddate as product_last_modified_at
    from product
    Left join latest_price
    on product.product_id = latest_price.product2id
)
select * from final