#include <Rcpp.h>
#include <boost/unordered_map.hpp>
using namespace Rcpp;

// [[Rcpp::export]]
std::map<double, int> table1(NumericVector x) {
    
  // perform the count
  std::tr1::unordered_map<double, int> counts;
  int n = x.size();
  for (int i = 0; i < n; i++) {
    counts[x[i]]++;
  }
  
  // sort the results
  std::map<double, int> out(counts.begin(), counts.end());
  return out;
}

/*** R
library(microbenchmark)

x <- sample(1e3, 1e4, rep = T) + 0.5
microbenchmark(
  table(x),
  table1(x)
)

*/