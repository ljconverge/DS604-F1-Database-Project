-- =====================================================================
-- DS604 Project: Formula 1 World Championship Database
-- Milestone 2: DDL Script (PostgreSQL)
--
-- 14 tables. Column names are lower case so they match the pandas
-- DataFrame columns after df.columns = df.columns.str.lower() in Step 3.
-- Tables are created parent-first so every FOREIGN KEY target exists.
-- =====================================================================

-- Drop in reverse dependency order (allows re-running the script)
DROP TABLE IF EXISTS constructor_results   CASCADE;
DROP TABLE IF EXISTS constructor_standings CASCADE;
DROP TABLE IF EXISTS driver_standings      CASCADE;
DROP TABLE IF EXISTS pit_stops             CASCADE;
DROP TABLE IF EXISTS lap_times             CASCADE;
DROP TABLE IF EXISTS qualifying            CASCADE;
DROP TABLE IF EXISTS sprint_results        CASCADE;
DROP TABLE IF EXISTS results               CASCADE;
DROP TABLE IF EXISTS races                 CASCADE;
DROP TABLE IF EXISTS status                CASCADE;
DROP TABLE IF EXISTS seasons               CASCADE;
DROP TABLE IF EXISTS drivers               CASCADE;
DROP TABLE IF EXISTS constructors          CASCADE;
DROP TABLE IF EXISTS circuits              CASCADE;


-- ---------------------------------------------------------------------
-- Independent (parent) tables
-- ---------------------------------------------------------------------

CREATE TABLE circuits (
    circuitid       INTEGER       PRIMARY KEY,
    circuitref      VARCHAR(50)   NOT NULL UNIQUE,
    name            VARCHAR(100)  NOT NULL,
    location        VARCHAR(100)  NOT NULL,
    country         VARCHAR(50)   NOT NULL,
    lat             NUMERIC(9,6)  NOT NULL,
    lng             NUMERIC(9,6)  NOT NULL,
    alt             INTEGER       NOT NULL,
    url             VARCHAR(255)  NOT NULL
);

CREATE TABLE constructors (
    constructorid   INTEGER       PRIMARY KEY,
    constructorref  VARCHAR(50)   NOT NULL UNIQUE,
    name            VARCHAR(100)  NOT NULL,
    nationality     VARCHAR(50)   NOT NULL,
    url             VARCHAR(255)  NOT NULL
);

CREATE TABLE drivers (
    driverid        INTEGER       PRIMARY KEY,
    driverref       VARCHAR(50)   NOT NULL UNIQUE,
    number          INTEGER,
    code            VARCHAR(3),
    forename        VARCHAR(50)   NOT NULL,
    surname         VARCHAR(50)   NOT NULL,
    dob             DATE          NOT NULL,
    nationality     VARCHAR(50)   NOT NULL,
    url             VARCHAR(255)  NOT NULL
);

CREATE TABLE seasons (
    year            INTEGER       PRIMARY KEY,
    url             VARCHAR(255)  NOT NULL
);

CREATE TABLE status (
    statusid        INTEGER       PRIMARY KEY,
    status          VARCHAR(50)   NOT NULL
);


-- ---------------------------------------------------------------------
-- Races (depends on seasons, circuits)
-- ---------------------------------------------------------------------

CREATE TABLE races (
    raceid          INTEGER       PRIMARY KEY,
    year            INTEGER       NOT NULL REFERENCES seasons (year),
    round           INTEGER       NOT NULL,
    circuitid       INTEGER       NOT NULL REFERENCES circuits (circuitid),
    name            VARCHAR(100)  NOT NULL,
    date            DATE          NOT NULL,
    time            TIME,
    url             VARCHAR(255)  NOT NULL,
    fp1_date        DATE,
    fp1_time        TIME,
    fp2_date        DATE,
    fp2_time        TIME,
    fp3_date        DATE,
    fp3_time        TIME,
    quali_date      DATE,
    quali_time      TIME,
    sprint_date     DATE,
    sprint_time     TIME
);


-- ---------------------------------------------------------------------
-- Race-level fact tables (depend on races, drivers, constructors, status)
-- ---------------------------------------------------------------------

CREATE TABLE results (
    resultid        INTEGER       PRIMARY KEY,
    raceid          INTEGER       NOT NULL REFERENCES races (raceid),
    driverid        INTEGER       NOT NULL REFERENCES drivers (driverid),
    constructorid   INTEGER       NOT NULL REFERENCES constructors (constructorid),
    number          INTEGER,
    grid            INTEGER       NOT NULL,
    position        INTEGER,
    positiontext    VARCHAR(10)   NOT NULL,
    positionorder   INTEGER       NOT NULL,
    points          NUMERIC(5,2)  NOT NULL,
    laps            INTEGER       NOT NULL,
    time            VARCHAR(20),
    milliseconds    INTEGER,
    fastestlap      INTEGER,
    rank            INTEGER,
    fastestlaptime  VARCHAR(20),
    fastestlapspeed NUMERIC(7,3),
    statusid        INTEGER       NOT NULL REFERENCES status (statusid)
);

CREATE TABLE sprint_results (
    resultid        INTEGER       PRIMARY KEY,
    raceid          INTEGER       NOT NULL REFERENCES races (raceid),
    driverid        INTEGER       NOT NULL REFERENCES drivers (driverid),
    constructorid   INTEGER       NOT NULL REFERENCES constructors (constructorid),
    number          INTEGER       NOT NULL,
    grid            INTEGER       NOT NULL,
    position        INTEGER,
    positiontext    VARCHAR(10)   NOT NULL,
    positionorder   INTEGER       NOT NULL,
    points          NUMERIC(5,2)  NOT NULL,
    laps            INTEGER       NOT NULL,
    time            VARCHAR(20),
    milliseconds    INTEGER,
    fastestlap      INTEGER,
    fastestlaptime  VARCHAR(20),
    statusid        INTEGER       NOT NULL REFERENCES status (statusid)
);

CREATE TABLE qualifying (
    qualifyid       INTEGER       PRIMARY KEY,
    raceid          INTEGER       NOT NULL REFERENCES races (raceid),
    driverid        INTEGER       NOT NULL REFERENCES drivers (driverid),
    constructorid   INTEGER       NOT NULL REFERENCES constructors (constructorid),
    number          INTEGER       NOT NULL,
    position        INTEGER       NOT NULL,
    q1              VARCHAR(20),
    q2              VARCHAR(20),
    q3              VARCHAR(20)
);

CREATE TABLE lap_times (
    raceid          INTEGER       NOT NULL REFERENCES races (raceid),
    driverid        INTEGER       NOT NULL REFERENCES drivers (driverid),
    lap             INTEGER       NOT NULL,
    position        INTEGER       NOT NULL,
    time            VARCHAR(20)   NOT NULL,
    milliseconds    INTEGER       NOT NULL,
    PRIMARY KEY (raceid, driverid, lap)
);

CREATE TABLE pit_stops (
    raceid          INTEGER       NOT NULL REFERENCES races (raceid),
    driverid        INTEGER       NOT NULL REFERENCES drivers (driverid),
    stop            INTEGER       NOT NULL,
    lap             INTEGER       NOT NULL,
    time            TIME          NOT NULL,
    duration        VARCHAR(20)   NOT NULL,
    milliseconds    INTEGER       NOT NULL,
    PRIMARY KEY (raceid, driverid, stop)
);


-- ---------------------------------------------------------------------
-- Championship tables (depend on races, drivers, constructors)
-- ---------------------------------------------------------------------

CREATE TABLE driver_standings (
    driverstandingsid       INTEGER       PRIMARY KEY,
    raceid                  INTEGER       NOT NULL REFERENCES races (raceid),
    driverid                INTEGER       NOT NULL REFERENCES drivers (driverid),
    points                  NUMERIC(6,2)  NOT NULL,
    position                INTEGER       NOT NULL,
    positiontext            VARCHAR(10)   NOT NULL,
    wins                    INTEGER       NOT NULL
);

CREATE TABLE constructor_standings (
    constructorstandingsid  INTEGER       PRIMARY KEY,
    raceid                  INTEGER       NOT NULL REFERENCES races (raceid),
    constructorid           INTEGER       NOT NULL REFERENCES constructors (constructorid),
    points                  NUMERIC(6,2)  NOT NULL,
    position                INTEGER       NOT NULL,
    positiontext            VARCHAR(10)   NOT NULL,
    wins                    INTEGER       NOT NULL
);

CREATE TABLE constructor_results (
    constructorresultsid    INTEGER       PRIMARY KEY,
    raceid                  INTEGER       NOT NULL REFERENCES races (raceid),
    constructorid           INTEGER       NOT NULL REFERENCES constructors (constructorid),
    points                  NUMERIC(6,2)  NOT NULL,
    status                  VARCHAR(10)
);
