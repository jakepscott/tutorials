+# Loading Libs and Data------------------------------------------------------------
library(tidyverse)
library(here)
library(vroom)
library(stringr)
library(lubridate)
library(haven)
library(lubridate)
library(glue)
library(tools)
library(zoo)
options(scipen = 999)



# Grouping the data by firm-year-quarter ----------------------------------
joined <- joined %>% 
  arrange(date) %>% 
  mutate(year_quarter=zoo::as.yearqtr(date)) %>% 
  filter(id!="" &
         id!=" ")
  
# Very slow way to group by and summarize

# grouped <- joined %>% 
#   group_by(id,year_quarter) %>% 
#   summarise(variable=median(var-of-interest),
#             date=max(date)) %>% 
#   ungroup()


# Grouping can be done *much* quicker with dt.table/dtplyr ----------------
library(data.table)
library(dtplyr)

#Convert to data.table
joined_dt <- as.data.table(joined)

library(tictoc)
tic()
# use datatable syntax
grouped_dt <- joined_dt[, .(median_variable=median(var-of-interest,na.rm = T),
                            date=max(date)), by = list(id,year_quarter)]
grouped_dt %>% as_tibble()
toc()

#Convert to "lazy_dt", which is what dtplyr uses
tic()
dtplyr_joined_dt <- lazy_dt(joined_dt)
#Use dtplyr syntax
grouped <- dtplyr_joined_dt %>% 
  group_by(id,year_quarter) %>% 
  summarise(variable=median(var-of-interest),
            date=max(date)) %>% 
  ungroup() %>% 
  as_tibble()
toc()

YOY_function <- function(id_val,
                               current_date_val,
                               value,
                               time_back=1,
                               full_data,
                               variable="variable") {
  current_date_val <- current_date_val %>% as.Date() %>% as.yearqtr()
  
  if ((full_data %>% 
      filter(id==id_val &
             year_quarter==current_date_val-time_back) %>% 
      nrow())==0) {
    #print("NA")
    return(NA)
  } else {
    year_ago_value <- full_data %>% 
      filter(id==id_val &
               year_quarter==current_date_val-time_back) %>%
      pull(variable)
    
    YOY_change <- ((value-year_ago_value)/year_ago_value)*100
    #print(YOY_change)
    return(YOY_change)
  }
}



# Implementing with For-Loop ----------------------------------------------
# Normally, since this is a row by row operation but that uses the whole data set, I would have to use a for-loop, like below.
# This works fine, but is somewhat cumbersome.

#In any case, this takes SUPER long

tic()
for_test <- grouped %>% mutate(yoy_change=12)
for (i in 1:100) {
  print(i)
  for_test$yoy_change[i] <- YOY_function(id_val = for_test$id[i],
                                              current_date_val = for_test$date[i],
                                              value = for_test$variable[i],
                                              time_back = 1,
                                              full_data = for_test,
                                              variable = "variable")
}
for_test
toc()

#This took 10.335 for 100 rows. There are 1,214,472 rows in grouped. 1,214,472/100= 12144.72, 12144.72*10.335 secs= 125515.7 seconds to run.
# So it would take 2091.928 MINUTES and 34.86547 hours.

# Using Rowwise to implement function -------------------------------------
# I **could** use rowwise, but like above it would take an insane amount of time
# grouped <- grouped %>%
#   rowwise() %>% 
#   mutate(YOY_variable=YOY_function(id_val = id,
#                                  current_date_val = date,
#                                  value = variable, 
#                                  time_back = 1, 
#                                  full_data = grouped,
#                                  variable = "variable"))



# Nesting to reduce run time ----------------------------------------------
#Nesting by id reduces the run time a fair bit. 

#Nest by id (the negative is saying nest everything but id)
nested <- grouped %>% nest(-id)

#Only keep the ones where the id shows up in more than 1 quarter. Using data.table for speed here
nested <- grouped %>%
  lazy_dt() %>% 
  group_by(id) %>% 
  mutate(appearances=n()) %>% 
  filter(appearances>1) %>% 
  select(-appearances) %>% 
  as_tibble() %>% 
  nest(-id)

#Same YOY function as above but we don't need to filter by id anymore, nesting took care of that
YOY_function2 <- function(current_date,
                          value,
                          time_back=1,
                          full_data,
                          variable="variable") {
  current_date_val <- current_date %>% as.Date() %>% as.yearqtr()
  
  if ((full_data %>% 
       filter(year_quarter==current_date_val-time_back) %>% 
       nrow())==0) {
    #print("NA")
    return(NA)
  } else {
    year_ago_value <- full_data %>% 
      filter(year_quarter==current_date_val-time_back) %>%
      pull(variable)
    
    YOY_change <- ((value-year_ago_value)/year_ago_value)*100
    #print(YOY_change)
    return(YOY_change)
  }
}


#For each id, go into the nested dataframe and run the YOY function on each row of said nested dataframe. 
nestedtest <- nested
tic()
for (i in 1:100) {
  print(i)
  nestedtest$data[[i]] <- nestedtest$data[[i]] %>% 
    rowwise() %>% 
    mutate(test=YOY_function2(current_date = date,value = variable,time_back = 1,full_data = .))
}
toc()

#It took 16.542 seconds to run on 100 rows of the nested data frame. There are 170,724 rows in the nested dataframe.
# So it would take (170,724/100)*15.542=26533.92 SECONDS to run. 
# 442.232 MINUTES to run
# 7.370533 HOURS to run


# Using Map rather than for --------------------------------------------------
#This is just a function that says go into a data frame, look at it row-wise, and then apply the YOY_function to each row
rowwise_YOY <- function(data){
  data %>% 
    rowwise() %>% 
    mutate(YOY_Change=YOY_function2(current_date = date,value = variable,time_back = 1,full_data = .))
}


#This takes 2.854 seconds for 100 rows. The data has 170,714 rows. (170,714/100)*2.854=4872.178 SECONDs to run
# 81.20297 MINUTES to run
# 1.353383 HOURS to run
tic()
viewthis <- nested %>% 
  head(100) %>%
  mutate(data=map(data,rowwise_YOY))
toc()
viewthis$data[[100]]



# Use Parallelization -----------------------------------------------------


tic()
viewthis <- nested %>% 
  head(100) %>%
  mutate(data=future_map(data,rowwise_YOY))
toc()
viewthis$data[[100]]

#Parallelization cannot really shine on only 100 entries. It manages to go maybe 0.1 to 0.5 seconds faster. Over 100k+ rows this is actually 
# meaningful. But in reality the speed increase is exponential. 

#When we increase the number of rows we are working with from 100 to 1000, map takes 25.995 seconds. So all rows would take
# (170,714/1000)*25.995 = 4437.71 SECONDs, 73.96183 MINUTES, 1.232697 HOURS

tic()
viewthis <- nested %>% 
  head(1000) %>%
  mutate(data=map(data,rowwise_YOY))
toc()
viewthis$data[[100]]

#But the future_map function, with parallelization, only takes 6.723 seconds.So all rows take (170,714/1000)*6.723=1147.71 SECONDs,
# 19.1285 MINUTES, 0.3188083 HOURS
tic()
viewthis <- nested %>% 
  head(1000) %>%
  mutate(data=future_map(data,rowwise_YOY))
toc()
viewthis$data[[100]]

