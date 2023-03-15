# NYC Heat Map (Surface Temperature)

### Mapping Heat Inequality in NYC

With more New Yorkers staying home this summer, extreme heat and unequal access to cool green spaces may become a more serious issue than ever before.

Using satellite data from the US Geological Survey’s Landsat 8 satellite, the New York City Council’s Data Team put together a map of how temperature varies across the city.

The result is clear: some parts of the city are hotter during the summer months than others, particularly in south/southeast Brooklyn and southeast Queens. 

## FAQ

#### Can I use this map in my own work?

Yes! Please attribute credit to the New York City Council Data Team. 

#### What does "deviation from the mean" mean?

For every pixel in the data, we find the average temperature over all days (that we have data for) during June through September in 2020-2022. This gives us an average surface temperature in every location. Then, we find the average over all locations and subtract that from each individual location, creating our "deviation from the mean" measure. This shows how much hotter or cooler that location is compared to the NYC average. 

#### How did you make this map?

You can read about how we created this map in the [Implementation](#Implementation) section of this document.

#### How does your methodology deal with clouds?

In the code we use to get our data from Google Earth Engine, we filter out clouds from every image before finding the average surface temperature at each point. This means we can include images even on cloudy days and will only be including valid data. See more in the [Implementation](#Implementation) section.

#### How does your methodology deal with creating neighborhood level estimates?

Since we're most interested in neighborhood level effects, we're taking the very fine grain data (each pixel is 30m, so about 10 data points every long block) and averaging over all areas to smooth the data out. For every pixel in the raw data, the final data we visualize 

#### What happened to the previous map?

We've updated the map! We're using more data now, and have slightly changed how we're visualizing the data, but the current code is slightly easier to follow and update. 

#### Where can I download a high res version of the map?

You can access and download the html map [here](visuals/summer_heat_smoothed_deviation_raster.html).

#### Where can I download the cleaned data that is shown in the map?

You can access and download that data [here](data/input/surfacetemperature_mean_2014_2022.tiff).

#### Where is the data originally sourced from?

We're using [satellite data from Landsat 8](https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_LC08_C02_T1_L2), as produced by USGS and disseminated by Google Earth Engine. The satellite was launched in 2013, and collects images across the globe, with an approximately 16 day revisit rate and between 15 and 100 meter resolution. We downloaded it through Google Earth Engine (and that code is provided), though it can also be accessed through the [USGS Earth Explorer](https://earthexplorer.usgs.gov/) or the [USGS Machine-to-Machine API](https://m2m.cr.usgs.gov/).
 
#### What's the difference between surface temperature and air temperature?



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

For this collection of images, the images are each "masked" to remove any part of the image with a cloud or a cloud shadow and clips to the boundaries of NYC, including removing any water area. The collection of images is then collapsed by taking the mean - for each pixel over NYC we take the mean at that pixel over all images. There are 107 images in the collection after all filters. (An additional 80 can be gained by removing the cloud filter).

The script provided then exports the final raster of mean temperatures at each pixel to Google Drive. To get this data you can paste the script provided into the web based code editor and hit "Run" above your code. After it is processed, you can hit the "Run" in the console to export the image to your Google Drive. This image can then be download for any local computation or plotting. 


### [Mapping the raster data](code/02_mapping_2020_2022_raster.R)


## Additional notes + resources about the data

Surface Temp data is sourced through LANDSAT 8, provided by USGS, and sourced from Google Earth Engine. The satellite orbits the earth vertically, across the poles. It captures roughly  112 miles (~180 km) wide swaths of the earth at a time, and circumnavigates the globe every 99 minutes. This also means that it will pass over the same longitude at the same time, +/- 15 minutes. 

[Visualise Landsat imagery through the USGS website](https://earthexplorer.usgs.gov/)
[Landsat 8 Data User's Handbook](https://prd-wret.s3-us-west-2.amazonaws.com/assets/palladium/production/atoms/files/LSDS-1574_L8_Data_Users_Handbook-v5.0.pdf)
[Google Earth Engine Data Dictionary](https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_LC08_C02_T1_L2): Important to note the scale and offset parameters included here or else the numbers are nonsensical. To get the temperature in Kelvin you must multiply by 0.00341802 then subtract 149. To get temperatures in Farenheight you can pass through the following formula: F = (K − 273.15) × 9/5 + 32.

