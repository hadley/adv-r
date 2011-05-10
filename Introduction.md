# Introduction

This book has grown out of over 10 years of programming in R, and constantly struggling to understand the best way of doing things. I would particularly like to thank the tireless contributors to R-help. There are too many that have helped me over the years to list individually, but I'd particularly like to thank Luke Tierney and Brian Ripley for correcting countless of my misunderstandings and helping me to deeply understand R.

R is still a relatively young language, and the resources to help you understand it are still maturing. In my personal journey to understand R, I've found it particularly helpful to refer to resources that describe how other programming languages work.  I found the following two books particularly helpful:

* The structure and interpretation of computer programs.

* P. van Roy and S. Haridi. Concepts, Techniques and Models of Computer Programming. The MIT Press, 2004.

It's also very useful to learn a little about LISP, because many of the ideas in R are adapted from lisp, and there are often good descriptions of the basic ideas, even if the implementation differs somewhat.

Part of the purpose of this book is so that you don't have to consult these original source, but if you want to learn more, this is a great way to develop a deeper understanding of how R works.

Other websites that helped me to understand smaller pieces of R are:

* [Getting Started with Dylan](http://www.opendylan.org/gdref/tutorial.html)
  for understanding S4

This book describes the skills that I think you need to be an advanced R developer, producing reproducible code that can be used in a wide variety of circumstances.

* You are familiar with the fundamentals of R, so that you can represent
  complex data types and simplify the operations performed on them. You have a
  deep understanding of the language, and know how to override default
  behaviours when necessary

* You know how to produce packages to make your work available to a wider
  audience, and how to efficiently program "in the large", so you spend your
  time solving new problems not struggling with old code.

In the remainder of the introduction, I will give a very quick revision of the basic skills that you already posses.

## Data structures

The basic data structure in R is the vector, which comes in two basic flavours: atomic vectors and lists. Atomic vectors are logical, integer, numeric, character and raw. Vectors have names and mode. 

Lists are different from atomic vectors in that they can contain any other type of vector. This makes them __recursive__, because a list can contain other lists. 

Vectors can be extended into multiple dimensions. If 2d they are called matrices, if more than 2d they are called arrays.

      x <- 1:10
      y <- matrix(1:20, nrow = 4, ncol = 5)
      z <- matrix(1:24, dims = c(3, 4, 5))
      
      length(x)
      names(x)

      nrow(y)
      rownames(y)
      ncol(y)
      colnames(y)

      dim(z)
      dimnames(z)

All vectors can also have additional arbitrary attributes - these are stored in a named list.

Another important 2d data structure is a data.frame. A data frame is a named list with the restriction that all elements must be vectors of the same length. Each element in the list represents a column, which means that each column must be one type, but a row may contain values of different types.

## Subsetting

* Three subsetting operators.
* Five types of subsetting.
* Extensions to more than 1d.

All basic data structures can be teased apart using the subsetting operators: `[`, `[[` and `$`. It's easiest to explain subsetting for 1d first, and then show how it generalises to higher dimensions. You can subset by 5 different things:

* blank: return everything
* positive integers: return elements at those positions
* negative integers: return all elements except at those positions
* character vector: return elements with matching names
* logical vector: return all elements where the corresponding logical value is `TRUE`

For higher dimensions these are separated by commas.

* `[` .  Drop argument controls simplification.
* `[[` returns an element
* `x$y` is equivalent to `x[["y"]]`

## Functions

* copy on modify
* returning multiple objects
* ...

Calling a function:

* argument matching: exact, partial, position
* recursion (+ recall)

Special functions

* binary operators
* replacement functions

## Vocabulary

