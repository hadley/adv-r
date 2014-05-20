library(bookdown)
library(rmarkdown)
library(tools)

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
pandoc_convert(wd = "book",
  "advanced-r.md", output = "tex/advanced-r.tex",
  options = c(
    "--template", system.file("book-template.tex", package = "bookdown")
  )
)
file.copy("diagrams/", "book/tex/", recursive = TRUE)
file.copy("screenshots/", "book/tex/", recursive = TRUE)

pandoc_convert(wd = "book/tex", "advanced-r.tex", output = "advanced-r.pdf",
  options = c("--latex-engine=xelatex"))

# Build entire latex file
old <- setwd("book/tex")
texi2pdf("advanced-r.tex", quiet = FALSE, clean = FALSE)
# setwd(old)
