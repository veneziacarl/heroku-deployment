DROP TABLE restaurants CASCADE;

CREATE TABLE restaurants(
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  address VARCHAR(255),
  city VARCHAR(255) NOT NULL,
  state VARCHAR(2) NOT NULL,
  zip VARCHAR(5) NOT NULL,
  description VARCHAR(1023) NOT NULL
);

CREATE UNIQUE INDEX restaurant_name_and_city ON restaurants(name, city);
