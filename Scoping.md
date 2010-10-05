# Scoping, environments and closures

## Scoping

Scoping refers to the set of rules than govern how we go from an object name, e.g. `x`, to the contents of that object, e.g. `10`. R has two types of scoping: __lexical scoping__, implemented automatically at the language level, and dynamic scoping, used in select functions to save typing during interactive analysis. Dynamic scoping is described in more detail in the context of [[controlling evaluation||Evaluation]].

## Environments

  * __frame__: collection of named objects (like a list)
  * __environment__: a frame plus a parent environment

An environment is very similar to a list, with two important differences. Firstly, an environment has reference semantics: R's usual copy on modify rules do not apply. Secondly, an environment has a parent: if an object is not found in an environment, then R will look in its parent.

  * `globalenv()`: the user's workspace
  * `baseenv()`: the environment of the base package
  * `emptyenv()`: the ultimate ancestor of all environments

`ls`, `get`, `assign`

    ls(environment(plot), all = T)
    get(".units", environment(plot))

    e <- new.env(hash = T, parent = emptyenv())
    f <- e
    
    e$a
    exists("a", e)
    get("a", e)
    ls(e)
    
    # Environments are reference object: R's usual copy-on-modify semantics
    # do not apply
    e$a <- 10
    f$a
    
    ls(e)
    
    parent.env(e)

## Lexical scoping

This is straightforward when the object exists in the local environment:

    x <- 10
    # 10
    x
    
    y
    # Error: object 'y' not found

If an object with that name doesn't exist in the current environment, R next looks in the parent environment. The parent environment is the environment in which the function was originally defined.

    
    f <- function() { 
      x
    }
    f()
    # [1] 10
    x <- 20
    f()
    # [1] 20

And this works regardless of how many functions down.  See if you can predict what the following function will return before trying it out yourself.

    w <- 0
    f <- function() {
      x <- 1
      g <- function() {
        y <- 2
        h <- function() {
          z <- 3
          c(w, x, y, z)
        }
        h()
      }
      g()
    }
    f()


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