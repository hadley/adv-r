library(microbenchmark)
library(Rcpp)

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
