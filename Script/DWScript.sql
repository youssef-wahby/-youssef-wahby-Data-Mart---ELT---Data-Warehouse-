if object_id('silver.crm_cust_info','U')is not null
	drop table silver.crm_cust_info
create table silver.crm_cust_info(
cst_id int,
cst_key nvarchar(50),
cst_firstname nvarchar(50),
cst_lastname nvarchar(50),
cst_material_status nvarchar(50),
cst_gndr nvarchar(50),
cst_create_date date )
go
if object_id('silver.crm_prd_info','U')is not null
	drop table silver.crm_prd_info
create table silver.crm_prd_info(
prd_id int,
prd_key nvarchar(50),
prd_nm nvarchar(50),
prd_cost int,
prd_start_dt datetime ,
prd_end_dt datetime)
IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
GO

CREATE TABLE silver.crm_sales_details (
    sls_ord_num     NVARCHAR(50),
    sls_prd_key     NVARCHAR(50),
    sls_cust_id     INT,
    sls_order_dt    DATE,
    sls_ship_dt     DATE,
    sls_due_dt      DATE,
    sls_sales       INT,
    sls_quantity    INT,
    sls_price       INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;
GO

CREATE TABLE silver.erp_loc_a101 (
    cid             NVARCHAR(50),
    cntry           NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;
GO

CREATE TABLE silver.erp_cust_az12 (
    cid             NVARCHAR(50),
    bdate           DATE,
    gen             NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;
GO

CREATE TABLE silver.erp_px_cat_g1v2 (
    id              NVARCHAR(50),
    cat             NVARCHAR(50),
    subcat          NVARCHAR(50),
    maintenance     NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO
-- make sure we are on the latest data
insert into silver.crm_cust_info(
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_material_status,
    cst_gndr,
    cst_create_date
)
select
cst_id,
cst_key,
trim(cst_firstname) as cst_firstname,
trim(cst_lastname) as cst_lastname,
case when upper(trim(cst_material_status))= 'M' then 'Married'
     when upper(trim(cst_material_status))='S' then 'Single'
     else 'n/a'
end cst_material_status,
case when upper(trim(cst_gndr))= 'F' then 'Female'
     when upper(trim(cst_gndr))='M' then 'Male'
     else 'n/a'
end cst_gndr,
cst_create_date
from(
select 
* ,
ROW_NUMBER() over (partition by cst_id order by cst_create_date desc) as flag_last
from bronze.crm_cust_info 
where cst_id is not null
)t where flag_last = 1
-- check for unwanted data
-- Expecation is no result :)
select  cst_lastname
from silver.crm_cust_info
where cst_lastname != trim(cst_lastname)
-- Data standardization& consistency
select distinct cst_gndr
from bronze.crm_cust_info
-------
select 
cst_id,
count(*)
from silver.crm_cust_info
group by cst_id
having count(*) > 1 or cst_id is null
select * from silver.crm_cust_info
--------------------------------------------
if object_id('silver.crm_prd_info','U')is not null
	drop table silver.crm_prd_info;
create table silver.crm_prd_info(
prd_id int,
cat_id nvarchar(50),
prd_key nvarchar(50),
prd_nm nvarchar(50),
prd_cost int,
prd_line nvarchar(50),
prd_start_dt date ,
prd_end_dt date,
dwh_create_date datetime2 default getdate())
insert into silver.crm_prd_info(
prd_id,
cat_id,
prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
)
select 
prd_id,
replace(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
SUBSTRING(prd_key,7,len(prd_key)) AS prd_key,
prd_nm,
isnull(prd_cost,0) as prd_cost,
case when upper(trim(prd_line))='M'then'Mountain'
     when upper(trim(prd_line))='R'then'Road'
     when upper(trim(prd_line))='S'then'Other sales'
     when upper(trim(prd_line))='T'then'Touring'
     else 'n/a'
end as prd_line,
cast(prd_start_dt as Date) as prd_start_dt,
cast(lead(prd_start_dt) over (partition by prd_key order by prd_start_dt)-1 as date) as prd_end_dt
from bronze.crm_prd_Info
select * from silver.crm_prd_info
-----------------------------------
if object_id ('silver.crm_sales_details','U') is not null
    drop table silver.crm_sales_details;
CREATE TABLE silver.crm_sales_details (
    sls_ord_num     NVARCHAR(50),
    sls_prd_key     NVARCHAR(50),
    sls_cust_id     INT,
    sls_order_dt    DATE,
    sls_ship_dt     DATE,
    sls_due_dt      DATE,
    sls_sales       INT,
    sls_quantity    INT,
    sls_price       INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
insert into silver.crm_sales_details(
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
)
select 
sls_ord_num,
sls_prd_key,
sls_cust_id,
case when sls_order_dt = 0 or len(sls_order_dt) != 8 then null
     else cast(cast(sls_order_dt as varchar) as date)
end as sls_order_dt,
case when sls_ship_dt = 0 or len(sls_ship_dt) != 8 then null
     else cast(cast(sls_ship_dt as varchar) as date)
end as sls_ship_dt,
case when sls_due_dt = 0 or len(sls_due_dt) != 8 then null
     else cast(cast(sls_due_dt as varchar) as date)
end as sls_due_dt,
sls_quantity,
case when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * ABS(sls_price)
     then sls_quantity * ABS(sls_price) 
     else sls_sales
end as sls_sales, 
case when sls_price is null or sls_price <=0 
     then sls_sales / nullif(sls_quantity,0)
     else sls_price
end as sls_price

from bronze.crm_sales_details
--------------------------------------------
insert into silver.erp_cust_az12(cid,bdate,gen)
select 
case when cid like 'nas%' then substring(cid,4,len(cid))
    else cid
end as cid ,
case when bdate> getdate() then null
    else bdate
end as bdate ,
gen
from bronze.erp_cust_az12
----------------------
insert into silver.erp_loc_a101(cid , cntry)
select 
replace(cid,'-','')cid,
case when Trim(cntry)= 'DE' THEN 'Germany'
     when Trim(cntry) IN ('US','USA') THEN 'United States'
     when Trim(cntry) = '' or cntry IS null then 'n/a'
     else trim(cntry)
end as cntry
from bronze.erp_loc_a101
---------------------------------
insert into silver.erp_px_cat_g1v2(id,cat,subcat,maintenance )
select id,cat,subcat,maintenance from bronze.erp_px_cat_g1v2
 
--------------------



--------------------

-- check for nulls or duplicates in primary key 
select 
prd_id,
count(*)
from bronze.crm_prd_info
group by prd_id
having count(*)>1 or prd_id is null
select distinct id from bronze.erp_px_cat_g1v2
----------------------------------------------
--GOLDEN LAYER--
----------------------------------------------
create view gold.dim_customers as 
select 
        row_number() over(order by cst_id) as customer_key,
        ci.cst_id as customer_id, 
        ci.cst_key as customer_number,
        ci.cst_firstname as Fisrt_name,
        ci.cst_lastname as Last_name,
        la.cntry as Country,
        ci.cst_material_status as Maritial_status,
        case when ci.cst_gndr != 'n/a' then ci.cst_gndr -- crm is master 
             else coalesce (ca.gen, 'n/a')
       end as Gender,
        ci.cst_create_date as Create_date,
        ca.bdate as Birthdate
      from silver.crm_cust_info ci
      left join silver.erp_cust_az12 ca
      on ci.cst_key = ca.cid
      left join silver.erp_loc_a101 la
      on ci.cst_key = la.cid

---------------------------------
select distinct
       ci.cst_gndr,
       ca.gen,
       case when ci.cst_gndr != 'n/a' then ci.cst_gndr -- crm is master 
             else coalesce (ca.gen, 'n/a')
       end as new_gen
from silver.crm_cust_info ci
left join silver.erp_cust_az12 ca
    on ci.cst_key = ca.cid
    left join silver.erp_loc_a101 la
    on ci.cst_key = la.cid
order by 1,2
--------------------------------------------------------
select * from gold.dim_customers
--------------------------------------------------------
create view gold.dim_products as 
select 
row_number() over(order by pn.prd_start_dt,pn.prd_key) as product_key,
pn.prd_id as Product_ID,
pn.prd_key as Product_number,
pn.prd_nm as product_name,
pn.cat_id as category_id,
pc.cat as category,
pc.subcat as Subcategory,
pc.maintenance ,
pn.prd_cost as cost,
pn.prd_line as Product_line,
pn.prd_start_dt as start_date
from silver.crm_prd_info pn
left join silver.erp_px_cat_g1v2 pc
on pn.cat_id = pc.id 
where prd_end_dt is null -- filter out all hsitorical data 
---------------------------------------
select * from gold.dim_products
---------------------------------------------------
create view gold.fact_sales as
select
sd.sls_ord_num as order_number,
pr.product_key,
cu.customer_key,
sd.sls_order_dt as order_date,
sd.sls_ship_dt as shipping_date,
sd.sls_due_dt as Due_date,
sd.sls_sales as sales_amount,
sd.sls_quantity as quantity,
sd.sls_price as Price 
from silver.crm_sales_details sd
left join gold.dim_products pr
on sd.sls_prd_key = pr.Product_number
left join gold.dim_customers cu
on sd.sls_cust_id = cu.customer_id
-----------------------------------------
-- foreign key  integrity (Dimensions)
select * from gold.fact_sales f
left join gold.dim_customers c
on c.customer_key = f.customer_key
left join gold.dim_products p 
on p.product_key = f.product_key
where p.product_key is null
