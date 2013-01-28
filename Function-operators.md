# Function operators

Solving bigger problems often involves develop a specialised language for describing them.  This section shows how you can create domain specific languages in R using function operators: functions that both input and output functions.  We will explore function operators in the context of avoiding a common R programming problem: supplying the wrong type of input to a function.  

We want to develop a flexible way of specifying what a function needs, using a minimum amount of typing.  To do that we'll define some simple building blocks, and then work our way up by developing tools that combine simple pieces to create more complicated structures.

We'll also deal with some issues of creating new languages like conflicts with existing function names.

Like creating an algebra, in the sense that we define atoms and how to combine them together. Closed.

Alternative to adding additional arguments to a function.  Advantage is that you don't limit uses to functionality that you've thought up - as long as the modify the function in the right way, they can add alsorts of extra functioanlity.

Allow you to add extra functionality to an existing function, or to combine two existing function.

* `fail_with`
* something to convert between different types of loops?
* logging
* timing
* curry
* memoise
* 

Python's decorators: http://stackoverflow.com/questions/739654/understanding-python-decorators

`test_that` ?

## Boolean algebra

```R
and <- function(f1, f2) {
  function(...) {
    f1(...) && f2(...)
  }
}
or <- function(f1, f2) {
  function(...) {
    f1(...) || f2(...)
  }
}
not <- function(f1) {
  function(...) {
    !f1(...)
  }
}
```

### Exercises

* Something with `Negate`

* Extend `and`, `or` and `not` to deal with any number of input functions.

* Implement a corresponding `xor` function. Why can't you give it the most natural name?  What might you call it instead? Should you rename `and`, `or` and `not` to match your new naming scheme?

* Once you have read the [[S3]] chapter, replace `and`, `or` and `not` with appropriate methods of `&`, `|` and `!`.  Does `xor` work?

## Existing examples

Two built-in examples of this are functions `Negate` and `Vectorise`:

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

* `Negate` is a general example of the Compose pattern:

    Compose <- function(f, g) {
      f <- match.fun(f)
      g <- match.fun(g)
      function(...) f(g(...))
    }

    Compose(sqrt, "+")(1, 8)
    Negate <- Curry(Compose, `!`)

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
