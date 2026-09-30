# 🚗 Automotive Service & Warranty Analytics — SQL

## Why I built this project

I wanted a SQL project that felt closer to the kind of work a Data Analyst would actually do inside an operations or automotive company. Instead of a small employee/salary dataset, I designed a service-operations database around **customers, vehicles, service centers, technicians, work orders, parts, invoices and warranty claims**.

The data is synthetic, but the workflow and questions are intentionally realistic.

## Business scenario

Imagine an automotive company with service centers across India. Vehicles come in for periodic maintenance, repairs, electrical issues, brakes, AC and other services. The operations team wants to understand service demand, revenue, repair time, parts usage, warranty cost and repeat customers.

## Database

```text
customers -> vehicles -> work_orders -> invoices
                              |
                              +-> warranty_claims
                              |
                              +-> work_order_parts -> parts

service_centers -> work_orders
service_centers -> technicians
```

## Scale

- 1,800 customers
- 2,600 vehicles
- 15 service centers
- 180 technicians
- 25 parts
- 5,200 work orders
- Thousands of work-order/part records
- 5,000+ invoices
- Warranty claim history

## SQL skills covered

**Core:** SELECT, WHERE, GROUP BY, HAVING, CASE, aggregates, dates

**Analysis:** multi-table JOINs, LEFT JOIN, conditional aggregation, NULL handling, KPI calculations

**Advanced:** CTEs, subqueries, RANK, DENSE_RANK, LAG, NTILE, running totals, MoM growth

## Business questions

- Which service centers handle the most work and generate the most revenue?
- Which vehicle models have the highest service frequency?
- What is the average repair time and invoice value?
- Which parts are replaced most often?
- Which failure categories create the highest warranty cost?
- Which customers are repeat visitors?
- How does monthly service revenue change?
- Which vehicle models are top performers within each region?

## Data quality first

Before business analysis, I included checks for invalid date sequences, completed work without invoices, row counts and relationship integrity. In a real analytics environment, I would also reconcile invoice totals with the finance system before publishing KPIs.

## Example: MoM revenue

```sql
WITH monthly AS (
    SELECT DATE_FORMAT(invoice_date, '%Y-%m') AS month,
           SUM(total_amount) AS revenue
    FROM invoices
    GROUP BY DATE_FORMAT(invoice_date, '%Y-%m')
)
SELECT month,
       revenue,
       LAG(revenue) OVER (ORDER BY month) AS previous_revenue,
       100 * (revenue - LAG(revenue) OVER (ORDER BY month))
           / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) AS mom_growth_pct
FROM monthly;
```

## What I would investigate next

If this were a real company project, I would go beyond the first query result and investigate why some models have repeat visits, whether warranty cost is concentrated in particular centers, whether long repair times are related to parts availability or service type, and whether fleet customers behave differently from individual customers.

## How to run

1. Install **MySQL 8+**.
2. Run `database/01_create_schema.sql`.
3. Update the CSV paths in `database/02_load_data.sql` if required and enable `LOCAL INFILE`.
4. Run `database/02_load_data.sql`.
5. Open `analysis/01_business_analysis.sql` and run the sections one at a time.

## Repository structure

```text
Automotive-Service-SQL-Analytics/
├── database/
│   ├── 01_create_schema.sql
│   ├── 02_load_data.sql
│   └── 03_data_dictionary.md
├── analysis/
│   ├── 01_business_analysis.sql
│   └── 02_interview_questions.md
├── data/
│   ├── customers.csv
│   ├── vehicles.csv
│   ├── service_centers.csv
│   ├── technicians.csv
│   ├── parts.csv
│   ├── work_orders.csv
│   ├── work_order_parts.csv
│   ├── invoices.csv
│   ├── warranty_claims.csv
│   └── DATA_QUALITY_NOTES.md
└── README.md
```

## Dataset note

This is a **synthetic portfolio dataset**, not confidential company data. The scenario is designed to resemble automotive service operations while remaining safe to publish publicly.

**Author:** Swatantra Pratap Singh  
**Focus:** Data Analysis | SQL | Python | Power BI
