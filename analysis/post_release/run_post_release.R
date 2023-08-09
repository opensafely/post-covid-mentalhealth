# Load libraries ---------------------------------------------------------------
print('Load libraries')

library(magrittr)

# Specify paths ----------------------------------------------------------------
print('Specify paths')

source("analysis/post_release/specify_paths.R")

# Source functions -------------------------------------------------------------
print('Source functions')

source("analysis/utility.R")

# Make post-release directory --------------------------------------------------
print('Make post-release directory')

dir.create("output/post_release/", recursive = TRUE, showWarnings = FALSE)

# Identify tables and figures to run -------------------------------------------
print('Identify tables and figures to run')

tables <- list.files(path = "analysis/post_release/", 
                     pattern = "manuscript_table")

figures <- list.files(path = "analysis/post_release/", 
                      pattern = "manuscript_figure")

# Run tables and figures -------------------------------------------------------
print('Run tables and figures')

for (i in c(tables, figures)) {
  message(paste0("Making: ",gsub(".R","",i)))
  source(paste0("analysis/post_release/",i))
}