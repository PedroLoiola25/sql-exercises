-- ============================================
-- SQL Practice - Northwind (PostgreSQL)
-- Author: Pedro Loiola
-- Total exercises: 17
-- Topics covered:
-- SELECT, JOINs, GROUP BY, subqueries, CTEs, window functions
-- ============================================

-- Exercício 01 time comercial quer uma lista de clientes da América do Sul para uma campanha regional.
SELECT 
	customer_id,
	country 
FROM customers
WHERE country = 'Brazil' OR  country = 'Venezuela' OR country = 'Argentina'
ORDER BY country;

-- Exercício 02 Liste os pedidos feitos em um determinado ano com frete acima da média. **

SELECT 
	order_id, 
	freight, 
	order_date 
FROM orders
WHERE order_date >= '1997-01-01' 
	AND order_date <= '1997-12-31' 
	AND freight > (
      	SELECT AVG(freight)
      	FROM orders
  	)
ORDER BY freight

-- Exercício 03 Traga os produtos mais caros da empresa, ordenados do maior para o menor.

SELECT product_id, product_name, unit_price FROM products
ORDER BY unit_price desc
LIMIT 10

-- Exercício 04 Gere um relatório com pedidos mostrando data do pedido, nome do cliente e país.

SELECT o.order_id, o.order_date, c.company_name, c.country
from orders o
JOIN customers c ON o.customer_id = c.customer_id

-- Exercício 05 O time de logística quer ver pedidos junto com a transportadora responsável. 
-- Não consegui encontrar o relecaionamento das databelas, pois nao acreditei que seria pela coluna ship_via, fiz um distinct dela e retornou só 1,2 e 3, entao achei que nao era ela pois na tabela shipper, na coluna shipper_id tem vai do 1 ao 6.

SELECT
    o.order_id,
    o.ship_via,
    s.shipper_id,
    s.company_name
FROM orders o
JOIN shippers s
    ON o.ship_via = s.shipper_id;

-- Exercício 06 Liste produtos mostrando: nome do produto, categoria e fornecedor

SELECT p.product_name as nome_do_produto, 
	c.category_name as categoria, 
	s.company_name as fornecedor
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN suppliers s ON p.supplier_id = s.supplier_id

-- Exercício 07 Traga todos os clientes, inclusive os que nunca fizeram pedidos, 
--e informe quantos pedidos cada um fez.

SELECT
  c.customer_id,
  c.company_name,
  COUNT(o.order_id) AS total_pedidos
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.company_name
ORDER BY total_pedidos DESC, c.customer_id;

-- Exercício 08 Quantos pedidos cada cliente já fez?

SELECT customer_id, count(order_id) as pedidos
FROM orders
GROUP BY customer_id

-- Exercício 09 Qual é o faturamento total por pedido?
SELECT order_id,
	SUM(unit_price * quantity * (1 - discount)) as valor_total
FROM order_details
GROUP BY order_id
ORDER BY order_id

-- Exercício 10 Liste os 5 clientes que mais faturaram.

SELECT  c.customer_id,
		c.company_name,
		SUM(od.unit_price * od.quantity * (1 - od.discount)) as valor_total
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN order_details od ON od.order_id = o.order_id
GROUP BY c.customer_id, c.company_name
ORDER BY valor_total DESC
LIMIT 5

-- Exercício 11 Liste produtos que custam mais do que a média de preço da empresa.


SELECT  product_id, 
		unit_price
From products
WHERE unit_price > (SELECT avg(unit_price) FROM products)
ORDER BY unit_price DESC

-- Exercício 12 Liste clientes que fizeram mais pedidos do que a média de pedidos por cliente.
SELECT count(order_id) AS total_pedidos,
		customer_id 
FROM orders
GROUP BY customer_id
HAVING count(order_id) > (
	SELECT avg(total_pedidos) 
	FROM (
		SELECT count(order_id) AS total_pedidos
		FROM orders
		GROUP BY customer_id
		) sub
)
ORDER BY total_pedidos

-- Exercício 13: Para cada cliente, traga apenas o pedido mais recente.
SELECT
  o.customer_id,
  o.order_id,
  o.order_date
FROM orders o
WHERE o.order_date = (
  SELECT MAX(o2.order_date)
  FROM orders o2
  WHERE o2.customer_id = o.customer_id
)
ORDER BY o.customer_id, o.order_date DESC, o.order_id DESC;


-- Exercício 14: Crie uma lógica reutilizável que calcule o faturamento por pedido
-- e depois use isso para gerar um relatório completo de pedidos

WITH faturamento_pedido AS (
SELECT order_id,
	SUM(unit_price * quantity * (1 - discount)) as valor_total
FROM order_details
GROUP BY order_id
)
SELECT * 
FROM orders o
JOIN faturamento_pedido fp on o.order_id = fp.order_id

-- Exercício 15: Use CTEs para calcular: Receita por cliente
-- Ranking de clientes por receita
WITH faturamento_pedido AS (
	SELECT 
		order_id,
		SUM(unit_price * quantity * (1 - discount)) as valor_total
	FROM order_details
GROUP BY order_id
),
tabela_completa AS (
	SELECT * FROM orders o
	JOIN faturamento_pedido fp on o.order_id = fp.order_id
)
SELECT 
	customer_id,
	SUM(valor_total) AS receita_total,
	rank() over(order by SUM(valor_total) DESC) AS ranking_receita
FROM tabela_completa
GROUP BY customer_id

-- Exercício 16 Para cada cliente, mostre os pedidos em ordem cronológica e compare o valor do pedido atual com o anterior.
WITH valor_pedido AS (
  SELECT
    o.customer_id,
    o.order_id,
    o.order_date,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) AS valor_atual
  FROM orders o
  JOIN order_details od ON o.order_id = od.order_id
  GROUP BY o.customer_id, o.order_id, o.order_date
)
SELECT
  customer_id,
  order_id,
  TO_CHAR(order_date, 'YYYY-MM-DD') AS order_date,
  LAG(valor_atual) OVER (
    PARTITION BY customer_id
    ORDER BY order_date ASC, order_id ASC
  ) AS valor_anterior,
  valor_atual
FROM valor_pedido
ORDER BY customer_id, order_date, order_id;

-- Exercício 17 Gere um relatório de faturamento acumulado por cliente ao longo do tempo.

WITH valor_pedido AS (
  SELECT
    o.customer_id,
    o.order_id,
    o.order_date,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) AS valor_pedido
  FROM orders o
  JOIN order_details od ON o.order_id = od.order_id
  GROUP BY o.customer_id, o.order_id, o.order_date
)
SELECT
  customer_id,
  TO_CHAR(order_date, 'YYYY-MM-DD') AS order_date,
  valor_pedido,
  SUM(valor_pedido) OVER (
    PARTITION BY customer_id
    ORDER BY order_date ASC, order_id ASC
  ) AS faturamento_acumulado
FROM valor_pedido
ORDER BY customer_id, order_date, order_id;