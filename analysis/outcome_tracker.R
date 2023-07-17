# Load data --------------------------------------------------------------------

df <- vroom::vroom("lib/actions_20230717.csv")

# Restrict to cox-ipw actions --------------------------------------------------

df <- df[grepl("cox_ipw",df$action),]

# Separate action name into components -----------------------------------------

df <- tidyr::separate(data = df, 
                      col = action,
                      into = c("name","cohort","analysis","outcome"), 
                      sep = "-", 
                      remove = TRUE)

# Format data ------------------------------------------------------------------

df <- df[,c("outcome","cohort","analysis","status")]
df$cohort <- gsub("cohort_","",df$cohort)

# Pivot to wide format ---------------------------------------------------------

df <- tidyr::pivot_wider(data = df, 
                         id_cols = c("outcome","cohort"), 
                         values_from = "status",
                         names_from = "analysis")

# Order data -------------------------------------------------------------------
  
df <- df[order(df$outcome,df$cohort),
         c("outcome",
           "cohort",
           "main",
           "sub_covid_hospitalised",
           "sub_covid_nonhospitalised",
           "sub_covid_history",
           "sub_history_none",
           "sub_history_recent",
           "sub_history_notrecent",
           "sub_sex_female",
           "sub_sex_male",
           "sub_age_18_39",
           "sub_age_40_59",
           "sub_age_60_79",
           "sub_age_80_110",
           "sub_ethnicity_white",
           "sub_ethnicity_black",
           "sub_ethnicity_mixed",
           "sub_ethnicity_asian",
           "sub_ethnicity_other")]

# Save data --------------------------------------------------------------------

write.csv(df, "output/outcome_tracker.csv", row.names = FALSE, na = "N/A")