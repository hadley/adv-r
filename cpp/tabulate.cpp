#include <Rcpp.h>
#include <boost/unordered_map.hpp>
using namespace Rcpp;

// No check for missing values
// [[Rcpp::export]]
IntegerVector tabulate1(const IntegerVector x, const int max) {
  IntegerVector counts(max);
  
  IntegerVector::iterator it = x.begin();
  int n = x.size();

  for (int i = 0; i < n; i++) {
    int pos = it[i] - 1;
    if (pos < max && pos >= 0) counts[pos]++;
  }

  return(counts);
}

// [[Rcpp::export]]
IntegerVector tabulate2(const IntegerVector x, const int max) {
  IntegerVector counts(max);
  
  IntegerVector::iterator it = x.begin();
  int n = x.size();

  for (int i = 0; i < n; i++) {
    int pos = it[i] - 1;
    if (pos < max && pos >= 0 && pos != NA_INTEGER) counts[pos]++;
  }

  return(counts);
}
