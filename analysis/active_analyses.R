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
                  TRUE, FALSE, FALSE,  #self harm
                  TRUE, #suicide
                  TRUE, FALSE) #addiction


for (i in 1:length(outcomes)) {
  df[nrow(df)+1,] <- c(TRUE,
                       outcomes[i],
                       paste0("out_date_",outcomes_short[i]),
                       "cov_num_age;cov_cat_sex;cov_cat_ethnicity;cov_cat_deprivation;cov_cat_region;cov_cat_smoking_status;cov_bin_carehome_status;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_dementia;cov_bin_liver_disease;cov_bin_chronic_kidney_disease;cov_bin_cancer;cov_bin_hypertension;cov_bin_diabetes;cov_bin_obesity;cov_bin_chronic_obstructive_pulmonary_disease;cov_bin_ami;cov_bin_stroke_isch;cov_bin_recent_depression;cov_bin_history_depression;cov_bin_recent_anxiety;cov_bin_history_anxiety;cov_bin_recent_eating_disorders;cov_bin_history_eating_disorders;cov_bin_recent_serious_mental_illness;cov_bin_history_serious_mental_illness;cov_bin_recent_self_harm;cov_bin_history_self_harm",
                       rep("all",2),
                       rep(TRUE,18), #18 + 6 = 24 column 7 22
                       rep(FALSE,0), #18 + 6 = 24 0
                       "",
                       "Mental_health",
                       outcome_venn[i])
}

#Remove column covid_history
df[,8] <- FALSE
#Remove not necessary columns for prescriptions, primary and secondary care
df[c(2:4,6:8,13:15,17:18,21),c(9:24)] <- FALSE
df[c(2:4,6:8,13:15,17:18,21),c(9:24)] <- FALSE #remove unnecessary columns for prescriptions, primary, and secondary care
df[c(9:11,19:21),c(11:24)] <- FALSE #remove unnecessary columns for other MH outcomes (not key outcomes)
#df[c(1,5,12,16), c(25:28)] <- FALSE #remove prior_recent & prior_history
#df[c(1,5,12,16), c(27:28)] <- FALSE

#Key outcomes + prior_history
#df[c(2:4,6:11,13:15,17:21),c(1,8)]<- FALSE

#------------------------------------------------------------------------------#

#Prior_history variables:
#Depression
df$prior_history_var <- ifelse(df$outcome=="Depression" ,"sub_bin_depression",df$prior_history_var)
df$prior_history_TRUE <- ifelse(df$outcome=="Depression" ,TRUE,df$prior_history_TRUE)
df$prior_history_FALSE <- ifelse(df$outcome=="Depression" ,TRUE,df$prior_history_FALSE)

# # #Anxiety - general
df$prior_history_var <- ifelse(df$outcome=="Anxiety - general" ,"sub_bin_anxiety_general",df$prior_history_var)
df$prior_history_TRUE <- ifelse(df$outcome=="Anxiety - general" ,TRUE,df$prior_history_TRUE)
df$prior_history_FALSE <- ifelse(df$outcome=="Anxiety - general" ,TRUE,df$prior_history_FALSE)

# # #Serious mental illness
df$prior_history_var <- ifelse(df$outcome=="Serious mental illness" ,"sub_bin_serious_mental_illness",df$prior_history_var)
df$prior_history_TRUE <- ifelse(df$outcome=="Serious mental illness" ,TRUE,df$prior_history_TRUE)
df$prior_history_FALSE <- ifelse(df$outcome=="Serious mental illness" ,TRUE,df$prior_history_FALSE)

# # #Self harm
df$prior_history_var <- ifelse(df$outcome=="Self harm" ,"sub_bin_self_harm",df$prior_history_var)
df$prior_history_TRUE <- ifelse(df$outcome=="Self harm" ,TRUE,df$prior_history_TRUE)
df$prior_history_FALSE <- ifelse(df$outcome=="Self harm" ,TRUE,df$prior_history_FALSE)

#------------------------------------------------------------------------------#

#Prior_history - recent history - MH specific
#Depression
# df$prior_recent_MH_var <- ifelse(df$outcome=="Depression" ,"cov_bin_recent_depression",df$prior_recent_MH_var)
# df$prior_recent_MH_TRUE <- ifelse(df$outcome=="Depression" ,TRUE,df$prior_recent_MH_TRUE)
# df$prior_recent_MH_FALSE <- ifelse(df$outcome=="Depression" ,TRUE,df$prior_recent_MH_FALSE)

#Remove Recent Episode of Depression as covariate

# # # #Anxiety - general
# df$prior_recent_MH_var <- ifelse(df$outcome=="Anxiety - general" ,"sub_bin_recent_anxiety_general",df$prior_recent_MH_var)
# df$prior_recent_MH_TRUE <- ifelse(df$outcome=="Anxiety - general" ,TRUE,df$prior_recent_MH_TRUE)
# df$prior_recent_MH_FALSE <- ifelse(df$outcome=="Anxiety - general" ,TRUE,df$prior_recent_MH_FALSE)

#Remove Recent Episode of Anxiety as covariate

# # # #Serious mental illness
# df$prior_recent_MH_var <- ifelse(df$outcome=="Serious mental illness" ,"sub_bin_recent_serious_mental_illness",df$prior_recent_MH_var)
# df$prior_recent_MH_TRUE <- ifelse(df$outcome=="Serious mental illness" ,TRUE,df$prior_recent_MH_TRUE)
# df$prior_recent_MH_FALSE <- ifelse(df$outcome=="Serious mental illness" ,TRUE,df$prior_recent_MH_FALSE)

#Remove Recent Episode of Serious mental illness as covariate

# # # #Self harm
# df$prior_recent_MH_var <- ifelse(df$outcome=="Self harm" ,"sub_bin_recent_self_harm",df$prior_recent_MH_var)
# df$prior_recent_MH_TRUE <- ifelse(df$outcome=="Self harm" ,TRUE,df$prior_recent_MH_TRUE)
# df$prior_recent_MH_FALSE <- ifelse(df$outcome=="Self harm" ,TRUE,df$prior_recent_MH_FALSE)

#Remove Recent Episode of Self harm as covariate

#------------------------------------------------------------------------------#

#Prior_history - history - MH specific
#Depression
# df$prior_history_MH_var <- ifelse(df$outcome=="Depression" ,"sub_bin_history_depression",df$prior_history_MH_var)
# df$prior_history_MH_TRUE <- ifelse(df$outcome=="Depression" ,TRUE,df$prior_history_MH_TRUE)
# df$prior_history_MH_FALSE <- ifelse(df$outcome=="Depression" ,TRUE,df$prior_history_MH_FALSE)

#Remove History of Depression as covariate

# # # #Anxiety - general
# df$prior_history_MH_var <- ifelse(df$outcome=="Anxiety - general" ,"sub_bin_history_anxiety_general",df$prior_history_MH_var)
# df$prior_history_MH_TRUE <- ifelse(df$outcome=="Anxiety - general" ,TRUE,df$prior_history_MH_TRUE)
# df$prior_history_MH_FALSE <- ifelse(df$outcome=="Anxiety - general" ,TRUE,df$prior_history_MH_FALSE)

#Remove History of Anxiety as covariate

# # # #Serious mental illness
# df$prior_history_MH_var <- ifelse(df$outcome=="Serious mental illness" ,"sub_bin_history_serious_mental_illness",df$prior_history_MH_var)
# df$prior_history_MH_TRUE <- ifelse(df$outcome=="Serious mental illness" ,TRUE,df$prior_history_MH_TRUE)
# df$prior_history_MH_FALSE <- ifelse(df$outcome=="Serious mental illness" ,TRUE,df$prior_history_MH_FALSE)

#Remove History of Serious mental illness as covariate

# # # #Self harm
# df$prior_history_MH_var <- ifelse(df$outcome=="Self harm" ,"sub_bin_history_self_harm",df$prior_history_MH_var)
# df$prior_history_MH_TRUE <- ifelse(df$outcome=="Self harm" ,TRUE,df$prior_history_MH_TRUE)
# df$prior_history_MH_FALSE <- ifelse(df$outcome=="Self harm" ,TRUE,df$prior_history_MH_FALSE)

#Remove History of Self harm as covariate

#------------------------------------------------------------------------------#

#Run main MH outcomes:
#df[c(2:4,6:8,13:15,17:18,21),1] <- FALSE

#prescriptions: depression, anxiety, serious mental illness, and addiction
#df[c(3:4,7:11,14:19),1] <- FALSE

#Just depression
#df[c(2:21),c(1,9:24)] <- FALSE
#depression presctiption
# df[c(1,3:21),1] <- FALSE
# df[2,c(8:21)] <- FALSE

#Depression: main, prescription, primary and secondary care
#df[c(5:21),1] <- FALSE
#df[c(2:4),c(9:10)] <- FALSE
#df[c(2:4),c(8:10)] <- FALSE

#Anxiety: main, prescription, primary and secondary care
#df[c(1:4,9:21),1] <- FALSE
#df[c(6:8),c(9:10)] <- FALSE

#Serious mental illness
#df[c(1:11,16:21),1] <- FALSE
#df[c(13:15),c(9:10)] <- FALSE

#self harm
#df[c(1:15,19:21),1] <- FALSE
#df[c(17:18),c(9:10)] <- FALSE

#Addiction
#df[c(1:19),1] <- FALSE
#df[21,c(9:10)] <- FALSE

#Anxiety PTSD-OCD-Eating disorders-Suicide
#df[c(1:8,12:18,20:21),1] <- FALSE

#df[-25,1] <- FALSE
#df[c(26:28,30:32,34:35,37:38,40:41,43:45,47:48,50:51,53,55:57), 1] <- FALSE

# Save active analyses list ----------------------------------------------------

saveRDS(df, file = "lib/active_analyses.rds")
