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

  return counts;
}

// Don't really need explicit R_IsNA(pos) check because in C++ all comparisons
// involving a NaN always return false
// [[Rcpp::export]]
IntegerVector tabulate2(const IntegerVector x, const int max) {
  IntegerVector counts(max);
  
  int n = x.size();
  for (int i = 0; i < n; i++) {
    int pos = x[i] - 1;
    if (pos < max && pos >= 0 && !R_IsNA(pos)) counts[pos]++;
  }

  return counts;
}

/*** R
library(microbenchmark)

x <- sample(10, 1e5, rep = T)
microbenchmark(
  tabulate(x, 10),
  tabulate1(x, 10),
  tabulate2(x, 10)
)
# About 25% faster without check for NA
# Slower with NA check - but it doesn't actually seem to matter.

*/