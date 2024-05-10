# Specify redaction threshold ----

threshold <- 6

# Source common functions ----

source("analysis/utility.R")

# Create vector of patient_ids for each cohort ----

for (cohort in c("prevax","vax","unvax")) {
  
  # Load data ----
  
  tmp <- readr::read_rds(paste0("output/input_",cohort,ifelse(cohort=="vax","","_extf"),"_stage1.rds"))
  
  # Remove people with history of COVID-19 ----
  
  tmp <- tmp[tmp$sub_bin_covid19_confirmed_history==FALSE,]
  
  # Assign ----
  
  patient_ids <- tmp$patient_id
  
  assign(cohort, patient_ids)
  
}

# Make a record of cohort participation ----

df <- data.frame(patient_id = unique(c(prevax,vax,unvax)))
df$prevax <- df$patient_id %in% prevax
df$vax <- df$patient_id %in% vax
df$unvax <- df$patient_id %in% unvax

df$group <- ""
df$group <- ifelse(df$prevax==TRUE & df$vax==FALSE & df$unvax==FALSE,"prevax_only",df$group)
df$group <- ifelse(df$prevax==FALSE & df$vax==TRUE & df$unvax==FALSE,"vax_only",df$group)
df$group <- ifelse(df$prevax==FALSE & df$vax==FALSE & df$unvax==TRUE,"unvax_only",df$group)
df$group <- ifelse(df$prevax==TRUE & df$vax==TRUE & df$unvax==FALSE,"prevax_vax",df$group)
df$group <- ifelse(df$prevax==TRUE & df$vax==FALSE & df$unvax==TRUE,"prevax_unvax",df$group)
df$group <- ifelse(df$prevax==FALSE & df$vax==TRUE & df$unvax==TRUE,"vax_unvax",df$group)
df$group <- ifelse(df$prevax==TRUE & df$vax==TRUE & df$unvax==TRUE,"prevax_vax_unvax",df$group)

# Calculate cohort combinations ----

df <- as.data.frame(table(df$group))
df <- dplyr::rename(df, "cohort" = "Var1", "N" = "Freq")

# Perform redaction ----

df$N_midpoint6 <- roundmid_any(as.numeric(df$N), to=threshold)

# Save output ----

write.csv(df[,c("cohort","N")], "output/cohortoverlap.csv", row.names = FALSE)
write.csv(df[,c("cohort","N_midpoint6")], "output/cohortoverlap_midpoint6.csv", row.names = FALSE)