#include <Rcpp.h>
#include <boost/unordered_map.hpp>
using namespace Rcpp;

// [[Rcpp::export]]
IntegerVector match1(const CharacterVector x, const CharacterVector table) {
  boost::unordered_map<std::string, int> lookup;

  int n = table.length();
  for (int i = 0; i < n; i++) {
    const char* name = table[i];
    lookup[name] = i + 1;
  }

  int m = x.length();
  IntegerVector out(m);
  for (int j = 0; j < m; j++) {
    const char* name = x[j];
    out[j] = lookup[name];
  }
  return(out);
}