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

// Iterators - the right way
// [[Rcpp::export]]
NumericVector range3(NumericVector x, const bool na_rm) {
  NumericVector out(2);
  out[0] = R_PosInf;
  out[1] = R_NegInf;

  NumericVector::iterator it;
  NumericVector::iterator end = x.end();
  for(it = x.begin(); it != end; ++it) {
    double val = *it;
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


// Avoid initial comparisons
// [[Rcpp::export]]
NumericVector range4(NumericVector x, const bool na_rm) {
  NumericVector out(2);
  out[0] = x[0];
  out[1] = x[1];

  NumericVector::iterator it = x.begin();
  NumericVector::iterator end = x.end();
  for(it++; it != end; ++it) {
    double val = *it;
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