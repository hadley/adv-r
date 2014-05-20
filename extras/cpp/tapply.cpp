#include <Rcpp.h>
#include <algorithm>
using namespace Rcpp;

// [[Rcpp::export]]
NumericVector tapply2(NumericVector x, IntegerVector i, Function fun) {
  std::vector< std::vector<double> > groups;
  
  NumericVector::iterator x_it;
  IntegerVector::iterator i_it;
  
  for(x_it = x.begin(), i_it = i.begin(); x_it != x.end(); ++x_it, ++i_it) {
    int i = *i_it;
    if (i > groups.size()) {
      groups.resize(i);
    }
    groups[i - 1].push_back(*x_it);
  }
  NumericVector out(groups.size());
  
  std::vector< std::vector<double> >::iterator g_it = groups.begin();
  NumericVector::iterator o_it = out.begin();
  for(; g_it != groups.end(); ++g_it, ++o_it) {
    NumericVector res = fun(*g_it);
    *o_it = res[0];
  }
  return out;
}

// [[Rcpp::export]]
NumericVector tapply3(NumericVector x, IntegerVector i, Function fun) {
  std::map<int, std::vector<double> > groups;
  
  NumericVector::iterator x_it;
  IntegerVector::iterator i_it;
  
  for(x_it = x.begin(), i_it = i.begin(); x_it != x.end(); ++x_it, ++i_it) {
    groups[*i_it].push_back(*x_it);
  }
  NumericVector out(groups.size());
  
  std::map<int, std::vector<double> >::const_iterator g_it = groups.begin();
  NumericVector::iterator o_it = out.begin();
  for(; g_it != groups.end(); ++g_it, ++o_it) {
    NumericVector res = fun(g_it->second);
    *o_it = res[0];
  }
  return out;
}

// [[Rcpp::export]]
NumericVector tapply4(NumericVector x, IntegerVector i, Function fun) {
  std::map<int, std::deque<double> > groups;
  
  NumericVector::iterator x_it;
  IntegerVector::iterator i_it;
  
  for(x_it = x.begin(), i_it = i.begin(); x_it != x.end(); ++x_it, ++i_it) {
    groups[*i_it].push_back(*x_it);
  }
  NumericVector out(groups.size());
  
  std::map<int, std::deque<double> >::const_iterator g_it = groups.begin();
  NumericVector::iterator o_it = out.begin();
  for(; g_it != groups.end(); ++g_it, ++o_it) {
    NumericVector res = fun(g_it->second);
    *o_it = res[0];
  }
  return out;
}

/*** R

library(microbenchmark)

x <- runif(1e5)
i <- sample(10, length(x), rep = T)

microbenchmark(
  tapply(x, i, sum),
  tapply2(x, i, sum),
  tapply3(x, i, sum),
  tapply4(x, i, sum)
)

i <- sample(sample(1e5, 10), length(x), rep = T)

microbenchmark(
  tapply(x, i, sum),
  # tapply2(x, i, sum),
  tapply3(x, i, sum),
  tapply4(x, i, sum)
)


*/