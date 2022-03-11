library(zoo)

#Use as.yearqtr to get a Zoo date-like object from something formatted like 
#2020q1. The convert that to date. To get it to be the last day in the Q
#(e.g. March 31 for Q1) put frac=1. Leave out the frac arg to get the first
#day in the Q
as.Date(as.yearqtr("2020q1",format="%Yq%q"),frac=1)
