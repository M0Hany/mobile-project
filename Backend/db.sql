DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS stores;
DROP TABLE IF EXISTS users;

-- Create users table
CREATE TABLE users (
    email VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    gender VARCHAR(10),
    level INT CHECK (level IN (1, 2, 3, 4)),
    password VARCHAR(255) NOT NULL,
    profile_picture VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    favorite_stores INTEGER[]
);

-- Create stores table
CREATE TABLE stores (
    id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    latitude NUMERIC(10,8) NOT NULL,
    longitude NUMERIC(11,8) NOT NULL,
    category VARCHAR(100),
    rating NUMERIC(3,1),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create products table
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    store_id INTEGER NOT NULL REFERENCES stores(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(100),
    image_url VARCHAR(255),
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert test user
INSERT INTO users (email, name, gender, level, password) VALUES
('test@test.com', 'Test User', 'Female', 3, 'password123');

-- Insert sample restaurants/cafes
INSERT INTO stores (id, name, latitude, longitude, category, rating) VALUES
(1, 'Campus Cafe', 30.04444000, 31.23570000, 'Restaurant', 4.5),
(2, 'Quick Bites', 30.04450000, 31.23580000, 'Restaurant', 4.0),
(3, 'Coffee Corner', 30.04460000, 31.23590000, 'Cafe', 4.8);

-- Insert products with some duplicates across stores
-- Campus Cafe products
INSERT INTO products (store_id, name, description, price, category, is_available) VALUES
(1, 'Chicken Sandwich', 'Grilled chicken with lettuce and mayo', 5.50, 'Sandwiches', true),
(1, 'Coffee', 'Freshly brewed coffee', 2.00, 'Beverages', true),
(1, 'Cola', 'Cold cola drink', 1.50, 'Beverages', true),
(1, 'Water Bottle', 'Pure mineral water', 1.00, 'Beverages', true);

-- Quick Bites products
INSERT INTO products (store_id, name, description, price, category, is_available) VALUES
(2, 'Chicken Sandwich', 'Crispy chicken with special sauce', 6.00, 'Sandwiches', true),
(2, 'Cola', 'Cold cola drink', 1.50, 'Beverages', true),
(2, 'Water Bottle', 'Pure mineral water', 1.00, 'Beverages', true);

-- Coffee Corner products
INSERT INTO products (store_id, name, description, price, category, is_available) VALUES
(3, 'Coffee', 'Premium coffee blend', 2.50, 'Beverages', true),
(3, 'Tea', 'Various tea flavors', 2.00, 'Beverages', true),
(3, 'Water Bottle', 'Pure mineral water', 1.00, 'Beverages', true); 