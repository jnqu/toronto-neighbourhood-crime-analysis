# Toronto Public Safety & Neighbourhood Crime Analysis

Analysis of major crime across Toronto's 158 neighbourhoods using PostgreSQL, SQL, Python
(pandas), and Tableau. The project normalizes crime by population to compare neighbourhoods
fairly, since raw incident counts tend to overstate risk in areas that simply have more people.


## Overview

Ranking neighbourhoods by raw crime count and by crime per capita gives different results.
Large neighbourhoods accumulate high counts mainly because more people live there, while
smaller neighbourhoods with concentrated crime can be overlooked. This project measures that
difference (the rank inversion) and shows where it is largest.

It uses three open datasets:

- **Major Crime Indicators (MCI):** about 475,000 offence records from the Toronto Police
  Service (2014 to 2025), covering five categories: Assault, Auto Theft, Break and Enter,
  Robbery, and Theft Over.
- **Neighbourhood Profiles (2021 Census):** population per neighbourhood from the City of
  Toronto, used as the denominator for per-capita rates.
- **Neighbourhood Boundaries:** polygons for the 158-neighbourhood system, used for the
  Tableau map.

Full citations are in the References section.

## Objectives

The project sets out to build a reproducible pipeline that moves the raw open data through to
analysis-ready tables in a relational database. On that foundation, it computes
population-normalized crime rates (incidents per 10,000 residents) and compares them against
raw counts to find the neighbourhoods whose ranking shifts most once population is taken into
account. It also measures how concentrated crime is across the city, quantifying the share of
incidents attributable to the busiest neighbourhoods. Finally, it presents the results through
interactive Tableau dashboards that allow the patterns to be explored by year and crime
category.

## Methodology

### 1. Data cleaning

Notebook: [`python/clean_data.ipynb`](python/clean_data.ipynb)

- Converted epoch-millisecond timestamps to dates and derived year, month, and quarter.
- Used the reported date rather than the occurrence date. Reported date is complete with no
  nulls; occurrence date has gaps and a long pre-2014 tail.
- Kept one row per offence, matching how the Toronto Police Service reports MCI counts.
- Removed 7,313 records (1.5%) with no neighbourhood (NSA, "Not in Specified Area"), since they
  cannot be population-normalized.
- Reshaped the transposed census file into one row per neighbourhood.
- Exported the cleaned tables to `data/cleaned/`.

### 2. Database

Scripts: [`sql/01_schema.sql`](sql/01_schema.sql), [`sql/02_load.sql`](sql/02_load.sql)

- Created a `crime_incidents` fact table and a `neighbourhood_profiles` dimension table, linked
  by a foreign key on `neighbourhood_id`, with indexes on the join, year, and category columns.
- Confirmed a 1:1 join between crime and census neighbourhood IDs. Both sources use the 2021
  158-neighbourhood system, so no crosswalk was needed.

### 3. Analysis

Queries: [`sql/03_analysis_queries.sql`](sql/03_analysis_queries.sql)

| # | Question | Technique |
|---|----------|-----------|
| 1 | Which neighbourhoods are misjudged by raw counts? | `RANK()` (rank inversion) |
| 2 | Is crime rising or falling per neighbourhood over time? | `LAG()` (year-over-year) |
| 3 | What crime mix defines each neighbourhood? | `SUM() OVER (PARTITION BY ...)` |
| 4 | How concentrated is crime across the city? | running `SUM() OVER (ORDER BY ...)` (Pareto) |

The analysis window is derived from the data (the most recent four complete years) rather than
hardcoded.

### 4. Visualization (Tableau)

- Citywide Overview: totals, category breakdown, and yearly and seasonal trends.
- Neighbourhood Comparison: a map shaded by incidents per 10,000 residents, with rankings by
  raw count shown next to rankings by per-capita rate.
- Offence Deep Dive: category trends, a neighbourhood-by-category heatmap, and a month-by-year
  seasonality grid.

## Key Findings

- Population adjustment reshuffles the rankings. Beechborough-Greenbrook ranks 139th of 158 by
  raw count but 27th per capita, while West Humber-Clairville has the most incidents of any
  neighbourhood yet only ranks 5th per capita. Raw counts largely track population.
- Crime is concentrated: the top 42 of 158 neighbourhoods (about 27%) account for roughly half
  of all major crime.
- Crime mix varies by area. West Humber-Clairville is 46% auto theft, while Mimico-Queensway is
  nearly 80% assault.
- Citywide incidents peaked in 2023 at about 49,000, following a dip during 2020 and 2021.

## Limitations

- Population is from the 2021 Census, the most recent neighbourhood-level data available.
  City-wide estimates are higher and more recent (around 3 million), but no neighbourhood
  breakdown exists for them. Since the analysis compares neighbourhoods to each other, a
  consistent census vintage is the appropriate denominator and does not affect rankings.
- The population figure uses Statistics Canada's 25% sample data, which is randomly rounded.
  Neighbourhood totals sum to about 2.76 million versus the official 2.79 million (about 1.2%
  lower). This does not affect relative comparisons.
- Data extends into early 2026, so the partial year is excluded from trend comparisons to avoid
  a misleading drop. The most recent complete year is 2025.
- The reported date was chosen for completeness and may differ from when an offence occurred.
- The analysis covers only the five MCI categories and excludes records without a mapped
  neighbourhood.

## References

1. Toronto Police Service. *Major Crime Indicators (Open Data).* Public Safety Data Portal.
   https://data.torontopolice.on.ca/datasets/TorontoPS::major-crime-indicators-open-data/about
2. City of Toronto. *Neighbourhood Profiles (2021 Census, 158-neighbourhood model).* City of
   Toronto Open Data Portal. https://open.toronto.ca/dataset/neighbourhood-profiles/
3. City of Toronto. *Neighbourhoods (boundary files).* City of Toronto Open Data Portal.
   https://open.toronto.ca/dataset/neighbourhoods/
4. Statistics Canada. *Census of Population, 2021.*

Data accessed June 2026. All datasets are publicly available under their respective open data
licences.