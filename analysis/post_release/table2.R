# Load libraries ---------------------------------------------------------------
print('Load libraries')

library(magrittr)

# Specify paths ---------------------------------------------------------------
print('Specify paths')

source("analysis/post_release/specify_paths.R")

# Source utility functions -----------------------------------------------------
print('Source utility functions')

source("analysis/utility.R")

# Load data --------------------------------------------------------------------
print("Load data")

df <- readr::read_csv(paste0(release,"model_output.csv"))

# Filter data ------------------------------------------------------------------
print("Filter data")

df <- df[((df$analysis=="main" & df$term=="days_pre") | 
           (grepl("hospitalised",df$analysis) & grepl("days",df$term) & df$term!="days_pre")) &
           grepl("day",df$term) & 
           df$model=="mdl_max_adj",
         c("cohort","outcome","analysis","term","N_events")]

           
# Make columns numeric ---------------------------------------------------------
print("Make columns numeric")

df <- df %>% 
  dplyr::mutate_at(c("N_events"), as.numeric)

# Sum events -------------------------------------------------------------------
print("Sum events")

df <- df %>% 
  dplyr::group_by(cohort,outcome,analysis) %>% 
  dplyr::mutate(events = sum(N_events)) %>% 
  dplyr::ungroup() %>%
  dplyr::select(cohort,outcome,analysis,events) %>% 
  unique()

# Add plot labels --------------------------------------------------------------
print("Add plot labels")

plot_labels <- readr::read_csv("lib/plot_labels.csv")

df <- merge(df, plot_labels, by.x = "outcome", by.y = "term", all.x = TRUE)
df <- dplyr::rename(df, "outcome_label" = "label")

df <- merge(df, plot_labels, by.x = "analysis", by.y = "term", all.x = TRUE)
df <- dplyr::rename(df, "analysis_label" = "label")
df$analysis_label <- ifelse(df$analysis_label=="All COVID-19","No COVID-19",df$analysis_label)
df$analysis_label <- factor(df$analysis_label, levels = c("No COVID-19","Hospitalised COVID-19","Non-hospitalised COVID-19"))

# Add other columns ------------------------------------------------------------
print("Add other columns")

df$event_personyears <- paste0(df$events,"/XXX")
df$incidencerate <- "XXX"

# Pivot table ------------------------------------------------------------------
print("Pivot table")

df <- df[,c("cohort","outcome_label","analysis_label","event_personyears","incidencerate")]

df <- tidyr::pivot_wider(df, 
                         names_from = "cohort",
                         values_from = c("event_personyears","incidencerate"))

# Order outcomes ---------------------------------------------------------------
print("Order outcomes")

df$outcome_label <- factor(df$outcome_label,
                           levels = c("General anxiety",
                                      "Post-traumatic stress disorder",
                                      "Depression",
                                      "Eating disorders",
                                      "Serious mental illness",
                                      "Addiction",
                                      "Self harm",
                                      "Suicide"))

# Tidy table -------------------------------------------------------------------
print("Tidy table")

df <- df[order(df$outcome_label,df$analysis_label),
         c("outcome_label","analysis_label",
           paste0(c("event_personyears","incidencerate"),"_prevax_extf"),
           paste0(c("event_personyears","incidencerate"),"_vax"),
           paste0(c("event_personyears","incidencerate"),"_unvax_extf"))]

df <- dplyr::rename(df,
                    "Outcome" = "outcome_label",
                    "COVID-19 severity" = "analysis_label")

# Save table -------------------------------------------------------------------
print("Save table")

readr::write_csv(df, "output/post_release/table2.csv", na = "-")