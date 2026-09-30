# Data Dictionary

- `customers`: customer master
- `vehicles`: vehicles linked to customers
- `service_centers`: service locations
- `technicians`: technician profile
- `parts`: parts catalogue and supplier cost
- `work_orders`: core service events
- `work_order_parts`: parts used on each work order
- `invoices`: financial transactions
- `warranty_claims`: warranty reimbursement events

Key relationships: customer -> vehicles -> work_orders; service_center -> work_orders/technicians; work_order -> invoices/warranty_claims; work_order <-> parts through work_order_parts.
