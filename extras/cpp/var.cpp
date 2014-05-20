#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
double var1(NumericVector x) {
  double mu = 0, m2 = 0;
  int n = x.size();

  for(int i = 0; i < n; ++i) {
    double delta = x[i] - mu;
    mu = mu + delta / (i + 1);
    m2 = m2 + delta * (x[i] - mu);
  }

  return m2 / (n - 1);
}

// [[Rcpp::export]]
double var2(NumericVector x) {
  double mu = 0, m2 = 0;
  int n = x.size();
  Fast<NumericVector> fx(x);

  for(int i = 0; i < n; ++i) {
    double delta = fx[i] - mu;
    mu = mu + delta / (i + 1);
    m2 = m2 + delta * (fx[i] - mu);
  }

  return m2 / (n - 1);
}

/*** R
x <- runif(1e3)
y <- runif(1e5)

library(microbenchmark)

microbenchmark(
  var(x),
  var1(x),
  var2(x),
  var(y),
  var1(y),
  var2(y)
)

*/
