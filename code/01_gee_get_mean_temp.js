var palettes = require('users/gena/packages:palettes');

// -----------------------------------------------------------------------------
// get a vague and specific NYC geometry to use -------------------------------- 
var nyc_bounds = ee.Geometry({
  'type': 'Polygon',
  'coordinates':
    [[[-74.28, 40.95],
      [-74.28, 40.47],
      [-73.65, 40.47],
      [-73.65, 40.95]]]
});

var nyc = ee.FeatureCollection('FAO/GAUL/2015/level2')
  .filter('ADM1_NAME == "New York"')
nyc = nyc
        .filter(ee.Filter.inList('ADM2_NAME', 
                                 ['Kings', 'Richmond', 'New York', 
                                  'Queens', 'Bronx'])).geometry()


// -----------------------------------------------------------------------------
// Function to map across image collection to mask cloud pixels ----------------
function prepSrL8(image) {
  // Develop masks for unwanted pixels (fill, cloud, cloud shadow).
  var qaMask = image.select('QA_PIXEL').bitwiseAnd(parseInt('11111', 2)).eq(0);
  var saturationMask = image.select('QA_RADSAT').eq(0);

 
  // Replace original bands with scaled bands and apply masks.
  return image.updateMask(qaMask).updateMask(saturationMask);
}


// -----------------------------------------------------------------------------
// get the collection for correct location, days, filtered and masked for clouds
var landsat8 = ee.ImageCollection('LANDSAT/LC08/C02/T1_L2')
                  .filterDate('2014-05-01', '2022-10-01')
                  .filter(ee.Filter.calendarRange(6, 9, 'month'))
                  .filter(ee.Filter.lt('CLOUD_COVER', 40))
                  .filterBounds(nyc)
                  .map(function(image){return image.clip(nyc_bounds)})
                  .map(prepSrL8);
                  
// how many images are we including
print(landsat8.size())



// -----------------------------------------------------------------------------
// get means for entire period and by year for exporting -----------------------

// get overall mean
var heat_overall = landsat8
                  .select('ST_B10')
                  .reduce(ee.Reducer.mean())
                  .clip(nyc);
                  
var visParams = {min: 45500, max: 48500, palette: palettes.colorbrewer.Spectral[9].reverse()};
Map.addLayer(heat_overall, visParams, "overall mean temp");
                              
Export.image.toDrive({
  image: heat_overall,
  scale: 30,
  description: 'surfacetemperature_2014_2022',
  fileFormat: 'GeoTIFF',
});

// get the mean for 2014
var heat_2014 = landsat8
                  .filterDate('2014-01-01', '2014-12-31')
                  .select('ST_B10')
                  .reduce(ee.Reducer.mean())
                  .clip(nyc)
                  .subtract(heat_overall);

var visParams = {min: -800, max: 800, palette: palettes.colorbrewer.Spectral[9].reverse()};
//Map.addLayer(heat_2014.select('ST_B10_mean'), visParams, "2014 diff temp");
                              
                              
Export.image.toDrive({
  image: heat_2014,
  scale: 30,
  description: 'surfacetemperature_summer2014',
  fileFormat: 'GeoTIFF',
});


// get the mean for 2015
var heat_2015 = landsat8
                  .filterDate('2015-01-01', '2015-12-31')
                  .select('ST_B10')
                  .reduce(ee.Reducer.mean())
                  .clip(nyc)
                  .subtract(heat_overall);

//Map.addLayer(heat_2015.select('ST_B10_mean'), visParams, "2015 diff temp");
                              
Export.image.toDrive({
  image: heat_2015,
  scale: 30,
  description: 'surfacetemperature_summer2015',
  fileFormat: 'GeoTIFF',
});


// get the mean for 2016
var heat_2016 = landsat8
                  .filterDate('2016-01-01', '2016-12-31')
                  .select('ST_B10')
                  .reduce(ee.Reducer.mean())
                  .clip(nyc)
                  .subtract(heat_overall);

//Map.addLayer(heat_2016.select('ST_B10_mean'), visParams, "2016 diff temp");
                              
Export.image.toDrive({
  image: heat_2016,
  scale: 30,
  description: 'surfacetemperature_summer2016',
  fileFormat: 'GeoTIFF',
});


// get the mean for 2017
var heat_2017 = landsat8
                  .filterDate('2017-01-01', '2017-12-31')
                  .select('ST_B10')
                  .reduce(ee.Reducer.mean())
                  .clip(nyc)
                  .subtract(heat_overall);

//Map.addLayer(heat_2017.select('ST_B10_mean'), visParams, "2017 diff temp");
                              
Export.image.toDrive({
  image: heat_2017,
  scale: 30,
  description: 'surfacetemperature_summer2017',
  fileFormat: 'GeoTIFF',
});


// get the mean for 2018
var heat_2018 = landsat8
                  .filterDate('2018-01-01', '2018-12-31')
                  .select('ST_B10')
                  .reduce(ee.Reducer.mean())
                  .clip(nyc)
                  .subtract(heat_overall);

//Map.addLayer(heat_2018.select('ST_B10_mean'), visParams, "2018 diff temp");
                              
Export.image.toDrive({
  image: heat_2018,
  scale: 30,
  description: 'surfacetemperature_summer2018',
  fileFormat: 'GeoTIFF',
});


// get the mean for 2019
var heat_2019 = landsat8
                  .filterDate('2019-01-01', '2019-12-31')
                  .select('ST_B10')
                  .reduce(ee.Reducer.mean())
                  .clip(nyc)
                  .subtract(heat_overall);
                  
//Map.addLayer(heat_2019.select('ST_B10_mean'), visParams, "2019 diff temp");
                              
Export.image.toDrive({
  image: heat_2019,
  scale: 30,
  description: 'surfacetemperature_summer2019',
  fileFormat: 'GeoTIFF',
});

// get the mean for 2020
var heat_2020 = landsat8
                  .filterDate('2020-01-01', '2020-12-31')
                  .select('ST_B10')
                  .reduce(ee.Reducer.mean())
                  .clip(nyc)
                  .subtract(heat_overall);
                  
//Map.addLayer(heat_2020.select('ST_B10_mean'), visParams, "2020 diff temp");
                              
Export.image.toDrive({
  image: heat_2020,
  scale: 30,
  description: 'surfacetemperature_summer2020',
  fileFormat: 'GeoTIFF',
});

// get the mean for 2021
var heat_2021 = landsat8
                  .filterDate('2021-01-01', '2021-12-31')
                  .select('ST_B10')
                  .reduce(ee.Reducer.mean())
                  .clip(nyc)
                  .subtract(heat_overall);
                  
//Map.addLayer(heat_2021.select('ST_B10_mean'), visParams, "2021 diff temp");
                              
Export.image.toDrive({
  image: heat_2021,
  scale: 30,
  description: 'surfacetemperature_summer2021',
  fileFormat: 'GeoTIFF',
});

// get the mean for 2022
var heat_2022 = landsat8
                  .filterDate('2022-01-01', '2022-12-31')
                  .select('ST_B10')
                  .reduce(ee.Reducer.mean())
                  .clip(nyc)
                  .subtract(heat_overall);
                  
//Map.addLayer(heat_2022.select('ST_B10_mean'), visParams, "2022 diff temp");
                              
Export.image.toDrive({
  image: heat_2022,
  scale: 30,
  description: 'surfacetemperature_summer2022',
  fileFormat: 'GeoTIFF',
});