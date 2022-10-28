# Load packages ----------------------------------------------------------------
print('Load packages')

library(magrittr)

# Load active analyses ---------------------------------------------------------
print('Load active analyses')

active_analyses <- readr::read_rds("lib/active_analyses.rds")

# List available model inputs -------------------------------------------------
print('List available model inputs')

files <- list.files("output", pattern = "model_input-")
files <- files[!grepl("describe-model_input-",files)]

# Combine model outputs --------------------------------------------------------
print('Combine model outputs')

for (i in files) {
  
  ## Load model output
  
  tmp <- readr::read_rds(paste0("output/",i))
  
  ## Describe file
  
  sink(paste0("output/describe-",i,".txt"))
  print(Hmisc::describe(tmp))
  sink()
  
}