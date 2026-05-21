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

  Zdrojové tabulky: czechia_payroll, czechia_payroll_industry_branch, czechia_price, 
  czechia_price_category.

  ### Sekundární tabulka: t_denys_lopanskyi_project_SQL_secondary_final
  Tabulka obsahuje ekonomické ukazatele evropských států za období 2006–2018.

  Obsahuje sloupce:
  **country** — název státu,
  **year** — rok,
  **gdp** — hrubý domácí produkt,
  **gini** — GINI koeficient,
  **population** — počet obyvatel.

  Zdrojové tabulky: economies, countries.
