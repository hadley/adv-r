// An exploration of why C++ is twice as fast as R for a simple
// vectorised numerical problem.

#include <Rcpp.h>
using namespace Rcpp;

// Straight forward implementation using a loop
// [[Rcpp::export]]
NumericVector pdist2(double x, NumericVector ys) {
  int n = ys.size();
  NumericVector out(n);

  for(int i = 0; i < n; ++i) {
    out[i] = pow(ys[i] - x, 2);
  }
  return out;
}

// Expand x to a numeric vector, and explicitly construct internal vectors
// [[Rcpp::export]]
NumericVector pdist3(double x, NumericVector ys) {
  int n = ys.size();
  NumericVector internal(n), out(n);

  for(int i = 0; i < n; ++i) {
    internal[i] = ys[i] - x;
  }

  for(int i = 0; i < n; ++i) {
    out[i] = pow(internal[i], 2);
  }

  return out;
}

// Check explicitly for missings (even though this isn't necessary since the
// arithmetic operators will do it anyway)
// [[Rcpp::export]]
NumericVector pdist4(double x, NumericVector ys) {
  int n = ys.size();
  NumericVector internal(n), out(n);

  for(int i = 0; i < n; ++i) {
    if (ISNA(ys[i])) {
      out[i] = NA_REAL;
    } else {
      out[i] = pow(ys[i] - x, 2);  
    }
  }
  return out;
}


/*** R 
pdist1 <- function(x, ys) {
  (x[1] - ys) ^ 2
}

ys <- runif(1e5)
all.equal(pdist1(0.5, ys), pdist2(0.5, ys))
all.equal(pdist1(0.5, ys), pdist3(0.5, ys))

library(microbenchmark)
microbenchmark(
  pdist1(0.5, ys),
  pdist2(0.5, ys),
  pdist3(0.5, ys),
  pdist4(0.5, ys)
)

*/