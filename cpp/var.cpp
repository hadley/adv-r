#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
double var1(NumericVector x) {
  double mu = 0, m2 = 0;
  int n = x.size();

  for(int i = 0; i < n; ++i) {
    delta = x[i] - mu;
    mu = mu + delta / (i + 1);
    m2 = m2 + delta * (x - mu);
  }

  return m2 / (n - 1);
}
def online_variance(data):
    n = 0
    mean = 0
    M2 = 0
 
    for x in data:
        n = n + 1
        delta = x - mean
        mean = mean + delta/n
        M2 = M2 + delta*(x - mean)
 
    variance = M2/(n - 1)
    return variance