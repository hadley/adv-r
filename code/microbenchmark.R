library(microbenchmark)
options(digits = 3)
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
