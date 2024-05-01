# Load packages ----------------------------------------------------------------
print('Load packages')

library(magrittr)
library(data.table)

# Source functions -------------------------------------------------------------
print('Source functions')

source("analysis/fn-check_vitals.R")

# Specify arguments ------------------------------------------------------------
print('Specify arguments')

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  output <- "cohortoverlap"
  outcomes <- "depression;anxiety_general"
} else {
  output <- args[[1]]
  outcomes <- args[[2]]
}

# Separate outcomes -------------------------------------------------------------
print('Separate outcomes')

outcomes <- stringr::str_split(as.vector(outcomes), ";")[[1]]

# Create blank table -----------------------------------------------------------
print('Create blank table')

df <- NULL

# Add output from each cohort --------------------------------------------------
print('Add output from each cohort')

for (i in outcomes) {
  
  tmp <- readr::read_csv(paste0("output/",output,"_",i,"_midpoint6.csv"))
  df <- rbind(df, tmp)
  
}

# Save output ------------------------------------------------------------------
print('Save output')

readr::write_csv(df, paste0("output/",output,"_output_midpoint6.csv"))
