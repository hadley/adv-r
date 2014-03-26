#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
NumericVector diff_cpp(const NumericVector x, const int lag = 1) {
  int n = x.length();
  NumericVector y(n - lag);
  for (int i = lag; i < n; i++) {
    y[i - lag] = x[i] - x[i - lag];
  }
  return y;
}

/*** R

diff_r <- function (x) {
  xlen <- length(x)
  if (xlen <= 1) return(x[0L])

  x[-1] - x[-xlen]
}


library(microbenchmark)

x <- runif(1e4)
stopifnot(all.equal(diff(x), diff2(x)))
microbenchmark(
  diff(x),
  diff_r(x),
  diff_cpp(x)
)

*/
