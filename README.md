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
  
## Výzkumné otázky a odpovědi

  ### Otázka 1: Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

  | Odvětví | Rok | Změna (%) |
|---|---|---|
| Administrativní a podpůrné činnosti|2013 |-0.36|
| Informační a komunikační činnosti|2013 |-1.01 |
|Kulturní, zábavní a rekreační činnosti |2011, 2013 | -0.05, -1.38|
|Peněžnictví a pojišťovnictví | 2013|-8.91 |
| Profesní, vědecké a technické činnosti| 2010, 2013 |-0.61, -2.91|
| Stavebnictví| 2013 |-2.13 |
| Těžba a dobývání|2009, 2013, 2014, 2016|-3.74, -2.85, -0.79, -0.59  |
|Ubytování, stravování a pohostinství |2009, 2011 |-1.2, -1.11 |
|Velkoobchod a maloobchod; opravy a údržba motorových vozidel | 2013|-0.94 |
|Veřejná správa a obrana; povinné sociální zabezpečení |2010, 2011 | -0.33, -2.24|
|Vzdělávání |2010 | -1.84|
|Výroba a rozvod elektřiny, plynu, tepla a klimatiz. vzduchu |2013, 2015  |-4.37, -1.31 |
| Zemědělství, lesnictví, rybářství|2009 |-0.62 |
|Zásobování vodou; činnosti související s odpady a sanacemi | 2013|-0.38 |
|Činnosti v oblasti nemovitostí |2013 |-1.69 |

