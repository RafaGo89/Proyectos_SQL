-- Data Cleaning

-- Creamos una base de datos para almacenar los datos
CREATE DATABASE world_layoffs;

-- Seleccionamos la base de datos
USE world_layoffs;

-- Visualizamos los datos de la tabla exportada
SELECT *
FROM layoffs;

-- Creamos una tabla 'en proceso' con la misma estructura que la original
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Copiamos los datos de la tabla original a la nueva tabla
INSERT layoffs_staging
SELECT *
FROM layoffs;

SELECT *
FROM layoffs_staging;

-- 1. Quitar duplicados

-- Obtenemos un número de fila única por todos los campos de las columnas, 
-- para buscar si hay filas repetidas
SELECT *,
       ROW_NUMBER() OVER(
		                   PARTITION BY company, location, industry, total_laid_off, 
								 percentage_laid_off, `date`, stage, country, 
								 funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Creamos una CTE con la querie que acabamos de crear
WITH duplicate_cte AS
(
	SELECT *,
	       ROW_NUMBER() OVER(
			                   PARTITION BY company, location, industry, total_laid_off, 
								    percentage_laid_off, `date`, stage, country, 
								    funds_raised_millions) AS row_num
	FROM layoffs_staging
)
-- Realizamos una querie para encontrar si hay algún número de fila que
-- se repite más de una vez
SELECT * 
FROM duplicate_cte
WHERE row_num > 1;

-- Buscamos por medio del nombre de una compañía para verificar que se repita la fila
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- Para poder eliminar duplicados, creamos una tabla en base a la querie
-- para encontrar los duplicados
CREATE TABLE layoffs_staging2 AS
	SELECT *,
		       ROW_NUMBER() OVER(
				                   PARTITION BY company, location, industry, total_laid_off, 
									    percentage_laid_off, `date`, stage, country, 
									    funds_raised_millions) AS row_num
		FROM layoffs_staging;

-- Modificamos el tipo de dato de la columna row_number
ALTER TABLE layoffs_staging2
MODIFY COLUMN row_num INT;

DESCRIBE layoffs_staging2;

-- Identificamos los duplicados
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Eliminamos los duplicados
DELETE FROM layoffs_staging2
WHERE row_num > 1;

-- Verificamos que los duplicados ya no existen
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- 2. Estandarizar los datos

-- Quitamos los espacios en blanco a los lados de la columna company
SELECT company,
       TRIM(company)
FROM layoffs_staging2;

-- Aplicamos los cambios en la tabla
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Verficamos los cambios
SELECT company,
       TRIM(company)
FROM layoffs_staging2;

-- Verificamos los valore en la columna industry
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- Nos fijamos en los valores de crypto ya que están divididos y hay que unificarlos
SELECT DISTINCT industry
FROM layoffs_staging2
WHERE industry LIKE 'crypto%';

-- Unificamos los valores
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Verificamos el cambio
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'crypto%';

-- Verificamos la columna de country
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- Encontramos que 'United states' está repetido al tener un punto al final
SELECT DISTINCT country
FROM layoffs_staging2
WHERE country LIKE 'United states%';

-- Usando TRAILING junto con TRIM, podemos especificar que queremos
-- borrar los puntos '.' de una determinada columna
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
WHERE country LIKE 'United states%';

-- Aplicamos el cambio en la tabla
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United states%';

-- Verificamos que el cambio se aplicó
SELECT DISTINCT country
FROM layoffs_staging2
WHERE country LIKE 'United states%';

-- Si nos fijamos en la columna date, su tipo de dato está mal,
-- es varchar y debe de ser de fecha
DESCRIBE layoffs_staging2;

-- Visualizamos como quedaría la fecha con un formato de fecha adecuado
SELECT `date`,
       STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

-- Aplicamos el cambio
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Verificamos que el cambio se haya aplicado
SELECT `date`
FROM layoffs_staging2;

-- Cambiamos el tipo de dato de la columna
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Verificamos el nuevo tipo de datos
DESCRIBE layoffs_staging2;

-- 3. Valores nulos o valores en blanco

-- Verificamos los valores de industry que sean NULL o en blanco
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry  = '';

-- Una de las compañías aparece más de una vez y un registro tiene industry
-- y el otro no
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- Establecemos los valores en blanco como NULL
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Hacemos un inner join para encontrar si hay registros de esas compañías
-- que sí tengan un valor de industry como tal 
SELECT *
FROM layoffs_staging2 AS t1
INNER JOIN layoffs_staging2 AS t2
	ON t1.company = t2.company
	
WHERE (t1.industry IS NULL)
      AND (t2.industry IS NOT NULL);

-- Aplicamos la actualización
UPDATE layoffs_staging2 AS t1
INNER JOIN layoffs_staging2 AS T2
	ON t1.company = t2.company
	
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL)
      AND (t2.industry IS NOT NULL);
      
-- Verificamos que ya no haya valores NULL o en blanco,
-- ahora solo aparece un solo registro que no tiene industry
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry  = '';

-- Verificamos que la empresa 'Airbnb' ahora sí ya tiene industry
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- 4. Quitar cualquier columna o fila irrelevante

-- Encontramos los registros que no cuenten con 'total_laid_off' ni con
-- 'percentage_laid_off'
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
      AND percentage_laid_off IS NULL;
      
-- ELiminamos esas filas ya que no aportan información útil
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
      AND percentage_laid_off IS NULL;

-- Quitamos la columna 'rowum' que creamos al inicio
ALTER TABLE layoffs_staging2
DROP COLUMN `row_num`; 

-- Cambiamos los tipos de dato de as siguientes columnas
DESCRIBE layoffs_staging2;

-- Cambiamos total_laid_off a SMALLINT
ALTER TABLE layoffs_staging2
MODIFY COLUMN total_laid_off SMALLINT;

-- Cambiamos total_laid_off a DECIMAL
ALTER TABLE layoffs_staging2
MODIFY COLUMN percentage_laid_off DECIMAL(4,3);

-- Y finalmente la tabla quedó lista
SELECT *
FROM layoffs_staging2;