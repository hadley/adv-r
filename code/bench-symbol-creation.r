library(inline)
new_symbol <- cfunction(NULL, '
  SEXP symbol = install("test");
  return(symbol);
')
new_string <- cfunction(NULL, '
  SEXP symbol = mkString("test");
  return(symbol);
')

library(microbenchmark)
microbenchmark(
  new_symbol(),
  new_string(), times = 10000,
  "test",
  as.name("test"))
