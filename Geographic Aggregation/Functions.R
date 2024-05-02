## Functions 

# Function to bring in shapefiles
Shapefiles <- function(states) {
  ab2 <- map_df(states, ~ {
    tracts(
      state = .x,
      cb = TRUE,
      keep_zipped_shapefile = TRUE,
      refresh = FALSE
    ) %>%
      select(-c(NAMELSAD, STUSPS, NAMELSADCO, STATE_NAME, ALAND, AWATER)) 
  })
  
  ab2 <- ab2 %>% 
    sf::st_transform(4326) %>%
    ms_simplify(keep = 0.2, keep_shapes = TRUE) 
}

## Function to map aggregation results
Map_Save <- function(filevars, area, aggregatedshp, exclist, gatvars, mergevars) {
  tryCatch({
    ## Calculate GAT Compactness
    aggregatedshp$GATcratio <- calculateGATcompactness(aggregatedshp)
    
    ## Calculate GAT Flag
    area$GATflag <- calculateGATflag(exclist, area)
    exclist$flagsum <- sum(area$GATflag)
    
    ## Map classes
    myclass <- defineGATmapclasses(
      areaold = area,
      areanew = aggregatedshp,
      aggvar = "n",
      breaks = 7
    )
    
    ## Number formatting function
    numformat <- function(num) {
      format(as.numeric(gsub(",", "", num)), big.mark = ",", 
             scientific = FALSE)
    }
    
    ## Empty plot list
    myplots <- list()
    
    ## Plotting functions 
    plot_map <- function(data, title_main, colcode, after = FALSE) {
      plotGATmaps(
        area = data,
        var = "n",
        clr = NULL,
        class = NULL,
        title.main = title_main,
        after = after,
        title.sub = paste(
          "Aggregation values:", 
          numformat(gatvars$minvalue1), 
          "to", 
          numformat(as.numeric(gsub(",", "", gatvars$maxvalue1))), 
          gatvars$aggregator1, 
          "\nExclusion criteria: ", 
          exclist$var1, 
          exclist$math1, 
          numformat(exclist$val1)
        ),
        breaks = NULL, 
        colcode = colcode, 
        mapstats = TRUE,
        ratemap = FALSE,
        closemap = TRUE
      )
    }
    
    myplots$Before_Merging <- plot_map(
      data = area,
      title_main = paste(gatvars$aggregator1, "Before Merging"),
      colcode = myclass$colcode1before
    )
    
    myplots$After_Merging <- plot_map(
      data = aggregatedshp,
      title_main = paste(gatvars$aggregator1, "After Merging"),
      colcode = myclass$colcode1after
    )
    
    ## plot GAT Comparison Map
    myplots$Comparison_Map <- 
      plotGATcompare(
        areaold = area,             
        areanew = aggregatedshp,    
        mergevars = mergevars,      
        gatvars = gatvars,          
        closemap = TRUE
      )
    
    ## Compactness Map
    myplots$Compactness_Map <- 
      plotGATmaps(
        area = aggregatedshp,      
        var = "GATcratio",          
        clr = "YlOrBr",
        title.main = "Compactness Ratio After Merging", 
        title.sub = paste(
          "compactness ratio = area of polygon over", 
          "area of circle with same perimeter \n",
          "1=most compact, 0=least compact"), 
        ratemap = TRUE, 
        closemap = TRUE
      )
    
    
    ## Save maps as combined pdf
    pdf_file <- paste0(filevars$userout, ".pdf")
    pdf(pdf_file, onefile = TRUE, width = 10, height = 7)
    for (myplot in myplots) {
      if (is(myplot, "recordedplot")) 
        replayPlot(myplot)
    }
    dev.off()
    
    message("Maps saved successfully: ", pdf_file)
    
  }, error = function(e) {
    message("Error occurred: ", e$message)
  })
}
