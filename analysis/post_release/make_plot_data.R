# Load data --------------------------------------------------------------------
print('Load data')

df <- readr::read_csv(path_model_output,
                      show_col_types = FALSE)

# Merge counts -----------------------------------------------------------------
print('Merge counts')

tmp <- readr::read_csv(path_counts_term,
                       show_col_types = FALSE)

df <- merge(df, tmp, by = c("name","term"))

# Seperate name ----------------------------------------------------------------
print('Seperate name')

df <- tidyr::separate(data = df, 
                      col = "name",
                      into = c("cohort","analysis","outcome"),
                      sep = "-",
                      remove = FALSE)

df$cohort <- gsub("cohort_","",df$cohort)

# Restrict to plot data --------------------------------------------------------
print('Restrict to plot data')

df <- df[grepl("day",df$term),
         c("name", "cohort","analysis","outcome","model",
           "outcome_time_median","term","hr","conf_low","conf_high")]

# Remove unsuccessful models ---------------------------------------------------
print('Remove unsuccessful models')

tmp <- unique(df[df$conf_high==Inf & grepl("day",df$term),]$name)
df <- df[!(df$name %in% tmp),]

# Save plot data ---------------------------------------------------------------
print('Save plot data')

df <- df[!grepl("detailed",df$analysis),]
readr::write_csv(df, "output/plot_model_output.csv")