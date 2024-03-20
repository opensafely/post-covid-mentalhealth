# Load data --------------------------------------------------------------------
print("Load data")

df <- readr::read_csv("output/plot_model_output.csv",
                      show_col_types = FALSE)

df <- df[!is.na(df$hr),]

# Filter data ------------------------------------------------------------------
print("Filter data")

df <- df[df$analysis=="day0_main" & grepl("days",df$term),
         c("cohort","outcome","outcome_time_median","model","term","hr","conf_low","conf_high")]

df <- df[!(df$term %in% c("days_pre","days0_1")),]

# Make columns numeric ---------------------------------------------------------
print("Make columns numeric")

df <- df %>% 
  dplyr::mutate_at(c("outcome_time_median","hr","conf_low","conf_high"), as.numeric)

# Add plot labels --------------------------------------------------------------
print("Add plot labels")

plot_labels <- readr::read_csv("lib/plot_labels.csv", show_col_types = FALSE)

df <- merge(df, plot_labels, by.x = "outcome", by.y = "term", all.x = TRUE)
df <- dplyr::rename(df, "outcome_label" = "label")

# Order outcomes ---------------------------------------------------------------
print("Order outcomes")

df$outcome_label <- factor(df$outcome_label,
                           levels = c("Depression",
                                      "Serious mental illness",
                                      "General anxiety",
                                      "Post-traumatic stress disorder",
                                      "Eating disorders",
                                      "Addiction",
                                      "Self-harm",
                                      "Suicide"))

# Plot data --------------------------------------------------------------------
print("Plot data")

ggplot2::ggplot(data = df,
                mapping = ggplot2::aes(x = outcome_time_median, y = hr, color = cohort)) +
  ggplot2::geom_hline(mapping = ggplot2::aes(yintercept = 1), colour = "#A9A9A9") +
  ggplot2::geom_point(position = ggplot2::position_dodge(width = 0)) +
  ggplot2::geom_errorbar(mapping = ggplot2::aes(ymin = conf_low, 
                                                ymax = conf_high,  
                                                width = 0), 
                         position = ggplot2::position_dodge(width = 0)) +
  ggplot2::geom_line(position = ggplot2::position_dodge(width = 0), ggplot2::aes(linetype=model)) +
  ggplot2::scale_y_continuous(lim = c(0.25,20), breaks = c(0.25,0.5,1,2,4,8,16,32), trans = "log") +
  ggplot2::scale_x_continuous(lim = c(0,511), breaks = seq(0,511,56), labels = seq(0,511,56)/7) +
  ggplot2::scale_linetype_manual(values=c("solid", "dashed"), 
                                 breaks = c("mdl_max_adj", "mdl_age_sex"),
                                labels = c("Maximally adjusted","Age- and sex- adjusted")) +
  ggplot2::scale_color_manual(breaks = c("prevax_extf", "vax", "unvax_extf"),
                              labels = c("Pre-vaccine availability (Jan 1 2020 - Dec 14 2021)",
                                        "Vaccinated (Jun 1 2021 - Dec 14 2021)",
                                        "Unvaccinated (Jun 1 2021 - Dec 14 2021)"),
                              values = c("#d2ac47", "#58764c", "#0018a8")) +
  ggplot2::labs(x = "\nWeeks since COVID-19 diagnosis", y = "Hazard ratio and 95% confidence interval\n") +
  ggplot2::guides(color=ggplot2::guide_legend(ncol = 1, byrow = TRUE),
                  linetype=ggplot2::guide_legend(ncol = 1, byrow = TRUE)) +
  ggplot2::theme_minimal() +
  ggplot2::theme(panel.grid.major.x = ggplot2::element_blank(),
                 panel.grid.minor = ggplot2::element_blank(),
                 panel.spacing.x = ggplot2::unit(0.5, "lines"),
                 panel.spacing.y = ggplot2::unit(0, "lines"),
                 strip.text = ggplot2::element_text(hjust = 0, vjust = 0),
                 legend.key = ggplot2::element_rect(colour = NA, fill = NA),
                 legend.title = ggplot2::element_blank(),
                 legend.position="bottom",
                 plot.background = ggplot2::element_rect(fill = "white", colour = "white")) +
  ggplot2::facet_wrap(outcome_label~., ncol = 2)

# Save plot --------------------------------------------------------------------
print("Save plot")

ggplot2::ggsave("output/post_release/figureAdj.png", 
                height = 297, width = 210, 
                unit = "mm", dpi = 600, scale = 0.8)


# Plot data --------------------------------------------------------------------
print("Plot data")

ggplot2::ggplot(data = df[df$model=="mdl_max_adj" & !(df$outcome %in% c("depression", "serious_mental_illness")),],
                mapping = ggplot2::aes(x = outcome_time_median, y = hr, color = cohort)) +
  ggplot2::geom_hline(mapping = ggplot2::aes(yintercept = 1), colour = "#A9A9A9") +
  ggplot2::geom_point(position = ggplot2::position_dodge(width = 0)) +
  ggplot2::geom_errorbar(mapping = ggplot2::aes(ymin = conf_low, 
                                                ymax = conf_high,  
                                                width = 0), 
                         position = ggplot2::position_dodge(width = 0)) +
  ggplot2::geom_line(position = ggplot2::position_dodge(width = 0)) +
  ggplot2::scale_y_continuous(lim = c(0.25,20), breaks = c(0.25,0.5,1,2,4,8,16,32), trans = "log") +
  ggplot2::scale_x_continuous(lim = c(0,511), breaks = seq(0,511,56), labels = seq(0,511,56)/7) +
  ggplot2::scale_color_manual(breaks = c("prevax_extf", "vax", "unvax_extf"),
                              labels = c("Pre-vaccine availability (Jan 1 2020 - Dec 14 2021)",
                                         "Vaccinated (Jun 1 2021 - Dec 14 2021)",
                                         "Unvaccinated (Jun 1 2021 - Dec 14 2021)"),
                              values = c("#d2ac47", "#58764c", "#0018a8")) +
  ggplot2::labs(x = "\nWeeks since COVID-19 diagnosis", y = "Hazard ratio and 95% confidence interval\n") +
  ggplot2::guides(color=ggplot2::guide_legend(ncol = 1, byrow = TRUE)) +
  ggplot2::theme_minimal() +
  ggplot2::theme(panel.grid.major.x = ggplot2::element_blank(),
                 panel.grid.minor = ggplot2::element_blank(),
                 panel.spacing.x = ggplot2::unit(0.5, "lines"),
                 panel.spacing.y = ggplot2::unit(0, "lines"),
                 strip.text = ggplot2::element_text(hjust = 0, vjust = 0),
                 legend.key = ggplot2::element_rect(colour = NA, fill = NA),
                 legend.title = ggplot2::element_blank(),
                 legend.position="bottom",
                 plot.background = ggplot2::element_rect(fill = "white", colour = "white")) +
  ggplot2::facet_wrap(outcome_label~., ncol = 2)

# Save plot --------------------------------------------------------------------
print("Save plot")

ggplot2::ggsave("output/post_release/figureOther.png", 
                height = 297*0.82, width = 210, 
                unit = "mm", dpi = 600, scale = 0.8)