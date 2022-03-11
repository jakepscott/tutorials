library(tidyverse)

#here I demonstrate how to create a custom function with as many inputs as desired, and I show how to find which rows
# of a tibble have all missing values

#This function takes in as many inputs as one will give it, and sees if they are all NAs
all_na <- function(...) {
  x <- list(...) %>% unlist() #The 3 dots means put as many args as you want, I will make them a list, then into a vector
  all(is.na(x)) # Are all elements of the vector missing?
}

# Data to demonstrate
input_data <- tibble(a=c(1,2,NA,4), b=c(NA,3,NA,5))

input_data %>% 
  #The pmap here says go across each row, plug in all the entries into "all_na()", and then spit out the result and
  # save it in the all_missing column
  mutate(all_missing=pmap_lgl(., all_na))
