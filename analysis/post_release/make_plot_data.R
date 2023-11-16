# Load model output ------------------------------------------------------------
print('Load model output')

df <- readr::read_csv(path_model_output,
                      show_col_types = FALSE)

df$source <- "R"

# Restrict to plot data --------------------------------------------------------
print('Restrict to plot data')

df <- df[grepl("day",df$term),
         c("name", "cohort","analysis","outcome","model",
           "outcome_time_median","term","hr","conf_low","conf_high","source")]

# Load stata model output ------------------------------------------------------
print('Load stata model output')

tmp <- readr::read_csv(path_stata_model_output,
                       show_col_types = FALSE)

tmp$source <- "Stata"

df$rank <- 0
tmp$rank <- 1

tmp <- tmp[,colnames(df)]
df <- rbind(df,tmp)

df <- df %>%
  dplyr::group_by(name) %>%
  dplyr::top_n(1, rank) %>%
  dplyr::ungroup()

df$rank <- NULL

# Save plot data ---------------------------------------------------------------
print('Save plot data')

df <- df[!grepl("detailed",df$analysis),]
readr::write_csv(df, "output/plot_model_output.csv")