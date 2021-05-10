
--1.How many pizzas were ordered?

/* SELECT COUNT(*) AS Ordered_Pizzas
FROM customer_orders */

--2.How many unique customer orders were made?

--3.How many successful orders were delivered by each runner?
/* WITH processed_runner_order AS
(
SELECT *
,CASE
    WHEN cancellation IS NULL OR LOWER(cancellation) LIKE 'null' OR LEN(cancellation) = 0
    THEN 'N/A'
    ELSE cancellation
END AS cancellation_cleaned
FROM runner_orders
)
SELECT 
runner_id
,COUNT(*) AS successful_orders
FROM processed_runner_order
WHERE cancellation_cleaned = 'N/A'
GROUP BY runner_id
 */

--4.How many of each type of pizza was delivered?
/* SELECT 
CO.pizza_id
,COUNT(*) AS Amount
FROM customer_orders AS CO
JOIN runner_orders AS RO
    ON CO.order_id = RO.order_id
WHERE LOWER(cancellation) LIKE 'null' OR LEN(cancellation) = 0 OR cancellation IS NULL
GROUP BY CO.pizza_id */

--5.How many Vegetarian and Meatlovers were ordered by each customer?
/* SELECT 
CO.customer_id
,PN.pizza_name
,COUNT(*) AS Amount
FROM customer_orders AS CO
INNER JOIN pizza_names PN
    ON CO.pizza_id = PN.pizza_id
GROUP BY CO.customer_id, PN.pizza_name
ORDER BY CO.customer_id */

--6.What was the maximum number of pizzas delivered in a single order?
/* WITH PizzasPerOrder AS
(
SELECT 
order_id
,COUNT(*) AS OrderedPizzas
FROM customer_orders
GROUP BY order_id
)
SELECT 
order_id
,OrderedPizzas
FROM PizzasPerOrder
WHERE OrderedPizzas = (SELECT MAX(OrderedPizzas) FROM PizzasPerOrder) */

--7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
WITH cleanedChanges AS
(
SELECT *,
CASE
    WHEN exclusions IS NULL OR len(exclusions) = 0 OR lower(exclusions) = 'null' 
    THEN 'n/a'
    ELSE exclusions
END AS exclusion_processed,
CASE
WHEN extras IS NULL OR len(extras) = 0 OR lower(extras) = 'null' 
    THEN 'n/a'
    ELSE extras
END AS extras_processed 
FROM customer_orders
)
SELECT 
customer_id
,COUNT(*) AS PizzasWithChanges
FROM cleanedChanges
WHERE exclusion_processed != 'n/a' OR extras_processed != 'n/a'
GROUP BY customer_id