# Load packages ----------------------------------------------------------------
print('Load packages')

library(magrittr)

# Specify arguments ------------------------------------------------------------
print('Specify arguments')

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  file <- "model_input-cohort_prevax-main-addiction.rds"
} else {
  file <- args[[1]]
}

# Load file
print('Load file')

df <- readr::read_rds(paste0("output/",file))
  
# Describe file
print('Describe file')
  
sink(paste0("output/describe-",gsub("\\.*","",file),".txt"))
print(Hmisc::describe(df))
sink()
  
