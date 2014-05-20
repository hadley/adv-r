sum1 <- cfunction(signature(x = "integer", y = "integer"), "
  int n = length(x);
  SEXP z = allocVector(INTSXP, n);

  int *px = INTEGER(x);
  int *py = INTEGER(y);
  int *pz = INTEGER(z);

  for (int i = 0; i < n; i++) {
    pz[i] = px[i] + py[i];
  }

  return z;")

sum2 <- cfunction(signature(x = "integer", y = "integer"), "
  int n = length(x);
  SEXP z = allocVector(INTSXP, n);

  int *px = INTEGER(x);
  int *py = INTEGER(y);
  int *pz = INTEGER(z);

  for (int i = 0; i < n; i++) {
    if (px[i] == NA_INTEGER || py[i] == NA_INTEGER) {
      pz[i] = NA_INTEGER;
    } else {
      pz[i] = px[i] + py[i];
    }
  }

  return z;
")

x <- sample(1e3, 10, rep = T)
y <- sample(1e3, 10, rep = T)
stopifnot(all.equal(sum1(x, y), x + y))
stopifnot(all.equal(sum2(x, y), x + y))

plus <- function(x, y) x + y

library(microbenchmark)
options(digits = 3)
microbenchmark(
  sum1(x, y),
  sum2(x, y),
  plus(x, y),
  times = 10000
)
