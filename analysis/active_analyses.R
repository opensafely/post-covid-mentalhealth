# Create output directory ------------------------------------------------------

fs::dir_create(here::here("lib"))

# Create empty data frame ------------------------------------------------------

df <- data.frame(cohort = character(),
                 exposure = character(), 
                 outcome = character(), 
                 ipw = logical(), 
                 strata = character(),
                 covariate_sex = character(),
                 covariate_age = character(),
                 covariate_other = character(),
                 cox_start = character(),
                 cox_stop = character(),
                 study_start = character(),
                 study_stop = character(),
                 cut_points = character(),
                 controls_per_case = numeric(),
                 total_event_threshold = numeric(),
                 episode_event_threshold = numeric(),
                 covariate_threshold = numeric(),
                 age_spline = logical(),
                 analysis = character(),
                 stringsAsFactors = FALSE)

# Set constant values ----------------------------------------------------------

age_spline <- TRUE
exposure <- "exp_date_covid19_confirmed"
strata <- "cov_cat_region"
covariate_sex <- "cov_cat_sex"
covariate_age <- "cov_num_age"
cox_start <- "index_date"
cox_stop <- "end_date_outcome"
study_stop <- "2021-12-14"
total_event_threshold <- 50L
episode_event_threshold <- 5L
covariate_threshold <- 5L

# Specify cohorts --------------------------------------------------------------

cohorts <- c("vax","unvax_extf","prevax_extf")

# Specify outcomes -------------------------------------------------------------

## Outcomes for which we will run ALL analyses

outcomes_runall <- c("out_date_depression", 
                     "out_date_serious_mental_illness")

## Outcomes for which we will run MAIN analyses only

outcomes_runmain <- c(outcomes_runall, 
                      "out_date_anxiety_general", 
                      "out_date_self_harm",
                      "out_date_anxiety_ptsd", 
                      "out_date_eating_disorders", 
                      "out_date_suicide", 
                      "out_date_addiction")

# Add active analyses ----------------------------------------------------------

for (c in cohorts) {
  
  ipw <- ifelse(c=="unvax", FALSE, TRUE)
  
  for (i in outcomes_runmain) {
    
    ## Reduce sampling for common outcomes due to memory issues ----------------
    
    controls_per_case <- ifelse(i %in% outcomes_runall, 10L, 20L) 
    
    ## analysis: main ----------------------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_cat_history_depression;cov_cat_history_anxiety_general;cov_cat_history_eating_disorders;cov_cat_history_serious_mental_illness;cov_cat_history_self_harm",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax_extf", "2020-01-01", "2021-06-01"),
                         study_stop = study_stop,
                         cut_points = ifelse(c=="prevax_extf", "28;197;365;714", "28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "main")
    
    ## analysis: sub_covid_hospitalised ----------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_cat_history_depression;cov_cat_history_anxiety_general;cov_cat_history_eating_disorders;cov_cat_history_serious_mental_illness;cov_cat_history_self_harm",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax_extf", "2020-01-01", "2021-06-01"),
                         study_stop = study_stop,
                         cut_points = ifelse(c=="prevax_extf", "28;197;365;714", "28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_covid_hospitalised")
    
    ## analysis: sub_covid_nonhospitalised -------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_cat_history_depression;cov_cat_history_anxiety_general;cov_cat_history_eating_disorders;cov_cat_history_serious_mental_illness;cov_cat_history_self_harm",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax_extf", "2020-01-01", "2021-06-01"),
                         study_stop = study_stop,
                         cut_points = ifelse(c=="prevax_extf", "28;197;365;714", "28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_covid_nonhospitalised")
    
  }
  
  for (i in outcomes_runall) {
    
    controls_per_case <- 10L
    
    ## analysis: sub_covid_history ---------------------------------------------
    
    if (c!="prevax_extf") {
      
      df[nrow(df)+1,] <- c(cohort = c,
                           exposure = exposure, 
                           outcome = i,
                           ipw = ipw, 
                           strata = strata,
                           covariate_sex = covariate_sex,
                           covariate_age = covariate_age,
                           covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_cat_history_depression;cov_cat_history_anxiety_general;cov_cat_history_eating_disorders;cov_cat_history_serious_mental_illness;cov_cat_history_self_harm",
                           cox_start = cox_start,
                           cox_stop = cox_stop,
                           study_start = ifelse(c=="prevax_extf", "2020-01-01", "2021-06-01"),
                           study_stop = study_stop,
                           cut_points = ifelse(c=="prevax_extf", "28;197;365;714", "28;197"),
                           controls_per_case = controls_per_case,
                           total_event_threshold = total_event_threshold,
                           episode_event_threshold = episode_event_threshold,
                           covariate_threshold = covariate_threshold,
                           age_spline = TRUE,
                           analysis = "sub_covid_history")
      
    }
    
    ## analysis: sub_sex_female ------------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = "NULL",
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_cat_history_depression;cov_cat_history_anxiety_general;cov_cat_history_eating_disorders;cov_cat_history_serious_mental_illness;cov_cat_history_self_harm",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax_extf", "2020-01-01", "2021-06-01"),
                         study_stop = study_stop,
                         cut_points = ifelse(c=="prevax_extf", "28;197;365;714", "28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_sex_female")
    
    ## analysis: sub_sex_male --------------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = "NULL",
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_cat_history_depression;cov_cat_history_anxiety_general;cov_cat_history_eating_disorders;cov_cat_history_serious_mental_illness;cov_cat_history_self_harm",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax_extf", "2020-01-01", "2021-06-01"),
                         study_stop = study_stop,
                         cut_points = ifelse(c=="prevax_extf", "28;197;365;714", "28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_sex_male")
    
    ## analysis: sub_age_18_39 ------------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_cat_history_depression;cov_cat_history_anxiety_general;cov_cat_history_eating_disorders;cov_cat_history_serious_mental_illness;cov_cat_history_self_harm",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax_extf", "2020-01-01", "2021-06-01"),
                         study_stop = study_stop,
                         cut_points = ifelse(c=="prevax_extf", "28;197;365;714", "28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = FALSE,
                         analysis = "sub_age_18_39")
    
    ## analysis: sub_age_40_59 ------------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_cat_history_depression;cov_cat_history_anxiety_general;cov_cat_history_eating_disorders;cov_cat_history_serious_mental_illness;cov_cat_history_self_harm",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax_extf", "2020-01-01", "2021-06-01"),
                         study_stop = study_stop,
                         cut_points = ifelse(c=="prevax_extf", "28;197;365;714", "28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = FALSE,
                         analysis = "sub_age_40_59")
    
    ## analysis: sub_age_60_79 ------------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_cat_history_depression;cov_cat_history_anxiety_general;cov_cat_history_eating_disorders;cov_cat_history_serious_mental_illness;cov_cat_history_self_harm",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax_extf", "2020-01-01", "2021-06-01"),
                         study_stop = study_stop,
                         cut_points = ifelse(c=="prevax_extf", "28;197;365;714", "28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = FALSE,
                         analysis = "sub_age_60_79")
    
    ## analysis: sub_age_80_110 ------------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_cat_history_depression;cov_cat_history_anxiety_general;cov_cat_history_eating_disorders;cov_cat_history_serious_mental_illness;cov_cat_history_self_harm",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax_extf", "2020-01-01", "2021-06-01"),
                         study_stop = study_stop,
                         cut_points = ifelse(c=="prevax_extf", "28;197;365;714", "28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = FALSE,
                         analysis = "sub_age_80_110")
    
    ## analysis: sub_ethnicity_white -------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_cat_history_depression;cov_cat_history_anxiety_general;cov_cat_history_eating_disorders;cov_cat_history_serious_mental_illness;cov_cat_history_self_harm",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax_extf", "2020-01-01", "2021-06-01"),
                         study_stop = study_stop,
                         cut_points = ifelse(c=="prevax_extf", "28;197;365;714", "28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_ethnicity_white")
    
    ## analysis: sub_ethnicity_black -------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_cat_history_depression;cov_cat_history_anxiety_general;cov_cat_history_eating_disorders;cov_cat_history_serious_mental_illness;cov_cat_history_self_harm",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax_extf", "2020-01-01", "2021-06-01"),
                         study_stop = study_stop,
                         cut_points = ifelse(c=="prevax_extf", "28;197;365;714", "28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_ethnicity_black")
    
    ## analysis: sub_ethnicity_mixed -------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_cat_history_depression;cov_cat_history_anxiety_general;cov_cat_history_eating_disorders;cov_cat_history_serious_mental_illness;cov_cat_history_self_harm",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax_extf", "2020-01-01", "2021-06-01"),
                         study_stop = study_stop,
                         cut_points = ifelse(c=="prevax_extf", "28;197;365;714", "28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_ethnicity_mixed")
    
    ## analysis: sub_ethnicity_asian -------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_cat_history_depression;cov_cat_history_anxiety_general;cov_cat_history_eating_disorders;cov_cat_history_serious_mental_illness;cov_cat_history_self_harm",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax_extf", "2020-01-01", "2021-06-01"),
                         study_stop = study_stop,
                         cut_points = ifelse(c=="prevax_extf", "28;197;365;714", "28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_ethnicity_asian")
    
    ## analysis: sub_ethnicity_other -------------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = "cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_cat_history_depression;cov_cat_history_anxiety_general;cov_cat_history_eating_disorders;cov_cat_history_serious_mental_illness;cov_cat_history_self_harm",
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax_extf", "2020-01-01", "2021-06-01"),
                         study_stop = study_stop,
                         cut_points = ifelse(c=="prevax_extf", "28;197;365;714", "28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_ethnicity_other")
    
    ## analysis: sub_history_none -----------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = gsub(";;",";",gsub(gsub("out_date","cov_cat_history",i),"","cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_cat_history_depression;cov_cat_history_anxiety_general;cov_cat_history_eating_disorders;cov_cat_history_serious_mental_illness;cov_cat_history_self_harm")),
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax_extf", "2020-01-01", "2021-06-01"),
                         study_stop = study_stop,
                         cut_points = ifelse(c=="prevax_extf", "28;197;365;714", "28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_history_none")
    
    ## analysis: sub_history_notrecent ------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = gsub(";;",";",gsub(gsub("out_date","cov_cat_history",i),"","cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_cat_history_depression;cov_cat_history_anxiety_general;cov_cat_history_eating_disorders;cov_cat_history_serious_mental_illness;cov_cat_history_self_harm")),
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax_extf", "2020-01-01", "2021-06-01"),
                         study_stop = study_stop,
                         cut_points = ifelse(c=="prevax_extf", "28;197;365;714", "28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_history_notrecent")
    
    ## analysis: sub_history_recent ---------------------------------------
    
    df[nrow(df)+1,] <- c(cohort = c,
                         exposure = exposure, 
                         outcome = i,
                         ipw = ipw, 
                         strata = strata,
                         covariate_sex = covariate_sex,
                         covariate_age = covariate_age,
                         covariate_other = gsub(";;",";",gsub(gsub("out_date","cov_cat_history",i),"","cov_cat_ethnicity;cov_cat_deprivation;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_cat_history_depression;cov_cat_history_anxiety_general;cov_cat_history_eating_disorders;cov_cat_history_serious_mental_illness;cov_cat_history_self_harm")),
                         cox_start = cox_start,
                         cox_stop = cox_stop,
                         study_start = ifelse(c=="prevax_extf", "2020-01-01", "2021-06-01"),
                         study_stop = study_stop,
                         cut_points = ifelse(c=="prevax_extf", "28;197;365;714", "28;197"),
                         controls_per_case = controls_per_case,
                         total_event_threshold = total_event_threshold,
                         episode_event_threshold = episode_event_threshold,
                         covariate_threshold = covariate_threshold,
                         age_spline = TRUE,
                         analysis = "sub_history_recent")
    
  }
  
}

# Add day 0 analyses -----------------------------------------------------------

df$analysis <- paste0("day0_",df$analysis)
df$cut_points <- gsub("28","1;28",df$cut_points)

# Assign unique name -----------------------------------------------------------

df$name <- paste0("cohort_",df$cohort, "-", 
                  df$analysis, "-", 
                  gsub("out_date_","",df$outcome))

# Check names are unique and save active analyses list -------------------------

if (length(unique(df$name))==nrow(df)) {
  saveRDS(df, file = "lib/active_analyses.rds")
} else {
  stop(paste0("ERROR: names must be unique in active analyses table"))
}