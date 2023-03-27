## Load Libraries -----------------------------------------------

#' NOTE: The code below is intended to load all listed libraries. If you do not
#' have these libraries on your computer, the code will attempt to INSTALL them.
#' 
#' IF YOU DO NOT WANT TO INSTALL ANY OF THESE PACKAGES, DO NOT RUN THIS CODE.

list.of.packages <- c("tidyverse", "raster", "sf", "leaflet", "XML", 
                      "methods", "rgdal", "ggplot2", "htmlwidgets", 
                      "exactextractr", "terra", "colorRamps", "spatialEco", 
                      "RColorBrewer", "SpaDES.tools", "mapview")

options(scipen = 999)

# checks if packages has been previously installed
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]

# if not, packages are installed
if(length(new.packages)) install.packages(new.packages)

# packages are loaded
lapply(list.of.packages, require, character.only = TRUE)

#devtools::install_version("velox", version = "0.2.0") 
#library(velox)

# function to unzip shapefiles
unzip_sf <- function(zip_url) {
  temp <- tempfile()
  temp2 <- tempfile()
  #download the zip folder from the internet save to 'temp' 
  download.file(zip_url, temp)
  #unzip the contents in 'temp' and save unzipped content in 'temp2'
  unzip(zipfile = temp, exdir = temp2)
  #if returns "character(0), then .shp may be nested within the folder
  your_SHP_file <- ifelse(!identical(list.files(temp2, pattern = ".shp$",full.names=TRUE), character(0)), 
                          list.files(temp2, pattern = ".shp$",full.names=TRUE), 
                          list.files(list.files(temp2, full.names=TRUE), pattern = ".shp$", full.names = TRUE))
  unlist(temp)
  unlist(temp2)
  return(your_SHP_file)
}

# Function to Convert Kelvin to Fahrenheit
k_to_f <- function(temp) { fahrenheight <- ((temp - 273) * (9/5)) + 32  }

temp_func_2 <-function(rastername) {
  rstr <- terra::rast(rastername)
  sf <- st_transform(shapes, crs(rastername))
  mean_temp <- paste0('mean_temp')
  max_temp <- paste0('max_temp')
  min_temp <- paste0('min_temp')
  sf[,mean_temp] <- sapply(exact_extract(rstr, sf, 'mean')/10, k_to_f)
  sf[,max_temp] <- sapply(exact_extract(rstr, sf, 'max')/10, k_to_f)
  sf[,min_temp] <- sapply(exact_extract(rstr, sf, 'min')/10, k_to_f)
  sf
}

# remove created variables for packages
rm(list.of.packages, new.packages)
