# Load packages ----

library(magrittr)

# Specify redaction threshold ----

threshold <- 6

# Source common functions ----

source("analysis/utility.R")

# Derive persondays ----

for (cohort in c("prevax","vax","unvax")) {
  
  # Load data ----
  
  input <- dplyr::as_tibble(readr::read_rds(paste0("output/input_",cohort, ifelse(cohort=="vax","","_extf"),"_stage1.rds")))
  
  # Restrict to required variables for dataset preparation ----
  
  input <- input[,unique(c("patient_id",
                           "index_date",
                           "exp_date_covid19_confirmed",
                           "end_date_exposure"))]
  
  # Remove exposures outside of follow-up time ----
  
  input <- dplyr::rename(input, 
                         "exp_date" = "exp_date_covid19_confirmed")
  
  input <- input %>% 
    dplyr::mutate(exp_date =  replace(exp_date, which(exp_date>end_date_exposure | exp_date<index_date), NA))
  
  # Derive covid19 and person_persondays variables ----
  
  input <- input %>% 
    dplyr::mutate(persondays = as.numeric((exp_date - index_date))+1,
                  covid19 = !is.na(exp_date))
  
  # Restrict variables ----
  
  input <- input[,c("patient_id","covid19","persondays")]
  colnames(input) <- c("patient_id",paste0(cohort,"_",c("covid19","persondays")))
  
  # Name data ----
  
  assign(cohort, input)
  
}

# Merge dataframe ----

df <- prevax
df <- merge(df, vax, by = "patient_id", all.x = TRUE)
df <- merge(df, unvax, by = "patient_id", all.x = TRUE)

# Aggregate infections ----

df <- df %>%
  dplyr::mutate(prevax_covid19_sum = sum(prevax_covid19, na.rm = TRUE),
                prevax_persondays_sum = sum(prevax_persondays, na.rm = TRUE),
                vax_covid19_sum = sum(vax_covid19, na.rm = TRUE),
                vax_persondays_sum = sum(vax_persondays, na.rm = TRUE),
                unvax_covid19_sum = sum(unvax_covid19, na.rm = TRUE),
                unvax_persondays_sum = sum(unvax_persondays, na.rm = TRUE))

df <- unique(df[,colnames(df)[grepl("_sum",colnames(df))]])
colnames(df) <- gsub("_sum","",colnames(df))

df <- tidyr::pivot_longer(df, cols = colnames(df), names_sep = "_", names_to = c("cohort","value1"))
df <- tidyr::pivot_wider(df, names_from = "value1")

# Perform redaction ----

df$covid19_midpoint6 <- roundmid_any(as.numeric(df$covid19), to=threshold)

# Save output ----

write.csv(df[,c("cohort","covid19","persondays")], "output/cohortcovid.csv", row.names = FALSE)
write.csv(df[,c("cohort","covid19_midpoint6","persondays")], "output/cohortcovid_midpoint6.csv", row.names = FALSE)