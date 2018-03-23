#----------------------------------------------------------------------------------------------#

# authors: Irene Celino, Gloria Re Calegari
# copyright: CEFRIEL, http://www.cefriel.com
# license: Apache 2.0, http://www.apache.org/licenses/LICENSE-2.0


# Set of functions for getting data from OpenStreetMap

#----------------------------------------------------------------------------------------------#
# 1) utility to load an R package and install it if not already installed
loadRPackage <- function(package.name = "utils") {
  
  # if already installed, simply load
  installed <- require(package.name, character.only=T)
  
  # if not installed, install and load
  if(!installed){
    install.packages(package.name, dependencies = TRUE)
    require(package.name, character.only=T)
  }
  
}

#----------------------------------------------------------------------------------------------#
# 2) utility to load the R packages used in the other methods
loadRequiredPackages <- function() {
  loadRPackage("rgdal") # to read geo files like geojson or shapes
  loadRPackage("RCurl")
  loadRPackage("osmar")
  loadRPackage("rgeos")  
  
}

#----------------------------------------------------------------------------
# 3) query to obtain a list of nodes with key-value amenity :restaurant in a bounding box 
# with output in .csv format
getNodeRestaurantOverpassQueryCSV <- function(coords=NULL, swne=c(), columns=c()){
  if(is.null(coords)){
    bbox.string = paste(swne, collapse=",")
    query <- paste0("[out:csv(", columns, ")];node[amenity=restaurant](", bbox.string, "); out;")
  }else{
    coords = t(coords[,2:1])
    bounds.string = paste(coords, collapse = " ")
    query <- paste0("[out:csv(", columns, ")];node[amenity=restaurant](poly:\"", bounds.string, "\"); out;")
  }
  return(query)
}


#----------------------------------------------------------------------------------------------#
# 4) execute the query on OpenStreetMap and save the response in the output.file
getOsmData <- function(query.string = "node(2669129148);out;",
                       output.file = "output-file.osm",
                       slowdown = FALSE){
  
  # build query request 
  overpass.api <- "http://overpass.osm.rambler.ru/cgi/interpreter?data="
  encoded.query <- URLencode(query.string)
  overpass.url <- paste0(overpass.api, encoded.query)
  
  # execute query and save result 
  overpass.response <- getURL(overpass.url, async = !slowdown)
  write(overpass.response, output.file)
  
}
