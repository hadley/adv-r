# High performance functions with Rcpp

Sometimes R code just isn't fast enough - you've already used all of the tips and tricks you know and you've used profiling to find the bottleneck, and there's simply no way to make the code any faster. This chapter is the answer to that problem: use Rcpp to easily write key functions in C++ to get all the performance of C, while sacrificing the minimum of convenience. [Rcpp](http://dirk.eddelbuettel.com/code/rcpp.html) is a fantastic tool written by Dirk Eddelbuettel and Romain Francois that makes it dead simple to write high-performance code in C++ that easily interfaces with the R-level data structures.

You can also write high performance code in straight C or Fortran. These may (or may not) be more performant than C++, but you have to sacrifice a lot of convenience and master the complex C internals of R, as well as doing memory management yourself. In my opinion, using Rcpp is currently the best balance between speed and convenience.

Writing performant code may also require you to rethink your basic approach: a solid understand of basic data structures and algorithms is very helpful here.  That's beyond the scope of this book, but I'd suggest the "algorithm design handbook" as a good place to start.  Or http://ocw.mit.edu/courses/electrical-engineering-and-computer-science/6-046j-introduction-to-algorithms-sma-5503-fall-2005/

The basic strategy is to keep as much code as possible in R, because:

* you are probably more familiar with R than C++

* people reading/maintaining your code in the future will probably be more familiar with R than C++

Implementing bottlenecks in C++ can give considerable speed ups (2-3 orders of magnitude) and allows you to easily access best-of-breed data structures.  Keeping the majority of your code in straight R, means that you don't have to sacrifice the benefits of R.  

Typical bottlenecks involve:

 * loops that can't easily be vectorised because each iteration depends on the previous: this is because C++ modifies in place by default, so there is little overhead for modifying a data structure many many times.
 
 * functions that are most elegantly expressed recursively: the overhead of calling a function in C++ is much much lower than the overhead of all a function in R.
 
 * functions that advanced data structures and algorithms that R doesn't provide

The aim of this chapter is to give you the absolute basics to get up and running with Rcpp for the purpose of speeding up slow parts of your code. You'll lean the essence of C++ by seeing how simple R functions are converted to there C++ equivalents.  Other resources that I found helpful when writing this chapter and you might too are:

* Slides from the [Rcpp master class ](http://dirk.eddelbuettel.com/blog/2011/04/29/#rcpp_class_2011-04_slides) taught by Dirk Eddelbuettel and Romain Francois in April 2011.

## Getting started

All examples in this chapter use the development version of the `Rcpp` package (>= 0.9.15.6). This version includes `cppFunction`, which makes it easier than ever to connect C++ to R.  You can install it with:

    install.packages("Rcpp", repos="http://R-Forge.R-project.org", 
      type = "source")
    library(Rcpp)

You'll also (obviously) need a working C++ compiler. 

`cppFunction` works slightly differently to `install::cfunction` - you specify the function completely in the string, and it parses that function to figure out what the arguments to the R function should be.  

    cppFunction('
      int fib(const int x) {
        if (x == 0) return(0); 
        if (x == 1) return(1);
        return fib(x - 1) + fib(x - 2);
      }'
    )
    fib(2)
    fib(-1) # segfault from C stack overflow
    fib(y = 1) # no error
    fib(1, 2) # no error
    fib(135) # no way to escape
    fib("a") # errors

The final section of this chapter shows you how to turn C++ functions you've created with `cppFunction` into C++ code for a package. While using `cppFunction` is easiest when exploring new code (and in tutorials like this), when you're actually developing code it's easier to set up a src directory and use `devtools::load_all` to automatically reload and recompile your code.

## Essentials of C++

C++ is a large language, and there's no way to cover it exhaustively here.  Our aim is to give you the the absolute basics so that you can start writing fast code. We we'll spend minimal time on object oriented C++ and on templating, because our focus is not on writing big programs in C++, just single, self-contained functions that allow you to speed up slow parts of your R code.  We'll focus on C++ 11 (the C++ standard written in 2011, formerly known as C++0x (as it was supposed be finished by 2009))

C++ strengths are as an infrastructure program language. Designed for environments where speed and safety are critical. This comes at a cost of verbosity compared to R - there is a quite a lot more typing to do (although modern C++ 11 techniques can offset that a lot).  

The biggest differences from R are:

* C++ is compiled: 
* semi-colon at end of each line
* static typing
* vectors are 0-based
* compiled, not interpreted 
* variables are scalars by default
* `pow` instead of `^`

In the following section we'll compare and contrast basic R functions with their C++ equivalents.

Let's start with a very simple function.  It has no arguments and always returns the the integer1 :

    one <- function() 1L

This example shows some of the key differences between R and C++:

    cppFunction('
      int one() {
        return(1);
      }'
    )

In C++ the syntax to create a function looks like the syntax to call a function: `one() {...}`.  Another key difference is that we have to declare the type of output the function returns: an integer.

* Vector: `IntegerVector`, scalar: `int`
* Vector: `NumericVector`, scalar: `double`
* Vector: `CharacterVector`, scalar: `std::string`

The final difference is that we must use an explicit `return` statement in C++, and that every statement is terminated by a `;`.

    sign1 <- function(x) {
      if (x > 0) {
        1
      } else if (x == 0) {
        0
      } else {
        -1
      }
    }

    cppFunction('
      int sign2(const int x) {
        if (x > 0) {
          return(1);
        } else if (x == 0) {
          return(0);
        } else {
          return(-1);
        }
      }'
    )

In the C++ version:

* we need to declare what type of input the function takes
* the if syntax is identical

Let's continue the example by vectorising it

    sign1 <- function(x) {
      
      if (x > 0) {
        1
      } else if (x == 0) {
        0
      } else {
        -1
      }
    }

    cppFunction('
      int sign2(const int x) {
        if (x > 0) {
          return(1);
        } else if (x == 0) {
          return(0);
        } else {
          return(-1);
        }
      }'
    )

    diff1 <- function(x, lag) {
      n <- length(x)
      y <- numeric(n)

      for (i in seq(lag + 1, n)) {
        y[i - lag + 1] <- x[i] - x[i - lag + 1]
      }
      y
    }


* basic syntax
* creating variables and assigning
* control flow (new for statement)
* functions

## Variable types

Table that shows R, standard C++, and Rcpp classes.

* NumericVector
* CharacterVector
* IntegerVector
* LogicalVector
* List

Also provides matrix equivalents of the above classes. 

* Function
* Environment
* DataFrame

As well as classes for many more specialised language objects: `ComplexVector`, `RawVector`, `DottedPair`, `Language`,  `Promise`, `Symbol`, `WeakReference` and so on.  These are beyond the scope of this document and won't be discussed further.

You can also use standard C++ variable types for scalars: `int`, `long`, `float`, `double`, `bool`, `char`, `std::string`.  

* lists and data frames, named vectors
* functions

* Important methods: `length`, `fill`, `begin`, `end`, etc.

### RCpp syntax sugar

* vectorised operations: ifelse, sapply
* lazy functions: any, all

More details are available in the [Rcpp syntactic sugar](http://dirk.eddelbuettel.com/code/rcpp/Rcpp-sugar.pdf) vignette.

## Useful data structures and algorithms

From the standard template library (STL).  Can be very useful when implementing algorithms that rely on data structures with particular performance characteristics.

Useful resources:

* http://www.cplusplus.com/reference/algorithm/
* http://www.cplusplus.com/reference/stl/

* http://www.davethehat.com/articles/eff_stl.htm
* http://www.sgi.com/tech/stl/
* http://www.uml.org.cn/c++/pdf/EffectiveSTL.pdf

Compared to R these objects are typically mutable, and most operations operator destructively in place - this can be much faster.

* vector: like an R vector, but efficiently grows (but see the reserve method if you know something about how many space you'll need)
* set: no duplicates, sorted
* map

Useful algorithms

* partial sort
* binary search
* accumulate (example: total length of strings)
* sort with custom comparison operation?

http://community.topcoder.com/tc?module=Static&d1=tutorials&d2=alg_index

### Profiling

http://stackoverflow.com/questions/13224322/profiling-rcpp-code-on-os-x

## Case studies

    rowsum.default (C)
    tapply (R: split + lapply) 
    median.default (R: sort): nth_element
    findInterval (C): binary_search, lower_bound
    cut.default?
    duplicated.data.frame (pastes rows together)
    interaction/table/plyr::id
    rank?
    rle (R, 3 copies) ?
    ifelse (R) ?
    match
    %in%
    merge
    range.default (makes copies, two passes)
    anyNA (vs any(is.NA(x)) - short circuiting)

 

## More Rcpp

This chapter has only touched on a small part of Rcpp, giving you the basic tools to rewrite poorly performing R code in C++.  Rcpp has many other capabilities that make it easy to interface R to existing C++ code, including:

* automatically creating the wrappers between R data structures and C++ data
  structures (modules).  A good introduction to this topic is the vignette of [Rcpp modules](http://dirk.eddelbuettel.com/code/rcpp/Rcpp-modules.pdf)

* mapping of C++ classes to reference classes.

I strongly recommend keeping an eye on the [Rcpp homepage](http://dirk.eddelbuettel.com/code/rcpp.html) and signing up for the [Rcpp mailing list](http://lists.r-forge.r-project.org/cgi-bin/mailman/listinfo/rcpp-devel). Rcpp is still under active development, and is getting better with every release.

## Using Rcpp in a package

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

