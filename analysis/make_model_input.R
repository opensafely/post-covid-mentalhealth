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
  name <- "cohort_prevax_extf-sub_sex_female-depression" # prepare datasets for all active analyses 
  # name <- "cohort_vax-sub_history_none-depression" # prepare datasets for all active analyses whose name contains X
  # name <- "vax-depression-main;vax-depression-sub_covid_hospitalised;vax-depression-sub_covid_nonhospitalised" # prepare datasets for specific active analyses
} else {
  name <- args[[1]]
}

# Load active analyses ---------------------------------------------------------
print('Load active analyses')

active_analyses <- readr::read_rds("lib/active_analyses.rds")

# Identify model inputs to be prepared -----------------------------------------
print('Identify model inputs to be prepared')

if (name=="all") {
  prepare <- active_analyses$name
} else if(grepl(";",name)) {
  prepare <- stringr::str_split(as.vector(name), ";")[[1]]
} else {
  prepare <- active_analyses[grepl(name,active_analyses$name),]$name
}

# Filter active_analyses to model inputs to be prepared ------------------------
print('Filter active_analyses to model inputs to be prepared')

active_analyses <- active_analyses[active_analyses$name %in% prepare,]

for (i in 1:nrow(active_analyses)) {
  
  # Load data ------------------------------------------------------------------
  print(paste0("Load data for ",active_analyses$name[i]))
  
  input <- dplyr::as_tibble(readr::read_rds(paste0("output/input_",active_analyses$cohort[i],"_stage1.rds")))
  
  # Restrict to required variables for dataset preparation ---------------------
  print('Restrict to required variables for dataset preparation')
  
  input <- input[,unique(c("patient_id",
                           "index_date",
                           "end_date_exposure",
                           "end_date_outcome",
                           active_analyses$exposure[i], 
                           active_analyses$outcome[i],
                           unlist(strsplit(active_analyses$strata[i], split = ";")),
                           unlist(strsplit(active_analyses$covariate_other[i], split = ";")),
                           "sub_cat_covid19_hospital",
                           "sub_bin_covid19_confirmed_history",
                           "cov_cat_sex",
                           "cov_num_age",
                           "cov_cat_ethnicity",
                           colnames(input)[grepl("cov_cat_history_",colnames(input))]))]
  
  # Identify final list of variables to keep -----------------------------------
  print('Identify final list of variables to keep')
  
  keep <- c("patient_id","index_date","exp_date","out_date","end_date_exposure","end_date_outcome")
  varlists <- c("strata","covariate_age","covariate_sex","covariate_other")
  for (j in varlists) {
    if (active_analyses[i,j] == "NULL") {
      tmp <- NULL
    } else {
      tmp <- stringr::str_split(as.vector(active_analyses[i,j]), ";")[[1]]
    }
    keep <- c(keep,tmp)
    rm(tmp)
  }
  
  # Remove outcomes outside of follow-up time ----------------------------------
  print('Remove outcomes outside of follow-up time')
  
  input <- dplyr::rename(input, 
                         "out_date" = active_analyses$outcome[i],
                         "exp_date" = active_analyses$exposure[i])
  
  input <- input %>% 
    dplyr::mutate(out_date = replace(out_date, which(out_date>end_date_outcome | out_date<index_date), NA),
                  exp_date =  replace(exp_date, which(exp_date>end_date_exposure | exp_date<index_date), NA),
                  sub_cat_covid19_hospital = replace(sub_cat_covid19_hospital, which(is.na(exp_date)),"no_infection"))
  
  # Update end date to be outcome date where applicable ------------------------
  print('Update end date to be outcome date where applicable')
  
  input <- input %>% 
    dplyr::rowwise() %>% 
    dplyr::mutate(end_date_outcome = min(end_date_outcome, out_date, na.rm = TRUE))
  
  # Make model input: main and day0 --------------------------------------------
  
  if (grepl("main",active_analyses$analysis[i])) {
    
    print(paste0('Make model input: ',active_analyses$analysis[i]))
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE,]
    
    df <- df %>%
      dplyr::select(tidyselect::all_of(keep))
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_covid_hospitalised -----------------------------------
  
  if (grepl("sub_covid_hospitalised",active_analyses$analysis[i])) {
    
    print(paste0('Make model input: ',active_analyses$analysis[i]))
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE,]
    
    df <- df %>% 
      dplyr::mutate(end_date_outcome = replace(end_date_outcome, which(sub_cat_covid19_hospital=="non_hospitalised"), exp_date-1),
                    exp_date = replace(exp_date, which(sub_cat_covid19_hospital=="non_hospitalised"), NA),
                    out_date = replace(out_date, which(out_date>end_date_outcome), NA))
    
    df <- df[df$end_date_outcome>=df$index_date,]
    
    df <- df %>%
      dplyr::select(tidyselect::all_of(keep))
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_covid_nonhospitalised --------------------------------
  
  if (grepl("sub_covid_nonhospitalised",active_analyses$analysis[i])) {
    
    print(paste0('Make model input: ',active_analyses$analysis[i]))
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE,]
    
    df <- df %>% 
      dplyr::mutate(end_date_outcome = replace(end_date_outcome, which(sub_cat_covid19_hospital=="hospitalised"), exp_date-1),
                    exp_date = replace(exp_date, which(sub_cat_covid19_hospital=="hospitalised"), NA),
                    out_date = replace(out_date, which(out_date>end_date_outcome), NA))
    
    df <- df[df$end_date_outcome>=df$index_date,]
    df$index_date <- as.Date(df$index_date)
    
    df <- df %>%
      dplyr::select(tidyselect::all_of(keep))
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_covid_history ----------------------------------------
  
  if (grepl("sub_covid_history",active_analyses$analysis[i])) {
    
    print(paste0('Make model input: ',active_analyses$analysis[i]))
    
    df <- input[input$sub_bin_covid19_confirmed_history==TRUE,]
    
    df <- df %>%
      dplyr::select(tidyselect::all_of(keep))
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_sex_* ------------------------------------------------
  
  if (grepl("sub_sex_",active_analyses$analysis[i])) {
    
    print(paste0('Make model input: ',active_analyses$analysis[i]))
    
    sex <- stringr::str_to_title(gsub(".*sub_sex_","",active_analyses$analysis[i]))
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_sex==sex,]
    
    df <- df %>%
      dplyr::select(tidyselect::all_of(keep))
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_age_* ------------------------------------------------
  
  if (grepl("sub_age_",active_analyses$analysis[i])==TRUE) {
    
    print(paste0('Make model input: ',active_analyses$analysis[i]))
    
    min_age <- as.numeric(strsplit(gsub(".*sub_age_","",active_analyses$analysis[i]), split = "_")[[1]][1])
    max_age <- as.numeric(strsplit(gsub(".*sub_age_","",active_analyses$analysis[i]), split = "_")[[1]][2])
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_num_age>=min_age &
                  input$cov_num_age<ifelse(max_age==110,max_age+1,max_age),]
    
    df <- df %>%
      dplyr::select(tidyselect::all_of(keep))

    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_ethnicity_* ------------------------------------------
  
  if (grepl("sub_ethnicity_",active_analyses$analysis[i])==TRUE) {
    
    print(paste0('Make model input: ',active_analyses$analysis[i]))
    
    ethnicity <- stringr::str_to_title(gsub(".*sub_ethnicity_","",active_analyses$analysis[i]))
    ethnicity <- ifelse(ethnicity=="Asian","South Asian",ethnicity)
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_ethnicity==ethnicity,]
    
    df <- df %>%
      dplyr::select(tidyselect::all_of(keep))
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_history_* --------------------------------------------
  
  if (grepl("sub_history_",active_analyses$analysis[i])==TRUE) {
    
    print(paste0('Make model input: ',active_analyses$analysis[i]))
    
    history <- gsub(".*sub_history_","",active_analyses$analysis[i])

    df <- input[input$sub_bin_covid19_confirmed_history==FALSE,]
    df <- dplyr::rename(df, "history" = gsub("out_date","cov_cat_history",active_analyses$outcome[i]))
    df <- df[df$history==history & !is.na(df$history),]
    
    df <- df %>%
      dplyr::select(tidyselect::all_of(keep))
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")), compress = "gz")
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
}