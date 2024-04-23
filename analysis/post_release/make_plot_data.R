# Load model output ------------------------------------------------------------
print('Load model output')

df <- readr::read_csv(path_model_output,
                      show_col_types = FALSE)


df <- df[!grepl("stata_",df$name),]

readr::write_csv(df, "output/plot_model_output.csv")