
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





SELECT customer_id, COUNT (DISTINCT card_id) AS distinct_cards, COUNT (fraud_confirmations.confirmed_at) AS confirmed
FROM transactions
LEFT JOIN fraud_confirmations
ON transactions.transaction_id = fraud_confirmations.transaction_id
GROUP BY customer_id
ORDER BY distinct_cards DESC ;

SELECT *
FROM transactions
LEFT JOIN fraud_confirmations
ON transactions.transaction_id = fraud_confirmations.transaction_id
WHERE customer_id = 183
ORDER BY transactions.customer_id;


SELECT customer_id, card_id
FROM transactions
WHERE card_id IN (
    SELECT card_id 
    FROM transactions
    WHERE customer_id = 183
)
ORDER BY card_id, customer_id;


SELECT card_id, customer_id
FROM transactions
WHERE card_id = 568
GROUP BY card_id, customer_id;


SELECT card_id, customer_id, fraud_confirmations.fraud_type 
FROM transactions
LEFT JOIN fraud_confirmations
ON transactions.transaction_id = fraud_confirmations.transaction_id
WHERE card_id = 568

SELECT card_id, COUNT(DISTINCT customer_id) AS cust, COUNT (fraud_confirmations.fraud_type) AS confirmedfrd
FROM transactions
LEFT JOIN fraud_confirmations
ON transactions.transaction_id = fraud_confirmations.transaction_id
WHERE card_id = 568
GROUP BY card_id;

SELECT customer_id, device_id, ip_address
FROM transactions
WHERE card_id = 568;

SELECT customer_id, card_id
FROM transactions
WHERE ip_address = '172.16.52.31';

SELECT ip_address, COUNT(DISTINCT customer_id), COUNT(DISTINCT card_id)
FROM transactions
WHERE ip_address = '172.16.52.31'
GROUP BY ip_address;

SELECT ip_address, COUNT(DISTINCT customer_id) AS distinct_cust
FROM transactions
GROUP BY ip_address 
HAVING COUNT(DISTINCT customer_id) > 1
ORDER BY distinct_cust DESC;


SELECT transaction_id, customer_id, amount, COUNT (*) OVER (PARTITION BY customer_id ) AS transnr
FROM transactions
ORDER BY transnr DESC;

SELECT customer_id, transaction_id, created_at, ROW_NUMBER() OVER (PARTITION BY  customer_id  ORDER BY  created_at  )  AS transnr
FROM transactions
ORDER BY customer_id, created_at ASC;

SELECT customer_id, transaction_id, created_at, LAG(created_at) OVER (PARTITION BY  customer_id  ORDER BY  created_at  )  AS previous_created_at
FROM transactions
ORDER BY customer_id, created_at ASC;



SELECT customer_id, transaction_id, created_at, LAG(created_at) OVER (PARTITION BY  customer_id  ORDER BY  created_at  )  AS previous_created_at, created_at - LAG(created_at) OVER (PARTITION BY  customer_id  ORDER BY  created_at  )  AS time_dif
FROM transactions
ORDER BY customer_id, created_at ASC;

SELECT customer_id, transaction_id, created_at, previous_created_at, created_at - previous_created_at AS time_diff
FROM (
    SELECT customer_id, transaction_id, created_at, LAG(created_at) OVER (PARTITION BY customer_id ORDER BY created_at ) AS previous_created_at
    FROM transactions
) AS x
ORDER BY customer_id, created_at;


SELECT customer_id, transaction_id, created_at, previous_created_at, time_dif
FROM (
SELECT customer_id, transaction_id, created_at, LAG(created_at) OVER (PARTITION BY  customer_id  ORDER BY  created_at  )  AS previous_created_at, created_at - LAG(created_at) OVER (PARTITION BY  customer_id  ORDER BY  created_at  )  AS time_dif
FROM transactions
ORDER BY customer_id, created_at ASC
) AS x
WHERE x.time_dif < INTERVAL '5 minutes';


SELECT 
    customer_id, 
    COUNT (*) AS total_tx, 
    SUM (CASE WHEN transaction_status = 'approved' THEN 1 ELSE 0 END) AS approved_tx,
    SUM (CASE WHEN transaction_status = 'declined' THEN 1 ELSE 0 END) AS declined_tx,
    SUM (CASE WHEN three_ds_used = FALSE THEN 1 ELSE 0 END) AS no_3ds_tx
FROM transactions
GROUP BY customer_id
ORDER BY total_tx DESC;



WITH customer_summary AS (
    SELECT 
        customer_id, 
        COUNT (*) AS total_tx, 
        SUM (CASE WHEN transaction_status = 'approved' THEN 1 ELSE 0 END) AS approved_tx,
        SUM (CASE WHEN transaction_status = 'declined' THEN 1 ELSE 0 END) AS declined_tx,
        SUM (CASE WHEN three_ds_used = FALSE THEN 1 ELSE 0 END) AS no_3ds_tx
    FROM transactions
    GROUP BY customer_id
)

SELECT *
FROM customer_summary
WHERE total_tx > 15
ORDER BY total_tx DESC;










WITH customer_summary AS (
    SELECT 
        customer_id, 
        COUNT (*) AS total_tx, 
        SUM (CASE WHEN transaction_status = 'approved' THEN 1 ELSE 0 END) AS approved_tx,
        SUM (CASE WHEN transaction_status = 'declined' THEN 1 ELSE 0 END) AS declined_tx,
        SUM (CASE WHEN three_ds_used = FALSE THEN 1 ELSE 0 END) AS no_3ds_tx,
        COUNT(DISTINCT card_id) AS distinct_cards, 
        COUNT(DISTINCT ip_address) AS distinct_ips, 
        COUNT(DISTINCT device_id) AS distinct_devices,
        COUNT(fraud_confirmations.transaction_id) AS confirmed_fraud_count
    FROM transactions
    LEFT JOIN fraud_confirmations
    ON transactions.transaction_id = fraud_confirmations.transaction_id
    GROUP BY transactions.customer_id
),

card_summary AS (
    SELECT
        card_id, 
        COUNT(DISTINCT customer_id) AS distinct_customers,
        COUNT (*) AS total_tx, 
        COUNT(fraud_confirmations.transaction_id) AS confirmed_fraud_count,
        COUNT(DISTINCT ip_address) AS distinct_ips, 
        COUNT(DISTINCT device_id) AS distinct_devices
    FROM transactions
    LEFT JOIN fraud_confirmations
    ON transactions.transaction_id = fraud_confirmations.transaction_id
    GROUP BY card_id
),

ip_summary AS (
    SELECT
        ip_address, 
        COUNT(DISTINCT customer_id) AS distinct_customers,
        COUNT(DISTINCT card_id) AS distinct_cards,
        COUNT (*) AS total_tx, 
        COUNT(fraud_confirmations.transaction_id) AS confirmed_fraud_count,
        COUNT(DISTINCT device_id) AS distinct_devices
    FROM transactions
    LEFT JOIN fraud_confirmations
    ON transactions.transaction_id = fraud_confirmations.transaction_id
    GROUP BY ip_address
),

device_summary AS (
    SELECT
        device_id, 
        COUNT(DISTINCT customer_id) AS distinct_customers,
        COUNT(DISTINCT card_id) AS distinct_cards,
        COUNT(DISTINCT ip_address) AS distinct_ips,
        COUNT (*) AS total_tx, 
        COUNT(fraud_confirmations.transaction_id) AS confirmed_fraud_count
    FROM transactions
    LEFT JOIN fraud_confirmations
    ON transactions.transaction_id = fraud_confirmations.transaction_id
    GROUP BY device_id
),

fraud_entities AS (

SELECT
    'CUSTOMER' AS entity_type,
    customer_id::TEXT AS entity_value,
    1 AS distinct_customers,
    distinct_cards,
    distinct_ips,
    distinct_devices,
    total_tx,
    confirmed_fraud_count
FROM customer_summary

UNION ALL

SELECT
    'CARD' AS entity_type,
    card_id::TEXT AS entity_value,
    distinct_customers,
    1 AS distinct_cards,
    distinct_ips,
    distinct_devices,
    total_tx,
    confirmed_fraud_count
FROM card_summary

UNION ALL

SELECT
    'IP' AS entity_type,
    ip_address AS entity_value,
    distinct_customers,
    distinct_cards,
    1 AS distinct_ips,
    distinct_devices,
    total_tx,
    confirmed_fraud_count
FROM ip_summary

UNION ALL

SELECT
    'DEVICE' AS entity_type,
    device_id AS entity_value,
    distinct_customers,
    distinct_cards,
    distinct_ips,
    1 AS distinct_devices,
    total_tx,
    confirmed_fraud_count
FROM device_summary

)
SELECT
    *,
    ROUND(
        confirmed_fraud_count::DECIMAL / NULLIF(total_tx, 0),
        3
    ) AS fraud_rate
FROM fraud_entities
WHERE confirmed_fraud_count > 0
ORDER BY fraud_rate DESC, confirmed_fraud_count DESC;









WITH export_transactions AS (
    SELECT
        transaction_id,
        customer_id,
        card_id,
        device_id,
        ip_address,

        CASE
            -- Păstrăm IP-urile pattern-urilor frauduloase exact cum sunt
            WHEN ip_address LIKE '172.16.%'
                THEN ip_address

            -- Aproximativ 20% dintre tranzacțiile normale
            -- folosesc un al doilea IP pentru același customer
            WHEN transaction_id % 5 = 0
                THEN
                    '10.0.' ||
                    (customer_id / 250)::INT || '.' ||
                    ((customer_id % 250) + 1)::TEXT

            -- IP-ul principal al customerului
            ELSE
                '192.168.' ||
                (customer_id / 250)::INT || '.' ||
                ((customer_id % 250) + 1)::TEXT
        END AS export_ip

    FROM transactions
)

-- 1. CUSTOMER -> CARD
SELECT DISTINCT
    'CUSTOMER_' || customer_id AS source,
    'CARD_' || card_id AS target,
    'uses_card' AS relationship
FROM export_transactions
WHERE customer_id IS NOT NULL
  AND card_id IS NOT NULL

UNION ALL

-- 2. CUSTOMER -> IP
SELECT DISTINCT
    'CUSTOMER_' || customer_id AS source,
    'IP_' || export_ip AS target,
    'uses_ip' AS relationship
FROM export_transactions
WHERE customer_id IS NOT NULL
  AND export_ip IS NOT NULL

UNION ALL

-- 3. CUSTOMER -> DEVICE
SELECT DISTINCT
    'CUSTOMER_' || customer_id AS source,
    'DEVICE_' || device_id AS target,
    'uses_device' AS relationship
FROM export_transactions
WHERE customer_id IS NOT NULL
  AND device_id IS NOT NULL

UNION ALL

-- 4. CARD -> IP
SELECT DISTINCT
    'CARD_' || card_id AS source,
    'IP_' || export_ip AS target,
    'used_from_ip' AS relationship
FROM export_transactions
WHERE card_id IS NOT NULL
  AND export_ip IS NOT NULL

UNION ALL

-- 5. CARD -> DEVICE
SELECT DISTINCT
    'CARD_' || card_id AS source,
    'DEVICE_' || device_id AS target,
    'used_on_device' AS relationship
FROM export_transactions
WHERE card_id IS NOT NULL
  AND device_id IS NOT NULL

UNION ALL

-- 6. IP -> DEVICE
SELECT DISTINCT
    'IP_' || export_ip AS source,
    'DEVICE_' || device_id AS target,
    'ip_device' AS relationship
FROM export_transactions
WHERE export_ip IS NOT NULL
  AND device_id IS NOT NULL;












SELECT current_database();

-- DROP TABLE fraud_confirmations;

SELECT *
FROM transactions
LIMIT 100;


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






