


# R's C interface {#c-api}

Reading R's source code is an extremely powerful technique for improving your programming skills. However, many base R functions, and many functions in older packages, are written in C. It's useful to be able to figure out how those functions work, so this chapter will introduce you to R's C API. You'll need some basic C knowledge, which you can get from a standard C text (e.g., [_The C Programming Language_](http://amzn.com/0131101633?tag=devtools-20) by Kernigan and Ritchie), or from [Rcpp](#rcpp). You'll need a little patience, but it is possible to read R's C source code, and you will learn a lot doing it. \index{C}

The contents of this chapter draw heavily from Section 5 ("System and foreign language interfaces") of [Writing R extensions](http://cran.r-project.org/doc/manuals/R-exts.html), but focus on best practices and modern tools. This means it does not cover the old `.C` interface, the old API defined in `Rdefines.h`, or rarely used language features. To see R's complete C API, look at the header file `Rinternals.h`. It's easiest to find and display this file from within R:


```r
rinternals <- file.path(R.home("include"), "Rinternals.h")
file.show(rinternals)
```

All functions are defined with either the prefix `Rf_` or `R_` but are exported without it (unless `#define R_NO_REMAP` has been used).

I do not recommend using C for writing new high-performance code. Instead write C++ with Rcpp. The Rcpp API protects you from many of the historical idiosyncracies of the R API, takes care of memory management for you, and provides many useful helper methods.

##### Outline

* [Calling C](#calling-c) shows the basics of creating and calling C functions 
  with the inline package.

* [C data structures](#c-data-structures) shows how to translate data 
  structure names from R to C. 

* [Creating and modifying vectors](#c-vectors) teaches you how to create, 
  modify, and coerce vectors in C.
  
* [Pairlists](#c-pairlists) shows you how to work with pairlists. You need
  to know this because the distinction between pairlists and list is more 
  important in C than R.

* [Input validation](#c-input-validation) talks about the importance of 
  input validation so that your C function doesn't crash R.

* [Finding the C source for a function](#c-find-source) concludes the 
  chapter by showing you how to find the C source code for internal and
  primitive R functions.

##### Prerequisites

To understand existing C code, it's useful to generate simple examples of your own that you can experiment with. To that end, all examples in this chapter use the `inline` package, which makes it extremely easy to compile and link C code to your current R session. Get it by running `install.packages("inline")`. To easily find the C code associated with internal and primitive functions, you'll need a function from pryr. Get the package with `install.packages("pryr")`.

You'll also need a C compiler. Windows users can use [Rtools](http://cran.r-project.org/bin/windows/Rtools/). Mac users will need the [Xcode command line tools](http://developer.apple.com/). Most Linux distributions will come with the necessary compilers.

In Windows, it's necessary that the Rtools executables directory (typically `C:\Rtools\bin`) and the C compiler executables directory (typically `C:\Rtools\gcc-4.6.3\bin`) are included in the Windows `PATH` environment variable. You may need to reboot Windows before R can recognise these values.

## Calling C functions from R {#calling-c}

Generally, calling a C function from R requires two pieces: a C function and an R wrapper function that uses `.Call()`. The simple function below adds two numbers together and illustrates some of the complexities of coding in C:

```c
// In C ----------------------------------------
#include <R.h>
#include <Rinternals.h>

SEXP add(SEXP a, SEXP b) {
  SEXP result = PROTECT(allocVector(REALSXP, 1));
  REAL(result)[0] = asReal(a) + asReal(b);
  UNPROTECT(1);

  return result;
}
```


```r
# In R ----------------------------------------
add <- function(a, b) {
  .Call("add", a, b)
}
```

(An alternative to using `.Call` is to use `.External`.  It is used almost identically, except that the C function will receive a single argument containing a `LISTSXP`, a pairlist from which the arguments can be extracted. This makes it possible to write functions that take a variable number of arguments. However, it's not commonly used in base R and `inline` does not currently support `.External` functions so I don't discuss it further in this chapter.) \indexc{.Call()} \indexc{.External()}

In this chapter we'll produce the two pieces in one step by using the `inline` package. This allows us to write:  \indexc{cfunction()}


```r
add <- cfunction(c(a = "integer", b = "integer"), "
  SEXP result = PROTECT(allocVector(REALSXP, 1));
  REAL(result)[0] = asReal(a) + asReal(b);
  UNPROTECT(1);

  return result;
")
add(1, 5)
#> [1] 6
```

Before we begin reading and writing C code, we need to know a little about the basic data structures.

## C data structures {#c-data-structures}

At the C-level, all R objects are stored in a common datatype, the `SEXP`, or S-expression. All R objects are S-expressions so every C function that you create must return a `SEXP` as output and take `SEXP`s as inputs. (Technically, this is a pointer to a structure with typedef `SEXPREC`.) A `SEXP` is a variant type, with subtypes for all R's data structures. The most important types are: \indexc{SEXP}

* `REALSXP`: numeric vector
* `INTSXP`: integer vector
* `LGLSXP`: logical vector
* `STRSXP`: character vector
* `VECSXP`: list
* `CLOSXP`: function (closure)
* `ENVSXP`: environment

__Beware:__ In C, lists are called `VECSXP`s not `LISTSXP`s. This is because early implementations of lists were Lisp-like linked lists, which are now known as "pairlists".

Character vectors are a little more complicated than the other atomic vectors. A `STRSXP`s contains a vector of `CHARSXP`s, where each `CHARSXP` points to C-style string stored in a global pool. This design allows individual `CHARSXP`'s to be shared between multiple character vectors, reducing memory usage. See [object size](#object-size) for more details.

There are also `SEXP`s for less common object types:

* `CPLXSXP`: complex vectors
* `LISTSXP`: "pair" lists. At the R level, you only need to care about the distinction lists and pairlists for function arguments, but internally they are used in many more places
* `DOTSXP`: '...'
* `SYMSXP`: names/symbols
* `NILSXP`: `NULL`

And `SEXP`s for internal objects, objects that are usually only created and used by C functions, not R functions:

* `LANGSXP`: language constructs
* `CHARSXP`: "scalar" strings
* `PROMSXP`: promises, lazily evaluated function arguments
* `EXPRSXP`: expressions

There's no built-in R function to easily access these names, but pryr provides `sexp_type()`:
  

```r
library(pryr)

sexp_type(10L)
#> [1] "INTSXP"
sexp_type("a")
#> [1] "STRSXP"
sexp_type(T)
#> [1] "LGLSXP"
sexp_type(list(a = 1))
#> [1] "VECSXP"
sexp_type(pairlist(a = 1))
#> [1] "LISTSXP"
```

## Creating and modifying vectors {#c-vectors}

At the heart of every C function are conversions between R data structures and C data structures. Inputs and output will always be R data structures (`SEXP`s) and you will need to convert them to C data structures in order to do any work. This section focusses on vectors because they're the type of object you're most likely to work with.

An additional complication is the garbage collector: if you don't protect every R object you create, the garbage collector will think they are unused and delete them.

### Creating vectors and garbage collection

The simplest way to create a new R-level object is to use `allocVector()`. It takes two arguments, the type of `SEXP` (or `SEXPTYPE`) to create, and the length of the vector. The following code creates a three element list containing a logical vector, a numeric vector, and an integer vector, all of length four: \indexc{PROTECT()}


```r
dummy <- cfunction(body = '
  SEXP dbls = PROTECT(allocVector(REALSXP, 4));
  SEXP lgls = PROTECT(allocVector(LGLSXP, 4));
  SEXP ints = PROTECT(allocVector(INTSXP, 4));

  SEXP vec = PROTECT(allocVector(VECSXP, 3));
  SET_VECTOR_ELT(vec, 0, dbls);
  SET_VECTOR_ELT(vec, 1, lgls);
  SET_VECTOR_ELT(vec, 2, ints);

  UNPROTECT(4);
  return vec;
')
dummy()
#> [[1]]
#> [1] 6.93e-310 6.93e-310 6.93e-310 6.93e-310
#> 
#> [[2]]
#> [1] TRUE TRUE TRUE TRUE
#> 
#> [[3]]
#> [1] 1952805488 1650424180 1801545074      12659
```

You might wonder what all the `PROTECT()` calls do. They tell R that the object is in use and shouldn't be deleted if the garbage collector is activated. (We don't need to protect objects that R already knows we're using, like function arguments.)

You also need to make sure that every protected object is unprotected. `UNPROTECT()` takes a single integer argument, `n`, and unprotects the last n objects that were protected. The number of protects and unprotects must match. If not, R will warn about a "stack imbalance in .Call".  Other specialised forms of protection are needed in some circumstances: 

* `UNPROTECT_PTR()` unprotects the object pointed to by the `SEXP`s. 

* `PROTECT_WITH_INDEX()` saves an index of the protection location that can 
  be used to replace the protected value using `REPROTECT()`. 
  
Consult the R externals section on [garbage collection](http://cran.r-project.org/doc/manuals/R-exts.html#Garbage-Collection) for more details.

Properly protecting the R objects you allocate is extremely important! Improper protection leads to difficulty diagnosing errors, typically segfaults, but other corruption is possible as well. In general, if you allocate a new R object, you must `PROTECT` it.

If you run `dummy()` a few times, you'll notice the output varies. This is because `allocVector()` assigns memory to each output, but it doesn't clean it out first. For real functions, you may want to loop through each element in the vector and set it to a constant. The most efficient way to do that is to use `memset()`:


```r
zeroes <- cfunction(c(n_ = "integer"), '
  int n = asInteger(n_);

  SEXP out = PROTECT(allocVector(INTSXP, n));
  memset(INTEGER(out), 0, n * sizeof(int));
  UNPROTECT(1);

  return out;
')
zeroes(10);
#>  [1] 0 0 0 0 0 0 0 0 0 0
```

### Missing and non-finite values

Each atomic vector has a special constant for getting or setting missing values:

* `INTSXP`: `NA_INTEGER`
* `LGLSXP`: `NA_LOGICAL`
* `STRSXP`: `NA_STRING`
  
Missing values are somewhat more complicated for `REALSXP` because there is an existing protocol for missing values defined by the floating point standard ([IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point)). In doubles, an `NA` is `NaN` with a special bit pattern (the lowest word is 1954, the year Ross Ihaka was born), and there are other special values for positive and negative infinity. Use `ISNA()`, `ISNAN()`, and `!R_FINITE()` macros to check for missing, NaN, or non-finite values. Use the constants `NA_REAL`, `R_NaN`, `R_PosInf`, and `R_NegInf` to set those values. \index{missing values!in C}

We can use this knowledge to make a simple version of `is.NA()`:


```r
is_na <- cfunction(c(x = "ANY"), '
  int n = length(x);

  SEXP out = PROTECT(allocVector(LGLSXP, n));

  for (int i = 0; i < n; i++) {
    switch(TYPEOF(x)) {
      case LGLSXP:
        LOGICAL(out)[i] = (LOGICAL(x)[i] == NA_LOGICAL);
        break;
      case INTSXP:
        LOGICAL(out)[i] = (INTEGER(x)[i] == NA_INTEGER);
        break;
      case REALSXP:
        LOGICAL(out)[i] = ISNA(REAL(x)[i]);
        break;
      case STRSXP:
        LOGICAL(out)[i] = (STRING_ELT(x, i) == NA_STRING);
        break;
      default:
        LOGICAL(out)[i] = NA_LOGICAL;
    }
  }
  UNPROTECT(1);

  return out;
')
is_na(c(NA, 1L))
#> [1]  TRUE FALSE
is_na(c(NA, 1))
#> [1]  TRUE FALSE
is_na(c(NA, "a"))
#> [1]  TRUE FALSE
is_na(c(NA, TRUE))
#> [1]  TRUE FALSE
```

Note that `base::is.na()` returns `TRUE` for both `NA` and `NaN`s in a numeric vector, as opposed to the C `ISNA()` macro, which returns `TRUE` only for `NA_REAL`s.

### Accessing vector data

There is a helper function for each atomic vector that allows you to access the C array which stores the data in a vector. Use `REAL()`, `INTEGER()`, `LOGICAL()`, `COMPLEX()`, and `RAW()` to access the C array inside numeric, integer, logical, complex, and raw vectors. The following example shows how to use `REAL()` to inspect and modify a numeric vector: \index{vectors!in C}


```r
add_one <- cfunction(c(x = "numeric"), "
  int n = length(x);
  SEXP out = PROTECT(allocVector(REALSXP, n));
  
  for (int i = 0; i < n; i++) {
    REAL(out)[i] = REAL(x)[i] + 1;
  }
  UNPROTECT(1);

  return out;
")
add_one(as.numeric(1:10))
#>  [1]  2  3  4  5  6  7  8  9 10 11
```

When working with longer vectors, there's a performance advantage to using the helper function once and saving the result in a pointer:































