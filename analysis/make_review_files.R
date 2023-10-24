# Make master file -------------------------------------------------------------
print('Make master file')

df <- readr::read_csv(path_model_output,
                      show_col_types = FALSE)

df$source <- "R"

tmp <- readr::read_csv(path_stata_model_output,
                       show_col_types = FALSE)

tmp$source <- "Stata"

df <- df[!(df$name %in% tmp$name),]

df <- rbind(df, tmp)

# Save failures ----------------------------------------------------------------
print('Save failures')

tmp1 <- df[!is.na(df$error),
               c("name","error","source")]

readr::write_csv(tmp1, "output/review-failures.csv")

df <- df[is.na(df$error),]

# Save counts at name level ----------------------------------------------------
print('Save counts at name level')

tmp2 <- unique(df[!is.na(df$N_total),
                    c("name","N_total","N_exposed")])

readr::write_csv(tmp2, "output/review-counts_name_rounded.csv")

# Save counts at term level ----------------------------------------------------
print('Save counts at term level')

tmp3 <- unique(df[!is.na(df$N_events),
                    c("name",
                      "term","N_events","person_time_total","outcome_time_median")])

readr::write_csv(tmp3, "output/review-counts_term_rounded.csv")

# Save model output ------------------------------------------------------------
print('Save model output')

tmp4 <- unique(df[df$term!="days_pre",
                    c("name","model","term",
                      "hr","conf_low","conf_high","surv_formula")])

readr::write_csv(tmp4, "output/review-model_output_rounded.csv")