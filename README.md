# NYC Heat Map (Surface Temperature)

Elaborate on the intent of reason for the project
- source for general public to access NYC surface temperature
- collect and store NYC surface temperature for NYC Council use. We are focusing on the summer months from 2014 to 2019 (update) in NYC.
- Addressing Summer heat vulernability is a topic of interest for the Council. 

## Data Sources & Outputs

- data
  - input
    - Parks Properties (https://data.cityofnewyork.us/City-Government/Parks-Properties/k2ya-ucmv)
    - Airport Polygon (https://data.cityofnewyork.us/City-Government/Airport-Polygon/xfhz-rhsk)
    - landsat_st (from Landsat folder on G drive) (update to repo)
    - Ground_Monitor_Temps_NYC (from Landsat folder on G drive) (update to repo)
  - outputs

## Code

- code
 - 
## Fixing & Updating below

https://www.usgs.gov/landsat-missions/landsat-data-access#C2ARD

2 ways to get analysis ready surface temperature product from USGS - through at no charge download using Earth Explorer or through an aws s3 requester pays bucket
https://www.usgs.gov/landsat-missions/landsat-commercial-cloud-data-access

citation: Landsat Level-2 Surface Temperature Science Product courtesy of the U.S. Geological Survey.

## Getting Data

- US Landsat 4-8 ARD: [Provisional Surface Temperature (ST)](https://www.usgs.gov/landsat-missions/landsat-collection-2-surface-temperature)
  1. Make an account at (https://earthexplorer.usgs.gov/)
  2. Install [Bulk Download Application](https://earthexplorer.usgs.gov/bulk)
  
  ------- up to here ------
  3. On Earth Exloper site search panel, select desired criteria:
      - Date Range: 2014 to 2020
      - Datasets: US Landsat 4-8 ARD
      - Tile grid horizontal: 29 (NYC)
      - Tile grid vertical: 7 (NYC)
        * search for tile grid [here](https://www.usgs.gov/media/images/conterminous-us-landsat-analysis-ready-data-ard-tiles)
  4. Follow [BIG DATA Download](https://blogs.fu-berlin.de/reseda/landsat-big-data-download/#3) instructions from the blog site (blogs.fu-berlin.de) 
     - Where the instructions say "Choose “Non-Limited Results” and “CSV” in order to export the metadata of every single file found to a csv-file (which is a text file)" choose "Comma (,) Delimited" format instead.
     
- Ground Monitor Temperature:
  1. Select your local stations. (Central Park, LaGuardia, Kennedy)
  [Local Climatological Data (LCD)](https://www.ncdc.noaa.gov/cdo-web/datatools/lcd)
  2. You need to add the data to your cart, then go to your cart, where you can select that you want a csv and subset to the dates you are interested in.
     - [Central Park](https://www.ncdc.noaa.gov/cdo-web/datasets/LCD/stations/WBAN:94728/detail)

## Validating Data
- Satellite Readings
  1. Cloud Cover: https://landsat.usgs.gov/landsat-8-cloud-cover-assessment-validation-data#Urban
  2. Comparing Ground Monitor temperatures to Satellite readings
