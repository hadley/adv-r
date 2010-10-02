# R scoping rules

Scoping refers to the set of rules than govern how we go from an object name, e.g. "x", to the contents of that object, e.g. 10. R has two types of scoping: __lexical scoping__,  implemented automatically at the language level, and non-standard scoping, used in select functions to save typing during interactive analysis.

Vocab:

  * frame: collection of named objects (like a list)
  * environment: a frame plus a parent environment
  *

## Other important environments

  * `globalenv()`: the user's workspace
  * `baseenv()`: the environment of the base package
  * `emptyenv()`: the ultimate ancestor of all environments

## Lexical scoping

This is straightforward when the object exists in the local environment:

    x <- 10
    # 10
    x

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
