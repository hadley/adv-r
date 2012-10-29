# First class functions

R supports "first class functions", functions that can be:

* created anonymously,
* assigned to variables and stored in data structures,
* returned from functions (closures),
* passed as arguments to other functions (higher-order functions)

You've already learned about anonymous functions in [[functions]]. This chapter will explore the other three properties, and show how they can remove redundancy in your code. The chapter concludes with an exploration of numerical integration, showing how all of the properties of first-class functions can be used to solve a real problem.

<!-- 
## Pure functions

Why pure functions are easy to reason about:
Always easier to reason about things locally.

Ways in which functions can have side effects
 -->

You should be familiar with the basic properties of [[scoping and environments|Scoping]] before reading this chapter.


## Closures

There are two useful built-in functions that return closures:

* `Negate` takes a function that returns a logical vector, and returns the
  negation of that function. This can be a useful shortcut when the function
  you have returns the opposite of what you need.

        Negate <- function(f) {
          f <- match.fun(f)
          function(...) !f(...)
        }
      
        (Negate(is.null))(NULL)

  This is most useful in conjunction with higher-order functions, as we'll see
  in the next section.

* `Vectorize` takes a non-vectorised function and vectorises with respect to
  the arguments given in the `vectorise.args` parameter. This doesn't
  give you any magical performance improvements, but it is useful if you want
  a quick and dirty way of making a vectorised function.

  An mildly useful extension of `sample` would be to vectorize it with respect
  to size: this would allow you to generate multiple samples in one call.

        sample2 <- Vectorize(sample, "size", SIMPLIFY = FALSE)
        sample2(1:10, rep(5, 4))
        sample2(1:10, 2:5)

  In this example we have used `SIMPLIFY = FALSE` to ensure that our newly
  vectorised function always returns a list. This is usually a good idea.

  `Vectorize` does not work with primitive functions.

* `ecdf`

## Mutable state


The ability to manage variables at two levels makes it possible to maintain the state across function invocations by allowing a function to modify variables in the environment of its parent. Key to managing variables at different levels is the double arrow assignment operator (`<<-`). Unlike the usual single arrow assignment (`<-`) that always assigns in the current environment, the double arrow operator will keep looking up the chain of parent environments until it finds a matching name.

This makes it possible to maintain a counter that records how many times a function has been called, as shown in the following example. Each time `new_counter` is run, it creates an environment, initialises the counter `i` in this environment, and then creates a new function.

    new_counter <- function() {
      i <- 0
      function() {
        # do something useful, then ...
        i <<- i + 1
        i
      }
    }

The new function is a closure, and its environment is the enclosing environment. When the closures `counter_one` and `counter_two` are run, each one modifies the counter in its enclosing environment and then returns the current count.

    counter_one <- new_counter()
    counter_two <- new_counter()

    counter_one() # -> [1] 1
    counter_one() # -> [1] 2
    counter_two() # -> [1] 1

This is an important technique because it is one way to generate "mutable state" in R. [[R5]] expands on this idea in considerably more detail.



## Higher-order functions

The power of closures is tightly coupled to another important class of functions: higher-order functions (HOFs), functions that take functions as arguments. Mathematicians distinguish between functionals, which accept a function and return a scalar, and function operators, which accept a function and return a function. Integration over an interval is a functional, the indefinite integral is a function operator.

Higher-order functions of use to R programmers fall into two main camps: data structure manipulation and mathematical tools, as described below.

### Data structure manipulation

The first important family of higher-order functions manipulate vectors. They each take a function as their first argument, and a vector as their second argument. 

The first three functions take a logical predicate, a function that returns either `TRUE` or `FALSE`. The predicate function does not need to be vectorised, as all three functions call it element by element.

* `Filter`: returns a new vector containing only elements where the predicate
  is `TRUE`.

* `Find`: return the first element that matches the predicate (or the last
  element if `right = TRUE`).

* `Position`: return the position of the first element that matches the
  predicate (or the last element if `right = TRUE`).

The following example shows some simple uses:

    x <- 200:250
    
    is.even <- function(x) x %% 2 == 0
    is.odd <- Negate(is.even)
    is.prime <- function(x) gmp::isprime(x) > 1
    
    Filter(is.prime, x)
    # [1] 211 223 227 229 233 239 241
    
    Find(is.even, x)
    # 200
    Find(is.odd, x)
    # 201
    
    Position(is.prime, x, right = T)
    # 42

The next two functions work with more general classes of functions:

* `Map`: can take more than one vector as an input and calls `f`
  element-by-element on each input. It returns a list.

* `Reduce` recursively reduces a vector to a single value by first calling `f`
  with the first two elements, then the result of `f` and the second element
  and so on.

  If `x = 1:5` then the result would be `f(f(f(f(1, 2), 3), 4), 5)`.

  If `right = TRUE`, then the function is called in the opposite order: 
  `f(1, f(2, f(3, f(4, 5))))`. 

  You can also specify an `init` value in which case the result would be
  `f(f(f(f(f(init, 1), 2),3), 4), 5)`

  Reduce is useful for implementing many types of recursive operations:
  merges, finding smallest values, intersections, unions.


Apart from `Map`, the implementation of these five vector-processing HOFs is straightforward and I encourage you to read the source code to understand how they each work.

<!-- 
  find_uses("package:base", "match.fun")
  find_uses("package:stats", "match.fun")
  find_args("package:base", "FUN")
  find_args("package:stats", "FUN")
-->

Other families of higher-order functions include:

* The `apply` family: `eapply`, `lapply`, `mapply`, `tapply`, `sapply`,
  `vapply`, `by`. Each of these functions processes breaks up a data structure
  in some way, applies the function to each piece and then joins them back
  together again.

* The `**ply` functions of the `plyr` package which attempt to unify the base
  apply functions by cleanly separating based on the type of input they break
  up and the type of output that they produce.

* The array manipulation functions modify arrays to compute various margins or
  other summaries, or generalise matrix multiplication in various ways:
  `apply`, `outer`, `kronecker`, `sweep`, `addmargins`.

<!-- `Negate` is a general example of the Compose pattern:

    Compose <- function(f, g) {
      f <- match.fun(f)
      g <- match.fun(g)
      function(...) f(g(...))
    }

    Compose(sqrt, "+")(1, 8)
 -->

### Mathematical higher order functions

<!-- 
  find_args("package:stats", "^f$")
  find_args("package:stats", "upper")
-->

Higher order functions arise often in mathematics. In this section we'll explore some of the built in mathematical HOF functions in R. There are three functions that work with a 1d numeric function:

* `integrate`: integrate it over a given range
* `uniroot`: find where it hits zero over a given range
* `optimise`: find location of minima (or maxima)

Let's explore how these are used with a simple function:

    integrate(sin, 0, pi)
    uniroot(sin, pi * c(1 / 2, 3 / 2))
    optimise(sin, c(0, 2 * pi))
    optimise(sin, c(0, pi), maximum = TRUE)

There is one function that works with a more general n-dimensional numeric function, `optim`, which finds the location of a minima. 

In statistics, optimisation is often used for maximum likelihood estimation. Maximum likelihood estimation is a natural match to closures because the arguments to a likelihood fall into two groups: the data, which is fixed for a given problem, and the parameters, which will vary as we try to find a maximum numerically. This naturally gives rise to an approach like the following:

    # Negative log-likelihood for Poisson distribution
    poisson_nll <- function(x) {
      n <- length(x)
      function(lambda) {
        n * lambda - sum(x) * log(lambda) # + terms not involving lambda
      }
    }
    
    nll1 <- poisson_nll(c(41, 30, 31, 38, 29, 24, 30, 29, 31, 38)) 
    nll2 <- poisson_nll(c(6, 4, 7, 3, 3, 7, 5, 2, 2, 7, 5, 4, 12, 6, 9)) 
    
    optimise(nll1, c(0, 100))
    optimise(nll2, c(0, 100))

## Lists of functions

In R, functions can be stored in lists. Together with closures and higher-order functions, this gives us a set of powerful tools for reducing duplication in code.

We'll start with a simple example: benchmarking, when you are comparing the performance of multiple approaches to the same problem. For example, if you wanted to compare a few approaches to computing the mean, you could store each approach (function) in a list:

    compute_mean <- list(
      base = function(x) mean(x),
      sum = function(x) sum(x) / length(x),
      manual = function(x) {
        total <- 0
        n <- length(x)
        for (i in seq_along(x)) {
          total <- total + x[i] / n
        }
        total
      }
    )

Calling a function from a list is straightforward: just get it out of the list first:

    x <- runif(1e5)
    system.time(compute_mean$base(x))
    system.time(compute_mean$manual(x))
    
If we want to call all functions to check that we've implemented them correctly and they return the same answer, we can use `lapply`, either with an anonymous function, or a new function that calls it's first argument with all other arguments:

    lapply(compute_mean, function(f) f(x))

    call_fun <- function(f, ...) f(...)
    lapply(compute_mean, call_fun, x)

We can time every function on the list with `lapply` or `Map` along with a simple anonymous function:
    
    lapply(compute_mean, function(f) system.time(f(x)))
    Map(function(f) system.time(f(x)), compute_mean)
    
If timing functions is something we want to do a lot, we can add another layer of abstraction: a closure that automatically times how long a function takes. We then create a list of timed functions and call the timers with our specified `x`.

    timer <- function(f) {
      force(f)
      function(...) system.time(f(...))
    }
    timers <- lapply(compute_mean, timer)
    lapply(timers, call_fun, x)

Another useful example is when we want to summarise an object in multiple ways.  We could store each summary function in a list, and run each function with `lapply` and `call_fun`:

    funs <- list(
      sum = sum,
      mean = mean,
      median = median
    )
    lapply(funs, call_fun, 1:10)

What if we wanted to modify our summary functions to automatically remove missing values?  One approach would be make a list of anonymous functions that call our summary functions with the appropriate arguments:

    funs2 <- list(
      sum = function(x, ...) sum(x, ..., na.rm = TRUE),
      mean = function(x, ...) mean(x, ..., na.rm = TRUE),
      median = function(x, ...) median(x, ..., na.rm = TRUE)
    )

But this leads to a lot of duplication - each function is almost identical apart from a different function name. We could write a closure to abstract this away:

    remove_missings <- function(f) {
      function(...) f(..., na.rm = TRUE)
    }
    funs2 <- lapply(funs, remove_missings)

We could also take a more general approach. A useful function here is `Curry` (named after a famous computer scientist Haskell Curry, not the food), which implements "partial function application". What the curry function does is create a new function that passes on the arguments you specify. A example will make this more clear:

    add <- function(x, y) x + y
    addOne <- function(x) add(x, 1)
    addOne <- Curry(add, y = 1)

One way to implement `Curry` is as follows:

    Curry <- function(FUN,...) { 
      .orig <- list(...)
      function(...) {
        do.call(FUN, c(.orig, list(...)))
      }
    }

(You should be able to figure out how this works.  See the exercises.)

But implementing it like this prevents arguments from being lazily evaluated, so it has a somewhat more complicated implementation, basically working by building up an anonymous function by hand. You should be able to work out how this works after you've read the [[computing on the language]] chapter.  (Hopefully this function will be included in a future version of R.)

    Curry <- function(FUN, ...) {
      args <- match.call(expand.dots = FALSE)$...
      args$... <- as.name("...")
      
      env <- new.env(parent = parent.frame())
      
      if (is.name(FUN)) {
        fname <- FUN
      } else if (is.character(FUN)) {
        fname <- as.name(FUN)
      } else if (is.function(FUN)){
        fname <- as.name("FUN")
        env$FUN <- FUN
      } else {
        stop("FUN not function or name of function")
      }
      curry_call <- as.call(c(list(fname), args))

      f <- eval(call("function", as.pairlist(alist(... = )), curry_call))
      environment(f) <- env
      f
    }

But back to our problem. With the `Curry` function we can reduce the code a bit:

    funs2 <- list(
      sum = Curry(sum, na.rm = TRUE),
      mean = Curry(mean, na.rm = TRUE),
      median = Curry(median, na.rm = TRUE)
    )

But if we look closely that will reveal we're just applying the same function to every element in a list, and that's the job of `lapply`. This drastically reduces the amount of code we need:

    funs2 <- lapply(funs, Curry, na.rm = TRUE)

Let's think about a similar, but subtly different case. Let's take a vector of numbers and generate a list of functions corresponding to trimmed means with that amount of trimming.  The following code doesn't work because we want the first argument of `Curry` to be fixed to mean.  We could try specifying the argument name because fixed matching overrides positional, but that doesn't work because the name of the function to call in `lapply` is also `FUN`.  And there's no way to specify we want to call the `trim` argument.

    trims <- seq(0, 0.9, length = 5) 
    lapply(trims, Curry, "mean")
    lapply(trims, Curry, FUN = "mean")

Instead we could use an anonymous function

    funs3 <- lapply(trims, function(t) Curry("mean", trim = t))
    lapply(funs3, call_fun, c(1:100, (1:50) * 100))

But that doesn't work because each function gets a promise to evaluate `t`, and that promise isn't evaluated until all of the functions are run.  To make it work you need to manually force the evaluation of t:

    funs3 <- lapply(trims, function(t) {force(t); Curry("mean", trim = t)})
    lapply(funs3, call_fun, c(1:100, (1:50) * 100))

A simpler solution in this case is to use `Map`, as described in the last chapter, which works similarly to `lapply` except that you can supply multiple arguments by both name and position. For this example, it doesn't do a good job of figuring out how to name the functions, but that's easily fixed.

    funs3 <- Map(Curry, "mean", trim = trims)
    names(funs3) <- trims
    lapply(funs3, call_fun, c(1:100, (1:50) * 100))

It's usually better to use `lapply` because it is more familiar to most R programmers, and it is somewhat simpler and so is slightly faster.

## Case study: numerical integration

To conclude this chapter, we will develop a simple numerical integration tool, and along the way, illustrate the use of many properties of first-class functions: we'll use anonymous functions, lists of functions, functions that make closures and functions that take functions as input. Each step is driven by a desire to make our approach more general and to reduce duplication.

We'll start with two very simple approaches: the midpoint and trapezoid rules. Each takes a function we want to integrate, `f`, and a range to integrate over, from `a` to `b`. For this example we'll try to integrate `sin x` from 0 to pi, because it has a simple answer: 2

    midpoint <- function(f, a, b) {
      (b - a) * f((a + b) / 2)
    }

    trapezoid <- function(f, a, b) {
      (b - a) / 2 * (f(a) + f(b))
    }
    
    midpoint(sin, 0, pi)
    trapezoid(sin, 0, pi)


Neither of these functions gives a very good approximation, so we'll do what we normally do in calculus: break up the range into smaller pieces and integrate each piece using one of the simple rules. To do that we create two new functions for performing composite integration:

    midpoint_composite <- function(f, a, b, n = 10) {
      points <- seq(a, b, length = n + 1)
      h <- (b - a) / n
      
      area <- 0
      for (i in seq_len(n)) {
        area <- area + h * f((points[i] + points[i + 1]) / 2)
      }
      area
    }

    trapezoid_composite <- function(f, a, b, n = 10) {
      points <- seq(a, b, length = n + 1)
      h <- (b - a) / n
      
      area <- 0
      for (i in seq_len(n)) {
        area <- area + h / 2 * (f(points[i]) + f(points[i + 1]))
      }
      area
    }
    
    midpoint_composite(sin, 0, pi, n = 10)
    midpoint_composite(sin, 0, pi, n = 100)
    trapezoid_composite(sin, 0, pi, n = 10)
    trapezoid_composite(sin, 0, pi, n = 100)
    
    mid <- sapply(1:20, function(n) midpoint_composite(sin, 0, pi, n))
    trap <- sapply(1:20, function(n) trapezoid_composite(sin, 0, pi, n))
    matplot(cbind(mid = mid, trap))

But notice that there's a lot of duplication across `midpoint_composite` and `trapezoid_composite`: they are basically the same apart from the internal rule used to integrate over a simple range. Let's extract out a general composite integrate function:

    composite <- function(f, a, b, n = 10, rule) {
      points <- seq(a, b, length = n + 1)
      
      area <- 0
      for (i in seq_len(n)) {
        area <- area + rule(f, points[i], points[i + 1])
      }
      
      area
    }
    
    midpoint_composite(sin, 0, pi, n = 10)
    composite(sin, 0, pi, n = 10, rule = midpoint)
    composite(sin, 0, pi, n = 10, rule = trapezoid)

This function now takes two functions as arguments: the function to integrate, and the integration rule to use for simple ranges. We can now add even better rules for integrating small ranges:

    simpson <- function(f, a, b) {
      (b - a) / 6 * (f(a) + 4 * f((a + b) / 2) + f(b))
    }
    
    boole <- function(f, a, b) {
      pos <- function(i) a + i * (b - a) / 4
      fi <- function(i) f(pos(i))
      
      (b - a) / 90 * 
        (7 * fi(0) + 32 * fi(1) + 12 * fi(2) + 32 * fi(3) + 7 * fi(4))
    }
    
Let's compare these different approaches.

    expt1 <- expand.grid(
      n = 5:50, 
      rule = c("midpoint", "trapezoid", "simpson", "boole"), 
      stringsAsFactors = F)
    
    abs_sin <- function(x) abs(sin(x))
    run_expt <- function(n, rule) {
      composite(abs_sin, 0, 4 * pi, n = n, rule = match.fun(rule))
    }
    
    library(plyr)
    res1 <- mdply(expt1, run_expt)
    
    library(ggplot2)
    qplot(n, V1, data = res1, colour = rule, geom = "line")

It turns out that the midpoint, trapezoid, Simpson and Boole rules are all examples of a more general family called Newton-Cotes rules. We can take our integration one step further by extracting out this commonality to produce a function that can generate any general Newton-Cotes rule:

    # http://en.wikipedia.org/wiki/Newton%E2%80%93Cotes_formulas
    newton_cotes <- function(coef, open = FALSE) {
      n <- length(coef) + open
      
      function(f, a, b) {
        pos <- function(i) a + i * (b - a) / n
        points <- pos(seq.int(0, length(coef) - 1))
        
        (b - a) / sum(coef) * sum(f(points) * coef)        
      }
    }
    
    trapezoid <- newton_cotes(c(1, 1))
    midpoint <- newton_cotes(1, open = T)
    simpson <- newton_cotes(c(1, 4, 1))
    boole <- newton_cotes(c(7, 32, 12, 32, 7))
    milne <- newton_cotes(c(2, -1, 2), open = TRUE)
    
    # Alternatively, make list then use lapply
    lapply(values, newton_cotes, closed)
    lapply(values, newton_cotes, open, open = TRUE)
    lapply(values, do.call, what = "newton_cotes")
    
    expt1 <- expand.grid(n = 5:50, rule = names(rules), stringsAsFactors = F)
    run_expt <- function(n, rule) {
      composite(abs_sin, 0, 4 * pi, n = n, rule = rules[[rule]])
    }
    

Mathematically, the next step in improving numerical integration is to move from a grid of evenly spaced points to a grid where the points are closer together near the end of the range. 

## Summary

## Exercises

1. Read the source code for `Filter`, `Negate`, `Find` and `Position`. Write a couple of sentences for each describing how they work.

1. Write an `And` function that given two logical functions, returns a logical And of all their results. Extend the function to work with any number of logical functions. Write similar `Or` and `Not` functions.

1. Write a general compose function that composes together an arbitrary number of functions. Write it using both recursion and looping.

1. How does the first version of `Curry` work?
