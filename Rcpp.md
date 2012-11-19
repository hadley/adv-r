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
        return sum;
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
      return 1;
    }

We can compile and use this from R with `cppFunction`

    cppFunction('
      int one() {
        return 1;
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
          return 1;
        } else if (x == 0) {
          return 0;
        } else {
          return -1;
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
        return total;
      }
    ')

The C++ version is similar, but:

* To find the length of the vector, we use the `length()` method, which returns an integer. Again, whenever we create a new variable we have to tell C++ what type of object it will hold. An `int` is a scalar integer, but we could have used `double` for a scalar numeric, `bool` for a scalar logical, or a `std::string` for a scalar character vector.

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
        return out;
      }
    ')

This function introduces only a few new concepts:

* We create a new `NumericVector` and say how long it should be using a constructor function: `out(n)`.

* Finally, C++ doesn't have the `^` operator for exponentiation, it instead has the `pow` function

Note that this function is not only much more verbose than R equivalent, it won't be much faster - the R version is already very fast because it uses vectorised primitives which very quickly turn into C loops. However, our C++ function does have one advantage - it will use less memory, because `pdist1` needs two vectors the same length as y (`z <- x - ys`, and `z ^ 2`)

    ys <- runif(1e5)
    all.equal(pdist1(0.5, ys), pdist2(0.5, ys))

    library(microbenchmark)
    microbenchmark(
      pdist1(0.5, ys),
      pdist2(0.5, ys)
    )

In the sugar section, you'll see how to rewrite this function to take advantage of Rcpp's vectorised operations so that the C++ code is barely longer than the R code.

### Matrix input, vector output

Each vector type also has a matrix equivalent: `NumericMatrix`, `IntegerMatrix`, `CharacterMatrix` and `LogicalMatrix`. Using them is straightforward. For example, we could easily create a function that reproduces `rowSums`:

    cppFunction('
      NumericVector row_sums(NumericMatrix x) {
        int nrow = x.nrow(), ncol = x.ncol();
        NumericVector out(nrow);

        for (int i = 0; i < nrow; i++) {
          double total = 0;
          for (int j = 0; j < ncol; j++) {
            total += x(i, j);
          }
          out[i] = total;
        }
        return out;
      }
    ')
    x <- matrix(sample(100), 10)
    rowSums(x)

The main thing to notice is that when subsetting a matrix we use `()` and not `[]`. 

### Exercises

With the basics of C++ in hand, now is a great time to practice by reading and writing some simple C++ functions.  

Convert the following functions into C++

* `diff`. Start by assuming lag 1, and then generalise for lag n.

* `range`. Start by assuming that the input has no missing values, then generalise to include a `na.rm` parameter. If `TRUE` your function should ignore missing values (does it need to do anything special?), if `FALSE` it should return two missing values the first time it sees a missing value.

* `var` or `sd`.

## Important Rcpp classes

You've already seen `NumericVector`, `CharacterVector`, `IntegerVector` and `LogicalVector`. They 

You can also use standard C++ variable types for scalars: `int`, `double`, `bool`, `std::string`.  

* Important methods: `length`, `fill`.
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

Calling an R function from C++ is straightforward:

    Function assign("assign");
    assign("y", 1);
    assign(_["x"] = "y", _["value"] = 1);

The challenge is storing the output. If you don't know a priori what the output will be, store it in an `RObject`. 

## Rcpp sugar

Rcpp provides a lot of "sugar", C++ functions included in the Rcpp namespace that work very similarly to their R equivalents. They work with `Vector` objects, and recycle in the same way as their R counterparts. Rcpp sugar makes it possible to write extremely efficient C++ code that looks almost identical to the R equivalent.

If a sugar version of the function you're interested exists, you should use it: it's likely to be fast and correct. Many of the sugar functions don't make copies of the object, or use expression capturing tricks to ensure that the minimal necessary computation is done.

More details are available in the [Rcpp syntactic sugar](http://dirk.eddelbuettel.com/code/rcpp/Rcpp-sugar.pdf) vignette.

### Vectorised arithmetic and logical operators: 

`+` `*`, `-`, `/`, `pow`, `<`, `<=`, `>`, `>=`, `==`, `!=`, `!`.  For example, we could use sugar to considerably simply the implementation of our `pdist2` function:

    pdist1 <- function(x, ys) {
      (x - ys) ^ 2
    }

    cppFunction('
      NumericVector pdist3(double x, NumericVector ys) {
        return pow((x - ys), 2);
      }
    ')

### Logical summary functions

`any` and  `all`. These functions are fully lazy (so that e.g `any(x == 0)` might only need to evaluate one element of the value), and return a special type that can be converted into a `bool` using `is_true`, `is_false`, or `is_na`.  

For example, we could use this to write an efficient funtion to determine whether or not a numeric vector contains any missing values.  In R we could do `any(is.na(x))` but that will always do the same amount of work regardless of if there's a missing value in the first position or the last.  

    any_na1 <- function(x) any(is.na(x))

    cppFunction('
      bool any_na2(NumericVector x) {
        return(is_true(any(is_na(x))));
      }
    ')

    cppFunction('
      bool any_na3(NumericVector x) {
        NumericVector::iterator it = x.begin(), end = x.end();
        for(; it != end; ++it) {
          if (ISNA(*it)) return(true);
        }

        return(false);
      }
    ')

    library(microbenchmark)
    x <- runif(1e5)
    x1 <- c(NA, x)
    x2 <- c(x, NA)

    microbenchmark(
      any_na1(x), any_na2(x), any_na3(x),
      any_na1(x1), any_na2(x1), any_na3(x1),
      any_na1(x2), any_na2(x2), any_na3(x2))

Our `any_na2` function is always (slightly) faster than `any_na1` (probably because it avoids allocation an logical vector of the same length of `x`), but it's much faster when the first value is missing. Our hand-written equivalent `any_na3` is exactly the same speed.

### Vector views

`head`, `tail`, `rep_each`, `rep_len`, `rev`, `seq_along`, `seq_len`.  

In R these would all produce copies of the vector, but in Rcpp sugar they simply point to the existing vector and override the subsetting operator (`[`) to implement special behaviour. This makes them very efficient.

### Other useful functions

* `mean, `min`, `max`, `sum`, `sd` and `var`.

* `which_max`, `which_min`

* `abs`, `exp`, `sign`, `floor`, `ceil`, `pow`, `log`, `sin`, `cos`, etc.

* `cumsum`, `diff`, `pmin`, and `pmax`

* `d/q/p/r` for all standard distributions in R.

* `no_na(x)`: this asserts that the vector `x` does not contain any missing values, and allows optimisation of some mathematical operations.

## Missing values

If you're working with missing values, you need to know two things:

* what happens when you put missing values in scalars (e.g. `double`)
* how to get and set missing values in vectors (e.g. `NumericVector`)

### Scalars

The following code explores what happens when you take one of R's missing values, coerce it into a scalar, and then coerce back to an R vector

    cppFunction('
      List scalar_missings() {
        CharacterVector chr(1);
        chr[0] = NA_STRING;

        int int_s = NA_INTEGER;
        std::string chr_s = std::string(chr[0]);
        bool lgl_s = NA_LOGICAL;
        double num_s = NA_REAL;

        return(List::create(int_s, chr_s, lgl_s, num_s));
      }
    ')
    str(scalar_missings())

So

* `NumericVector` -> `double`: stored as an NaN, and preserved. Most numerical operations will behave as you expect, but logical comparisons will not.  See below for more details.

* `IntegerVector` -> `int`: stored as the smallest integer. If you leave as is, it will be preserved, but no C++ operations are aware of the missingness: `evalCpp('NA_INTEGER + 1')` gives -2147483647.

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
        CharacterVector chr(1);
        chr[0] = NA_STRING;

        return(List::create(
          NumericVector::create(NA_REAL), 
          IntegerVector::create(NA_INTEGER),
          LogicalVector::create(NA_LOGICAL), 
          chr));
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
        return out;
      }
    ')
    is_na2(c(NA, 5.4, 3.2, NA))

Rcpp provides a helper function called `is_na` that works similarly to `is_na2` above, producing a logical vector that's true where the value in the vector was missing.

## The STL

The real strength of C++ shows itself when you need to implement more complex algorithms. The standard template library (STL) provides set of extremely useful data structures and algorithms. This section will explain the most important algorithms and data structures and point you in the right direction to learn more.

If you need an algorithm or data strucutre that isn't implemented in STL, the first place to look is [boost](http://www.boost.org/doc/).

### Using iterators

Iterators are used extensively in the STL: many functions either accept or return iterators. They are the next step up from basic loops, abstracting away the details of the underlying data structure. Iterators have three main operators: they can be advanced with `++`, dereferenced (to get the value they refer to) with `*` and compared using `==`. For example we could re-write our sum function using iterators:

    cppFunction('
      double sum3(NumericVector x) {
        double total = 0;

        NumericVector::iterator end = x.end();
        for(NumericVector::iterator it = x.begin(); it != end; ++it) {
          total += *it;
        }
        return total;
      }
    ')

The main changes are in the for loop:

* we start at `x.begin()` and loop until we get to `x.end()`. A small optimisiation is to store the value of the end iterator so we don't need to look it up each time. This only saves about 2 ns per iteration, so it's only important when the calculations in the loop are very simple.

* instead of indexing into x, we use the dereference operator to get its current value: `*it`.

* notice the type of the iterator: `NumericVector::iterator`.  Each vector type has it's own iterator type: `LogicalVector::iterator`, `CharacterVector::iterator` etc.

Iterators also allow us to use the C++ equivalents of the apply family of functions. For example, we could again rewrite `sum` to use the `accumulate` function, which takes an starting and ending iterator and adds all the values in between. The third argument to accumulate gives the initial value: it's particularly important because this also determines the data type that accumulate uses (here we use `0.0` and not `0` so that accumulate uses a `double`, not an `int`.)

    cppFunction('
      #include <numeric>
      double sum4(NumericVector x) {

        double total = std::accumulate(x.begin(), x.end(), 0.0);
        return total;
      }
    ')

`accumulate` (along with the other functions in `<numeric>`, `adjacent_difference`, `inner_product` and `partial_sum`) are not that important in Rcpp because Rcpp sugar provides equivalents: `sum`, `diff, `*` and `cumsum`.


### Algorithms

http://www.cplusplus.com/reference/algorithm/

The `<algorithm>` header provides a large number of algorithms that work with iterators. For example, we could write a basic Rcpp version of `findInterval` that takes two arguments a vector of values and a vector of breaks - the aim is to find the bin that each x falls into. This shows off a few more advanced iterator features.  Read the code below and see if you can figure out how it works.

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

        return out;
      }
    ')

* We step through two iterators (input and output) simultaneously.  

* We can assign into an dereferenced iterator (`out_it`) to change the values in `out`.

* `upper_bound` returns an iterator. If we wanted the value of the `upper_bound` we could dereference it; to figure out its location, we use the `distance` function.

* Small note: if we want this function to be as fast as `findInterval` in R (which uses hand-written C code), we need to cache the calls to `.begin()` and `.end()`.  This is easy, but it distracts from this example so it has been omitted.

It's generally better to use algorithms from the STL than hand rolled loops.  In "Effective STL", Scott Meyer gives three reasons: efficiency, correctness and maintainability. Algorithms from the STL are written by C++ experts to be extremely efficient, and they have been around for a long time so they are well tested. Using standard algorithms also makes the intent of your code more clear, helping to make it more readable and more maintainable.

### Data structures

The STL provides a large set of data structures: `array`, `bitset`, `list`, `forward_list`, `map`, `multimap`, `multiset`, `priority_queue`, `queue`, `dequeue`, `set`, `stack`, `unordered_map`, `unordered_set`, `unordered_multimap`, `unordered_multiset`, and `vector`.  The most important of these datastructures are the `vector`, the `unordered_set`, and the `unordered_map`.  We'll focus on these three in this section, but using the others is very similar: they just have different performance tradeoffs. For example, the `deque` (pronounced "deck") has a very similar interface to vectors but a different implementation with different performance trade-offs. You may want to try them for your problem.

http://www.cplusplus.com/reference/stl/

One nice feature of the STL containers is that Rcpp knows how to convert from most STL data structures to their R equivalents. For example, the following is a very simple implementation of a unique function: it loads everything into a set and then returns the set. Rcpp takes care of converting it into an integer vector.

    std::tr1::unordered_set<int> unique(IntegerVector x) {
      std::tr1::unordered_set<int> seen;

      for(IntegerVector::iterator it = x.begin(); it != x.end(); ++it) {
        seen.insert(*it);
      } 
      return(seen);
    }

    // [[Rcpp::export]]
    NumericVector tapply3(NumericVector x, IntegerVector i, Function fun) {
      std::map<int, std::vector<double> > groups;
      
      NumericVector::iterator x_it;
      IntegerVector::iterator i_it;
      
      for(x_it = x.begin(), i_it = i.begin(); x_it != x.end(); ++x_it, ++i_it) {
        groups[*i_it].push_back(*x_it);
      }
     
      NumericVector out(groups.size());   
      std::map<int, std::vector<double> >::const_iterator g_it = groups.begin();
      NumericVector::iterator o_it = out.begin();
      for(; g_it != groups.end(); ++g_it, ++o_it) {
        NumericVector res = fun(g_it->second);
        *o_it = res[0];
      }
      return out;
    }

Sets are a useful data structure for many jobs that involve duplicates or unique values. The following function is a simple implementation of R's `duplicated` funciton. Note the use of `seen.insert(x[i]).second` - `insert` returns a pair, the first value giving an iterator to the position of the element and the second element is a boolean that's true if the value was a new addition to the set.  

    LogicalVector duplicated(IntegerVector x) {
      std::set<int> seen;
      int n = x.size();
      LogicalVector out(n);

      for (int i = 0; i < n; ++i) {
        out[i] = seen.insert(x[i]).second;
      }

      return(out);
    }

### Exercises

Implement:

* `median.default` using `partial_sort`
* `%in%` using `unordered_set` and the `find` method
* `unique` using an `unordered_set`
* `min` using `min`
* `which.min` using `min_element`
* `setdiff`, `union` and `intersect` using sorted ranges and `set_union`, `set_intersection` and `set_difference`
* `rle` using `vector` and `push_back`

* re-write our implementation of `row_sums` to use iterators. Rewrite it to use `accumulate`.

<!-- 
duplicated.data.frame (pastes rows together)
rank?
 -->

## Special programming topics

### Dispatching based on type

Table?

### Profiling

http://stackoverflow.com/questions/13224322/profiling-rcpp-code-on-os-x

## Case studies

### Gibbs sampler

The following case study updates an example [blogged about](From http://dirk.eddelbuettel.com/blog/2011/07/14/) by Dirk Eddelbuettel, illustrating the conversion of a gibbs sampler in R to C++.  The R and C++ code shown below is very similar (it only took a few minutes to convert the R version to the C++ version), but runs about 20 times faster on my computer.  Dirk's blog post also shows another way to make it even faster: using the faster (but presumably less numerically accurate) random number generator functions in GSL (easily accessible from R through RcppGSL) can eke out another 2-3x speed improvement.

    gibbs_r <- function(N, thin) {
      mat <- matrix(nrow = N, ncol = 2)
      x <- y <- 0

      for (i in 1:N) {
        for (j in 1:thin) {
          x <- rgamma(1, 3, y * y + 4)
          y <- rnorm(1, 1 / (x + 1), 1 / sqrt(2 * (x + 1)))
        }
        mat[i, ] <- c(x, y)
      }
      mat
    }

    cppFunction('
      NumericMatrix gibbs_cpp(int N, int thin) {
        NumericMatrix mat(N, 2);
        double x = 0, y = 0;

        for(int i = 0; i < N; i++) {
          for(int j = 0; j < thin; j++) {
            x = rgamma(1, 3.0, y * y + 4)[0];
            y = rnorm(1, 1 / (x + 1), 1 / sqrt(2 * (x + 1)))[0];
          }
          mat(i, 0) = x;
          mat(i, 1) = y;
        }

        return(mat);
      }
    ')

    library(microbenchmark)
    microbenchmark(
      gibbs_r(100, 10),
      gibbs_cpp(100, 10)
    )

### R vectorisation vs. C++ vectorisation

This example is adapted from [Rcpp is smoking fast for agent-based models in data frames](http://www.babelgraph.org/wp/?p=358). The challenge is to predict a model response from three inputs. The basic R version looks like:

    vacc1a <- function(age, female, ily) {
      p <- 0.25 + 0.3 * 1 / (1 - exp(0.04 * age)) + 0.1 * ily
      p <- p * if (female) 1.25 else 0.75
      p <- max(0, p)
      p <- min(1, p)
      p
    }

We want to be able to apply this function to many inputs, so we might write a vectorised version using a for loop.

    vacc1 <- function(age, female, ily) {
      n <- length(age)
      out <- numeric(n)
      for (i in seq_len(n)) {
        out[i] <- vacc1a(age[i], female[i], ily[i])
      }
      out
    }

If you're familiar with R, you'll have a gut feeling that this will be slow, and indeed it is. There are two ways we could attack this problem. If you have a good R vocabulary, you might immediately see how to vectorise the function (using `ifelse`, `pmin` and `pmax`).  Alternatively, we could rewrite `vacc1a` and `vacc1` in C++, using our knowledge that loops and function calls have much lower overhead in C++.

Either approach is fairly straighforward. In R:

    vacc2 <- function(age, female, ily) {
      p <- 0.25 + 0.3 * 1 / (1 - exp(0.04 * age)) + 0.1 * ily
      p <- p * ifelse(female, 1.25, 0.75)
      p <- pmax(0, p)
      p <- pmin(1, p)
      p
    }

Or in C++:

    double vacc3a(double age, bool female, bool ily){
      double p = 0.25 + 0.3 * 1 / (1 - exp(0.04 * age)) + 0.1 * ily;
      p = p * (female ? 1.25 : 0.75);
      p = std::max(p, 0.0); 
      p = std::min(p, 1.0);
      return p;
    }

    // [[Rcpp::export]]
    NumericVector vacc3(NumericVector age, LogicalVector female, LogicalVector ily) {
      int n = age.size();
      NumericVector out(n);

      for(int i = 0; i < n; ++i) {
        out[i] = vacc3a(age[i], female[i], ily[i]);
      }

      return out;
    }

We next generate some sample data, and check that all three versions return the same values:

    n <- 1000
    age <- rnorm(n, mean = 50, sd = 10)
    female <- sample(c(T, F), n, rep = TRUE)
    ily <- sample(c(T, F), n, prob = c(0.8, 0.2), rep = TRUE)

    stopifnot(
      all.equal(vacc1(age, female, ily), vacc2(age, female, ily)),
      all.equal(vacc1(age, female, ily), vacc3(age, female, ily))
    )

The original blog post forgot to do this, and hence introduced a bug in the C++ version: `0.004` instead of `0.04`.  Finally, we can benchmark our three approaches:

    microbenchmark(
      vacc1(age, female, ily),
      vacc2(age, female, ily),
      vacc3(age, female, ily)

Not surprisingly, our original approach with loops is very slow.  Vectorising in R gives a huge speedup, and we can eke out even more performance (~10x) with the C++ loop.  I was a little surprised that the C++ was so much faster, but I think that this is because the R version has to create 11 vectors to store intermediate results, where the C++ code only needs to create 1.

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

* http://www.icce.rug.nl/documents/cplusplus/cplusplus.html
* http://www.cs.helsinki.fi/u/tpkarkka/alglib/k06/
* http://www.davethehat.com/articles/eff_stl.htm
* http://www.sgi.com/tech/stl/
