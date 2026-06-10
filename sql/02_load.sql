TRUNCATE crime_incidents, neighbourhood_profiles;

\copy neighbourhood_profiles FROM 'data/cleaned/neighbourhood_profiles.csv' WITH (FORMAT csv, HEADER true);
\copy crime_incidents FROM 'data/cleaned/crime_incidents.csv' WITH (FORMAT csv, HEADER true);
