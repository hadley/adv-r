call2 <- function(f, args) {
  f <- as.name(f)
  as.call(c(list(f), args))
}

bench <- function(funs, args, ...) {
  stopifnot(!is.null(names(funs)))

  calls <- lapply(names(funs), call2, args)
  names(calls) <- names(funs)

  eval(bquote(microbenchmark(list = .(calls))), funs, parent.frame())
}

funs <- list(
  base = function(x) mean(x),
  sum = function(x) sum(x) / length(x)
)
x <- runif(1e6)
bench(funs, alist(x))
