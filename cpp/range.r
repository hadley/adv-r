library(Rcpp)
library(microbenchmark)

sourceCpp("range.cpp")

x <- c(runif(1e5), NA)
microbenchmark(
  range(x, na.rm = TRUE),
  min(x, na.rm = TRUE),
  max(x, na.rm = TRUE),
  range2(x, TRUE),
  range3(x, TRUE)
)
