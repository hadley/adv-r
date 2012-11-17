#include <Rcpp.h>
#include <algorithm>
using namespace Rcpp;

// [[Rcpp::export]]
LogicalVector duplicated2(IntegerVector x) {
  std::set<int> seen;

  LogicalVector out(x.size());

  IntegerVector::iterator it;
  LogicalVector::iterator out_it;

  for (it = x.begin(), out_it = out.begin(); it != x.end(); ++it, ++out_it) {
    *out_it = seen.insert(*it).second;
  }

  return(out);
}

// [[Rcpp::export]]
LogicalVector duplicated3(IntegerVector x) {
  std::set<int> seen;

  LogicalVector out(x.size());

  IntegerVector::iterator it, end = x.end();
  LogicalVector::iterator out_it;

  for (it = x.begin(), out_it = out.begin(); it != end; ++it, ++out_it) {
    *out_it = seen.insert(*it).second;
  }

  return(out);
}

// [[Rcpp::export]]
LogicalVector duplicated3a(IntegerVector x) {
  std::tr1::unordered_set<int> seen;

  LogicalVector out(x.size());

  IntegerVector::iterator it, end = x.end();
  LogicalVector::iterator out_it;

  for (it = x.begin(), out_it = out.begin(); it != end; ++it, ++out_it) {
    *out_it = seen.insert(*it).second;
  }

  return(out);
}

// [[Rcpp::export]]
LogicalVector duplicated4(IntegerVector x) {
  std::set<int> seen;
  int n = x.size();
  LogicalVector out(n);

  for (int i = 0; i < n; ++i) {
    out[i] = seen.insert(x[i]).second;
  }

  return(out);
}

// [[Rcpp::export]]
std::set<int> s_unique(IntegerVector x) {
  std::set<int> seen;

  for(IntegerVector::iterator it = x.begin(); it != x.end(); ++it) {
    seen.insert(*it);
  } 
  return(seen);
}

// [[Rcpp::export]]
std::tr1::unordered_set<int> unique1(IntegerVector x) {
  std::tr1::unordered_set<int> seen;

  for(IntegerVector::iterator it = x.begin(); it != x.end(); ++it) {
    seen.insert(*it);
  } 
  return(seen);
}