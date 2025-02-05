# Load dependencies to start
source("code/00_load_dependencies.R")

################################################################################
# custom functions
################################################################################

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
        if (is.null(labels)) {labels <- rev(labFormat(type = "numeric", cuts))}
        colors <- pal(rev(c(r[1], cuts, r[2])))
        labels <- labels
      }else{
        if (is.null(labels)) {labels <- labFormat(type = "numeric", cuts)}
        colors <- pal(c(r[1], cuts, r[2]))
        labels <- labels
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
        if(is.null(labels)) {labels = rev(labFormat(type = "quantile", cuts, p))}
        labels <- labels
      }else{
        colors <- pal(mids)
        if(is.null(labels)) {labels = labFormat(type = "quantile", cuts, p)}
        labels <- labels
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

nyc = st_read("https://data.cityofnewyork.us/api/geospatial/jgqm-ccbd?method=export&format=GeoJSON") %>%
  st_transform("+proj=longlat +datum=WGS84")

mean_temp = raster('data/input/surfacetemperature_mean_2020_2022.tif')


################################################################################
# prep temp raster 
################################################################################

nyc = st_transform(nyc, projection(mean_temp))

mean_temp = mean_temp %>% crop(nyc) %>% mask(nyc)
mean_temp = mean_temp*0.00341802 + 149 #the scale and offset parameters on GEE
mean_temp = k_to_f(mean_temp)
writeRaster(mean_temp, "data/output/f_mean_temp", 
            format = "GTiff", overwrite = T)

deviation = mean_temp - mean(values(mean_temp), na.rm=T)

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
heat_pal = colorNumeric(colorRamps::matlab.like(15),
                        domain = c(values(deviation_plot), 
                                   # extend domain past so border values aren't NA
                                   min(values(deviation_plot), na.rm=T)-0.1, 
                                   max(values(deviation_plot), na.rm=T)+0.1),
                        na.color = "transparent")

map = leaflet(options = leafletOptions(zoomControl = FALSE, 
                                       minZoom = 10, 
                                       maxZoom = 17)) %>%
  addProviderTiles('CartoDB.Positron', 
                   options = providerTileOptions(minZoom = 10, maxZoom = 17)) %>%
  addRasterImage(deviation_plot, colors = heat_pal, opacity = 0.4) %>% 
  addLegend_decreasing(position = "topleft", 
            pal = heat_pal, 
            values = values(deviation_plot), 
            title = paste0("Temperature Deviation", "<br>", "from Mean"),  
            labels = c("> 8°", "6°", "4°", "2°", "0°", "-2°", 
                       "-4°", "-6°", "< -8°"), 
            decreasing = T)


saveWidget(map, file = file.path("visuals", "summer_heat_deviation_raster.html"))
mapshot(map, file = file.path("visuals", "summer_heat_deviation_raster.png"),
         remove_controls = c("homeButton", "layersControl"), vwidth = 1000, vheight = 850)

################################################################################
# smoothed plot - 1.5 block average
################################################################################

# 9 pixels is about 1 long block, so 27 is about 1.5 blocks in each direction

n = 27
deviation_smooth = focal(deviation, w = matrix(rep(1, n^2), nrow = n), 
                         fun = "mean", na.rm = T, pad = T) %>% mask(nyc)

values(deviation_smooth) = ifelse(values(deviation_smooth) <= -8, -8, values(deviation_smooth))
values(deviation_smooth) = ifelse(values(deviation_smooth) >= 8, 8, values(deviation_smooth))

heat_pal = colorNumeric(colorRamps::matlab.like(15),
                        domain = c(values(deviation_smooth), 
                                   # extend domain past so border values aren't NA
                                   min(values(deviation_smooth), na.rm=T)-0.1, 
                                   max(values(deviation_smooth), na.rm=T)+0.1),
                        na.color = "transparent")

writeRaster(deviation_smooth, "data/output/f_deviation_smooth", 
            format = "GTiff", overwrite = T)

map = leaflet(options = leafletOptions(zoomControl = FALSE, 
                                       minZoom = 10, 
                                       maxZoom = 16)) %>%
  addProviderTiles('CartoDB.Positron', 
                   options = providerTileOptions(minZoom = 10, maxZoom = 16)) %>%
  addRasterImage(deviation_smooth, colors = heat_pal, opacity = 0.4) %>% 
  addLegend_decreasing(position = "topleft", 
                       pal = heat_pal, 
                       values = values(deviation_smooth), 
                       title = paste0("Temperature Deviation", "<br>", "from Mean"),  
                       labels = c("> 8°", "6°", "4°", "2°", "0°", "-2°", 
                                  "-4°", "-6°", "< -8°"), 
                       decreasing = T)


saveWidget(map, file=file.path('visuals', 
                               "summer_heat_smoothed_deviation_raster.html"))
mapshot(map, 
        file = file.path("visuals", "summer_heat_smoothed_deviation_raster.png"),
        remove_controls = c("homeButton", "layersControl"), vwidth = 1000, vheight = 850)
           

################################################################################
# custom smoothed plot - 1.5 block average
################################################################################


map = leaflet(options = leafletOptions(zoomControl = FALSE, 
                                       minZoom = 11, 
                                       maxZoom = 18)) %>%
  addProviderTiles('CartoDB.PositronNoLabels', 
                   options = providerTileOptions(minZoom = 11, maxZoom = 18)) %>%
  addRasterImage(deviation_smooth, colors = heat_pal, opacity = 0.3) %>% 
  addLegend_decreasing(position = "topleft", 
                       pal = heat_pal, 
                       values = values(deviation_smooth), 
                       title = paste0("Temperature Deviation", "<br>", "from Mean"),  
                       labels = c("> 8°", "6°", "4°", "2°", "0°", "-2°", 
                                  "-4°", "-6°", "< -8°"), 
                       decreasing = T) %>%
  addProviderTiles('CartoDB.PositronOnlyLabels', #'Stadia.StamenTonerLabels'/'CartoDB.PositronOnlyLabels'
                   options = providerTileOptions(minNativeZoom=15)) 

saveWidget(map, file=file.path('visuals', 
                               "custom_street_names_summer_heat_smoothed_deviation_raster.html"))
