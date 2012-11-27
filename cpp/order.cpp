#include <Rcpp.h>
using namespace Rcpp;

// Create a pair, sort it, extra first value
// [[Rcpp::export]]
IntegerVector order1(NumericVector x) {
  int n = x.size();
  std::vector<std::pair <double, int> > vals(n);

  for(int i = 0; i < n; i++) {
    vals[i] = std::make_pair<double, int>(x[i], i + 1);
  }

  std::sort(vals.begin(), vals.end());

  IntegerVector out(n);
  for(int i = 0; i < n; i++) {
    out[i] = vals[i].second;
  }

  return out;
}

// Insert values into ordered map and then iterate
// [[Rcpp::export]]
IntegerVector order2(NumericVector x) {
  int n = x.size();
  std::map<double, int> vals;

  for(int i = 0; i < n; i++) {
    vals[x[i]] = i;
  }

  IntegerVector out(n);
  std::map<double, int>::iterator it = vals.begin(), it_end = vals.end();
  IntegerVector::iterator out_it = out.begin();
  for(; it != vals.end(); ++it, ++out_it) {
    *out_it = it->second + 1;
  }

  return out;
}



class Sorter {
    NumericVector x_;
  public:
    Sorter (NumericVector x) : x_(x) {}
    bool inline operator() (int i, int j) const { 
      return (x_[i - 1] < x_[j - 1]);
    }
};

// Sort vector of indices using custom comparator that looks up values
// [[Rcpp::export]]
std::vector<int> order3(NumericVector x) {
  int n = x.size();
  std::vector<int> vals(n);

  for(int i = 0; i < n; i++) {
    vals[i] = i + 1;
  }

  std::sort(vals.begin(), vals.end(), Sorter(x));

  return vals;
}


class Sorter2 {
    Fast<NumericVector> x_;
  public:
    Sorter2 (Fast<NumericVector> x) : x_(x) {}
    bool inline operator() (int i, int j) const { 
      return (x_[i - 1] < x_[j - 1]);
    }
};

// Sort vector of indices using custom comparator that looks up values,
// using the Fast vector class.
// [[Rcpp::export]]
std::vector<int> order4(NumericVector x) {
  int n = x.size();
  std::vector<int> vals(n);
  Fast<NumericVector> fx(x);

  for(int i = 0; i < n; i++) {
    vals[i] = i + 1;
  }

  std::sort(vals.begin(), vals.end(), Sorter2(fx));

  return vals;
}

/*** R 
options(digits = 3)
library(microbenchmark)
x <- runif(1e4)
ord <- x[order(x)]

stopifnot(all.equal(ord, x[order1(x)]))
stopifnot(all.equal(ord, x[order2(x)]))
stopifnot(all.equal(ord, x[order3(x)]))
stopifnot(all.equal(ord, x[order4(x)]))

microbenchmark(
  order(x),
  order1(x),
  order2(x),
  order3(x),
  order4(x),
  sort(x)
)
*/