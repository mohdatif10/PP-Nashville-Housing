use portfolioproject;


create table coviddeaths (
iso_code varchar(3),
continent varchar(100),
location varchar(100),
covid_date date,
population bigint,
total_cases bigint,
new_cases bigint, 
new_cases_smoothed	double, total_deaths bigint,
new_deaths int, 
new_deaths_smoothed double,
total_cases_per_million	double, 
new_cases_per_million double,	
new_cases_smoothed_per_million double,
total_deaths_per_million double,
new_deaths_per_million double,
new_deaths_smoothed_per_million	double,
reproduction_rate double,
icu_patients int,
icu_patients_per_million double,
hosp_patients int,
hosp_patients_per_million double,
weekly_icu_admissions int, 
weekly_icu_admissions_per_million double, 
weekly_hosp_admissions int, 
weekly_hosp_admissions_per_million double, 
total_tests bigint);

#################
use portfolioproject;
select count(*) from information_schema.columns WHERE table_name='covidvaccinations';

UPDATE covidvaccinations
SET new_vaccinations= NULL 
WHERE new_vaccinations= 0;


#####################
select location, covid_date, total_Cases, new_cases, total_deaths, population from coviddeaths order by 1,2;

## Looking at total cases vs. total deaths
select location, covid_date, total_Cases, total_deaths, (total_deaths*100/total_cases) as death_rate from coviddeaths where location like '%states%' order by 1,2;

##Looking at countries with highest infection rate
select location, population, covid_date, max(total_Cases) as highest_infection_count, max((total_cases*100/population)) as infection_rate from coviddeaths group by location, population order by infection_rate desc;

##Showing countries with highest death count per population
select location, population, covid_date, max(Total_deaths) as highest_death_count, total_deaths, max((total_deaths*100/population)) as death_rate from coviddeaths group by location, population order by death_rate desc;

##Showing continents with highest death count
select continent, max(Total_deaths) as highest_death_count from coviddeaths 
where continent is not null 
group by continent
order by highest_death_count desc;

##Global numbers
select sum(new_Cases) as total_Cases, sum(new_deaths) as total_deaths, (sum(new_deaths)/sum(new_Cases))*100 as death_rate
from coviddeaths
where continent is not null
#group by covid_date
order by 1,2;

##Looking at Total Population vs. Total Vaccinations 

#tmp table for the query
create temporary table percent_pop_vaccinated
(continent varchar(100),
location varchar(100),
covid_date date,
population bigint,
new_vaccinations bigint,
rolling_people_vaccinated bigint);
drop temporary table if exists percent_pop_vaccinated;   ##to drop my table as soon as I create it to make it temp

insert into percent_pop_vaccinated 				#to use the tmp table data for the query, we have to insert the queried data into the table
select coviddeaths.continent, coviddeaths.location, coviddeaths.covid_date, coviddeaths.population, covidvaccinations.new_vaccinations, 
sum(new_vaccinations) over (partition by coviddeaths.location order by coviddeaths.location, coviddeaths.covid_date)  as rolling_people_vaccinated
from coviddeaths 
inner join covidvaccinations 
on coviddeaths.location=covidvaccinations.location 
and coviddeaths.covid_date=covidvaccinations.covid_date
where coviddeaths.continent is not null;

select *, (rolling_people_vaccinated/population)*100 from percent_pop_vaccinated;

	
##Creating view for later visualizations
create view percent_population_vaccinated as
select coviddeaths.continent, coviddeaths.location, coviddeaths.covid_date, coviddeaths.population, covidvaccinations.new_vaccinations, 
sum(new_vaccinations) over (partition by coviddeaths.location order by coviddeaths.location, coviddeaths.covid_date) as rolling_people_vaccinated
from coviddeaths 
inner join covidvaccinations 
on coviddeaths.location=covidvaccinations.location 
and coviddeaths.covid_date=covidvaccinations.covid_date
where coviddeaths.continent is not null;









##SCRATCH##

GRANT ALL ON portfolioproject TO 'root' WITH GRANT OPTION;
tail -f /var/log/mysqld.log;


LOAD DATA local
infile '"C:\\Users\\mohda\\Desktop\\UW\\Fall 2022\\Info Sys 422\\Practicing SQL\\CovidVaccinations.csv"'
into table covidvaccinations
fields terminated by ','
ignore 1 rows;

show databases;


create table xxx (
iso_code varchar(7),
continent varchar(25),
location varchar(25),
date_sample date,
population bigint,
total_cases int,
new_cases int)
;

show variables like "local_infile";
set global local_infile=1;
