#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
LogicalVector in1(NumericVector x, NumericVector table) {
  std::tr1::unordered_set<double> set;
  NumericVector::iterator it;

  for(it = table.begin(); it != table.end(); ++it) {
    set.insert(*it);
  }

  LogicalVector out(x.size());
  LogicalVector::iterator out_it;
  for(it = x.begin(), out_it = out.begin(); it != x.end(); ++it, ++out_it) {
    *out_it = (set.count(*it) == 1);
  }

  return out;
}

// [[Rcpp::export]]
LogicalVector in2(NumericVector x, NumericVector table) {
  std::tr1::unordered_set<double> set(table.begin(), table.end());

  NumericVector::iterator it;
  LogicalVector out(x.size());
  LogicalVector::iterator out_it;
  for(it = x.begin(), out_it = out.begin(); it != x.end(); ++it, ++out_it) {
    *out_it = set.count(*it);
  }

  return out;
}

// [[Rcpp::export]]
LogicalVector in3(NumericVector x, NumericVector table) {
  std::tr1::unordered_set<double> set(table.begin(), table.end());

  LogicalVector out(x.size());
  NumericVector::iterator x_it = x.begin(), x_end = x.end();
  LogicalVector::iterator out_it = out.begin();
  std::tr1::unordered_set<double>::iterator set_end = set.end();
  for(; x_it != x_end; ++x_it, ++out_it) {
    *out_it = set.find(*x_it) != set_end;
  }

  return out;
}


/*** R 
options(digits = 3)
library(microbenchmark)
x1 <- sample(10, 1e3, rep = T)
y1 <- 1:8

x2 <- sample(1e4, 1e3, rep = T)
y2 <- 1:1e4

stopifnot(all.equal(x1 %in% y1, in1(x1, y1)))
stopifnot(all.equal(x1 %in% y1, in2(x1, y1)))
stopifnot(all.equal(x1 %in% y1, in3(x1, y1)))

microbenchmark(
  x1 %in% y1,
  in1(x1, y1),
  in2(x1, y1),
  in3(x1, y1),
  x2 %in% y2,
  in1(x2, y2),
  in2(x2, y2),
  in3(x2, y2)
)
*/