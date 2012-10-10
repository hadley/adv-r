# R-C interface

This is a opinionated re-write of section 5 ("System and foreign language interfaces") of [Writing R extensions](http://cran.r-project.org/doc/manuals/R-exts.html), focussing on best practices and modern tools. This means it does not cover:

* the `.C` interface
* the old api defined in `Rdefines.h`
* many esoteric language features that are rarely used

It focusses mainly on section 5.9, "Handling R objects in C", considerably expanding it, and providing many more examples. The main point of the guide is to help you read and understand R's C source code. It will also help you write your own C functions, but for anything more than the simplest function, we recommend using C++ and Rcpp.

All examples in this chapter use the `inline` package - this makes it extremely easy to get up and running with C code. Make sure you have it installed and loaded with the following code:

    install.packages("inline")
    library(inline)

You'll also (obviously) need a working C compiler.  The final section of this chapter shows you how to turn C functions you've created with inline into a package C code.

## Calling C functions from R

Generally, calling C functions from R involves two parts: a c function, and an R function that uses `.Call`. The simple function below adds two numbers together and illustrates some of the important features of coding in C (creating new R vectors, coercing input arguments to the appropriate type and dealing with garbage collection).  

    # In R ----------------------------------------
    add <- function(a, b) {
      .Call("add", a, b)
    }

    # In C ----------------------------------------
    #include <R.h>
    #include <Rinternals.h>

    SEXP add(SEXP a, SEXP b) {
      SEXP result;

      PROTECT(result = allocVector(REALSXP, 1));
      REAL(result)[0] = asReal(a) + asReal(b);
      UNPROTECT(1);

      return(result);
    }

In this chapter we'll produce these two pieces in one step by using the `inline` package. This allows us to write:

    add <- cfunction(signature(a = "integer", b = "integer"), "
      SEXP result;

      PROTECT(result = allocVector(REALSXP, 1));
      REAL(result)[0] = asReal(a) + asReal(b);
      UNPROTECT(1);

      return(result);
    ")
    add(1, 5)

The rest of this chapter explains in more detail how these (and other important functions) work.  The C functions and macros that R provides for us to modify R data structures are all defined in the header file `Rinternals.h`.  It's easiest to find and display this file from within R:

    rinternals <- file.path(R.home(), "include", "Rinternals.h")
    file.show(rinternals)

Before we begin writing and reading C code, we need to know a little about the basic data structures.

## Basic data structures

At the C-level, all R objects are stored in a common datatype, the `SEXP`. (Technically, this is a pointer to a structure with typedef `SEXPREC`). A `SEXP` is a variant type, with subtypes for all of the common R data structures. The most important types are:

* `REALSXP`: numeric vector
* `INTSXP`: integer vector
* `LGLSXP`: logical vector
* `STRSXP`: character vector
* `VECSXP`: a list
* `CLOSXP`: a function or function closure
* `ENVSXP`: a environment
* `NILSXP`: `NULL`

__Beware:__ At the C level, R's lists are `VECSXP`s not `LISTSXP`s. This is because early implementations of R used LISP-like linked lists (now known as "pairlists") before moving to the S-like generic vectors that we now know as lists.

There are also `SEXP`s for less used object types:

* `CPLXSXP`: complex vectors
* `LISTSXP`: a "pair" list, in R used only for function arguments
* `DOTSXP`: a object used to reprsent '...'
* `SYMSXP`: name/symbol

And `SEXP`s for internal objects, objects that are usually only created and used by C functions, not R functions:

* `LANGSXP`: language constructs
* `CHARSXP`: "scalar" string type
* `PROMSXP`: promises, lazily evaluated function arguments
* `EXPRSXP`: expressions

### Character vectors

R character vectors are stored as `STRSXP`s, a vector type like `VECSXP`
where every element is of type `CHARSXP`. `CHARSXP`s are read-only objects and must never be modified. In particular, the C-style string contained in a `CHARSXP` should be treated as read-only; and it's hard to do otherwise because the `CHAR` accessor function returns a `const char*`.

Strings have this more complicated design because individual `CHARSXP`'s (elements of a character vector) can be shared between multiple strings. This is an optimisation to reduce memory usage, and can result in unexpected behaviour:

      x <- "banana"
      y <- rep(x, 1e6)
      object.size(x)
      # 64 bytes
      object.size(y) / 1e6
      # 4.000056 bytes

(This is also the reason why factors are no more memory efficient than strings. `factor(y)` is actually slightly bigger than `factor(x)`)

## Coercion and object creation

At the heart of every C function will be a set of conversions between R data structures and C data structures. Inputs will always be as R data structures (`SEXP`s) and you will need to convert them to C data structures in order to operate on then. The output also must be a R data structure, so you'll need to be able to convert C data structures to their R equivalents.

An additional complication is the garbage collection: if you don't claim it, the garbage collector will think the R objects that you create are unused and delete them.

Generally, it's a good idea to write a wrapper function that checks arguments are of the correct type, and coerces them as necessary.  It easier to do this at the R level, because `as.numeric` will use S3 dispatch, whereas the C-level equivalent described below will not.

### Extracting C vectors

There is a helper function for each atomic vector (apart from character) that allows you to index to a `SEXP` and access the regular C-level data structure that lives at its heart.  The following example shows how to use the helper function `REAL` to get values from and set values in a numeric vector:

    add_one <- cfunction(c(x = "numeric"), "
      SEXP out;
      int n = length(x);

      PROTECT(out = allocVector(REALSXP, n));
      for (int i = 0; i < n; i++) {
        REAL(out)[i] = REAL(x)[i] + 1;
      }
      UNPROTECT(1);

      return(out);
    ")
    add_one(as.numeric(1:10))

There are similar helpers for logical vectors, `LOGICAL(x)`, integer vectors, `INTEGER(x)`, complex vectors `COMPLEX(x)` and raw vectors `RAW(x)`. If you're working with long vectors, there's a performance advantage to using the helper function once and saving it as a pointer:

    add_two <- cfunction(c(x = "numeric"), "
      SEXP out;
      int n = length(x);
      double *px, *pout;

      PROTECT(out = allocVector(REALSXP, n));

      px = REAL(x);
      pout = REAL(out);
      for (int i = 0; i < n; i++) {
        pout[i] = px[i] + 2;
      }
      UNPROTECT(1);

      return(out);
    ")
    add_two(as.numeric(1:10))

    library(microbenchmark)
    x <- as.numeric(1:1e6)
    microbenchmark(
      add_one(x),
      add_two(x)
    )

On my computer, `add_two` is about twice as fast as `add_one` for a million element vector.  This is a common idiom in the R source code.

Strings and lists are more complicated because the individual elements are `SEXP`s not C-level data structures. You can use `STRING_ELT(x, i)` and `VECTOR_ELT(x, i)` to extract individual components.  To get a single C string from a element in a R character vector, use `CHAR(STRING_ELT(x, i))`. Setting values is done with `SET_STRING_ELT`.

### Coercion to C scalars

There are also a few helper functions if just want a scalar C value:

* `asLogical(x)`, `INTSXP -> int`
* `asInteger(x)`, `INTSXP -> int`
* `asReal(x)`, `REALSXP -> double`
* `asComplex(x)`, `CPLXSXP -> Rcomplex`
* `CHAR(asChar(x))`, `STRSXP -> const char*`

### Object creation and garbage collection

The simplest way to create an new R datastructure is `allocVector`, which takes two arguments, the `SEXP` to create, and the length of the vector.  For example, the following code code creates a list containing a logical vector, a numeric vector and an integer vector:

    dummy <- cfunction(body = '
      SEXP vec, real, lgl, ints;

      PROTECT(real = allocVector(REALSXP, 2));
      REAL(real)[0] = 10;
      REAL(real)[1] = 100;

      PROTECT(lgl = allocVector(LGLSXP, 10));

      PROTECT(ints = allocVector(INTSXP, 10));

      PROTECT(vec = allocVector(VECSXP, 3));
      SET_VECTOR_ELT(vec, 0, real);
      SET_VECTOR_ELT(vec, 1, lgl);
      SET_VECTOR_ELT(vec, 2, ints);

      UNPROTECT(4);
      return(vec);
    ')
    dummy()

You might wonder what all the `PROTECT` calls do. They tell R that we're currently using the object, and not to delete if the garbage collector is activated. Protection is not needed for objects that R already knows are in use, like function arguments. This is also protects all objects pointed to in the corresponding `SEXPREC`, for example all elements of a protected list are automatically protected.

You are responsible for making sure that every protected object is unprotected. `UNPROTECT` takes a single integer argument, n, and unprotects the last n objects that were protected. If your calls don't match, R will warn about "stack imbalance in .Call".

Other specialised forms of `PROTECT` and `UNPROTECT` are needed in some circumstances: `UNPROTECT_PTR(`s`)` unprotects the
object pointed to by the `SEXP` s, `PROTECT_WITH_INDEX` saves an index of the protection location that can be used to replace the protected value using `REPROTECT`.  Consult R externals for more details.

If you run `dummy()` a few times, you'll notice the output is basically random. This is because `allocVector` assigns memory to each output, but it doesn't clean it out first.

### Creating R scalars

Convenience functions for creating a single element:

* `ScalarLogical(int x)`
* `ScalarInteger(int x)`
* `ScalarReal(double x)`
* `ScalarComplex(Rcomplex x); Rcomplex cmp = {0.1, 0.2};`
* `ScalarRaw(Rbyte x)`
* `mkString("mystring")`

### Creating new strings

* `mkString("mystring")`
* `mkChar("mystring")`

### Helper functions

allocVector(SEXPTYPE type, R_xlen_t length)
allocMatrix(SEXPTYPE mode, int nrow, int ncol)
alloc3DArray(SEXPTYPE mode, int nrow, int ncol, int nface)
allocArray(SEXPTYPE mode, SEXP dims)
allocList(int n)
mkNamed: to create `list(xi=, yi=, zi=)`

        const char *nms[] = {"xi", "yi", "zi", ""};
        mkNamed(VECSXP, nms);

### Coercing vectors 

Coercing to R objects:

* coerceVector  .  This will return an error if the `SEXP` can not be converted to the desired type.

You will always need to run `coerceVector` inside `PROTECT`, as described in the garbage collection section below.


If storage is required for C objects during the calculations this is
best allocating by calling `R_alloc`; see [Memory
allocation](http://cran.r-project.org/doc/manuals/R-exts.html#Memory-allocation).
All of these memory allocation routines do their own error-checking, so
the programmer may assume that they will raise an error if the memory cannot be allocated.


## Symbols and attributes

To create a symbol (the equivalent of `as.symbol` or `as.name` in R), use `install`.  Symbols are used in more places when working at the C-level.  For example, to get or set attributes, you need to use a symbol:

    SEXP set_attr(obj, SEXP attr, SEXP value) {
      duplicate(obj);
      setAttrib(obj, install(attr), value);
      return(obj)
    }

(We'll talk about why the duplicated is need in the modifying inputs section)The converse to `setAttrib` is `getAttrib`.  

Some commonly used symbols are available without the use of `install`:

* `R_ClassSymbol`: class
* `R_DimNamesSymbol`: dimnames
* `R_DimSymbol`: dim
* `R_NamesSymbol`: names
* `R_LevelsSymbol`: levels

There are some (confusingly named) shortcuts for common setting operations: `classgets`, `namesgets`, `dimgets` and `dimnamesgets` are the internal versions of the default methods of `class<-`, `names<-`, `dim<-` and `dimnames<-`.

## Missing and non-finite values

R's `NA` is a subtype of `NaN` so IEC60559 arithmetic will handle them
correctly.  However, it is unwise to depend on such details, and is better to deal with missings explicitly.

* In doubles, use the `ISNA` macro, `ISNAN`, or `R_FINITE` macros to check for missing, NaN or non-finite values.  Use the constants `NA_REAL`, `R_NaN`, `R_PosInf` and `R_NegInf` to set those values

* Integers, compare to and set with `NA_INTEGER`
* Logicals, compare to and set with `NA_LOGICAL`
* String, compare to and set with `NA_STRING`

## Checking types

`TYPEOF` returns the `SEXPTYPE` of the incoming SEXP:

      is_numeric <- cfunction(c("x" = "ANY"), "
        return(ScalarLogical(TYPEOF(x) == REALSXP));
      ")
      is_numeric(7)
      is_numeric("a")

(Here we have to use `ScalarLogical` to convert the result of the C comparison, an integer, in an R data structure, a logical vector of length 1).

These all return 0 for FALSE and 1 for TRUE.

Atomic vectors:

* isInteger: an integer vector (that isn't a factor)
* isReal
* isComplex
* isLogical
* isString
* isNumeric: integer, logical, real
* isNumber: numeric + complex numbers
* isVectorAtomic: atomic vectors (logical, interger, numeric, complex, string, raw)

* isArray: vector with dimension attribute
* isMatrix: vector with dimension attribute of length 2

* isEnvironment
* isExpression
* isFactor: 
* isFunction: function: a closure, a primitive, or an internal function
* isList: __pair__list?
* isNewList: list
* isSymbol
* isNull
* isObject
* isVector: atomic vectors + lists and expressions

Note that some of these functions behave differently to the R-level functions with similar names. For example `isVector` is true for any atomic vector type, lists and expression, where `is.vector` is returns `TRUE` only if its input has no attributes apart from names.

## Modifying objects

### Modifying inputs

When assignments are done in R such as

   x <- 1:10
   y <- x

the named object is not necessarily copied, so after those two
assignments `y` and `x` are bound to the same `SEXPREC` (the structure a
`SEXP` points to). This means that any code which alters one of them has
to make a copy before modifying the copy if the usual R semantics are to
apply. Note that whereas `.C` and `.Fortran` do copy their arguments
(unless the dangerous `dup = FALSE` is used), `.Call` and `.External` do
not. So `duplicate` is commonly called on arguments to `.Call` before
modifying them.

However, at least some of this copying is unneeded. In the first
assignment shown, `x <- 1:10`, R first creates an object with value
`1:10` and then assigns it to `x` but if `x` is modified no copy is
necessary as the temporary object with value `1:10` cannot be referred
to again. R distinguishes between named and unnamed objects *via* a
field in a `SEXPREC` that can be accessed *via* the macros `NAMED` and
`SET_NAMED`. This can take values

* `0`:  The object is not bound to any symbol
* `1`:  The object has been bound to exactly one symbol
* `2`:  The object has potentially been bound to two or more symbols, and
 one should act as if another variable is currently bound to this
 value.

Note the past tenses: R does not do full reference counting and there
may currently be fewer bindings.

Currently all arguments to a `.Call` call will have `NAMED` set to 2,
and so users must assume that they need to be `duplicate()`d before
alteration.

### Lists

List elements can be retrieved or set by direct access to the elements
of the generic vector. Suppose we have a list object

   a <- list(f = 1, g = 2, h = 3)

Then we can access `a$g` as `a[[2]]` by

    double g;
      ....
    g = REAL(VECTOR_ELT(a, 1))[0];

This can rapidly become tedious, and the function like the following is very useful:

    SEXP getListElement(SEXP list, const char *str) {
      SEXP elmt = R_NilValue;
      SEXP names = getAttrib(list, R_NamesSymbol);

      for (R_len_t i = 0; i < length(list); i++) {
        if (strcmp(CHAR(STRING_ELT(names, i)), str) == 0) {
          elmt = VECTOR_ELT(list, i);
          break;
        }
      }
      return elmt;
    }

and enables us to say

     double g;
     g = REAL(getListElement(a, "g"))[0];


### Pairlists and language objects

There are a series of small macros/functions to help construct pairlists
and language objects (whose internal structures just differ by
`SEXPTYPE`). Function `CONS(u, v)` is the basic building block: is
constructs a pairlist from `u` followed by `v` (which is a pairlist or
`R_NilValue`). `LCONS` is a variant that constructs a language object.

Functions `list1` to `list5` construct a pairlist from one to five
items, and `lang1` to `lang6` do the same for a language object (a
function to call plus zero to five arguments). 

Functions `elt` and `lastElt` find the ith element and the last element of a pairlist, and `nthcdr` returns a pointer to the nth position in the pairlist (whose `CAR` is the nth item).

## `.External`

An alternative to using `.Call` is to use `.External`.  It is used almost identically, except that the C function will recieve a single arugment containing a `LISTSXP`, a pairlist from which the
arguments can be extracted.  For example, if we used `.External`, the add function would become.

## Finding the C source code for a function

`.Primitive`

`.Internal`


## Using C code in a package

The easiest way to get up and running with compiled C code is to use devtools.  You'll need to put your code in a package structure, which means:

* R files in a `R/` directory
* C files in `src/` directory
* A `DESCRIPTION` in the main directory
* A `NAMESPACE` file containing `useDynLib(packagename)`

Then running `load_all` will automatically compile and reload the code in your package.

