--select * from ProjectBootcamp..CovidDeaths

--select * from ProjectBootcamp..CovidVaccinations

--Looking at total cases vs total deaths
--1)LIKELIHOOD OF DEATH
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from ProjectBootcamp..CovidDeaths21
WHERE total_deaths != 0 
AND total_cases != 0 
AND location like '%peru%'
order by 1,2 


--2)Looking at total cases vs population
select location, date, total_cases, population, (total_cases/population)*100 as CasesPercentage
from ProjectBootcamp..CovidDeaths21
WHERE total_deaths != 0 
AND total_cases != 0 
AND population != 0 
--AND location like '%peru%'
order by 1, 2 DESC

--3)looking at countries with highes infection rate compared to population
select location, population, max(total_cases) as HighesInfectionCount, max(total_cases/population)*100 as CasesPercentage
from ProjectBootcamp..CovidDeaths21
where total_cases != 0 
AND population != 0 
group by location, population
order by CasesPercentage desc

--4)countries with highes death count per population
select location, population, max(total_deaths) as TotalDeathCount, max(total_deaths/population)*100 as DeathxCountry
from ProjectBootcamp..CovidDeaths21
where total_deaths != 0 
AND population != 0
AND continent != ''
group by location, population
order by DeathxCountry desc


--5)deaths by continent
--option1 using data in LOCATION
select location, max(total_deaths) as TotalDeathCount
from ProjectBootcamp..CovidDeaths21
where continent = ''
group by location
order by TotalDeathCount desc


--option2 using CTE and grouping by continent
with DEATHS_COUNTRY AS (
select continent, location, max(total_deaths) as TotalDeathCount
from ProjectBootcamp..CovidDeaths21
where continent != ''
group by continent,location
)

select continent, SUM(TotalDeathCount) as deaths_c
from DEATHS_COUNTRY
group by continent
order by deaths_c desc

--6)Global numbers
with DEATHS_COUNTRY AS (
select continent, location, sum(new_cases) as n_cas, sum(new_deaths) as n_dea
from ProjectBootcamp..CovidDeaths21
where continent != ''
group by continent,location
)

select SUM(n_cas) as cases_w, sum(n_dea) as deaths_w, sum(n_dea) / sum(n_cas)*100 as death_ratio
from DEATHS_COUNTRY
order by cases_w desc


--7)total population vs vaccination

select DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations
-- to make a rolling count of new vaccionation by country and date
, SUM(VAC.new_vaccinations) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) as RollingPeopleVaccinated
from ProjectBootcamp..CovidDeaths21 as DEA
join ProjectBootcamp..CovidVaccinations21 AS VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
where DEA.continent != ''
order by 2,3


--8)use cte, vaccinations percentage / ORDER BY can NOT be used within the creation of the CTE

-- column names can be different from those of the underlying query i.e. RollingVac
with PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingVac) as 
(
	select DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations
	-- to make a rolling count of new vaccionation by country and date
	, SUM(VAC.new_vaccinations) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) as RollingPeopleVaccinated
	from ProjectBootcamp..CovidDeaths21 as DEA
	join ProjectBootcamp..CovidVaccinations21 AS VAC
		ON DEA.location = VAC.location
		AND DEA.date = VAC.date
	where DEA.continent != ''
	--can NOT use ORDER BY
)

select *, (RollingVac/Population)*100 as PercentageVac from PopvsVac
where Population != 0


--9) Usage of Temp Table for Vaccinatios ( 8) ) / ORDER BY can be used within the creation of the TEMP TABLE

-- drops TEMP TABLE if it previously existed with the same name RollingPeopleVaccinated, useful if its necessary to update TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated

--create TEMP TABLE to upload data from underlying query
CREATE TABLE #PercentPopulationVaccinated

--a TEMP TABLE uses the same parameters as a regular table
(
Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated

	select DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations
	-- to make a rolling count of new vaccionation by country and date
	, SUM(VAC.new_vaccinations) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) as RollingPeopleVaccinated
	from ProjectBootcamp..CovidDeaths21 as DEA
	join ProjectBootcamp..CovidVaccinations21 AS VAC
		ON DEA.location = VAC.location
		AND DEA.date = VAC.date
	where DEA.continent != '' and DEA.population != 0
	order by 2,3

select *, (RollingPeopleVaccinated/Population)*100 as PercentageVac from #PercentPopulationVaccinated


--10) usage of VIEW / ORDER BY can NOT be used within the creation of the VIEW

--10.1) Create a VIEW

CREATE VIEW PercentPopulationVaccinated AS
	select DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations
	-- to make a rolling count of new vaccionation by country and date
	, SUM(VAC.new_vaccinations) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) as RollingPeopleVaccinated
	from ProjectBootcamp..CovidDeaths21 as DEA
	join ProjectBootcamp..CovidVaccinations21 AS VAC
		ON DEA.location = VAC.location
		AND DEA.date = VAC.date
	where DEA.continent != '' and DEA.population != 0
--	order by 2,3

--10.2) SELECT from VIEW

Select * from PercentPopulationVaccinated


--11)How to use VARCHAR in aggregate functions

--1) usage of CONVERT function to transform varchar data into numeric (first upload)
select location, date, total_cases, total_deaths, CONVERT(numeric,total_cases), (CONVERT(numeric,total_deaths)/CONVERT(numeric,total_cases))*100
from ProjectBootcamp..CovidDeaths
WHERE total_deaths != 0 
AND total_cases != 0 
order by 1,2


--2) usage of CAST function to transform varchar data into numeric (first upload)
select location, date, total_cases, total_deaths, cast(total_cases as numeric), cast(total_deaths as numeric)/cast(total_cases as numeric)*100
from ProjectBootcamp..CovidDeaths
WHERE total_deaths != 0 AND total_cases != 0 
order by 1,2
