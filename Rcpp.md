# High performance functions with Rcpp

Sometimes R code just isn't fast enough - you've already used all of the tips and tricks you know and you've used profiling to find the bottleneck, and there's simply no way to make the code any faster.  This chapter is the answer to that situation: use Rcpp to easily write key functions in C++ to get all the performance of C, while sacrificing the minimum of convenience.

(You can also write high performance code in straight C or Fortran.  These may (or may not) be more performant than C++, but you have to sacrifice a lot of convenience and master the complex C internals of R.  Using Rcpp is currently the best balance between speed and convenience)

The basic strategy is to keep as much code as possible in R, because:

* higher level language is more expressive

* don't need to compile which makes development faster

* you are probably more familiar with R than C++

Implementing bottlenecks in C++ can give considerable speed ups (2-3 orders of magnitude) and allows you to easily access best-of-breed data structures.  Keeping the majority of your code in straight R, means that you don't have to sacrifice the benefits of R.

## Essentials of C++

## Conversions

* from R to C
* from C to R
