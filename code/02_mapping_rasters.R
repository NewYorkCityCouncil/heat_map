# Notes -------------------------------------------------------------------

#' After discussion with a NASA-affiliated expert, we've determined that 
#' actually presenting the true surface temperature, regardless of whether it's
#' measured in Kelvin, Celsius or Fahrenheit, will not be very informative for
#' us or end users; what does it mean if the surface temperature is 95 degrees F
#' on a summer day? Is that hold or cold? Additionally, relying on exact temper-
#' atures increases the likelihood of inaccuracy due to the susceptibility of
#' the data to cloud coverage and other factors that obscure satelite access to
#' the ground.
#' 
#' However, as the expert pointed out, while temperatures may fluctuate, and 
#' are susceptible to "memory" (i.e. yesterday's rain may result in cooler sur-
#' face temperatures than expected, even on a scorching day), they nonetheless
#' operate consistently across space; the parts of the city that are the warmest
#' today are still going to be the parts of the city that are warmest tomorrow.
#' This consistency allows us to look at just a handful of the clearest days to
#' get an accurate impression not of temperature, but of relative temperature - 
#' how the temperatures compare to each other.


# Load dependencies to start
source("code/00_load_dependencies.R")

# functions --------------------------------------------------------------------
k_to_f <- function(temp) {return((temp - 273) * (9/5)) + 32}

# solution from mpriem89 (https://github.com/rstudio/leaflet/issues/256#issuecomment-440290201)
addLegend_decreasing <- function (map, position = c("topright", "bottomright", "bottomleft","topleft"),
                                  pal, values, na.label = "NA", bins = 7, colors, 
                                  opacity = 0.5, labels = NULL, labFormat = labelFormat(), 
                                  title = NULL, className = "info legend", layerId = NULL, 
                                  group = NULL, data = getMapData(map), decreasing = FALSE) {
  
  position <- match.arg(position)
  type <- "unknown"
  na.color <- NULL
  extra <- NULL
  if (!missing(pal)) {
    if (!missing(colors)) 
      stop("You must provide either 'pal' or 'colors' (not both)")
    if (missing(title) && inherits(values, "formula")) 
      title <- deparse(values[[2]])
    values <- evalFormula(values, data)
    type <- attr(pal, "colorType", exact = TRUE)
    args <- attr(pal, "colorArgs", exact = TRUE)
    na.color <- args$na.color
    if (!is.null(na.color) && col2rgb(na.color, alpha = TRUE)[[4]] == 
        0) {
      na.color <- NULL
    }
    if (type != "numeric" && !missing(bins)) 
      warning("'bins' is ignored because the palette type is not numeric")
    if (type == "numeric") {
      cuts <- if (length(bins) == 1) 
        pretty(values, bins)
      else bins   
      if (length(bins) > 2) 
        if (!all(abs(diff(bins, differences = 2)) <= 
                 sqrt(.Machine$double.eps))) 
          stop("The vector of breaks 'bins' must be equally spaced")
      n <- length(cuts)
      r <- range(values, na.rm = TRUE)
      cuts <- cuts[cuts >= r[1] & cuts <= r[2]]
      n <- length(cuts)
      p <- (cuts - r[1])/(r[2] - r[1])
      extra <- list(p_1 = p[1], p_n = p[n])
      p <- c("", paste0(100 * p, "%"), "")
      if (decreasing == TRUE){
        colors <- pal(rev(c(r[1], cuts, r[2])))
        labels <- rev(labFormat(type = "numeric", cuts))
      }else{
        colors <- pal(c(r[1], cuts, r[2]))
        labels <- rev(labFormat(type = "numeric", cuts))
      }
      colors <- paste(colors, p, sep = " ", collapse = ", ")
    }
    else if (type == "bin") {
      cuts <- args$bins
      n <- length(cuts)
      mids <- (cuts[-1] + cuts[-n])/2
      if (decreasing == TRUE){
        colors <- pal(rev(mids))
        labels <- rev(labFormat(type = "bin", cuts))
      }else{
        colors <- pal(mids)
        labels <- labFormat(type = "bin", cuts)
      }
    }
    else if (type == "quantile") {
      p <- args$probs
      n <- length(p)
      cuts <- quantile(values, probs = p, na.rm = TRUE)
      mids <- quantile(values, probs = (p[-1] + p[-n])/2, na.rm = TRUE)
      if (decreasing == TRUE){
        colors <- pal(rev(mids))
        labels <- rev(labFormat(type = "quantile", cuts, p))
      }else{
        colors <- pal(mids)
        labels <- labFormat(type = "quantile", cuts, p)
      }
    }
    else if (type == "factor") {
      v <- sort(unique(na.omit(values)))
      colors <- pal(v)
      labels <- labFormat(type = "factor", v)
      if (decreasing == TRUE){
        colors <- pal(rev(v))
        labels <- rev(labFormat(type = "factor", v))
      }else{
        colors <- pal(v)
        labels <- labFormat(type = "factor", v)
      }
    }
    else stop("Palette function not supported")
    if (!any(is.na(values))) 
      na.color <- NULL
  }
  else {
    if (length(colors) != length(labels)) 
      stop("'colors' and 'labels' must be of the same length")
  }
  legend <- list(colors = I(unname(colors)), labels = I(unname(labels)), 
                 na_color = na.color, na_label = na.label, opacity = opacity, 
                 position = position, type = type, title = title, extra = extra, 
                 layerId = layerId, className = className, group = group)
  invokeMethod(map, data, "addLegend", legend)
}

################################################################################
# load data
################################################################################

nyc = st_read("https://data.cityofnewyork.us/api/geospatial/tqmj-j8zm?method=export&format=GeoJSON") %>%
  st_transform("+proj=longlat +datum=WGS84")

median_temp = raster('data/input/surfacetemperature_median_2014_2022.tiff')


################################################################################
# prep temp raster 
################################################################################

nyc = st_transform(nyc, projection(median_temp))

median_temp = median_temp %>% crop(nyc) %>% mask(nyc)
median_temp = median_temp*0.00341802 + 149 #the scale and offset parameters on GEE
median_temp = k_to_f(median_temp)

deviation = median_temp - mean(values(median_temp), na.rm=T)
z_score = scale(median_temp)


################################################################################
# create plot 
################################################################################

# capping the outliers ---------------------------------------------------------
# since leaflet coloring is linear, this lets us use the larger range

values(deviation) = ifelse(values(deviation) <= -8, -8, values(deviation))
values(deviation) = ifelse(values(deviation) >= 8, 8, values(deviation))


# mapping 

heat_pal = colorNumeric(colorRamps::matlab.like(15), 
                        domain = c(values(deviation), 
                                   # extend domain past so border values aren't NA
                                   min(values(deviation), na.rm=T)-0.1, 
                                   max(values(deviation), na.rm=T)+0.1),
                        na.color = "transparent")

map = leaflet(options = leafletOptions(zoomControl = FALSE, 
                                       minZoom = 10, 
                                       maxZoom = 16)) %>%
  addProviderTiles('CartoDB.Positron', 
                   options = providerTileOptions(minZoom = 10, maxZoom = 14)) %>%
  addRasterImage(deviation, colors = heat_pal, opacity = 0.3) %>% 
  addLegend_decreasing(position = "topleft", 
            pal = heat_pal, 
            values = values(deviation), 
            title = paste0("Temperature Deviation", "<br>", "from Mean"),  
            labFormat = labelFormat(prefix = "  "), decreasing = T)


withr::with_dir('visuals', saveWidget(map, file="summer_heat_deviation_raster.html"))


# original ---------------------------------------------------------------------

# Convert raster to Sf
august_30_19_sf <- rasterToPoints(august_30_19_cropped, spatial = TRUE) %>%
  as_tibble() %>% 
  mutate(date = mdy("08-30-2019"))


july_10_18_sf <- rasterToPoints(july_10_18_cropped, spatial = TRUE) %>%
  as_tibble() %>% 
  mutate(date = mdy("07-10-2018"))

sept_22_19_sf <- rasterToPoints(sept_22_19_cropped, spatial = TRUE) %>%
  as_tibble() %>% 
  mutate(date = mdy("09-22-2019"))

# Merge sfs

collected_sf <- rbind(august_30_19_sf, july_10_18_sf, sept_22_19_sf) %>% 
  mutate(coords = paste0(as.character(x),", ", as.character(y)))


median_temp <- collected_sf %>% 
  rename(temp = Band.1) %>% 
  group_by(coords) %>% 
  summarise(median_temp = k_to_f(median(temp)/10)) %>% 
  separate(coords, into = c("x", "y"), sep = ", ") %>% 
  mutate(x = as.numeric(x),
         y = as.numeric(y))

median_temp_sf <- st_as_sf(median_temp, coords = c("x", "y")) %>% 
  st_set_crs(crs(august_30_19_cropped)) %>% st_transform(4326)

# As seen below, distribution of points seems pretty normal, slight tail on the 
# left, or possibly even an overlapping of two distributions, driven by variables
# about which we don't have access to information.
ggplot(median_temp_sf, aes(x = median_temp)) +
  geom_histogram()



# Z-Scores
#' because distribution is relatively normal, we're electing to go with z-score
#' calculation, so as to represent the distribution accurately without relying
#' on Fahrenheit values

# (value - mean)/stdev

median_temp_sf$zscore <- scale(median_temp_sf$median_temp)

# export median temp shapefile
st_write(median_temp_sf, 'data/output/median_satellite_surface_temperatures.shp')


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
