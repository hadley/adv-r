# Functions

## Creating functions 

## Anonymous functions

In R, functions are objects in their own right. Unlike many other programming languages, functions aren't automatically bound to a name: they can exist independently. You might have noticed this already, because when you create a function, you use the usual assignment operator to give it a name. 

Given the name of a function as a string, you can find that function using `match.fun`. The inverse is not possible: because not all functions have a name, or functions may have more than one name. Functions that don't have a name are called __anonymous functions__. Anonymous functions are not that useful by themselves, so in this section you'll learn about their basic properties, and then see how they are used in subsequence sections.

The tool we use for creating functions is `function`. It is very close to being an ordinary R function, but it has special syntax: the last argument to the function is outside the call and provides the body of the new function.  If we don't assign the results of `function` to a variable we get an anonymous function:

    function(x) 3
    # function(x) 3

You can call anonymous functions, but the code is a little tricky to read because you must use parentheses in two different ways: to call a function, and to make it clear that we want to call the anonymous function `function(x) 3` not inside our anonymous function call a function called `3` (not a valid function name):

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


## Pure functions

Why pure functions are easy to reason about.

Ways in which functions can have side effects

## Primitive functions

## Lazy evaluation of function arguments

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

But note that `force` is just syntactic sugar.  The definition of force is:

    force <- function(x) x
    
The argument is evaluated in the environment in it was created, not the environment of the function:

        f <- function() {
          y <- "f"
          g(y)
        }    
        g <- function(x) {
          y <- "g"
          x
        }
        y <- "toplevel"
        f()
        # [1] "f"

More technically, an unevaluated argument is called a __promise__, or a thunk. A promise is made up of two parts:

* an expression giving the delayed computation, which can be accessed with
  `substitute` (see [[controlling evaluation|evaluation]] for more details)

* the environment where the expression was created and where it should be
  evaluated

You may notice this is rather similar to a closure with no arguments, and in many languages that don't have laziness built in like R, this is how you can implement laziness.

<!-- When is it useful? http://lambda-the-ultimate.org/node/2273 -->

This is particularly useful in if statements:

      if (!is.null(x) && y > 0)

And you can use it to write functions that are not possible otherwise

      and <- function(x, y) {
        if (!x) FALSE else y
      }
      
      a <- 1
      and(!is.null(a), a > 0)

      a <- NULL
      and(!is.null(a), a > 0)

This function would not work without lazy evaluation because both `x` and `y` would always be evaluated, testing if `a > 0` even if `a` was NULL.


### delayedAssign

Delayed assign is particularly useful for doing expensive operations that
you're not sure you'll need. This is the essence of lazyness - put off doing
any work until the last possible minute.

To create a variable `x`, that is the sum of the values `a` and `b`, but is not evaluated until we need, we use `delayedAssign`:

  a <- 1
  b <- 2
  delayedAssign("x", a + b)
  a <- 10
  x
  # [1] 12

`delayedAssign` also provides two parameters that control where the evaluation happens (`eval.env`) and which in environment the variable is assigned in (`assign.env`).


Autoload is an example of this, it's a wrapper around `delayedAssign` for functions or data in a package - it makes R behave as if the package is loaded, but it doesn't actually load it (i.e. do any work) until you call one of the functions.  This is the way that data sets in most packages work - you can call (e.g.) `diamonds` after `library(ggplot2)` and it just works, but it isn't loaded into memory unless you actually use it.

## Default arguments


