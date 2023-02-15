### Landsat Air Correlation 

# Load dependencies to start
source("code/00_load_dependencies.R")


# Air Temps ---------------------------------------------------------------
# Load temperature data for Central Park and LaGuardia

# Central Park
cp_raw <- read_csv("data/input/raw/Ground_Monitor_Temps_NYC/central_park_temp.csv") %>% 
  janitor::clean_names() %>% 
  dplyr::select(station, date, hourly_dry_bulb_temperature) %>% 
  mutate(name = "Central Park")

cp_raw <- cp_raw %>% 
  filter(!is.na(date))

# LaGuardia
lag_raw <- read_csv("data/input/raw/Ground_Monitor_Temps_NYC/laguardia_temp.csv") %>% 
  janitor::clean_names() %>% 
  dplyr::select(station, date, hourly_dry_bulb_temperature) %>% 
  mutate(name = "La Guardia Airport")

lag_raw <- lag_raw %>% 
  filter(!is.na(date))




# Geometry ----------------------------------------------------------------
# Load spatial polygons for LaGuardia and Central Park from OpenData

# LaGuardia
# source: https://data.cityofnewyork.us/City-Government/Airport-Polygon/xfhz-rhsk

lag_shape <- read_sf("https://data.cityofnewyork.us/api/geospatial/xfhz-rhsk?method=export&format=GeoJSON") %>% 
  filter(name == "La Guardia Airport") %>% 
  dplyr::select(name, geometry)


# Central Park
# source: https://nycopendata.socrata.com/Recreation/Parks-Properties/enfh-gkve

cp_shape <- read_sf("https://nycopendata.socrata.com/api/geospatial/enfh-gkve?method=export&format=GeoJSON") %>% 
  filter(signname == "Central Park") %>% 
  dplyr::select(signname, geometry) %>% 
  rename(name = signname)

shapes <- rbind(lag_shape, cp_shape)



# Landsat Temps -------------------------------------------------------------
# load in all raster files and apply the temp func to get mean, max and min temperatures
# within the sf geometry

filenames <- list.files("data/input/raw/landsat_final_used_values/", pattern="*.tif", full.names=TRUE)
ldf_r <- lapply(filenames, raster)
res <- lapply(ldf_r, temp_func_2)

#pull out just the date for the names of each dataframe
dataset_names <- str_extract(str_extract(filenames, pattern ="029007_[0-9]*"), pattern = "_[0-9]*")

# name the dataframes in the list
names(res) <- dataset_names

#join listed dataframes into single dataframe
raster_shape <- bind_rows(res, .id = "column_label") %>% 
  mutate(date = lubridate::ymd(str_replace(column_label, "_", ""))) %>% 
  # a lot of values are coming up as n/a - every third value, in fact.
  # After looking at the raster images themselves, I believe it's because, while
  # they are categorized under NYC, the satelite doesn't actually pass over much 
  # of the city, if any. But they still count it as a NYC file. These will be 
  # removed from the analysis
  filter(!is.na(max_temp))



# XML Cloud Cover Extraction ----------------------------------------------

# Read in all xmlfiles, and use TreeParse to separate the files into subsettable parts
xmlfilenames <- list.files("data/input/raw/landsat_xml", pattern="*.xml", full.names=TRUE)
xmldf <- lapply(xmlfilenames, xmlTreeParse)
xmldf <- lapply(xmldf, xmlRoot)


# Extract date and cloud cover information
cloud_list <- list()
for (i in 1:length(xmldf)) {
  date <- xmlValue(xmldf[[i]][["tile_metadata"]][["global_metadata"]][["acquisition_date"]])
  tmp <- list(cloud_cover = xmlValue(xmldf[[i]][["tile_metadata"]][["global_metadata"]][["cloud_cover"]]))
  cloud_list[[date]] <- tmp
}

#transform to dataframe so we can join it with the raster dataframe
cloud_data  <-  as.data.frame(x = list(
  date = ymd(names(cloud_list)), 
  cloud_cover = as.numeric(matrix(unlist(cloud_list)))), 
  stringsAsFactors = FALSE)


#' This allows us to see which raster files both cover New York effectively 
#' (and therefore have valid raster values), and which have reasonably low 
#' cloud coverage, which, based on a discussion with a NASA-affiliated expert, 
#' we'll at below 10. Also based on this discussion, we'll attempt to limit
#' what data we actually use to the last year or two, if possible.
raster_with_metadata <- left_join(cloud_data, raster_shape) %>% 
  filter(cloud_cover < 10,
         !is.na(mean_temp))




# Usage Conclusion --------------------------------------------------------

#' will use 9/22/2019, 8/30/2019 and possibly 7/10/2018 for mapping. See notes
#' at top section of 02_mapping_rasters for reasoning.




# Prepare Air Temps for Join ----------------------------------------------

## Aggregate the air temps by day
cp_dates <- cp_raw %>%  
  filter(!is.na(hourly_dry_bulb_temperature),
         format(date,format='%Y-%m-%d') %in% as.character(raster_shape$date),
         as.POSIXct(format(date,format='%H:%M:%S'), format = "%H:%M:%S")
         %within%
             interval(
               as.POSIXct(paste0(today("EST"), "15:00:00"), 
                          format = "%Y-%m-%d %H:%M:%S", tz = "EST"), 
               as.POSIXct(paste0(today("EST"), "16:00:00"), 
                          format = "%Y-%m-%d %H:%M:%S", tz = "EST")))
                                                                       
  
cp_avg <- aggregate(list(avg_ground_temp = cp_dates$hourly_dry_bulb_temperature),
                    by = list(date = as.POSIXct(format(cp_dates$date,format='%Y-%m-%d')),
                              name = cp_dates$name),
                    function(x) {round(mean(x),0)})



lag_dates <- lag_raw %>%  
  filter(!is.na(hourly_dry_bulb_temperature),
         format(date,format='%Y-%m-%d') %in% as.character(raster_shape$date),
         as.POSIXct(format(date,format='%H:%M:%S'), format = "%H:%M:%S")
         %within%
           interval(
             as.POSIXct(paste0(today("EST"), "15:00:00"), 
                        format = "%Y-%m-%d %H:%M:%S", tz = "EST"), 
             as.POSIXct(paste0(today("EST"), "16:00:00"), 
                        format = "%Y-%m-%d %H:%M:%S", tz = "EST")))

lag_avg <- aggregate(list(avg_ground_temp = lag_dates$hourly_dry_bulb_temperature),
                    by = list(date = as.POSIXct(format(lag_dates$date,format='%Y-%m-%d')),
                              name = lag_dates$name),
                    function(x) {round(mean(x),0)})

air_avg <- bind_rows(cp_avg, lag_avg) %>%
  mutate(date = (ymd(date)))

shape_temps <- dplyr::left_join(air_avg, raster_shape) %>% 
  mutate(colum_label = NULL)

