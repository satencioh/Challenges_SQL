USE pizza_runner;
GO

-- Limpieza de los datos

UPDATE customer_orders
SET exclusions = ''
WHERE exclusions IS NULL OR exclusions = 'null';

UPDATE customer_orders
SET extras = ''
WHERE extras IS NULL OR extras = 'null';

UPDATE runner_orders
SET pickup_time = NULL
WHERE pickup_time = 'null';

UPDATE runner_orders
SET distance = NULL
WHERE distance = 'null';

UPDATE runner_orders
SET duration = NULL
WHERE duration = 'null';

UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation = 'null' or cancellation = '';

select * from runner_orders


-- eliminar los km en columna distance
UPDATE runner_orders
SET distance = SUBSTRING(distance, 1, len(distance)-2)
WHERE distance like '%km';

-- cambiar tipo de dato de variable distance
ALTER TABLE runner_orders
ALTER COLUMN distance float;

--- extraer solo los numeros de la variable duration

UPDATE runner_orders
SET duration = SUBSTRING(duration, PATINDEX('%[0-9]%', duration), PATINDEX('%[0-9][^0-9]%', duration + 't') - PATINDEX('%[0-9]%', duration) + 1);

ALTER TABLE runner_orders
ALTER COLUMN duration int;

-- cambiar tipo de dato de picup a solo fecha
ALTER TABLE runner_orders
ALTER COLUMN pickup_time datetime;


---- A. Metricas de pizza -------

-- 1. ¿Cuántas pizzas fueron ordenadas?

select count(order_id) as cantidad_pizzas_ordenadas from customer_orders;

-- 2. ¿Cuántos pedidos únicos de clientes se realizaron?

select count(distinct(order_id)) as pedido_unicos from customer_orders;

-- 3. ¿Cuántos pedidos exitosos entregó cada corredor?
select runner_id, count(order_id) as pedidos_exitosos
from runner_orders
where cancellation IS NULL
group by runner_id;

-- 4. ¿Cuántas pizzas de cada tipo se entregaron?

select pizza_id, count(order_id) as cantidad_entregada
from customer_orders
group by pizza_id;

-- 5. ¿Cuántos vegetarianos y amantes de la carne ordenó cada cliente?

select c.customer_id, SUM(CASE WHEN p.pizza_name LIKE 'Meatlovers' THEN 1 ELSE 0 END) cantidad_Meatlovers, SUM(CASE WHEN p.pizza_name LIKE 'Vegetarian' THEN 1 ELSE 0 END) as cantidad_Vegetarian
from customer_orders as c
inner join pizza_names as p
ON c.pizza_id = p.pizza_id
GROUP BY c.customer_id
ORDER BY c.customer_id;

-- 6. ¿Cuál fue el número máximo de pizzas entregadas en un solo pedido?
with conteo_pizza as
(SELECT order_id, COUNT(*) as pizzas_pedidos 
from customer_orders
GROUP BY order_id)
SELECT MAX(pizzas_pedidos) as numero_max_entrega FROM conteo_pizza;
-- 7. Para cada cliente, ¿cuántas pizzas entregadas tenían al menos 1 cambio y cuántas no tenían cambios?
SELECT c.customer_id,
SUM(CASE WHEN  c.exclusions <> '' OR c.extras <> '' THEN 1 ELSE 0 END ) AS con_cambios,
SUM(CASE WHEN  c.exclusions = '' AND c.extras = '' THEN 1 ELSE 0 END) AS sin_cambios
FROM customer_orders as c
INNER JOIN runner_orders as r
ON	c.order_id = r.order_id
WHERE cancellation is null
GROUP BY c.customer_id;
-- 8. ¿Cuántas pizzas se entregaron que tenían exclusiones y extras?
SELECT COUNT(*) exclus_extras
FROM customer_orders as c
INNER JOIN runner_orders as r
ON	c.order_id = r.order_id
WHERE c.exclusions <> '' AND c.extras <> '' AND cancellation is null;

-- 9. ¿Cuál fue el volumen total de pizzas ordenadas para cada hora del día?
with hora as (
SELECT DATENAME(HOUR ,order_time) AS hora  
FROM customer_orders )
SELECT hora, COUNT(*) as pizzas_por_hora
FROM hora
GROUP BY hora
ORDER BY hora;
-- 10. ¿Cuál fue el volumen de pedidos para cada día de la semana?

with dia as (
SELECT DATENAME(DAY ,order_time) AS dia  
FROM customer_orders )
SELECT dia, COUNT(*) as pizzas_por_dia
FROM dia
GROUP BY dia
ORDER BY dia;

------------ B. Runner y experiencia del cliente ----------
-- 1. ¿Cuántos corredores se inscribieron para cada período de 1 semana? (es decir, la semana comienza el 2021-01-01)
SELECT DATENAME(WEEK ,registration_date) AS semana_registro, COUNT(*) as cantidad_repartidores
FROM runners
GROUP BY DATENAME(WEEK ,registration_date);
-- 2. ¿Cuál fue el tiempo promedio en minutos que tardó cada corredor en llegar a la sede de Pizza Runner para recoger el pedido?
SELECT r.runner_id, round(avg(DATEDIFF(MINUTE, c.order_time, r.pickup_time)), 1) as tiempo_promedio
FROM customer_orders AS c
INNER JOIN runner_orders AS r
ON c.order_id = r.order_id
WHERE r.distance != 0
GROUP BY r.runner_id
ORDER BY r.runner_id;
-- 3. ¿Existe alguna relación entre la cantidad de pizzas y el tiempo de preparación del pedido?
with cte as (
SELECT c.order_id, count(c.order_id) as cantidad_pizza, c.order_time, r.pickup_time,
(DATEDIFF(MINUTE, c.order_time, r.pickup_time)) as tiempo_promedio
FROM customer_orders AS c
INNER JOIN runner_orders AS r
ON c.order_id = r.order_id
WHERE r.distance != 0
GROUP BY c.order_id, r.pickup_time, c.order_time
)select cantidad_pizza, round(avg(tiempo_promedio), 2) as promedio 
from cte
GROUP BY cantidad_pizza;


-- 4. ¿Cuál fue la distancia promedio recorrida por cada cliente?
select c.customer_id, round(AVG(r.distance), 1) as distancia_recorrida
FROM customer_orders as c
inner join runner_orders as r
on c.order_id = r.order_id
group by c.customer_id;
-- 5. ¿Cuál fue la diferencia entre los tiempos de entrega más largos y más cortos para todos los pedidos?
with cte as (
SELECT c.order_id,  c.order_time, r.pickup_time,
(DATEDIFF(MINUTE, c.order_time, r.pickup_time)) as tiempo_diferencia
FROM customer_orders AS c
INNER JOIN runner_orders AS r
ON c.order_id = r.order_id
WHERE r.distance != 0
GROUP BY c.order_id, r.pickup_time, c.order_time
)select max(tiempo_diferencia)- min(tiempo_diferencia) as diferencia_tiempo
from cte;


-- 6. ¿Cuál fue la velocidad promedio de cada corredor para cada entrega? ¿Observa alguna tendencia para estos valores?
select r.runner_id, round(AVG(r.distance *60 / r.duration), 1) as velocidad_promedio
FROM runner_orders as r
group by r.runner_id;
-- 7. ¿Cuál es el porcentaje de entrega exitosa para cada corredor?

select * from runners;
select * from runner_orders;
select * from customer_orders;
select * from pizza_names;
select * from pizza_recipes;
select * from pizza_toppings;
