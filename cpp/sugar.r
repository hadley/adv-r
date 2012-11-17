library(Rcpp)
library(microbenchmark)

# Compute distance between single point and vector of points
pdist1 <- function(x, ys) {
  (x - ys) ^ 2
}

cppFunction('
  NumericVector pdist2(double x, NumericVector ys) {
    int n = ys.size();
    NumericVector out(n);

    for(int i = 0; i < n; ++i) {
      out[i] = pow(ys[i] - x, 2);
    }
    return out;
  }
')

ys <- runif(1e4)
all.equal(pdist1(0.5, ys), pdist2(0.5, ys))

library(microbenchmark)
microbenchmark(
  pdist1(0.5, ys),
  pdist2(0.5, ys)
)
# C++ version about twice as fast, presumably because it avoids a
# complete vector allocation.


# Sugar version:
cppFunction('
  NumericVector pdist3(double x, NumericVector ys) {
    return pow((x - ys), 2);
  }
')
all.equal(pdist1(0.5, ys), pdist3(0.5, ys))

microbenchmark(
  pdist1(0.5, ys),
  pdist2(0.5, ys),
  pdist3(0.5, ys)
)
# 10-fold slower??  Maybe it's because I'm using a double instead of
# a numeric vector

cppFunction('
  NumericVector pdist4(NumericVector x, NumericVector ys) {
    return pow((x - ys), 2);
  }
')
all.equal(pdist1(0.5, ys), pdist4(0.5, ys))

# Is this a bug in sugar? Should recycle to length of longest vector.
# Let's try flipping the order of operations:

cppFunction('
  NumericVector pdist5(NumericVector x, NumericVector ys) {
    return pow((ys - x), 2);
  }
')
all.equal(pdist1(0.5, ys), pdist5(0.5, ys))
# Where are the missing values coming from??
