# Load data --------------------------------------------------------------------
print("Load data")

df <- readr::read_csv(path_model_output,
                      show_col_types = FALSE)

# Filter data ------------------------------------------------------------------
print("Filter data")

df <- df[df$outcome %in% c("depression","serious_mental_illness") &
           grepl("day",df$term) & 
           df$model=="mdl_max_adj",
         c("cohort","analysis","outcome","outcome_time_median","term","hr","conf_low","conf_high")]

df <- df[df$term!="days_pre",]

# Make columns numeric ---------------------------------------------------------
print("Make columns numeric")

df <- df %>% 
  dplyr::mutate_at(c("outcome_time_median","hr","conf_low","conf_high"), as.numeric)


# Add plot labels ---------------------------------------------------------
print("Add plot labels")

plot_labels <- readr::read_csv("lib/plot_labels.csv",
                               show_col_types = FALSE)

df <- merge(df, plot_labels[,c("term","label")], by.x = "outcome", by.y = "term", all.x = TRUE)
df <- dplyr::rename(df, "outcome_label" = "label")

df <- merge(df, plot_labels, by.x = "analysis", by.y = "term", all.x = TRUE)
df <- dplyr::rename(df, "analysis_label" = "label")

# Add facet labels -------------------------------------------------------------
print("Add facet labels")

df$facet_label <- ifelse(df$ref==TRUE & !is.na(df$ref), 
                         paste0(df$outcome_label,"\n\n",df$analysis_label),
                         df$analysis_label)

# Iterate over plots -----------------------------------------------------------
print("Iterate over plots")

for (i in unique(df$analysis_group)){
  
  message(paste0(i))
  
  # Restrict to plot data ------------------------------------------------------
  print("Restrict to plot data")
  
  df_plot <- df[df$analysis_group==i,]

  # Update labels --------------------------------------------------------------
  
  if (i=="sub_covid_history") {
    print("Update labels")
    df_plot$analysis_label <- ifelse(df_plot$analysis_label=="All COVID-19",
                                     "No history of COVID-19",df_plot$analysis_label)
    df_plot <- df_plot[df_plot$cohort!="prevax_extf",]
  }
  
  # Calculate number of facet cols ---------------------------------------------
  print("Calculate number of facet col")
  
  facet_cols <- length(unique(df_plot$analysis))
  
  # Remove extreme estimates from plot -----------------------------------------
  print("Remove extreme estimates from plot")
  
  df_plot$hr <- ifelse(df_plot$hr>64 | df_plot$hr < 0.5, NA, df_plot$hr)
  df_plot$conf_low <- ifelse(is.na(df_plot$hr), NA, df_plot$conf_low)
  df_plot$conf_high <- ifelse(is.na(df_plot$hr), NA, df_plot$conf_high)

  #df_plot <- df_plot[order(df_plot$outcome_label, df_plot$analysis_label, df_plot$term),]  

  # Plot data ------------------------------------------------------------------
  print("Plot data")
  
  p <- ggplot2::ggplot(data = df_plot,
                  mapping = ggplot2::aes(x = outcome_time_median, y = hr, color = cohort)) +
    ggplot2::geom_hline(mapping = ggplot2::aes(yintercept = 1), colour = "#A9A9A9") +
    ggplot2::geom_point(position = ggplot2::position_dodge(width = 0)) +
    ggplot2::geom_errorbar(mapping = ggplot2::aes(ymin = conf_low, 
                                                  ymax = conf_high,  
                                                  width = 0), 
                           position = ggplot2::position_dodge(width = 0)) +
    ggplot2::geom_line(position = ggplot2::position_dodge(width = 0)) +
    ggplot2::scale_y_continuous(lim = c(0.5,64), breaks = c(0.5,1,2,4,8,16,32,64), trans = "log") +
    ggplot2::scale_x_continuous(lim = c(0,511), breaks = seq(0,511,56), labels = seq(0,511,56)/7) +
    ggplot2::scale_color_manual(breaks = c("prevax_extf", "vax", "unvax_extf"),
                                labels = c("Pre-vaccination (Jan 1 2020 - Dec 14 2021)",
                                           "Vaccinated (Jun 1 2021 - Dec 14 2021)",
                                           "Unvaccinated (Jun 1 2021 - Dec 14 2021)"),
                                values = c("#d2ac47", "#58764c", "#0018a8")) +
    ggplot2::labs(x = "\nWeeks since COVID-19 diagnosis", y = "Hazard ratio and 95% confidence interval\n") +
    ggplot2::theme_minimal() +
    ggplot2::theme(panel.grid.major.x = ggplot2::element_blank(),
                   panel.grid.minor = ggplot2::element_blank(),
                   panel.spacing.x = ggplot2::unit(0.5, "lines"),
                   panel.spacing.y = ggplot2::unit(0, "lines"),
                   legend.key = ggplot2::element_rect(colour = NA, fill = NA),
                   legend.title = ggplot2::element_blank(),
                   legend.position="bottom",
                   plot.background = ggplot2::element_rect(fill = "white", colour = "white"))
  
  if (facet_cols==1) {
    #p + ggplot2::facet_wrap(outcome_label~., ncol = facet_cols) +
    p + ggplot2::facet_grid(outcome_label~.) + 
      ggplot2::guides(color=ggplot2::guide_legend(ncol = 1, byrow = TRUE)) 
    plot_width = ifelse(grepl("detailed",i),297*0.7,297*0.5)
  } else if (i %in% c("sub_covid_history","sub_sex")) {
    #p + ggplot2::facet_wrap(outcome_label~forcats::fct_rev(analysis_label), ncol = facet_cols) + 
    p + ggplot2::facet_grid(outcome_label~forcats::fct_rev(analysis_label)) + 
      ggplot2::guides(color=ggplot2::guide_legend(ncol = 1, byrow = TRUE))
    plot_width = 297*0.7
  } else {
    #p + ggplot2::facet_wrap(outcome_label~analysis_label, ncol = facet_cols) +
    p + ggplot2::facet_grid(outcome_label~analysis_label, switch = "y") +
      ggplot2::guides(color=ggplot2::guide_legend(nrow = 1, byrow = TRUE))
    plot_width = 297
  }
  
  # Save plot ------------------------------------------------------------------
  print("Save plot")
  
  ggplot2::ggsave(paste0("output/post_release/figure_",i,".png"), 
                  height = 210, width = plot_width, 
                  unit = "mm", dpi = 600, scale = 0.8)
}