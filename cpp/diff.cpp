#include <Rcpp.h>
using namespace Rcpp;

NumericVector diff2(const NumericVector x, const int lag) {
  int n = x.length();
  NumericVector y(n - lag);
  for (int i = lag; i < n; i++) {
    y[i - lag] = x[i] - x[i - lag];
  }
  return(y);
}