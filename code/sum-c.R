library(inline)


sum1 <- cfunction(signature(x = "numeric"), "
  double *px = REAL(x);
  int n = length(x);

  double sum = 0;

  for (R_xlen_t i = 0; i < n; i++) {
    sum += px[i];
  }

  return ScalarReal(sum);
")

sum2 <- cfunction(signature(x = "numeric"), "
  double *px = REAL(x);
  int n = length(x);

  double sum = 0;

  for (R_xlen_t i = 0; i < n; i++) {
    if (ISNA(px[i])) continue;
    sum += px[i];
  }

  return ScalarReal(sum);
")

x <- runif(1e3)
stopifnot(all.equal(sum1(x), sum(x)))
stopifnot(all.equal(sum2(x), sum(x)))

library(microbenchmark)
options(digits = 3)
microbenchmark(
  sum1(x),
  sum2(x),
  sum3(x),
  sum(x)
)
