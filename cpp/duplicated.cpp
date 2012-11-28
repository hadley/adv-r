#include <Rcpp.h>
#include <algorithm>
using namespace Rcpp;

// Set
// [[Rcpp::export]]
LogicalVector duplicated1(IntegerVector x) {
  std::set<int> seen;

  LogicalVector out(x.size());

  IntegerVector::iterator it;
  LogicalVector::iterator out_it;

  for (it = x.begin(), out_it = out.begin(); it != x.end(); ++it, ++out_it) {
    *out_it = seen.insert(*it).second;
  }

  return out;
}

// Unordered set
// [[Rcpp::export]]
LogicalVector duplicated2(IntegerVector x) {
  std::tr1::unordered_set<int> seen;

  LogicalVector out(x.size());

  IntegerVector::iterator it;
  LogicalVector::iterator out_it;

  for (it = x.begin(), out_it = out.begin(); it != x.end(); ++it, ++out_it) {
    *out_it = seen.insert(*it).second;
  }

  return out;
}

// Unorderd set, caching iterators
// [[Rcpp::export]]
LogicalVector duplicated3(IntegerVector x) {
  std::tr1::unordered_set<int> seen;

  LogicalVector out(x.size());

  IntegerVector::iterator it, end = x.end();
  LogicalVector::iterator out_it;

  for (it = x.begin(), out_it = out.begin(); it != end; ++it, ++out_it) {
    *out_it = seen.insert(*it).second;
  }

  return out;
}

/*** R

library(microbenchmark)

x <- sample(1e3, 1e5, rep = T)
microbenchmark(
  duplicated(x),
  duplicated1(x),
  duplicated2(x),
  duplicated3(x)
)

# Fastest version of duplicated ~2.3x faster

*/