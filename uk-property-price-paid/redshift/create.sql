-- Create table:
CREATE TABLE uk_price_paid_col(
  transaction VARCHAR(40) primary key,
  price VARCHAR(255),
  transfer_date TIMESTAMP,
  postcode VARCHAR(255),
  property_type VARCHAR(255),
  newly_built VARCHAR(255),
  duration VARCHAR(255),
  paon VARCHAR(255),
  saon VARCHAR(255),
  street VARCHAR(255),
  locality VARCHAR(255),
  city VARCHAR(255),
  district VARCHAR(255),
  county VARCHAR(255),
  ppd_category_type VARCHAR(255),
  record_status VARCHAR(255));

-- Copy CSV data from S3
COPY uk_price_paid_col
FROM 's3://bucket_name/pp-complete.csv'
CREDENTIALS 'aws_access_key_id=...;aws_secret_access_key=...'
DELIMITER ','
removequotes
emptyasnull
blanksasnull
maxerror 1000;