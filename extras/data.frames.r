# As far as I can tell, these details are not documented anywhere:
# ?data.frame, ?Ops.data.frame, ?"+",  R language,
# Ops.data.frame for implementation details
options(digits = 3)

df <- data.frame(a = 1:10, b = -(1:10))
# Vectors are applied to every column
df + 10
# Recycled first along the rows, then the columns
df + c(0, 10)
df + c(rep(0, 19), 100)

# Lists are matched to each column in order
df + list(0, 10)
df + list(c(0, 10), 10)

# Beware: names are ignored
df + list(b = 0, a = 10)

# Matrices are treated as vectors
df + matrix(c(0, 10), ncol = 2)
df + as.numeric(matrix(c(0, 10), ncol = 2))
df + matrix(c(0, 10), ncol = 2, nrow = 10, byrow = TRUE)
df + as.numeric(matrix(c(0, 10), ncol = 2, nrow = 10, byrow = TRUE))

# Data frames must be exactly the same size
df + data.frame(a = 0, b = 10)
df + data.frame(a = rep(-10, 10), b = rep(10, 10))
# And matching only occurs by position, not name
df + data.frame(b = rep(-10, 10), a = rep(10, 10))
df + data.frame(d = rep(-10, 10), e = rep(10, 10))

library(microbenchmark)

df <- data.frame(a = 1:10, b = -(1:10))
l <- list(0, 10)
l_2 <- list(rep(0, 10), rep(10, 10))
m <- matrix(c(0, 10), ncol = 2, nrow = 10, byrow = TRUE)
df_2 <- as.data.frame(m)
v <- as.numeric(m)

microbenchmark(
  df + v,
  df + l,
  df + l_2,
  df + m,
  df + df_2
)

# Adding a list is fastest, closely followed by a data frame.
# Adding matrices/vectors is slowest.

# Different with logical operations: you get a matrix back.
df > 10
# This is presumably to make subsetting easier
