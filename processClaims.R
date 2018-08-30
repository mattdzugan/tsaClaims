library(data.table)
library(ggplot2)
library(stringr)
library(qdapTools)

setwd("~/Documents/dev/dataisbeautiful/battle/2018/august")

d1 <- fread("./preprocessed/claims-2002-2006.csv", check.names = TRUE)
d2 <- fread("./preprocessed/claims-2007-2009.csv", check.names = TRUE) #^
d3 <- fread("./preprocessed/claims-2010-2013.csv", check.names = TRUE) #no "CLAIM AMOUNT" , no "Status"   "Item --> Item Category"
d4 <- fread("./preprocessed/claims-2014.csv", check.names = TRUE)      #^
d5 <- fread("./preprocessed/claims-2015.csv")      # "Incident Date --> Incident D"
d6 <- fread("./preprocessed/claims-2016.csv")
d7 <- fread("./preprocessed/claims-2017.csv")
#data <- rbindlist(list(d1,d2,d3,d4,d5,d6,d7), fill = TRUE)

claims <- rbindlist(list(d1,d2
                         ,d3,d4
                         ,d5
                         ,d6,d7
                       #,d3,d4,d5,d6,d7
                       ), fill = TRUE)
#remove('d1','d2','d3','d4','d5')
remove('d1','d2','d3','d4','d5','d6','d7')






## work on the Item Type Stuff
# d12 <- rbindlist(list(d1,d2), fill=TRUE)
# u <- (unique(d12$Item))
# fullCat <- paste(u,collapse = ";")
# zz_1 <- unique(trimws(strsplit(tolower(fullCat),";")[[1]]))
# write.csv(x = zz_1, './dump/earyItemNames.csv')
# 
# u <- (unique(d3$Item.Category))
# fullCat <- paste(u,collapse = ";")
# zz_2 <- unique(trimws(strsplit(tolower(fullCat),";")[[1]]))
# write.csv(x = zz_2, './dump/laterItemNames.csv')



cleanParts <- function(s_in){
  s_1 <- tolower(s_in)
  s_out <- paste(trimws(strsplit(s_1,";")[[1]]),collapse = ";")
  return(s_out)
}

claims[!is.na(Item), Item := mapply(cleanParts,Item)] # get the older years
claims[is.na(Item),  Item := mapply(cleanParts,Item.Category)] # and the newer years
claims <- cbind(claims, mtabulate(strsplit(claims$Item,";")))

mapping <- fread('./dump/mapping.csv', header = TRUE)
for (cc in 1:nrow(mapping)){
  newCat <- mapping[cc,new]
  claims[, (newCat) := 0]
}
for (cc in 1:nrow(mapping)){
  oldCat <- mapping[cc,old]
  newCat <- mapping[cc,new]
  claims[get(oldCat)>0, (newCat) := 1]
}
for (cc in 1:nrow(mapping)){
  oldCat <- mapping[cc,old]
  if (oldCat != 'other'){
    claims[, (oldCat):= NULL]
  }
}


zz <- claims[, .(count=.N), by=Airport.Code]

tokeep <- c(which(sapply(claims,is.numeric)))

airportSummary <- claims[, lapply(.SD, sum, na.rm=TRUE), by=Airport.Code,.SDcols=tokeep]



##
numOhare <- nrow(claims[ Airport.Code=='ORD', ])
numLAX   <- nrow(claims[ Airport.Code=='LAX', ])
numSEA   <- nrow(claims[ Airport.Code=='SEA', ])
numBOI   <- nrow(claims[ Airport.Code=='BOI', ])

cosmetics <- claims[ `hunting & fishing items`>0, ]
ohareRate <- nrow(cosmetics[ Airport.Code=='ORD', ])/numOhare
laxRate   <- nrow(cosmetics[ Airport.Code=='LAX', ])/numLAX
seaRate   <- nrow(cosmetics[ Airport.Code=='SEA', ])/numSEA
boiRate   <- nrow(cosmetics[ Airport.Code=='BOI', ])/numBOI






metadata <- fread('./raw/airports.dat',header = FALSE, col.names = c('id'
                                                                     ,'Name'
                                                                     ,'City'
                                                                     ,'Country'
                                                                     ,'IATA'
                                                                     ,'ICAO'
                                                                     ,'Lat'
                                                                     ,'Lon'
                                                                     ,'Alt'
                                                                     ,'Timezone'
                                                                     ,'DST'
                                                                     ,'TZDBTZ'
                                                                     ,'Type'
                                                                     ,'Source'))

airportSummary <- merge(airportSummary
                        ,metadata
                        ,by.x='Airport.Code'
                        ,by.y='IATA'
                        ,all.x = TRUE
                        ,all.y = FALSE)
airportSummary <- merge(airportSummary
                        , zz
                        ,by = 'Airport.Code'
                        ,all.x = TRUE
                        ,all.y = FALSE)
airportSummary <- merge(airportSummary
                        , fread('./preprocessed/airport/enplaned.csv')
                        , by.x = 'Airport.Code'
                        , by.y = 'Locid'
                        ,all.x = TRUE
                        ,all.y = FALSE)



itemCols <- intersect(setdiff(unique(mapping[,new]),"-"), names(airportSummary))
allCols  <- c("Airport.Code","Name","Lat","Lon","count","meanEnplaned","totalEnplaned",itemCols)
processedClaimData <-airportSummary[ (!is.na(Lat)) &
                                       (Country=='United States') &
                                       (count>10)
                                     , .SD, .SDcols=allCols] #figure out how to add itemCols here
  
write.csv(processedClaimData, file = './processed/claimData.csv')


ggplot(airportSummary[(Country=='United States')&(count>100), ])+
  geom_point(aes(x=Lon, y=Lat, color=count))
