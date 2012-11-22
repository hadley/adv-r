#include <Rcpp.h>
#include <algorithm>
using namespace Rcpp;

std::tr1::unordered_set<double> unique1(NumericVector x) {
  return std::tr1::unordered_set<double>(x.begin(), x.end());
}
std::tr1::unordered_set<int> unique1(IntegerVector x) {
  return std::tr1::unordered_set<int>(x.begin(), x.end());
}
std::tr1::unordered_set<bool> unique1 (LogicalVector x) {
  return std::tr1::unordered_set<bool>(x.begin(), x.end());
}
std::tr1::unordered_set<std::string> unique1(CharacterVector x) {
  std::tr1::unordered_set<std::string> seen;

  for(CharacterVector::iterator it = x.begin(); it != x.end(); ++it) {
    seen.insert(std::string(*it));
  } 
  return(seen);
}

void unique1 (RObject x) {
  Rf_error("Unsupported type");
}


// [[Rcpp::export]]
RObject unique2(RObject x, ) {
  switch(x.sexp_type()) {
    case REALSXP: 
      return wrap(unique1(as<NumericVector>(x)));
    case INTSXP: 
      return wrap(unique1(as<IntegerVector>(x)));
    case STRSXP: 
      return wrap(unique1(as<CharacterVector>(x)));
    case LGLSXP: 
      return wrap(unique1(as<LogicalVector>(x)));
    default:
      Rf_error("Unsupported type");
  }
}

RObject dispatch(RObject x, Function f) {
  switch(x.sexp_type()) {
    case REALSXP: 
      return wrap(unique1(as<NumericVector>(x)));
    case INTSXP: 
      return wrap(unique1(as<IntegerVector>(x)));
    case STRSXP: 
      return wrap(unique1(as<CharacterVector>(x)));
    case LGLSXP: 
      return wrap(unique1(as<LogicalVector>(x)));
    default:
      Rf_error("Unsupported type");
  }
}


/*** R 
  options(digits = 3)
  library(microbenchmark)
  x <- sample(1e3, 1e5, rep = T)
  y <- x + 0.5
  z <- c(rep(T, 1e5 - 1), F)
  a <- sample(letters, 1e5, rep = T)
  
  microbenchmark(
    unique(x),
    unique2(x),
    unique(y),
    unique2(y),
    unique(z),
    unique2(z),
    unique(a),
    unique2(a)
  )

*/