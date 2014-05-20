#include <Rcpp.h>
using namespace Rcpp;

double vacc3a(double age, bool female, double ily){
  double p = 0.25 + 0.3 * 1 / (1 - exp(0.04 * age)) + 0.1 * ily;
  p = p * (female ? 1.25 : 0.75);
  p = std::max(p, 0.0); 
  p = std::min(p, 1.0);
  return p;
}

// [[Rcpp::export]]
NumericVector vacc3(NumericVector age, LogicalVector female, NumericVector ily) {
  int n = age.size();
  NumericVector out(n);

  for(int i = 0; i < n; ++i) {
    out[i] = vacc3a(age[i], female[i], ily[i]);
  }

  return out;
}

// [[Rcpp::export]]
NumericVector vacc4(NumericVector age, LogicalVector female, NumericVector ily) {
  NumericVector p(age.size());

  p = 0.25 + 0.3 * 1 / (1 - exp(0.04 * age)) + 0.1 * ily;
  p = p * ifelse(female, 1.25, 0.75);
  p = pmax(0,p); 
  p = pmin(1,p);
  return p;
}

// [[Rcpp::export]]
NumericVector vacc5(NumericVector age, LogicalVector female, NumericVector ily) {
  NumericVector p(age.size());

  p = 0.25 + 0.3 * 1 / (1 - exp(0.04 * noNA(age))) + 0.1 * noNA(ily);
  p = noNA(p) * ifelse(noNA(female), 1.25, 0.75);
  p = pmax(0, noNA(p)); 
  p = pmin(1, noNA(p));
  return p;
}
