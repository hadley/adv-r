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

// Special case for positive integers: will be fast when x is dense.
// [[Rcpp::export]]
LogicalVector duplicated4(IntegerVector x) {
  std::vector<bool> seen;

  LogicalVector out(x.size());

  IntegerVector::iterator it, end = x.end();
  LogicalVector::iterator out_it;

  for (it = x.begin(), out_it = out.begin(); it != end; ++it, ++out_it) {
    int val = *it;
    if (val > seen.size()) {
      seen.resize(val + 1);
    }
    *out_it = seen[val];
    seen[val] = true;
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
  duplicated3(x),
  duplicated4(x)
)
# Fastest version of duplicated ~2x faster

z <- sample(2 * 1e4, 1e4, rep = T)
microbenchmark(
  duplicated(z),
  duplicated1(z),
  duplicated2(z),
  duplicated3(z),
  duplicated4(z)
)
# Fastest version of duplicated ~4x slower

*/