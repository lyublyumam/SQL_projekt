# SQL_projekt

## Popis projektu
Analýza dostupnosti základních potravin široké veřejnosti na základě průměrných příjmů v ČR v období 2006–2018. Cílem je připravit robustní datové podklady pro porovnání dostupnosti potravin a poskytnout odpovědi na výzkumné otázky tiskovému oddělení.

Jako dodatečný materiál je připravena tabulka s HDP, GINI koeficientem a populací evropských států ve stejném období.

## Zdroje dat
**czechia_payroll** — mzdy v různých odvětvích, zdroj: Portál otevřených dat ČR,
**czechia_price** — ceny vybraných potravin, zdroj: Portál otevřených dat ČR,
**countries** — informace o zemích světa,
**economies** — HDP, GINI a další ekonomické ukazatele zemí.

## Popis výstupních tabulek

  ### Primární tabulka: t_denys_lopanskyi_project_SQL_primary_final
  Tabulka spojuje data o mzdách a cenách potravin za ČR za společné období 2006–2018. 
  Obsahuje sloupce:
  **rok** — rok měření,
  **odvětví** — název odvětví dle czechia_payroll_industry_branch,
  **prumerna_mzda** — průměrná hrubá mzda na zaměstnance (Kč),
  **kategorie_potraviny** — název kategorie potraviny,
  **jednotka** — jednotka množství (kg, l, ks...),
  **prumerna_cena** — průměrná cena potraviny za daný rok (Kč).
  Zdrojové tabulky: czechia_payroll, czechia_payroll_industry_branch, czechia_price, czechia_price_category.

  Skript:
```sql  
  CREATE TABLE t_denys_lopanskyi_project_SQL_primary_final AS
SELECT
    cp.payroll_year AS rok,
    cpib.name AS odvětví,
    AVG(cp.value) AS prumerna_mzda,
    cpc.name AS kategorie_potraviny,
    cpc.price_unit AS jednotka,
    AVG(p.value) AS prumerna_cena
FROM czechia_payroll cp
JOIN czechia_payroll_industry_branch cpib 
    ON cp.industry_branch_code = cpib.code
JOIN czechia_price p 
    ON cp.payroll_year = EXTRACT(YEAR FROM p.date_from)
JOIN czechia_price_category cpc 
    ON p.category_code = cpc.code
WHERE cp.value_type_code = 5958
    AND cp.payroll_year BETWEEN 2006 AND 2018
GROUP BY
    cp.payroll_year,
    cpib.name,
    cpc.name,
    cpc.price_unit
ORDER BY
    cp.payroll_year,
    cpib.name,
    cpc.name;
```

  ### Sekundární tabulka: t_denys_lopanskyi_project_SQL_secondary_final
  Tabulka obsahuje ekonomické ukazatele evropských států za období 2006–2018.
  Obsahuje sloupce:
  **country** — název státu,
  **year** — rok,
  **gdp** — hrubý domácí produkt,
  **gini** — GINI koeficient,
  **population** — počet obyvatel.
  Zdrojové tabulky: economies, countries.

  Skript:
```sql
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
```

  ### Kvalita dat
  
  ### Primární tabulka
Tabulka obsahuje 6 498 řádků bez chybějících hodnot.

### Sekundární tabulka
Tabulka obsahuje 585 řádků. Chybějící hodnoty se vyskytují u:
- **HDP** — 37 chybějících hodnot (6 % řádků)
- **GINI koeficient** — 124 chybějících hodnot (21 % řádků)
- **Populace** — žádné chybějící hodnoty

Chybějící hodnoty GINI koeficientu jsou způsobeny tím, že ne všechny 
evropské státy reportují tento ukazatel každý rok. Při analýze 
vlivu HDP (otázka č. 5) je třeba brát v úvahu že 6 % hodnot HDP 
chybí.

  

## Výzkumné otázky a odpovědi

  ### Otázka 1: Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

    Skript:
  ```sql
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
```


| Rok | Odvětví | Změna (%) |
|---|---|---|
| 2009 | Těžba a dobývání | -3.74 |
| 2009 | Ubytování, stravování a pohostinství | -1.20 |
| 2009 | Zemědělství, lesnictví, rybářství | -0.62 |
| 2010 | Profesní, vědecké a technické činnosti | -0.61 |
| 2010 | Veřejná správa a obrana | -0.33 |
| 2010 | Vzdělávání | -1.84 |
| 2011 | Kulturní, zábavní a rekreační činnosti | -0.05 |
| 2011 | Veřejná správa a obrana | -2.24 |
| 2013 | Peněžnictví a pojišťovnictví | -8.91 |
| 2013 | Výroba elektřiny, plynu... | -4.37 |
| 2013 | Stavebnictví | -2.13 |
| 2013 | Profesní, vědecké a technické činnosti | -2.91 |
| 2013 | Těžba a dobývání | -2.85 |
| 2013 | Administrativní a podpůrné činnosti | -0.36 |
| 2013 | Informační a komunikační činnosti | -1.01 |
| 2013 | Kulturní, zábavní a rekreační činnosti | -1.38 |
| 2013 | Velkoobchod a maloobchod | -0.94 |
| 2013 | Zásobování vodou | -0.38 |
| 2013 | Činnosti v oblasti nemovitostí | -1.69 |
| 2014 | Těžba a dobývání | -0.79 |
| 2015 | Výroba elektřiny, plynu... | -1.31 |
| 2016 | Těžba a dobývání | -0.59 |

 ### Odpověd:  
 Mzdy nerostly ve všech odvětvích každý rok. Data ukazují dva období 
poklesů:
**1. Vlna (2009)** — přímý dopad finanční krize 2008, pokles mezd 
ve 3 odvětvích (Těžba a dobývání, Ubytování a pohostinství, Zemědělství).
**2. Vlna (2010–2013)** — kombinace dozvuku finanční krize a vládních 
úsporných opatření. Nejkritičtější byl rok 2013, kdy klesly mzdy 
v 10 odvětvích najednou. Největší pokles zaznamenalo Peněžnictví 
a pojišťovnictví (-8.91 %) jako důsledek regulace finančního sektoru 
po krizi.
Po roce 2013 byly poklesy mezd již ojedinělé — týkaly se pouze 
Těžby a dobývání (2014: -0.79 %, 2016: -0.59 %) a Výroby elektřiny 
a plynu (2015: -1.31 %), což odráží strukturální problémy 
v těchto odvětvích.
