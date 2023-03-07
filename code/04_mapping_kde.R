# Load dependencies to start
source("code/00_load_dependencies.R")

################################################################################
# load data
################################################################################

median_temp = raster("data/output/f_median_temp.tif")
deviation_temp = raster("data/output/f_deviation.tif")

#nyc = st_read("https://data.cityofnewyork.us/api/geospatial/tqmj-j8zm?method=export&format=GeoJSON") %>%
#  st_transform("+proj=longlat +datum=WGS84")


################################################################################
# convert raster to points for KDE 
################################################################################

points_temp = rasterToPoints(deviation_temp, spatial = T) %>% 
  #as_tibble() %>%
  #mutate(x = x * 100000, y = y * 100000) %>%
  st_as_sf() %>%
  #st_as_sf(coords = c("x", "y"), dim = "XY") %>% 
  st_set_crs(crs(deviation_temp)) %>% 
  st_transform(4326)# %>%
  #st_transform(28992)# 
#st_set_crs(28992) 
  


cell_size <- 10
band_width <- 150

raster_meuse <- points_temp %>% dplyr::select() %>%
  create_raster(cell_size = cell_size)

kde <- points_temp %>% dplyr::select() %>%
  kde(band_width = band_width, weights = points_temp$layer, kernel = "triweight", grid = raster_meuse)

plot(kde)

stop()

# 
# tm_shape(kde) +
#   tm_raster(palette = "viridis", title = "KDE Estimate") +
#   tm_shape(meuse) +
#   tm_bubbles(size = 0.1, col = "red") +
#   tm_layout(legend.outside = TRUE)


# 
# 
# ( e <- st_bbox(points_temp)[c(1,3,2,4)] ) 
# test <- sf.kde(x = points_temp, y = points_temp$layer, ref = e,  
#                       standardize = TRUE, 
#                       scale.factor = 10000)
# 
kde_heat = sp.kde(x = points_temp, y = points_temp$layer, 
                  res = 0.001, bw = 0.0001, scale.factor = 100000,
                  standardize = T )
plot(kde_heat)

bw = 0.00000001

# writeRaster(kde_heat, filename="data/output/kde_heatmap.tif", overwrite=TRUE)


points_temp = as(points_temp, "Spatial")

median_temp <- collected_sf %>% 
  rename(temp = Band.1) %>% 
  group_by(coords) %>% 
  summarise(median_temp = k_to_f(median(temp)/10)) %>% 
  separate(coords, into = c("x", "y"), sep = ", ") %>% 
  mutate(x = as.numeric(x),
         y = as.numeric(y))

median_temp_sf <- st_as_sf(median_temp, coords = c("x", "y")) %>% 
  st_set_crs(crs(august_30_19_cropped)) %>% st_transform(4326)


# Heat Map ----------------------------------------------------------------

### ERRORS HERE - some change in 'sp.kde'; must remove nr/nc options, replace median_temp_sp with median_temp_sf; error: gridsize too small
#convert to spatial for sp.kde
median_temp_sp <- as(median_temp_sf, "Spatial")


# Use kernel density estimate (kde) to create heatmap of city; using higher
# row/column values for a resolution that better fits the scale of the data.
kde_heat <- sp.kde(x = median_temp_sp, y = median_temp_sp$zscore,  
                   nr = 600, nc = 600, standardize = TRUE)
plot(kde_heat)

#write output
writeRaster(kde_heat, filename="data/output/kde_heatmap.tif", format = "GTiff", overwrite=TRUE)

# crop this new raster to nyc
nyc1 <- st_transform(nyc, projection(kde_heat))

write_sf(nyc1, "data/output/nyc_custom_shapefile.shp")


#crop & mask the raster files to poylgon extent/boundary
kde_heat_masked <- mask(kde_heat, nyc1)
kde_heat_crop <- crop(kde_heat_masked, nyc1)

#write nyc-cropped output
writeRaster(kde_heat_crop, filename="data/output/kde_heatmap_cropped.tif", format = "GTiff", overwrite=TRUE)


# QUICK ACCESS ------------------------------------------------------------

kde_heat <- raster("data/output/kde_heatmap.tif")
kde_heat_crop <- raster("data/output/kde_heatmap_cropped.tif")
median_temp_sf <- read_sf("data/output/median_satellite_surface_temperatures.shp")
median_temp_sp <- as(median_temp_sf, "Spatial")
nyc1 <-read_sf("data/output/nyc_custom_shapefile/nyc_custom_shapefile.shp") %>%
  st_transform("+proj=longlat +datum=WGS84")




data(meuse, package = "sp")
meuse <- st_as_sf(meuse, coords = c("x", "y"), crs = 28992,
                  agr = "constant")

# Unweighted KDE (spatial locations only)				
pt.kde <- sf.kde(x = meuse, bw = 1000, standardize = TRUE,
                 scale.factor = 10000, res=40)

plot(pt.kde, main="Unweighted kde")
plot(st_geometry(meuse), pch=20, col="red", add=TRUE)

