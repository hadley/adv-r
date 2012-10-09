library(microbenchmark)

microbenchmark(
  a <- 1,
  assign("a", 1, envir = e),
  e$a <- 1,
  e[["a"]] <- 1,
  eval(quote(a <- 1), e)
)

microbenchmark(
  a,
  get("a", envir = e),
  e$a,
  e[["a"]],
  eval(quote(a), e)
)
