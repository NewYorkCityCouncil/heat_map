# Load dependencies to start
source("code/00_load_dependencies.R")


################################################################################
# load data
################################################################################

# download puma shapefile from Department of Planning
url <- "https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/nypuma2010_23a.zip"
puma_shp <- sf::read_sf(unzip_sf(url)) 

# read in air conditioning data
# downloaded from: https://a816-dohbesp.nyc.gov/IndicatorPublic/beta/data-explorer/climate/?id=2185#display=summary
ac = read_csv("data/input/NYC EH Data Portal - Household air conditioning (full).csv")

# puma_crosswalk made by matching https://www.baruch.cuny.edu/confluence/display/geoportal/NYC+Geographies (NYC PUMAs and Neighborhoods) 
# to Sub-Borough/PUMA names used in the ac data
puma_crosswalk <- read_csv("data/input/puma_crosswalk.csv") %>%
  mutate(PUMA = as.character(PUMA))

################################################################################
# clean and join data
################################################################################

# select 2017 PUMA data
ac <- ac %>%
  filter(Time == "2017", 
         GeoType == "Subboro") %>%
  # create variable of % of households without AC access (100 - % with access)
  mutate(lack_ac = 100 - as.numeric(substr(`Percent (with AC)`, 1, 4))) %>%
  dplyr::select(GeoID, lack_ac)

# join ac data to puma crosswalk for name matching and puma shapefile for polygons 
ac_shp <- ac %>%
  left_join(puma_crosswalk, by = "GeoID") %>%
  left_join(puma_shp, by = "PUMA") %>% 
  st_as_sf() %>%
  st_transform("+proj=longlat +datum=WGS84")


################################################################################
# map data
################################################################################

# right-skewed, so use fisher-jenks natural breaks for palette
nat_intvl_puma = classInt::classIntervals(ac_shp$lack_ac, n = 5, style = 'fisher')

# create palette for map
pal_puma = colorBin(
  palette = c('#d5dded', '#afb9db', '#8996ca', '#6175b8', '#2f56a6'),
  # make sure the full range of data is included in bins of palette
  bins = c(nat_intvl_puma$brks[1]-.1, nat_intvl_puma$brks[2:5], nat_intvl_puma$brks[6]+.1),
  domain = ac_shp$lack_ac, 
  na.color = "Grey"
)

# add labels for when cursor hovers over map
labels <- paste0("<h3>","Households without AC: ", round(ac_shp$lack_ac, 1), "%", sep="", "</h3>",
                "<p>","PUMA: ",ac_shp$Name,"</p>")

# create leaflet map
map <-  leaflet(ac_shp, 
                options = leafletOptions(zoomControl = FALSE, 
                                       minZoom = 10, 
                                       maxZoom = 16)) %>%
  addProviderTiles('CartoDB.Positron', 
                   options = providerTileOptions(minZoom = 10, maxZoom = 16)) %>%
  addPolygons(weight = 1,
              color = "grey",
              stroke = FALSE,
              fillColor = ~pal_puma(ac_shp$lack_ac),
              fillOpacity = 0.9,
              label = lapply(labels,htmltools::HTML)) %>% 
  addLegend(position ="topleft", 
            pal = pal_puma, 
            opacity = 0.9,
            values = ac_shp$lack_ac,
            title =  "Households Without<br>Air Conditioning (%)")

# save html map to visuals folder
withr::with_dir('visuals', saveWidget(map, file="air_conditioning_map.html"))
