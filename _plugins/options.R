set_knitr_options <- function() {
  set.seed(1410)
  options(digits = 3)
  knitr::opts_chunk$set(
    comment = "#>",
    collapse = TRUE,
    error = FALSE,
    cache.path = "_cache/",
    fig.width = 4,
    fig.height = 4
  )
}

knit_print.knit_asis <- function(x, ...) x

begin_sidebar <- function(x, options) {
  if (identical(doc_type(), "latex")) {
    knitr::asis_output("\\begin{sidebar}")
  } else {
    knitr::asis_output("<div class = 'well'>\n")
  }
}

end_sidebar <- function(x, options) {
  if (identical(doc_type(), "latex")) {
    knitr::asis_output("\\end{sidebar}")
  } else {
    knitr::asis_output("</div>\n")
  }
}

doc_type <- function() knitr::opts_knit$get('rmarkdown.pandoc.to')

