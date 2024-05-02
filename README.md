# GAT-for-CIF
This repository contains example code and functions to implement the Geographic Aggregation Tool (GAT) to de-identify clinical trial data and integrate the results into the Cancer InFocus (CIF) R shiny application. De-identification is achieved by merging census tracts using GAT to meet a minimum required value. Data contained within are randomly generated and do not contain any patient information. 

Reviewing the [GAT walkthrough](https://nystracking.github.io/gatpkg/dev/articles/gat_tutorial.html) is strongly encouraged before starting this process.

# Instructions. 
1. Download the repository and change input and output paths accordingly. 
2. Run the Functions script to create the shapefiles and Map_Save functions. 
3. Run the SHAPER script to walk through an example of using GAT to de-identify data. 
4. Review results saved to the Output and www folders
5. Change the SHAPER script paths and inputs to de-identify other data.

For any questions regarding the code or process, please email Daniel Antonio at daniel.antonio@northwestern.edu.

# Citations

Justin Todd Burus, Lee Park, Caree R. McAfee, Natalie P. Wilhite, Pamela C. Hull; Cancer InFocus: Tools for Cancer Center Catchment Area Geographic Data Collection and Visualization. Cancer Epidemiol Biomarkers Prev 2023; https://doi.org/10.1158/1055-9965.EPI-22-1319, 
https://cancerinfocus.uky.edu/about/

Stamm A, Babcock G (2023). gatpkg: Geographic Aggregation Tool (GAT). R package version 2.0.0, https://github.com/nystracking/gatpkg.
