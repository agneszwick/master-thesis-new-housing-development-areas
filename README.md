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

# Workflow
