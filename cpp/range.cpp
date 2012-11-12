#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
NumericVector range2(NumericVector x, const bool na_rm) {
  NumericVector out(2);
  out[0] = R_PosInf;
  out[1] = R_NegInf;

  int n = x.length();
  for(int i = 0; i < n; i++) {
    if (!na_rm && x[i] == NA_REAL) {
      out[0] = NA_REAL;
      out[1] = NA_REAL;
      return(out);
    }

    if (x[i] < out[0]) out[0] = x[i];
    if (x[i] > out[1]) out[1] = x[i];
  }

  return(out);

}

// [[Rcpp::export]]
NumericVector range3(NumericVector x, const bool na_rm) {
  NumericVector out(2);
  out[0] = R_PosInf;
  out[1] = R_NegInf;

  int n = x.length();
  NumericVector::iterator it = x.begin();
  for(int i = 0; i < n; i++) {
    double val = it[i];
    if (!na_rm && val == NA_REAL) {
      out[0] = NA_REAL;
      out[1] = NA_REAL;
      return(out);
    }

    if (val < out[0]) out[0] = val;
    if (val > out[1]) out[1] = val;
  }

  return(out);

}

// Other optimisations: you can reduce the number of comparisons
// because if a value is a new min it's probably not the new max - could
// also elim