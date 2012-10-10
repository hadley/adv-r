subs <- function(expr, env) {
  stopifnot(is.language(expr))

  replace <- function(expr) {
    if (!is.name(expr)) return(expr)

    name <- as.character(expr)
    if (!exists(name, env)) return(expr)

    get(name, env)
  }

  capply(expr, replace)
}

# Need to make recursive
capply <- function(X, FUN, ...) {

  out <- lapply(X, FUN, ...)

  if (is.function(X)) {
    out <- as.function(out, environment(X))
  } else {
    mode(out) <- mode(X)
  }
  out
}

library(microbenchmark)

# Why is it so much slower?
microbenchmark(
  subs(quote(1 + a), list(a = 2)),
  substitute(1 + a, list(a = 2))
)
