# NYC Heat Map (Surface Temperature)

### Mapping Heat Inequality in NYC

In our warming climate, [with New York statewide annual temperature warming 3 degrees since 1970](https://www.dec.ny.gov/energy/94702.html#:~:text=The%20annual%20statewide%20average%20temperature,northern%20parts%20of%20the%20state.), extreme heat and unequal access to cool green spaces may become a more serious issue than ever before.

Using satellite data from the US Geological Survey’s Landsat 8 satellite, the New York City Council’s Data Team put together a map of how temperature varies across the city. Following a discussion with [Dr. Christian Braneon of Columbia The Environmental Justice and Climate Just Cities Network](https://people.climate.columbia.edu/networks/profile/environmental-justice-and-climate-just-cities-network), we decided to focus on relative temperature rather than presenting the raw surface temperature. Relative temperature gives us exactly the measure we're interested in - how neighborhoods are exposed to high heat relative to one another. 

The result is clear: some parts of the city are hotter during the summer months than others, particularly in south/southeast Brooklyn and southeast Queens. The differences in neighborhood temperature are dominated by the presence of parks - where there are green spaces there are cool spaces. 

https://people.climate.columbia.edu/users/profile/christian-v-braneon

## FAQ

#### Can I use this map in my own work?

Yes! Please attribute credit to the New York City Council Data Team. 

#### What does "deviation from the mean" mean?

For every pixel in the data, we find the average temperature over all days (that we have data for) during June through September in 2020-2022. This gives us an average surface temperature in every location. Then, we find the average over all locations and subtract that from each individual location, creating our "deviation from the mean" measure. This shows, on average, how much hotter or cooler that location is compared to the city average. 

#### How did you make this map?

You can read about how we created this map in the [Implementation](#Implementation) section of this document.

#### How does your methodology deal with clouds?

In the code we use to get our data from Google Earth Engine, we filter out clouds from every image before finding the average surface temperature at each point. This means we can include images even on cloudy days. See more in the [Implementation](#Implementation) section.

#### How does your methodology deal with creating neighborhood level estimates?

Since we're most interested in neighborhood level effects, we're taking the very fine grain data (each pixel is 30m, so about 10 data points every long block) and averaging over all areas to smooth the data out. The final data we visualize is averaging over all cells that are about 1.5 long blocks in any direction. 

To be specific, we are calculating "moving window" averages over a square area 27 pixels tall and wide. Given each pixel represents 30m, that means the total area we are averaging over is about half a mile tall and wide. 

#### What happened to the previous map?

We've updated the map! We're using more data now, and have slightly changed how we're visualizing the data, and the current code is slightly easier to follow and update. 

#### Where can I download a high res version of the map?

You can access and download the html map [here](visuals/summer_heat_smoothed_deviation_raster.html). You can also download an html map at the native satellite resolution of 30m [here](visuals/summer_heat_deviation_raster.html) if you'd like to look at how heat differs at a finer grain level.

#### Where can I download the cleaned data that is shown in the map?

You can access and download that data [here](data/output/f_deviation_smooth.tif).

#### Where is the data originally sourced from?

We're using [satellite data from Landsat 8](https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_LC08_C02_T1_L2), as produced by USGS and disseminated by Google Earth Engine. The satellite was launched in 2013, and collects images across the globe, with an approximately 16 day revisit rate and 30 meter resolution. It captures roughly  112 miles (about 180 km) wide swaths of the earth at a time and passes over the same longitude at the same time of day +/- 15 minutes. For more information about Landsat and various usage caveats check the [Landsat 8 Data User's Handbook](https://prd-wret.s3-us-west-2.amazonaws.com/assets/palladium/production/atoms/files/LSDS-1574_L8_Data_Users_Handbook-v5.0.pdf).

We downloaded it through Google Earth Engine (and that code is provided), though it can also be accessed through the [USGS Earth Explorer](https://earthexplorer.usgs.gov/) or the [USGS Machine-to-Machine API](https://m2m.cr.usgs.gov/).
 
#### What's the difference between surface temperature and air temperature?

You can learn more about how Landsat 8 measures temperature using the Thermal Infrared Sensor in two thermal bands [here](https://landsat.gsfc.nasa.gov/satellites/landsat-8/spacecraft-instruments/thermal-infrared-sensor/).


## Data 

No data structure is required to be able to reproduce this as all data is fetched through the code provided. See more in the [Implementation](#Implementation) section.

## Implementation

### [Download temperature rasters over the city using Google Earth Engine](code/01_gee_get_mean_temp.js)

This script is meant to be run in [Google Earth Engine](https://code.earthengine.google.com/) (GEE), which is free to access but does require you to fill out a brief form explaining your main use cases.  

Pulls in all Landsat 8 imagery (Collection 2, Tier 1) covering the NYC area and filters for images: 
* from 2020-2022 
* falling in a month from June to September

For this collection of images, the images are each "masked" to remove any part of the image with a cloud or a cloud shadow and clipped to the boundaries of NYC. The collection of images is then collapsed by taking the mean - for each pixel over NYC we take the mean at that pixel over all images. There are around 150 images in the collection after all filters. 

The script provided then exports the final raster of mean temperatures at each pixel to Google Drive. To get this data you can paste the script provided into the web based code editor and hit "Run" above your code. After it is processed, you can hit the "Run" in the console to export the image to your Google Drive. This image can then be download for any local computation or plotting. For the rest of the code to run, you must put the image in the `data/input` folder, and keep the name as `surfacetemperature_mean_2020_2022.tif`. 

### [Mapping the raster data](code/02_mapping_2020_2022_raster.R)

This script takes the mean temperature raster that we created in GEE, and processes it for the final map. To get the final product we take the following steps:

* crop to be only the NYC area, removing water area
* convert to Kelvin using the scale and offset parameters provided in the GEE [data dictionary]((https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_LC08_C02_T1_L2))
* convert to Farenheit
* figure out what the overall mean over all of NYC is and subtract it from all pixels. From here on we are dealing with a "deviation from the mean" measure rather than raw Farenheit. Instead it represents the difference (still in farenheit) from the city average. 

At this point we create the native resolution version of the final map. This map shows very fine grain differences in temperature - you can distinguish the heat of the runways vs the greenery at Floyd Bennett Field, or the Met building surrounded by the cool of Central Park. 

To process our fine grain data from Landsat to get a neighborhood level estimate we take an average for each pixel over a square area 27 pixels wide and high - 13 pixels on either side of the pixel of interest. As each pixel is 30m, that window covers about 390 meters = 1300 feet = 1.4 long blocks. This windowed average is created for all pixels in the map. Only pixels within NYC borders are used, so for pixels close to the border less data is used to create the average.

Before plotting either map, we first cap the temperature deviations at |8|, so that the map doesn't too heavily focus on the few very extreme deviations (up to 30 degrees different from the city average!). If we don't cap the extreme deviations the map drowns all the variation in neighborhoods people live and work in by focusing on the extreme temperatures of parks, water, marshes, airports, and train yards. 