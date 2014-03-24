x <- runif(1e5)
w <- runif(1e5)

sum(x * w)
crossprod(x, w)
x %*% w

library(microbenchmark)
microbenchmark(
  sum(x * w),
  t(x) %*% w,
  crossprod(x, w)
)


X <- matrix(runif(25 * 30), ncol = 25)

microbenchmark(
  sweep(X, 2, colSums(X), "/"),
  t(t(X) * (1 / colSums(X))),
  X %*% diag(1 / colSums(X))
)

microbenchmark(
  sweep(X, 1, rowSums(X), "/"),
  X * (1 / rowSums(X)),
  diag(1 / rowSums(X)) %*% X
)
