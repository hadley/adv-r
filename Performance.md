# Performance

General techniques for improving performance

## Brainstorming

Most important step is to brainstorm as many possible alternative approaches.

Good to have a variety of approaches to call upon.  

* Read blogs
* Algorithm/data structure courses (https://www.coursera.org/course/algs4partI)
* Book
* Read R code

We introduce a few at a high-level in the Rcpp chapter.

## Caching

`readRDS`, `saveRDS`, `load`, `save`

Caching packages

### Memoisation

A special case of caching is memoisation.

## Byte code compilation

R 2.13 introduced a new byte code compiler which can increase the speed of certain types of code 4-5 fold. This improvement is likely to get better in the future as the compiler implements more optimisations - this is an active area of research.

Using the compiler is an easy way to get speed ups - it's easy to use, and if it doesn't work well for your function, then you haven't invested a lot of time in it, and so you haven't lost much.

## Other people's code

One of the easiest ways to speed up your code is to find someone who's already done it! Good idea to search for CRAN packages.

    RppGSL, RcppEigen, RcppArmadillo

Stackoverflow can be a useful place to ask.

### Important vectorised functions

Not all base functions are fast, but many are. And if you can find the one that best matches your problem you may get big improvements

    cumsum, diff
    rowSums, colSums, rowMeans, colMeans
    rle
    match
    duplicated

Read the source code - implementation in C is usually correlated with high performance.

## Rewrite in a lower-level language

C, C++ and Fortran are easy. C++ easiest, recommended, and described in the following chapter.