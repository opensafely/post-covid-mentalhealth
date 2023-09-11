# This script replaces the variable 'out_date_sucide', which is sourced from HES
# and the death registry with 'tmp_out_date_suicide_death' so that the new variable
# is derived from the death registry only. This is not best practice but saves
# rerunning the study definitions at this late stage as all the data we need is
# already extracted.

for (cohort in c("prevax_extf","vax","unvax_extf")) {   
  
  print(paste0("Cohort: ", cohort))
  
  # Load stage 1 data ----------------------------------------------------------
  print("Load stage 1 data")
  
  df <- readr::read_rds(paste0("output/input_",cohort,"_stage1.rds"))

  # Load Venn data to get outcome source data ----------------------------------
  print("Load Venn data to get outcome source data")
  
  tmp <- readr::read_rds(paste0("output/venn_",cohort,".rds"))
  
  # Format 'new' suicide variable ----------------------------------------------
  print("Format 'new' suicide variable")
  
  tmp <- tmp[tmp$patient_id %in% df$patient_id,
             c("patient_id","tmp_out_date_suicide_death")]
  
  tmp <- dplyr::rename(tmp, "out_date_suicide" = "tmp_out_date_suicide_death")
  
  # Remove 'old' suicide variable ----------------------------------------------
  print("Remove 'old' suicide variable")
  
  df[,c("out_date_suicide")] <- NULL
  
  # Merge 'new' suicide variable -----------------------------------------------
  print("Merge 'new' suicide variable")
  
  df <- merge(df, tmp, by = c("patient_id"))
  
  # Save corrected stage 1 data ------------------------------------------------
  print("Save corrected stage 1 data")
  
  saveRDS(df, 
          file = paste0("output/input_",cohort,"_stage1_v1.rds"), 
          compress = TRUE)
  
}