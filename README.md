# project_template
a template repository for future github projects


## Basic Repo Structure Overview

***

## Readme Example



### Analyzing Storefront Vacancies
Data analysis and visuals for NYCC 6.9.22 ['Oversight - Combatting Commercial Vacancies'](https://legistar.council.nyc.gov/MeetingDetail.aspx?From=Alert&ID=980028&GUID=239563C5-9CA2-44A7-8E1D-A970A0556192) hearing.

An associated webpage for this analysis can be found [on the council website](https://council.nyc.gov/data/vacant-storefronts/): 

***  

#### Data Sources 
- [Storefronts Reported Vacant or Not (Filing Year 2020 - 2021)](https://data.cityofnewyork.us/City-Government/Storefronts-Reported-Vacant-or-Not-Filing-Year-202/92iy-9c3n)

- 2019 5-Year ACS Survey: *We used R package censusapi to get demographic data

#### Methodology 

##### Summary & Intention
New York City can be a challenging place for small businesses to operate. In addition to adhering to occasionally complex regulatory schemes enforced by multiple City agencies, business owners confront hurdles including rising rents, taxation, competition from chain stores and e-commerce retailers, and various zoning restrictions. Over the course of the last year, a slew of beloved local establishments across the city closed amid skyrocketing costs.

Local Law 157 of 2019 seeks to gather data about the state of vacant storefronts to conduct the sort of studies needed to understand the full scope of storefront vacancy in New York City. The bill requires the department of finance to collect data and establish a public dataset of commercial properties in the City.

The data team analyzed local law 57 data in order to:
- Assess the severity of the problem 
- Identify vacant storefront hotspots 
- Release recommendations for better reporting

#### Main Takeaways
Through an analysis of this data, the New York City Council Data Team has investigated hotspots of storefront vacancies and potential economic correlations:

- Overall, the highest vacancy rates are found in the lower and midtown Manhattan and downtown Brooklyn business areas. These are also the areas that received that most COVID-19 grants and loans.
- At the neighborhood level, West Brighton, Stuyvesant Town-Cooper Village, Turtle Bay-East Midtown and Brooklyn Heights-Cobble Hill have the highest vacancies. 
- At a more granular level, census tracts with the higher vacancy rates have, on average, 216 storefronts per census tract and are mostly located in lower Manhattan.
- While the vacancy rate hovers around 12% for most census tracts, those with lower income residents are more likely to have very high vacancy rates (above 20% vacancy).
- Improving current reporting of Local Law 157 of 2019 is important to fully understand the issue. Recommendations are provided below.

#### Recommendations
Certain changes could be made by the Department of Finance to improve the overall usability of the data set. Those changes include:

- Adding a column for the date and specifically the year of the data collected
- Streamlining the multiple datasets for each year into one dataset to allow for easy integration in live updating tools/maps/charts and more accessibility to citizen data scientists
- Reduce geocode null values
- Require class 1 properties to update their status as of 6/30 or date sold if earlier than 6/30
- Require owners to report the primary business activity of the last business that leased the storefront

#### Scripts
