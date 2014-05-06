source("_plugins/rmd2html.r")

chapters <- dir(".", pattern = "\\.rmd$")

knitr::opts_knit$set('rmarkdown.pandoc.to' = "latex")
for (chapter in chapters) {
  message("Processing ", chapter)
  out_path <- paste0("book/chapters/", gsub(".rmd", ".md", chapter))
  out <- rmd2md(chapter, out_path, out = "mdtex")
}
knitr::opts_knit$set('rmarkdown.pandoc.to' = NULL)

system("book/build.sh")
