
--1. ¿Cuál es la cantidad total que gastó cada cliente en el restaurante?

`SELECT s.customer_id, sum(m.price) total_amount
FROM dannys_diner.sales as s
INNER JOIN dannys_diner.menu as m
ON s.product_id = m.product_id
group by s.customer_id`

-- 2. ¿Cuántos días ha visitado el restaurante cada cliente?

`SELECT customer_id, count(distinct(order_date))
FROM dannys_diner.sales
group by customer_id`

-- 3. ¿Cuál fue el primer artículo del menú comprado por cada cliente

`SELECT s.customer_id, m.product_name
FROM dannys_diner.sales as s
INNER JOIN dannys_diner.menu as m
ON s.product_id = m.product_id
where s.order_date = (SELECT min(order_date) FROM dannys_diner.sales)
group by s.customer_id, m.product_name
ORDER BY s.customer_id`

-- 4. ¿Cuál es el artículo más comprado en el menú y cuántas veces lo compraron todos los clientes?

`SELECT m.product_name, count(m.product_name) as veces_comprado
FROM dannys_diner.sales as s
INNER JOIN dannys_diner.menu as m
ON s.product_id = m.product_id
group by m.product_name`

-- 5. ¿Qué artículo fue el más popular para cada cliente?

`with cte_1 as
(
SELECT s.customer_id, m.product_name, count(*) as veces_comprado
FROM sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id
group by s.customer_id, m.product_name
),
cte_2 as
(
SELECT product_name, customer_id, veces_comprado,
DENSE_RANK() OVER( PARTITION BY customer_id ORDER BY veces_comprado desc) as producto_rankeado
FROM cte_1
)
SELECT *
FROM cte_2
WHERE producto_rankeado = 1;`

-- 6. ¿Qué artículo compró primero el cliente después de convertirse en miembro?

`with cte as
(
select s.customer_id, m.join_date, s.order_date, mu.product_name,
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date ASC ) as rank_producto
from members as m
inner join sales as s
on m.customer_id = s.customer_id
inner join menu as mu
on s.product_id = mu.product_id
where s.order_date >= m.join_date
)
select customer_id, product_name
from cte
where rank_producto = 1;`

-- 7. ¿Qué artículo se compró justo antes de que el cliente se convirtiera en miembro?

`with cte as
(
select s.customer_id, m.join_date, s.order_date, mu.product_name,
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date ASC ) as rank_producto
from members as m
inner join sales as s
on m.customer_id = s.customer_id
inner join menu as mu
on s.product_id = mu.product_id
where s.order_date < m.join_date
)
select customer_id, product_name
from cte
where rank_producto = 1;`

-- 8. ¿Cuál es el total de artículos y la cantidad gastada por cada miembro antes de convertirse en miembro?

`select s.customer_id, count(mu.product_name) as total_articulos, sum(mu.price) as cantidad_gastada
from members as m
inner join sales as s
on m.customer_id = s.customer_id
inner join menu as mu
on s.product_id = mu.product_id
where s.order_date < m.join_date
group by s.customer_id`

-- 9. Si cada $ 1 gastado equivale a 10 puntos y el sushi tiene un multiplicador de puntos 2x, ¿cuántos puntos tendría cada cliente?

`SELECT
s.customer_id,
SUM(CASE WHEN mu.product_name = 'sushi' THEN mu.price*20 ELSE mu.price*10 END) as total_puntos
FROM sales s
JOIN menu mu
ON (s.product_id = mu.product_id) JOIN members m
ON (s.customer_id = m.customer_id)
WHERE s.order_date >= m.join_date
GROUP BY s.customer_id;`

-- 10. En la primera semana después de que un cliente se une al programa (incluida la fecha de ingreso), gana el doble de puntos en todos los artículos, no solo en sushi. ¿Cuántos puntos tienen los clientes A y B a fines de enero?

`WITH cte AS (
SELECT
customer_id,
join_date,
DATEADD(day, 6, join_date) AS primera_semana
,eomonth(join_date) AS ultima_semana
FROM members
)
SELECT
c.customer_id,
SUM(CASE
WHEN s.order_date BETWEEN c.join_date AND c.primera_semana THEN e.price*20
ELSE e.price*10 END) AS total_puntos
FROM cte c
INNER JOIN sales s
ON c.customer_id = s.customer_id
INNER JOIN menu e
ON s.product_id = e.product_id
WHERE s.order_date <= ultima_semana and s.order_date >= c.join_date
GROUP BY c.customer_id
ORDER BY c.customer_id`