##################################################################################
# 
# Description: This script reads in the input data and prepares it for data cleaning.
#
# Input: output/input.feather
# Output: output/
#
# Author(s): Rachel Denholm,  Kurt Taylor
#
# Date last updated: 
#
##################################################################################

# Load libraries ---------------------------------------------------------------

library(magrittr)
library(tidyverse)
library(lubridate)

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  cohort_name <- "all" # interactive testing
} else {
  cohort_name <- args[[1]]
}
# FILE PATHS

fs::dir_create(here::here("output", "not-for-review"))
fs::dir_create(here::here("output", "review"))

preprocess <- function(cohort_name){
  # Create spine dataset ---------------------------------------------------------
  
  if(cohort_name == "prevax" | cohort_name == "unvax"){
    
    dfspine <- arrow::read_feather(file = "output/input_prelim.feather",
                                   col_select = -c("cov_cat_sex",
                                                   "vax_jcvi_age_1",
                                                   "vax_jcvi_age_2",
                                                   "vax_cat_jcvi_group",
                                                   "vax_date_eligible"))
  } else if (cohort_name == "vax"){
    
    dfspine <- arrow::read_feather(file = "output/input_prelim.feather", 
                                   col_select = -c("cov_cat_sex"))
  }
  
  print(paste0(cohort_name," Spine dataset (input prelim feather) read in successfully"))
  print(paste0(cohort_name," ", nrow(dfspine), " rows in spine dataset"))
  
  ## Load dataset
  df <- arrow::read_feather(file = paste0("output/input_",cohort_name,".feather"))
  
  print(paste0(cohort_name," ", nrow(df), " rows in input dataset"))
  
  ## merge with spine 
  
  df <- merge(df,dfspine, by = "patient_id")
  
  print(paste0(cohort_name," ", nrow(df), " rows in dataset after merging spine with input"))
  
  # QC for consultation variable
  # max to 365 (average of one per day)
  
  print(paste0(cohort_name,"Consultation variable before QC"))
  summary(df$cov_num_consulation_rate)
  
  df <- df %>%
    mutate(cov_num_consulation_rate = replace(cov_num_consulation_rate, cov_num_consulation_rate > 365, 365))
  
  print(paste0(cohort_name,"Consultation variable after QC"))
  summary(df$cov_num_consulation_rate)
  
  # Combine BMI variables to create one history of obesity variable ---------------
  
  df <- df %>%
    mutate(cov_bin_obesity = ifelse(cov_bin_obesity == TRUE | cov_cat_bmi_groups == "Obese", TRUE, FALSE)) %>%
    dplyr::select(- cov_num_bmi)
  
  # Overwrite vaccination information for dummy data only ------------------------
  
  # if(Sys.getenv("OPENSAFELY_BACKEND") %in% c("", "expectations")) {
  #   source("analysis/modify_dummy_vax_data.R")
  #   print("Vaccine information overwritten successfully")
  # }
  # 
  # Format columns -----------------------------------------------------
  # dates, numerics, factors, logicals
  
  df <- df %>%
    #dplyr::rename(#tmp_out_max_hba1c_mmol_mol_date = tmp_out_num_max_hba1c_date,
                  #tmp_out_bmi_date_measured = cov_num_bmi_date_measured) %>%
    mutate(across(contains('_date'), ~ as.Date(as.character(.)))) %>% #convert to date format
    mutate(across(contains('_birth_year'), ~ format(as.Date(.), "%Y"))) %>% #convert numbers to numbers format p1
    mutate(across(contains('_num'), ~ as.numeric(.))) %>% #convert numbers to numbers format p2
    mutate(across(contains('_cat'), ~ as.factor(.))) %>% #convert categories to factor format
    mutate(across(contains('_bin'), ~ as.logical(.))) #convert binaries to logical format
  
  print("Columns formatted successfully")
  
  # Define COVID-19 severity --------------------------------------------------------------
  
  df <- df %>%
    mutate(sub_cat_covid19_hospital = 
             ifelse(!is.na(exp_date_covid19_confirmed) &
                      !is.na(sub_date_covid19_hospital) &
                      sub_date_covid19_hospital - exp_date_covid19_confirmed >= 0 &
                      sub_date_covid19_hospital - exp_date_covid19_confirmed < 29, "hospitalised",
                    ifelse(!is.na(exp_date_covid19_confirmed), "non_hospitalised", 
                           ifelse(is.na(exp_date_covid19_confirmed), "no_infection", NA)))) %>%
    mutate(across(sub_cat_covid19_hospital, factor))
  
  # Define diabetes outcome (using Sophie Eastwood algorithm) ----------------------------
  
  # Create vars for mental health outcomes -------------------------------------------------------------
  
  #Mental Health - Primary care (depression; anxiety; self-harm; serious mental illness)
  df<- df %>% mutate(out_date_depression_primarycare = tmp_out_date_depression_snomed,
                     out_date_anxiety_general_primarycare = tmp_out_date_anxiety_general_snomed,
                     out_date_serious_mental_illness_primarycare = tmp_out_date_serious_mental_illness_snomed,
                     out_date_self_harm_primarycare = tmp_out_date_self_harm_snomed)
  
  print("Mental health primary care variables created successfully")
  
  #Mental Health - Secondary care (depression; anxiety; self-harm; serious mental illness)
  df<- df %>% mutate(out_date_depression_secondarycare = tmp_out_date_depression_hes,
                     out_date_anxiety_general_secondarycare = tmp_out_date_anxiety_general_hes,
                     out_date_serious_mental_illness_secondarycare = tmp_out_date_serious_mental_illness_hes,
                     out_date_self_harm_secondarycare = tmp_out_date_self_harm_hes)
  
  print("Mental health secondary care variables created successfully")
  
  # Restrict columns and save analysis dataset ---------------------------------
  
  df1 <- df %>% 
    # dplyr::select(- vax_jcvi_age_1, - vax_jcvi_age_2) %>% #  remove JCVI variables
    # select patient id, death date and variables: subgroups, exposures, outcomes, covariates, quality assurance and vaccination
    # need diabetes "step" variables for flowchart (diabetes_flowchart.R)
    # dplyr::select(patient_id, death_date,
    #               contains(c("sub_", "exp_", "out_", "cov_", "qa_", "vax_", "step"))) %>%
    # dplyr::select(-contains("df_out_")) %>%
    dplyr::select(-contains("tmp_"))
  
  # Describe data --------------------------------------------------------------
  
  sink(paste0("output/not-for-review/describe_input_",cohort_name,"_stage0.txt"))
  print(Hmisc::describe(df1))
  sink()
  
  # SAVE
  
  saveRDS(df1, file = paste0("output/input_",cohort_name,".rds"))
  
  print(paste0(cohort_name,"Dataset saved successfully"))
  
  # Restrict columns and save Venn diagram input dataset -----------------------
  
  # df2 <- df %>% 
  #   dplyr::select(patient_id,
  #                 starts_with(c("out_")))
  
  # SAVE
  ## create folders for outputs
  # fs::dir_create(here::here("output", "venn"))
  saveRDS(df, file = paste0("output/venn_",cohort_name,".rds"))
  
  print(paste0(cohort_name,"Venn dataset saved successfully"))
  
}

# Run function using specified commandArgs

if(cohort_name == "all"){
  preprocess("prevax")
  preprocess("vax")
  preprocess("unvax")
}else{
  preprocess(cohort_name)
}

# END