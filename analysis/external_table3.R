# Load libraries ---------------------------------------------------------------
print('Load libraries')

library(magrittr)

# Specify paths ----------------------------------------------------------------
print('Specify paths')

source("analysis/specify_paths.R")

# Source utility functions -----------------------------------------------------
print('Source utility functions')

source("analysis/utility.R")

# Load data --------------------------------------------------------------------
print("Load data")

df <- readr::read_csv(paste0(release,"model_output.csv"))

# Filter data ------------------------------------------------------------------
print("Filter data")

df <- df[grepl("day",df$term) & 
           df$model=="mdl_max_adj",
         c("analysis","cohort","outcome","term","hr","conf_low","conf_high")]

df <- df[df$term!="days_pre",]

# Make columns numeric ---------------------------------------------------------
print("Make columns numeric")

df <- df %>% 
  dplyr::mutate_at(c("hr","conf_low","conf_high"), as.numeric)

# Add plot labels ---------------------------------------------------------
print("Add plot labels")

plot_labels <- readr::read_csv("lib/plot_labels.csv")

df <- merge(df, plot_labels, by.x = "outcome", by.y = "term", all.x = TRUE)
df <- dplyr::rename(df, "outcome_label" = "label")

df <- merge(df, plot_labels, by.x = "analysis", by.y = "term", all.x = TRUE)
df <- dplyr::rename(df, "analysis_label" = "label")
df$analysis_label <- ifelse(df$analysis_label=="All COVID-19","Primary",df$analysis_label)

# Tidy estimate ----------------------------------------------------------------
print("Tidy estimate")

df$estimate <- paste0(display(df$hr)," (",display(df$conf_low),"-",display(df$conf_high),")")

# Tidy term --------------------------------------------------------------------
print("Tidy term")

df$weeks <- ""
df$weeks <- ifelse(df$term=="days0_28", "1-4", df$weeks)
df$weeks <- ifelse(df$term=="days28_197", "5-28", df$weeks)
df$weeks <- ifelse(df$term=="days197_365", "29-52", df$weeks)
df$weeks <- ifelse(df$term=="days365_714", "53-102", df$weeks)

df$weeks <- factor(df$weeks, levels = c("1-4","5-28","29-52","53-102"))

# Pivot table ------------------------------------------------------------------
print("Pivot table")

df <- df[,c("analysis_label","cohort","outcome_label","weeks","estimate")]

df <- tidyr::pivot_wider(df, 
                         names_from = "cohort",
                         values_from = "estimate")

# Order analyses ---------------------------------------------------------------
print("Order analyses")

df$analysis_label <- factor(df$analysis_label,
                            levels = c("Primary",
                                       "Hospitalised COVID-19",
                                       "Non-hospitalised COVID-19",
                                       "No prior history of event",
                                       "Prior history of event, more than six moths ago",
                                       "Prior history of event, within six moths",
                                       "History of COVID-19",
                                       "Age group: 18-39",
                                       "Age group: 40-59",
                                       "Age group: 60-79",
                                       "Age group: 80-110",
                                       "Sex: Female",                                   
                                       "Sex: Male",
                                       "Ethnicity: White",
                                       "Ethnicity: South Asian",
                                       "Ethnicity: Black",
                                       "Ethnicity: Other",                       
                                       "Ethnicity: Mixed"))

# Tidy table -------------------------------------------------------------------
print("Tidy table")

df <- df[order(df$analysis_label,df$outcome_label,df$weeks),
         c("analysis_label","outcome_label","weeks","prevax_extf","vax","unvax_extf")]

df <- dplyr::rename(df,
                    "Analysis" = "analysis_label",
                    "Outcome" = "outcome_label",
                    "Weeks since COVID-19" = "weeks",
                    "Pre-vaccination cohort" = "prevax_extf",
                    "Vaccinated cohort" = "vax",
                    "Unvaccinated cohort" = "unvax_extf")

# Save table -------------------------------------------------------------------
print("Save table")

readr::write_csv(df, "output/table3.csv", na = "-")