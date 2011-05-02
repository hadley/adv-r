# Scoping and environments

Scoping is the set of rules that govern how R looks up the value of a symbol, or name. That is, the rules that R applies to go from the symbol `x`, to its value `10` in the following example.

    x <- 10
    x
    # [1] 10

R has two types of scoping: __lexical scoping__, implemented automatically at the language level, and __dynamic scoping__, used in select functions to save typing during interactive analysis. This document describes lexical scoping, as well as environments (the underlying data structure). Dynamic scoping is described in the context of [[controlling evaluation|Evaluation]].

## Lexical scoping

Lexical scoping looks up symbol values using how functions are nested when they were written, not when they were called. With lexical scoping, you can figure out where the value of each variable will be looked up only by looking at the definition of the function, you don't need to know anything about how the function is called.

The "lexical" in lexical scoping doesn't correspond to the usual English definition ("of or relating to words or the vocabulary of a language as distinguished from its grammar and construction") but comes from the computer science term "lexing", which is part of the process that converts code represented as text to meaningful pieces that the programming language understands.  It's lexical in this sense, because you only need the definition of the functions, not how they are called.

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

If a name is defined inside a function, it will mask the top-level definition:

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

The new [[reference based classes|R5]], introduced in R 2.12, provide a more formal way to do this, with usual inheritance semantics.

There are also a few special environments that you can access directly:

  * `globalenv()`: the user's workspace
  * `baseenv()`: the environment of the base package
  * `emptyenv()`: the ultimate ancestor of all environments

The only environment that doesn't have a parent is emptyenv(), which is the eventual parent of every other environment. The most common environment is the global environment (globalenv()) which corresponds to the to your top-level workspace. The parent of the global environment is one of the packages you have loaded (the exact order will depend on which packages you have loaded in which order). The eventual parent will be the base environment, which is the environment of "base R" functionality, which has the empty environment as a parent.

Apart from that, the environment hierarchy is created by function definition. When you create a function, f, in the global environment, the environment of the function f will have the global environment as a parent.  If you create a function g inside f, then the environment of g will have have the environment of f as a parent, and the global environment as a grandparent.
