CREATE TABLE IF NOT EXISTS circuits (
    "circuitId"   INT           PRIMARY KEY,
    "circuitRef"  VARCHAR(50)   UNIQUE NOT NULL,
    name          VARCHAR(100)  NOT NULL,
    location      VARCHAR(100),
    country       VARCHAR(60)
);

CREATE TABLE IF NOT EXISTS constructors (
    "constructorId"   INT          PRIMARY KEY,
    "constructorRef"  VARCHAR(50)  UNIQUE NOT NULL,
    name              VARCHAR(100) NOT NULL,
    nationality       VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS drivers (
    "driverId"    INT          PRIMARY KEY,
    "driverRef"   VARCHAR(50)  UNIQUE NOT NULL,
    forename      VARCHAR(50)  NOT NULL,
    surname       VARCHAR(50)  NOT NULL,
    dob           DATE,
    nationality   VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS status (
    "statusId" INT           PRIMARY KEY,
    status     VARCHAR(100)  NOT NULL
);

CREATE TABLE IF NOT EXISTS races (
    "raceId"     INT          PRIMARY KEY,
    year       SMALLINT     NOT NULL,
    round      SMALLINT     NOT NULL,
    name       VARCHAR(100) NOT NULL,
    date       DATE        NOT NULL,
    time       TIME        NULL,
    "circuitId"  INT          NOT NULL,

    CONSTRAINT uq_races_year_rnd UNIQUE (year, round),

    CONSTRAINT fk_races_circuit
        FOREIGN KEY ("circuitId")
        REFERENCES circuits ("circuitId")
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT ck_races_year
        CHECK (year BETWEEN 1950 AND 2100),

    CONSTRAINT ck_races_round
        CHECK (round > 0)
);

CREATE TABLE IF NOT EXISTS results (
    "resultId"        INT            PRIMARY KEY,
    "raceId"          INT            NOT NULL,
    "driverId"        INT            NOT NULL,
    "constructorId"   INT            NOT NULL,
    "statusId"        INT            NOT NULL,
    points            DECIMAL(5,2)   NOT NULL DEFAULT 0,
    position          SMALLINT       NULL,
    grid              SMALLINT       NOT NULL DEFAULT 0,
    laps              SMALLINT       NOT NULL DEFAULT 0,
    rank              SMALLINT       NULL,
    "positionOrder"   SMALLINT       NOT NULL,
    "fastestLapTime"  VARCHAR(12)    NULL,

    CONSTRAINT uq_results_race_driver
        UNIQUE ("raceId", "driverId"),

    CONSTRAINT fk_results_race
        FOREIGN KEY ("raceId")
        REFERENCES races ("raceId")
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_results_driver
        FOREIGN KEY ("driverId")
        REFERENCES drivers ("driverId")
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_results_constructor
        FOREIGN KEY ("constructorId")
        REFERENCES constructors ("constructorId")
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_results_status
        FOREIGN KEY ("statusId")
        REFERENCES status ("statusId")
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT ck_results_points
        CHECK (points >= 0),

    CONSTRAINT ck_results_grid
        CHECK (grid >= 0),

    CONSTRAINT ck_results_laps
        CHECK (laps >= 0)
);

CREATE TABLE IF NOT EXISTS qualifying (
    "qualifyId"       INT          PRIMARY KEY,
    "raceId"          INT          NOT NULL,
    "driverId"        INT          NOT NULL,
    "constructorId"   INT          NOT NULL,
    position          SMALLINT     NOT NULL,

    CONSTRAINT uq_qualifying_race_driver
        UNIQUE ("raceId", "driverId"),

    CONSTRAINT fk_qualifying_race
        FOREIGN KEY ("raceId")
        REFERENCES races ("raceId")
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_qualifying_driver
        FOREIGN KEY ("driverId")
        REFERENCES drivers ("driverId")
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_qualifying_constructor
        FOREIGN KEY ("constructorId")
        REFERENCES constructors ("constructorId")
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT ck_qualifying_pos
        CHECK (position IS NULL OR position > 0)
);

CREATE TABLE IF NOT EXISTS sprint_results (
    "resultId"        INT            PRIMARY KEY,
    "raceId"          INT            NOT NULL,
    "driverId"        INT            NOT NULL,
    "statusId"        INT            NOT NULL,
    "constructorId"   INT            NOT NULL,
    points            DECIMAL(5,2)   NOT NULL DEFAULT 0,
    position          SMALLINT       NULL,
    "positionOrder"   SMALLINT       NOT NULL,
    grid              SMALLINT       NOT NULL DEFAULT 0,
    laps              SMALLINT       NOT NULL DEFAULT 0,

    CONSTRAINT uq_sprint_race_driver
        UNIQUE ("raceId", "driverId"),

    CONSTRAINT fk_sprint_race
        FOREIGN KEY ("raceId")
        REFERENCES races ("raceId")
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_sprint_driver
        FOREIGN KEY ("driverId")
        REFERENCES drivers ("driverId")
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_sprint_status
        FOREIGN KEY ("statusId")
        REFERENCES status ("statusId")
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_sprint_constructor
        FOREIGN KEY ("constructorId")
        REFERENCES constructors ("constructorId")
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT ck_sprint_points
        CHECK (points >= 0)
);

CREATE TABLE IF NOT EXISTS lap_times (
    "raceId"        INT          NOT NULL,
    "driverId"      INT          NOT NULL,
    lap             SMALLINT     NOT NULL,
    milliseconds    INT          NOT NULL,

    CONSTRAINT pk_lap_times
        PRIMARY KEY ("raceId", "driverId", lap),

    CONSTRAINT fk_laptimes_race
        FOREIGN KEY ("raceId")
        REFERENCES races ("raceId")
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_laptimes_driver
        FOREIGN KEY ("driverId")
        REFERENCES drivers ("driverId")
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT ck_laptimes_lap
        CHECK (lap > 0),

    CONSTRAINT ck_laptimes_ms
        CHECK (milliseconds > 0)
);

CREATE TABLE IF NOT EXISTS pit_stops (
    "raceId"        INT          NOT NULL,
    "driverId"      INT          NOT NULL,
    stop            SMALLINT     NOT NULL,
    lap             SMALLINT     NOT NULL,
    milliseconds    INT          NOT NULL,

    CONSTRAINT pk_pit_stops
        PRIMARY KEY ("raceId", "driverId", stop),

    CONSTRAINT fk_pitstops_race
        FOREIGN KEY ("raceId")
        REFERENCES races ("raceId")
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_pitstops_driver
        FOREIGN KEY ("driverId")
        REFERENCES drivers ("driverId")
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT ck_pitstops_stop
        CHECK (stop > 0),

    CONSTRAINT ck_pitstops_lap
        CHECK (lap > 0),

    CONSTRAINT ck_pitstops_ms
        CHECK (milliseconds > 0)
);

CREATE TABLE IF NOT EXISTS driver_standings (
    "driverStandingsId"  INT           PRIMARY KEY,
    "raceId"             INT           NOT NULL,
    "driverId"           INT           NOT NULL,
    points               DECIMAL(6,2)  NOT NULL DEFAULT 0,
    position             SMALLINT      NOT NULL,
    wins                 SMALLINT      NOT NULL DEFAULT 0,

    CONSTRAINT uq_dstand_race_driver
        UNIQUE ("raceId", "driverId"),

    CONSTRAINT fk_dstand_race
        FOREIGN KEY ("raceId")
        REFERENCES races ("raceId")
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_dstand_driver
        FOREIGN KEY ("driverId")
        REFERENCES drivers ("driverId")
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT ck_dstand_points
        CHECK (points >= 0),

    CONSTRAINT ck_dstand_wins
        CHECK (wins >= 0)
);

CREATE TABLE IF NOT EXISTS constructor_standings (
    "constructorStandingsId"  INT           PRIMARY KEY,
    "raceId"                  INT           NOT NULL,
    "constructorId"           INT           NOT NULL,
    points                    DECIMAL(6,2)  NOT NULL DEFAULT 0,
    position                  SMALLINT      NOT NULL,
    wins                      SMALLINT      NOT NULL DEFAULT 0,

    CONSTRAINT uq_cstand_race_constr
        UNIQUE ("raceId", "constructorId"),

    CONSTRAINT fk_cstand_race
        FOREIGN KEY ("raceId")
        REFERENCES races ("raceId")
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_cstand_constructor
        FOREIGN KEY ("constructorId")
        REFERENCES constructors ("constructorId")
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT ck_cstand_points
        CHECK (points >= 0),

    CONSTRAINT ck_cstand_wins
        CHECK (wins >= 0)
);

CREATE INDEX IF NOT EXISTS idx_races_year
    ON races (year);

CREATE INDEX IF NOT EXISTS idx_races_circuit
    ON races ("circuitId");

CREATE INDEX IF NOT EXISTS idx_results_driver
    ON results ("driverId");

CREATE INDEX IF NOT EXISTS idx_results_constructor
    ON results ("constructorId");

CREATE INDEX IF NOT EXISTS idx_results_status
    ON results ("statusId");

CREATE INDEX IF NOT EXISTS idx_results_rank
    ON results ("rank");

CREATE INDEX IF NOT EXISTS idx_qualifying_driver
    ON qualifying ("driverId");

CREATE INDEX IF NOT EXISTS idx_laptimes_driver
    ON lap_times ("driverId");

CREATE INDEX IF NOT EXISTS idx_pitstops_driver
    ON pit_stops ("driverId");

CREATE INDEX IF NOT EXISTS idx_dstand_driver
    ON driver_standings ("driverId");

CREATE INDEX IF NOT EXISTS idx_cstand_constructor
    ON constructor_standings ("constructorId");

CREATE INDEX IF NOT EXISTS idx_sprint_driver
    ON sprint_results ("driverId");

CREATE INDEX IF NOT EXISTS idx_drivers_nationality
    ON drivers (nationality);

CREATE INDEX IF NOT EXISTS idx_circuits_country
    ON circuits (country);
