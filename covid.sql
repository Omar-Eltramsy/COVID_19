-- Drop tables if they exist
DROP TABLE IF EXISTS covid_death;
DROP TABLE IF EXISTS covid_vacc;

-- Create covid_death table
CREATE TABLE covid_death (
    iso_code VARCHAR(8),
    continent VARCHAR(13),
    location VARCHAR(32),
    dates DATE,
    population BIGINT,
    total_cases INT,
    new_cases INT,
    new_cases_smoothed NUMERIC,
    total_deaths INT,
    new_deaths INT,
    new_deaths_smoothed NUMERIC,
    total_cases_per_million NUMERIC,
    new_cases_per_million NUMERIC,
    new_cases_smoothed_per_million NUMERIC,
    total_deaths_per_million NUMERIC,
    new_deaths_per_million NUMERIC,
    new_deaths_smoothed_per_million NUMERIC,
    reproduction_rate NUMERIC,
    icu_patients INT,
    icu_patients_per_million NUMERIC,
    hosp_patients INT,
    hosp_patients_per_million NUMERIC,
    weekly_icu_admissions NUMERIC,
    weekly_icu_admissions_per_million NUMERIC,
    weekly_hosp_admissions NUMERIC,
    weekly_hosp_admissions_per_million NUMERIC
);

-- Create covid_vacc table
CREATE TABLE covid_vacc (
    iso_code VARCHAR(8),
    continent VARCHAR(13),
    location VARCHAR(32),
    dates DATE,
    new_tests INT,
    total_tests INT,
    total_tests_per_thousand NUMERIC,
    new_tests_per_thousand NUMERIC,
    new_tests_smoothed INT,
    new_tests_smoothed_per_thousand NUMERIC,
    positive_rate NUMERIC,
    tests_per_case NUMERIC,
    tests_units VARCHAR(15),
    total_vaccinations INT,
    people_vaccinated INT,
    people_fully_vaccinated INT,
    new_vaccinations INT,
    new_vaccinations_smoothed INT,
    total_vaccinations_per_hundred NUMERIC,
    people_vaccinated_per_hundred NUMERIC,
    people_fully_vaccinated_per_hundred NUMERIC,
    new_vaccinations_smoothed_per_million INT,
    stringency_index NUMERIC,
    population_density NUMERIC,
    median_age NUMERIC,
    aged_65_older NUMERIC,
    aged_70_older NUMERIC,
    gdp_per_capita NUMERIC,
    extreme_poverty NUMERIC,
    cardiovasc_death_rate NUMERIC,
    diabetes_prevalence NUMERIC,
    female_smokers NUMERIC,
    male_smokers NUMERIC,
    handwashing_facilities NUMERIC,
    hospital_beds_per_thousand NUMERIC,
    life_expectancy NUMERIC,
    human_development_index NUMERIC
);

-- Select all records from covid_death where continent is not null
SELECT * 
FROM covid_death
WHERE continent IS NOT NULL;

-- Display location, dates, total cases, new cases, total deaths, and population
SELECT 
    location,
    dates,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM covid_death
ORDER BY location, dates;

-- Looking at total cases vs total deaths for Germany
SELECT 
    location,
    dates,
    total_cases,
    total_deaths,
    ROUND((total_deaths::NUMERIC / total_cases::NUMERIC) * 100, 2) AS DeathPercentage
FROM covid_death
WHERE location ILIKE '%Germany%'
ORDER BY location, dates;

-- Total cases as a percentage of population
SELECT 
    ROW_NUMBER() OVER (PARTITION BY location ORDER BY total_deaths DESC) AS row_number,
    location,
    dates,
    population,
    total_cases,
    (total_cases::NUMERIC / population::NUMERIC) * 100 AS InfectionPercentage
FROM covid_death
ORDER BY row_number, dates;

-- Countries with the highest infection rate compared to population
SELECT 
    location,
    population,
    MAX(total_cases) AS HighestInfectionCount,
    MAX((total_cases::NUMERIC / population::NUMERIC) * 100) AS PercentPopulationInfected
FROM covid_death
WHERE total_cases IS NOT NULL AND population IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Country with the highest death count per population
SELECT 
    location,
    MAX(total_deaths::INT) AS Total_Death_Count
FROM covid_death
WHERE continent IS NULL  
GROUP BY location
ORDER BY Total_Death_Count DESC;

-- Breakdown by continent, showing total deaths
SELECT 
    continent,
    MAX(total_deaths::INT) AS Total_Death_Count
FROM covid_death
WHERE continent IS NULL  
GROUP BY continent
ORDER BY Total_Death_Count DESC;

-- Global numbers: total cases and deaths, and the infection percentage
SELECT 
    SUM(new_cases) AS total_cases,
    SUM(new_deaths) AS total_death, 
    (SUM(new_deaths::NUMERIC) / SUM(new_cases::NUMERIC)) * 100 AS InfectionPercentage
FROM covid_death
WHERE continent IS NOT NULL;

-- Total population vs vaccinations (cumulative)
WITH cumulative_vaccinations AS (
    SELECT DISTINCT
        cd.continent,
        cd.location,
        cd.dates,
        cd.population,
        cv.new_vaccinations,
        SUM(cv.new_vaccinations) OVER (
            PARTITION BY cd.location 
            ORDER BY cd.dates
        ) AS cumulative_vaccinations
    FROM covid_death AS cd
    JOIN covid_vacc AS cv
        ON cd.location = cv.location 
        AND cd.dates = cv.dates
    WHERE 
        cd.continent IS NOT NULL 
        AND cv.new_vaccinations IS NOT NULL
    ORDER BY location, dates
)
SELECT 
    *,
    ROUND(cumulative_vaccinations::NUMERIC / population::NUMERIC * 100, 2) AS VaccinationPercentage
FROM cumulative_vaccinations;

-- Create a view to store data for later visualizations
CREATE VIEW percent_population_vaccinated AS
SELECT DISTINCT
    cd.continent,
    cd.location,
    cd.dates,
    cd.population,
    cv.new_vaccinations,
    SUM(cv.new_vaccinations) OVER (
        PARTITION BY cd.location 
        ORDER BY cd.dates
    ) AS cumulative_vaccinations
FROM covid_death AS cd
JOIN covid_vacc AS cv
    ON cd.location = cv.location 
    AND cd.dates = cv.dates
WHERE 
    cd.continent IS NOT NULL 
    AND cv.new_vaccinations IS NOT NULL
ORDER BY location, dates;

-- Select data from the view for population vaccination percentages
SELECT *
FROM percent_population_vaccinated;
