#include <Rcpp.h>
#include <boost/unordered_map.hpp>
using namespace Rcpp;

// No check for missing values
// [[Rcpp::export]]
IntegerVector tabulate1(IntegerVector x, const int max) {
  IntegerVector counts(max);
  
  int n = x.size();
  for (int i = 0; i < n; i++) {
    int pos = x[i] - 1;
    if (pos < max && pos >= 0) counts[pos]++;
  }

  return(counts);
}

// [[Rcpp::export]]
IntegerVector tabulate2(const IntegerVector x, const int max) {
  IntegerVector counts(max);
  
  int n = x.size();
  for (int i = 0; i < n; i++) {
    int pos = x[i] - 1;
    if (pos < max && pos >= 0 && !R_IsNA(pos)) counts[pos]++;
  }

  return(counts);
}
