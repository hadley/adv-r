library(Rcpp)
library(microbenchmark)

sourceCpp("range.cpp")

x <- c(NA, runif(1e5))
microbenchmark(
  range(x, na.rm = TRUE),
  min(x, na.rm = TRUE),
  max(x, na.rm = TRUE),
  range2(x, TRUE),
  range3(x, TRUE),
  range3a(x, TRUE)
)
microbenchmark(
  range(x, na.rm = FALSE),
  min(x, na.rm = FALSE),
  max(x, na.rm = FALSE),
  range2(x, FALSE),
  range3(x, FALSE),
  range3a(x, FALSE)
)
