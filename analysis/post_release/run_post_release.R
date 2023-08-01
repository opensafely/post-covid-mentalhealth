tables <- list.files(path = "analysis/post_release/", pattern = "table")
figures <- list.files(path = "analysis/post_release/", pattern = "figure")

for (i in c(tables, figures)) {
  message(paste0("Making: ",gsub(".R","",i)))
  source(paste0("analysis/post_release/",i))
}