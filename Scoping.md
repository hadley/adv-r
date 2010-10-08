# Scoping, environments and closures

## Scoping

Scoping is the set of rules that govern how R looks up the value of a symbol, or name, how R goes from the symbol `x`, to its value `10` in the following example.

    x <- 10
    x
    # [1] 10

R has two types of scoping: __lexical scoping__, implemented automatically at the language level, and __dynamic scoping__, used in select functions to save typing during interactive analysis. This document describes lexical scoping, as well as environments (the underlying data structure) and closures (a useful consequence). Dynamic scoping is described in the context of [[controlling evaluation|Evaluation]].

## Basic rules

Lexical scoping is so called because it depends on the underlying lexical structure of the program, the way that functions are nested when they are written, not when they are called.  With lexical scoping, it's generally easy to figure out what value each name will have by looking at the definition of the function.

The following example illustrates the basic principle:

    x <- 5
    f <- function() { 
      y <- 10
      c(x = x, y = y)
    }
    f()
    #  x  y 
    #  5 10

Unlike some languages, R looks up at the values at run-time, not when the function is created:

    x <- 15
    f()
    #  x  y 
    # 15 10

If an name is defined inside a function, it will mask the top-level definition:

    g <- function() { 
      x <- 20
      y <- 10
      c(x = x, y = y)
    }
    f()
    #  x  y 
    # 20 10

The same principle applies regardless of the degree of nesting. See if you can predict what the following function will return before trying it out yourself.

    w <- 0
    f <- function() {
      x <- 1
      g <- function() {
        y <- 2
        h <- function() {
          z <- 3
          c(w = w, x = x, y = y, z = z)
        }
        h()
      }
      g()
    }
    f()

To better understand how scoping works, it's useful to know a little about environments, the data structure that powers scoping.

## Environments

An __environment__ is very similar to a list, with two important differences. Firstly, an environment has reference semantics: R's usual copy on modify rules do not apply. Secondly, an environment has a parent: if an object is not found in an environment, then R will look in its parent. Technically, an environment is made up of a __frame__, a collection of named objects (like a list), and link to a parent environment.

When a function is created, it gains a pointer to the environment where it was made. You can access this environment with the `environment` function. This environment may have access to objects that are not in the global environment: this is how [[namespaces]] work.

    environment(plot)
    ls(environment(plot), all = T)
    get(".units", environment(plot))
    get(".units")

Every time a function is called, a new environment is created to host execution. The following example illustrates that each time a function is run it gets a new environment:

    f <- function(x) {
      if (!exists("a")) {
        message("Defining a")
        a <- 1
      } else {
        a <- a + 1 
      }
      a
    }
    f()
    # Defining a
    # [1] 1
    f()
    # Defining a
    # [1] 1

The section on closures describes how to work around this limitation by using a parent environment that stays the same between runs.

Environments can also be useful in their own right, if you want to create a data structure that has reference semantics. This is not something that should be undertaken lightly: it will violate users expectations about how R code works, but it can sometimes be critical. The following example shows how to create an environment for this purpose.

    e <- new.env(hash = T, parent = emptyenv())
    f <- e

    exists("a", e)
    e$a
    get("a", e)
    ls(e)

    # Environments are reference object: R's usual copy-on-modify semantics
    # do not apply
    e$a <- 10
    ls(e)
    f$a

There are also a few special environments that you can access directly:

  * `globalenv()`: the user's workspace
  * `baseenv()`: the environment of the base package
  * `emptyenv()`: the ultimate ancestor of all environments

## Lazy evaluation

Promises

Arguments are lazily evaluated in their original environment.

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

## Closures 

A closure is a function written by another function. Closures are so called because they __enclose__ the environment of the parent function, and can access all variables and parameters in that function. This is useful because it allows us to have two levels of parameters. One level of parameters (the parent) controls how the function works. The other level (the child) does the work. The following example shows how can use this idea to generate a family of power functions. The parent function (`power`) creates child functions (`square` and `cube`) that actually do the hard work.

    power <- function(exponent) {
      function(x) x ^ exponent
    }

    square <- power(2)
    square(2) # -> [1] 4
    square(4) # -> [1] 8

    cube <- power(3)
    cube(2) # -> [1] 8
    cube(4) # -> [1] 64

The ability to manage variables at two levels also makes it possible to maintain the state across function invocations by allowing a function to modify variables in the environment of its parent. Key to managing variables at different levels is the double arrow assignment operator (`<<-`). Unlike the usual single arrow assignment (`<-`) that always works on the current level, the double arrow operator can modify variables in parent levels.

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

A more technical description is available in [Frames, Environments, and Scope in R and S-PLUS](http://cran.r-project.org/doc/contrib/Fox-Companion/appendix-scope.pdf). Section 2 is recommended as a good introduction to the formal vocabulary used in much of the R documentation. [Lexical scope and statistical computing](http://www.stat.auckland.ac.nz/~ihaka/downloads/lexical.pdf) gives more examples of the power and utility of closures.