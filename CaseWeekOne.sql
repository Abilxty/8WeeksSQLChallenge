/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

 1. What is the total amount each customer spent at the restaurant?
Select
customer_id AS Customer
,SUM(price) AS Total
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
GROUP BY customer_id

 2. How many days has each customer visited the restaurant?
Select
customer_id AS Customer,
COUNT(distinct order_date) AS VisitedDays
FROM sales AS s
GROUP BY customer_id

 3. What was the first item from the menu purchased by each customer?
WITH minDate AS
(
  SELECT 
--customer_id AS Customer
  MIN(order_date) AS Date
  FROM sales AS S
  GROUP BY customer_id
)
Select m.product_name AS Product
FROM menu AS m
INNER JOIN sales AS s
	ON s.product_id = m.product_id
INNER JOIN minDate AS mD
	ON mD.Customer = s.customer_id
    AND mD.Date = s.order_date 

 4. What is the most purchased item on the menu and how many times was it purchased by all customers? CHECK
SELECT product_name, COUNT(*) 
FROM sales AS s
INNER JOIN menu AS m
	ON m.product_id = s.product_id
GROUP BY product_name 
ORDER BY COUNT(*) DESC
LIMIT 1

 5. Which item was the most popular for each customer? CHECK but without ties
WITH popularProduct AS
(
SELECT customer_id
,product_id
,COUNT(*)
,ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY COUNT(*) DESC) AS r_id
FROM sales
GROUP BY customer_id, product_id
ORDER BY customer_id, COUNT(*) DESC
)
SELECT customer_id, product_name
FROM popularProduct AS pP
INNER JOIN menu AS m
	ON m.product_id = pP.product_id
WHERE r_id = 1


 6. Which item was purchased first by the customer after they became a member? Depends on when exactly? Did he buy on this day before he became a member? CHECK
WITH purchasesAfterMember AS
(
SELECT 
  s.customer_id
  ,s.product_id 
  ,ROW_NUMBER() OVER(PARTITION BY s.customer_id)
FROM sales AS s
INNER JOIN members AS me
	ON me.customer_id = s.customer_id AND order_date > join_date
)
SELECT 
customer_id
,product_name
FROM purchasesAfterMember AS p
INNER JOIN menu AS m
	ON m.product_id = p.product_id
WHERE row_number = 1


 7. Which item was purchased just before the customer became a member? CHECK
WITH purchaseBeforeMember AS
(
SELECT
s.customer_id
,s.product_id
,s.order_date
,ROW_NUMBER() OVER(PARTITION BY s.customer_id)
FROM sales AS s
INNER JOIN members AS me
	ON me.customer_id = s.customer_id AND s.order_date < me.join_date
)
SELECT p1.customer_id, m.product_name
FROM purchaseBeforeMember p1
LEFT JOIN purchaseBeforeMember p2
	ON p1.customer_id = p2.customer_id AND p1.row_number < p2.row_number
INNER JOIN menu AS m
	ON p1.product_id = m.product_id
WHERE p2.row_number IS NULL


 8. What is the total items and amount spent for each member before they became a member? CHECK
SELECT
s.customer_id
,COUNT(*) AS totalItems
, SUM(price) AS totalAmount
FROM sales AS s
INNER JOIN members AS me
	ON s.order_date < me.join_date AND s.customer_id = me.customer_id
INNER JOIN menu AS m
	ON m.product_id = s.product_id
GROUP BY s.customer_id


 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? CHECK
WITH perCustomerPoints AS
(
WITH perItemCustomer AS
(
SELECT 
customer_id
,s.product_id
,COUNT(*) AS count
FROM sales AS s
GROUP BY customer_id, s.product_id
)
SELECT 
p.customer_id
,CASE
  WHEN p.product_id = 1 THEN count*20*price
  WHEN p.product_id != 1 THEN count*10*price
END AS points
FROM perItemCustomer AS p
INNER JOIN menu AS m
	ON p.product_id = m.product_id
)
SELECT
customer_id
,SUM(points)
FROM perCustomerPoints
GROUP BY customer_id


 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January? CHECK
  
WITH pointsPerPurchase AS
(
SELECT
s.customer_id
,s.product_id
,s.order_date
,CASE
	WHEN s.order_date IN (
      					  SELECT order_date
                          FROM sales AS s
                          INNER JOIN members AS me
                              ON 1=1 
                              AND me.customer_id = s.customer_id 
                              AND s.order_date BETWEEN me.join_date AND me.join_date+ INTERVAL'7 day' 
    					  ) AND s.customer_id IN (SELECT customer_id FROM members)
	THEN me.price*20
    WHEN s.order_date NOT IN (
                            SELECT order_date
                            FROM sales AS s
                            INNER JOIN members AS me
                                ON 1=1 
                                AND me.customer_id = s.customer_id 
                                AND s.order_date BETWEEN me.join_date AND me.join_date+ INTERVAL'7 day' 
    					  ) AND s.product_id = 1
	THEN me.price*20
    ELSE me.price*10
END AS points
FROM sales AS s
INNER JOIN menu AS me
	ON s.product_id = me.product_id
ORDER BY s.customer_id ASC
  )
SELECT 
customer_id
,SUM(points)
FROM pointsPerPurchase
WHERE 1=1
AND order_date < '2021-02-01' 
AND customer_id IN ('A','B')
GROUP BY customer_id
