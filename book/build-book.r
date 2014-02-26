source("_plugins/rmd2html.r")

chapters <- dir(".", pattern = "\\.rmd$")

for (chapter in chapters) {
  message("Processing ", chapter)
  out_path <- paste0("book/chapters/", gsub(".rmd", ".md", chapter))
  out <- rmd2md(chapter, out_path, out = "mdtex")
}

system("book/build.sh")
