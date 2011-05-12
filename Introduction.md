# Introduction

This book has grown out of over 10 years of programming in R, and constantly struggling to understand the best way of doing things. I would particularly like to thank the tireless contributors to R-help. There are too many that have helped me over the years to list individually, but I'd particularly like to thank Luke Tierney, John Chambers, and Brian Ripley for correcting countless of my misunderstandings and helping me to deeply understand R.

R is still a relatively young language, and the resources to help you understand it are still maturing. In my personal journey to understand R, I've found it particularly helpful to refer to resources that describe how other programming languages work.  I found the following two books particularly helpful:

* [The structure and interpretation of computer programs](http://mitpress.mit.edu/sicp/full-text/book/book.html) by Harold Abelson and Gerald Jay Sussman.

* [Concepts, Techniques and Models of Computer Programming](http://amzn.com/0262220695?tag=hadlwick-20) by Peter van Roy and Sef Haridi

It's also very useful to learn a little about LISP, because many of the ideas in R are adapted from lisp, and there are often good descriptions of the basic ideas, even if the implementation differs somewhat.

Part of the purpose of this book is so that you don't have to consult these original source, but if you want to learn more, this is a great way to develop a deeper understanding of how R works.

Other websites that helped me to understand smaller pieces of R are:

* [Getting Started with Dylan](http://www.opendylan.org/gdref/tutorial.html)
  for understanding S4

Other recommendations for becoming a better programmer:

* [The pragmatic programmer](http://amzn.com/020161622X?tag=hadlwick-20), by Andrew Hunt and David Thomas.

## Goal

This book describes the skills that I think you need to be an advanced R developer, producing reproducible code that can be used in a wide variety of circumstances.

* You are familiar with the fundamentals of R, so that you can represent
  complex data types and simplify the operations performed on them. You have a
  deep understanding of the language, and know how to override default
  behaviours when necessary

* You know how to produce packages to make your work available to a wider
  audience, and how to efficiently program "in the large", so you spend your
  time solving new problems not struggling with old code.

In the remainder of the introduction, I will give a very quick revision of the basic skills that you already posses.

## Programming styles in R

### Functional

* First class functions
* Pure functions: a goal, not a prerequisite
* Recursion: no tail call elimination. Slow
* Lazy evaluation: but only of function arguments. No infinite streams
* Untyped

### Object oriented

* Has three distinct OO frameworks built in to base. And more available in add on packages.  Two of the OO styles are built around generic functions, a style of OO that comes from lisp.

## Basics

### Data structures

The basic data structure in R is the vector, which comes in two basic flavours: atomic vectors and lists. Atomic vectors are logical, integer, numeric, character and raw. Common vector properties are mode, length and names:

    x <- 1:10
    mode(x)
    length(x)
    names(x)
    
    names(x) <- letters[1:10]
    x
    names(x)

Lists are different from atomic vectors in that they can contain any other type of vector. This makes them __recursive__, because a list can contain other lists. 

    x <- list(list(list(list())))
    x
    str(x)

`str` is one of the most important functions in R: it gives a human readable description of any R data structure.

Vectors can be extended into multiple dimensions. If 2d they are called matrices, if more than 2d they are called arrays.  Length generalises to `nrow` and `ncol` for matrices, and `dim` for arrays.  Names generalises to `rownames` and `colnames` for matrices, a `dimnames` for arrays.

    y <- matrix(1:20, nrow = 4, ncol = 5)
    z <- matrix(1:24, dims = c(3, 4, 5))

    nrow(y)
    rownames(y)
    ncol(y)
    colnames(y)

    dim(z)
    dimnames(z)

All vectors can also have additional arbitrary attributes - these can be thought of as a named list (although the names must be unique), and can be accessed individual with `attr` or all at once with `attributes`.  `structure` returns a new object with modified attributes.

Another extremely important data structure is the data.frame. A data frame is a named list with a restriction that all elements must be vectors of the same length. Each element in the list represents a column, which means that each column must be one type, but a row may contain values of different types.

### Subsetting

* Three subsetting operators.
* Five types of subsetting.
* Extensions to more than 1d.

All basic data structures can be teased apart using the subsetting operators: `[`, `'[[` and `$`. It's easiest to explain subsetting for 1d first, and then show how it generalises to higher dimensions. You can subset by 5 different things:

* blank: return everything
* positive integers: return elements at those positions
* negative integers: return all elements except at those positions
* character vector: return elements with matching names
* logical vector: return all elements where the corresponding logical value is `TRUE`

For higher dimensions these are separated by commas.

* `[` .  Drop argument controls simplification.
* `'[[` returns an element
* `x$y` is equivalent to `x'[["y"]]`

### Functions

Functions in R are created by `function`. They consist of an argument list (which can include default values), and a body of code to execute when evaluated. In R arguments are passed-by-value, so the only way a function can affect the outside world is through its return value:

    f <- function(x) {
      x$a <- 2
    }
    x <- list(a = 1)
    f()
    x$a

Functions can return only a single value, but this is not a limitation in practice because you can always return a list containing any number of objects.

When calling a function you can specify arguments by position, or by name:

    mean(1:10)
    mean(x = 1:10)
    mean(x = 1:10, trim = 0.05)

Arguments are matched first by exact name, then by prefix matching and finally by position.

There is a special argument called `...`.  This argument will match any arguments not otherwise specifically matched, and can be used to call other functions.  This is useful if you want to collect arguments to call another function, but you don't want to prespecify their possible names.

You can define new infix operators with a special syntax:

    "%+%" <- function(a, b) paste(a, b)
    "new" %+% "string"

And replacement functions to modify arguments "in-place":

    "second<-" <- function(x, value) {
      x[2] <- value
      x
    }
    x <- 1:10
    second(x) <- 5
    x

But this is really the same as 

    x <- "second<-"(x, 5)

and actual modification in place should be considered a performance optimisation, not a fundamental property of the language.

### Vocabulary

You should also have a decent [[vocabulary]].
