# Create output directory ------------------------------------------------------

fs::dir_create(here::here("lib"))

# Create empty data frame ------------------------------------------------------

df <- data.frame(active = logical(),
                 outcome = character(),
                 outcome_variable = character(),
                 covariates = character(),
                 model = character(),
                 cohort	= character(),
                 main = character(),
                 covid_history = character(),
                 covid_pheno_hospitalised = character(),
                 covid_pheno_non_hospitalised = character(),
                 agegp_18_39 = character(),
                 agegp_40_59 = character(),
                 agegp_60_79 = character(),
                 agegp_80_110 = character(),
                 sex_Male = character(),
                 sex_Female = character(),
                 ethnicity_White = character(),
                 ethnicity_Mixed = character(),
                 ethnicity_South_Asian = character(),
                 ethnicity_Black = character(),
                 ethnicity_Other = character(),
                 ethnicity_Missing = character(),
                 prior_history_TRUE = character(),
                 prior_history_FALSE = character(),
                 prior_history_var = character(),
                 outcome_group = character(),
                 venn = character(),
                 stringsAsFactors = FALSE)

# Add Mental Health outcomes --------------------------------------------------------

outcomes <- c("Depression", "Depression - Prescription", "Depression - Primary Care", "Depression - Secondary Care", 
              "Anxiety - general", "Anxiety - general Prescription", "Anxiety - general Primary Care", "Anxiety - general Secondary Care",
              "Anxiety - obsessive compulsive disorder", "Anxiety - post traumatic stress disorder", "Eating disorders", 
              "Serious mental illness", "Serious mental illness - Prescription", "Serious mental illness - Primary Care", "Serious mental illness - Secondary Care",
              "Self harm", "Self harm - Primary Care", "Self harm - Secondary Care",
              "Suicide", "Addiction", "Addiction - Prescription")

outcome_group <- "Mental_health"

outcomes_short <- c("depression", "depression_prescription", "depression_primarycare", "depression_secondarycare",
                    "anxiety_general", "anxiety_general_prescription","anxiety_general_primarycare", "anxiety_general_secondarycare",
                    "anxiety_ocd", "anxiety_ptsd", "eating_disorders", 
                    "serious_mental_illness", "serious_mental_illness_prescription", "serious_mental_illness_primarycare", "serious_mental_illness_secondarycare",
                    "self_harm", "self_harm_primarycare", "self_harm_secondarycare",
                    "suicide", "addiction", "addiction_prescription")

outcome_venn <- c(TRUE, FALSE, FALSE, FALSE, #depression
                  TRUE, FALSE, FALSE, FALSE, #anxiety
                  TRUE, TRUE, TRUE, #anxiety -ocd, ptsd, eating disorders
                  TRUE, FALSE, FALSE, FALSE, #serious mental illness
                  TRUE, FALSE, FALSE, #self harm
                  TRUE, #suicide
                  TRUE, FALSE) #addiction


for (i in 1:length(outcomes)) {
  df[nrow(df)+1,] <- c(TRUE,
                       outcomes[i],
                       paste0("out_date_",outcomes_short[i]),
                       "cov_num_age;cov_cat_sex;cov_cat_ethnicity;cov_cat_deprivation;cov_cat_region;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_bin_recent_depression;cov_bin_history_depression;cov_bin_recent_anxiety;cov_bin_history_anxiety;cov_bin_recent_eating_disorders;cov_bin_history_eating_disorders;cov_bin_recent_serious_mental_illness;cov_bin_history_serious_mental_illness;cov_bin_recent_self_harm;cov_bin_history_self_harm",
                       rep("all",2),
                       rep(TRUE,4),
                       rep(FALSE,14),
                       "",
                       "Mental_health",
                       outcome_venn[i])
}

#Run main MH outcomes:
#df[c(2:4,6:8,13:15,17:18,21),1] <- FALSE

#prescriptions: depression, anxiety, serious mental illness, and addiction
#df[c(3:4,7:11,14:19),1] <- FALSE

#Depression: main, prescription, primary and secondary care
#df[c(5:21),1] <- FALSE
#df[c(2:4),c(8:10)] <- FALSE
#df[1,8] <- FALSE
#Anxiety: main, prescription, primary and secondary care
#df[c(1:4,9:21),1] <- FALSE
#df[c(6:8),c(8:10)] <- FALSE
#df[5,8] <- FALSE
#Serious mental illness
#df[c(1:11,16:21),1] <- FALSE
#df[c(13:15),c(8:10)] <- FALSE
#df[12,8] <- FALSE
#self harm
#df[c(1:15,19:21),1] <- FALSE
#df[c(17:18),c(8:10)] <- FALSE
#df[16,8] <- FALSE
#Addiction
df[c(1:19),1] <- FALSE
df[21,c(8:10)] <- FALSE
df[20,8] <- FALSE


#self harm
#df[c(1:15,17:21),1] <- FALSE
#df[c(1:15,19:21),1] <- FALSE 
#df[c(17:18),c(8:10)] <- FALSE 
#df[c(1:15,19:21),1] <- FALSE
#df[c(17:18), c(8:10)] <- FALSE
#Run Primary care
#df[c(1:2,4:6,8:9,11:12,14:15,17:19,21:22,24:25,27:31,33), 1] <- FALSE
#Run secondary care
#df[c(1:3,5:7,9:10,12:13,15:16,18:20,22:23,25:26,28,30:32), 1] <- FALSE
#Run Secondary outcomes (Prescriptions)
#df[c(1,3:5,7:18,20:30,32:33), 1] <- FALSE
#Run Depression, Anxiety general, and Serious mental illness
#df[c(2:4,6:17,19:33), c(1, 7:24)] <- FALSE
#Run Depression, Anxiety general, and Serious mental illness + prior_history
#df[c(2:4,6:17,19:33), c(1, 7:24)] <- FALSE

#Prior_history variables:
#Depression
# df$prior_history_var <- ifelse(df$outcome=="Depression" ,"sub_bin_depression",df$prior_history_var)
# df$prior_history_TRUE <- ifelse(df$outcome=="Depression" ,TRUE,df$prior_history_TRUE)
# df$prior_history_FALSE <- ifelse(df$outcome=="Depression" ,TRUE,df$prior_history_FALSE)
# 
# # #Anxiety - general
# df$prior_history_var <- ifelse(df$outcome=="Anxiety - general" ,"sub_bin_anxiety_general",df$prior_history_var)
# df$prior_history_TRUE <- ifelse(df$outcome=="Anxiety - general" ,TRUE,df$prior_history_TRUE)
# df$prior_history_FALSE <- ifelse(df$outcome=="Anxiety - general" ,TRUE,df$prior_history_FALSE)
# # 
# # #Serious mental illness
# df$prior_history_var <- ifelse(df$outcome=="Serious mental illness" ,"sub_bin_serious_mental_illness",df$prior_history_var)
# df$prior_history_TRUE <- ifelse(df$outcome=="Serious mental illness" ,TRUE,df$prior_history_TRUE)
# df$prior_history_FALSE <- ifelse(df$outcome=="Serious mental illness" ,TRUE,df$prior_history_FALSE)
# # #Self harm
# df$prior_history_var <- ifelse(df$outcome=="Self harm" ,"sub_bin_self_harm",df$prior_history_var)
# df$prior_history_TRUE <- ifelse(df$outcome=="Self harm" ,TRUE,df$prior_history_TRUE)
# df$prior_history_FALSE <- ifelse(df$outcome=="Self harm" ,TRUE,df$prior_history_FALSE)

#df[-25,1] <- FALSE
#df[c(26:28,30:32,34:35,37:38,40:41,43:45,47:48,50:51,53,55:57), 1] <- FALSE

# Save active analyses list ----------------------------------------------------

saveRDS(df, file = "lib/active_analyses.rds")
