library(oldbookdown)
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
  render_old <- function(src) {
    library(oldbookdown)
    # from https://github.com/hadley/ggplot2-book/pull/142/commits/29f39e32b1dfe52f3c7b3342213f3ca2b2edc57a
    tex_chapter <- function(chapter = NULL, latex_engine = c("xelatex", "pdflatex",
                                                              "lualatex"), code_width = 65) {
      options(digits = 3)
      set.seed(1014)
      latex_engine <- match.arg(latex_engine)
      rmarkdown::output_format(rmarkdown::knitr_options("html", chapter),
                               rmarkdown::pandoc_options(to = "latex", from = "markdown",
                                                         ext = ".tex",
                                                         args = c("--top-level-division=chapter",
                                                                  rmarkdown::pandoc_latex_engine_args(latex_engine))),
                               clean_supporting = FALSE)
    }
    rmarkdown::render(src, tex_chapter(),
                      output_dir = "book/tex", quiet = TRUE, envir = globalenv())
  }

  callr::r(render_old, args = list(src = src))

#   command <- bquote(rmarkdown::render(.(src), tex_chapter(),
#     output_dir = "book/tex", quiet = TRUE, envir = globalenv()))
#   writeLines(deparse(command), "run.r")
#   on.exit(unlink("run.r"))
#   source_clean("run.r")
}

source_clean <- function(path) {
browser()
  r_path <- file.path(R.home("bin"), "R")
  cmd <- paste0(shQuote(r_path), " --quiet --file=", shQuote(path))

  out <- system(cmd, intern = TRUE)
  status <- attr(out, "status")
  if (is.null(status)) status <- 0
  if (!identical(as.character(status), "0")) {
    stop("Command failed (", status, ")", call. = FALSE)
  }
}

chapters <- dir(".", pattern = "\\.rmd$")
lapply(chapters, render_chapter)

# Apply regular expressions to files -------------------------------------------
apply_regexp <- function(file, regexps) {
  lines <- readLines(file)
  for (i in seq_along(regexps)) {
    lines <- gsub(escape(names(regexps)[i]), escape(regexps[[i]]), lines)
  }

  writeLines(lines, file)
}
apply_regexps <- function(regexps) {
  files <- dir("book/tex/", "\\.tex$", full.names = TRUE)
  lapply(files, apply_regexp, regexps = regexps)
}
escape <- function(x) {
  x <- gsub("\\\\", "\\\\\\\\", x)
  gsub("([{}])", "\\\\\\1", x)
}
apply_regexps(c(
  "\\begin{SIDEBAR}" =    "\\begin{shortbox}\\Boxhead{",
  "\\end{SIDEBAR}"   = "}",
  "\\begin{ENDSIDEBAR}\\end{ENDSIDEBAR}" = "\\end{shortbox}"
))

# Copy across additional files -------------------------------------------------
file.copy("book/advanced-r.tex", "book/tex/", recursive = TRUE)
file.copy("book/krantz.cls", "book/tex/", recursive = TRUE)
file.copy(dir("book", "^K", full.names = TRUE), "book/tex/", recursive = TRUE)
file.copy("diagrams/", "book/tex/", recursive = TRUE)
file.copy("screenshots/", "book/tex/", recursive = TRUE)
# file.copy("figures", "book/tex/", recursive = TRUE)

# Build tex file ---------------------------------------------------------------
# (build with Rstudio to find/diagnose errors)
old <- setwd("book/tex")
unlink("advanced-r.ind") # delete old index
system("xelatex -interaction=batchmode advanced-r ")
system("makeindex advanced-r")
system("xelatex -interaction=batchmode advanced-r ")
system("xelatex -interaction=batchmode advanced-r ")
setwd(old)

file.copy("book/tex/advanced-r.pdf", "book/advanced-r.pdf", overwrite = TRUE)
embedFonts("book/tex/advanced-r.pdf")
