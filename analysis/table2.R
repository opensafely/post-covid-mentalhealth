library(readr)
library(dplyr)
library(magrittr)

# Load active analyses ---------------------------------------------------------

active_analyses <- readr::read_rds("lib/active_analyses.rds")

# Repeat

for (i in 1:nrow(active_analyses)) {
  
  ## Load data -----------------------------------------------------------------
  
  df <- read_rds(paste0("model_input-",active_analyses$name[i],".rds"))
  
  ## Calculate number of events ------------------------------------------------
  
  
  
}
