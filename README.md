# NYC Heat Map (Surface Temperature)

### Mapping Heat Inequality in NYC

With more New Yorkers staying home this summer, extreme heat and unequal access to cool green spaces may become a more serious issue than ever before.

Using satellite data from the US Geological Survey’s Landsat 8 satellite, the New York City Council’s Data Team put together a map of how temperature varies across the city.

The result is clear: some parts of the city are hotter during the summer months than others, particularly in south/southeast Brooklyn and southeast Queens. 

## Quick Links 

#### - [Download our NYC Summer 2014-2022 surface temperature data.](data/input/surfacetemperature_mean_2014_2022.tiff)

#### - [Download surface temperature data from the USGS.](code/01_gee_get_mean_temp.js)

#### - [Download the html NYC heat map.](visuals/summer_heat_smoothed_deviation_raster.html)


## Background

After discussion with a NASA-affiliated expert, we've determined that actually presenting the true surface temperature, regardless of whether it's measured in Kelvin, Celsius or Fahrenheit, will not be very informative for us or end users; what does it mean if the surface temperature is 95 degrees F on a summer day? Is that hold or cold? Additionally, relying on exact temperatures increases the likelihood of inaccuracy due to the susceptibility of the data to cloud coverage and other factors that obscure satelite access to the ground. However, as the expert ----(replace with Name and link to them as a source)--- pointed out, while temperatures may fluctuate, and are susceptible to "memory" (i.e. yesterday's rain may result in cooler surface temperatures than expected, even on a scorching day), they nonetheless operate consistently across space; the parts of the city that are the warmest today are still going to be the parts of the city that are warmest tomorrow. This consistency allows us to look at just a handful of the clearest days to get an accurate impression not of temperature, but of relative temperature - how the temperatures compare to each other.


## Data 

The data structure required to reproduce this code is as follows. These files are all provided in the repo, though some of them are not raw data directly downloaded from the source - both of the files outside the raw folder are generated through the `01_gee_get_mean_temp.js` file using the process described in the implementation section. 

The ground monitor temps are sourced from [NOAA](https://www.ncdc.noaa.gov/cdo-web/datatools/lcd).

```
 └── input
  	 ├── surfacetemperature_mean_2014_2022.tiff
  	 ├── surfacetemperature_median_2014_2022.tiff
  	 └──  raw
  	      └── Ground_Monitor_Temps_NYC
              ├── central_park_temp.csv 
              ├── jfk_temp.csv
              └── laguardia_temp.csv
```

Additional data sources are used but the data is pulled straight from the source. This includes: 

* [park polygons](https://data.cityofnewyork.us/City-Government/Airport-Polygon/xfhz-rhsk)
* [airport polygons](https://data.cityofnewyork.us/City-Government/Airport-Polygon/xfhz-rhsk)

## Implementation

### [Download temperature rasters over the city using Google Earth Engine](code/01_gee_get_mean_temp.js)

This script is meant to be run in [Google Earth Engine](https://code.earthengine.google.com/), which is free to access but does require you to fill out a brief form explaining your main use cases.  

Pulls in all Landsat 8 imagery (Collection 2, Tier 1) covering the NYC area and filters for images: 
* from 2014 onwards
* falling from June to September in any year
* with <= 40% cloud cover 

For this collection of images, the images are each "masked" to remove any part of the image with a cloud or a cloud shadow and clips to the boundaries of NYC, including removing any water area. The collection of images is then collapsed by taking the mean - for each pixel over NYC we take the mean at that pixel over all images. There are 107 images in the collection after all filters. (An additional 80 can be gained by removing the cloud filter).

The script provided then exports the final raster of mean temperatures at each pixel to Google Drive. To get this data you can paste the script provided into the web based code editor and hit "Run" above your code. After it is processed, you can hit the "Run" in the console to export the image to your Google Drive. This image can then be download for any local computation or plotting. 


### [Check satellite measures against ground monitors](code/01_landsat_air_correlation.R)

### [Mapping the raster data](code/03_mapping_rasters.R)


## Additional notes + resources about the data

Surface Temp data is sourced through LANDSAT 8, provided by USGS, and sourced from Google Earth Engine. The satellite orbits the earth vertically, across the poles. It captures roughly  112 miles (~180 km) wide swaths of the earth at a time, and circumnavigates the globe every 99 minutes. This also means that it will pass over the same longitude at the same time, +/- 15 minutes. 

[Visualise Landsat imagery through the USGS website](https://earthexplorer.usgs.gov/)
[Landsat 8 Data User's Handbook](https://prd-wret.s3-us-west-2.amazonaws.com/assets/palladium/production/atoms/files/LSDS-1574_L8_Data_Users_Handbook-v5.0.pdf)
[Google Earth Engine Data Dictionary](https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_LC08_C02_T1_L2): Important to note the scale and offset parameters included here or else the numbers are nonsensical. To get the temperature in Kelvin you must multiply by 0.00341802 then subtract 149. To get temperatures in Farenheight you can pass through the following formula: F = (K − 273.15) × 9/5 + 32.

