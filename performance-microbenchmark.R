library(microbenchmark)
options(digits = 3)

# Cache values of last benchmark so can re-use in text
benchmark <- new.env()
benchmark$last <- NULL

microbenchmark <- function(...) {
  out <- eval(substitute(microbenchmark::microbenchmark(...)))
  benchmark$last <- out
  out
}

last_benchmark <- function(expr, fun = median) {
  if (is.null(benchmark$last))
    stop("No previous benchmark", call. = FALSE)

  structure(
    fun(benchmark$last$time[benchmark$last$expr == expr]),
    class = "benchmark"
  )
}

knit_print.benchmark <- function(x, ...) {
  format(signif(x, 1), big.mark = ",")
}

print.benchmark <- function(x, ...) {
  cat(knitr::knit_print(x), ...)
}


print_microbenchmark <- function (x, unit, order = NULL, ...) {
  s <- summary(x, unit = unit)
  cat("Unit: ", attr(s, "unit"), "\n", sep = "")

  timing_cols <- c("min", "lq", "median", "uq", "max")
  s[timing_cols] <- lapply(s[timing_cols], signif, digits = 3)
  s[timing_cols] <- lapply(s[timing_cols], format, big.mark = ",")

  print(s, ..., row.names = FALSE)
}
assignInNamespace("print.microbenchmark", print_microbenchmark,
  "microbenchmark")
