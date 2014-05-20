#include <Rcpp.h>
#include <algorithm>
using namespace Rcpp;

// [[Rcpp::export]]
List rle2(NumericVector x) {
  std::vector<int> lengths;
  std::vector<double> values;

  // Initialise first value
  int i = 0;
  double prev = x[0];
  values.push_back(prev);
  lengths.push_back(1);

  for(NumericVector::iterator it = x.begin() + 1; it != x.end(); ++it) {
    if (prev == *it) {
      // Same as previous so increment lengths
      lengths[i]++;
    } else {
      // Different, so add to values, and add 1 to lengths
      values.push_back(*it);
      lengths.push_back(1);

      i++;
      prev = *it;
    }
  }

  return List::create(_["lengths"] = lengths, _["values"] = values);
}

/*** R

x <- rev(rep(1:20, 1:20))
y <- sample(10, 1e4, rep = T)

library(microbenchmark)
microbenchmark(
  rle(x),
  rle2(x),
  rle(y),
  rle2(y))

*/