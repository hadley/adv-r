#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
NumericVector pmin1(NumericVector x, NumericVector y) {
  int n = std::max(x.size(), y.size());
  NumericVector x1 = rep_len(x, n);
  NumericVector y1 = rep_len(y, n);

  NumericVector out(n);

  for (int i = 0; i < n; ++i) {
    out[i] = std::min(x[i], y[i]);
  }

  return out;
}

// [[Rcpp::export]]
NumericVector pmin2(NumericVector x, NumericVector y) {
  int n = std::max(x.size(), y.size());
  NumericVector x1 = rep_len(x, n);
  NumericVector y1 = rep_len(y, n);

  NumericVector out(n);

  for (int i = 0; i < n; ++i) {
    out[i] = x[i] < y[i] ? x[i] : y[i];
  }

  return out;
}

// [[Rcpp::export]]
NumericVector pmin3(NumericVector x, NumericVector y) {
  int n = std::max(x.size(), y.size());
  NumericVector x1 = rep_len(x, n);
  NumericVector y1 = rep_len(y, n);

  NumericVector out(n);

  NumericVector::iterator x_i = x.begin(), x_end = x.end(), y_i = y.begin(),
    out_i = out.begin();

  for (; x_i != x_end; ++x_i, ++y_i, ++out_i) {
    *out_i = std::min(*x_i, *y_i);
  }

  return out;
}

/*** R 

options(digits = 3)
library(microbenchmark)
x <- runif(1e5)
y <- runif(1e5)

stopifnot(all.equal(pmin(x, y), pmin1(x, y)))

microbenchmark(
  pmin(x, y),
  pmin1(x, y),
  pmin2(x, y),
  pmin3(x, y)
)

*/