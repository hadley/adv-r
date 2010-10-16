# Lazy loading

R has a number of features designed to help you do as little work as possible.  These are collectively known as lazy loading tools, and allow you to put off doing work as long as possible (so hopefully you never have to do it).  You are probably familiar with lazy function arguments, but there are a few other ways you can make operations lazy by hand.

## Function arguments

By default, R function arguments are lazy - they're not evaluated when you call the function, but only when that argument is used:

    f <- function(x) {
      10
    }
    system.time(f(Sys.sleep(10)))
    # user  system elapsed 
    #    0       0       0  

If you want to ensure that an argument is evaluated you can use `force`: 

    f <- function(x) {
      force(x)
      10
    }
    system.time(f(Sys.sleep(10)))
    # user  system elapsed 
    #    0       0  10.001  

More technically, an unevaluated argument is called a __promise__ (also known as a thunk).  A promise is made up of two parts:

  * an expression giving the delayed computation (can be accessed with `substitute`)
  * the environment in which the expression is evaluated

You may notice this is rather similar to a closure with no arguments, and in many languages that don't have laziness built in like R, this is how you can implement laziness.

<!-- When is it useful? http://lambda-the-ultimate.org/node/2273 -->

Particularly useful in if statements:

      if (!is.null(a) && a > 0)

And you can use it to write functions that are not possible otherwise

      and <- function(a, b) {
        if (a) TRUE else b
      }
      and(!is.null(a), a > 0)

This function would not work without lazy evaluation because both `a` and `b` would always be evaluated, testing if `a > 0` even if `a` was NULL.

## delayedAssign

Many ways it could be implemented

      delay(x <- a + b)
      x <- delay(a + b)
      delay(x) <- a + b

But in R its written

      delayedAssign("x", a + b)

## Extensions 

### autoload

`autoload` is kind of like `delayedAssign` for every function in a package - it makes R behave as if the package is loaded, but it doesn't actually load it (i.e. do any work) until you call one of the functions.

### makeActiveBinding

`makeActiveBinding` goes one step further than `delayedAssign` by making a function behave like a variable.  Every time you access the object a function is run.  This lets you do crazy things like:

      makeActiveBinding("x", function(...) rnorm(1), globalenv())
      x
      # [1] 0.4754442
      x
      # [1] -1.659971
      x
      # [1] -1.040291

