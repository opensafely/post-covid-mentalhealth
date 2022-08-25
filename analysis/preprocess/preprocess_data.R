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

tictoc::tic()
library(magrittr)
library(dplyr)
library(tidyverse)
library(lubridate)

args <- commandArgs(trailingOnly=TRUE)
print(length(args))
if(length(args)==0){
  # interactive testing
  cohort_name <- "prevax" #"all"
  # cohort_name <- "vax"
  # cohort_name <- "unvax"
} else {
  cohort_name <- args[[1]]
}
# FILE PATHS

fs::dir_create(here::here("output", "not-for-review"))
fs::dir_create(here::here("output", "review"))

# Read cohort dataset ---------------------------------------------------------- 

df <- arrow::read_feather(file = paste0("output/input_",cohort_name,".feather") )

message(paste0("Dataset has been read successfully with N = ", nrow(df), " rows"))

#Add death_date from prelim data
prelim_data <- read_csv("output/index_dates.csv") %>%
  select(c(patient_id,death_date))
df <- df %>% inner_join(prelim_data,by="patient_id")

message("Death date added!")

# Format columns ---------------------------------------------------------------
# dates, numerics, factors, logicals

df <- df %>%
  mutate(across(c(contains("_date")),
                ~ floor_date(as.Date(., format="%Y-%m-%d"), unit = "days")),
         across(contains('_birth_year'),
                ~ format(as.Date(.), "%Y")),
         across(contains('_num') & !contains('date'), ~ as.numeric(.)),
         across(contains('_cat'), ~ as.factor(.)),
         across(contains('_bin'), ~ as.logical(.)))


# Overwrite vaccination information for dummy data and vax cohort only --

# if(Sys.getenv("OPENSAFELY_BACKEND") %in% c("", "expectations") &&
#    cohort_name %in% c("vax")) {
#   source("analysis/preprocess/modify_dummy_vax_data.R")
#   message("Vaccine information overwritten successfully")
# }

# Describe data ----------------------------------------------------------------

sink(paste0("output/not-for-review/describe_",cohort_name,".txt"))
print(Hmisc::describe(df))
sink()

message ("Cohort ",cohort_name, " description written successfully!")

#Combine BMI variables to create one history of obesity variable ---------------

df$cov_bin_obesity <- ifelse(df$cov_bin_obesity == TRUE | 
                               df$cov_cat_bmi_groups=="Obese",TRUE,FALSE)
df[,c("cov_num_bmi")] <- NULL

# QC for consultation variable--------------------------------------------------
#max to 365 (average of one per day)
df <- df %>%
  mutate(cov_num_consulation_rate = replace(cov_num_consulation_rate, 
                                            cov_num_consulation_rate > 365, 365))

# Format columns ---------------------------------------------------------------

# READ IN INDEX DATES AND SUMMARISE TO LOG FILE

# index_dates <- readr::read_csv(file = "output/index_dates.csv")
# for(i in names(index_dates)){
#   print(summary(index_dates[i]))
# }

# CREATE PREPROCESS FUNCTION

# preprocess <- function(cohort_name){
#   # Create spine dataset ---------------------------------------------------------
# 
#   if(cohort_name == "prevax" | cohort_name == "unvax"){
# 
#     dfspine <- arrow::read_feather(file = "output/input_prelim.feather",
#                                    col_select = -c("cov_cat_sex",
#                                                    "vax_jcvi_age_1",
#                                                    "vax_jcvi_age_2",
#                                                    "vax_cat_jcvi_group",
#                                                    "vax_date_eligible"))
#   } else if (cohort_name == "vax"){
# 
#     dfspine <- arrow::read_feather(file = "output/input_prelim.feather",
#                                    col_select = -c("cov_cat_sex"))
#   }
# 
#   print(paste0(cohort_name," Spine dataset (input prelim feather) read in successfully"))
#   print(paste0(cohort_name," ", nrow(dfspine), " rows in spine dataset"))
# 
#   ## Load dataset
#   df <- arrow::read_feather(file = paste0("output/input_",cohort_name,".feather"))
# 
#   print(paste0(cohort_name," ", nrow(df), " rows in input dataset"))
#   print(purrr::map(df, ~sum(is.na(.))))
#   print(summary(df))
# 
#   ## merge with spine
# 
#   df <- merge(df,dfspine, by = "patient_id")
# 
#   print(paste0(cohort_name," ", nrow(df), " rows in dataset after merging spine with input"))


  # Format columns -----------------------------------------------------
  # dates, numerics, factors, logicals
  
  # df <- df %>%
  #   #dplyr::rename(#tmp_out_max_hba1c_mmol_mol_date = tmp_out_num_max_hba1c_date,
  #                 #tmp_out_bmi_date_measured = cov_num_bmi_date_measured) %>%
  #   mutate(across(contains('_date'), ~ as.Date(as.character(.)))) %>% #convert to date format
  #   mutate(across(contains('_birth_year'), ~ format(as.Date(.), "%Y"))) %>% #convert numbers to numbers format p1
  #   mutate(across(contains('_num'), ~ as.numeric(.))) %>% #convert numbers to numbers format p2
  #   mutate(across(contains('_cat'), ~ as.factor(.))) %>% #convert categories to factor format
  #   mutate(across(contains('_bin'), ~ as.logical(.))) #convert binaries to logical format
  
  # print("Columns formatted successfully")
  
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
  
  df <- df[!is.na(df$patient_id),]
  df[,c("sub_date_covid19_hospital")] <- NULL

  message("COVID19 severity determined successfully")
  
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
  
  
  df1 <- df%>% select(patient_id,"death_date",starts_with("index_date_"),
                      starts_with("end_date_"),
                      contains("sub_"), # Subgroups
                      contains("exp_"), # Exposures
                      contains("out_"), # Outcomes
                      contains("cov_"), # Covariates
                      contains("qa_"), # Quality assurance
                      #contains("step"), # diabetes steps
                      contains("vax_date_eligible"), # Vaccination eligibility
                      contains("vax_date_"), # Vaccination dates and vax type 
                      #contains("vax_cat_")# Vaccination products
  )
  
  # df1 <- df %>% 
  #   # dplyr::select(- vax_jcvi_age_1, - vax_jcvi_age_2) %>% #  remove JCVI variables
  #   # select patient id, death date and variables: subgroups, exposures, outcomes, covariates, quality assurance and vaccination
  #   # need diabetes "step" variables for flowchart (diabetes_flowchart.R)
  #   # dplyr::select(patient_id, death_date,
  #   #               contains(c("sub_", "exp_", "out_", "cov_", "qa_", "vax_", "step"))) %>%
  #   # dplyr::select(-contains("df_out_")) %>%
  #   dplyr::select(-contains("tmp_"))
  
  # Repo specific preprocessing 
  
  saveRDS(df1, file = paste0("output/input_",cohort_name,".rds"))
  
  message(paste0("Input data saved successfully with N = ", nrow(df1), " rows"))
  
  # SAVE
  
  saveRDS(df1, file = paste0("output/input_",cohort_name,".rds"))
  
  print(paste0(cohort_name," ","Dataset saved successfully"))
  
  # Describe data --------------------------------------------------------------
  
  sink(paste0("output/not-for-review/describe_input_",cohort_name,"_stage0.txt"))
  print(Hmisc::describe(df1))
  sink()
  
  # Restrict columns and save Venn diagram input dataset -----------------------
  
  df2 <- df %>% select(starts_with(c("patient_id","tmp_out_date","out_date")))
  
  # Describe data --------------------------------------------------------------
  
  sink(paste0("output/not-for-review/describe_venn_",cohort_name,".txt"))
  print(Hmisc::describe(df2))
  sink()
  
  saveRDS(df2, file = paste0("output/venn_",cohort_name,".rds"))
  
  message("Venn diagram data saved successfully")
  tictoc::toc() 
  
#   # SAVE
#   ## create folders for outputs
#   # fs::dir_create(here::here("output", "venn"))
#   saveRDS(df, file = paste0("output/venn_",cohort_name,".rds"))
#   
#   print(paste0(cohort_name,"Venn dataset saved successfully"))
#   
# }

# Run function using specified commandArgs

# if(cohort_name == "all"){
#   preprocess("prevax")
#   preprocess("vax")
#   preprocess("unvax")
# }else{
#   preprocess(cohort_name)
# }

# END