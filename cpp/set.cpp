#include <Rcpp.h>
#include <algorithm>
using namespace Rcpp;

// [[Rcpp::export]]
NumericVector set(NumericVector x) {
  NumericVector out(x);

  std::sort(out.begin(), out.end());

  NumericVector::iterator unique = std::unique(x.begin(), x.end());

  return(out);
}
