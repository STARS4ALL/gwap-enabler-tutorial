#----------------------------------------------------------------------------------------------#

# authors: Irene Celino, Gloria Re Calegari
# copyright: CEFRIEL, http://www.cefriel.com
# license: Apache 2.0, http://www.apache.org/licenses/LICENSE-2.0

#----------------------------------------------------------------------------------------------#

# GWAP-enabler tutorial: Preparing data of OSM restaurant in Milano

#By running this script you can generate the INSERT queries for tables 'resource', 'topic' and 'resource_has_topic'
#The script consists in the following 3 steps:
# 1) extracting data from OpenStreetMap
# 2) cleaning and filtering data
# 3) SQL query generation

#set your workspace
 # setwd("/home/re/stars4all - WP5/Enabler-tutorialOSM/")
setwd("/path/to/workspace/")

#1) Extracting data from OSM

    #a) import the osm-utlity.r file (set of functions to query OpenStreetMap) and load the required packages
    source("osm-utilities-tutorial.r")
    loadRPackage()
    loadRequiredPackages()
    
    #b) Define the area of analysis, by setting the coordinates of the bounding box 
    #(can be extracted from https://www.openstreetmap.org/export#map=16/45.5210/9.2184)
    # order of the coordinates in the array: South, West, North, East  
    swne<-c(45.4785, 9.1442, 45.5397, 9.2792)
    
    #c) select only the restaurants' attributes desired 
    # (all the available field can be extracted by querying https://overpass-turbo.eu/ and analysing the data result)
    # col<-"::id,::lat,::lon,name,cuisine,website,'addr:city','addr:street','addr:housenumber','addr:postcode'"
    col<-"::id,::lat,::lon,name,cuisine,website"
    query<-getNodeRestaurantOverpassQueryCSV(swne= swne, columns = col)
    # run the query and save the result in a .csv file
    getOsmData(query.string = query, output.file = "output-file.csv",slowdown = F)
    all.data<-read.csv("output-file.csv", sep = "\t")
    
#----------------------------------------------------------------------------------

# 2) Cleaning and filtering data
    
    # a) keep only the restaurant with a valid name
    filtered<-all.data[!all.data$name =="",]
    
    # b) managing multiple tags in the field "cuisine"
    # Keep only the first tag and delete all the others tabs (separated by ; or , or :)
    filtered$cuisine<-as.character(filtered$cuisine)
    filtered$cuisine<-gsub("[;,:]\\s*[A-z]*","",filtered$cuisine)
    
    #c) Definition of the output categories (types of cuisine)
      #c.1) select the overall top n categories (overall ranking from https://taginfo.openstreetmap.org/keys/cuisine#values)
      label<- c("regional", "pizza", "burger", "italian", "chinese", "sandwich", "mexican", "japanese", "indian", "kebab")
      # with the corresponding frequency in the dataset (prior probability) 
      prior<- c(0.114, 0.0972, 0.0824, 0.0671, 0.0493, 0.0344, 0.0268, 0.0239, 0.0213, 0.0211) 
      categories<-data.frame(label, prior)
      
      #c.2) select the top n categories from the specific use case (only the restaurant in the area considered)
      table.categories<-as.data.frame(table(filtered$cuisine))
      table.categories<-table.categories[!table.categories$Var1=="",]
      table.categories<-table.categories[with(table.categories, order(-Freq)), ]
      table.categories$prior<-round(table.categories$Freq/sum(table.categories$Freq),3)
      categories<-table.categories[c(1:9), c("Var1","prior")]
      names(categories)<-c("label", "prior")
    
    # d) define the Ground Truth set and the set of data to be classified
    # "GT" set: restaurant already labelled with one of the selected categories 
    gt<-filtered[filtered$cuisine %in% categories$label, ]
    
    # "toCalssify" set: all the restaurants with no value for 'cuisine' 
    to.classify<-filtered[! filtered$X.id %in% gt$X.id & filtered$cuisine =="", ]
    
    # put all the resource together ("GT" and the "toClassify" restaurants)
    resource<-gt
    resource<-rbind(resource, to.classify)

#--------------------------------------------------------------------------------
    
# 3) SQL query generation

    # a) table RESOURCE    
    query.resource<-character()
    query.resource<-c("LOCK TABLES resource WRITE;")
    query.resource<-c(query.resource, "INSERT INTO resource (refId, lat, lon, orderBy, label, url) VALUES")
    
    for(i in 1:nrow(resource)){
      if(i != nrow(resource)){
        q<-paste0("('http://www.openstreetmap.org/node/", resource[i,]$X.id, "'," , resource[i,]$X.lat, "," , resource[i,]$X.lon, ", rand(),'", gsub("'","''",resource[i,]$name), "', ''),")
        query.resource<-c(query.resource, q)
      }else{
        q<-paste0("('http://www.openstreetmap.org/node/", resource[i,]$X.id, "'," , resource[i,]$X.lat, "," , resource[i,]$X.lon, ", rand(),'", gsub("'","''",resource[i,]$name), "', '');")
        query.resource<-c(query.resource, q)
      }
    }    
    
    query.resource<-c(query.resource, "UNLOCK TABLES;")
    write(query.resource, file="2_Insert_Resource.sql")  # all the resource INSERT queries
    
    # b) table TOPIC
    query.topic<-character()
    query.topic<-c("LOCK TABLES topic WRITE;")
    query.topic<-c(query.topic, "INSERT INTO topic (refId, value, weight, url) VALUES")
    
    for(ct in 1:nrow(categories)){
      if(ct != nrow(categories)){
        qt<-paste0("('", categories$label[ct], "','" , categories$label[ct], "',", categories$prior[ct], ", ''),")
        query.topic<-c(query.topic, qt)
      }else{
        qt<-paste0("('", categories$label[ct], "','" , categories$label[ct], "',", categories$prior[ct], ", '');")
        query.topic<-c(query.topic, qt)
      }
    }
    query.topic<-c(query.topic, "UNLOCK TABLES;")
    write(query.topic, file="3_Insert_Topic.sql") # all the topic INSERT queries
    
    
    # c) table RESOURCE HAS TOPIC (per GT solo una riga, per le altre una riga per ogni categoria)
      #c.1) GT resources: only one row of the correspondig topic with score 2
      query.rht.gt<-character()
      query.rht.gt<-c("LOCK TABLES resource_has_topic WRITE, resource READ, topic READ;")
      
      for(t in 1:nrow(gt)){
        qgt<-paste0("INSERT INTO resource_has_topic (idResource, idTopic, score) VALUES ((SELECT idResource FROM resource WHERE refId = 'http://www.openstreetmap.org/node/", gt$X.id[t], "'), (SELECT idTopic FROM topic WHERE refId ='", gt$cuisine[t], "'), 2);")
        query.rht.gt<-c(query.rht.gt,qgt)
      }
      
      #c.2) toClassify resources: one row for each topic with score 0
      query.rht.toclassify<-character()

      for(w in 1:nrow(to.classify)){
        for(f in 1:nrow(categories)){
          qtc<-paste0("INSERT INTO resource_has_topic (idResource, idTopic, score) VALUES ((SELECT idResource FROM resource WHERE refId = 'http://www.openstreetmap.org/node/", to.classify$X.id[w], "'), (SELECT idTopic FROM topic WHERE refId ='", categories$label[f], "'), 0);")
          query.rht.toclassify<-c(query.rht.toclassify,qtc)
        }
      }
      query.rht.toclassify<-c(query.rht.toclassify, "UNLOCK TABLES;")
      
      #save both the GT and toClassify resource_has_topic in a single file
      query.rht<-c(query.rht.gt, query.rht.toclassify)
      write(query.rht, file="4_Insert_Resource_has_Topic.sql")  # all the resource_has_topic INSERT queries 



 
