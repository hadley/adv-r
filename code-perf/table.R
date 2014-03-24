library(microbenchmark)

x <- sample(10, 100, replace = TRUE)
y <- sample(10, 100, replace = TRUE)

table2d_1 <- function(x, y) table(x, y)

table2d_2 <- function(x, y) {
  stopifnot(length(x) == length(y))

  x <- addNA(x, TRUE)
  y <- addNA(y, TRUE)
  nl_x <- length(levels(x))
  nl_y <- length(levels(y))

  id <- as.integer(x) + (as.integer(y) - 1L) * nl_x

  tbl <- tabulate(id, nl_x * nl_y)
  matrix(tbl, nrow = nl_x)
}

table2d_1(x, y)
table2d_2(x, y)

microbenchmark(
  table2d_1(x, y),
  table2d_2(x, y)
)
