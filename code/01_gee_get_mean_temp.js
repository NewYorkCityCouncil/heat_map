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

Map.setCenter(-73.9860, 40.7302, 10.5);


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
                  .filterDate('2016-05-01', '2025-10-01')
                  .filter(ee.Filter.calendarRange(6, 9, 'month'))
                  .filterBounds(nyc)
                  .filter(ee.Filter.contains('.geo', nyc))
                  .map(function(image){return image.clip(nyc_bounds)})
                  .map(prepSrL8);
                  
// how many images are we including
print(landsat8.size())



// -----------------------------------------------------------------------------
// get means for entire period and exporting -----------------------------------


// get 10 year mean -------------------------------------------------------------
var mean_heat = landsat8
                  .select('ST_B10')
                  .reduce(ee.Reducer.mean())
                  .clip(nyc);
                  
var visParams = {min: 44500, max: 49000, palette: palettes.colorbrewer.Spectral[9].reverse()};
Map.addLayer(mean_heat, visParams, "10yr mean temp");
        
Export.image.toDrive({
  image: mean_heat,
  scale: 30,
  description: 'surfacetemperature_mean_2016_2025',
  fileFormat: 'GeoTIFF',
});

// get 2025 mean -------------------------------------------------------------
var mean_heat_2025 = landsat8
                  .filterDate('2025-05-01', '2025-10-01')
                  .select('ST_B10')
                  .reduce(ee.Reducer.mean())
                  .clip(nyc);

var visParams = {min: 44500, max: 49000, palette: palettes.colorbrewer.Spectral[9]};
Map.addLayer(mean_heat_2025, visParams, "2025 mean temp");
          
Export.image.toDrive({
  image: mean_heat_2025,
  scale: 30,
  description: 'surfacetemperature_mean_2025_2025',
  fileFormat: 'GeoTIFF',
});


// get 2016 mean -------------------------------------------------------------
var mean_heat_2016 = landsat8
                  .filterDate('2016-05-01', '2016-10-01')
                  .select('ST_B10')
                  .reduce(ee.Reducer.mean())
                  .clip(nyc);

var visParams = {min: 44500, max: 49000, palette: palettes.colorbrewer.Spectral[9]};
Map.addLayer(mean_heat_2016, visParams, "2016 mean temp");
          
Export.image.toDrive({
  image: mean_heat_2016,
  scale: 30,
  description: 'surfacetemperature_mean_2016_2016',
  fileFormat: 'GeoTIFF',
});


// get 5 year median -------------------------------------------------------------
var median_heat = landsat8
                  .select('ST_B10')
                  .reduce(ee.Reducer.median())
                  .clip(nyc);
                  
var visParams = {min: 44500, max: 49000, palette: palettes.colorbrewer.Spectral[9]};
Map.addLayer(median_heat, visParams, "10yr median temp");
        
Export.image.toDrive({
  image: median_heat,
  scale: 30,
  description: 'surfacetemperature_mean_2016_2025',
  fileFormat: 'GeoTIFF',
});
