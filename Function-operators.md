## Function operators

A related use of function factories is to tweak the way that existing functions behase. Two built-in examples of this are functions `Negate` and `Vectorise`:

* `Negate` takes a function that returns a logical vector, and returns the
  negation of that function. This can be a useful shortcut when the function
  you have returns the opposite of what you need.

  ```R
  Negate <- function(f) {
    f <- match.fun(f)
    function(...) !f(...)
  }

  (Negate(is.null))(NULL)
  ```

<!-- `Negate` is a general example of the Compose pattern:

    Compose <- function(f, g) {
      f <- match.fun(f)
      g <- match.fun(g)
      function(...) f(g(...))
    }

    Compose(sqrt, "+")(1, 8)
 -->

* `Vectorize` takes a non-vectorised function and vectorises with respect to
  the arguments given in the `vectorise.args` parameter. This doesn't
  give you any magical performance improvements, but it is useful if you want
  a quick and dirty way of making a vectorised function.

  An mildly useful extension of `sample` would be to vectorize it with respect
  to size: this would allow you to generate multiple samples in one call.

  ```R
  sample2 <- Vectorize(sample, "size", SIMPLIFY = FALSE)
  sample2(1:10, rep(5, 4))
  sample2(1:10, 2:5)
  ```

  In this example we have used `SIMPLIFY = FALSE` to ensure that our newly
  vectorised function always returns a list. This is usually a good idea.

  `Vectorize` does not work with primitive functions.


### Exercises

* What does the following function do? What would be a good name for it?

  ```R
  g <- function(f1, f2) {
    function(...) f1(...) || f2(...)
  } 
  Filter(g(is.character, is.factor), mtcars)
  ```

  Can you extend the function to take any number of functions as input? You'll probably need a loop.

* Create a function `pick()`, that takes an index, `i`, as an argument and returns a function an argument `x` that subsets `x` with `i`.
  
  ```R
  lapply(mtcars, pick(5))
  ```

* Write a function `and` that takes two function as input and returns a single function as an output that ands together the results of the two functions. Write a function `or` that combines the results with `or`.  Add a `not` function and you now have a complete set of boolean operators for predicate functions.

* Create a function called `timer` that takes a function as input and returns as function as output. The new function should perform exactly the same as the old function, except that it should also print out how long it took to run.

* What does the following function do? What would be a good name for it?

  ```R
  f <- function(g) {
    stopifnot(is.function(g))
    result <- NULL
    function(...) {
      if (is.null(result)) {
        result <- g(...)
      }
      result
    }
  }
  ```
