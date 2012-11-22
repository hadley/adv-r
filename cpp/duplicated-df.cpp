#include <Rcpp.h>
using namespace Rcpp;

LogicalVector duplicated_df(DataFrame df) {
  int n = df.nrow();
  LogicalVector out(n);
  
  
}