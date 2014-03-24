We begin by defining the lookup matrices. I've laid them out in a way
that should make them easier to check against a reference, e.g.
<http://en.wikipedia.org/wiki/Verhoeff_algorithm>.

    d5_mult <- matrix(as.integer(c(
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
      1, 2, 3, 4, 0, 6, 7, 8, 9, 5,
      2, 3, 4, 0, 1, 7, 8, 9, 5, 6,
      3, 4, 0, 1, 2, 8, 9, 5, 6, 7,
      4, 0, 1, 2, 3, 9, 5, 6, 7, 8,
      5, 9, 8, 7, 6, 0, 4, 3, 2, 1,
      6, 5, 9, 8, 7, 1, 0, 4, 3, 2,
      7, 6, 5, 9, 8, 2, 1, 0, 4, 3,
      8, 7, 6, 5, 9, 3, 2, 1, 0, 4,
      9, 8, 7, 6, 5, 4, 3, 2, 1, 0
    )), ncol = 10, byrow = TRUE)

    d5_perm <- matrix(as.integer(c(
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
      1, 5, 7, 6, 2, 8, 3, 0, 9, 4,
      5, 8, 0, 3, 7, 9, 6, 1, 4, 2,
      8, 9, 1, 6, 0, 4, 3, 5, 2, 7,
      9, 4, 5, 3, 1, 2, 6, 8, 7, 0,
      4, 2, 8, 6, 5, 7, 3, 9, 0, 1,
      2, 7, 9, 3, 8, 0, 6, 4, 1, 5,
      7, 0, 4, 6, 9, 1, 3, 2, 5, 8
    )), ncol = 10, byrow = TRUE)

    d5_inv <- as.integer(c(0, 4, 3, 2, 1, 5, 6, 7, 8, 9))

Next, we'll define the check function, and try it out with a test input.
I've followed the derivation in wikipedia as closely as possible.

    p <- function(i, n_i) {
      d5_perm[(i %% 8) + 1, n_i + 1] + 1
    }
    d <- function(c, p) {
      d5_mult[c + 1, p]
    }

    verhoeff <- function(x) {
      #split and convert to numbers
      digs <- strsplit(as.character(x), "")[[1]]
      digs <- as.numeric(digs)
      digs <- rev(digs)   ## right to left algorithm

      ## apply algoritm - note 1-based indexing in R
      c <- 0
      for (i in 1:length(digs)) {
        c <- d(c, p(i, digs[i]))
      }

      d5_inv[c + 1]
    }
    verhoeff(142857)

    ## [1] 0

This function is fundamentally iterative, as each iteration depends on
the value of the previous. This means that we're unlikely to be able to
vectorise in R, so if we want to vectorise, we'll need to use Rcpp.

However, before we turn to that, it's worth exploring if we can do the
initial split faster. First we do a little microbenchmark to see if it's
worth bothering:

    library(microbenchmark)
    digits <- function(x) {
      digs <- strsplit(as.character(x), "")[[1]]
      digs <- as.numeric(digs)
      rev(digs)
    }

    microbenchmark(
      digits(142857),
      verhoeff(142857)
    )

    ## Unit: microseconds
    ##              expr   min    lq median    uq    max neval
    ##    digits(142857) 11.70 12.31  12.80 13.31  26.95   100
    ##  verhoeff(142857) 32.87 34.33  35.17 35.85 123.92   100

It looks like it! On my computer, `verhoeff_prepare()` accounts for
about 50% of the run time. A little searching on stackoverflow reveals
another approach to turning a [number into
digits](http://stackoverflow.com/questions/18786432):

    digits2 <- function(x) {
       n <- floor(log10(x))
       x %/% 10^(0:n) %% 10
    }
    digits2(12345)

    ## [1] 5 4 3 2 1

    microbenchmark(
      digits(142857),
      digits2(142857)
    )

    ## Unit: microseconds
    ##             expr    min     lq median     uq   max neval
    ##   digits(142857) 11.507 11.942 12.233 12.576 63.48   100
    ##  digits2(142857)  2.314  2.705  3.128  3.477 26.05   100

`digits2()` is a lot faster than `digits()` but it has limited impact on
the whole runtime.

    verhoeff2 <- function(x) {
      digs <- digits2(x)

      c <- 0
      for (i in 1:length(digs)) {
        c <- d(c, p(i, digs[i]))
      }

      d5_inv[c + 1]
    }
    verhoeff2(142857)

    ## [1] 0

    microbenchmark(
      verhoeff(142857),
      verhoeff2(142857)
    )

    ## Unit: microseconds
    ##               expr   min    lq median    uq    max neval
    ##   verhoeff(142857) 33.92 35.69  36.51 37.78 124.65   100
    ##  verhoeff2(142857) 21.85 23.19  25.18 26.07  54.15   100

It's always worth checking out the impact of byte-code compilation:

    verhoeff_c <- compiler::cmpfun(verhoeff)
    verhoeff2_c <- compiler::cmpfun(verhoeff2)
    microbenchmark(
      verhoeff(142857),
      verhoeff_c(142857),
      verhoeff2(142857),
      verhoeff2_c(142857)
    )

    ## Unit: microseconds
    ##                 expr   min    lq median    uq    max neval
    ##     verhoeff(142857) 33.34 36.15  37.15 38.02 104.43   100
    ##   verhoeff_c(142857) 31.98 33.79  34.69 35.38  46.21   100
    ##    verhoeff2(142857) 21.34 24.22  25.44 26.52  44.61   100
    ##  verhoeff2_c(142857) 20.42 23.22  24.03 25.36  35.48   100

It looks like it speeds it up by around 10%, which is fairly typical.

To make it even faster we could try C++.

    #include <Rcpp.h>
    using namespace Rcpp;

    // [[Rcpp::export]]
    int verhoeff3_c(IntegerVector digits, IntegerMatrix mult, IntegerMatrix perm,
                    IntegerVector inv) {
      int n = digits.size();
      int c = 0;

      for(int i = 0; i < n; ++i) {
        int p = perm(i % 8, digits[i]);
        c = mult(c, p);
      }

      return inv[c];
    }

    verhoeff3 <- function(x) {
      verhoeff3_c(digits(x), d5_mult, d5_perm, d5_inv)
    }
    verhoeff3(142857)

    ## [1] 3

    microbenchmark(
      verhoeff2(142857),
      verhoeff3(142857)
    )

    ## Unit: microseconds
    ##               expr   min    lq median    uq    max neval
    ##  verhoeff2(142857) 22.16 23.56  26.65 27.97  57.18   100
    ##  verhoeff3(142857) 17.49 18.34  19.11 19.95 102.51   100

That doesn't yield much of an improvement. Maybe we can do better if we
pass the number to C++ and process the digits in a loop:

    #include <Rcpp.h>
    using namespace Rcpp;

    // [[Rcpp::export]]
    int verhoeff4_c(int number, IntegerMatrix mult, IntegerMatrix perm,
                    IntegerVector inv) {
      int c = 0;
      int i = 0;

      for (int i = 0; number > 0; ++i, number /= 10) {
        int p = perm(i % 8, number % 10);
        c = mult(c, p);
      }

      return inv[c];
    }

    verhoeff4 <- function(x) {
      verhoeff4_c(x, d5_mult, d5_perm, d5_inv)
    }
    verhoeff4(142857)

    ## [1] 3

    microbenchmark(
      verhoeff2(142857),
      verhoeff3(142857),
      verhoeff4(142857)
    )

    ## Unit: microseconds
    ##               expr   min     lq median     uq   max neval
    ##  verhoeff2(142857) 23.07 25.883 28.147 30.708 72.31   100
    ##  verhoeff3(142857) 18.11 19.992 21.227 23.005 78.80   100
    ##  verhoeff4(142857)  3.24  4.402  4.891  5.255 18.82   100

And we get a pay off: `verhoeff4()` is about 5 times faster than
`verhoeff2()`.
