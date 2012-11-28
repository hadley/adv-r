#include <Rcpp.h>
#include <algorithm>
using namespace Rcpp;

// [[Rcpp::export]]
std::tr1::unordered_set<int> unique1(IntegerVector x) {
  std::tr1::unordered_set<int> seen;

  for(IntegerVector::iterator it = x.begin(); it != x.end(); ++it) {
    seen.insert(*it);
  } 
  return seen;
}

// [[Rcpp::export]]
std::tr1::unordered_set<int> unique2(IntegerVector x) {
  std::tr1::unordered_set<int> seen;
  seen.insert(x.begin(), x.end());

  return seen;
}

// [[Rcpp::export]]
std::tr1::unordered_set<int> unique3(IntegerVector x) {
  std::tr1::unordered_set<int> seen(x.begin(), x.end());
  return seen;
}

// [[Rcpp::export]]
std::tr1::unordered_set<int> unique4(IntegerVector x) {
  return std::tr1::unordered_set<int>(x.begin(), x.end());
}

/*** R

library(microbenchmark)

microbenchmark(
  sort(unique(x)),
  s_unique(x),
  sort(unique1(x)),
  sort(unique2(x)),
  sort(unique3(x))
)

x <- sample(1e3, 1e6, rep = T)
microbenchmark(
  unique(x),
  unique1(x),
  unique2(x),
  unique3(x),
  unique4(x)
)

*/