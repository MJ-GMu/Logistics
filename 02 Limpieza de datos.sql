/*===============================
	LIMPIEZA DE DATOS
=================================*/

-- Buscar duplicados
-- Buscar valores nulos
-- Buscar incongruencias/errores en nombres/fechas

/*===============================
	TABLA dim_carrier
=================================*/
-- Ver la tabla completa
SELECT * FROM dim_carrier;

-- Ver cuántas filas tiene la tabla (en este caso se podría ver con la query anterior)
SELECT COUNT(*) FROM dim_carrier; -- Tenemos 9 filas en esta tabla

-- Ver cuantos ID distintos tenemos, por si hay duplicados, sabiendo el número de filas
SELECT COUNT(distinct carrier_id) FROM dim_carrier;   -- Tenemos 9 ID distintos, por lo que no hay duplicado en carrier_id

-- Ver filas duplicadas con distinto id
SELECT COUNT(distinct carrier_name, carrier_type) FROM dim_carrier;  -- Tenemos 6 distintos, por lo que hay 3 posibles duplicados o nulos

-- Ver los posibles duplicados
SELECT distinct carrier_name, carrier_type FROM dim_carrier; -- Tenemos 7 distintos, uno de ellos es un null, por eso no aparece en el COUNT anterior

-- Seleccionar los duplicados
SELECT carrier_name, carrier_type, COUNT(*) 
FROM dim_carrier
GROUP BY carrier_name, carrier_type
HAVING COUNT(*) > 1;

-- Vemos que hay dos duplicados, DHL y UPS

-- Vamos a ver qué ID tiene cada uno para eliminarlo
SELECT * FROM dim_carrier
WHERE carrier_name IN ('DHL' , 'UPS');

-- Eliminaremos carrier_id 5 y 8
-- IMPORTANTE!! En la tabla fact_shipments, tendremos que sustituir los carrier_id 5 por 1 y 8 por 4


-- Ya habíamos detectado un nulo, pero lo podenos volver a ver con la siguiente query
SELECT * FROM dim_carrier
WHERE carrier_name IS NULL
	OR carrier_type IS NULL;

-- Vemos que hay un null en carrier_type para carrier_name = Correos Express

-- Vemos si tenemos más Corres Express
SELECT * FROM dim_carrier
WHERE carrier_name = 'Correos Express';  

-- Dos posibilidades: Llamarlo como Correos Express Urgente y eliminar duplicado o llamarlo Correos Express Normal. Investigando en la tabla Facts, el tiempo de entrega de este Correos Express respecto al otro es mayor. Por lo tanto, lo vamos a llamar Normal en lugar de Urgente

-- Ver los distintos nombres en cada columna

SELECT DISTINCT carrier_name COLLATE utf8mb4_bin  -- Se utiliza COLLATE utf8mb4_bin para que diferencie entre mayúsculas y minúsculas, ya que MySQL no es "case sensitive".
FROM dim_carrier;
-- Para que quede homogéneo, aunque no es necesario, cambiaremos Seur a SEUR

SELECT DISTINCT carrier_type COLLATE utf8mb4_bin  
FROM dim_carrier;
-- Para que quede homogéneo, aunque no es necesario, cambiaremos internacional a Internacional

/*===============================
	LIMPIEZA DE TABLA dim_carrier
=================================*/

-- Eliminar carrier_id 5 y 8
-- Cambiar Seur a SEUR en carrier_name
-- Cambiar internacional a Internacional en carrier_type


-- Antes de limpiar, voy a crear una copia de la tabla original, para no modificar la original

DROP TABLE IF EXISTS dim_carrier_clean;
CREATE TABLE dim_carrier_clean AS
SELECT *
FROM dim_carrier;

SELECT * FROM dim_carrier_clean; -- Compruebo que la ha creado

-- Eliminar carrier_id 5 y 8

SET SQL_SAFE_UPDATES = 0; -- Como voy a eliminar IDs, tengo que desactivar el modo SAFE

DELETE FROM dim_carrier_clean
WHERE carrier_id IN (5, 8);

SELECT * FROM dim_carrier_clean;


-- Cambiar Seur a SEUR en carrier_name

UPDATE dim_carrier_clean
SET carrier_name = 'SEUR'
WHERE carrier_name = 'Seur';

SELECT * FROM dim_carrier_clean;

-- Cambiar normal a Normal en carrier_type

UPDATE dim_carrier_clean
SET carrier_type = 'Normal'
WHERE carrier_type = 'normal';

SELECT * FROM dim_carrier_clean;

-- Actualizar el NUll de Correos Express a Normal

UPDATE dim_carrier_clean
SET carrier_type = 'Normal'
WHERE carrier_id = '7';

SELECT * FROM dim_carrier_clean;


/*===============================
	TABLA dim_customer
=================================*/
-- Ver la tabla completa
SELECT * FROM dim_customer;

-- Ver cuántas filas tiene la tabla (en este caso se podría ver con la query anterior)
SELECT COUNT(*) FROM dim_customer; -- Tenemos 11 filas en esta tabla

-- Ver cuantos ID distintos tenemos, por si hay duplicados, sabiendo el número de filas
SELECT COUNT(distinct customer_id) FROM dim_customer;   -- Tenemos 11 ID distintos, por lo que no hay duplicado en carrier_id

-- Ver filas duplicadas con distinto id
SELECT COUNT(distinct customer_name, customer_email, customer_city, customer_country) FROM dim_customer;  -- Tenemos 8 distintos, por lo que hay 3 posibles duplicados

-- Ver los posibles duplicados
SELECT distinct customer_name, customer_email, customer_city, customer_country FROM dim_customer; -- Tenemos 10 distintos, dos de ellos son un null, por eso no aparece en el COUNT anterior

-- Seleccionar los duplicados
SELECT customer_name, customer_email, customer_city, customer_country, COUNT(*) 
FROM dim_customer
GROUP BY customer_name, customer_email, customer_city, customer_country
HAVING COUNT(*) > 1;

-- Vemos que hay 1 duplicado, Ana López. 
-- Vamos a ver qué ID tiene para eliminarlo

SELECT * FROM dim_customer
WHERE customer_name = 'Ana López';

-- Eliminaremos customer_id=6
-- IMPORTANTE!! En la tabla fact_shipments, tendremos que sustituir el customer_id 6 por 1.


-- Ya habíamos detectado los nulos, pero los podenos volver a ver con la siguiente query
SELECT * FROM dim_customer
WHERE customer_name IS NULL
   OR customer_email IS NULL
   OR customer_city IS NULL
   OR customer_country IS NULL;

-- Vemos que hay un email nulo y una city nula. No vamos a modificar nada.


-- Comprobamos si hay algún e-mail que no cumple formato

SELECT customer_email FROM dim_customer
WHERE customer_email NOT LIKE '%@%.%';
-- Aparece un email incorrecto: paulo.saram@gmail Completaremos con .com

-- Ver los distintos nombres en cada columna

SELECT DISTINCT 
	customer_name COLLATE utf8mb4_bin n, -- Se utiliza COLLATE utf8mb4_bin para que diferencia entre mayúsculas y minúsculas, ya que MySQL no es "case sensitive".
	customer_email COLLATE utf8mb4_bin e,
    customer_city COLLATE utf8mb4_bin c,
    customer_country COLLATE utf8mb4_bin co
FROM dim_customer
ORDER BY n;  -- Aquí también hice ORDER BY e, c y co para ver todo mejor

-- Para que quede homogéneo, aunque no es necesario, cambiaremos Perez por Pérez. Tendremos un nombre duplicado, pero es un ID diferente.
-- También cambiaremos ESPAÑA por España


/*===============================
	LIMPIEZA DE TABLA dim_customer
=================================*/

-- Eliminar customer_id=6
-- Cambiar Perez por Pérez en customer_name
-- Cambiar ESPAÑA a España en customer_country


-- Antes de limpiar, voy a crear una copia de la tabla original, para no modificar la original

DROP TABLE IF EXISTS dim_customer_clean;
CREATE TABLE dim_customer_clean AS
SELECT *
FROM dim_customer;

SELECT * FROM dim_customer_clean; -- Compruebo que la ha creado

-- Eliminar customer_id=6

DELETE FROM dim_customer_clean
WHERE customer_id = 6;

SELECT * FROM dim_customer_clean;

-- Actualizar email 
UPDATE dim_customer_clean
SET customer_email = 'paulo.saram@gmail.com'
WHERE customer_email = 'paulo.saram@gmail';

SELECT * FROM dim_customer_clean;

-- Cambiar Perez por Pérez en customer_name

UPDATE dim_customer_clean
SET customer_name = REPLACE(customer_name, 'Perez', 'Pérez')
WHERE customer_name LIKE '%Perez';

SELECT * FROM dim_customer_clean;

-- Cambiar ESPAÑA a España en customer_country

UPDATE dim_customer_clean
SET customer_country = 'España'
WHERE customer_country = 'ESPAÑA';

SELECT * FROM dim_customer_clean;

/*===============================
	TABLA dim_date
=================================*/
-- Ver la tabla completa
SELECT * FROM dim_date;

-- Ver cuántas filas tiene la tabla 
SELECT COUNT(*) FROM dim_date; -- Tenemos 1612 filas en esta tabla

-- Ver cuantos ID distintos tenemos, por si hay duplicados, sabiendo el número de filas
SELECT COUNT(distinct date_id) FROM dim_date;   -- Tenemos 1612 ID distintos, por lo que no hay duplicado en date_id

-- Ver filas duplicadas con distinto id
SELECT COUNT(distinct full_date) FROM dim_date;  -- Tenemos 1612 distintos, por lo que no hay duplicados ni nulos

-- Esta tabla está limpia. De todas formas la renombramos a _clean para mantener la homogeneidad

DROP TABLE IF EXISTS dim_date_clean;
CREATE TABLE dim_date_clean AS
SELECT *
FROM dim_date;

SELECT * FROM dim_date_clean; -- Compruebo que la ha creado

/*===============================
	TABLA dim_destination
=================================*/
-- Ver la tabla completa
SELECT * FROM dim_destination;

-- Ver cuántas filas tiene la tabla (en este caso se podría ver con la query anterior)
SELECT COUNT(*) FROM dim_destination; -- Tenemos 10 filas en esta tabla

-- Ver cuantos ID distintos tenemos, por si hay duplicados, sabiendo el número de filas
SELECT COUNT(distinct destination_id) FROM dim_destination;   -- Tenemos 10 ID distintos, por lo que no hay duplicado en carrier_id

-- Ver filas duplicadas con distinto id
SELECT COUNT(distinct city, country, region) FROM dim_destination;  -- Tenemos 6 distintos, por lo que hay 4 posibles duplicados o nulos

-- Ver los posibles duplicados
SELECT distinct city, country, region FROM dim_destination; -- Tenemos 8 distintos, dos de ellos son un null, por eso no aparece en el COUNT anterior

-- Seleccionar los duplicados
SELECT city, country, region, COUNT(*) 
FROM dim_destination
GROUP BY city, country, region
HAVING COUNT(*) > 1;

-- Vemos que hay 2 duplicados: Madrid, España, Centro y Barcelona, España, Cataluña
-- Vamos a ver qué ID tienen para eliminarlos

SELECT * FROM dim_destination
WHERE city IN ('Madrid','Barcelona');

-- Eliminaremos destination_id 6 y 10
-- IMPORTANTE!! En la tabla fact_shipments, tendremos que sustituir el destination_id 6 por 2 y 10 por 1.


-- Ya habíamos detectado los nulos, pero los podenos volver a ver con la siguiente query
SELECT * FROM dim_destination
WHERE city IS NULL
   OR country IS NULL
   OR region IS NULL;

-- Vemos que hay un null en country para city= Valencia. Lo actualizaremos a España
-- Vemos que hay un null en región para city= Lisboa. Lo actualizaremos a Lisboa


-- Ver los distintos nombres en cada columna

SELECT DISTINCT 
	city COLLATE utf8mb4_bin, -- Se utiliza COLLATE utf8mb4_bin para que diferencia entre mayúsculas y minúsculas, ya que MySQL no es "case sensitive".
	country COLLATE utf8mb4_bin,
    region COLLATE utf8mb4_bin
FROM dim_destination
ORDER BY city COLLATE utf8mb4_bin;  -- Aquí también hice ORDER BY e, c y co para ver todo mejor

-- Para que quede homogéneo, aunque no es necesario, cambiaremos ESPAÑA por España en country. 


/*====================================
	LIMPIEZA DE TABLA dim_destination
======================================*/

-- Eliminar destination_id 6 y 10
-- Actualizar  para city= Valencia country= España. Comprobaremos si estamos creando nuevos duplicados que tendremos que eliminar
-- Actualizar  para city= Lisboa region= Lisboa. Comprobaremos si estamos creando nuevos duplicados que tendremos que eliminar


-- Antes de limpiar, voy a crear una copia de la tabla original, para no modificar la original

DROP TABLE IF EXISTS dim_destination_clean;
CREATE TABLE dim_destination_clean AS
SELECT *
FROM dim_destination;

SELECT * FROM dim_customer_clean; -- Compruebo que la ha creado

-- Eliminar destination_id 6 y 10

DELETE FROM dim_destination_clean
WHERE destination_id IN (6, 10);

SELECT * FROM dim_destination_clean;


-- Actualizar  para city= Valencia country= España. Comprobaremos si estamos creando nuevos duplicados que tendremos que eliminar

UPDATE dim_destination_clean
SET country = 'España'
WHERE destination_ID = 7;

SELECT * FROM dim_destination_clean;

-- Actualizar  para city= Lisboa region= Lisboa. Comprobaremos si estamos creando nuevos duplicados que tendremos que eliminar

UPDATE dim_destination_clean
SET region = 'Lisboa'
WHERE destination_ID = 8;

SELECT * FROM dim_destination_clean
ORDER BY city;  
-- Con las actualizaciones de los nulos tenemos dos nuevos duplicados. destination id=8 y destination_id=7

-- Eliminamos esos dos id y recordamos que en la tabla fact, tendremos que cambiar destination id=8 a 4 y destination_id=7 a 3

DELETE FROM dim_destination_clean
WHERE destination_id IN (7, 8);

SELECT * FROM dim_destination_clean;

/*===============================
	TABLA fact_shipments
=================================*/
-- Ver la tabla completa
SELECT * FROM fact_shipments;

-- Ver cuántas filas tiene la tabla (en este caso se podría ver con la query anterior)
SELECT COUNT(*) FROM fact_shipments; -- Tenemos 3303 filas en esta tabla

-- Ver cuantos ID distintos tenemos, por si hay duplicados, sabiendo el número de filas
SELECT COUNT(distinct shipment_id) FROM fact_shipments;   -- Tenemos 3303 ID distintos, por lo que no hay duplicado en shipment_id


/*===================================================
	LIMPIEZA/ACTUALIZACION DE TABLA fact_shipments
=====================================================*/

-- Tenemos que modificar en esta tabla los id que hemos eliminado en las tablas de dimensiones
	-- En la tabla fact_shipments, tendremos que sustituir los carrier_id 5 por 1 y 8 por 4
	-- En la tabla fact_shipments, tendremos que sustituir los customer_id 6 por 1
	-- En la tabla fact_shipments, tendremos que sustituir los destination_id 6 por 2 y 10 por 1.
	-- En la tabla fact_shipments, tendremos que sustituir los destination_id 7 por 3 y 8 por 4.


-- Antes de limpiar, voy a crear una copia de la tabla original, para no modificar la original

DROP TABLE IF EXISTS fact_shipments_clean;
CREATE TABLE fact_shipments_clean AS
SELECT *
FROM fact_shipments;

SELECT * FROM fact_shipments_clean; -- Compruebo que la ha creado

UPDATE fact_shipments_clean
SET carrier_id = 1
WHERE carrier_id = 5;

UPDATE fact_shipments_clean
SET carrier_id = 4
WHERE carrier_id = 8;

UPDATE fact_shipments_clean
SET customer_id = 1
WHERE customer_id = 6;

UPDATE fact_shipments_clean
SET destination_id = 2
WHERE destination_id = 6;

UPDATE fact_shipments_clean
SET destination_id = 1
WHERE destination_id = 10;

UPDATE fact_shipments_clean
SET destination_id = 3
WHERE destination_id = 7;

UPDATE fact_shipments_clean
SET destination_id = 4
WHERE destination_id = 8;

SELECT * FROM fact_shipments_clean;


-- Ahora necesito vincular las tablas con las claves primary key y foreign key

ALTER TABLE dim_carrier_clean
ADD PRIMARY KEY (carrier_id);

ALTER TABLE dim_customer_clean
ADD PRIMARY KEY (customer_id);

ALTER TABLE dim_date_clean
ADD PRIMARY KEY (date_id);

ALTER TABLE dim_destination_clean
ADD PRIMARY KEY (destination_id);

ALTER TABLE fact_shipments_clean
ADD PRIMARY KEY (shipment_id);

ALTER TABLE fact_shipments_clean
ADD CONSTRAINT fk_shipments_carrier_clean
FOREIGN KEY (carrier_id)
REFERENCES dim_carrier_clean(carrier_id);

ALTER TABLE fact_shipments_clean
ADD CONSTRAINT fk_shipments_customer_clean
FOREIGN KEY (customer_id)
REFERENCES dim_customer_clean(customer_id);

ALTER TABLE fact_shipments_clean
ADD CONSTRAINT fk_shipments_date_clean
FOREIGN KEY (date_id)
REFERENCES dim_date_clean(date_id);

ALTER TABLE fact_shipments_clean
ADD CONSTRAINT fk_shipments_destination_clean
FOREIGN KEY (destination_id)
REFERENCES dim_destination_clean(destination_id);


