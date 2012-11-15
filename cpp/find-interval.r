library(microbenchmark)
library(Rcpp)

sourceCpp("find-interval.cpp")

library(microbenchmark)
x <- sample(10, 1000, rep = T)
print(microbenchmark(
  findInterval(x, c(2, 4, 8)),
  findInterval2(x, c(2, 4, 8)),
  findInterval3(x, c(2, 4, 8))
))
