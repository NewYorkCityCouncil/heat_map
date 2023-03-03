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
writeRaster(median_temp, "data/output/f_median_temp", 
            format = "GTiff", overwrite = T)

deviation = median_temp - mean(values(median_temp), na.rm=T)
z_score = scale(median_temp)

# save out the deviation
writeRaster(deviation, "data/output/f_deviation", 
            format = "GTiff", overwrite = T)


################################################################################
# create plot 
################################################################################

# capping the outliers ---------------------------------------------------------
# since leaflet coloring is linear, this lets us use the larger range

deviation_plot = deviation
values(deviation_plot) = ifelse(values(deviation_plot) <= -8, -8, values(deviation_plot))
values(deviation_plot) = ifelse(values(deviation_plot) >= 8, 8, values(deviation_plot))


# mapping 

#colorRamps::matlab.like(15), 
heat_pal = colorNumeric(rev(brewer.pal(11, "RdYlBu")), 
                        domain = c(values(deviation_plot), 
                                   # extend domain past so border values aren't NA
                                   min(values(deviation_plot), na.rm=T)-0.1, 
                                   max(values(deviation_plot), na.rm=T)+0.1),
                        na.color = "transparent")

map = leaflet(options = leafletOptions(zoomControl = FALSE, 
                                       minZoom = 10, 
                                       maxZoom = 16)) %>%
  addProviderTiles('CartoDB.Positron', 
                   options = providerTileOptions(minZoom = 10, maxZoom = 14)) %>%
  addRasterImage(deviation_plot, colors = heat_pal, opacity = 0.4) %>% 
  addLegend_decreasing(position = "topleft", 
            pal = heat_pal, 
            values = values(deviation_plot), 
            title = paste0("Temperature Deviation", "<br>", "from Mean"),  
            labFormat = labelFormat(prefix = "  "), decreasing = T)


withr::with_dir('visuals', saveWidget(map, file="summer_heat_deviation_raster.html"))


################################################################################
# smoothed plot
################################################################################

deviation_smooth = focal(deviation, w=matrix(rep(1, 47^2), nrow=47), 
                         fun="mean", na.rm=T) %>% mask(nyc)

values(deviation_smooth) = ifelse(values(deviation_smooth) <= -8, -8, values(deviation_smooth))
values(deviation_smooth) = ifelse(values(deviation_smooth) >= 8, 8, values(deviation_smooth))

map = leaflet(options = leafletOptions(zoomControl = FALSE, 
                                       minZoom = 10, 
                                       maxZoom = 16)) %>%
  addProviderTiles('CartoDB.Positron', 
                   options = providerTileOptions(minZoom = 10, maxZoom = 14)) %>%
  addRasterImage(deviation_smooth, colors = heat_pal, opacity = 0.4) %>% 
  addLegend_decreasing(position = "topleft", 
                       pal = heat_pal, 
                       values = values(deviation_plot), 
                       title = paste0("Temperature Deviation", "<br>", "from Mean"),  
                       labFormat = labelFormat(prefix = "  "), decreasing = T)


withr::with_dir('visuals', saveWidget(map, file="summer_heat_smoothed_deviation_raster.html"))
