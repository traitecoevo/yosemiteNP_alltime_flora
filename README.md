
<!-- README.md is generated from README.Rmd. Please edit that file -->

# A dynamic lookup to help curate the “all time” plant species list for Royal National Park, NSW, Australia

Versioned data for the “all time” flora of Royal National Park, NSW,
Australia. The R script checks the ALA for species that are candidates
for new discoveries since the list was created and prints out the list
of those candidates for new discoveries. These new discoveries may arise
from new collections at herbaria or from citizen scientists.

Note that some of these “new” species arise from the different rates of
taxonomic updates in the different data resources. These need manual
curation before adding new species to the all-time list.

### First load some libraries and helper functions:

``` r
source("download_recent_gbif_functions.R")
```

### Then there are a few steps to the process:

1.  Download the 2024 or later data from ALA

``` r
yos_kml <- st_read("Yosemite.kml",)
```

    ## Reading layer `WildernessBoundary' from data source 
    ##   `/Users/z3484779/Documents/yosemiteNP_alltime_flora/Yosemite.kml' 
    ##   using driver `KML'
    ## Simple feature collection with 1 feature and 2 fields
    ## Geometry type: LINESTRING
    ## Dimension:     XY
    ## Bounding box:  xmin: -119.8863 ymin: 37.49221 xmax: -119.1995 ymax: 38.18646
    ## Geodetic CRS:  WGS 84

``` r
yos_obs <- download_observations_bbox(
  "Yosemite.kml", start_year = 2024)
yos_only_obs <- geo_filter(yos_obs, yos_kml)
```

    ## Warning: Using one column matrices in `filter()` was deprecated in dplyr 1.1.0.
    ## ℹ Please use one dimensional logical vectors instead.
    ## This warning is displayed once every 8 hours.
    ## Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
    ## generated.

``` r
yos_only_obs_minus<-dplyr::filter(yos_only_obs,coordinateUncertaintyInMeters<5000)%>%
  dplyr::filter(phylum=="Tracheophyta")
```

2.  trying to wrangle taxonomy to APC for both lists, using the APCalign
    package

``` r
# resources <- APCalign::load_taxonomic_resources(quiet = TRUE)
# accepted_new_names <- APCalign::create_taxonomic_update_lookup(
#   unique(royal_only_obs$species, resources = resources, quiet = TRUE))
 alltime_org <- read.csv("Yosemite_masterlist_2024_06_15.csv")
# alltime <- APCalign::create_taxonomic_update_lookup(
#   unique(alltime_org$accepted_name), resources = resources, quiet = TRUE)
# putative_new_species <- stringr::word(
#   unique(accepted_new_names$accepted_name), 1, 2)
```

3.  figure out new names that appeared in 2024 (or later) that are not
    in the all time list

``` r
#gbif gives taxonomic names per obs, so checking both currently to see if either is on the all time list; this is a bit hacky but empirically seems to work better than using TNRS 
new_discoveries1 <- setdiff(unique(yos_only_obs_minus$species), 
                           unique(alltime_org$accepted_name))

new_discoveries2 <- setdiff(word(unique(yos_only_obs_minus$scientificName),1,2), 
                           unique(alltime_org$accepted_name))

new_discoveries<-intersect(new_discoveries1,new_discoveries2)
```

4.  calculate number of 2024 or later observations for the set of
    potentially new species, to help evaluate the candidate list.

``` r
new_discoveries<-data.frame(species=new_discoveries)

yos_only_obs %>% 
  group_by(species) %>% 
  summarize(number_of_recent_obs = n()) %>% 
  right_join(new_discoveries) %>% 
  filter(!is.na(species)) %>%
  print(n = Inf)
```

    ## Joining with `by = join_by(species)`

    ## Simple feature collection with 7 features and 2 fields
    ## Geometry type: GEOMETRY
    ## Dimension:     XY
    ## Bounding box:  xmin: -119.8604 ymin: 37.50503 xmax: -119.3741 ymax: 38.04865
    ## Geodetic CRS:  WGS 84
    ## # A tibble: 7 × 3
    ##   species                 number_of_recent_obs                          geometry
    ## * <chr>                                  <int>                    <GEOMETRY [°]>
    ## 1 Asclepias eriocarpa                        1        POINT (-119.6407 37.54668)
    ## 2 Jasminum nudiflorum                        1        POINT (-119.5883 37.75171)
    ## 3 Lupinus polyphyllus                        1        POINT (-119.6467 37.53971)
    ## 4 Phlox subulata                             1        POINT (-119.7511 37.69822)
    ## 5 Pteridium aquilinum                       44 MULTIPOINT ((-119.3741 37.87156)…
    ## 6 Salvia greggii                             1         POINT (-119.587 37.74829)
    ## 7 Symphyotrichum chilense                    1        POINT (-119.6275 37.56025)

The Yosemite NP plant species list currently contains 1633 species and
this analysis suggests XX candidates for addition found in 2024.
