library(bookdown)
library(rmarkdown)

# Render chapters into tex  ----------------------------------------------------
needs_update <- function(src, dest) {
  if (!file.exists(dest)) return(TRUE)
  mtime <- file.info(src, dest)$mtime
  mtime[2] < mtime[1]
}

render_chapter <- function(src) {
  dest <- file.path("book/tex/", gsub("\\.rmd", "\\.tex", src))
  if (!needs_update(src, dest)) return()

  message("Rendering ", src)
  env <- new.env(parent = globalenv())

  render(src, tex_chapter(), output_dir = "book/tex", quiet = TRUE)
}

chapters <- dir(".", pattern = "\\.rmd$")
lapply(chapters, render_chapter)


# Copy across additional files -------------------------------------------------
file.copy("book/advanced-r.tex", "book/tex/", recursive = TRUE)
file.copy("book/krantz.cls", "book/tex/", recursive = TRUE)
file.copy("diagrams/", "book/tex/", recursive = TRUE)
file.copy("screenshots/", "book/tex/", recursive = TRUE)
file.copy("figures", "book/tex/", recursive = TRUE)

# Build tex file ---------------------------------------------------------------
# (build with Rstudio to find/diagnose errors)
old <- setwd("book/tex")
system("xelatex advanced-r -interaction=batchmode")
system("xelatex advanced-r -interaction=batchmode")
setwd(old)

file.copy("book/tex/advanced-r.pdf", "book/advanced-r.pdf")
