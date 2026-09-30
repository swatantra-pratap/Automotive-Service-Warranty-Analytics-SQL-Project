USE automotive_service_analytics;

-- 01 DATA QUALITY
SELECT 'customers' table_name,COUNT(*) row_count FROM customers UNION ALL SELECT 'vehicles',COUNT(*) FROM vehicles UNION ALL SELECT 'work_orders',COUNT(*) FROM work_orders UNION ALL SELECT 'invoices',COUNT(*) FROM invoices UNION ALL SELECT 'warranty_claims',COUNT(*) FROM warranty_claims;
SELECT COUNT(*) invalid_dates FROM work_orders WHERE close_date IS NOT NULL AND close_date < open_date;
SELECT COUNT(*) completed_without_invoice FROM work_orders wo LEFT JOIN invoices i ON wo.work_order_id=i.work_order_id WHERE wo.status='Completed' AND i.invoice_id IS NULL;

-- 02 OPERATIONS KPIs
SELECT COUNT(*) total_work_orders,SUM(status='Completed') completed,SUM(status='Cancelled') cancelled,SUM(status='In Progress') in_progress,ROUND(AVG(CASE WHEN close_date IS NOT NULL THEN DATEDIFF(close_date,open_date) END),2) avg_resolution_days FROM work_orders;
SELECT COUNT(*) invoices,ROUND(SUM(total_amount),2) revenue,ROUND(AVG(total_amount),2) avg_invoice,ROUND(SUM(labor_cost),2) labor_revenue,ROUND(SUM(parts_cost),2) parts_revenue FROM invoices;

-- 03 SERVICE CENTERS
SELECT sc.service_center_name,sc.region,COUNT(wo.work_order_id) work_orders,SUM(wo.status='Completed') completed,ROUND(AVG(CASE WHEN wo.close_date IS NOT NULL THEN DATEDIFF(wo.close_date,wo.open_date) END),2) avg_days FROM service_centers sc LEFT JOIN work_orders wo ON sc.service_center_id=wo.service_center_id GROUP BY sc.service_center_id,sc.service_center_name,sc.region ORDER BY work_orders DESC;
SELECT sc.service_center_name,ROUND(SUM(i.total_amount),2) revenue,ROUND(AVG(i.total_amount),2) avg_invoice FROM service_centers sc JOIN work_orders wo ON sc.service_center_id=wo.service_center_id JOIN invoices i ON wo.work_order_id=i.work_order_id GROUP BY sc.service_center_id,sc.service_center_name ORDER BY revenue DESC;

-- 04 VEHICLE RELIABILITY
SELECT v.vehicle_model,COUNT(wo.work_order_id) visits,COUNT(DISTINCT v.vehicle_id) vehicles_serviced,ROUND(COUNT(wo.work_order_id)/NULLIF(COUNT(DISTINCT v.vehicle_id),0),2) visits_per_vehicle FROM vehicles v JOIN work_orders wo ON v.vehicle_id=wo.vehicle_id GROUP BY v.vehicle_model ORDER BY visits_per_vehicle DESC;
SELECT v.vehicle_model,ROUND(SUM(i.total_amount),2) service_revenue,ROUND(AVG(i.total_amount),2) avg_repair_cost FROM vehicles v JOIN work_orders wo ON v.vehicle_id=wo.vehicle_id JOIN invoices i ON wo.work_order_id=i.work_order_id GROUP BY v.vehicle_model ORDER BY service_revenue DESC;

-- 05 WARRANTY
SELECT CASE WHEN wo.warranty_flag=1 THEN 'Warranty' ELSE 'Customer Paid' END repair_type,COUNT(*) work_orders,ROUND(SUM(i.total_amount),2) billed_amount FROM work_orders wo LEFT JOIN invoices i ON wo.work_order_id=i.work_order_id WHERE wo.status<>'Cancelled' GROUP BY repair_type;
SELECT failure_category,COUNT(*) claims,ROUND(SUM(claim_amount),2) claim_cost,ROUND(AVG(claim_amount),2) avg_claim FROM warranty_claims GROUP BY failure_category ORDER BY claim_cost DESC;
SELECT v.vehicle_model,COUNT(wc.claim_id) claims,ROUND(SUM(wc.claim_amount),2) warranty_cost FROM warranty_claims wc JOIN work_orders wo ON wc.work_order_id=wo.work_order_id JOIN vehicles v ON wo.vehicle_id=v.vehicle_id GROUP BY v.vehicle_model ORDER BY warranty_cost DESC;

-- 06 PARTS
SELECT p.part_name,p.part_category,SUM(wop.quantity) units_used,COUNT(DISTINCT wop.work_order_id) work_orders FROM parts p JOIN work_order_parts wop ON p.part_id=wop.part_id GROUP BY p.part_id,p.part_name,p.part_category ORDER BY units_used DESC;
SELECT p.part_name,p.unit_cost,ROUND(AVG(wop.unit_price),2) avg_selling_price,ROUND(100*(AVG(wop.unit_price)-p.unit_cost)/NULLIF(p.unit_cost,0),2) markup_pct FROM parts p JOIN work_order_parts wop ON p.part_id=wop.part_id GROUP BY p.part_id,p.part_name,p.unit_cost ORDER BY markup_pct DESC;

-- 07 TECHNICIANS
SELECT t.technician_name,t.specialization,t.experience_years,COUNT(wo.work_order_id) assigned_orders,SUM(wo.status='Completed') completed,ROUND(AVG(CASE WHEN wo.close_date IS NOT NULL THEN DATEDIFF(wo.close_date,wo.open_date) END),2) avg_days FROM technicians t LEFT JOIN work_orders wo ON t.technician_id=wo.technician_id GROUP BY t.technician_id,t.technician_name,t.specialization,t.experience_years ORDER BY completed DESC;

-- 08 CUSTOMERS
SELECT c.customer_id,c.customer_name,c.customer_type,COUNT(wo.work_order_id) visits,ROUND(SUM(i.total_amount),2) spend FROM customers c JOIN vehicles v ON c.customer_id=v.customer_id JOIN work_orders wo ON v.vehicle_id=wo.vehicle_id JOIN invoices i ON wo.work_order_id=i.work_order_id GROUP BY c.customer_id,c.customer_name,c.customer_type HAVING visits>=3 ORDER BY visits DESC;
SELECT c.customer_type,COUNT(DISTINCT c.customer_id) customers,COUNT(DISTINCT v.vehicle_id) vehicles,COUNT(DISTINCT wo.work_order_id) work_orders,ROUND(SUM(i.total_amount),2) revenue FROM customers c LEFT JOIN vehicles v ON c.customer_id=v.customer_id LEFT JOIN work_orders wo ON v.vehicle_id=wo.vehicle_id LEFT JOIN invoices i ON wo.work_order_id=i.work_order_id GROUP BY c.customer_type;

-- 09 ADVANCED SQL
WITH monthly AS (SELECT DATE_FORMAT(invoice_date,'%Y-%m') month,SUM(total_amount) revenue FROM invoices GROUP BY DATE_FORMAT(invoice_date,'%Y-%m')) SELECT month,ROUND(revenue,2) revenue,ROUND(LAG(revenue) OVER(ORDER BY month),2) previous_revenue,ROUND(100*(revenue-LAG(revenue) OVER(ORDER BY month))/NULLIF(LAG(revenue) OVER(ORDER BY month),0),2) mom_growth_pct FROM monthly ORDER BY month;
WITH monthly AS (SELECT DATE_FORMAT(invoice_date,'%Y-%m') month,SUM(total_amount) revenue FROM invoices GROUP BY DATE_FORMAT(invoice_date,'%Y-%m')) SELECT month,ROUND(revenue,2) revenue,ROUND(SUM(revenue) OVER(ORDER BY month),2) cumulative_revenue FROM monthly ORDER BY month;
WITH mr AS (SELECT sc.region,v.vehicle_model,SUM(i.total_amount) revenue FROM service_centers sc JOIN work_orders wo ON sc.service_center_id=wo.service_center_id JOIN vehicles v ON wo.vehicle_id=v.vehicle_id JOIN invoices i ON wo.work_order_id=i.work_order_id GROUP BY sc.region,v.vehicle_model), ranked AS (SELECT region,vehicle_model,revenue,DENSE_RANK() OVER(PARTITION BY region ORDER BY revenue DESC) rnk FROM mr) SELECT region,vehicle_model,ROUND(revenue,2) revenue,rnk FROM ranked WHERE rnk<=3 ORDER BY region,rnk;
WITH cv AS (SELECT c.customer_id,c.customer_name,COUNT(DISTINCT wo.work_order_id) visits,SUM(i.total_amount) spend FROM customers c JOIN vehicles v ON c.customer_id=v.customer_id JOIN work_orders wo ON v.vehicle_id=wo.vehicle_id JOIN invoices i ON wo.work_order_id=i.work_order_id GROUP BY c.customer_id,c.customer_name) SELECT customer_id,customer_name,visits,ROUND(spend,2) spend,NTILE(4) OVER(ORDER BY spend DESC) value_quartile FROM cv ORDER BY spend DESC;
