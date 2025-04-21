# FMCG Sales Analytics Data Mart with Hydra

This project demonstrates a star schema implementation for FMCG (Fast-Moving Consumer Goods) sales analytics using Hydra's PostgreSQL-compatible data warehouse. The solution includes synthetic data generation, table creation with optimized columnar storage, and analytical queries designed for Metabase visualization.

## Table of Contents

1. [Database Schema](#database-schema)
2. [Data Generation](#data-generation)
3. [Materialized Views](#materialized-views)
4. [Analytical Queries](#analytical-queries)
5. [Metabase Integration](#metabase-integration)
6. [Maintenance](#maintenance)

## Database Schema

### Dimension Tables

```sql
-- Date Dimension
CREATE TABLE dim_date (
    date_id DATE PRIMARY KEY,
    day INT,
    month INT,
    year INT,
    quarter INT,
    day_of_week INT,
    day_name VARCHAR(10),
    month_name VARCHAR(10),
    is_weekend BOOLEAN
);

-- Product Dimension
CREATE TABLE dim_product (
    product_id VARCHAR(20) PRIMARY KEY,
    product_name VARCHAR(200),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    brand VARCHAR(50),
    unit_cost DECIMAL(10,2)
);

-- Customer Dimension
CREATE TABLE dim_customer (
    customer_id VARCHAR(20) PRIMARY KEY,
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    loyalty_tier VARCHAR(20)
);

-- Geography Dimension
CREATE TABLE dim_geography (
    geography_id SERIAL PRIMARY KEY,
    country VARCHAR(50),
    region VARCHAR(50),
    state VARCHAR(50),
    city VARCHAR(50),
    postal_code VARCHAR(20)
);
```

### Fact Table (Columnar Storage)

```sql
CREATE TABLE fact_sales (
    sale_id VARCHAR(20),
    date_id DATE,
    customer_id VARCHAR(20),
    product_id VARCHAR(20),
    geography_id INT,
    order_id VARCHAR(20),
    sales DECIMAL(10,2),
    quantity INT,
    discount DECIMAL(5,2),
    profit DECIMAL(10,2),
    shipping_cost DECIMAL(10,2)
) USING columnar;

ALTER TABLE fact_sales ADD PRIMARY KEY (sale_id);
```

## Data Generation

### Generate Date Dimension

```sql
INSERT INTO dim_date (date_id, day, month, year, quarter, day_of_week, day_name, month_name, is_weekend)
SELECT 
    date_id,
    EXTRACT(DAY FROM date_id) AS day,
    EXTRACT(MONTH FROM date_id) AS month,
    EXTRACT(YEAR FROM date_id) AS year,
    EXTRACT(QUARTER FROM date_id) AS quarter,
    EXTRACT(DOW FROM date_id) AS day_of_week,
    TO_CHAR(date_id, 'Day') AS day_name,
    TO_CHAR(date_id, 'Month') AS month_name,
    EXTRACT(DOW FROM date_id) IN (0,6) AS is_weekend
FROM generate_series('2010-01-01'::date, '2030-12-31'::date, '1 day'::interval) AS date_id;
```

### Generate Product Dimension (50,000 products)

```sql
INSERT INTO dim_product
SELECT 
    'PROD-' || LPAD(i::text, 6, '0') AS product_id,
    'Product ' || i AS product_name,
    CASE WHEN i % 5 = 0 THEN 'Beverages'
         WHEN i % 5 = 1 THEN 'Snacks'
         WHEN i % 5 = 2 THEN 'Dairy'
         WHEN i % 5 = 3 THEN 'Household'
         ELSE 'Personal Care' END AS category,
    CASE WHEN i % 10 = 0 THEN 'Carbonated Drinks'
         WHEN i % 10 = 1 THEN 'Chips'
         WHEN i % 10 = 2 THEN 'Cheese'
         WHEN i % 10 = 3 THEN 'Cleaning'
         WHEN i % 10 = 4 THEN 'Shampoo'
         WHEN i % 10 = 5 THEN 'Juices'
         WHEN i % 10 = 6 THEN 'Cookies'
         WHEN i % 10 = 7 THEN 'Yogurt'
         WHEN i % 10 = 8 THEN 'Paper Goods'
         ELSE 'Soap' END AS sub_category,
    CASE WHEN i % 7 = 0 THEN 'Premium'
         WHEN i % 7 = 1 THEN 'Value'
         WHEN i % 7 = 2 THEN 'Organic'
         WHEN i % 7 = 3 THEN 'International'
         WHEN i % 7 = 4 THEN 'Local'
         WHEN i % 7 = 5 THEN 'Budget'
         ELSE 'Standard' END AS brand,
    (RANDOM() * 50 + 1)::DECIMAL(10,2) AS unit_cost
FROM generate_series(1, 50000) AS i;
```

### Generate Customer Dimension (1 million customers)

```sql
INSERT INTO dim_customer
SELECT 
    'CUST-' || LPAD(i::text, 7, '0') AS customer_id,
    'Customer ' || i AS customer_name,
    CASE WHEN i % 3 = 0 THEN 'Retail'
         WHEN i % 3 = 1 THEN 'Wholesale'
         ELSE 'Online' END AS segment,
    CASE WHEN i % 5 = 0 THEN 'Gold'
         WHEN i % 5 = 1 THEN 'Silver'
         WHEN i % 5 = 2 THEN 'Bronze'
         ELSE 'Standard' END AS loyalty_tier
FROM generate_series(1, 1000000) AS i;
```

### Generate Geography Dimension (10,000 locations)

```sql
INSERT INTO dim_geography (country, region, state, city, postal_code)
SELECT 
    'United States' AS country,
    CASE WHEN i % 4 = 0 THEN 'Northeast'
         WHEN i % 4 = 1 THEN 'Midwest'
         WHEN i % 4 = 2 THEN 'South'
         ELSE 'West' END AS region,
    'State ' || (i % 50 + 1) AS state,
    'City ' || i AS city,
    LPAD((i % 89999 + 10001)::text, 5, '0') AS postal_code
FROM generate_series(1, 10000) AS i;
```

### Generate Fact Sales (100 million records in batches)

```sql
DO $$
BEGIN
    FOR i IN 1..100 LOOP
        INSERT INTO fact_sales
        SELECT 
            'SALE-' || LPAD((i*1000000 + j)::text, 10, '0') AS sale_id,
            (DATE '2010-01-01' + (RANDOM() * 7300)::INT) AS date_id,
            'CUST-' || LPAD((RANDOM() * 999999 + 1)::INT::text, 7, '0') AS customer_id,
            'PROD-' || LPAD((RANDOM() * 49999 + 1)::INT::text, 6, '0') AS product_id,
            (RANDOM() * 9999 + 1)::INT AS geography_id,
            'ORD-' || LPAD((i*1000000 + j)::text, 10, '0') AS order_id,
            (RANDOM() * 990 + 10)::DECIMAL(10,2) AS sales,
            (RANDOM() * 10 + 1)::INT AS quantity,
            CASE WHEN RANDOM() > 0.7 THEN (RANDOM() * 0.3)::DECIMAL(5,2) ELSE 0 END AS discount,
            (RANDOM() * 200)::DECIMAL(10,2) AS profit,
            (RANDOM() * 15)::DECIMAL(10,2) AS shipping_cost
        FROM generate_series(1, 1000000) AS j;
        
        RAISE NOTICE 'Inserted batch %, total rows: %', i, i*1000000;
    END LOOP;
END $$;
```

## Materialized Views

```sql
-- 1. Sales Trends (Daily refresh)
CREATE MATERIALIZED VIEW mv_sales_trends AS
SELECT 
    d.year,
    d.quarter,
    d.month,
    d.month_name,
    COUNT(DISTINCT f.order_id) AS order_count,
    SUM(f.quantity) AS total_units,
    SUM(f.sales) AS gross_sales,
    SUM(f.sales * f.discount) AS total_discounts,
    SUM(f.profit) AS net_profit,
    SUM(f.profit)/NULLIF(SUM(f.sales),0) AS profit_margin
FROM fact_sales f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.quarter, d.month, d.month_name;

-- 2. Product Performance (Weekly refresh)
CREATE MATERIALIZED VIEW mv_product_performance AS
SELECT 
    p.category,
    p.sub_category,
    p.brand,
    COUNT(DISTINCT f.order_id) AS order_count,
    SUM(f.quantity) AS total_units,
    SUM(f.sales) AS gross_sales,
    SUM(f.profit) AS net_profit,
    AVG(f.sales/f.quantity) AS avg_unit_price,
    SUM(f.quantity)/COUNT(DISTINCT f.date_id) AS daily_sales_velocity
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
GROUP BY p.category, p.sub_category, p.brand;

-- 3. Customer Analysis (Monthly refresh)
CREATE MATERIALIZED VIEW mv_customer_analysis AS
SELECT 
    c.segment,
    c.loyalty_tier,
    COUNT(DISTINCT f.customer_id) AS customer_count,
    COUNT(DISTINCT f.order_id) AS order_count,
    SUM(f.sales) AS total_spend,
    AVG(f.sales) AS avg_order_value,
    SUM(f.profit) AS total_profit
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.segment, c.loyalty_tier;

-- 4. Geographic Sales (Quarterly refresh)
CREATE MATERIALIZED VIEW mv_geographic_sales AS
SELECT 
    g.region,
    g.state,
    COUNT(DISTINCT f.customer_id) AS customer_count,
    SUM(f.sales) AS total_sales,
    SUM(f.profit) AS total_profit,
    SUM(f.profit)/NULLIF(SUM(f.sales),0) AS profit_margin
FROM fact_sales f
JOIN dim_geography g ON f.geography_id = g.geography_id
GROUP BY g.region, g.state;
```

## Analytical Queries for Metabase

### Time Series Dashboard

```sql
SELECT 
    year || '-' || LPAD(month::text, 2, '0') AS year_month,
    gross_sales,
    net_profit,
    profit_margin,
    total_units
FROM mv_sales_trends
WHERE year >= EXTRACT(YEAR FROM CURRENT_DATE) - 2
ORDER BY year, month;
```

**Recommended Visualizations:**
- Line chart: Sales and profit trends
- Bar chart: Monthly units sold
- Metric cards: Key performance indicators

### Product Performance Dashboard

```sql
SELECT 
    category,
    sub_category,
    brand,
    gross_sales,
    net_profit,
    profit_margin,
    daily_sales_velocity
FROM mv_product_performance
ORDER BY gross_sales DESC
LIMIT 50;
```

**Recommended Visualizations:**
- Treemap: Sales by category hierarchy
- Scatter plot: Profit margin vs. sales velocity
- Table: Detailed product metrics

### Customer Segmentation Dashboard

```sql
SELECT 
    segment,
    loyalty_tier,
    customer_count,
    total_spend,
    avg_order_value,
    total_profit,
    total_profit/NULLIF(customer_count,0) AS profit_per_customer
FROM mv_customer_analysis
ORDER BY total_spend DESC;
```

**Recommended Visualizations:**
- Pie chart: Spend by customer segment
- Bar chart: Profit per customer tier
- Funnel chart: Customer conversion metrics

## Maintenance

### Refresh Schedule

```sql
CREATE OR REPLACE PROCEDURE refresh_analytics_views()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Daily refreshes
    REFRESH MATERIALIZED VIEW mv_sales_trends;
    
    -- Weekly refreshes (on Mondays)
    IF EXTRACT(DOW FROM CURRENT_DATE) = 1 THEN
        REFRESH MATERIALIZED VIEW mv_product_performance;
    END IF;
    
    -- Monthly refreshes (on 1st of month)
    IF EXTRACT(DAY FROM CURRENT_DATE) = 1 THEN
        REFRESH MATERIALIZED VIEW mv_customer_analysis;
    END IF;
    
    -- Quarterly refreshes (first of quarter months)
    IF EXTRACT(MONTH FROM CURRENT_DATE) IN (1,4,7,10) AND EXTRACT(DAY FROM CURRENT_DATE) = 1 THEN
        REFRESH MATERIALIZED VIEW mv_geographic_sales;
    END IF;
END;
$$;
```

### Performance Optimization

```sql
-- Create indexes on fact table
CREATE INDEX idx_fact_sales_date ON fact_sales(date_id);
CREATE INDEX idx_fact_sales_product ON fact_sales(product_id);
CREATE INDEX idx_fact_sales_customer ON fact_sales(customer_id);
CREATE INDEX idx_fact_sales_geography ON fact_sales(geography_id);

-- Create indexes on materialized views
CREATE INDEX idx_mv_sales_trends_date ON mv_sales_trends(year, month);
CREATE INDEX idx_mv_product_performance_cat ON mv_product_performance(category, sub_category);
CREATE INDEX idx_mv_customer_analysis_segment ON mv_customer_analysis(segment, loyalty_tier);
```

This implementation provides a complete FMCG sales analytics solution with synthetic data at scale, optimized for Hydra's columnar storage and designed for effective visualization in Metabase.