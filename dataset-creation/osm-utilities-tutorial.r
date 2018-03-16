# utility functions for getting data from openstreetmap

#----------------------------------------------------------------------------------------------#

# authors: Irene Celino, Gloria Re Calegari
# copyright: CEFRIEL, http://www.cefriel.com
# license: Apache 2.0, http://www.apache.org/licenses/LICENSE-2.0


#----------------------------------------------------------------------------------------------#
# utility to load an R package and install it if not already installed
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
# utility to load the R packages used in the other methods
loadRequiredPackages <- function() {
  loadRPackage("rgdal") # to read geo files like geojson or shapes
  loadRPackage("RCurl")
  loadRPackage("osmar")
  loadRPackage("rgeos")  
  
}

#----------------------------------------------------------------------------------------------#
# create query for Overpass API
getOverpassQuery <- function(north=0.0, south=0.0, west=0.0, east=0.0, coords=NULL){
  if(is.null(coords)){
    query <- paste0("<osm-script>",
                    "<bbox-query e=\"", east, "\" n=\"", north, "\" s=\"", south, "\" w=\"", west, "\"/>",
                    "<print/>",
                    "</osm-script>")
    
  }else{
    coords = t(coords[,2:1])
    bounds.string = paste(coords, collapse = " ")
    query <- paste0("<osm-script><union into=\"_\"><polygon-query bounds=\"", bounds.string,
                    "\" into=\"_\"/><recurse from=\"_\" into=\"_\" type=\"up\"/>",
                    "</union><print /></osm-script>")
  }
  return(query)
}

#----------------------------------------------------------------------------------------------#
# query to obtain a list of nodes ids in a bounding box 
getNodeIdsOverpassQuery <- function(coords=NULL, swne=c()){
  if(is.null(coords)){
    bbox.string = paste(swne, collapse=",")
    query <- paste0("[out:csv(::id;false)]; node(", bbox.string, "); out ids;")
  }else{
    coords = t(coords[,2:1])
    bounds.string = paste(coords, collapse = " ")
    query <- paste0("[out:csv(::id;false)]; node(poly:\"", bounds.string, "\"); out ids;")
  }
  return(query)
}

#----------------------------------------------------------------------------
# query to obtain a list of nodes with key-value amenity:restaurant in a bounding box 
# a) with output in .osm format
getNodeRestaurantOverpassQuery <- function(coords=NULL, swne=c()){
  if(is.null(coords)){
    bbox.string = paste(swne, collapse=",")
    query <- paste0("node[amenity=restaurant](", bbox.string, "); out;")
  }else{
    coords = t(coords[,2:1])
    bounds.string = paste(coords, collapse = " ")
    query <- paste0("node[amenity=restaurant](poly:\"", bounds.string, "\"); out;")
  }
  return(query)
}


# b) with output in .csv format
getNodeRestaurantOverpassQueryCSV <- function(coords=NULL, swne=c(), columns=c()){
  # [out:csv(::id;false)]; --> in output voglio un csv con una colonna con l'id e non voglio la riga di header (false)
  # node(s,w,n,e); --> prendi tutti i nodi nel bounding box, oppure
  # node(poly:"lat lon lat lon lat lon ..."); --> prendi tutti i nodi nel poligono
  # out ids; --> genera l'output, ma solo con gli id
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
# query to obtain a list of ways ids in a bounding box
getWayIdsOverpassQuery <- function(coords=NULL, swne=c()){
  if(is.null(coords)){
    bbox.string = paste(swne, collapse=",")
    query <- paste0("[out:csv(::id;false)]; way(", bbox.string, "); out ids;")
  }else{
    coords = t(coords[,2:1])
    bounds.string = paste(coords, collapse = " ")
    query <- paste0("[out:csv(::id;false)]; way(poly:\"", bounds.string, "\"); out ids;")
  }
  return(query)
}

#----------------------------------------------------------------------------------------------#
# query to obtain the details of a node given its osm id
getNodesDetailsOverpassQuery <- function(node.ids = c(2669129148)){
  query <- "("
  for(i in 1:length(node.ids)){
    query <- paste0(query, "node(", node.ids[i],");")
  }
  query <- paste0(query, ");out;")
  return(query)
}

#----------------------------------------------------------------------------------------------#
# query to obtain the details of a way given its osm id
getWaysDetailsOverpassQuery <- function(way.ids = c(27626748)){
  query <- "("
  for(i in 1:length(way.ids)){
    query <- paste0(query, "way(", way.ids[i],");")
  }
  query <- paste0(query, "); (._;>;); out;")
  return(query)
}

#----------------------------------------------------------------------------------------------#
# execute the query on OpenStreetMap and save the response in the output.file
getOsmData <- function(query.string = "node(2669129148);out;",
                       output.file = "output-file.osm",
                       slowdown = FALSE){
  
  # build query request 
  # overpass.api <- "http://overpass-api.de/api/interpreter?data="
  overpass.api <- "http://overpass.osm.rambler.ru/cgi/interpreter?data="
  encoded.query <- URLencode(query.string)
  overpass.url <- paste0(overpass.api, encoded.query)
  
  # execute query and save result 
  overpass.response <- getURL(overpass.url, async = !slowdown)
  write(overpass.response, output.file)
  
}

#----------------------------------------------------------------------------------------------#
# execute the query on OpenStreetMap and return the string
getOsmDataInMemory <- function(query.string = "node(2669129148);out;",
                               slowdown = FALSE){
  
  # build query request 
  # overpass.api <- "http://overpass-api.de/api/interpreter?data="
  overpass.api <- "http://overpass.osm.rambler.ru/cgi/interpreter?data="
  encoded.query <- URLencode(query.string)
  overpass.url <- paste0(overpass.api, encoded.query)
  
  # execute query and save result 
  overpass.response <- getURL(overpass.url, async = !slowdown, .encoding="UTF-8")
  return(overpass.response)
  
}

#----------------------------------------------------------------------------------------------#
# read OpenStreetMap file and return the spatial object
getOsmarObject <- function(osm.file = "output-file.osm"){
  
  if(file.access(osm.file, mode=4)==0){
    
    # translate result in spatial object
    f <- file(osm.file)
    osmar.object <- as_osmar(xmlParse(readLines(f)))
    close(f)
    
    # return spatial object
    return(osmar.object)
    
  } else {
    stop("file OSM doesn't exist or is not readable")
  }    
  
}

#----------------------------------------------------------------------------------------------#
# read OpenStreetMap file and return the spatial object
getOsmarObjectInMemory <- function(osm.result = "<osm/>"){
  
  # translate result in spatial object
  osmar.object <- as_osmar(xmlParse(osm.result, asText=T, encoding="UTF-8"))
  
  # return spatial object
  return(osmar.object)
}


#----------------------------------------------------------------------------------------------#
# compute way centroid and return coordinates

computeWayCentroids <- function(way.nodes.coords) {
  ways.list = unique(way.nodes.coords$id)
  ways.centroids = data.frame(lat=NULL, lon=NULL)
  for(i in 1:length(ways.list)){
    way = ways.list[i]
    coords <- as.matrix(way.nodes.coords[way.nodes.coords$id==way,c("lat","lon")])
    if(dim(coords)[1]>=4){
      wgs84 <- CRS("+proj=longlat +datum=WGS84 +no_defs") # WGS 84 (EPSG:4326)
      poly <- SpatialPolygons(list(Polygons(list(Polygon(coords)),1)), proj4string=wgs84) 
      point <- gCentroid(poly)@coords
      p <- data.frame(lat=point[1,1], lon=point[1,2])
    } else {
      #warning("can't compute the centroid of a polygon with less than 4 vertices")
      p <- data.frame(lat=mean(coords[,1]), lon=mean(coords[,2]))
    }
    ways.centroids = rbind(ways.centroids, p)
  }
  return(ways.centroids)
}

#----------------------------------------------------------------------------------------------#
# re-compute way centroid (with simple mean) and return coordinates

reComputeWayCentroids <- function(way.ids=c(27626748)) {
  n <- length(way.ids)
  ways.centroids = data.frame(id= way.ids, lat=rep(0, n), lon=rep(0, n))
  # creo la query
  q <- getWaysDetailsOverpassQuery(way.ids)
  # interrogo osm per avere i nodi
  getOsmData(q, "temp.osm", T)
  osm <- getOsmarObject("temp.osm")
  for(i in 1:n){
    # prendo i nodi unici
    nids <- unique(osm$ways$refs[osm$ways$refs$id==way.ids[i],"ref"])
    # prendo le loro coordinate
    nodes <- unique(osm$nodes$attrs[osm$nodes$attrs$id%in%nids, c("lat","lon")])
    # faccio la media di lat e lon e le metto nel dataframe da restituire
    ways.centroids[i,]$lat <- mean(nodes$lat)
    ways.centroids[i,]$lon <- mean(nodes$lon)
  }
  return(ways.centroids)
}

#----------------------------------------------------------------------------------------------#
# check if ways are closed (last point = first point)

checkIfWaysAreClosed <- function(way.nodes) {
  ways.list = unique(way.nodes$id)
  check = rep(NULL, length(ways.list))
  for(i in 1:length(ways.list)){
    way = ways.list[i]
    nodes = way.nodes[way.nodes$id==way, "ref"]
    check[i] = (nodes[1]==nodes[length(nodes)])
  }
  return(check)
}

