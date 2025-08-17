-- Proyecto de limpieza de datos en SQL
-- By: Rafael Rodríguez Gómez

CREATE DATABASE IF NOT EXISTS clean;

-- Desactivamos el modo seguro
SET sql_safe_updates = 0;

USE clean;

-- Obtenemos una muestra de los datos importados
SELECT *
FROM limpieza
LIMIT 10;

-- Creamos un procedimiento almacenado para acortar
-- la revisión de datos
DELIMITER //
CREATE PROCEDURE limp()
BEGIN
	SELECT *
	FROM limpieza;
END //

DELIMITER ;

-- Llamamos al procedimiento
CALL limp();

-- Cambiamos el nombre y ajustamos el tipo de la columna id empleado
ALTER TABLE limpieza
CHANGE COLUMN `ï»¿Id?empleado`
               Id_emp VARCHAR(20) NULL;
         
-- Cambiamos el nombre y ajustamos el tipo de la columna génerop
ALTER TABLE limpieza
CHANGE COLUMN `gÃ©nero`
               gender VARCHAR(20) NULL;
               
-- Encontrar valores duplicados
SELECT id_emp,
	   COUNT(*) AS valores_duplicados
FROM limpieza
GROUP BY id_emp
HAVING valores_duplicados > 1;

-- Obtenemos la cantidad de valores duplicados
SELECT COUNT(*) AS cantidad_duplicados
FROM 
      (SELECT id_emp,
	   COUNT(*) AS valores_duplicados
	  FROM limpieza
	  GROUP BY id_emp
	  HAVING valores_duplicados > 1) AS subquerie;
      
-- Ahora eliminaremos los valores duplicados
-- Primero renonbramos la tabla
RENAME TABLE limpieza TO con_duplicados;

-- Creamos una tabla temporal para guardar la tabla con valores únicos
CREATE TEMPORARY TABLE temp_limpieza AS
	SELECT DISTINCT *
    FROM con_duplicados;
    
-- Contamos la cantidad de filas de nuestra tabla original
SELECT 
    COUNT(*) AS original
FROM
    con_duplicados;

-- Contamos la cantidad de filas de nuestra temporal con valores únicos
SELECT COUNT(*) AS temporal
FROM temp_limpieza;

-- Creamos una tabla normal con solo los valores únicos
CREATE TABLE limpieza AS
	SELECT *
    FROM temp_limpieza;

-- Mostramos el resultado usando el procedimiento almacenado    
CALL limp();

-- Eliminamos la tabla con valores duplicados
DROP TABLE con_duplicados;

-- Renombramos más columnas que están érroneas
ALTER TABLE limpieza
CHANGE COLUMN Apellido 
              Last_name VARCHAR(50) NULL;
              
ALTER TABLE limpieza
CHANGE COLUMN star_date 
              Start_date VARCHAR(50) NULL;

CALL limp();

-- Obtenemos los nombres que estén entre espacios en blanco
SELECT name
FROM limpieza
WHERE length(name) - length(TRIM(name)) > 0;

-- Así deben de quedar los nombres después del tratamiento
SELECT name,  
       TRIM(name) AS name_trimmed
FROM limpieza
WHERE length(name) - length(TRIM(name)) > 0;

-- Hacemos los cambios en los nombres
UPDATE limpieza
SET name = TRIM(name)
WHERE length(name) - length(TRIM(name)) > 0;

CALL limp();

-- Hacemos lo mismo para el apellido
-- Obtenemos los apellidos que estén entre espacios en blanco
SELECT last_name
FROM limpieza
WHERE length(last_name) - length(TRIM(last_name)) > 0;

-- Así deben de quedar los apellidos después del tratamiento
SELECT last_name,  
       TRIM(last_name) AS last_name_trimmed
FROM limpieza
WHERE length(last_name) - length(TRIM(last_name)) > 0;

-- Hacemos los cambios en los apellidos
UPDATE limpieza
SET last_name = TRIM(last_name)
WHERE length(last_name) - length(TRIM(last_name)) > 0;

CALL limp();

-- Introducimos varios espacios en blanco en la columna área
UPDATE limpieza
SET area = REPLACE(area, ' ', '     ');

CALL limp();

-- Buscamos las filas que tengan 2 o más espacios consecutivos
SELECT area
FROM limpieza
WHERE area REGEXP '\\s{2,}';

-- Hacemos un ensayo de como quedaría la columna ya formateada
SELECT area,
       TRIM(regexp_replace(area, '\\s{2,}', ' ')) AS ensayo
FROM limpieza;

-- Actualizamos los valores de esa columna para que solo tengan un espacio en blanco
UPDATE limpieza
SET area = TRIM(regexp_replace(area, '\\s{2,}', ' '));

CALL limp();

-- Cambiar valores de género a inglés, haciendo el ensayo primero
SELECT gender,
	   CASE
	        WHEN gender = 'hombre' THEN 'male'
            WHEN gender = 'mujer' THEN 'female'
            ELSE 'other'
	   END AS gender_english
FROM limpieza;

-- Ahora hacemos los cambios en la tabla
UPDATE limpieza
SET gender = CASE
	        WHEN gender = 'hombre' THEN 'male'
            WHEN gender = 'mujer' THEN 'female'
            ELSE 'other'
            END;
            
CALL limp();

-- Verificamos el tipo de dato de la columna 'type'
DESCRIBE limpieza;

-- Al ser 'int', lo cambiaremos a tipo texto para poder usar CASE
ALTER TABLE limpieza
			MODIFY COLUMN type TEXT;
            
DESCRIBE limpieza;

-- Modificamos type, que va de acuerdo al tipo de contrato
SELECT type,
       CASE
           WHEN type = '1' THEN 'Remote'
           WHEN type = '0' THEN 'Hybrid'
		   ELSE 'Other'
	   END AS type_changed
FROM limpieza;

-- Ahora modificamos la columna
UPDATE limpieza
SET type = CASE
           WHEN type = '1' THEN 'Remote'
           WHEN type = '0' THEN 'Hybrid'
		   ELSE 'Other'
	   END;
       
CALL limp();

-- Ahora modificaremos el salario para que sea un número, eliminado comas y signos de pesos,
-- quitando espacios en blanco y casteando a un valor DECIMAL
SELECT salary,
	   CAST(TRIM(REPLACE(REPLACE(salary,'$',''),',','')) AS DECIMAL(15, 2)) AS salary_formatted
FROM limpieza;

-- Aplicamos el cambio a la tabla
UPDATE limpieza
SET salary = CAST(TRIM(REPLACE(REPLACE(salary,'$',''),',','')) AS DECIMAL(15, 2));

-- Cambiamos la columna al tipo adecuado
ALTER TABLE limpieza
			MODIFY COLUMN salary DECIMAL(15,2);

CALL limp();

-- A la siguiente columna, le daremos un formato de fecha adecuado
SELECT birth_date
FROM limpieza;

-- Hacemos un ensayo de como quedarán las fechas formateadas
SELECT birth_date,
       CASE
	        WHEN birth_date LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(birth_date, '%m/%d/%Y'), '%Y-%m-%d')
            WHEN birth_date LIKE '%-%' THEN DATE_FORMAT(STR_TO_DATE(birth_date, '%m-%d-%Y'), '%Y-%m-%d') -- Por si encontramos la fecha con otro separador
            ELSE NULL
		END AS new_birth_date
FROM limpieza;

-- Ahora actualizamos la columna
UPDATE limpieza
SET birth_date = 
           CASE
				WHEN birth_date LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(birth_date, '%m/%d/%Y'), '%Y-%m-%d')
				WHEN birth_date LIKE '%-%' THEN DATE_FORMAT(STR_TO_DATE(birth_date, '%m-%d-%Y'), '%Y-%m-%d')
				ELSE NULL
		    END;
            
CALL limp();

-- Modificamos el tipo de datos de la columna birth_date
ALTER TABLE limpieza
             MODIFY COLUMN birth_date DATE;

-- Verificamos que se haya realizado el cambio
DESCRIBE limpieza;

-- A la siguiente columna, le daremos un formato de fecha adecuado
SELECT start_date
FROM limpieza;

-- Hacemos un ensayo de como quedarán las fechas formateadas
SELECT start_date,
       CASE
	        WHEN start_date LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(start_date, '%m/%d/%Y'), '%Y-%m-%d')
            WHEN start_date LIKE '%-%' THEN DATE_FORMAT(STR_TO_DATE(start_date, '%m-%d-%Y'), '%Y-%m-%d') -- Por si encontramos la fecha con otro separador
            ELSE NULL
		END AS new_start_date
FROM limpieza;

-- Ahora actualizamos la columna
UPDATE limpieza
SET start_date = 
           CASE
				WHEN start_date LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(start_date, '%m/%d/%Y'), '%Y-%m-%d')
				WHEN start_date LIKE '%-%' THEN DATE_FORMAT(STR_TO_DATE(start_date, '%m-%d-%Y'), '%Y-%m-%d') -- Por si encontramos la fecha con otro separador
				ELSE NULL
		    END;
            
CALL limp();
            
-- Modificamos el tipo de datos de la columna start_date
ALTER TABLE limpieza
             MODIFY COLUMN start_date DATE;

-- Verificamos que se haya realizado el cambio
DESCRIBE limpieza;

-- Ahora modificaremos la columna finish_date de diferentes formas
SELECT finish_date
FROM limpieza;

-- Primero convertimos la columna a un objeto de fecha (timestamp)
SELECT finish_date,
	   STR_TO_DATE(finish_date, '%Y-%m-%d %H:%i:%s') AS new_finish_date
FROM limpieza;

-- Pasamos la fecha a formato solo años, meses y días
SELECT finish_date,
	   DATE_FORMAT(STR_TO_DATE(finish_date, '%Y-%m-%d %H:%i:%s'), '%Y-%m-%d') AS new_finish_date
FROM limpieza;

-- Separar solo la fecha de manera directo, resultado como el anterior
SELECT finish_date,
	   STR_TO_DATE(finish_date,'%Y-%m-%d') AS new_finish_date
FROM limpieza;

-- Obtener solo la hora
SELECT finish_date,
	   DATE_FORMAT(finish_date, '%H:%i:%s') AS hour_stamp
FROM limpieza;

-- Diviendo todos los elementos de la hora
SELECT finish_date,
	   DATE_FORMAT(finish_date, '%H') AS Hora,
       DATE_FORMAT(finish_date, '%i') AS Minutos,
       DATE_FORMAT(finish_date, '%s') AS segundos,
       DATE_FORMAT(finish_date, '%H:%i:%s') AS hour_stamp
FROM limpieza;

 /* Diferencia entre timestamp y datetime
-- timestamp (YYYY-MM-DD HH:MM:SS) - desde: 01 enero 1970 a las 00:00:00 UTC , hasta milesimas de segundo
-- datetime desde año 1000 a 9999 - no tiene en cuenta la zona horaria , hasta segundos. */

-- Creamos una columna de respaldo ahora que trabajamos con estas columnas
ALTER TABLE	limpieza
ADD COLUMN date_backup TEXT;

-- Copiamos los datos de la coumna finish date a la columna de respaldo
UPDATE limpieza
SET date_backup =  finish_date;

CALL limp();

-- Convertimos a fecha la columna finish_date
UPDATE limpieza
SET finish_date = STR_TO_DATE(finish_date, '%Y-%m-%d %H:%i:%s UTC')
WHERE finish_date <> '';

-- Agregamos 2 columnas nuevas para separar fecha y hora
ALTER TABLE limpieza
	ADD COLUMN fecha DATE,
    ADD COLUMN hora TIME;
    
-- Copiamos la fecha y hora a las 2 respectivas columna
UPDATE limpieza
SET fecha = finish_date,
    hora = finish_date
WHERE finish_date IS NOT NULL AND finish_date <> '';

-- Ponemos valores nules donde haya espacios en blanco
UPDATE limpieza
SET finish_date = NULL
WHERE finish_date = '';

CALL limp();

-- Pusimos valores nulos anteriormente, para poder establecer la columna como tipo DATETIME
ALTER TABLE limpieza
MODIFY COLUMN finish_date DATETIME;

DESCRIBE limpieza;

-- Calculamos la edad a la que ingresaron los empleados a la empresa
SELECT birth_date,
       start_date,
       TIMESTAMPDIFF(YEAR, birth_date, start_date) AS edad_de_ingreso
FROM limpieza;
       

-- Calcular edad de empleados
-- Añadimos una columna para albergar este valor
ALTER TABLE limpieza
ADD COLUMN age INT;

-- Ensayo para calcular la fecha
SELECT birth_date,
       TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) AS age
FROM limpieza;

-- Actualizamos y establecemos la edad
UPDATE limpieza
SET age = TIMESTAMPDIFF(YEAR, birth_date, CURDATE());

CALL limp();

-- Creación de un correo electrónico con base a columnas que tenemos
-- Ensayo de como quedará la columna
SELECT CONCAT(SUBSTRING_INDEX(name, ' ', 1), '_', SUBSTRING(last_name, 1, 2), '.', SUBSTRING(type, 1, 1),
             '@consulting.com') AS email
FROM limpieza;

-- Creamos y añadimos la columna para el email
ALTER TABLE limpieza
ADD COLUMN email VARCHAR(100);

CALL limp();

-- Rellenamos la columna de email
UPDATE limpieza
SET email = CONCAT(SUBSTRING_INDEX(name, ' ', 1), '_', SUBSTRING(last_name, 1, 2), '.', SUBSTRING(type, 1, 1),
             '@consulting.com');
             
CALL limp();

-- Una consulta que incluya los datos a exportar con algunos filtros
SELECT id_emp,
       name,
       last_name,
       age,
       gender,
       area,
       salary,
       email,
       finish_date
FROM limpieza

WHERE finish_date <= CURDATE()
OR finish_date IS NULL

ORDER BY area, name;

SELECT area,
       COUNT(*) AS cantidad_de_empleados
FROM limpieza
GROUP BY area
ORDER BY cantidad_de_empleados DESC;