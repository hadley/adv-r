#include <Rcpp.h>
#include <numeric>
using namespace Rcpp;

// [[Rcpp::export]]
double sum1(NumericVector x) {
  double total = 0;

  int n = x.size();
  for(int i = 0; i < n; i++) {
    total += x[i];
  }
  return total;
}

// [[Rcpp::export]]
double sum2(NumericVector x) {
  double total = 0;

  for(NumericVector::iterator it = x.begin(); it != x.end(); it++) {
    total += *it;
  }
  return total;
}

// [[Rcpp::export]]
double sum2a(NumericVector x) {
  double total = 0;

  NumericVector::iterator end = x.end();
  for(NumericVector::iterator it = x.begin(); it != end; it++) {
    total += *it;
  }
  return total;
}

// [[Rcpp::export]]
double sum3(NumericVector x) {
  return std::accumulate(x.begin(), x.end(), 0.0);
}

// [[Rcpp::export]]
double sum4(NumericVector x) {
  return sum(x);
}

/*** R

library(microbenchmark)
x <- runif(1e4)
microbenchmark(
   sum(x),
   sum1(x),
   sum2(x),
   sum2a(x),
   sum3(x),
   sum4(x)
)

*/