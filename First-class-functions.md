# First class functions

R supports "first class functions", functions that can be:

* created anonymously
* assigned to variables and stored in data structures
* returned from functions (closures)
* passed as arguments to other functions (higher-order functions)

This chapter explores these properties in more depth. You should be familiar with the basic properties of [[scoping and environments|Scoping]] before reading this chapter

New levels of abstraction give us more tools to identify and remove redundancy from our code. For loops abstract repetition, giving us general tools to repeat an action multiple time. Functions abstract tasks, allowing us to separate the general principles of a task from the specific data it is applied to. The properties of first class functions give us new tools for problems that involve working with multiple functions.

## Anonymous functions

The key to all more advanced techniques described below is that in R, functions are objects in their own right. Unlike many other programming languages functions aren't automatically bound to a name - they can exist independently in their own right. You're probably aware of this already, because when you create a named function, you use the usual assignment operator to give it a name. If you don't do that - you get an anonymous function. The remainder of this chapter explores the consequences of this idea.

Anonymous functions are not that useful by themselves, so this section will introduce the basic ideas, and show useful applications in the following sections.

Given the name of a function as a string, you can retrieve the function using `match.fun`. You can also construct a call completely from scratch as outlined in [[computing on the language]].  Given a function, there is no general way to retrieve its name because it may not have a name, or may have more than one name. Named functions are a subset of all functions in R.

The tool we use for creating functions is `function` - it is very close to being an ordinary R function, but it has special syntax: the last argument to the function is outside the call to function and provides the body of the new function.

    function(x) 3
    # function(x) 3

You can also call anonymous functions. The following code is a little tricky to read because parentheses are used in two different ways: to call a function, and to make it clear that we want to call the anonymous function `function(x) 3` not inside our anonymous function call a function called `3` (not a valid function name)

    (function(x) 3)()
    # [1] 3
    
    # Exactly the same as
    f <- function(x) 3
    f()
    
    function(x) 3()
    # function(x) 3()

The syntax extends in a straightforward way if the function has parameters

    (function(x) x)(3)
    # [1] 3
    (function(x) x)(x = 4)
    # [1] 4

Functions have three important components

* `body()`: the quoted object representing the code inside the function
* `formals()`: the argument list to the function
* `environment()`: the environment in which the function was defined

These can both also be used to modify the structure of the function in their assignment form.
  
These are illustrated below:
  
    formals(function(x = 4) g(x) + h(x))
    # $x
    # [1] 4

    body(function(x = 4) g(x) + h(x))
    # g(x) + h(x)
    
    environment(function(x = 4) g(x) + h(x))
    # <environment: R_GlobalEnv>

## Closures 

"An object is data with functions. A closure is a function with data." 
--- [John D Cook](http://twitter.com/JohnDCook/status/29670670701)

A closure is a function written by another function. Closures are so called because they __enclose__ the environment of the parent function, and can access all variables and parameters in that function. This is useful because it allows us to have two levels of parameters. One level of parameters (the parent) controls how the function works. The other level (the child) does the work. The following example shows how can use this idea to generate a family of power functions. The parent function (`power`) creates child functions (`square` and `cube`) that actually do the hard work.

    power <- function(exponent) {
      function(x) x ^ exponent
    }

    square <- power(2)
    square(2) # -> [1] 4
    square(4) # -> [1] 16

    cube <- power(3)
    cube(2) # -> [1] 8
    cube(4) # -> [1] 64

The ability to manage variables at two levels also makes it possible to maintain the state across function invocations by allowing a function to modify variables in the environment of its parent. Key to managing variables at different levels is the double arrow assignment operator (`<<-`). Unlike the usual single arrow assignment (`<-`) that always works on the current level, the double arrow operator will look for a variable with that name in the parent scope.

This makes it possible to maintain a counter that records how many times a function has been called, as the following example shows. Each time `new_counter` is run, it creates an environment, initialises the counter `i` in this environment, and then creates a new function.

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

This is an important technique because it is one way to generate "mutable state" in R.

Basically every function in R is a closure, because all functions remember the environment in which they are created, typically either the global environment, if it's a function that you're written, or a package environment, if it's a function that someone else has written. When you print a function in R, it always shows you which environment it comes from. If the environment isn't displayed, it doesn't mean it doesn't have an environment, it means that it was created in the global environment. The environment inside an arbitrary function doesn't have a special name, so the environment of closures that you've created will have random names.

    f <- function(x) x
    f
    # function(x) x
    environment(f)
    # <environment: R_GlobalEnv>
    
    print
    # function (x, ...) 
    # UseMethod("print")
    # <environment: namespace:base>
    
    counter_one
    # function() {
    #         # do something useful, then ...
    #         i <<- i + 1
    #         i
    #       }
    # <environment: 0x1022be7f0>


A more technical description is available in [Frames, Environments, and Scope in R and S-PLUS](http://cran.r-project.org/doc/contrib/Fox-Companion/appendix-scope.pdf). Section 2 is recommended as a good introduction to the formal vocabulary used in much of the R documentation. [Lexical scope and statistical computing](http://www.stat.auckland.ac.nz/~ihaka/downloads/lexical.pdf) gives more examples of the power and utility of closures.

### Built-in functions that write functions

There are two useful built-in functions that write functions:

* `Negate`: takes a function that returns a logical vector, and returns a
  function that returns the negation of that vector. This can be a useful
  shortcut when the function you have returns the opposite of what you need.

      Negate <- function(f) {
        f <- match.fun(f)
        function(...) !f(...)
      }
      
      (Negate(is.null))(NULL)

  `Negate` is a general example of the Compose pattern:
  
      Compose <- function(f, g) {
        f <- match.fun(f)
        g <- match.fun(g)
        function(...) f(g(...))
      }
      
      Compose(sqrt, "+")(1, 8)

* `Vectorize`: takes a non-vectorised function and makes it vectorised. This
  doesn't get you any magical performance improvements, but it is useful if
  you want a quick and dirty way of making a vectorised function, as you need
  (for example) with `outer`

## Higher-order functions

The power of closures is tightly connected to another important class of functions: higher-order functions (HOFs), also known as functionals. HOFs are functions that take a function as an argument. Higher-order functionals of use to R programmers fall into three main camps: data structure manipulation, mathematical tools and statistical tools. In this section we will explore some of their properties and uses.

### Data structure manipulation

The first important family of higher-order functions that manipulate vectors.  They each take a function as their first argument, and a vector as their second argument.  These function come from functional programming languages like Lisp and Haskell.

For the first three, the function should be a logical predicate, either returning `TRUE` or `FALSE`. The predicate function does not need to be vectorised, as all three functions call it element by element.

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
  and so on. If `x = 1:5` then the result would be `f(f(f(f(1, 2), 3), 4),
  5)`. If `right = TRUE` then you get `f(1, f(2, f(3, f(4, 5))))`. You can
  also specify an `init` value in which case the operation is `f(f(f(f(f(init,
  1), 2),3), 4), 5)`

  Reduce is useful for implementing many types of recursive operations:
  merges, taking unique, finding smallest values.

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

* The array manipulation functions modify arrays to compute various margins or
  other summaries, or generalise matrix multiplication in various ways:
  `apply`, `outer`, `kronecker`, `sweep`, `addmargins`.

* The `**ply` functions of the `plyr` package which attempt to unify the base
  apply functions by cleanly separating based on the type of input they break
  up and the type of output that they produce.

### Mathematical higher order functions

Higher order functions arise often in mathematics. In this section we'll explore some of the built in mathematical HOF functions in R, as well as deriving some of our simpler approximations to learn more about programming with functions.

<!-- 
  find_args("package:stats", "^f$")
  find_args("package:stats", "upper")
-->

There are three functions that work with a 1d numeric function:

* `integrate`: integrate it over a given range
* `uniroot`: find where it hits zero over a given range
* `optmise`: find location of minima (or maxima)

And one function that works with a more general function

* `optim`: given a numeric function, find the location of a minima

We will develop simple version of `itegrate` to explore how we can use higher order functions to integrate a given function over a range.

<!-- * integral: midpoint, trapezoid, Simpson's rule, Boole's rule: two functional inputs: function to derive, and rule to use for approximation  -->

    trapezoid <- function(f, a, b) {
      (b - a) / 2 * (f(a) + f(b))
    }
    
    midpoint <- function(f, a, b) {
      
    }
    
Neither of these gives a terribly good result for anything other than the most simple functions.  We need to break up a function into smaller pieces and evaluate on those. 

    midpoint_composite

    trapezoid_composite
      
But notice that there's a lot of duplication these functions: they are basically the same apart from the internal rule used to integrate over a simple range.  Let's extract that rule into it's own component.

    composite

With this generalisation in place we can also generalise the approximation rules.  The Newton-Cotes
    
    # http://en.wikipedia.org/wiki/Newton%E2%80%93Cotes_formulas
    newton_cotes <- function(coef, open = FALSE) {
      n <- length(coef) + open
      
      fuction(f, a, b) {
        if (open) {
          points <- seq(a, b)
        }
        
        (b - a) * sum(f(points) * coef) / sum(coef)
      }
    }

The integrate function takes a somewhat different approach. Instead of making the approximation method better (and more complicated), it varies the position of the points so they are no longer evenly spaced.  This is known as quadrature and it has appealing theoretical properties.

### Statistical applications

* ecdf 
* maximum likelihood estimation


## List of functions

These components join together to make lists of functions surprisingly powerful.

Storing functions in lists is also useful for benchmarking, when you are comparing the performance of multiple different approaches to the same problem.  For example, if 

Using lapply etc. to generate lists of functions. Need helper function to actually call them elegantly.

    funs <- list(
      sum = sum,
      mean = mean,
      median = median
    )
    lapply(funs, function(x) x(1:10))

    callfun <- function(f, ...) f(...)
    lapply(funs, funcall, 1:10)

If we wanted to add parameters we have to duplicate a lot of code:

    funs2 <- list(
      sum = function(x, ...) sum(x, ..., na.rm = TRUE),
      mean = function(x, ...) mean(x, ..., na.rm = TRUE),
      median = function(x, ...) median(x, ..., na.rm = TRUE)
    )

How could we reduce this duplication?  A useful function here is `Curry` (named after a famous computer scientist Haskell Curry, not the food), which implements "partial function application".  What the curry function does is create a new function that passes on the arguments you specify.  A example will make this more clear:

    add <- function(x, y) x + y
    addOne <- funtion(x) add(x, 1)
    addOne <- Curry(add, y = 1)

A possible way to implement `Curry` is as follows:

    Curry <- function(FUN,...) { 
      .orig <- list(...)
      function(...) {
        args <- list(...)
        do.call(FUN, c(.orig, list(...)))
      }
    }

But implementing it like this prevents arguments from being lazily evaluated, so it has a somewhat more complicated implementation, basically working by building up an anonymous function by hand. You should be able to work out how this works after you've read the [[computing on the language]] chapter.  (Hopefully this function will be included in a future version of R.)

    Curry <- function(FUN, ...) {
      args <- match.call(expand.dots = FALSE)$...
      args$... <- as.name("...")
      
      env <- parent.frame()
      
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
    lapply(funs3, funcall, c(1:100, (1:50) * 100))

But that doesn't work because each function gets a promise to evaluate `t`, and that promise isn't evaluated until all of the functions are run.  To make it work you need to manually force the evaluation of t:

    funs3 <- lapply(trims, function(t) {force(t); Curry("mean", trim = t)})
    lapply(funs3, funcall, c(1:100, (1:50) * 100))

A somewhat simpler solution in this case is to use `mapply` which is a special version of lapply which allows you call vary multiple arguments, not just the first one.

    funs3 <- mapply(Curry, "mean", trim = trims,
      SIMPLIFY = FALSE, USE.NAMES = FALSE)
    names(funs3) <- trims
    lapply(funs3, funcall, c(1:100, (1:50) * 100))

A similar is approach is to use `plyr::mlply`
    
    plyr::mlply(data.frame(FUN = "mean", trim = trims, stringsAsFactors = F), Curry)
    ldply(funs3, funcall, c(1:100, (1:50) * 100))


## Summary

## Exercises

1. Write an `And` function that given two logical functions, returns a logical And of all their results. Extend the function to work with any number of logical functions. Write similar `Or` and `Not` functions.