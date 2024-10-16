suppressPackageStartupMessages(library(sf))
suppressPackageStartupMessages(library(rgbif))
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(APCalign))
suppressPackageStartupMessages(library(tidyverse, warn.conflicts = FALSE))

# Define the function for querying GBIF data with geographic and temporal filters
query_gbif <- function(taxon="Plantae", datayear=2024, wkt_bbox = NULL) {
  # Set up the taxon key for the specified taxon group
  taxon_key <- name_backbone(name = taxon)$usageKey
  
  # Define the search parameters for GBIF, including WKT filter
  occurrence_data <- occ_search(
    taxonKey = taxon_key,
    hasCoordinate = TRUE,
    year = datayear,
    geometry = wkt_bbox,
    limit = 20000 # adjust limit as needed
  )
  
  return(occurrence_data$data)
}

# Function to download observations within a bounding box from a KML file
download_observations_bbox <- function(kml_file_path, start_year) {
  area <- sf::st_read(kml_file_path, quiet = TRUE)
  bbox <- sf::st_bbox(area)
  
  # Convert bbox to WKT format for GBIF spatial query
  wkt_bbox <- paste(
    "POLYGON((",
    bbox["xmin"],
    bbox["ymin"],
    ",",
    bbox["xmin"],
    bbox["ymax"],
    ",",
    bbox["xmax"],
    bbox["ymax"],
    ",",
    bbox["xmax"],
    bbox["ymin"],
    ",",
    bbox["xmin"],
    bbox["ymin"],
    "))"
  )
  
  # Query GBIF data within the specified spatial and temporal constraints
  download <- query_gbif(datayear = start_year, wkt_bbox=wkt_bbox)
  
  # Remove records with high coordinate uncertainty
  #download <- download %>%
  #  filter(is.na(coordinateUncertaintyInMeters) | coordinateUncertaintyInMeters <= 1000)
  
  return(download)
}


geo_filter<-function(yos_obs,yos_kml){
  yos_obs_sf <- st_as_sf(yos_obs,
                         coords = c("decimalLongitude", "decimalLatitude"),
                         crs = 4326) # WGS 84 CRS, commonly used for geographic coordinates
yos_multilines <- st_cast(yos_kml, "MULTILINESTRING")
yos_poly <- st_polygonize(yos_multilines)
within_polygon <- st_within(yos_obs_sf, yos_poly, sparse = FALSE)
sum(within_polygon)
yos_obs_sf$within_polygon<-within_polygon
out<-dplyr::filter(yos_obs_sf,within_polygon)

# library(ggplot2)
# ggplot() +
# geom_sf(data = yos_poly, fill = NA, color = "blue") +
# geom_sf(data = yos_obs_sf, aes(color = within_polygon), size = 1) +
# labs(color = "Within Polygon")
return(out)
}
