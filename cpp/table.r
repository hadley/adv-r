library(microbenchmark)
library(Rcpp)

sourceCpp("table.cpp")
x <- sample(letters, 1e4, rep = T)
print(microbenchmark(
  table(x),
  table1(x),
  table4(x),
  table5(x),
  table6(x),
  table6a(x)
))
# About 2x slower
