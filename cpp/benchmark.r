library(microbenchmark)
library(Rcpp)

# Table ------------------------------------------------------------------------

sourceCpp("table.cpp")
x <- sample(letters, 1e4, rep = T)
microbenchmark(
  table(x),
  table1(x),
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
# Ask JJ about custom hashing function for R strings - since they're
# already in a string table, we can use that pointer as a hash.
#
# Building up a hash table is probably a common enough operation that'd
# it be useful to have a template that dispatched on the type of the
# input.

# Long x, short table
x <- sample(letters, 1e4, rep = T)
microbenchmark(
  match(x, letters),
  match1(x, letters),
  match2(x, letters)
)

x <- replicate(1e4, paste(sample(letters, 10), collapse = ""))
microbenchmark(
  match(x[1:10], x),
  match1(x[1:10], x),
  match2(x[1:10], x)
)

microbenchmark(
  match(x[9990:10000], x),
  match1(x[9990:10000], x),
  match2(x[9990:10000], x)
)
