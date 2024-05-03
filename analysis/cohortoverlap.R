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

# Calculate cohort combinations ----

df <- data.frame(rbind(c("prevax_only",length(setdiff(prevax,c(unvax,vax)))),
                       c("vax_only",length(setdiff(vax,c(prevax,unvax)))),
                       c("unvax_only",length(setdiff(unvax,c(prevax,vax)))),
                       c("prevax_vax",length(intersect(prevax,vax))),
                       c("prevax_unvax",length(intersect(prevax,unvax))),
                       c("vax_unvax",length(intersect(vax,unvax))),
                       c("prevax_vax_unvax",length(intersect(prevax,intersect(vax,unvax))))))

colnames(df) <- c("cohort","N")

# Perform redaction ----

df$N_midpoint6 <- roundmid_any(as.numeric(df$N), to=threshold)

# Save output ----

write.csv(df[,c("cohort","N")], "output/cohortoverlap.csv", row.names = FALSE)
write.csv(df[,c("cohort","N_midpoint6")], "output/cohortoverlap_midpoint6.csv", row.names = FALSE)