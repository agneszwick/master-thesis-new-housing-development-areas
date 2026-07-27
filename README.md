# master-thesis-new-housing-development-areas

# Topic
This project develops a reproducible workflow to identify new housing development areas (NHDAs) across Bavaria from publicly available 3D building data. Construction start years were estimated using a Random Forest model based on Sentinel-2 NDVI time series, and spatially matched reference areas were generated for each development. Environmental conditions (NDVI, Land Surface Temperature), urban morphology, and spatial context were analysed for both areas, and the influence of development characteristics on environmental outcomes was assessed using linear mixed-effects models (LMMs) and exploratory generalized additive models (GAMs).

# Input Data
## Environmental Data: 
- Sentinel-2 L3: https://geoservice.dlr.de/data-assets/4hcq6dgkj648.html
- Landsat LST: https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_LC08_C02_T1_L2?hl=de

## Settlement Data
- 3D Building Model: https://geodaten.bayern.de/opengeodata/OpenDataDetail.html?pn=lod2
- Administrative Regions: https://gdz.bkg.bund.de/index.php/default/verwaltungsgebiete-1-250-000-mit-einwohnerzahlen-stand-31-12-vg250-ew-31-12.html
- ATKIS: https://geodaten.bayern.de/opengeodata/OpenDataDetail.html?pn=atkis_basis_dlm
- World Settlement Footprint: https://geoservice.dlr.de/data-assets/6n5h1ezef920.html
## Auxiliary Data
- Landcover: https://gdz.bkg.bund.de/index.php/default/digitale-geodaten/digitale-landschaftsmodelle/corine-land-cover-5-ha-stand-2012-clc5-2012.html (2012), https://gdz.bkg.bund.de/index.php/default/digitale-geodaten/digitale-landschaftsmodelle/digitales-landbedeckungsmodell-deutschland-stand-2021-lbm-de.htm (2021)
- Degree of Urbanisation: https://ec.europa.eu/eurostat/web/gisco/geodata/population-distribution/degree-urbanisation
- Census: Lieth J (2026). z22: Official Gridded Data from the German Census 2022. doi:10.32614/CRAN.package.z22. https://github.com/jslth/z22/.
- Natura-2000: https://www.stmuv.bayern.de/themen/naturschutz/schutzgebiete/natura2000/index.htm


# Workflow

This repository contains the complete workflow used to identify, characterize, and analyse New Housing Development Areas (NHDAs) in Bavaria.

---

## 1. Preprocessing (`01_Preprocessing`)

### 1.1 3D Building Model (`01_3D_Building_Model`)

`01_bulk_download.ipynb`  
Download Bavarian LoD2 (2025) building model from the Bavarian Open Data portal.

`02_gml_to_gpkg.ipynb`  
Convert downloaded CityGML files to GeoPackage format.

`03_merge_gpkg.ipynb`  
Merge individual GeoPackages into statewide datasets.

`04_classify_LoD2_buildings.ipynb`  
Assign building function classes to LoD2 buildings.

`05_residential_subclassification.ipynb`  
Subclassify residential buildings into residential building types.

`06_detect_new_buildings.ipynb`  
Identify buildings constructed between 2015 and 2025 by comparing LoD1 and LoD2 datasets.

`07_accuracy_assessment_residential_subtypes.ipynb`  
Assess the accuracy of the residential building subtype classification.

---

### 1.2 Environmental Data (`02_Environmental_Data`)

**Note:** Sentinel-2 processing was performed on the LRZ Terrabyte platform, while Landsat 8/9 processing was carried out using Google Earth Engine.

`01_Sentinel_NDVI.ipynb`  
Generate annual Sentinel-2 NDVI composites.

`02_Landsat_LST.txt`  
Google Earth Engine script to generate annual Landsat 8/9 Land Surface Temperature (LST) composites.

---

### 1.3 Additional (`03_Additional`)

`01_Download_Census_data.R`  
Download 2022 German Census data.

`02_CORINE_preprocessing.ipynb`  
Preprocess CORINE Land Cover data.

---

## 2. Detection of New Housing Development Areas (`02_NHDA_Detection`)

`00_filter_ATKIS.ipynb`  
Prepare residential settlement areas from ATKIS.

`01_NHDA_min_1_new_building.ipynb`  
Generate candidate NHDAs containing at least one newly constructed residential building.

`02a_threshold_ratio_old_vs_new.ipynb`  
Evaluate the ratio of existing to new buildings within candidate areas.

`02b_NHDA_ratio_old_vs_new.ipynb`  
Filter candidate areas based on the selected building ratio threshold.

`03_classify_dominant_building_type.ipynb`  
Assign the dominant residential building type to each NHDA.

`04a_threshold_WSF_coverage.ipynb`  
Evaluate World Settlement Footprint (WSF) coverage to remove false-positive development areas.

---

## 3. Construction Start Time Estimation (`03_Construction_Start_Estimation`)

`00_random_nhda_for_trainingsdata.ipynb`  
Select a random sample of NHDAs for manual construction year annotation.

`01_random_forest_based_on_trainingsdata.ipynb`  
Train and optimize the Random Forest model using manually labelled training data.

`02_apply_random_forest_model.ipynb`  
Apply the trained Random Forest model to estimate the construction start year for all NHDAs.

`03_accuracy_assessment.ipynb`  
Assess the accuracy of the construction start year estimation using an independent validation dataset.

---

## 4. Definition of Reference Areas (04_Reference_Area)

`01_detect_reference_area.ipynb`  
For each NHDA, identifies a nearby reference area (RA) within ATKIS residential settlement polygons (classes 41001 and 41006). Reference areas are matched to the NHDA in area (±20%) and must have a new-to-total building footprint ratio of ≤0.1, ensuring that at least 90% of the building footprint area consists of pre-existing buildings.

`02_sensitivity_analysis_RA.ipynb`  
Evaluates how the distance between each NHDA and its matched reference area influences the environmental comparison by assessing changes in the environmental indicators across different search radii.

---
## 5. Comparison NHDA vs. RA (`05_Comparison_NHDA_RA`)

`01_comparison_LST.ipynb`  
Calculate annual summer Land Surface Temperature (LST) statistics for each NHDA and its corresponding reference area.

`02_comparison_NDVI.ipynb`  
Calculate annual growing-season NDVI statistics for each NHDA and its corresponding reference area.

`03_merge_LST_and_NDVI.ipynb`  
Merge the annual LST and NDVI comparison datasets into a single GeoPackage.

`04_NHDA_RA_with_DEGURBA.ipynb`  
Assign the DEGURBA class to each NHDA and reference area.

`05_NHDA_RA_with_CLC.ipynb`  
Assign the dominant CORINE Land Cover (CLC) class within the surrounding buffer of each NHDA and reference area.

`06_NHDA_RA_LoD2.ipynb`  
Calculate urban morphology metrics (e.g. building density, building height, building footprint, built-up ratio and building volume density) for each NHDA and reference area using the LoD2 building model.

`07_NHDA_RA_BuildingStructure_Difference.ipynb`  
Calculate difference in residential building type share and calculate relative differences of the urban morphology metrics.

`08_NHDA_RA_Census.ipynb`  
Calculate population density in NHDA and RA and dominant heating source.

`09_analyze_LST_NDVI_pre_post_construction.ipynb`  
annual pre- and post-construction environmental indicators relative to the estimated construction start year.

---

## 6. Statistical Analysis of Urban Morphology–Environment Relationships (`06_Statistical_Analysis`)

*Scripts for exploratory data analysis (EDA), correlation analyses, linear mixed-effects models (LMMs), generalized additive models (GAMs), and causal mediation analysis.*
