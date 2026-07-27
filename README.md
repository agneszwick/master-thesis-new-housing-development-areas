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
## 1. Preprocessing (01_Preprocessing)
### 1.1 3D- Building Model (01_3D_building model)
`01_bulk_download.ipynb`

`02_gml_to_gpkg.ipynb`


## 2. Detection of New Housing Development Areas
## 3. Construction Start Time Estimation
## 4. Definition of Reference Areas
## 5. Assignment of Contextual Variables
## 6. Statistical Analysis of Urban Morphology-Environment Relationships
