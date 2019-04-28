# -----------------------------------------------------------------------
# NEW 4.0 usage parser
# -----------------------------------------------------------------------
# GPL3
# -----------------------------------------------------------------------

library(ggplot2)  # plotting
library(gdata)  # plotting
library(tidyverse)
library(lubridate)
library(reshape2)

# read the NEW file log for enable/disable of NEW 4.0 homeegramm
times <- read.table("http://www.kompsoft.de/test/new40/NEW40-Log.txt", header = FALSE, sep = "|")
colnames(times) <- c("date", "time", "status")
times$dtime <- paste(times$date,times$time)
times$dtime <- as.POSIXct(times$dtime)
times <- times[order(as.POSIXct(times$dtime)),]
if(trim(toString(times$status[1])) == 'ausgeschaltet'){
  times[,1] <- NA
}

new_schaltzeiten <- NULL;
for (i in 1:nrow(times)){
  if (!i %% 2){
    next
  }
  #print(is.na(times$dtime[i+1]))
  if(!is.na(times$dtime[i+1])){
    new_schaltzeiten <- rbind(new_schaltzeiten,data.frame(
      start=times$dtime[i],
      end=times$dtime[i+1],
      diff_sec=difftime(times$dtime[i+1], times$dtime[i],  units = "secs"),
      diff_mins=difftime(times$dtime[i+1], times$dtime[i],  units = "mins")
    ))
  }
}

# read all csv files in the defined data folder
setwd("~/Documents/Programmierung/R-Scripts/New40/data")
filenames = list.files(pattern="*.csv")

# read the exported homee summarized consumption files and add them to a dataframe
# add the first part of the filename (Steckdosenname) as an ID to the dataframe
allData <- lapply(filenames, function(.file){
  dat<-read.csv(.file, header=F, dec = ",")
  names(dat)<-c('time','usage')
  fnfragments <- unlist(strsplit(.file, "_"))
  dat$id<-as.character(fnfragments[1])
  dat    # return the dataframe
})
# combine into a single dataframe
myDF <- do.call(rbind, allData)
myDF2 <- myDF
myDF2$time <- as.POSIXct(myDF2$time)

# get all results for a start and end time
# https://stackoverflow.com/questions/27206074/r-extracting-data-from-certain-date-or-time-period-from-a-dataframe
data_new_time = NULL
data_newtime_consumption <- data.frame(id=character(),
                                       date_start=numeric(),
                                       date_end=numeric(), 
                                       usage_start=double(),
                                       usage_end=double()
                                       ) 
for (j in 1:nrow(new_schaltzeiten)){
  new_time <- myDF2[myDF2$time>=as.POSIXct(new_schaltzeiten$start[j]) & myDF2$time<=as.POSIXct(new_schaltzeiten$end[j]),]
  data_newtime_consumption <- rbind(data_newtime_consumption, new_time %>% 
                                      dplyr::group_by(id) %>% 
                                      dplyr::summarise(
                                        date_start = dplyr::first(time),
                                        date_end = dplyr::last(time),
                                        usage_start = dplyr::first(usage),
                                        usage_end = dplyr::last(usage)
                                      ))
  data_new_time  <- rbind(data_new_time , new_time)
}
data_newtime_consumption$consumption <- as.numeric(as.character(data_newtime_consumption$usage_end)) - as.numeric(as.character(data_newtime_consumption$usage_start))
data_new_oot <- subset(myDF2, !(time %in% data_new_time$time))
data_new_oot_sum <- data_new_oot %>% 
                                    dplyr::group_by(day=floor_date(time, "day"),id) %>% 
                                    dplyr::summarise(
                                      date_start = dplyr::first(time),
                                      date_end = dplyr::last(time),
                                      usage_start = dplyr::first(usage),
                                      usage_end = dplyr::last(usage)
                                    )
data_new_oot_sum$consumption <- (as.numeric(as.character(data_new_oot_sum$usage_end)) - as.numeric(as.character(data_new_oot_sum$usage_start)) )

ggplot(new_schaltzeiten, aes(x=start, y=as.numeric(diff_mins)))+
  geom_line()+
  scale_y_continuous(name="Einschaltzeit [Minuten]") +
  scale_x_datetime(name="Datum", date_breaks = "10 days") +
  geom_hline(aes(yintercept = mean(as.numeric(diff_mins))), color="blue")


data_new_it_sum <- data_newtime_consumption %>% group_by(day=floor_date(date_start, "day"), id) %>%
  summarize(amount=sum(consumption))
data_new_oot2_sum <- data_new_oot_sum
data_new_oot2_sum$date_start <- NULL
data_new_oot2_sum$date_end <- NULL
data_new_oot2_sum$usage_start <- NULL
data_new_oot2_sum$usage_end <- NULL

consumptionPerDay <- merge(data_new_it_sum, data_new_oot2_sum, by = c("day", "id") )
names(consumptionPerDay)[3] <- "Billig"
names(consumptionPerDay)[4] <- "Teuer"

# rename the ids
consumptionPerDay$id[consumptionPerDay$id %in% "NEW4.0 #4"] <- "Waschmaschine"
consumptionPerDay$id[consumptionPerDay$id %in% "NEW4.0 #2"] <- "Akkus"
consumptionPerDay$id[consumptionPerDay$id %in% "NEW4.0 #3"] <- "Staubsauger"
consumptionPerDay$id[grep("NEW4.0 #1", consumptionPerDay$id)] <- "Geschirrspüler"

# build the graph
melted <- melt(consumptionPerDay, c("id", "day"))
melted %>% mutate(month = as.Date(cut(day, breaks = "month"))) %>% 
ggplot(aes(x = id, y = value, fill = variable)) + 
  geom_bar(stat = 'identity', position = 'stack') + facet_grid(~ as.Date(month)) +
  scale_fill_manual(values=c('#00FF00','#FF0000')) +
  scale_y_continuous(name="Verbrauch [kwh]") +
  scale_x_discrete(name="Verbraucher") +
  guides(fill=guide_legend(title="Modus"))

# Percentage
consumptionPerDay$percentageCheap <- round(consumptionPerDay$Billig/(consumptionPerDay$Billig+consumptionPerDay$Teuer), 2)
percentagePerMonthCheap <- consumptionPerDay %>% group_by(day=floor_date(day, "month"), id) %>% summarize(Billig=sum(Billig), Teuer=sum(Teuer))
percentagePerMonthCheap$percentageCheap <- round(percentagePerMonthCheap$Billig/(percentagePerMonthCheap$Billig+percentagePerMonthCheap$Teuer), 2)
