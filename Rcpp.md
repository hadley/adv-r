# High performance functions with Rcpp

Sometimes R code just isn't fast enough - you've already used all of the tips and tricks you know and you've used profiling to find the bottleneck, and there's simply no way to make the code any faster. This chapter is the answer to that problem: use Rcpp to easily write key functions in C++ to get all the performance of C, while sacrificing the minimum of convenience. [Rcpp](http://dirk.eddelbuettel.com/code/rcpp.html) is a fantastic tool written by Dirk Eddelbuettel and Romain Francois that makes it dead simple to write high-performance code in C++ that easily interfaces with the R-level data structures.

You can also write high performance code in straight C or Fortran. These may (or may not) be more performant than C++, but you have to sacrifice a lot of convenience and master the complex C internals of R, as well as doing memory management yourself. In my opinion, using Rcpp is currently the best balance between speed and convenience.

Writing performant code may also require you to rethink your basic approach: a solid understand of basic data structures and algorithms is very helpful here.  That's beyond the scope of this book, but I'd suggest the "algorithm design handbook" as a good place to start.  Or http://ocw.mit.edu/courses/electrical-engineering-and-computer-science/6-046j-introduction-to-algorithms-sma-5503-fall-2005/

The basic strategy is to keep as much code as possible in R, because:

* don't need to compile which makes development faster

* you are probably more familiar with R than C++

* people reading/maintaining your code in the future will probably be more familiar with R than C++

* don't know the length of the output vector

Implementing bottlenecks in C++ can give considerable speed ups (2-3 orders of magnitude) and allows you to easily access best-of-breed data structures.  Keeping the majority of your code in straight R, means that you don't have to sacrifice the benefits of R.  

Typically bottlenecks involve:

 * loops that can't easily be vectorised because each iteration depends on the previous.  (e.g. Sieve of Erastothenes: http://stackoverflow.com/questions/3789968/generate-a-list-of-primes-in-r-up-to-a-certain-number, simulation)
 
 * recursive functions

The aim of this chapter is to give you the absolute basics to get up and running with Rcpp for the purpose of speeding up slow parts of your code. Other resources that I found helpful when writing this chapter and you might too are:

* Slides from the [Rcpp master class ](http://dirk.eddelbuettel.com/blog/2011/04/29/#rcpp_class_2011-04_slides) taught by Dirk Eddelbuettel and Romain Francois in April 2011.

## Essentials of C++

Many many other components of C++, the idea here is to give you the absolute basics so that you can start writing code.  Emphasis on the C-like aspect of C++.  Minimal OO, minimal templating - just how to use them, not how to program them yourself.

* basic syntax
* creating variables and assigning
* control flow
* functions

### Variable types

Table that shows R, standard C++, and Rcpp classes.

* `int`, `long`, `float`, `double`, `bool`, `char`, `std::string`
* lists and data frames, named vectors
* functions

* Important methods: `length`, `fill`, `begin`, `end`, etc.

Conversions

* from R to C++: `as`
* from C++ to R: `wrap`

### Differences from R

* semi-colon at end of each line
* static typing
* vectors are 0-based
* compiled, not interpreted 
* variables are scalars by default
* `pow` instead of `^`

### RCpp syntax sugar

* vectorised operations: ifelse, sapply
* lazy functions: any, all

More details are available in the [Rcpp syntactic sugar](http://dirk.eddelbuettel.com/code/rcpp/Rcpp-sugar.pdf) vignette.

## Building

Prerequisites: R development environment (which you need for package building any).  C++ compiler (e.g. g++).

### Inline

Inline package is the absolute easiest way to 

    # TODO: Update to own example
    src <- ’
      int n = as<int>(ns); 
      double x = as<double>(xs);
      for (int i = 0; i<n; i++) 
        x = 1 / (1 + x);
      return wrap(x); ’ 
    l <- cxxfunction(signature(ns = "integer", xs = "numeric"), 
      body = src, plugin = "Rcpp")

### In package

For more details see the vignette, [Writing a package that uses Rcpp](http://dirk.eddelbuettel.com/code/rcpp/Rcpp-package.pdf).

    Rcpp.package.skeleton( "mypackage" )

Description:

    Depends: Rcpp (>= 0.9.4.1) 
    LinkingTo: Rcpp 

Namespace:

    useDynLib(mypackage)


Makefiles

R function


## Useful data structures and algorithms

From the standard template library (STL).  Can be very useful when implementing algorithms that rely on data structures with particular performance characteristics.

Useful resources:

* http://www.davethehat.com/articles/eff_stl.htm
* http://www.sgi.com/tech/stl/
* http://www.uml.org.cn/c++/pdf/EffectiveSTL.pdf

Compared to R these objects are typically mutable, and most operations operator destructively in place - this can be much faster.

* vector: like an R vector, but efficiently grows (but see the reserve method if you know something about how many space you'll need)
* deque
* list
* set: no duplicates, sorted
* map
* ropes

Useful algorithms

* partial sort
* binary search
* accumulate (example: total length of strings)
* sort with custom comparison operation?

http://community.topcoder.com/tc?module=Static&d1=tutorials&d2=alg_index

## More Rcpp

This chapter has only touched on a small part of Rcpp, giving you the basic tools to rewrite poorly performing R code in C++.  Rcpp has many other capabilities that make it easy to interface R to existing C++ code, including:

* automatically creating the wrappers between R data structures and C++ data
  structures (modules).  A good introduction to this topic is the vignette of [Rcpp modules](http://dirk.eddelbuettel.com/code/rcpp/Rcpp-modules.pdf)

* mapping of C++ classes to reference classes.

I strongly recommend keeping an eye on the [Rcpp homepage](http://dirk.eddelbuettel.com/code/rcpp.html) and signing up for the [Rcpp mailing list](http://lists.r-forge.r-project.org/cgi-bin/mailman/listinfo/rcpp-devel). Rcpp is still under active development, and is getting better with every release.
