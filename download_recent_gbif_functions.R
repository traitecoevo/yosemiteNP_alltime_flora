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

# Function to filter data within KML-defined boundaries
geo_filter <- function(gbif_data, kml) {
  
  kml_multilines <- st_cast(kml, "MULTILINESTRING")
  if (!st_is_valid(kml_multilines)) {
    kml_multilines <- st_make_valid(kml_multilines)  # Attempt to fix invalid geometry
  }
  kml_p <- st_polygonize(kml_multilines)
  kml_p <- st_collection_extract(kml_p, "POLYGON")
  
  gbif_data <- dplyr::filter(gbif_data, !is.na(decimalLatitude))
  
  df_sf <- st_as_sf(
    gbif_data,
    coords = c("decimalLongitude", "decimalLatitude"),
    crs = st_crs(kml_p)
  )
  gbif_data$inside_kml <- st_within(df_sf, kml_p, sparse = FALSE) #not working!!!!!!!
  gbif_data_inside <- dplyr::filter(gbif_data, inside_kml)
  gbif_data_inside_ss<-dplyr::filter(gbif_data,coordinateUncertaintyInMeters<5000)
  return(gbif_data_inside_ss)
}
