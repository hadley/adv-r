#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
NumericVector range2(NumericVector x, const bool na_rm) {
  NumericVector out(2);
  out[0] = R_PosInf;
  out[1] = R_NegInf;

  int n = x.length();
  for(int i = 0; i < n; ++i) {
    if (!na_rm && R_IsNA(x[i])) {
      out[0] = NA_REAL;
      out[1] = NA_REAL;
      return out;
    }

    if (x[i] < out[0]) out[0] = x[i];
    if (x[i] > out[1]) out[1] = x[i];
  }

  return out;

}

// Iterators - the right way (but no faster than raw access)
// [[Rcpp::export]]
NumericVector range3(NumericVector x, const bool na_rm) {
  NumericVector out(2);
  out[0] = R_PosInf;
  out[1] = R_NegInf;

  NumericVector::iterator it;
  NumericVector::iterator end = x.end();
  for(it = x.begin(); it != end; ++it) {
    double val = *it;
    if (!na_rm && R_IsNA(val)) {
      out[0] = NA_REAL;
      out[1] = NA_REAL;
      return out;
    }

    if (val < out[0]) out[0] = val;
    if (val > out[1]) out[1] = val;
  }

  return out;

}

// Iterators - the _really_ right way but much slower
// [[Rcpp::export]]
NumericVector range3a(const NumericVector& x, const bool na_rm) {
  NumericVector out(2);
  out[0] = R_PosInf;
  out[1] = R_NegInf;

  NumericVector::iterator it;
  for(it = x.begin(); it != x.end(); ++it) {
    double val = *it;
    if (!na_rm && R_IsNA(val)) {
      out[0] = NA_REAL;
      out[1] = NA_REAL;
      return out;
    }

    if (val < out[0]) out[0] = val;
    if (val > out[1]) out[1] = val;
  }

  return out;
}

// If this was a pure c++ function, it might look like this
struct MyRange {
  double min;
  double max;
  MyRange() : min(R_PosInf), max(R_NegInf) {}
};

MyRange range(NumericVector x) {
  MyRange out;
  
  int n = x.length();
  for(int i = 0; i < n; ++i) {
    if (R_IsNA(x[i])) continue;

    if (x[i] < out.min) out.min = x[i];
    if (x[i] > out.max) out.max = x[i];
  }

  return out;   
}


/*** R

library(microbenchmark)

x <- c(NA, runif(1e5))
microbenchmark(
  range(x, na.rm = TRUE),
  min(x, na.rm = TRUE),
  max(x, na.rm = TRUE),
  range2(x, TRUE),
  range3(x, TRUE),
  range3a(x, TRUE)
)
microbenchmark(
  range(x, na.rm = FALSE),
  min(x, na.rm = FALSE),
  max(x, na.rm = FALSE),
  range2(x, FALSE),
  range3(x, FALSE),
  range3a(x, FALSE)
)

*/