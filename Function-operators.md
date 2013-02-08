# Function operators

The final functional programming technique we will discuss in this book is function operators: functions that take (at least) one function as input and return a function as output. Function operators allow you to add extra functionality to an existing function, or combine multiple existing functions. They have two main uses:

* developing specialised languages for solving wide classes of problems

* eliminating function parameters by encapsulating common variations as function transformations. The advantage is that you don't limit uses to functionality that you've thought up - as long as the modify the function in the right way, they can add all sorts of extra functioanlity. And you don't need a different argument for every possible option; end up with smaller, simpler pieces that you combine together. 

Functionals abstract away common looping operations. Function operators abstract over common anonymous functions operations. Like functionals, there's nothing you can't do without them; but they can make your code more readable and expressive by communicating higher level intent.

If you're familiar with Python, decorates are function operators. : http://stackoverflow.com/questions/739654/understanding-python-decorators

Like creating an algebra, in the sense that we define atoms and how to combine them together. Closed.

In this chapter, we'll explore four classes of function operators:

* change the output of the function: 
* change the input to the function:
* leave the function unchanged, but add additional useful behaviour
* combine multiple functions togeher:


## `match.fun`

It's often useful to be able to pass in either the name of a function, or a function. `match.fun()`.

Caveat: http://stackoverflow.com/questions/14183766

Also need the opposite: to get the name of the function.


## Output modifications

* negate the result of a predicate function (`base::Negate`)
* return a default value if the function throws an error (`fail_with`)
* convert a function that prints output to a function that returns output

```R
capture_it <- function(f) {
  function(...) {
    capture.output(f(...))
  }
}
str_out <- capture_it(str)
str(1:10)
str_out(1:10)

failwith <- function(default = NULL, f, quiet = FALSE) {
  f <- match.fun(f)
  function(...) {
    out <- default
    try(f(...), silent = quiet)
    out
  }
}
log("a")
failwith(NA, log)("a")
failwith(NA, log, quiet = TRUE)("a")
```

### Negate

`Negate` takes a function that returns a logical vector, and returns the negation of that function. This can be a useful shortcut when the function you have returns the opposite of what you need.

```R
Negate <- function(f) {
  f <- match.fun(f)
  function(...) !f(...)
}

(Negate(is.null))(NULL)
```

One function I find handy based on this is `compact`: it removes all non-null elements from a list:

```R
compact <- function(x) Filter(Negate(is.null), x)
```

### Exercises

* The `evaluate` package makes it easy to capture all the outputs (results, text, messages, warnings, errors and plots) from an expression. 

## Add additional behaviour

* log to disk everytime a function is run
* automatically print how long it took to run: timing
* save time by caching previous function results (`memoise::memoise`)
* add a delay to avoid swamping a server

```R
time_it <- function(f) {
  function(...) {
    start <- proc.time()
    res <- f(...)
    end <- proc.time()

    print(end - start)
    out
  }
}
delay_it <- function(f, delay) {
  function(...) {
    Sys.sleep(delay)
    f(...)
  }
}
log_it <- function(f, path, message) {
  stopifnot(file.exists(path))

  function(...) {
    cat(Sys.time(), ": ", message, sep = "", file = path, 
      append = TRUE)
    f(...)
  }
}
```

### Exercises

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

## Input modification

* modify an existing function by changing the default arguments (`pryr::curry`)
* convert a function that works with a data frame to a function that works with a matrix (`plyr::colwise`)
* convert a function of multiple parameters to a function of a single list parameter (`plyr::splat`)
* vectorise a scalar function (`base::Vectorise`)

### Partial function evaluation

<!-- Should Curry be renamed to partial -->

A common task is making a variant of a function that has certain arguments "filled in" already.  Instead of doing:

```R
x <- function(a) y(a, b = 1)
x <- curry(y, b = 1)

compact <- function(x) Filter(Negate(is.null), x)
compact <- curry(Filter, Negate(is.null))
```

This type of programming is called point-free (sometimes derogatorily known as pointless) because it you don't explicitly refer to variables (which are called points in some areas of computer science.)

One way to implement `curry` is as follows:

```R
curry <- function(FUN, ...) { 
  .orig <- list(...)
  function(...) {
    do.call(FUN, c(.orig, list(...)))
  }
}
```

But implementing it like this prevents arguments from being lazily evaluated, so `pryr::curry()` has a more complicated implementation that works by creating the same anonymous function that you'd created by hand, using techniques from the [[computing on the language]] chapter.

Alternative to providing `...` to user supplied functions.

```R
Map(function(x, y) f(x, y, zs), xs, ys)
Map(Curry(f, zs = zs), xs, ys)
```

### Vectorise

`Vectorize` takes a non-vectorised function and vectorises with respect to the arguments given in the `vectorise.args` parameter. This doesn't give you any magical performance improvements, but it is useful if you want a quick and dirty way of making a vectorised function.

An mildly useful extension of `sample` would be to vectorize it with respect to size: this would allow you to generate multiple samples in one call.

```R
sample2 <- Vectorize(sample, "size", SIMPLIFY = FALSE)
sample2(1:10, rep(5, 4))
sample2(1:10, 2:5)
```

In this example we have used `SIMPLIFY = FALSE` to ensure that our newly vectorised function always returns a list. This is usually a good idea. `Vectorize` does not work with primitive functions.


## Combine multiple functions

* combine two functions together (`pryr::compose`)
* combine the results of two vectorised functions into a matrix (`plyr::each`) 


### Function composition

```R
"%.%" <- compose <- function(f, g) {
  f <- match.fun(f)
  g <- match.fun(g)
  function(...) f(g(...))
}
compose(sqrt, "+")(1, 8)
(sqrt %.% `+`)(1, 8)
```

Then we could implement `Negate` as

```R
Negate <- curry(compose, `!`)
```

### Exercises

* What does the following function do? What would be a good name for it?

  ```R
  g <- function(f1, f2) {
    function(...) f1(...) || f2(...)
  } 
  Filter(g(is.character, is.factor), mtcars)
  ```

  Can you extend the function to take any number of functions as input? You'll probably need a loop.

* Write a function `and` that takes two function as input and returns a single function as an output that ands together the results of the two functions. Write a function `or` that combines the results with `or`.  Add a `not` function and you now have a complete set of boolean operators for predicate functions.

## Case study: boolean algebra


We will explore function operators in the context of avoiding a common R programming problem: supplying the wrong type of input to a function.  

We want to develop a flexible way of specifying what a function needs, using a minimum amount of typing.  To do that we'll define some simple building blocks, and then work our way up by developing tools that combine simple pieces to create more complicated structures.
Particularly powerful in conjunction with some S3 and S4 methods for operators (like `+`, `|`, etc.).



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

* Extend `and`, `or` and `not` to deal with any number of input functions. Can you keep them lazy?

* Implement a corresponding `xor` function. Why can't you give it the most natural name?  What might you call it instead? Should you rename `and`, `or` and `not` to match your new naming scheme?

* Once you have read the [[S3]] chapter, replace `and`, `or` and `not` with appropriate methods of `&`, `|` and `!`.  Does `xor` work?


