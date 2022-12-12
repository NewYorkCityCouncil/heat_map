# NYC Heat Map (Surface Temperature)

### Mapping Heat Inequality in NYC

With more New Yorkers staying home this summer, extreme heat and unequal access to cool green spaces may become a more serious issue than ever before.
Using satellite data from the US Geological Survey’s Landsat 8 satellite, the New York City Council’s Data Team put together a map of how temperature varies across the city.

The result is clear: some parts of the city are hotter during the summer months than others, particularly in south/southeast Brooklyn and southeast Queens.

- Download NYC Summer 2018-2022 surface temperature data. (add link)

- Learn how to download surface temperature data from the USGS. (add link)

- Download the NYC heat map. (add link)

- FAQ (add link or section)


## Methodology

After discussion with a NASA-affiliated expert, we've determined that actually presenting the true surface temperature, regardless of whether it's measured in Kelvin, Celsius or Fahrenheit, will not be very informative for us or end users; what does it mean if the surface temperature is 95 degrees F on a summer day? Is that hold or cold? Additionally, relying on exact temperatures increases the likelihood of inaccuracy due to the susceptibility of the data to cloud coverage and other factors that obscure satelite access to the ground. However, as the expert ----(replace with Name and link to them as a source)--- pointed out, while temperatures may fluctuate, and are susceptible to "memory" (i.e. yesterday's rain may result in cooler surface temperatures than expected, even on a scorching day), they nonetheless operate consistently across space; the parts of the city that are the warmest today are still going to be the parts of the city that are warmest tomorrow. This consistency allows us to look at just a handful of the clearest days to get an accurate impression not of temperature, but of relative temperature - how the temperatures compare to each other.

- below 3% cloud coverage
- convert tif files into raster spatial items
- crop & mask the raster files to NYC polygon extent/boundary
- convert raster to SF spatial points
- group by coordinates & summarize to get median value output
- convert kelvin to farenheit
- look at the distribution, relatively normal
- compute z-score to get deviation from the median (relative temperature)
- run KDE to make heatmap visual


## Notes About the Data

Surface Temp data is sourced through LANDSAT 8, provided by USGS Earth Explorer. The satellite orbits the earth vertically, across the poles. It captures roughly  112 miles (~180 km) wide swaths of the earth at a time, and circumnavigates the globe every 99 minutes. This also means that it will pass over the same longitude at the same time, +/- 15 minutes. This makes time comparison quite easy. To ensure no gaps in data, LANDSAT 8 paths overlap slightly. New York City conveniently falls in the intersection of two paths - columns 13 and 14 of row 32. This means we get twice as many measurements. A third path, probably column 15, also picks up as New York City on the Earth Explorer site, but actually contains no (or nearly no) NYC geometry. Accordingly, every third will return NA, as it contains no values within the geometry we are examining.

https://earthexplorer.usgs.gov/
Acquisition Visualization: https://landsat.usgs.gov/landsat_acq
NYC Coordinates: 40.7128° N, 74.0060° W
L8 Data User's Handbook: https://prd-wret.s3-us-west-2.amazonaws.com/assets/palladium/production/atoms/files/LSDS-1574_L8_Data_Users_Handbook-v5.0.pdf

Note on Cloud Coverage:
According to the documentation, cloud coverage levels over 65% are considered cloudy. Days with high cloud coverage seem to present clearly inaccurate results; 9/8/14, for example, has a cloud coverage of 85% and shows Central Park as having an average temperature of -65 F. While Earth explorer allows users to filter based on cloud coverage (and if repeating this endeavor, I'd encourage you to download from the source while using this filter), because we already downloaded all dates, I will remove days with significant cloud coverage by pulling from the XML data, which constrains cloud cover information.


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
