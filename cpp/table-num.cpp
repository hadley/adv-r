#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
std::map<double, int> tableC(NumericVector x) {
  std::map<double, int> counts;

  int n = x.size();
  for (int i = 0; i < n; i++) {
    counts[x[i]]++;
  }

  return counts;
}


/*** R
library(microbenchmark)

x <- sample(1e3, 1e4, rep = T) + 0.5
microbenchmark(
  table(x),
  tableC(x)
)

*/
