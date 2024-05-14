# Load cohort covid information ------------------------------------------------
print('Load cohort covid information')

df <- data.table::fread(path_cohortcovid)

# Calculate infection rates ----------------------------------------------------
print('Calculate infection rates')

df$covid19_100000py <- round(100000*(df$covid19_midpoint6 / df$persondays))

# Make output ------------------------------------------------------------------
print('Make output')

df$characteristic <- "COVID-19 per 100000 person years"

df <- tidyr::pivot_wider(df[,c("characteristic","cohort","covid19_100000py")], 
                         names_from = "cohort", 
                         values_from = "covid19_100000py",
                         id_cols = "characteristic")

# Save table -------------------------------------------------------------------
print("Save table")

readr::write_csv(df, "output/post_release/table1_covid19100000py.csv", na = "-")