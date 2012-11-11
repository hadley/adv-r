library(microbenchmark)
library(Rcpp)

# Table ------------------------------------------------------------------------

sourceCpp("table.cpp")
x <- sample(letters, 1e4, rep = T)
microbenchmark(
  table(x),
  table4(x),
  table5(x)
)
# About 2x slower

# Tabulate ---------------------------------------------------------------------

sourceCpp("tabulate.cpp")
x <- sample(10, 1e5, rep = T)
microbenchmark(
  tabulate(x, 10),
  tabulate1(x, 10),
  tabulate2(x, 10)
)
# About 25% faster without check for NA
# About the same speed with NA check


# match ------------------------------------------------------------------------

sourceCpp("match.cpp")
x <- sample(letters, 1e6, rep = T)
microbenchmark(
  match(x, letters),
  match1(x, letters), times = 10
)
