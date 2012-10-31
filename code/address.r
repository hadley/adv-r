library(inline)
.address <- cfunction(c(x = "SEXP"), '
  return(ScalarReal((long) x));
')

address <- function(x) sprintf("%x", .address(x))
