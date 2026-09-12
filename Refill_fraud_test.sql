
CREATE TABLE customers (
    customer_id INT,
    email VARCHAR (100) NOT NULL,
    phone VARCHAR (30),
    country VARCHAR (2),
    created_at TIMESTAMP NOT NULL,
PRIMARY KEY (customer_id)
);

CREATE TABLE payment_cards (
    card_id INT PRIMARY KEY,
    card_fingerprint VARCHAR (100) NOT NULL,
    card_country VARCHAR (2),
    card_type VARCHAR (20),
    created_at TIMESTAMP NOT NULL
);

CREATE TABLE products(
    product_id INT PRIMARY KEY,
    product_name VARCHAR (100) NOT NULL,
    category VARCHAR (50),
    price DECIMAL (10,2)
);

CREATE TABLE transactions (
    transaction_id INT,
    customer_id INT,
    card_id INT,
    product_id INT,
    amount DECIMAL (10,2),
    transaction_status VARCHAR (20),
    three_ds_used BOOLEAN,
    ip_address VARCHAR (45),
    device_id VARCHAR (100),
    created_at TIMESTAMP NOT NULL,
PRIMARY KEY (transaction_id),
FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE SET NULL,
FOREIGN KEY (card_id) REFERENCES payment_cards(card_id) ON DELETE SET NULL,
FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE SET NULL
);

CREATE TABLE fraud_confirmations (
    fraud_id INT,
    transaction_id INT NOT NULL UNIQUE,
    fraud_type VARCHAR (50),
    confirmed_at TIMESTAMP NOT NULL,
PRIMARY KEY (fraud_id),
FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE CASCADE
);


SELECT customer_id, COUNT (DISTINCT card_id) AS distinct_cards
FROM transactions
GROUP BY customer_id
ORDER BY distinct_cards DESC;


SELECT COUNT (transaction_id)
FROM transactions;

SELECT *
FROM fraud_confirmations;

SELECT *
FROM transactions
WHERE customer_id = 495;

SELECT *
FROM transactions
WHERE device_id = 'device_0742';

SELECT *
FROM transactions
WHERE ip_address = '172.16.24.18';

SELECT transactions.customer_id, fraud_confirmations.fraud_type 
FROM transactions
JOIN fraud_confirmations
ON transactions.transaction_id = fraud_confirmations.transaction_id
WHERE transactions.customer_id = 495; 



-- DROP TABLE fraud_confirmations;

SELECT *
FROM fraud_confirmations
LIMIT 10;

ALTER TABLE products DROP COLUMN gpa;

DELETE FROM products;









-- Inserting value

INSERT INTO products VALUES 
(1, 'Steam Gift Card 20', 'gaming', 20.00),
(2, 'Steam Gift Card 50', 'gaming', 50.00),
(3, 'PlayStation Gift Card 25', 'gaming', 25.00),
(4, 'Xbox Gift Card 50', 'gaming', 50.00),
(5, 'Nintendo eShop 25', 'gaming', 25.00),
(6, 'Mobile Top Up 10', 'mobile', 10.00),
(7, 'Mobile Top Up 25', 'mobile', 25.00),
(8, 'Mobile Top Up 50', 'mobile', 50.00),
(9, 'Shopping Gift Card 25', 'shopping', 25.00),
(10, 'Shopping Gift Card 100', 'shopping', 100.00),
(11, 'Prepaid Voucher 50', 'prepaid', 50.00),
(12, 'Prepaid Voucher 100', 'prepaid', 100.00);


INSERT INTO customers (customer_id, email, phone, country, created_at)
SELECT
    i,
    'customer' || i || '@example.com',
    '+40' || (700000000 + i)::TEXT,
    (ARRAY['RO', 'DE', 'LT', 'GB', 'NL', 'PL'])[1 + FLOOR(RANDOM() * 6)::INT],
    CURRENT_TIMESTAMP - (RANDOM() * INTERVAL '60 days')
FROM generate_series(1, 500) AS g(i);


INSERT INTO payment_cards (
    card_id,
    card_fingerprint,
    card_country,
    card_type,
    created_at
)
SELECT
    i,
    'card_fp_' || LPAD(i::TEXT, 6, '0'),
    (ARRAY['RO', 'DE', 'LT', 'GB', 'NL', 'PL'])[1 + FLOOR(RANDOM() * 6)::INT],
    (ARRAY['Visa', 'Mastercard'])[1 + FLOOR(RANDOM() * 2)::INT],
    CURRENT_TIMESTAMP - (RANDOM() * INTERVAL '90 days')
FROM generate_series(1, 700) AS g(i);


INSERT INTO transactions (
    transaction_id,
    customer_id,
    card_id,
    product_id,
    amount,
    transaction_status,
    three_ds_used,
    ip_address,
    device_id,
    created_at
)
SELECT
    i,
    1 + FLOOR(RANDOM() * 500)::INT,
    1 + FLOOR(RANDOM() * 700)::INT,
    1 + FLOOR(RANDOM() * 12)::INT,
    (ARRAY[10.00, 20.00, 25.00, 50.00, 100.00])[
        1 + FLOOR(RANDOM() * 5)::INT
    ],
    (ARRAY['approved', 'approved', 'approved', 'approved', 'declined'])[
        1 + FLOOR(RANDOM() * 5)::INT
    ],
    RANDOM() < 0.45,
    '192.168.' ||
        FLOOR(RANDOM() * 255)::INT || '.' ||
        FLOOR(RANDOM() * 255)::INT,
    'device_' || LPAD((1 + FLOOR(RANDOM() * 900)::INT)::TEXT, 4, '0'),
    CURRENT_TIMESTAMP - (RANDOM() * INTERVAL '60 days')
FROM generate_series(1, 5000) AS g(i);


WITH base AS (
    SELECT
        i AS transaction_id,
        1 + FLOOR(RANDOM() * 500)::INT AS customer_id
    FROM generate_series(1, 5000) AS g(i)
)
INSERT INTO transactions (
    transaction_id,
    customer_id,
    card_id,
    product_id,
    amount,
    transaction_status,
    three_ds_used,
    ip_address,
    device_id,
    created_at
)
SELECT
    transaction_id,
    customer_id,

    CASE
        WHEN customer_id <= 200 AND RANDOM() < 0.30
            THEN 500 + customer_id
        ELSE customer_id
    END AS card_id,

    1 + FLOOR(RANDOM() * 12)::INT,

    (ARRAY[10.00, 20.00, 25.00, 50.00, 100.00])[
        1 + FLOOR(RANDOM() * 5)::INT
    ],

    (ARRAY['approved', 'approved', 'approved', 'approved', 'declined'])[
        1 + FLOOR(RANDOM() * 5)::INT
    ],

    RANDOM() < 0.45,

    '192.168.' ||
        FLOOR(RANDOM() * 255)::INT || '.' ||
        FLOOR(RANDOM() * 255)::INT,

    'device_' || LPAD(customer_id::TEXT, 4, '0'),

    CURRENT_TIMESTAMP - (RANDOM() * INTERVAL '60 days')

FROM base;










-- Fraudulent Patterns
WITH chosen_customer AS MATERIALIZED (
    SELECT customer_id
    FROM customers
    ORDER BY RANDOM()
    LIMIT 1
),
chosen_cards AS MATERIALIZED (
    SELECT card_id
    FROM payment_cards
    ORDER BY RANDOM()
    LIMIT 8
)
INSERT INTO transactions (
    transaction_id,
    customer_id,
    card_id,
    product_id,
    amount,
    transaction_status,
    three_ds_used,
    ip_address,
    device_id,
    created_at
)
SELECT
    5000 + ROW_NUMBER() OVER (),
    c.customer_id,
    pc.card_id,
    1 + FLOOR(RANDOM() * 12)::INT,
    (ARRAY[25.00, 50.00, 100.00])[1 + FLOOR(RANDOM() * 3)::INT],
    'approved',
    FALSE,
    '172.16.24.18',
    'device_0742',
    CURRENT_TIMESTAMP - INTERVAL '3 days'
        + (ROW_NUMBER() OVER () * INTERVAL '2 minutes')
FROM chosen_customer c
CROSS JOIN chosen_cards pc;


WITH chosen_card AS MATERIALIZED (
    SELECT card_id
    FROM payment_cards
    ORDER BY RANDOM()
    LIMIT 1
),
chosen_customers AS MATERIALIZED (
    SELECT customer_id
    FROM customers
    ORDER BY RANDOM()
    LIMIT 8
)
INSERT INTO transactions (
    transaction_id,
    customer_id,
    card_id,
    product_id,
    amount,
    transaction_status,
    three_ds_used,
    ip_address,
    device_id,
    created_at
)
SELECT
    5008 + ROW_NUMBER() OVER (),
    c.customer_id,
    pc.card_id,
    1 + FLOOR(RANDOM() * 12)::INT,
    50.00,
    'approved',
    FALSE,
    '172.16.52.31',
    'device_' || LPAD((300 + c.customer_id)::TEXT, 4, '0'),
    CURRENT_TIMESTAMP - INTERVAL '2 days'
        + (ROW_NUMBER() OVER () * INTERVAL '3 minutes')
FROM chosen_card pc
CROSS JOIN chosen_customers c;


WITH chosen_customers AS MATERIALIZED (
    SELECT customer_id
    FROM customers
    ORDER BY RANDOM()
    LIMIT 10
)
INSERT INTO transactions (
    transaction_id,
    customer_id,
    card_id,
    product_id,
    amount,
    transaction_status,
    three_ds_used,
    ip_address,
    device_id,
    created_at
)
SELECT
    5016 + ROW_NUMBER() OVER (),
    c.customer_id,
    c.customer_id,
    1 + FLOOR(RANDOM() * 12)::INT,
    25.00,
    'approved',
    FALSE,
    '172.16.77.44',
    'device_0881',
    CURRENT_TIMESTAMP - INTERVAL '1 day'
        + (ROW_NUMBER() OVER () * INTERVAL '4 minutes')
FROM chosen_customers c;


WITH chosen AS MATERIALIZED (
    SELECT customer_id
    FROM customers
    ORDER BY RANDOM()
    LIMIT 1
)
INSERT INTO transactions (
    transaction_id,
    customer_id,
    card_id,
    product_id,
    amount,
    transaction_status,
    three_ds_used,
    ip_address,
    device_id,
    created_at
)
SELECT
    5026 + i,
    c.customer_id,
    c.customer_id,
    1 + FLOOR(RANDOM() * 12)::INT,
    (ARRAY[10.00, 20.00, 25.00, 50.00])[1 + FLOOR(RANDOM() * 4)::INT],
    CASE
        WHEN i <= 12 THEN 'approved'
        ELSE 'declined'
    END,
    FALSE,
    '172.16.91.12',
    'device_0917',
    CURRENT_TIMESTAMP - INTERVAL '12 hours'
        + (i * INTERVAL '1 minute')
FROM chosen c
CROSS JOIN generate_series(1, 15) AS g(i);


INSERT INTO fraud_confirmations (
    fraud_id,
    transaction_id,
    fraud_type,
    confirmed_at
)
SELECT
    ROW_NUMBER() OVER (),
    transaction_id,
    CASE
        WHEN transaction_id BETWEEN 5001 AND 5008 THEN 'payment_instrument_abuse'
        WHEN transaction_id BETWEEN 5009 AND 5016 THEN 'shared_card_abuse'
        WHEN transaction_id BETWEEN 5017 AND 5026 THEN 'multi_account_abuse'
        WHEN transaction_id BETWEEN 5027 AND 5041 THEN 'velocity_abuse'
    END,
    created_at
        + INTERVAL '1 day'
        + RANDOM() * INTERVAL '2 days'
FROM transactions
WHERE transaction_id BETWEEN 5001 AND 5041
AND RANDOM() < 0.70;






