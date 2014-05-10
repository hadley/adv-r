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
