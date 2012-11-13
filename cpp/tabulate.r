library(Rcpp)
library(microbenchmark)

sourceCpp("tabulate.cpp")
x <- sample(10, 1e5, rep = T)
print(microbenchmark(
  tabulate(x, 10),
  tabulate1(x, 10),
  tabulate2(x, 10)
))
# About 25% faster without check for NA
# Slower with NA check - but it doesn't actually seem to matter.
