# Aggregation for clinical Trial Accrual Data with Cancer InFocus Integration -----
# More information about gatpgk can be found https://nystracking.github.io/gatpkg/dev/index.html
library(tidyverse)
library(readxl)
library(sf)
library(tigris)
library(rmapshaper)
library(gatpkg)
library(utils)

# Define input and output paths
input_path <- "C:/Users/teh6043/Geographic Aggregation/Data/cto.csv"
output_path <- "C:/Users/teh6043/Geographic Aggregation/Data/Output/"
output_file <- "aggregated_sf"
user_output <- paste0(output_path, output_file)

## Step 1. load data and shapefiles ----

### Read input data ----
input_data = read.csv(paste0(input_path),
                 colClasses = c("FIPS" = "character"),
                 header = T) %>%
  mutate(n = as.numeric(n), 
         pop = as.numeric(pop))

states <- "Illinois"

shapefiles <- Shapefiles(states)

### Join  input data with shapefiles ----
input_sf <- input_data %>%
  left_join(shapefiles, by = c("FIPS" = "GEOID")) %>%
  st_as_sf() 

## Step 2. Define GAT Inputs ----

### Selects the unique geographic variable that will be aggregated, boundaries, minimum and maximum values, and population weighting options
gatvars <- list(
  myidvar = "FIPS",             # Unique Geographic Identifier, source: input_sf
  boundary = "COUNTYFP",        # Aggregation will be done within this boundary, source: input_sf 
  rigidbound = FALSE,           # If TRUE will enforce boundaries even if area total will be less than desired minimum
  aggregator1 = "n",            # Aggregation variable, source: input_sf 
  minvalue1 = 20,               # Minimum required value for first aggregation variable
  maxvalue1 = sum(input_sf$n),  # Max required value for first aggregation variable
  aggregator2 = "NONE",         # If not "NONE", define minvalue2 & maxvalue2
  popwt = FALSE,                # If TRUE selects population-weighted aggregation method
  popvar = "NONE",              # Population weights variable, source: a shapefile with population values
  numrow = nrow(input_sf),      # Counts the number of input_sf areas
  savekml = FALSE               # Saves a KML file
)

### Selects the type of aggregation that will be performed
mergevars <- list(
  mergeopt1 = "least",          # Can be similar, closest, or least
  similar1 = "NONE",            # Used for merging neighbor with most similar ratio, source: input_sf
  similar2 = "NONE",            # Used for merging neighbor with most similar ratio, source: input_sf
  centroid = "geographic"       # population-weighted or geographic
)

### Create new rate variable
ratevars <- list(
  ratename = "rate",            # Name of rate to be calculated, no_rate will ignore rate calculation
  multiplier = 10000,           # Rate multiplier (ex. per 100,000 people)
  numerator = "n",              # Numerator for rate calculation, source: input_sf
  denominator = "pop"           # Denominator for rate calculation, source: input_sf
)

### Identifies any areas that are to be excluded from the aggregation process
exclist <- list(
  var1 = "n",                   # Defines areas excluded from aggregation process, source: input_sf
  math1 = "equals",             # Conditional, can be equals, less than, or greater than
  val1 = 0,                     # Any area where n = 0 will be excluded from aggregation
  var2 = "NONE",                # If not "NONE", define math2 & val2
  var3 = "NONE"                 # If not "NONE", define math3 & val3
)

## Step 3. Perform GAT Aggregation ----

### Sets Settings for output log ----
mysettings <- list(
  version = utils::packageDescription("gatpkg")$Version, 
  pkgdate = utils::packageDescription("gatpkg")$Date, 
  adjacent = TRUE, pwrepeat = FALSE, minfirst = TRUE, 
  limitdenom = FALSE, starttime = Sys.time(), quit = FALSE, exists = FALSE
)

### Merge Function ----
aggvars <- defineGATmerge(
  area = input_sf,              # Shapefile to be aggregated
  pop = NULL,                   # Shapefile that contains population values for population weighted
  progressbar = TRUE,           # Shows progress of merging process
  gatvars = gatvars,            # Aggregation parameters
  mergevars = mergevars,        # Aggregation type
  exclist = exclist             # Exclusion criteria
)

### Aggregated Shapefile ----
aggregatedshp <- mergeGATareas(
  ratevars = ratevars,          # Rate information
  aggvars = aggvars,            # Results from the merge function
  idvar = "GATid",              # Identifier variable from aggvars 
  myshp = input_sf              # The original shapefile used in the merging process
)

## Step 4. Save Aggregation output ----

### Save paths ----
filevars <- list(
  filein = input_sf,            # input_sf file 
  userout = user_output,        # save aggregated file path and name
  pathout = output_path,        # save aggregated path name
  fileout = output_file         # save aggregated file name
)

### Save settings ----
save(file = paste0(output_path, "settings.Rdata"), 
     list = c("gatvars", 
              "aggvars", 
              "filevars",
              "mergevars", 
              "ratevars", 
              "exclist", 
              "mysettings"))

### Save aggregatedshp ----
sf::st_write(aggregatedshp, output_path, output_file,
             driver = "ESRI Shapefile", overwrite_layer = TRUE, 
             append = FALSE)

## Save GAT log of the aggregation process ----
writeGATlog(
  gatvars = gatvars, 
  aggvars = aggvars, 
  filevars = filevars, 
  mysettings = mysettings, 
  area = input_data, 
  mergevars = mergevars,
  ratevars = ratevars, 
  exclist = exclist, 
  settingsfile = NULL
)

## Step 5. Map Results ----
Map_Save(filevars, 
         area = input_sf, 
         aggregatedshp,
         exclist, 
         gatvars, 
         mergevars)

## Step 6. CIF Post-Processing ----
aggregatedshp <- aggregatedshp %>%
  select(STATEFP:NAME, FIPS, Tract, County, value = rate) %>%
  mutate(Tract = paste("Census Tract", NAME), 
         value = round(value, 1), 
         cat = "Clinical Trials (Rate per 10K)",
         State = "Illinois", 
         measure = "Clinical Trial Accruals", 
         def = "Accruals",
         year = 2023,
         fmt = "int",
         source = "NM Accruals, 2018-2023", 
         lbl = case_when(
           fmt == "pct" ~ paste0(round(value, 1), "%"),
           fmt == "int" ~ prettyNum(value, big.mark=",")), 
         Sex = NA, 
         RE = NA) 

## Step. 7. write CIF friendly shapefiles ----
st_write(aggregatedshp, "C:/Users/teh6043/Geographic Aggregation//Data/www/aggregated_sf.shp", append = F)
