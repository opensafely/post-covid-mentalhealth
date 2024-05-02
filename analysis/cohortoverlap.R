# Load libraries ----
print('Load libraries')

library(readr)
library(dplyr)
library(magrittr)

# Specify redaction threshold ----
print('Specify redaction threshold')

threshold <- 6

# Source common functions ----
print('Source common functions')

source("analysis/utility.R")

# Specify arguments ----
print('Specify arguments')

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  outcome <- "anxiety_general"
} else {
  outcome <- args[[1]]
}

# Load cohort data ----
print('Load cohort data')

for (cohort in c("prevax","vax","unvax")) {
  
  tmp <- readr::read_rds(paste0("output/model_input-cohort_",cohort,ifelse(cohort=="vax","","_extf"),"-day0_main-",outcome,".rds"))
  
  if (cohort %in% c("vax","unvax")) {
    tmp$end_date_exposure <- tmp$end_date_outcome
  }
  
  tmp <- tmp[,c("patient_id","index_date","exp_date","out_date","end_date_exposure","end_date_outcome")]
  
  tmp <- tmp %>% 
    dplyr::mutate(exposure = replace(exp_date, which(exp_date>end_date_exposure | exp_date<index_date), NA),
                  outcome = replace(out_date, which(out_date>end_date_outcome | out_date<index_date), NA))
 
  tmp$end_date <- min(tmp$end_date_outcome, tmp$out_date, na.rm = TRUE)
  
  tmp <- tmp[,c("patient_id","index_date","end_date")]
  
  tmp <- tmp[tmp$index_date<=tmp$end_date,]
  
  assign(cohort, tmp)
  
}

rm(tmp)

# Create empty data frame to record information ----
print('Create empty data frame to record information')

df <- data.frame(outcome = rep(outcome, 4),
                 date = c("2020-01-01",
                          "2021-06-01",
                          "2021-06-18",
                          "2021-12-14"),
                 description = c("Start of follow-up for the pre-vaccine availability cohort",
                                 "Start of follow-up for the vaccinated and unvaccinated cohorts",
                                 "End of ascertainment of COVID-19 diagnoses for the pre-vaccine availability cohort",
                                 "End of ascertainment of outcomes for all cohorts"),
                 prevax_only = rep(NA,4),
                 vax_only = rep(NA,4),
                 unvax_only = rep(NA,4),
                 prevax_vax = rep(NA,4),
                 prevax_unvax = rep(NA,4),
                 vax_unvax = rep(NA,4), # This should always be zero
                 total_prevax = rep(NA,4),
                 total_vax = rep(NA,4),
                 total_unvax = rep(NA,4))

# Record number of patients on 2020-01-01 ----
print('Record number of patients on 2020-01-01')

date <- "2020-01-01"

df[df$date==date,"prevax_only"] <- nrow(prevax[prevax$index_date==date,])

# Record number of patients on 2021-06-01 ----
print('Record number of patients on 2021-06-01')

date <- "2021-06-01"

prevax <- prevax[prevax$end_date>=date,]

df[df$date==date,"prevax_only"] <- length(setdiff(prevax[prevax$index_date<=date,]$patient_id, c(vax[vax$index_date==date,]$patient_id, unvax[unvax$index_date==date,]$patient_id)))
df[df$date==date,"vax_only"] <- length(setdiff(vax[vax$index_date==date,]$patient_id, c(prevax[prevax$index_date<=date,]$patient_id, unvax[unvax$index_date==date,]$patient_id)))
df[df$date==date,"unvax_only"] <- length(setdiff(unvax[unvax$index_date==date,]$patient_id, c(prevax[prevax$index_date<=date,]$patient_id, vax[vax$index_date==date,]$patient_id)))
df[df$date==date,"prevax_vax"] <- length(intersect(prevax[prevax$index_date<=date,]$patient_id,vax[vax$index_date==date,]$patient_id))
df[df$date==date,"prevax_unvax"] <- length(intersect(prevax[prevax$index_date<=date,]$patient_id,unvax[unvax$index_date==date,]$patient_id))
df[df$date==date,"vax_unvax"] <- length(intersect(vax[vax$index_date==date,]$patient_id,unvax[unvax$index_date==date,]$patient_id))
df[df$date==date,"total_prevax"] <- nrow(prevax)
df[df$date==date,"total_vax"] <- nrow(vax)
df[df$date==date,"total_unvax"] <- nrow(unvax)

# Record number of patients on 2021-06-18 ----
print('Record number of patients on 2021-06-18')

date <- "2021-06-18"

prevax <- prevax[prevax$end_date>=date,]
vax <- vax[vax$end_date>=date,]
unvax <- unvax[unvax$end_date>=date,]

df[df$date==date,"prevax_only"] <- length(setdiff(prevax[prevax$index_date<=date,]$patient_id, c(vax[vax$index_date<=date,]$patient_id, unvax[unvax$index_date<=date,]$patient_id)))
df[df$date==date,"vax_only"] <- length(setdiff(vax[vax$index_date<=date,]$patient_id, c(prevax[prevax$index_date<=date,]$patient_id, unvax[unvax$index_date<=date,]$patient_id)))
df[df$date==date,"unvax_only"] <- length(setdiff(unvax[unvax$index_date<=date,]$patient_id, c(prevax[prevax$index_date<=date,]$patient_id, vax[vax$index_date<=date,]$patient_id)))
df[df$date==date,"prevax_vax"] <- length(intersect(prevax[prevax$index_date<=date,]$patient_id,vax[vax$index_date<=date,]$patient_id))
df[df$date==date,"prevax_unvax"] <- length(intersect(prevax[prevax$index_date<=date,]$patient_id,unvax[unvax$index_date<=date,]$patient_id))
df[df$date==date,"vax_unvax"] <- length(intersect(vax[vax$index_date<=date,]$patient_id,unvax[unvax$index_date<=date,]$patient_id))
df[df$date==date,"total_prevax"] <- nrow(prevax)
df[df$date==date,"total_vax"] <- nrow(vax)
df[df$date==date,"total_unvax"] <- nrow(unvax)

# Record number of patients on 2021-12-14 ----
print('Record number of patients on 2021-12-14')

date <- "2021-12-14"

prevax <- prevax[prevax$end_date>=date,]
vax <- vax[vax$end_date>=date,]
unvax <- unvax[unvax$end_date>=date,]

df[df$date==date,"prevax_only"] <- length(setdiff(prevax[prevax$index_date<=date,]$patient_id, c(vax[vax$index_date<=date,]$patient_id, unvax[unvax$index_date<=date,]$patient_id)))
df[df$date==date,"vax_only"] <- length(setdiff(vax[vax$index_date<=date,]$patient_id, c(prevax[prevax$index_date<=date,]$patient_id, unvax[unvax$index_date<=date,]$patient_id)))
df[df$date==date,"unvax_only"] <- length(setdiff(unvax[unvax$index_date<=date,]$patient_id, c(prevax[prevax$index_date<=date,]$patient_id, vax[vax$index_date<=date,]$patient_id)))
df[df$date==date,"prevax_vax"] <- length(intersect(prevax[prevax$index_date<=date,]$patient_id,vax[vax$index_date<=date,]$patient_id))
df[df$date==date,"prevax_unvax"] <- length(intersect(prevax[prevax$index_date<=date,]$patient_id,unvax[unvax$index_date<=date,]$patient_id))
df[df$date==date,"vax_unvax"] <-  length(intersect(vax[vax$index_date<=date,]$patient_id,unvax[unvax$index_date<=date,]$patient_id))
df[df$date==date,"total_prevax"] <- nrow(prevax)
df[df$date==date,"total_vax"] <- nrow(vax)
df[df$date==date,"total_unvax"] <- nrow(unvax)

# Save output ----
print('Save output')

write.csv(df, paste0("output/cohortoverlap_",outcome,".csv"), row.names = FALSE)

# Perform redaction ----
print('Perform redaction')

df$prevax_only_midpoint6 <- roundmid_any(as.numeric(df$prevax_only), to=threshold)
df$vax_only_midpoint6 <- roundmid_any(as.numeric(df$vax_only), to=threshold)
df$unvax_only_midpoint6 <- roundmid_any(as.numeric(df$unvax_only), to=threshold)
df$prevax_vax_midpoint6 <- roundmid_any(as.numeric(df$prevax_vax), to=threshold)
df$prevax_unvax_midpoint6 <- roundmid_any(as.numeric(df$prevax_unvax), to=threshold)
df$vax_unvax_midpoint6 <- roundmid_any(as.numeric(df$vax_unvax), to=threshold)
df$total_prevax_midpoint6 <- roundmid_any(as.numeric(df$total_prevax), to=threshold)
df$total_vax_midpoint6 <- roundmid_any(as.numeric(df$total_vax), to=threshold)
df$total_unvax_midpoint6 <- roundmid_any(as.numeric(df$total_unvax), to=threshold)

# Save redacted output ----
print('Save redacted output')

df <- df[,c("outcome","date","description",colnames(df)[grepl("_midpoint6",colnames(df))])]
write.csv(df, paste0("output/cohortoverlap_",outcome,"_midpoint6.csv"), row.names = FALSE)