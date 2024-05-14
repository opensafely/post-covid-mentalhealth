# Load data --------------------------------------------------------------------
print("Load data")

library("extrafont")
extrafont::loadfonts()

# Load data --------------------------------------------------------------------
print("Load data")

df <- readr::read_csv(path_cohortoverlap,
                      show_col_types = FALSE)

# Create Venn ------------------------------------------------------------------
print("Create Venn")

# svglite::svglite("output/post_release/figure_CohortOverlap.svg", width = 8, height = 8)
tiff("output/post_release/figure_CohortOverlap.tiff", width = 8, height = 8, units = "in", res = 800)

venn.plot <- VennDiagram::draw.triple.venn(
  area1 = sum(df[df$cohort %in% c("prevax_only","prevax_vax","prevax_unvax","prevax_vax_unvax"),]$N_midpoint6), 
  area2 = sum(df[df$cohort %in% c("vax_only","prevax_vax","vax_unvax","prevax_vax_unvax"),]$N_midpoint6), 
  area3 = sum(df[df$cohort %in% c("unvax_only","prevax_unvax","vax_unvax","prevax_vax_unvax"),]$N_midpoint6),
  n12 = sum(df[df$cohort %in% c("prevax_vax","prevax_vax_unvax"),]$N_midpoint6),
  n23 = sum(df[df$cohort %in% c("vax_unvax","prevax_vax_unvax"),]$N_midpoint6),
  n13 = sum(df[df$cohort %in% c("prevax_unvax","prevax_vax_unvax"),]$N_midpoint6),
  n123 = df[df$cohort=="prevax_vax_unvax",]$N_midpoint6,
  category = c("Pre-vaccine\navailability\ncohort","Vaccinated\ncohort","Unvaccinated cohort"),
  col = "white",
  fill = c("#f1e6c8", "#cbdac5", "#98a7ff"),
  print.mode = c("raw"),
  sigdigs = 2,
  cat.fontfamily = "Arial",
  fontfamily="Arial"
)

grid::grid.draw(venn.plot)
dev.off()

# SVG converted to EPS using https://cloudconvert.com/svg-to-eps