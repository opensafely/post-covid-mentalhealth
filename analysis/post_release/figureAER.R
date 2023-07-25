# Load data --------------------------------------------------------------------
print('Load data')

df <- read.csv("output/post_release/lifetables_compiled.csv")

# Format aer_age ---------------------------------------------------------------
print("Format aer_age")

df$aer_age <- factor(df$aer_age,
                     levels = c("18_39",
                                "40_59",
                                "60_79",
                                "80_110",
                                "overall"),
                     labels = c("Age group: 18-39",
                                "Age group: 40-59",
                                "Age group: 60-79",
                                "Age group: 80-110",
                                "Combined"))

# Format aer_sex ---------------------------------------------------------------
print("Format aer_sex")

df$aer_sex <- factor(df$aer_sex,
                     levels = c("Female",
                                "Male",
                                "overall"),
                     labels = c("Sex: Female",
                                "Sex: Male",
                                "Combined"))

# Format cohort ----------------------------------------------------------------
print("Format cohort")

df$cohort <- ifelse(df$cohort == "prevax", "Pre-vaccination (1 Jan 2020 - 14 Dec 2021)", df$cohort)
df$cohort <- ifelse(df$cohort == "vax", "Vaccinated (1 Jun 2021 - 14 Dec 2021)", df$cohort)
df$cohort <- ifelse(df$cohort == "unvax", "Unvaccinated (1 Jun 2021 - 14 Dec 2021)", df$cohort)

# Plot and save each outcome ---------------------------------------------------
print("Plot and save each outcome")

for (outcome in unique(df$outcome)) {
  
  # Plot -----------------------------------------------------------------------
  print(paste0("Plot outcome: ",outcome))
  
  ggplot2::ggplot(data = df[df$days<197 & df$outcome==outcome,], 
                  mapping = ggplot2::aes(x = days/7, 
                                         y = cumulative_difference_absolute_excess_risk*100, 
                                         color = aer_age, linetype = aer_sex)) +
    ggplot2::geom_line() +
    #ggplot2::scale_y_continuous(lim = c(0,0.5), breaks = c(0.1,0.2,0.3,0.4,0.5)) +
    ggplot2::scale_color_manual(values = c("#006d2c",
                                           "#31a354",
                                           "#74c476",
                                           "#bae4b3",
                                           "#000000"), 
                                labels = levels(df$aer_age)) +
    ggplot2::scale_linetype_manual(values = c("solid",
                                              "longdash",
                                              "solid"), 
                                   labels = levels(df$aer_sex))+
    ggplot2::labs(x = "Weeks since COVID-19 diagnosis", y = "Cumulative difference in absolute risk  (%)") +
    ggplot2::guides(fill=ggplot2::guide_legend(ncol = 6, byrow = TRUE)) +
    ggplot2::theme_minimal() +
    ggplot2::theme(panel.grid.major.x = ggplot2::element_blank(),
                   panel.grid.minor = ggplot2::element_blank(),
                   panel.spacing.x = ggplot2::unit(0.5, "lines"),
                   panel.spacing.y = ggplot2::unit(0, "lines"),
                   legend.key = ggplot2::element_rect(colour = NA, fill = NA),
                   legend.title = ggplot2::element_blank(),
                   legend.position="bottom",
                   plot.background = ggplot2::element_rect(fill = "white", colour = "white"),
                   plot.title = ggplot2::element_text(hjust = 0.5),
                   text = ggplot2::element_text(size=13)) +
    ggplot2::facet_grid(. ~ cohort, scales = "free_x")
  
  # Save figure ----------------------------------------------------------------
  print('Save figure')
  
  ggplot2::ggsave(paste0("output/post_release/figureAER_",outcome,".png"), 
                  height = 210, width = 297, unit = "mm", dpi = 600, scale = 1)
  
}
