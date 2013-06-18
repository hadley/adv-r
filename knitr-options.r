library(knitr)
set.seed(1410)
options(digits = 3)
knit_hooks$set(document = function(x) {
  gsub('```r?\n+```r?\n', '', x)
})
opts_chunk$set(
  comment = "#", error = TRUE, tidy = FALSE,
  fig.width = 4, fig.height = 4)
opts_knit$set(stop_on_error = 2L)
