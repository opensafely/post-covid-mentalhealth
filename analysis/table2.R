# Load libraries ---------------------------------------------------------------
print('Load libraries')

library(readr)
library(dplyr)
library(magrittr)
library(survival)

# Specify redaction threshold --------------------------------------------------
print('Specify redaction threshold')

threshold <- 6

# Source common functions ------------------------------------------------------
print('Source common functions')

source("analysis/utility.R")

# Specify arguments ------------------------------------------------------------
print('Specify arguments')

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0){
  cohort <- "prevax"
} else {
  cohort <- args[[1]]
}

# Load active analyses ---------------------------------------------------------
print('Load active analyses')

active_analyses <- readr::read_rds("lib/active_analyses.rds")
active_analyses <- active_analyses[active_analyses$cohort==cohort,]

# Make empty table 2 -----------------------------------------------------------
print('Make empty table 2')

table2 <- data.frame(name = character(),
                     cohort = character(),
                     exposure = character(),
                     outcome = character(),
                     analysis = character(),
                     unexposed_person_days = numeric(),
                     unexposed_events = numeric(),
                     exposed_person_days = numeric(),
                     exposed_events = numeric())

# Record number of events and person days for each active analysis -------------
print('Record number of events and person days for each active analysis')

for (i in 1:nrow(active_analyses)) {
  
  ## Load data -----------------------------------------------------------------
  print(paste0("Load data for ",active_analyses$name[i]))
  
  df <- read_rds(paste0("output/model_input-",active_analyses$name[i],".rds"))
  
  df <- df[,c("patient_id",
              "index_date",
              "end_date_exposure",
              "end_date_outcome",
              "exp_date",
              "out_date")]
  
  # Define arguments -----------------------------------------------------------
  print("Define arguments")
  
  outcome <- active_analyses$outcome[i]
  exposure <- active_analyses$exposure[i]
  cox_start <- active_analyses$cox_start[i]
  cox_stop <- active_analyses$cox_stop[i]
  study_start <- active_analyses$study_start[i]
  study_stop <- active_analyses$study_stop[i]

  # Make date variables dates --------------------------------------------------
  print("Make date variables dates")
  
  var_date <- colnames(df)[grepl("_date",colnames(df))]
  df[,var_date] <- lapply(df[,var_date], function(x) as.Date(x,origin="1970-01-01"))
  
  # Specify study dates ----------------------------------------------------------
  print("Specify study dates")
  
  df$study_start <- as.Date(study_start)
  df$study_stop <- as.Date(study_stop)

  # Specify follow-up dates ------------------------------------------------------
  print("Specify follow-up dates")
  
  df$fup_start <- do.call(pmax, c(df[, c("study_start", cox_start)], list(na.rm = TRUE)))
  
  df$fup_stop <- do.call(pmin, c(df[, c("study_stop", cox_stop)], list(na.rm = TRUE)))
  
  df <- df[df$fup_stop >= df$fup_start, ]
  
  # Remove exposures and outcomes outside follow-up ------------------------------
  print("Remove exposures and outcomes outside follow-up")
  
  print(paste0("Exposure data range: ", min(df$exp_date, na.rm = TRUE), " to ", max(df$exp_date, na.rm = TRUE)))
  print(paste0("Outcome data range: ", min(df$out_date, na.rm = TRUE), " to ", max(df$out_date, na.rm = TRUE)))
  
  df <- df %>% 
    dplyr::mutate(exp_date = replace(exp_date, which(exp_date>fup_stop | exp_date<fup_start), NA),
                  out_date = replace(out_date, which(out_date>fup_stop | out_date<fup_start), NA))
  
  print(paste0("Exposure data range: ", min(df$exp_date, na.rm = TRUE), " to ", max(df$exp_date, na.rm = TRUE)))
  print(paste0("Outcome data range: ", min(df$out_date, na.rm = TRUE), " to ", max(df$out_date, na.rm = TRUE)))
  
  # Make indicator variable for outcome status -----------------------------------
  print("Make indicator variable for outcome status")
  
  df$outcome_status <- df$out_date==df$fup_stop & !is.na(df$out_date) & !is.na(df$fup_stop)
  
  # Calculate where follow-up occurs in study period ---------------------------
  print("Calculate where follow-up occurs in study period")
  
  df$days_to_start <- as.numeric(df$fup_start-df$study_start)
  df$days_to_end <- as.numeric(df$fup_stop-df$study_start) + 1
  
  # Set survival data for the exposed ------------------------------------------
  print("Set survival data for the exposed")
  
  ## Filter data to exposed
  print("Filter data to exposed")
  exposed <- df[!is.na(df$exp_date),]
  
  ## Calculate days to exposure
  print("Calculate days to exposure")
  exposed$days_to_exp <- as.numeric(exposed$exp_date - exposed$study_start)
  
  ## Put into survival format
  print("Put into survival format (dataset d1)")
  d1 <- exposed[,!(colnames(exposed) %in% c("days_to_start", "days_to_exp", "days_to_end", "outcome_status"))]
  
  print("Put into survival format (dataset d2)")
  d2 <- exposed[,c("patient_id", "days_to_start", "days_to_exp", "days_to_end", "outcome_status")]
  
  print("Put into survival format (tmerge)")
  exposed <- survival::tmerge(data1=d1, 
                              data2=d2, 
                              id=patient_id,
                              outcome_status=event(days_to_end, outcome_status), 
                              tstart=days_to_start, 
                              tstop = days_to_end,
                              exposure_status=tdc(days_to_exp)) 

  # Split post-exposure time for the exposed -----------------------------------
  print("Split post-exposure time for the exposed")
  
  ## Filter to post-exposure data
  print("Filter to post-exposure data")
  exposed_post <- exposed[exposed$exposure_status==1,]
  
  ## Format tstart and tstop
  print("Format tstart and tstop")
  exposed_post <- dplyr::rename(exposed_post, t0=tstart, t=tstop) 
  exposed_post$tstart <- 0 
  exposed_post$tstop <- exposed_post$t - exposed_post$t0
  
  ## Account for pre-exposure time
  print("Account for pre-exposure time")
  
  exposed_post$tstart <- exposed_post$tstart + exposed_post$t0
  exposed_post$tstop <- exposed_post$tstop + exposed_post$t0
  exposed_post[,c("t0","t")] <- NULL
  
  # Combine pre- and post-exposure time for the exposed ------------------------
  print("Combine pre- and post-exposure time for the exposed")
  
  ## Filter to pre-exposure data
  print("Filter to pre-exposure data")
  exposed_pre <- exposed[exposed$exposure_status==0,]
  
  ## Set pre-exposure to be episode 0
  print("Set pre-exposure to be episode 0")
  exposed_pre$episode <- 0
  
  ## Bind pre- and post-exposure time
  print("Bind pre- and post-exposure time")
  exposed <- plyr::rbind.fill(exposed_pre, exposed_post)
  
  # Set survival data for the unexposed ----------------------------------------
  print("Set survival data for the unexposed")
  
  ## Filter data to unexposed
  print("Filter data to unexposed")
  unexposed <- df[is.na(df$exp_date),]
  
  ## Rename variables to survival variable names
  print("Rename variables to survival variable names")
  
  unexposed <- dplyr::rename(unexposed,
                             "tstart" = "days_to_start",
                             "tstop" = "days_to_end")
  
  unexposed$exposure_status <- c(0)
  unexposed$episode <- c(0)
  unexposed$outcome_status <- as.numeric(unexposed$outcome_status)
  
  # Combine exposed and unexposed individuals ----------------------------------
  print("Combine exposed and unexposed individuals")
  
  exposed <- exposed[,intersect(colnames(unexposed), colnames(exposed))]
  unexposed <- unexposed[,intersect(colnames(unexposed), colnames(exposed))]
  df <- rbind(exposed,unexposed)
  
  # Calculate number of events per episode -------------------------------------
  print("Calculate number of events per episode")
  
  df$episode <- ifelse(is.na(df$episode) & df$exposure_status==1, 1, df$episode)
  
  events <- df[df$outcome_status==1, c("patient_id","episode")]
  
  events <- aggregate(episode ~ patient_id, data = events, FUN = max)
  
  events <- data.frame(table(events$episode), 
                       stringsAsFactors = FALSE)
  
  events <- dplyr::rename(events, "episode" = "Var1", "N_events" = "Freq")
  
  # Add number of events to episode info table ---------------------------------
  print("Add number of events to episode info table")
  
  episode_info <- events
  episode_info$N_events <- ifelse(is.na(episode_info$N_events),0,episode_info$N_events)

  # Calculate person-time in each episode --------------------------------------
  print("Calculate person-time in each episode")
  
  tmp <- df[,c("episode","tstart","tstop")]
  tmp$person_time_total <- (tmp$tstop - tmp$tstart)
  tmp[,c("tstart","tstop")] <- NULL
  
  tmp <- aggregate(person_time_total ~ episode, data = tmp, FUN = sum)
  
  episode_info <- merge(episode_info, tmp, by = "episode", all.x = TRUE)
  
  ## Append to table 2 ---------------------------------------------------------
  print('Append to table 2')
  
  table2[nrow(table2)+1,] <- c(name = active_analyses$name[i],
                               cohort = active_analyses$cohort[i],
                               exposure = active_analyses$exposure[i],
                               outcome = active_analyses$outcome[i],
                               analysis = active_analyses$analysis[i],
                               unexposed_person_days = episode_info[episode_info$episode==0,]$person_time_total,
                               unexposed_events = episode_info[episode_info$episode==0,]$N_events,
                               exposed_person_days = episode_info[episode_info$episode==1,]$person_time_total,
                               exposed_events = episode_info[episode_info$episode==1,]$N_events)

}

# Add other information --------------------------------------------------------
print('Add other information')

table2$unexposed_person_days <- as.numeric(table2$unexposed_person_days)
table2$unexposed_events <- as.numeric(table2$unexposed_events)
table2$exposed_person_days <- as.numeric(table2$exposed_person_days)
table2$exposed_events <- as.numeric(table2$exposed_events)

table2$total_person_days <- table2$exposed_person_days + table2$unexposed_person_days
table2$total_events <- table2$exposed_events +table2$unexposed_events
table2$day0_events <- length(unique(df[df$exp_date==df$out_date & !is.na(df$exp_date) & !is.na(df$out_date),]$patient_id))
table2$total_exposed <- length(unique(df[df$exposure_status==1,]$patient_id))
table2$sample_size <- length(unique(df$patient_id))

# Save Table 2 -----------------------------------------------------------------
print('Save Table 2')

write.csv(table2, paste0("output/table2_",cohort,".csv"), row.names = FALSE)

# Perform redaction ------------------------------------------------------------
print('Perform redaction')

table2[,setdiff(colnames(table2),c("name","cohort","exposure","outcome","analysis"))] <- lapply(table2[,setdiff(colnames(table2),c("name","cohort","exposure","outcome","analysis"))],
                                            FUN=function(y){roundmid_any(as.numeric(y), to=threshold)})

# Save Table 2 -----------------------------------------------------------------
print('Save rounded Table 2')

write.csv(table2, paste0("output/table2_",cohort,"_rounded.csv"), row.names = FALSE)