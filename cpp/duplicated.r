library(Rcpp)
library(microbenchmark)

sourceCpp("duplicated.cpp")

x <- sample(1e3, 1e5, rep = T)
print(microbenchmark(
  duplicated(x),
  duplicated2(x),
  duplicated3(x),
  duplicated4(x)
))


print(microbenchmark(
  sort(unique(x)),
  s_unique(x)
))
