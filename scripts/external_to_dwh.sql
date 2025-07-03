/* обновление сущствующих записей и добавление новых в dwh.d_craftsman */
merge into dwh.d_craftsman d
using (select distinct craftsman_id, craftsman_name, craftsman_address, craftsman_birthday, craftsman_email 
		from external_source.craft_products_orders) t
on d.craftsman_name = t.craftsman_name and d.craftsman_email = t.craftsman_email
when matched then 
	update set craftsman_address = t.craftsman_address, 
				craftsman_birthday = t.craftsman_birthday, 
				load_dttm = current_timestamp
when not matched then
	insert (craftsman_name, craftsman_address, craftsman_birthday, craftsman_email, load_dttm)
  	values (t.craftsman_name, t.craftsman_address, t.craftsman_birthday, t.craftsman_email, current_timestamp);


/* обновление существующих записей и добавление новых в dwh.d_products */
merge into dwh.d_product d
using (select distinct product_name, product_description, product_type, product_price 
	from external_source.craft_products_orders) t
on d.product_name = t.product_name and d.product_description = t.product_description and d.product_price = t.product_price
when matched then
	update set product_type= t.product_type, 
				load_dttm = current_timestamp
when not matched then
	insert (product_name, product_description, product_type, product_price, load_dttm)
  	values (t.product_name, t.product_description, t.product_type, t.product_price, current_timestamp);


/* обновление существующих записей и добавление новых в dwh.d_customer */
merge into dwh.d_customer d
using (select distinct customer_name, customer_address, customer_birthday, customer_email 
	from external_source.customers) t
on d.customer_name = t.customer_name and d.customer_email = t.customer_email
when matched then
	update set customer_address= t.customer_address, 
				customer_birthday= t.customer_birthday, 
				load_dttm = current_timestamp
when not matched then
	insert (customer_name, customer_address, customer_birthday, customer_email, load_dttm)
  	values (t.customer_name, t.customer_address, t.customer_birthday, t.customer_email, current_timestamp);


/* создание таблицы tmp_sources_fact */
drop table if exists tmp_sources_fact;
create temp table tmp_sources_fact as 
select  dp.product_id,
        dc.craftsman_id,
        dcust.customer_id,
        src.order_created_date,
        src.order_completion_date,
        src.order_status,
        current_timestamp 
from external_source.craft_products_orders src
join dwh.d_craftsman dc using(craftsman_id)
join dwh.d_customer dcust using(customer_id)
join dwh.d_product dp using(product_id);

/* обновление существующих записей и добавление новых в dwh.f_order */
merge into dwh.f_order f
using tmp_sources_fact t
	on f.product_id = t.product_id and f.craftsman_id = t.craftsman_id and f.customer_id = t.customer_id and f.order_created_date = t.order_created_date 
when matched then
	update set order_completion_date = t.order_completion_date, 
				order_status = t.order_status, 
				load_dttm = current_timestamp
when not matched then
	insert (product_id, craftsman_id, customer_id, order_created_date, order_completion_date, order_status, load_dttm)
  	values (t.product_id, t.craftsman_id, t.customer_id, t.order_created_date, t.order_completion_date, t.order_status, current_timestamp); 

