# Data stuctures

## Vectors

The basic data structure in R is the vector, which comes in two basic flavours: atomic vectors and lists. Atomic vectors can be logical, integer, numeric, or character, or less commonly complex or raw. 

Vectors have three properties: `mode`, `length` and `names`:

    x <- 1:10
    mode(x)
    length(x)
    names(x)
    
    names(x) <- letters[1:10]
    x
    names(x)

## Lists

Lists are different from atomic vectors in that they can contain any other type of vector. This makes them __recursive__, because a list can contain other lists. 

    x <- list(list(list(list())))
    x
    str(x)

`str` is one of the most important functions in R: it gives a human readable description of any R data structure.

## Matrices and arrays

Vectors can be extended into multiple dimensions. If 2d they are called matrices, if more than 2d they are called arrays.  Length generalises to `nrow` and `ncol` for matrices, and `dim` for arrays.  Names generalises to `rownames` and `colnames` for matrices, a `dimnames` for arrays.

    y <- matrix(1:20, nrow = 4, ncol = 5)
    z <- array(1:24, dim = c(3, 4, 5))

    nrow(y)
    rownames(y)
    ncol(y)
    colnames(y)

    dim(z)
    dimnames(z)

All vectors can also have additional arbitrary attributes - these can be thought of as a named list (although the names must be unique), and can be accessed individual with `attr` or all at once with `attributes`.  `structure` returns a new object with modified attributes.

## Data frames

Another extremely important data structure is the data.frame. A data frame is a named list with a restriction that all elements must be vectors of the same length. Each element in the list represents a column, which means that each column must be one type, but a row may contain values of different types.

## Attributes

You can think of attributes as a named set that can be attached to any R object.

* `classs`
* `dim`, `dimnames`
* `names`

The class attribute is used to implement S3.

`attributes`, `attr`, `attr<-`