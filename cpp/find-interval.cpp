#include <Rcpp.h>
#include <algorithm>
using namespace Rcpp;

// [[Rcpp::export]]
IntegerVector findInterval2(NumericVector x, NumericVector breaks) {
  IntegerVector out(x.size());

  NumericVector::iterator it, ubound;
  IntegerVector::iterator out_it;

  for(it = x.begin(), out_it = out.begin(); it != x.end(); it++, out_it++) {
    ubound = std::upper_bound(breaks.begin(), breaks.end(), *it);
    *out_it = std::distance(ubound, breaks.begin());
  }

  return(out);
}

// [[Rcpp::export]]
IntegerVector findInterval3(NumericVector x, NumericVector breaks) {
  IntegerVector out(x.size());

  NumericVector::iterator x_it = x.begin(), x_end = x.end(),
    breaks_it = breaks.begin(), breaks_end = breaks.end();
  IntegerVector::iterator out_it = out.begin(), out_end = out.end();
  NumericVector::iterator ubound; 
  
  for(; x_it != x_end; x_it++, out_it++) {
    ubound = std::upper_bound(breaks_it, breaks_end, *x_it);
    *out_it = std::distance(ubound, breaks_it);
  }

  return(out);
}
