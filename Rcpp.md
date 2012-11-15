# High performance functions with Rcpp

Sometimes R code just isn't fast enough - you've used profiling to find the bottleneck, but there's simply no way to make the code any faster. This chapter is the answer to that problem: use Rcpp to easily write key functions in C++ to get high-performance functions that only take slightly longer to write than their R requivalents. [Rcpp](http://dirk.eddelbuettel.com/code/rcpp.html) is a fantastic tool written by Dirk Eddelbuettel, Romain Francois, Doug Bates, John Chambers and JJ Allaire that makes it dead simple to write high-performance R code in C++.

It is possible to write high performance code in C or Fortran. This may (or may not) be produce faster code, but it will almost certainly take you much much longer to write.  Without Rcpp, you must sacrifice a lot of very helpful wrappers and master the complex C internals of R yourself. In my opinion, using Rcpp is currently the best balance between speed and convenience.

The basic strategy is to keep as much code as possible in R, because:

* you are probably more familiar with R than C++

* people reading/maintaining your code in the future will probably be more familiar with R than C++

Implementing bottlenecks in C++ can give considerable speed ups (2-3 orders of magnitude) and allows you to easily access best-of-breed data structures.  Keeping the majority of your code in straight R, means that you don't have to sacrifice R's rapid development and huge library of statistical functions.  Note, however, that many functions that would be bottlenecks if implemented in pure R have already been turned into hand-rolled C. To write functions in C++ that are faster than these often takes some tuning and performance tricks.  That's not the aim of this chapter - often the naive approach will get you within 20% of the running time of the base R function.  If you need more performance, you'll need to consult other sources (some of which are described in the final section of this chapter).

Typical bottlenecks involve:

 * loops that can't easily be vectorised because each iteration depends on the previous: this is because C++ modifies in place by default, so there is little overhead for modifying a data structure many many times.
 
 * functions that are most elegantly expressed recursively: the overhead of calling a function in C++ is much much lower than the overhead of all a function in R.  (It's often possible to rewrite recursive functions in a iterative way, but that may muddy their intent).
 
 * problems that advanced data structures and algorithms that R doesn't provide.

The aim of this chapter is to give you the absolute basics to get up and running with Rcpp for the purpose of speeding up slow parts of your code. You'll lean the essence of C++ by seeing how simple R functions are converted to their C++ equivalents. 

## Getting started with Rcpp

All examples in this chapter need at least version 0.10 of the `Rcpp` package. This version includes `cppFunction`, which makes it very easy to connect C++ to R. You'll also (obviously) need a working C++ compiler.  

If you're familiar with `inline::cfunction`, `cppFunction` is similarly, except that you specifcy the function completely in the string, and it parses the C++ function arguments to figure out what the R function arguments should be:

    cppFunction('
      int add(int x, int y, int z) {
        int sum = x + y + z;
        return(sum);
      }'
    )
    formals(add)

As well compiling C++ code inline, you can also create whole files of C++ code and load them with `sourceCpp`, and you can easily include C++ code in a package.  Both of these uses are described at the end of the chapter.  While using `cppFunction` is easiest when exploring new code (and in tutorials like this), when you're actually developing code it's easier to set up a src directory and use `devtools::load_all` (or similar tools) to automatically reload and recompile your code.

## Getting starting with C++

C++ is a large language, and there's no way to cover it exhaustively here.  Our aim is to give you the basics so that you can start writing useful functions in C++. We we'll spend minimal time on object oriented C++ and on templating, because our focus is not on writing big programs in C++, just small, mostly self-contained functions that allow you to speed up slow parts of your R code.  

### No inputs, scalar output

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

### Scalar input, scalar output

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

* we need to declare the type of each of the function's inputs, in the same way we need to declare the type of output it produces

* the `if` syntax is identical - while there are some big differences between R and C++, there are also lots of similarities!  C++ also has a `while` statement that works the same way as R's.  You can also use `break`, but instead of R's `next`, C++ has `continue`.

### Vector input, scalar output

One big difference between R and C++ is that the cost of loops is much lower.  For example, we could implement the `sum` function in R using a loop. If you've been programming in R a while, you'll probably have a visceral reaction to this function: why aren't I using an internal vectorise function?!

    sum1 <- function(x) {
      total <- 0;
      for (i in seq_along(x)) {
        total <- total + x[i]
      }
      total
    }

In C++, for loops have very little overhead, so it's fine to use them (although as we'll see later, like in R, there are better alternatives that more clearly express your intent).

    cppFunction('
      double sum2(NumericVector x) {
        int n = x.length();
        double total = 0;
        for(int i = 0; i < n; ++i) {
          total += x[i];
        }
        return(total);
      }
    ')

The C++ version is similar, but:

* To find the length of the vector, we use the `length()` method, which returns an integer. Again, whenever we create a new variable we have to tell C++ what type of object it will hold. An int is a scalar integer, but we could have used double for a scalar numeric, bool for a scalar logical, or a std::string for a scalar character vector.

* The `for` statement has a different syntax: `for(intialise; condition; increase)`. The initialise component creates a new variable called `i` and sets it equal to 0. The condition is checked in each iteration of the loop: the loop is completed when it becomes false. The increase statement is run after each loop iteration (but before the condition is checked). Here we use the special prefix operator `++` which increases the value of `i` by 1.

* Vectors in C++ start at 0. I'll say this again because it's so important: VECTORS IN C++ START AT 0! Forgetting that is probably the most common source of bugs when converting R functions to C++.

* We can't use `<-` (or `->`) for assignment, but instead use `=`.

* We can take advantage of the in-place modification operator `total += x[i]` which is equivalent to `total = total + x[i]`.  Similar in-place operators are `-=`, `*=` and `/=`.  

This is a good example of where C++ is much more efficient than the R equivalent: our `sum2` function is competitive with the built-in (and highly optimised) `sum` function, while `sum1` is several orders of magnitude slower.

    library(microbenchmark)
    x <- runif(1e3)
    microbenchmark(
      sum(x),
      sum1(x),
      sum2(x)
    )

It's possible to make our version of sum even faster if we use some tricks, but those are beyond the scope of this book.

### Vector input, vector output

For our next example, we'll create a function that computes the distance between one value and a vector of other values:

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
        return(out);
      }
    ')

This function introduces only a few new concepts:

* We create a new `NumericVector` and say how long it should be using a constructor function: `out(n)`.

* Finally, C++ doesn't have the `^` operator for exponentiation, it instead has the `pow` function

Note that this function is not only much more verbose than R equivalent, it's unlikely to be much faster - the R version will be very fast because it uses vectorised primitives. These very quickly turn into C loops.  However, our C++ function does have one advantage - it will use less memory, because `pdist1` needs two vectors the same length as y (`z <- x - ys`, and `z ^ 2`)

    ys <- runif(1e5)
    all.equal(pdist1(0.5, ys), pdist2(0.5, ys))

    library(microbenchmark)
    microbenchmark(
      pdist1(0.5, ys),
      pdist2(0.5, ys)
    )

### Exercises

With the basics of C++ in hand, now is a great time to practice by writing some simple C++ functions.  

Convert the following functions into C++

* `diff`. Start by assuming lag 1, and then generalise for lag n.

* `range`.  Start by assuming that the input has no missing values, then generalise to include a `na.rm` parameter. If `TRUE` your function should ignore missing values (does it need to do anything special?), if `FALSE` it should return two missing values the first time it sees a missing value.

* `var` or `sd`

## Rcpp

### Important classes

* NumericVector
* CharacterVector
* IntegerVector
* LogicalVector

You can also use standard C++ variable types for scalars: `int`, `double`, `bool`, `std::string`.  

* Important methods: `length`, `fill`, `begin`, `end`, etc.
* Naming vectors `names()`
* Attributes `attr()`

* Matrices

* List
* DataFrame
* Environment

As well as classes for many more specialised language objects: `ComplexVector`, `RawVector`, `DottedPair`, `Language`,  `Promise`, `Symbol`, `WeakReference` and so on. These are beyond the scope of this document and won't be discussed further.

* lists and data frames, named vectors
* functions

### Calling R functions

### Variable arguments

Not easily supported - instead put the arguments in a list.

## Missing values

If you're working with missing values, you need to know two things:

* what happens when you put missing values in scalars (e.g. `double`)
* how to get and set missing values in vectors (e.g. `NumericVector`)

### Scalars

The following code explores what happens when you coerce the first element of a vector into the corresponding scalar:

    cppFunction('int first_int(IntegerVector x) {
      return(x[0]);
    }')
    cppFunction('double first_num(NumericVector x) {
      return(x[0]);
    }')
    cppFunction('std::string first_char(CharacterVector x) {
      return((std::string) x[0]);
    }')
    cppFunction('bool first_log(LogicalVector x) {
      return(x[0]);
    }')

    first_log(NA)
    first_int(NA_integer_)
    first_num(NA_real_)
    first_char(NA_character_)

So

* `NumericVector` -> `double`: NAN

* `IntegerVector` -> `int`: NAN (not sure how this works given that integer types don't usually have a missing value)

* `CharacterVector` -> `std::string`: the string "NA"

* `LogicalVector` -> `bool`: TRUE

If you're working with doubles, depending on your problem, you may be able to get away with ignoring missing values and working with NaNs. R's missing values are a special type of the IEEE 754 floating point number NaN (not a number). That means if you coerce them to `double` or `int` in your C++ code, they will behave like regular NaN's. 

In a logical context they always evaluate to FALSE:

    evalCpp("NAN == 1")
    evalCpp("NAN < 1")
    evalCpp("NAN > 1")
    evalCpp("NAN == NAN")
    
But be careful when combining then with boolean values:

    evalCpp("NAN && TRUE")
    evalCpp("NAN || FALSE")

In numeric contexts, they propagate similarly to NA in R:

    evalCpp("NAN + 1")
    evalCpp("NAN - 1")
    evalCpp("NAN / 1")
    evalCpp("NAN * 1")

### Vectors

To set a missing value in a vector, you need to use a missing value specific to the type of vector. Unfortunately these are not named terribly consistently:

    cppFunction('
      List missing_sampler() {

        NumericVector num(1);
        num[0] = NA_REAL;

        IntegerVector intv(1);
        intv[0] = NA_INTEGER;

        LogicalVector lgl(1);
        lgl[0] = NA_LOGICAL;

        CharacterVector chr(1);
        chr[0] = NA_STRING;

        List out(4);
        out[0] = num;
        out[1] = intv;
        out[2] = lgl;
        out[3] = chr;
        return(out);
      }
    ')
    str(missing_sampler())

To check if a value in a vector is missing, use `ISNA`:

    cppFunction('
      LogicalVector is_na2(NumericVector x) {
        LogicalVector out(x.size());
        
        NumericVector::iterator x_it;
        LogicalVector::iterator out_it;
        for (x_it = x.begin(), out_it = out.begin(); x_it != x.end(); x_it++, out_it++) {
          *out_it = ISNA(*x_it);
        }
        return(out);
      }
    ')
    is_na2(c(NA, 5.4, 3.2, NA))

Rcpp provides a helper function called `is_na` that works similarly to `is_na2` above, producing a logical vector that's true where the value in the vector was missing.

### Using iterators

Iterators are the next step up from basic loops.  They abstract away from the details of the underlying datastructure.  They are important to understand because many C++ functions either accept or return iterators. Iterators have three main operators: they can be advanced with `++`, dereferenced (to get the value they refer to) with `*` and compared using `==`.  For example we could re-write our sum function above using iterators:

    cppFunction('
      double sum3(NumericVector x) {
        double total = 0;

        NumericVector::iterator end = x.end();
        for(NumericVector::iterator it = x.begin(); it != end; ++it) {
          total += *it;
        }
        return(total);
      }
    ')

The main changes are in the for loop:

* we start at `x.begin()` and loop until we get to `x.end()`. A small optimisiation is to store the value of the end iterator so we don't need to look it up each time. This only saves about 2 ns per iteration, so it's only important when the calculations in the loop are very simple.

* instead of indexing into x, we use the dereference operator to get its current value: `*it`.

Also notice the type of the iterator: `NumericVector::iterator`.  Each vector type has it's own iterator type: `LogicalVector::iterator`, `CharacterVector::iterator` etc.

Iterators also allow us to use the C++ equivalents of the apply family of functions. For example, we could again rewrite to use the `accumulate` function, which takes an starting and ending iterator and adds all the values in between. The third argument to accumulate gives the initial value: it's particularly important because this also determines the data type that accumulate uses (here we use `0.0` and not `0` so that accumulate uses a `double`, not an `int`.)

    cppFunction('
      #include <numeric>
      double sum4(NumericVector x) {

        double total = std::accumulate(x.begin(), x.end(), 0.0);
        return(total);
      }
    ')

However, `accumulate` (along with the other functions in `<numeric>`, `adjacent_difference`, `inner_product` and `partial_sum`) is not really that important in Rcpp because Rcpp sugar provides equivalents: `sum`, `diff, `*` and `cumsum`.

The `<algorithm>` provides a large number of algorithms that work with iterators. For example, we could write a basic Rcpp version of `findInterval` that takes two arguments a vector of values and a vector of breaks - the aim is to find the bin that each x falls into.  This shows off a number of more advanced iterator features.  Read the code below and see if you can figure out how it works.

    cppFunction('
      #include <algorithm>
      IntegerVector findInterval2(NumericVector x, NumericVector breaks) {
        IntegerVector out(x.size());

        NumericVector::iterator it, pos;
        IntegerVector::iterator out_it;

        for(it = x.begin(), out_it = out.begin(); it != x.end(); ++it, ++out_it) {
          pos = std::upper_bound(breaks.begin(), breaks.end(), *it);
          *out_it = std::distance(pos, breaks.begin());
        }

        return(out);
      }
    ')

* We step through two iterators (input and output) simultaneously.  

* We can also assign into an deferenced iterator (`out_it`) to change the values in `out`.

* `upper_bound` returns an iterator.  If we wanted the value of the `upper_bound` we could dereference it; to figure out its location, we use the `distance` function.

* Small note: if we want this function to be as fast as `findInterval` in R (which uses hand-written C code), we need to cache access to `.begin()` and `.end`.  This is simple but it adds cognitive overhead that distracts from this example.

It's generally better to use algorithms from the STL than hand rolled loops.  In "Effective STL", Scott Meyer gives three reasons: efficiency, correctness and maintainability.  Also makes clear the intent.  Extremely well tested and performant.

#### Exercises

Implement:

* `median.default` using `partial_sort`
* `%in%` using `unordered_set` and the `find` method
* `min` using `min`
* `which.min` using `min_element`
* `setdiff`, `union` and `intersect` using sorted ranges and `set_union`, `set_intersection` and `set_difference`

### Sugar

* vectorised operations: ifelse, sapply
* lazy functions: any, all (is_true, is_false, is_na)
* math functions: abs, exp, floor, ceil, pow, 
* binary arithmetic and logical operators

More details are available in the [Rcpp syntactic sugar](http://dirk.eddelbuettel.com/code/rcpp/Rcpp-sugar.pdf) vignette.

### Dispatching based on type

Table?

## Useful data structures and algorithms

The real strength of C++ shows itself when you need to implement more complex algorithms. The standard template library (STL) provides the standard CS data structures, and the Boost library implements a very wide range of data structures.

Some resources that you might find helpful are:

* http://www.cplusplus.com/reference/algorithm/
* http://www.cplusplus.com/reference/stl/
* http://www.davethehat.com/articles/eff_stl.htm
* http://www.sgi.com/tech/stl/

* vector: like an R vector, but grows efficiently (but use the `reserve` method if you know how much space you need in advance)
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

### More Rcpp

This chapter has only touched on a small part of Rcpp, giving you the basic tools to rewrite poorly performing R code in C++.  Rcpp has many other capabilities that make it easy to interface R to existing C++ code, including:

* automatically creating the wrappers between C++ data structures and R
  data structures. A good introduction to this topic is the vignette of [Rcpp modules](http://dirk.eddelbuettel.com/code/rcpp/Rcpp-modules.pdf)

* mapping C++ classes to reference classes.

I strongly recommend keeping an eye on the [Rcpp homepage](http://dirk.eddelbuettel.com/code/rcpp.html) and signing up for the [Rcpp mailing list](http://lists.r-forge.r-project.org/cgi-bin/mailman/listinfo/rcpp-devel). Rcpp is still under active development, and is getting better with every release.

### More C++

Writing performant code may also require you to rethink your basic approach: a solid understand of basic data structures and algorithms is very helpful here.  That's beyond the scope of this book, but I'd suggest the "algorithm design handbook" as a good place to start.  Or http://ocw.mit.edu/courses/electrical-engineering-and-computer-science/6-046j-introduction-to-algorithms-sma-5503-fall-2005/

* [Effective C++](http://amzn.com/0321334876)
* [Effective STL](http://amzn.com/0201749629)

* http://www.cs.helsinki.fi/u/tpkarkka/alglib/k06/
