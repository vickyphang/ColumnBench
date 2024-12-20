-- Create table:
CREATE TABLE uk_price_paid(
  transaction uuid,
  price numeric,
  transfer_date date,
  postcode text NULL,
  property_type char(1),
  newly_built boolean,
  duration char(1),
  paon text NULL,
  saon text NULL,
  street text NULL,
  locality text NULL,
  city text NULL,
  district text NULL,
  county text,
  ppd_category_type char(1),
  record_status char(1)
) USING columnar;

-- Copy CSV data, with appropriate munging:
\copy uk_price_paid FROM 'pp-complete.csv' with (format csv, encoding 'win1252', header false, null '', quote '"', force_null (postcode, saon, paon, street, locality, city, district));