-- ===================================
-- PRIMÁRNÍ TABULKA
-- ===================================
-- 
CREATE TABLE t_denys_lopanskyi_project_SQL_primary_final AS
SELECT 
    mzdy.rok,
    mzdy.odvětví,
    mzdy.prumerna_mzda,
    ceny.kategorie_potraviny,
    ceny.jednotka,
    ceny.prumerna_cena
FROM (
    SELECT 
        cp.payroll_year AS rok,
        cpib.name AS odvětví,
        ROUND(AVG(cp.value)::numeric, 2) AS prumerna_mzda
    FROM czechia_payroll cp
    JOIN czechia_payroll_industry_branch cpib 
        ON cp.industry_branch_code = cpib.code
    WHERE cp.value_type_code = 5958 
        AND cp.payroll_year BETWEEN 2006 AND 2018
    GROUP BY cp.payroll_year, cpib.name
) mzdy
JOIN (
    SELECT 
        EXTRACT(YEAR FROM p.date_from) AS rok,
        cpc.name AS kategorie_potraviny,
        cpc.price_unit AS jednotka,
        ROUND(AVG(p.value)::numeric, 2) AS prumerna_cena
    FROM czechia_price p
    JOIN czechia_price_category cpc 
        ON p.category_code = cpc.code
    WHERE EXTRACT(YEAR FROM p.date_from) BETWEEN 2006 AND 2018
    GROUP BY EXTRACT(YEAR FROM p.date_from), cpc.name, cpc.price_unit
) ceny ON mzdy.rok = ceny.rok
ORDER BY mzdy.rok, mzdy.odvětví, ceny.kategorie_potraviny;

-- ===================================
-- SEKUNDÁRNÍ TABULKA
-- ===================================
-- 
CREATE TABLE t_denys_lopanskyi_project_SQL_secondary_final AS
SELECT
    e.country,
    e.year,
    e.gdp,
    e.gini,
    e.population
FROM economies e
JOIN countries c
    ON e.country = c.country
WHERE c.continent = 'Europe'
    AND e.year BETWEEN 2006 AND 2018
ORDER BY
    e.country,
    e.year;

-- ===================================
-- OTÁZKA 1
-- ===================================
--  
SELECT
  odvětví,
  rok,
  prumerna_mzda,
  LAG(prumerna_mzda) OVER (PARTITION BY odvětví ORDER BY rok) AS mzda_predchozi_rok,
  ROUND(
      (prumerna_mzda - LAG(prumerna_mzda) OVER (PARTITION BY odvětví ORDER BY rok))
      / LAG(prumerna_mzda) OVER (PARTITION BY odvětví ORDER BY rok) * 100
  , 2) AS zmena_procent
FROM (
  SELECT rok, odvětví, AVG(prumerna_mzda) AS prumerna_mzda
  FROM t_denys_lopanskyi_project_sql_primary_final
  GROUP BY rok, odvětví
) sub
ORDER BY odvětví, rok;

-- ===================================
-- OTÁZKA 2
-- ===================================
--    
SELECT 
    mzdy.rok,
    mzdy.prumerna_mzda_cr,
    ceny.kategorie_potraviny,
    ceny.prumerna_cena_cr,
    ROUND((mzdy.prumerna_mzda_cr / ceny.prumerna_cena_cr)::numeric, 2) AS pocet_kusu
FROM (
    SELECT 
        rok,
        AVG(prumerna_mzda) AS prumerna_mzda_cr
    FROM t_denys_lopanskyi_project_sql_primary_final
    WHERE rok IN (2006, 2018)
    GROUP BY rok
) mzdy
JOIN (
    SELECT 
        rok,
        kategorie_potraviny,
        AVG(prumerna_cena) AS prumerna_cena_cr
    FROM t_denys_lopanskyi_project_sql_primary_final
    WHERE rok IN (2006, 2018)
        AND kategorie_potraviny IN ('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
    GROUP BY rok, kategorie_potraviny
) ceny ON mzdy.rok = ceny.rok
ORDER BY ceny.kategorie_potraviny, mzdy.rok;

-- ===================================
-- OTÁZKA 3
-- ===================================
-- 
SELECT
    kategorie_potraviny,
    ROUND(AVG(zmena_procent)::numeric, 2) AS prumerna_mezirocni_zmena
FROM (
    SELECT
        kategorie_potraviny,
        rok,
        prumerna_cena_cr,
        ROUND((
            (prumerna_cena_cr / LAG(prumerna_cena_cr) OVER (PARTITION BY kategorie_potraviny ORDER BY rok) * 100) - 100
        )::numeric, 2) AS zmena_procent
    FROM (
        SELECT rok, kategorie_potraviny, AVG(prumerna_cena) AS prumerna_cena_cr
        FROM t_denys_lopanskyi_project_sql_primary_final
        GROUP BY rok, kategorie_potraviny
    ) sub
) zmeny
GROUP BY kategorie_potraviny
ORDER BY prumerna_mezirocni_zmena ASC;

-- ===================================
-- OTÁZKA 4
-- ===================================
-- 
SELECT
    mzdy.rok,
    mzdy.prumerna_mezirocni_zmena_mzdy,
    ceny.prumerna_mezirocni_zmena_cen,
    ROUND((ceny.prumerna_mezirocni_zmena_cen - mzdy.prumerna_mezirocni_zmena_mzdy)::numeric, 2) AS rozdil
FROM (
    SELECT
        rok,
        ROUND(AVG(zmena_procent)::numeric, 2) AS prumerna_mezirocni_zmena_mzdy
    FROM (
        SELECT
            rok,
            odvětví,
            prumerna_mzda,
            ROUND((
                (prumerna_mzda / LAG(prumerna_mzda) OVER (PARTITION BY odvětví ORDER BY rok) * 100) - 100
            )::numeric, 2) AS zmena_procent
        FROM (
            SELECT rok, odvětví, AVG(prumerna_mzda) AS prumerna_mzda
            FROM t_denys_lopanskyi_project_sql_primary_final
            GROUP BY rok, odvětví
        ) sub
    ) zmeny
    GROUP BY rok
) mzdy
JOIN (
    SELECT
        rok,
        ROUND(AVG(zmena_procent)::numeric, 2) AS prumerna_mezirocni_zmena_cen
    FROM (
        SELECT
            rok,
            kategorie_potraviny,
            prumerna_cena,
            ROUND((
                (prumerna_cena / LAG(prumerna_cena) OVER (PARTITION BY kategorie_potraviny ORDER BY rok) * 100) - 100
            )::numeric, 2) AS zmena_procent
        FROM (
            SELECT rok, kategorie_potraviny, AVG(prumerna_cena) AS prumerna_cena
            FROM t_denys_lopanskyi_project_sql_primary_final
            GROUP BY rok, kategorie_potraviny
        ) sub
    ) zmeny
    GROUP BY rok
) ceny ON mzdy.rok = ceny.rok
WHERE (ceny.prumerna_mezirocni_zmena_cen - mzdy.prumerna_mezirocni_zmena_mzdy) > 10
ORDER BY mzdy.rok;

-- ===================================
-- OTÁZKA 5
-- ===================================
-- 
SELECT
    mzdy.rok,
    mzdy.prumerna_mezirocni_zmena_mzdy,
    ceny.prumerna_mezirocni_zmena_cen,
    hdp.zmena_hdp
FROM (
    SELECT
        rok,
        ROUND(AVG(zmena_procent)::numeric, 2) AS prumerna_mezirocni_zmena_mzdy
    FROM (
        SELECT
            rok,
            odvětví,
            prumerna_mzda,
            ROUND((
                (prumerna_mzda / LAG(prumerna_mzda) OVER (PARTITION BY odvětví ORDER BY rok) * 100) - 100
            )::numeric, 2) AS zmena_procent
        FROM (
            SELECT rok, odvětví, AVG(prumerna_mzda) AS prumerna_mzda
            FROM t_denys_lopanskyi_project_sql_primary_final
            GROUP BY rok, odvětví
        ) sub
    ) zmeny
    GROUP BY rok
) mzdy
JOIN (
    SELECT
        rok,
        ROUND(AVG(zmena_procent)::numeric, 2) AS prumerna_mezirocni_zmena_cen
    FROM (
        SELECT
            rok,
            kategorie_potraviny,
            prumerna_cena,
            ROUND((
                (prumerna_cena / LAG(prumerna_cena) OVER (PARTITION BY kategorie_potraviny ORDER BY rok) * 100) - 100
            )::numeric, 2) AS zmena_procent
        FROM (
            SELECT rok, kategorie_potraviny, AVG(prumerna_cena) AS prumerna_cena
            FROM t_denys_lopanskyi_project_sql_primary_final
            GROUP BY rok, kategorie_potraviny
        ) sub
    ) zmeny
    GROUP BY rok
) ceny ON mzdy.rok = ceny.rok
JOIN (
    SELECT
        year AS rok,
        ROUND((
            (gdp / LAG(gdp) OVER (ORDER BY year) * 100) - 100
        )::numeric, 2) AS zmena_hdp
    FROM t_denys_lopanskyi_project_sql_secondary_final
    WHERE country = 'Czech Republic'
) hdp ON mzdy.rok = hdp.rok
ORDER BY mzdy.rok ASC;
