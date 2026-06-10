-- Query1 ---------------------------
WITH bounds AS (
    SELECT MAX(reported_year) AS latest_complete_year
    FROM crime_incidents
    WHERE reported_year < EXTRACT(YEAR FROM CURRENT_DATE)
),
incident_counts AS (
    SELECT c.neighbourhood_id, COUNT(*) AS total_incidents
    FROM crime_incidents c, bounds b
    WHERE c.reported_year BETWEEN b.latest_complete_year - 3 AND b.latest_complete_year
    GROUP BY c.neighbourhood_id
)
SELECT
    n.neighbourhood_name,
    ic.total_incidents,
    n.population,
    ROUND(ic.total_incidents * 10000.0 / n.population, 1) AS incidents_per_10k,
    RANK() OVER (ORDER BY ic.total_incidents DESC) AS rank_by_count,
    RANK() OVER (ORDER BY ic.total_incidents * 10000.0 / n.population DESC) AS rank_by_rate,
    RANK() OVER (ORDER BY ic.total_incidents DESC)
        - RANK() OVER (ORDER BY ic.total_incidents * 10000.0 / n.population DESC) AS rank_shift
FROM incident_counts ic
JOIN neighbourhood_profiles n ON ic.neighbourhood_id = n.neighbourhood_id
ORDER BY rank_shift DESC;

-- Query2 ---------------------------
WITH yearly AS (
    SELECT neighbourhood_name, reported_year, COUNT(*) AS incidents
    FROM crime_incidents
    WHERE reported_year < EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY neighbourhood_name, reported_year
)
SELECT
    neighbourhood_name,
    reported_year,
    incidents,
    LAG(incidents) OVER (PARTITION BY neighbourhood_name ORDER BY reported_year) AS prev_year,
    incidents - LAG(incidents) OVER (PARTITION BY neighbourhood_name ORDER BY reported_year) AS yoy_change,
    ROUND(
        100.0 * (incidents - LAG(incidents) OVER (PARTITION BY neighbourhood_name ORDER BY reported_year))
        / NULLIF(LAG(incidents) OVER (PARTITION BY neighbourhood_name ORDER BY reported_year), 0)
    , 1) AS yoy_pct
FROM yearly
ORDER BY neighbourhood_name, reported_year;

-- Query3 ---------------------------
SELECT
    neighbourhood_name,
    offence_category,
    COUNT(*) AS incidents,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY neighbourhood_name),
        1
    ) AS pct_of_neighbourhood
FROM crime_incidents
WHERE reported_year < EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY neighbourhood_name, offence_category
ORDER BY neighbourhood_name, incidents DESC;

-- Query4 ---------------------------
WITH neighbourhood_counts AS (
    SELECT neighbourhood_name, COUNT(*) AS total_incidents
    FROM crime_incidents
    WHERE reported_year < EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY neighbourhood_name
)
SELECT
    neighbourhood_name,
    total_incidents,
    ROW_NUMBER() OVER (ORDER BY total_incidents DESC) AS neighbourhood_rank_cum,
    SUM(total_incidents) OVER (ORDER BY total_incidents DESC) AS running_total,
    ROUND(
        100.0 * SUM(total_incidents) OVER (ORDER BY total_incidents DESC)
        / SUM(total_incidents) OVER (),
        1
    ) AS cumulative_pct
FROM neighbourhood_counts
ORDER BY total_incidents DESC;