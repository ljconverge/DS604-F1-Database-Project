-- DS604 Project – Milestone 4: Analytical Queries
-- Formula 1 World Championship (1950–2024) | Schema: DBMS_project

SET search_path TO "DBMS_project";

-- Query 1: Career wins
-- Which drivers have the highest number of career race wins, and how does the top 10 list look across all seasons?
SELECT d.forename || ' ' || d.surname                         AS driver,
       d.nationality,
       COUNT(*) FILTER (WHERE NULLIF(r.position, '\N')::int = 1)                 AS wins,
       COUNT(*) FILTER (WHERE NULLIF(r.position, '\N')::int <= 3)                AS podiums,
       COUNT(*)                                               AS races_entered,
       ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(r.position, '\N')::int = 1) / COUNT(*), 1) AS win_pct
FROM results r
JOIN drivers d ON d."driverId" = r."driverId"
GROUP BY d."driverId", d.forename, d.surname, d.nationality
ORDER BY wins DESC, podiums DESC
LIMIT 10;

-- Query 2: Constructor dominance
-- Which constructors have won the most Constructors' Championships, and in which eras did they dominate?
WITH season_final_race AS (          -- last race of every season
    SELECT year, MAX(round) AS last_round
    FROM races
    GROUP BY year
),
champions AS (                       -- constructor in P1 after the final race
    SELECT ra.year, cs."constructorId"
    FROM constructor_standings cs
    JOIN races ra             ON ra."raceId" = cs."raceId"
    JOIN season_final_race sf ON sf.year = ra.year AND sf.last_round = ra.round
    WHERE cs.position = 1
)
SELECT c.name                                             AS constructor,
       COUNT(*)                                           AS championships,
       MIN(ch.year)                                       AS first_title,
       MAX(ch.year)                                       AS latest_title,
       STRING_AGG(ch.year::text, ', ' ORDER BY ch.year)   AS title_years
FROM champions ch
JOIN constructors c ON c."constructorId" = ch."constructorId"
GROUP BY c.name
ORDER BY championships DESC, first_title;

-- Query 3: All-time points leaders
-- Who are the top 10 drivers by total career championship points?
WITH season_final_race AS (
    SELECT year, MAX(round) AS last_round
    FROM races
    GROUP BY year
),
season_end AS (                      -- each driver's final standing in each season
    SELECT ds."driverId", ra.year, ds.points, ds.position
    FROM driver_standings ds
    JOIN races ra             ON ra."raceId" = ds."raceId"
    JOIN season_final_race sf ON sf.year = ra.year AND sf.last_round = ra.round
)
SELECT d.forename || ' ' || d.surname            AS driver,
       SUM(se.points)                            AS career_points,
       COUNT(*)                                  AS seasons,
       COUNT(*) FILTER (WHERE se.position = 1)   AS world_titles,
       MAX(se.points)                            AS best_season_points,
       ROUND((SUM(se.points) / COUNT(*))::numeric, 1)       AS points_per_season
FROM season_end se
JOIN drivers d ON d."driverId" = se."driverId"
GROUP BY d."driverId", d.forename, d.surname
ORDER BY career_points DESC
LIMIT 10;

-- Query 4: Pit-stop efficiency
-- What is the average pit-stop duration per constructor per season, and which team is consistently the fastest in the pits?
WITH stops AS (                      -- attach the constructor and season to every stop
    SELECT ra.year, r."constructorId", ps.milliseconds
    FROM pit_stops ps
    JOIN results r ON r."raceId" = ps."raceId" AND r."driverId" = ps."driverId"
    JOIN races ra  ON ra."raceId" = ps."raceId"
    WHERE ps.milliseconds < 60000    -- exclude red-flag stoppages and long repairs
),
season_avg AS (
    SELECT year, "constructorId",
           COUNT(*)                         AS stops,
           AVG(milliseconds) / 1000.0       AS avg_stop_s,
           RANK() OVER (PARTITION BY year ORDER BY AVG(milliseconds)) AS season_rank
    FROM stops
    GROUP BY year, "constructorId"
    HAVING COUNT(*) >= 20            -- ignore teams with very few stops in a season
)
SELECT c.name                                       AS constructor,
       COUNT(*)                                     AS seasons,
       COUNT(*) FILTER (WHERE sa.season_rank = 1)   AS seasons_fastest,
       ROUND(AVG(sa.season_rank), 1)                AS avg_season_rank,
       ROUND(MIN(sa.avg_stop_s), 2)                 AS best_season_avg_s,
       ROUND(AVG(sa.avg_stop_s), 2)                 AS overall_avg_s
FROM season_avg sa
JOIN constructors c ON c."constructorId" = sa."constructorId"
GROUP BY c.name
HAVING COUNT(*) >= 3
ORDER BY seasons_fastest DESC, avg_season_rank;

-- Query 5: Busiest circuits
-- Which circuits have hosted the highest number of Grands Prix?
SELECT ci.name           AS circuit,
       ci.location,
       ci.country,
       COUNT(*)          AS grands_prix,
       MIN(ra.year)      AS first_race,
       MAX(ra.year)      AS latest_race
FROM races ra
JOIN circuits ci ON ci."circuitId" = ra."circuitId"
GROUP BY ci."circuitId", ci.name, ci.location, ci.country
ORDER BY grands_prix DESC, first_race;

-- Query 5b: Busiest circuits (part b)
-- How has the race calendar evolved geographically, decade by decade?
SELECT (ra.year / 10) * 10                 AS decade,
       COUNT(*)                            AS races,
       COUNT(DISTINCT ra."circuitId")      AS circuits_used,
       COUNT(DISTINCT ci.country)          AS countries,
       ROUND(COUNT(*)::numeric / COUNT(DISTINCT ra.year), 1) AS races_per_season
FROM races ra
JOIN circuits ci ON ci."circuitId" = ra."circuitId"
GROUP BY decade
ORDER BY decade;

-- Query 6: Lap-time evolution
-- How has the lap time at a given circuit (Monza) changed over the decades?
SELECT (ra.year / 10) * 10                         AS decade,
       COUNT(DISTINCT ra."raceId")                 AS races,
       COUNT(*)                                    AS laps_recorded,
       ROUND(AVG(lt.milliseconds) / 1000.0, 3)     AS avg_lap_s,
       ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY lt.milliseconds) / 1000.0)::numeric, 3) AS median_lap_s,
       ROUND(MIN(lt.milliseconds) / 1000.0, 3)     AS fastest_lap_s
FROM lap_times lt
JOIN races ra    ON ra."raceId" = lt."raceId"
JOIN circuits ci ON ci."circuitId" = ra."circuitId"
WHERE ci."circuitRef" = 'monza'
GROUP BY decade
ORDER BY decade;

-- Query 7: Qualifying vs. race outcome
-- What is the correlation between a driver's qualifying position and their final race position?
SELECT ra.year,
       COUNT(DISTINCT ra."raceId")                                  AS races,
       COUNT(*)                                                     AS driver_results,
       ROUND(CORR(q.position, NULLIF(r.position, '\N')::int)::numeric, 3)              AS corr_quali_vs_finish,
       COUNT(*) FILTER (WHERE q.position = 1 AND NULLIF(r.position, '\N')::int = 1)    AS wins_from_pole,
       ROUND(100.0 * COUNT(*) FILTER (WHERE q.position = 1 AND NULLIF(r.position, '\N')::int = 1)
             / COUNT(DISTINCT ra."raceId"), 1)                      AS pct_races_won_from_pole
FROM qualifying q
JOIN results r ON r."raceId" = q."raceId" AND r."driverId" = q."driverId"
JOIN races ra  ON ra."raceId" = q."raceId"
WHERE NULLIF(r.position, '\N')::int IS NOT NULL          -- classified finishers only
GROUP BY ra.year
ORDER BY ra.year DESC;

-- Query 8: Winners by nationality
-- What is the nationality distribution of race winners, and which countries have produced the most successful drivers?
SELECT d.nationality,
       COUNT(*)                                            AS race_wins,
       COUNT(DISTINCT d."driverId")                        AS different_winners,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)  AS pct_of_all_wins
FROM results r
JOIN drivers d ON d."driverId" = r."driverId"
WHERE NULLIF(r.position, '\N')::int = 1
GROUP BY d.nationality
ORDER BY race_wins DESC;

-- Query 9: DNF / retirement analysis
-- Which constructors have the highest number of race retirements (DNFs), and what are the most common causes?
WITH dnf AS (
    SELECT r."constructorId",
           s.status,
           CASE
             WHEN s.status ILIKE ANY (ARRAY['%engine%', '%power unit%', '%turbo%', '%overheating%', '%oil%',
                                            '%water%', '%radiator%', '%ers%', '%fuel%', '%ignition%',
                                            '%injection%', '%exhaust%', '%alternator%', '%magneto%', '%throttle%'])
                  THEN 'Engine / power unit'
             WHEN s.status ILIKE ANY (ARRAY['%accident%', '%collision%', '%spun off%', '%damage%'])
                  THEN 'Accident / collision'
             WHEN s.status ILIKE ANY (ARRAY['%gearbox%', '%transmission%', '%clutch%', '%driveshaft%',
                                            '%halfshaft%', '%differential%', '%axle%'])
                  THEN 'Gearbox / transmission'
             ELSE 'Other'
           END AS cause_group
    FROM results r
    JOIN status s ON s."statusId" = r."statusId"
    WHERE s.status <> 'Finished'
      AND s.status NOT LIKE '+%'                     -- '+1 Lap' etc. are classified finishers
      AND s.status NOT IN ('Did not qualify', 'Did not prequalify', 'Withdrew',
                           'Did not start', 'Disqualified', 'Excluded', '107% Rule')
)
SELECT c.name                                                          AS constructor,
       COUNT(*)                                                        AS dnfs,
       COUNT(*) FILTER (WHERE cause_group = 'Engine / power unit')     AS engine,
       COUNT(*) FILTER (WHERE cause_group = 'Accident / collision')    AS accident,
       COUNT(*) FILTER (WHERE cause_group = 'Gearbox / transmission')  AS gearbox,
       COUNT(*) FILTER (WHERE cause_group = 'Other')                   AS other,
       MODE() WITHIN GROUP (ORDER BY status)                           AS most_common_cause
FROM dnf
JOIN constructors c ON c."constructorId" = dnf."constructorId"
GROUP BY c.name
ORDER BY dnfs DESC;

-- Query 10: Season points progression
-- How do the championship points of the top 5 drivers of the 2021 season progress race by race?
WITH season_races AS (
    SELECT "raceId", round, name
    FROM races
    WHERE year = 2021
),
top5 AS (                            -- top 5 of the final standings
    SELECT ds."driverId"
    FROM driver_standings ds
    WHERE ds."raceId" = (SELECT "raceId" FROM season_races ORDER BY round DESC LIMIT 1)
      AND ds.position <= 5
)
SELECT sr.round,
       sr.name                                                        AS race,
       d.surname                                                      AS driver,
       ds.points                                                      AS total_points,
       ds.points - COALESCE(LAG(ds.points, 1) OVER (PARTITION BY ds."driverId" ORDER BY sr.round), 0) AS points_this_race,
       MAX(ds.points) OVER (PARTITION BY sr.round) - ds.points        AS gap_to_leader,
       ds.position                                                    AS championship_position
FROM driver_standings ds
JOIN season_races sr ON sr."raceId" = ds."raceId"
JOIN top5 t          ON t."driverId" = ds."driverId"
JOIN drivers d       ON d."driverId" = ds."driverId"
ORDER BY sr.round, ds.position;

-- Query 11: Fastest-lap leaders (drivers)
-- Which drivers hold the most 'fastest lap of the race' awards?
SELECT d.forename || ' ' || d.surname    AS driver,
       COUNT(*)                          AS fastest_laps,
       COUNT(DISTINCT ra.year)           AS seasons_with_fastest_lap,
       MIN(ra.year)                      AS first,
       MAX(ra.year)                      AS latest
FROM results r
JOIN drivers d ON d."driverId" = r."driverId"
JOIN races ra  ON ra."raceId" = r."raceId"
WHERE r.rank = '1'                         -- rank 1 = fastest lap of the race
GROUP BY d."driverId", d.forename, d.surname
ORDER BY fastest_laps DESC;

-- Query 11b: Fastest-lap leaders (constructors)
-- Which constructors hold the most fastest-lap awards, and how are these distributed across seasons?
SELECT c.name                                                 AS constructor,
       COUNT(*)                                               AS fastest_laps,
       COUNT(DISTINCT ra.year)                                AS seasons,
       ROUND(COUNT(*)::numeric / COUNT(DISTINCT ra.year), 1)  AS per_season,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)     AS pct_of_all
FROM results r
JOIN constructors c ON c."constructorId" = r."constructorId"
JOIN races ra       ON ra."raceId" = r."raceId"
WHERE r.rank = '1'
GROUP BY c.name
ORDER BY fastest_laps DESC;

-- Query 12: Home-race advantage
-- Do drivers perform better (higher finishing position) at their home Grand Prix compared to their season average?
WITH nationality_country(nationality, country) AS (
    VALUES ('British','UK'), ('American','USA'), ('American','United States'), ('Italian','Italy'),
           ('French','France'), ('German','Germany'), ('Brazilian','Brazil'), ('Argentine','Argentina'),
           ('Belgian','Belgium'), ('South African','South Africa'), ('Swiss','Switzerland'),
           ('Japanese','Japan'), ('Australian','Australia'), ('Dutch','Netherlands'), ('Spanish','Spain'),
           ('Austrian','Austria'), ('Canadian','Canada'), ('Swedish','Sweden'), ('Mexican','Mexico'),
           ('Monegasque','Monaco'), ('Portuguese','Portugal'), ('Russian','Russia'), ('Chinese','China'),
           ('Indian','India'), ('Malaysian','Malaysia'), ('Hungarian','Hungary')
),
entries AS (
    SELECT r."driverId", ra.year, r."positionOrder",
           CASE WHEN nc.country IS NOT NULL THEN 1 ELSE 0 END AS is_home
    FROM results r
    JOIN races ra    ON ra."raceId" = r."raceId"
    JOIN circuits ci ON ci."circuitId" = ra."circuitId"
    JOIN drivers d   ON d."driverId" = r."driverId"
    LEFT JOIN nationality_country nc ON nc.nationality = d.nationality AND nc.country = ci.country
),
per_season AS (                      -- home races vs. the driver's other races in the same season
    SELECT "driverId", year,
           COUNT(*) FILTER (WHERE is_home = 1)                AS home_races,
           AVG("positionOrder") FILTER (WHERE is_home = 1)    AS avg_home,
           AVG("positionOrder") FILTER (WHERE is_home = 0)    AS avg_other
    FROM entries
    GROUP BY "driverId", year
    HAVING COUNT(*) FILTER (WHERE is_home = 1) > 0
       AND COUNT(*) FILTER (WHERE is_home = 0) > 0
)
SELECT d.forename || ' ' || d.surname                AS driver,
       d.nationality,
       SUM(ps.home_races)::int                       AS home_races,
       ROUND(AVG(ps.avg_home), 2)                    AS avg_finish_home,
       ROUND(AVG(ps.avg_other), 2)                   AS avg_finish_other,
       ROUND(AVG(ps.avg_other - ps.avg_home), 2)     AS places_gained_at_home,
       CASE WHEN AVG(ps.avg_other - ps.avg_home) > 0 THEN 'Better at home'
            ELSE 'Not better at home' END            AS verdict
FROM per_season ps
JOIN drivers d ON d."driverId" = ps."driverId"
GROUP BY d."driverId", d.forename, d.surname, d.nationality
HAVING SUM(ps.home_races) >= 8
ORDER BY home_races DESC;

-- Query 12b: Home-race advantage (overall)
-- Across all drivers, is the average finishing position better at home races?
WITH nationality_country(nationality, country) AS (
    VALUES ('British','UK'), ('American','USA'), ('American','United States'), ('Italian','Italy'),
           ('French','France'), ('German','Germany'), ('Brazilian','Brazil'), ('Argentine','Argentina'),
           ('Belgian','Belgium'), ('South African','South Africa'), ('Swiss','Switzerland'),
           ('Japanese','Japan'), ('Australian','Australia'), ('Dutch','Netherlands'), ('Spanish','Spain'),
           ('Austrian','Austria'), ('Canadian','Canada'), ('Swedish','Sweden'), ('Mexican','Mexico'),
           ('Monegasque','Monaco'), ('Portuguese','Portugal'), ('Russian','Russia'), ('Chinese','China'),
           ('Indian','India'), ('Malaysian','Malaysia'), ('Hungarian','Hungary')
),
entries AS (
    SELECT r."driverId", ra.year, r."positionOrder",
           CASE WHEN nc.country IS NOT NULL THEN 1 ELSE 0 END AS is_home
    FROM results r
    JOIN races ra    ON ra."raceId" = r."raceId"
    JOIN circuits ci ON ci."circuitId" = ra."circuitId"
    JOIN drivers d   ON d."driverId" = r."driverId"
    LEFT JOIN nationality_country nc ON nc.nationality = d.nationality AND nc.country = ci.country
),
per_season AS (                      -- home races vs. the driver's other races in the same season
    SELECT "driverId", year,
           COUNT(*) FILTER (WHERE is_home = 1)                AS home_races,
           AVG("positionOrder") FILTER (WHERE is_home = 1)    AS avg_home,
           AVG("positionOrder") FILTER (WHERE is_home = 0)    AS avg_other
    FROM entries
    GROUP BY "driverId", year
    HAVING COUNT(*) FILTER (WHERE is_home = 1) > 0
       AND COUNT(*) FILTER (WHERE is_home = 0) > 0
)
SELECT COUNT(*)                                       AS driver_seasons_compared,
       ROUND(AVG(avg_home), 2)                        AS avg_finish_home,
       ROUND(AVG(avg_other), 2)                       AS avg_finish_other,
       ROUND(AVG(avg_other - avg_home), 2)            AS avg_places_gained_at_home,
       ROUND(100.0 * COUNT(*) FILTER (WHERE avg_home < avg_other) / COUNT(*), 1) AS pct_seasons_better_at_home
FROM per_season;

-- Query 13: Decade-wise team dominance
-- What share of total points did each constructor earn per decade (top 3 per decade)?
WITH season_final_race AS (
    SELECT year, MAX(round) AS last_round
    FROM races
    GROUP BY year
),
season_points AS (                   -- constructors' final points of each season
    SELECT ra.year, cs."constructorId", cs.points
    FROM constructor_standings cs
    JOIN races ra             ON ra."raceId" = cs."raceId"
    JOIN season_final_race sf ON sf.year = ra.year AND sf.last_round = ra.round
),
decade_points AS (
    SELECT (year / 10) * 10 AS decade, "constructorId", SUM(points) AS points
    FROM season_points
    GROUP BY decade, "constructorId"
),
ranked AS (
    SELECT decade, "constructorId", points,
           ROUND((100.0 * points / SUM(points) OVER (PARTITION BY decade))::numeric, 1) AS pct_share,
           RANK() OVER (PARTITION BY decade ORDER BY points DESC)           AS rank_in_decade
    FROM decade_points
)
SELECT r.decade, r.rank_in_decade, c.name AS constructor, r.points, r.pct_share
FROM ranked r
JOIN constructors c ON c."constructorId" = r."constructorId"
WHERE r.rank_in_decade <= 3
ORDER BY r.decade, r.rank_in_decade;

-- Query 14: Grid position vs. points scored
-- Does starting grid position show a meaningful relationship with points scored in the race (2010 onward, same points system)?
SELECT CASE
         WHEN r.grid = 0               THEN 'Pit lane'
         WHEN r.grid = 1               THEN 'P1 (pole)'
         WHEN r.grid BETWEEN 2 AND 3   THEN 'P2-P3'
         WHEN r.grid BETWEEN 4 AND 6   THEN 'P4-P6'
         WHEN r.grid BETWEEN 7 AND 10  THEN 'P7-P10'
         WHEN r.grid BETWEEN 11 AND 15 THEN 'P11-P15'
         ELSE 'P16+'
       END                                                                    AS grid_bucket,
       COUNT(*)                                                               AS starts,
       ROUND(AVG(r.points)::numeric, 2)                                                AS avg_points,
       ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(r.position, '\N')::int = 1)  / COUNT(*), 1)   AS win_pct,
       ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(r.position, '\N')::int <= 3) / COUNT(*), 1)   AS podium_pct,
       ROUND(100.0 * COUNT(*) FILTER (WHERE r.points > 0)    / COUNT(*), 1)   AS points_finish_pct
FROM results r
JOIN races ra ON ra."raceId" = r."raceId"
WHERE ra.year >= 2010
GROUP BY grid_bucket
ORDER BY MIN(CASE WHEN r.grid = 0 THEN 99 ELSE r.grid END);

-- Query 15: Sprint vs. Grand Prix performance
-- For seasons with sprint races (2021 onward), how does a driver's sprint result compare with their main-race result on the same weekend?
SELECT d.forename || ' ' || d.surname                              AS driver,
       COUNT(*)                                                    AS sprint_weekends,
       ROUND(AVG(s."positionOrder"), 2)                            AS avg_sprint_finish,
       ROUND(AVG(r."positionOrder"), 2)                            AS avg_gp_finish,
       ROUND(AVG(r."positionOrder" - s."positionOrder"), 2)        AS gp_minus_sprint,
       SUM(s.points)                                               AS sprint_points,
       SUM(r.points)                                               AS gp_points_same_weekends,
       COUNT(*) FILTER (WHERE s."positionOrder" = r."positionOrder") AS same_position_both
FROM sprint_results s
JOIN results r ON r."raceId" = s."raceId" AND r."driverId" = s."driverId"
JOIN races ra  ON ra."raceId" = s."raceId"
JOIN drivers d ON d."driverId" = s."driverId"
GROUP BY d."driverId", d.forename, d.surname
HAVING COUNT(*) >= 5
ORDER BY sprint_points DESC;