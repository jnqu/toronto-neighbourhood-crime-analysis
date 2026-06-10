DROP TABLE IF EXISTS crime_incidents;
DROP TABLE IF EXISTS neighbourhood_profiles;

CREATE TABLE neighbourhood_profiles(
    neighbourhood_id INTEGER PRIMARY KEY,
    neighbourhood_name TEXT NOT NULL,
    population INTEGER NOT NULL
);

CREATE TABLE crime_incidents(
    incident_id INTEGER PRIMARY KEY,
    event_id TEXT,
    reported_date DATE NOT NULL,
    reported_year SMALLINT NOT NULL,
    reported_month SMALLINT NOT NULL,
    reported_quarter SMALLINT NOT NULL,
    offence_category TEXT NOT NULL,
    neighbourhood_id INTEGER NOT NULL REFERENCES neighbourhood_profiles (neighbourhood_id),
    neighbourhood_name TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION
);

CREATE INDEX idx_crime_neighbourhood ON crime_incidents (neighbourhood_id);
CREATE INDEX idx_crime_year ON crime_incidents (reported_year);
CREATE INDEX idx_crime_category ON crime_incidents (offence_category);