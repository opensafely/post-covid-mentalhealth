# Load packages ----------------------------------------------------------------
print('Load packages')

library(magrittr)
library(data.table)

# Source functions -------------------------------------------------------------
print('Source functions')

source("analysis/model/fn-check_vitals.R")

# Specify arguments ------------------------------------------------------------
print('Specify arguments')

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  # name <- "all" # prepare datasets for all active analyses 
  name <- "cohort_prevax-sub_priorhistory" # prepare datasets for all active analyses whose name contains X
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
  
  # Load data --------------------------------------------------------------------
  print(paste0("Load data for ",active_analyses$name[i]))
  
  input <- readr::read_rds(paste0("output/input_",active_analyses$cohort[i],"_stage1.rds"))
  
  # Restrict to required variables -----------------------------------------------
  print('Restrict to required variables')
  
  history_components <- colnames(input)[grepl("cov_bin_recent",colnames(input)) | grepl("cov_bin_history",colnames(input))]
  
  input <- input[,unique(c("patient_id",
                           "index_date",
                           "end_date",
                           active_analyses$exposure[i], 
                           active_analyses$outcome[i],
                           unlist(strsplit(active_analyses$strata[i], split = ";")),
                           unlist(strsplit(active_analyses$covariate_other[i], split = ";"))[!grepl("_priorhistory_",unlist(strsplit(active_analyses$covariate_other[i], split = ";")))],
                           "sub_cat_covid19_hospital",
                           "sub_bin_covid19_confirmed_history",
                           "cov_cat_sex",
                           "cov_num_age",
                           "cov_cat_ethnicity",
                           history_components))]
  
  
  # Remove outcomes outside of follow-up time ------------------------------------
  print('Remove outcomes outside of follow-up time')
  
  input <- dplyr::rename(input, 
                         "out_date" = active_analyses$outcome[i],
                         "exp_date" = active_analyses$exposure[i])
  
  input <- input %>% 
    dplyr::mutate(out_date = replace(out_date, which(out_date>end_date | out_date<index_date), NA),
                  exp_date =  replace(exp_date, which(exp_date>end_date | exp_date<index_date), NA),
                  sub_cat_covid19_hospital = replace(sub_cat_covid19_hospital, which(is.na(exp_date)),"no_infection"))
  
  # Update end date to be outcome date where applicable ------------------------
  print('Update end date to be outcome date where applicable')
  
  input <- input %>% 
    dplyr::rowwise() %>% 
    dplyr::mutate(end_date = min(end_date, out_date, na.rm = TRUE))
  
  # Make three level history covariates ----------------------------------------
  print('Make three level history covariates')
  
  input$cov_bin_priorhistory_depression <- dplyr::case_when(
    input$cov_bin_history_depression==TRUE & input$cov_bin_recent_depression==TRUE ~ "recent",
    input$cov_bin_history_depression==TRUE & input$cov_bin_recent_depression==FALSE ~ "notrecent",
    input$cov_bin_history_depression==FALSE & input$cov_bin_recent_depression==TRUE ~ "recent",
    input$cov_bin_history_depression==FALSE & input$cov_bin_recent_depression==FALSE ~ "none")
  input[,c("cov_bin_history_depression","cov_bin_recent_depression")] <- NULL
  
  input$cov_bin_priorhistory_anxiety_general <- dplyr::case_when(
        input$cov_bin_history_anxiety==TRUE & input$cov_bin_recent_anxiety==TRUE ~ "recent",
        input$cov_bin_history_anxiety==TRUE & input$cov_bin_recent_anxiety==FALSE ~ "notrecent",
        input$cov_bin_history_anxiety==FALSE & input$cov_bin_recent_anxiety==TRUE ~ "recent",
        input$cov_bin_history_anxiety==FALSE & input$cov_bin_recent_anxiety==FALSE ~ "none")
  input[,c("cov_bin_history_anxiety","cov_bin_recent_anxiety")] <- NULL
  
  input$cov_bin_priorhistory_eating_disorders <- dplyr::case_when(
        input$cov_bin_history_eating_disorders==TRUE & input$cov_bin_recent_eating_disorders==TRUE ~ "recent",
        input$cov_bin_history_eating_disorders==TRUE & input$cov_bin_recent_eating_disorders==FALSE ~ "notrecent",
        input$cov_bin_history_eating_disorders==FALSE & input$cov_bin_recent_eating_disorders==TRUE ~ "recent",
        input$cov_bin_history_eating_disorders==FALSE & input$cov_bin_recent_eating_disorders==FALSE ~ "none")
  input[,c("cov_bin_history_eating_disorders","cov_bin_recent_eating_disorders")] <- NULL
  
  input$cov_bin_priorhistory_serious_mental_illness <- dplyr::case_when(
        input$cov_bin_history_serious_mental_illness==TRUE & input$cov_bin_recent_serious_mental_illness==TRUE ~ "recent",
        input$cov_bin_history_serious_mental_illness==TRUE & input$cov_bin_recent_serious_mental_illness==FALSE ~ "notrecent",
        input$cov_bin_history_serious_mental_illness==FALSE & input$cov_bin_recent_serious_mental_illness==TRUE ~ "recent",
        input$cov_bin_history_serious_mental_illness==FALSE & input$cov_bin_recent_serious_mental_illness==FALSE ~ "none")
  input[,c("cov_bin_history_serious_mental_illness","cov_bin_recent_serious_mental_illness")] <- NULL
  
  input$cov_bin_priorhistory_self_harm <- dplyr::case_when(
        input$cov_bin_history_self_harm==TRUE & input$cov_bin_recent_self_harm==TRUE ~ "recent",
        input$cov_bin_history_self_harm==TRUE & input$cov_bin_recent_self_harm==FALSE ~ "notrecent",
        input$cov_bin_history_self_harm==FALSE & input$cov_bin_recent_self_harm==TRUE ~ "recent",
        input$cov_bin_history_self_harm==FALSE & input$cov_bin_recent_self_harm==FALSE ~ "none")
  input[,c("cov_bin_history_self_harm","cov_bin_recent_self_harm")] <- NULL
  
  
  # Make model input: main -------------------------------------------------------
  
  if (active_analyses$analysis[i]=="main") {
    
    print('Make model input: main')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE,]
    
    df[,colnames(df)[grepl("sub_",colnames(df))]] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")))
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_covid_hospitalised -------------------------------------
  
  if (active_analyses$analysis[i]=="sub_covid_hospitalised") {
    
    print('Make model input: sub_covid_hospitalised')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE,]
    
    df <- df %>% 
      dplyr::mutate(end_date = replace(end_date, which(sub_cat_covid19_hospital=="non_hospitalised"), exp_date-1),
                    exp_date = replace(exp_date, which(sub_cat_covid19_hospital=="non_hospitalised"), NA),
                    out_date = replace(out_date, which(out_date>end_date), NA))
    
    df <- df[df$end_date>=df$index_date,]
    
    df[,colnames(df)[grepl("sub_",colnames(df))]] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")))
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_covid_nonhospitalised ----------------------------------
  
  if (active_analyses$analysis[i]=="sub_covid_nonhospitalised") {
    
    print('Make model input: sub_covid_nonhospitalised')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE,]
    
    df <- df %>% 
      dplyr::mutate(end_date = replace(end_date, which(sub_cat_covid19_hospital=="hospitalised"), exp_date-1),
                    exp_date = replace(exp_date, which(sub_cat_covid19_hospital=="hospitalised"), NA),
                    out_date = replace(out_date, which(out_date>end_date), NA))
    
    df <- df[df$end_date>=df$index_date,]
    df$index_date <- as.Date(df$index_date)
    
    df[,colnames(df)[grepl("sub_",colnames(df))]] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")))
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_covid_history ------------------------------------------
  
  if (active_analyses$analysis[i]=="sub_covid_history") {
    
    print('Make model input: sub_covid_history')
    
    df <- input[input$sub_bin_covid19_confirmed_history==TRUE,]
    
    df[,colnames(df)[grepl("sub_",colnames(df))]] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")))
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_sex_female ---------------------------------------------
  
  
  if (active_analyses$analysis[i]=="sub_sex_female") {
    
    print('Make model input: sub_sex_female')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_sex=="Female",]
    
    df[,c(colnames(df)[grepl("sub_",colnames(df))],"cov_cat_sex")] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")))
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_sex_male -----------------------------------------------
  
  if (active_analyses$analysis[i]=="sub_sex_male") {
    
    print('Make model input: sub_sex_male')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_sex=="Male",]
    
    df[,c(colnames(df)[grepl("sub_",colnames(df))],"cov_cat_sex")] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")))
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_age_18_39 ----------------------------------------------
  
  if (active_analyses$analysis[i]=="sub_age_18_39") {
    
    print('Make model input: sub_age_18_39')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_num_age>=18 &
                  input$cov_num_age<40,]
    
    df[,colnames(df)[grepl("sub_",colnames(df))]] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")))
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_age_40_59 ----------------------------------------------
  
  if (active_analyses$analysis[i]=="sub_age_40_59") {
    
    print('Make model input: sub_age_40_59')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_num_age>=40 &
                  input$cov_num_age<60,]
    
    df[,colnames(df)[grepl("sub_",colnames(df))]] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")))
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_age_60_79 ----------------------------------------------
  
  if (active_analyses$analysis[i]=="sub_age_60_79") {
    
    print('Make model input: sub_age_60_79')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_num_age>=60 &
                  input$cov_num_age<80,]
    
    df[,colnames(df)[grepl("sub_",colnames(df))]] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")))
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_age_80_110 ---------------------------------------------
  
  if (active_analyses$analysis[i]=="sub_age_80_110") {
    
    print('Make model input: sub_age_80_110')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_num_age>=80 &
                  input$cov_num_age<111,]
    
    df[,colnames(df)[grepl("sub_",colnames(df))]] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")))
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_ethnicity_white --------------------------------------
  
  if (active_analyses$analysis[i]=="sub_ethnicity_white") {
    
    print('Make model input: sub_ethnicity_white')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_ethnicity=="White",]
    
    df[,colnames(df)[grepl("sub_",colnames(df))]] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")))
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_ethnicity_black --------------------------------------
  
  if (active_analyses$analysis[i]=="sub_ethnicity_black") {
    
    print('Make model input: sub_ethnicity_black')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_ethnicity=="Black",]
    
    df[,colnames(df)[grepl("sub_",colnames(df))]] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")))
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_ethnicity_mixed ----------------------------------------
  
  if (active_analyses$analysis[i]=="sub_ethnicity_mixed") {
    
    print('Make model input: sub_ethnicity_mixed')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_ethnicity=="Mixed",]
    
    df[,c(colnames(df)[grepl("sub_",colnames(df))],"cov_cat_ethnicity")] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")))
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_ethnicity_asian --------------------------------------
  
  if (active_analyses$analysis[i]=="sub_ethnicity_asian") {
    
    print('Make model input: sub_ethnicity_asian')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_ethnicity=="South Asian",]
    
    df[,c(colnames(df)[grepl("sub_",colnames(df))],"cov_cat_ethnicity")] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")))
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_ethnicity_other ----------------------------------------
  
  if (active_analyses$analysis[i]=="sub_ethnicity_other") {
    
    print('Make model input: sub_ethnicity_other')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE & 
                  input$cov_cat_ethnicity=="Other",]
    
    df[,c(colnames(df)[grepl("sub_",colnames(df))],"cov_cat_ethnicity")] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")))
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_priorhistory_none --------------------------------------

  if (active_analyses$analysis[i]=="sub_priorhistory_none") {
    
    print('Make model input: sub_priorhistory_none')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE,]
    df <- dplyr::rename(df, "priorhistory" = gsub("out_date","cov_bin_priorhistory",active_analyses$outcome[i]))
    df <- df[df$priorhistory=="none",]
    
    df[,c(colnames(df)[grepl("sub_",colnames(df))],"priorhistory")] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")))
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
  # Make model input: sub_priorhistory_recent --------------------------------------
  
  if (active_analyses$analysis[i]=="sub_priorhistory_recent") {
    
    print('Make model input: sub_priorhistory_recent')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE,]
    df <- dplyr::rename(df, "priorhistory" = gsub("out_date","cov_bin_priorhistory",active_analyses$outcome[i]))
    df <- df[df$priorhistory=="recent",]
    
    df[,c(colnames(df)[grepl("sub_",colnames(df))],"priorhistory")] <- NULL
    
    check_vitals(df)
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")))
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
    
  # Make model input: sub_priorhistory_notrecent --------------------------------------
  
  if (active_analyses$analysis[i]=="sub_priorhistory_notrecent") {
    
    print('Make model input: sub_priorhistory_notrecent')
    
    df <- input[input$sub_bin_covid19_confirmed_history==FALSE,]
    df <- dplyr::rename(df, "priorhistory" = gsub("out_date","cov_bin_priorhistory",active_analyses$outcome[i]))
    df <- df[df$priorhistory=="notrecent",]
    
    df[,c("sub_bin_covid19_confirmed_history","priorhistory")] <- NULL
    readr::write_rds(df, file.path("output", paste0("model_input-",active_analyses$name[i],".rds")))
    print(paste0("Saved: output/model_input-",active_analyses$name[i],".rds"))
    rm(df)
    
  }
  
}
