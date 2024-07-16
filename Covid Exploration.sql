-- Covid-19 data exploration

-- Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Create Views

-- Verify coviddeaths table uploaded correctly
select *
from covid.coviddeaths

-- Verify covidvaccinations table uploaded correctly
select *
from covid.covidvaccinations

select location, date, total_cases, new_cases, total_deaths, population
from covid.coviddeaths
order by 1,2

-- Total deaths as percentage of total cases in United States
-- Shows % chance of dying if Covid is contracted by date through end of June 2024
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from covid.coviddeaths
where location = "United States"
order by 1,2

-- Looking at total cases vs. population
-- Shows percentage of population that gets Covid
-- Population reflects 2024 numbers
select location, date, total_cases, population, (total_cases/population)*100 as population_percentage
from covid.coviddeaths
where location = "United States"
order by 1,2

-- Countries that have the highest infection rate
select location, population, MAX(total_cases) as highest_infection_count, max((total_cases/population))*100 as population_percentage
from covid.coviddeaths
group by 1,2
order by population_percentage desc

-- Countries with highest death count
select location, population, MAX(total_deaths) as total_death_count
from covid.coviddeaths
where continent != location
group by location, population
order by total_death_count desc

-- Breakdown by continent
select continent, population, MAX(total_deaths) as total_death_count
from covid.coviddeaths
where continent = location
group by continent, population
order by total_death_count desc

-- Continents with highest death percentage of population
select continent, population, MAX(total_deaths) as total_death_count, (MAX(total_deaths)/population)*100 as percent_death
from covid.coviddeaths
where continent = location
group by continent, population
order by percent_death desc

-- Total deaths as percentage of total cases in North America starting in 2021
-- Shows % chance of dying if Covid is contracted by date through end of June 2024
select continent, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from covid.coviddeaths
where continent = "North America" and date > '2021-01-01'
order by `date` 

-- Total cases vs. population starting in 2021
-- Shows percentage of population that gets Covid
-- Population reflects 2024 numbers
select continent, date, total_cases, population, (total_cases/population)*100 as population_percentage
from covid.coviddeaths
where continent = "North America" and date > '2021-01-01'
order by date

-- Highest infection rate ordered by continent
select continent, population, MAX(total_cases) as highest_infection_count, max((total_cases/population))*100 as population_percentage
from covid.coviddeaths
where continent = location
group by 1,2
order by population_percentage desc

-- Global Numbers
-- Total deaths as percentage of total cases in United States
-- Shows % chance of dying if Covid is contracted by date through end of June 2024
select location, date, SUM(new_cases), SUM(new_deaths) total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from covid.coviddeaths
where continent = location
group by 1,2,5,6
order by 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rolling_people_vaccinated
--, (rolling_people_vaccinated/population)*100
From covid.coviddeaths dea
Join covid.covidvaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent = dea.location
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query
With pop_vs_vac (Continent, Location, Date, Population, New_Vaccinations, rolling_people_vaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rolling_people_vaccinated
--, (rolling_people_vaccinated/population)*100
From covid.coviddeaths dea
Join covid.covidvaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (rolling_people_vaccinated/Population)*100
From pop_vs_vac

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP Table if exists covid.percentpopulationvaccinated
Create Table percentpopulationvaccinated (
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
);

Insert into covid.percentpopulationvaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, (SUM(vac.new_vaccinations) over (partition by dea.location, dea.date)) as rolling_people_vaccinated
From covid.coviddeaths dea
Join covid.covidvaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent = dea.location
order by 2,3

Select *, (rolling_people_vaccinated/Population)*100
From covid.percentpopulationvaccinated

-- median age by country
create view covid.median_age_by_country as
select vac.location, vac.date, vac.median_age, total_cases, total_deaths
from covid.covidvaccinations vac
join covid.coviddeaths dea
	on dea.location = vac.location
	and dea.date = vac.date
where vac.continent != vac.location and median_age is not null
order by location

-- aged 65 and older by country
create view covid.aged65_by_country as
select vac.location, vac.date, vac.aged_65_older, total_cases, total_deaths
from covid.covidvaccinations vac
join covid.coviddeaths dea
	on dea.location = vac.location
	and dea.date = vac.date
where vac.continent != vac.location and aged_65_older is not null
order by location

-- diabetes prevalence by country
create view covid.diabetes_by_country as
select vac.location, vac.date, vac.diabetes_prevalence, total_cases, total_deaths
from covid.covidvaccinations vac
join covid.coviddeaths dea
	on dea.location = vac.location
	and dea.date = vac.date
where vac.continent != vac.location and diabetes_prevalence is not null
order by location

-- hospital beds by country
create view covid.hospital_beds_by_country as
select vac.location, vac.date, vac.hospital_beds_per_thousand, total_cases, total_deaths
from covid.covidvaccinations vac
join covid.coviddeaths dea
	on dea.location = vac.location
	and dea.date = vac.date
where vac.continent != vac.location and hospital_beds_per_thousand is not null
group by 1,2,3,4,5
order by hospital_beds_per_thousand desc