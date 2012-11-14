# High performance functions with Rcpp

Sometimes R code just isn't fast enough - you've used profiling to find the bottleneck, but there's simply no way to make the code any faster. This chapter is the answer to that problem: use Rcpp to easily write key functions in C++ to get high-performance functions that only take slightly longer to write than their R requivalents. [Rcpp](http://dirk.eddelbuettel.com/code/rcpp.html) is a fantastic tool written by Dirk Eddelbuettel, Romain Francois, Doug Bates, John Chambers and JJ Allaire that makes it dead simple to write high-performance R code in C++.

It is possible to write high performance code in C or Fortran. This may (or may not) be produce faster code, but it will almost certainly take you much much longer to write.  Without Rcpp, you must sacrifice a lot of very helpful wrappers and master the complex C internals of R yourself. In my opinion, using Rcpp is currently the best balance between speed and convenience.

The basic strategy is to keep as much code as possible in R, because:

* you are probably more familiar with R than C++

* people reading/maintaining your code in the future will probably be more familiar with R than C++

Implementing bottlenecks in C++ can give considerable speed ups (2-3 orders of magnitude) and allows you to easily access best-of-breed data structures.  Keeping the majority of your code in straight R, means that you don't have to sacrifice R's rapid development and huge library of statistical functions.  

Typical bottlenecks involve:

 * loops that can't easily be vectorised because each iteration depends on the previous: this is because C++ modifies in place by default, so there is little overhead for modifying a data structure many many times.
 
 * functions that are most elegantly expressed recursively: the overhead of calling a function in C++ is much much lower than the overhead of all a function in R.  (It's often possible to rewrite recursive functions in a iterative way, but that may muddy their intent).
 
 * problems that advanced data structures and algorithms that R doesn't provide.

The aim of this chapter is to give you the absolute basics to get up and running with Rcpp for the purpose of speeding up slow parts of your code. You'll lean the essence of C++ by seeing how simple R functions are converted to their C++ equivalents. 

## Getting started with Rcpp

All examples in this chapter need at least version 0.10 of the `Rcpp` package. This version includes `cppFunction`, which makes it easier than ever to connect C++ to R. You'll also (obviously) need a working C++ compiler.  

If you're familiar with `inline::cfunction`, `cppFunction` is similarly, except that you specifcy the function completely in the string, and it parses the C++ function arguments to figure out what the R function arguments should be:

    cppFunction('
      int fib(const int x) {
        if (x == 0) return(0); 
        if (x == 1) return(1);
        return fib(x - 1) + fib(x - 2);
      }'
    )
    formals(fib)

As well compiling C++ code inline, you can also create whole files of C++ code and load them with `sourceCpp`, and you can easily include C++ in a package.  Both of these uses are described at the end of the package.  While using `cppFunction` is easiest when exploring new code (and in tutorials like this), when you're actually developing code it's easier to set up a src directory and use `devtools::load_all` to automatically reload and recompile your code.

## Getting starting with C++

C++ is a large language, and there's no way to cover it exhaustively here.  Our aim is to give you the basics so that you can start writing fast code. We we'll spend minimal time on object oriented C++ and on templating, because our focus is not on writing big programs in C++, just single, self-contained functions that allow you to speed up slow parts of your R code.  

<!-- We'll focus on C++ 11 (the C++ standard written in 2011, formerly known as C++0x (as it was supposed be finished by 2009))
 -->

In the following section we'll compare and contrast basic R functions with their C++ equivalents. Let's start with a very simple function. It has no arguments and always returns the the integer 1:

    one <- function() 1L

The equivalent C++ function is: 

    int one() {
      return(1);
    }

We can compile and use this from R with `cppFunction`

    cppFunction('
      int one() {
        return(1);
      }
    ')

This small function illustrates a number of important differences between R and C++:

* In C++ the syntax to create a function looks like the syntax to call a function: `one() {...}`.  We don't use assignment to create functions.

* We must declare the type of output the function returns. This function returns an `int` (a scalar integer). The classes for the most common types of R vectors are: `NumericVector`, `IntegerVector`, `CharacterVector` and `LogicalVector`.

* C++ distinguishes between scalars and vectors. The scalar equivalents of numeric, integer, character and logical vectors are: `double`, `int`, `std::string` and `bool`.

* We must use an explicit `return` statement 

* Every statement is terminated by a `;`.

The next example function makes things a little more complicated

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
      int sign2(int x) {
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

One big difference between R and C++ is that the cost of loops is much lower.  For example, we could implement the `sum` function in R using a loop: but if you've been programming in R a while this will look pretty strange. 

    sum1 <- function(x) {
      total <- 0;
      for (i in seq_along(x)) {
        total <- total + x[i]
      }
      total
    }

    cppFunction('
      double sum2(NumericVector x) {
        int n = x.size();
        double total = 0;
        for(int i = 0; i < n; i++) {
          total =+ x[i];
        }
        return(total);
      }
    ')

The C++ version is similar, but:

* The `for` statement has a different syntax: `for(intialise; condition; increase)`.

* Vectors in C++ start at 0. I'll say this again because it's so important: VECTORS IN C++ START AT 0! Forgetting that is probably the most common source of bugs when converting R functions to C++.

* We can take advantage of the in-place modification operator `total =+ x[i]` which is equivalent to `total = total + x[i]`.  Similar in-place operators are `=-`, `=*` and `=/`.  

This is a good example of where C++ is much more efficient than the R equivalent: our `sum2` function is competitive with the built-in (and highly optimised) `sum` function, while `sum1` is several orders of magnitude slower.

    library(microbenchmark)
    x <- runif(1e3)
    microbenchmark(
      sum(x),
      sum1(x),
      sum2(x)
    )

<!-- 
* for loops
* 0-based indices

* initialising scalars
* initialising vectors

* `pow` instead of `^`
 -->


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

As well as classes for many more specialised language objects: `ComplexVector`, `RawVector`, `DottedPair`, `Language`,  `Promise`, `Symbol`, `WeakReference` and so on. These are beyond the scope of this document and won't be discussed further.

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

## Learning more

Writing performant code may also require you to rethink your basic approach: a solid understand of basic data structures and algorithms is very helpful here.  That's beyond the scope of this book, but I'd suggest the "algorithm design handbook" as a good place to start.  Or http://ocw.mit.edu/courses/electrical-engineering-and-computer-science/6-046j-introduction-to-algorithms-sma-5503-fall-2005/


