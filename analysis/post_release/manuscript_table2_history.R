# Load data --------------------------------------------------------------------
print("Load data")

df <- readr::read_csv(path_table2_history,
                      show_col_types = FALSE)

colnames(df) <- gsub("_midpoint6","",colnames(df))

# Filter data ------------------------------------------------------------------
print("Filter data")

df$events <- df$exposed_events
df$person_days <- df$exposed_person_days

df <- df[,c("cohort","analysis","outcome","events","person_days")]

# Add plot labels --------------------------------------------------------------
print("Add plot labels")

plot_labels <- readr::read_csv("lib/plot_labels.csv",
                               show_col_types = FALSE)

df$outcome <- gsub("out_date_","",df$outcome)
df <- merge(df, plot_labels[,c("term","label")], by.x = "outcome", by.y = "term", all.x = TRUE)
df <- dplyr::rename(df, "outcome_label" = "label")

df <- merge(df, plot_labels[,c("term","label")], by.x = "analysis", by.y = "term", all.x = TRUE)
df <- dplyr::rename(df, "history" = "label")
df$history <- factor(df$history, levels = c("No prior history of event","Prior history of event, within six months","Prior history of event, more than six months ago"))

# Add other columns ------------------------------------------------------------
print("Add other columns")

df$event_personyears <- paste0(df$events,"/", round((df$person_days/365.25)))
df$incidencerate <- round(df$events/((df$person_days/365.25)/100000))

# Pivot table ------------------------------------------------------------------
print("Pivot table")

df <- df[,c("cohort","outcome_label","history","event_personyears","incidencerate")]

df <- tidyr::pivot_wider(df, 
                         names_from = "cohort",
                         values_from = c("event_personyears","incidencerate"))

# Order outcomes ---------------------------------------------------------------
print("Order outcomes")

df$outcome_label <- factor(df$outcome_label,
                           levels = c("N",
                                      "Depression",
                                      "Serious mental illness"))

# Tidy table -------------------------------------------------------------------
print("Tidy table")

df <- df[order(df$outcome_label,df$history),
         c("outcome_label","history",
           paste0(c("event_personyears","incidencerate"),"_prevax_extf"),
           paste0(c("event_personyears","incidencerate"),"_vax"),
           paste0(c("event_personyears","incidencerate"),"_unvax_extf"))]

df <- dplyr::rename(df,
                    "Outcome" = "outcome_label",
                    "Prior history of event" = "history")

# Save table -------------------------------------------------------------------
print("Save table")

readr::write_csv(df, "output/post_release/table2_history.csv", na = "-")