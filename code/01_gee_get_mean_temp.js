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
// get means for entire period and exporting -----------------------------------


// get overall mean
var mean_heat = landsat8
                  .select('ST_B10')
                  .reduce(ee.Reducer.mean())
                  .clip(nyc);
                  
var visParams = {min: 45000, max: 50000, palette: palettes.colorbrewer.Spectral[9].reverse()};
Map.addLayer(mean_heat, visParams, "overall mean temp");
        
Export.image.toDrive({
  image: mean_heat,
  scale: 30,
  description: 'surfacetemperature_mean_2014_2022',
  fileFormat: 'GeoTIFF',
});


// get overall mean
var median_heat = landsat8
                  .select('ST_B10')
                  .reduce(ee.Reducer.median())
                  .clip(nyc);
                  
var visParams = {min: 45000, max: 50000, palette: palettes.colorbrewer.Spectral[9].reverse()};
Map.addLayer(median_heat, visParams, "overall median temp");
          
Export.image.toDrive({
  image: median_heat,
  scale: 30,
  description: 'surfacetemperature_median_2014_2022',
  fileFormat: 'GeoTIFF',
});