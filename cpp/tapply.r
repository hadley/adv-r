library(Rcpp)
library(microbenchmark)

sourceCpp("tapply.cpp")

x <- runif(1e5)
i <- sample(10, length(x), rep = T)

print(microbenchmark(
  tapply(x, i, sum),
  tapply2(x, i, sum),
  tapply3(x, i, sum),
  tapply4(x, i, sum)
))

i <- sample(sample(1e5, 10), length(x), rep = T)

print(microbenchmark(
  tapply(x, i, sum),
  # tapply2(x, i, sum),
  tapply3(x, i, sum),
  tapply4(x, i, sum)
))
