/*===============
	QUERIES 
==================*/

/*======================================
1. Clientes que han realizado más envíos
=========================================*/

SELECT cu.customer_id, cu.customer_name, COUNT(*) AS total_shipments
FROM dim_customer_clean cu
LEFT JOIN fact_shipments_clean sh
ON cu.customer_id = sh.customer_id
GROUP BY cu.customer_id, cu.customer_name
ORDER BY total_shipments DESC;

	-- Ana López es la mejor cliente en cuanto a número de envíos

/*======================================
2. Clientes que han realizado más gasto
=========================================*/

SELECT cu.customer_id, cu.customer_name, SUM(sh.shipping_cost)  AS total_cost
FROM dim_customer_clean cu
LEFT JOIN fact_shipments_clean sh
ON cu.customer_id = sh.customer_id
GROUP BY cu.customer_id, cu.customer_name
ORDER BY total_cost DESC;

	-- Ana López es la mejor cliente en cuanto a gasto realizado

/*==============================================
3. Clientes que han realizado más gasto por año
================================================*/

SELECT 
	cu.customer_id, 
	cu.customer_name, 
    YEAR(sh.date_id) as year, 
    SUM(sh.shipping_cost) AS total_cost
FROM dim_customer_clean cu
LEFT JOIN fact_shipments_clean sh
ON cu.customer_id = sh.customer_id
GROUP BY cu.customer_id, cu.customer_name, YEAR(sh.date_id)
ORDER BY year, total_cost DESC;


/*=======================================================
4. Top 3 de clientes que han realizado más gasto por año
=========================================================*/
-- Si quiero limitar a n resultados por año necesito una función row_number() o rank()

WITH ranking AS (
    SELECT 
        cu.customer_id,
        cu.customer_name,
        YEAR(sh.date_id) AS year,
        SUM(sh.shipping_cost) AS total_cost,
        ROW_NUMBER() OVER (
            PARTITION BY YEAR(sh.date_id)
            ORDER BY SUM(sh.shipping_cost) DESC
        ) AS ranking_per_year
    FROM dim_customer_clean cu
    LEFT JOIN fact_shipments_clean sh ON cu.customer_id = sh.customer_id
    GROUP BY cu.customer_id, cu.customer_name, YEAR(sh.date_id)
)
SELECT *
FROM ranking
WHERE ranking_per_year <= 3
ORDER BY year, total_cost DESC;

	-- En caso de empate, en lugar de ROW_NUMBER() podríamos usar RANK()

/*=========================================================================================
5. Top 3 de clientes que han realizado más gasto por año ordenado por el mejor de cada año
===========================================================================================*/

WITH ranking AS (
    SELECT 
        cu.customer_id,
        cu.customer_name,
        YEAR(sh.date_id) AS year,
        SUM(sh.shipping_cost) AS total_cost,
        RANK() OVER (
            PARTITION BY YEAR(sh.date_id)
            ORDER BY SUM(sh.shipping_cost) DESC
        ) AS ranking_per_year
    FROM dim_customer_clean cu
    LEFT JOIN fact_shipments_clean sh ON cu.customer_id = sh.customer_id
    GROUP BY cu.customer_id, cu.customer_name, YEAR(sh.date_id)
)
SELECT *
FROM ranking
WHERE ranking_per_year <= 3
ORDER BY ranking_per_year, total_cost DESC;

/*=========================================================================================
6. Empresas de transporte con menos tiempo de entrega medio
===========================================================================================*/

SELECT 
	ca.carrier_id, 
    ca.carrier_name, 
    ca.carrier_type,
    ROUND(AVG(sh.delivery_time_days), 1) AS average_delivery_days
FROM dim_carrier_clean ca
JOIN fact_shipments_clean sh
ON ca.carrier_id = sh.carrier_id
GROUP BY ca.carrier_id, ca.carrier_name, ca.carrier_type
ORDER BY average_delivery_days;

	-- El que menos tiempo de entrega tiene de promedio es Correos Expres Urgente
    
 /*=========================================================================================
7. Empresa con menor coste medio por peso de mercancía
===========================================================================================*/   

SELECT
    ca.carrier_name,
    ca.carrier_type,
    ROUND(AVG(sh.shipping_cost / sh.weight_kg), 3) AS €_kg 
FROM fact_shipments_clean sh
JOIN dim_carrier_clean ca ON ca.carrier_id = sh.carrier_id
GROUP BY ca.carrier_name, ca.carrier_type
ORDER BY  €_kg  ASC;

	-- La empresa con menor coste medio por peso de mercancía es Correos Expres Urgente
    
    
/*=========================================================================================
8. Días de la semana con más envíos
===========================================================================================*/    

-- Preparo una vista con los días de la semana

DROP VIEW IF EXISTS vw_date;
CREATE VIEW vw_date AS
	SELECT
		full_date,
		YEAR(full_date) AS year, 
		MONTHNAME(full_date) AS month,  -- Si usamos MONTH aparece como número del 1 al 12
		DAYNAME(full_date) AS week_day
    FROM dim_date_clean;  

SELECT * FROM vw_date;

-- Compruebo que puedo hacer un JOIN relacionando full_date con date_id

SELECT full_date, date_id
FROM fact_shipments_clean sh
JOIN vw_date vd
ON vd.full_date=sh.date_id;


-- Días de la semana con más envíos

SELECT COUNT(*), vd.week_day
FROM fact_shipments_clean sh
JOIN vw_date vd
ON vd.full_date=sh.date_id
GROUP BY vd.week_day;

	-- Los días con más envíos son lunes, miércoles y viernes.  
    
	-- No aparece ningún sábado. Compruebo con un RIGHT JOIN si es verdad o he cometido algún error.
    
SELECT vd.week_day, sh.date_id
FROM fact_shipments_clean sh
RIGHT JOIN vw_date vd
ON vd.full_date=sh.date_id
WHERE vd.week_day = 'Saturday'
GROUP BY vd.week_day, sh.date_id;

	-- Correcto: ningún sábado tiene pedidos porque sh.date_id es nulo.
    
/*=========================================================================================
9. Meses con más envíos
===========================================================================================*/       

SELECT COUNT(*), vd.month
FROM fact_shipments_clean sh
JOIN vw_date vd
ON vd.full_date=sh.date_id
GROUP BY vd.month;  
    
    -- No parece haber una diferencia significativa en el número de envíos en ninguna época en concreta
    
 
/*=========================================================================================
10. Cantidad de envíos por categoría de peso: ligero-medio-pesado
===========================================================================================*/   
-- Usamos CASE WHEN para definir las categorías
-- Primero vemos cual es el peso máximo en nuestra tabla para definir categorías

SELECT MAX(weight_kg)
FROM fact_shipments_clean;

	-- El máximo es de 9.46 kg

SELECT 
	COUNT(*) AS total_shipments, 
	weight_category
FROM (
	SELECT 
		sh.weight_kg,
		CASE 
			WHEN sh.weight_kg < 2 THEN 'Ligth'
			WHEN sh.weight_kg BETWEEN 2 AND 5 THEN 'Medium'
			ELSE 'Heavy'
		END AS weight_category
	FROM fact_shipments_clean sh ) AS sh
    GROUP BY weight_category;
  
	-- Los envíos se distribuyen de forma más o menos homnogénea  en función del peso según nuestra clasificación
    
/*=========================================================================================
11. País de destino más demandado
===========================================================================================*/   

SELECT COUNT(*), de.country
FROM fact_shipments sh
JOIN dim_destination_clean de
ON sh.destination_id=de.destination_id
GROUP BY de.country;

	-- El país de destino con más demanda es España

/*=========================================================================================
12. Promedio de coste por país de destino
===========================================================================================*/   

SELECT de.country, AVG(sh.shipping_cost) AS average_cost
FROM fact_shipments sh
JOIN dim_destination_clean de
ON sh.destination_id=de.destination_id
GROUP BY de.country
ORDER BY average_cost;

	-- El coste del servicio es más barato de media cuando el país de destino es Francia
    
  