install.packages("z22", repos = c('https://jslth.r-universe.dev', 'https://cloud.r-project.org'))
install.packages("tzdb")

library(z22)
library(terra)
library(tzdb)
library(dplyr)

themes_2022_100m <- c(
  # Population
  "population",
  "citizens",
  "foreigners",
  "foreigners_from_18",
  "birth_country",
  "citizenship",
  "citizenship_group",
  "age_avg",
  "age_short",
  "age_long",
  "age_under_18",
  "age_from_65",
  "marital_status",
  
  # Families
  "families",
  "family_type",
  
  # Households
  "households",
  "household_size_avg",
  "household_size_group",
  
  # Dwellings
  "dwellings",
  "rent_avg",
  "owner_occupier",
  "vacancies",
  "market_vacancies",
  "inhabitant_space",
  "dwelling_space",
  "floor_space",
  "dwelling_rooms",
  "dwelling_building_size",
  "dwelling_heat_type",
  "dwelling_heat_src",
  
  # Buildings
  "buildings",
  "building_constr_year",
  "building_dwellings",
  "building_size",
  "building_heat_type",
  "building_heat_src"
)


output_dir <- "C:/Users/agz90fk/Documents/Masterarbeit/03_Daten/Output/Census/Census2022_100m"
dir.create(output_dir, showWarnings = FALSE)

for (th in themes_2022_100m) {
  message("Lade: ", th)
  
  try({
    r <- z22_data(
      th,              # ← HIER ist der Fix
      year = 2022,
      res  = "100m",
      as   = "raster"
    )
    
    writeRaster(
      r,
      filename = file.path(output_dir, paste0(th, ".tif")),
      overwrite = TRUE
    )
  })
}
