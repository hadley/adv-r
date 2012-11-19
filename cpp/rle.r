library(Rcpp)
library(microbenchmark)

sourceCpp("rle.cpp")

x <- rev(rep(1:20, 1:20))
print(microbenchmark(
  rle(x),
  rle2(x)))
