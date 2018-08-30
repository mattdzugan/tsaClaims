library(data.table)

setwd("~/Documents/dev/dataisbeautiful/battle/2018/august")

d <- fread("./preprocessed/airport/cy02.csv", check.names = TRUE)
d <- merge(d, fread("./preprocessed/airport/cy03.csv", check.names = TRUE), by='Locid', all.x = TRUE, all.y = TRUE, suffixes = c('','03'))
d <- merge(d, fread("./preprocessed/airport/cy04.csv", check.names = TRUE), by='Locid', all.x = TRUE, all.y = TRUE, suffixes = c('','04'))
d <- merge(d, fread("./preprocessed/airport/cy05.csv", check.names = TRUE), by='Locid', all.x = TRUE, all.y = TRUE, suffixes = c('','05'))
d <- merge(d, fread("./preprocessed/airport/cy07.csv", check.names = TRUE), by='Locid', all.x = TRUE, all.y = TRUE, suffixes = c('','07'))
d <- merge(d, fread("./preprocessed/airport/cy08.csv", check.names = TRUE), by='Locid', all.x = TRUE, all.y = TRUE, suffixes = c('','08'))
d <- merge(d, fread("./preprocessed/airport/cy10.csv", check.names = TRUE), by='Locid', all.x = TRUE, all.y = TRUE, suffixes = c('','10'))
d <- merge(d, fread("./preprocessed/airport/cy11.csv", check.names = TRUE), by='Locid', all.x = TRUE, all.y = TRUE, suffixes = c('','11'))
d <- merge(d, fread("./preprocessed/airport/cy12.csv", check.names = TRUE), by='Locid', all.x = TRUE, all.y = TRUE, suffixes = c('','12'))
d <- merge(d, fread("./preprocessed/airport/cy14.csv", check.names = TRUE), by='Locid', all.x = TRUE, all.y = TRUE, suffixes = c('','14'))
d <- merge(d, fread("./preprocessed/airport/cy15.csv", check.names = TRUE), by='Locid', all.x = TRUE, all.y = TRUE, suffixes = c('','15'))



# Dirty Data is Dirty
cols <- c('CY.2002.Boardings'
          ,'CY.2003.Boardings'
          ,'CY.2004.Boardings'
          ,'CY.05.Enplanements'
          ,'CY.2006.Enplanements'
          ,'CY2007.Enplanements'
          ,'CY08.Enplanements'
          ,'CY.09.Enplanements'
          ,'CY.10.Enplanements'
          ,'CY.11.Enplanements'
          ,'CY.12.Enplanements'
          ,'CY.13.Enplanements'
          ,'CY.14.Enplanements'
          ,'CY.15.Enplanements')

d[, (cols):=lapply(.SD, function(x) as.numeric(gsub(",", "", x))), .SDcols=cols]
d[, totalEnplaned := rowSums(.SD), .SDcols=cols]
d[, meanEnplaned := totalEnplaned/(length(cols))]

enplaned <- d[ !is.na(meanEnplaned), c('Locid', 'meanEnplaned', 'totalEnplaned')]

write.csv(enplaned,'preprocessed/airport/enplaned.csv')

