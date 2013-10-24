library(devtools)
source("_plugins/rmd2html.r")

chapters <- dir(".", pattern = "\\.rmd$")

for (chapter in chapters) {
  out <- cache_file(chapter, rmd2md, ".md")
  file.copy(out, paste0("book/chapters/", gsub(".rmd", ".md", chapter)))
}

system("book/build.sh")
