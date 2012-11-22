library(Rcpp)
library(microbenchmark)

sourceCpp("duplicated.cpp")

x <- sample(1e3, 1e5, rep = T)
print(microbenchmark(
  duplicated(x),
  duplicated2(x),
  duplicated3(x),
  duplicated3a(x),
  duplicated4(x)
))

print(microbenchmark(
  sort(unique(x)),
  s_unique(x),
  sort(unique1(x)),
  sort(unique2(x)),
  sort(unique3(x))
))

x <- sample(1e3, 1e6, rep = T)
print(microbenchmark(
  unique(x),
  unique1(x),
  unique2(x),
  unique3(x),
  unique4(x)
))
