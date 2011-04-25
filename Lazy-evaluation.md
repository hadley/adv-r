# Lazy loading

R has a number of features designed to help you do as little work as possible.  These are collectively known as lazy loading tools, and allow you to put off doing work as long as possible (so hopefully you never have to do it).  You are probably familiar with lazy function arguments, but there are a few other ways you can make operations lazy by hand.

Example creating a cache function that lazy loads its contents.

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

Delayed assign is particularly useful for doing expensive operations that
you're not sure you'll need. This is the essence of lazyness - put off doing
any work until the last possible minute.

To create a variable `x`, that is the 

  delayedAssign("x", a + b)

`delayedAssign` also provides two parameters that control where the evaluation happens (`eval.env`) and which in environment the variable is assigned in (`assign.env`).

To demonstrate the use of `delayedAssign` we're going to create a caching function that saves the results of an expensive operation to disk, and then we you next load it, it lazy loads the objects - this means if we cached something you didn't need, we only pay a small disk usage penalty, we don't use up any data in R.

Challenge: if we do it one file per object, how do we know whether the cache has been run before or not?

    cache <- function(code, cache_dir = ".cache") {
      if (!file.exists(cache_dir)) dir.create(cache_dir)
  
      # Create a new environment and evaluate the code in it, so we know
      # what was created
      parent <- parent.frame()
      res <- new.env(parent = parent)
      eval(substitute(code), res)
  
      # Iterate through each object, saving it to disk and copying it to the
      # parent environment
      objs <- ls(res)
      for(obj in objs) {
        assign(obj, res[[obj]], env = parent)
    
        file_path <- file.path(cache_dir, paste(obj, ".rds", sep =""))
        f <- file(file_path, "w")
        on.exit(close(f))
        serialize(res[[obj]], f)
      }
      
    }
    
    clear_cache <- function(cache_dir = ".cache") {
      file.remove(dir(cache_dir, full.names = T))
    }

Should print message when loading from cache.  Can we make caching robust enough that some objects can be retrieved from disk and some can be computed afresh?

Autoload is an example of this, it's a wrapper around `delayedAssign` for functions or data in a package - it makes R behave as if the package is loaded, but it doesn't actually load it (i.e. do any work) until you call one of the functions.  This is the way that data sets in most packages work - you can call (e.g.) `diamonds` after `library(ggplot2)` and it just works, but it isn't loaded into memory unless you actually use it.

## makeActiveBinding

`makeActiveBinding` goes one step further than `delayedAssign` by making a variable behave like a function.  Every time you access the object a function is run. This lets you do crazy things like:

      makeActiveBinding("x", function(...) rnorm(1), globalenv())
      x
      # [1] 0.4754442
      x
      # [1] -1.659971
      x
      # [1] -1.040291

