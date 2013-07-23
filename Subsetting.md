# Subsetting

R's subsetting operators are powerful and fast, and mastering them will give you much power. Subsetting operators allow you to express common data manipulation operations very succinctly, in a way few other languages can match (except perhaps APL). Subsetting is a natural complement to `str()`: `str()` shows you the structure of any object, and subsetting allow you to pull out the pieces that you're interested in.

Subsetting is a hard to learn at first because you need to master a number of interrelated concepts:

* the three subsetting operators,
* the six types of subsetting, 
* how to extend 1d subsetting to higher dimensions, and
* using subsetting in conjunction with assignment

This chapter will introduce you to subsetting atomic vectors with `[`, and then gradually extend you knowledge, first to more complicated data types (like arrays and lists), and then to the other subsetting operators.

This chapter briefly reviews these important ideas, and then shows how you can apply them to solve a variety of real problems.

## Data types

It's easiest to explain subsetting first for atomic vectors, and then show how it generalises to higher dimensions and other more complicated objects. We'll start by exploring the use of `[`, as it's the most commonly used operator. The next section will discuss  `'[[` and `$`, the two other most important operators.

### Atomic vectors

Let's explore the different types of subsetting with a simple vector, `x`. Note that the value after the decimal point gives the original position.

```R
x <- c(2.1, 4.2, 3.3, 5.4)
```

There are five different types of vector we can use to subset with:

* __positive integers__: return elements at those positions.

    ```R
    x[c(3, 1)]
    x[order(x)]

    # Duplicated indices yield duplicated values
    x[c(1, 1)]

    # Real numbers are silently truncated to integers
    x[c(2.1, 2.9)]
    ```

* __negative integers__: return all elements except at those positions

    ```R
    x[-c(3, 1)]
    ```

    It's an error to mix positive and negative integers in a single subset

    ```R
    x[c(-1, 2)]
    ```

* a __logical vector__: return all elements where the corresponding logical value is `TRUE`. This is probably the most useful type of subsetting, because you will usually generate the logical vector with another expression. If the logical vector is shorter than the vector being subsetted, it will be _recycled_ to be the same length.

    ```R
    x[c(TRUE, TRUE, FALSE, FALSE)]
    x[x > 3]
    ```

    A missing value in the index always yields a missing value in the output:

    ```R
    x[c(T, T, NA, F)]
    ```

* __blank__: return the original vector unchanged. This is not useful in 1d, but we'll see shortly that it's very important for generalisation to 2d and higher. It can also be useful in conjunction with subsetting because it preserves object behaviour.

    ```R
    x[]
    ```

* __zero__: returns a zero-length vector. This is not something you'd usually do on purpose, unless you generating test data.

    ```R
    x[0]
    ```

If the vector is named, you can also subset by:

* a __character vector__: return elements with matching names

    ```R
    y <- setNames(x, letters[1:4])
    y[c("d", "c", "a")]

    # Like integer indices, you can repeat indices
    y[c("a", "a", "a")]

    # Names are always matched exactly, not partially
    z <- c(abc = 1, def = 2)
    z[c("a", "d")]
    ```

### Lists

Subsetting a list in exactly the same way as subsetting an atomic vector. Note that subsetting a list with `[` will always return a list: see below for the other subsetting operators that will let you pull out the components of the list.

### Matrices and arrays

Subsetting matrices (2d) and arrays (>2d) is a basic generalisation of 1d subsetting: you supply a 1d index for each dimension separated by a column. Blank now becomes useful, because you use it when (e.g.) you want to return all the rows or all the columns.

```R
a <- matrix(1:9, nrow = 3)
colnames(a) <- c("A", "B", "C")
a[1:2, ]
a[c(T, F, T), c("B", "A")]
a[0, -2]
```

Note that by default, `[` will simplify the results to their lowest possible dimensional representation. See the section on simplifying vs. preserving subsetting for how to avoid this.

Because matrices and arrays are implemented as vectors with special attributes, you can also subset them with a single vector, in which case they will behave like a vector.

You can also subset high-d data structures with an integer matrix (or if named, a character matrix). Each row in the matrix specifies the location of a value, with each column corresponding to a dimension in the array being subsetted. The result is a vector of values:

```R
vals <- outer(1:5, 1:5, FUN = "paste", sep = ",")
vals

select <- matrix(ncol = 2, byrow = 2, c(
  1, 1,
  3, 1,
  2, 4
))
vals[select]
```

### Data frames

Data frames possess characteristics of both lists and matrices. If you subset like a 1d data structure, they behave like lists; if you subset like a 2d data structure, they behave like matrices.

```R
df <- data.frame(x = 1:3, y = 3:1, z = letters[1:3])

# There are two ways to select columns from a data frame
# Like a list:
df[c("x", "z")]
# Like a matrix
df[, c("x", "z")]

# There's an important difference if you select a simple column
# because subsetting matrices simplifies by default, but subsetting
# lists does not.
df["x"]
df[, "x"]
```

### S3 objects

S3 objects are all made of atomic vectors, arrays and lists, so you can always pull apart an S3 object using the knowledge you gain from `str()` and the techniques described above.

### S4

There are also two additional subsetting operators that are needed for S4 objects: `@` (equivalent to `$`), and `slot()` (equivalent to `'[[`). `@` is also more restrictive that `$` in that it will return an error if the slot does not exist.  These are described in more detail in [[OO-essentials]].

### Exercises

* Explain the result of `x <- 1:5; x[NA]`.  Hint: why is it different to `x[NA_real_]`

* What does `upper.tri()` return? How does subsetting a matrix with it work? Do we need any additional subsetting rules?  

    ```R
    x <- outer(1:5, 1:5, FUN = "*")
    x[upper.tri(x)]
    ```

* Why does `mtcars[1:20]` return a error?

* Implement a function that extracts the diagonal entries from a matrix (it should behave like `diag(x)` when `x` is a matrix)

## Subsetting operators

Apart from `[`, there are two other subsetting operators: `'[[` and `$`. `'[[` is similar to `[`, except it only ever returns a single value, and it allows you to pull pieces out of a list. `$` is a useful shortcut for `[[` combined with character subsetting.

The key distinction between the types of subsetting operators is whether they are simplifying or preserving.

### Simplifying vs. preserving subsetting

It's important to understand the distinction between simplifying and preserving subsetting. Simplifying subsets return the simplest possible data structure that can represent the output. They are useful interactively because they usually give you what you want.  Preserving subsetting keeps the structure of output the same as input, and is generally better for programming, because the result will always be of the same type.

Unfortunately, how you switch between subsetting and preserving differs for different data types, as summarised in the table below.

|             | Simplifying         | Preserving           |
|-------------|---------------------|----------------------|
| Vector      | `x'[[1]]`           | `x[1]`               | 
| List        | `x'[[1]]`           | `x[1]`               | 
| Factor      | `x[1:4, drop = T]`  | `x[1:4]`             | 
| Array       | `x[1, ]`, `x[, 1`]  | `x[1, , drop = F]`   | 
| Data frame  | `x[, 1]`            | `x[, 1, drop = F]`   | 

The meaning of simplifying and preserving also differs a little:

* __atomic vector__: remove names

* __list__: return the object inside the list, not a single element list

    "If list `x` is a train carrying objects, then `x'[[5]]` is the object in car 5; `x[4:6]` is a train of cars 4-6." --- [@RLangTip](http://twitter.com/#!/RLangTip/status/118339256388304896)

* __factor__: drop an unnused levels

* __matrix__ or __array__: if any of the dimensions has length 1, drop that dimension.

* __data frame__: if output is a single column, return a vector instead of a data frame

### `$`

`$` is a shorthand operator, where `x$y` is basically equivalent to `x'[["y"]]` (with one caveat, see below).  It's commonly used to access columns of a dataframe, e.g. `mtcars$cyl`, `diamonds$carat`. 

One common mistake with `$` is to try and use it when you have the name of a column stored in a variable:

```R
var <- "cyl"
# Doesn't work - mtcars$var translated to mtcars[["var"]]
mtcars$var

# Instead use [[
mtcars[[var]]
```

There's one important different between `$` and `'[[` - `$` does partial matching:

```R
x <- list(abc = 1)
x$a
x[["a"]]
```

If you want to avoid this behaviour you can do `options(warnPartialMatchDollar = TRUE)` - but because this is a global option it will also affect any packages you have loaded.

### Missing/out of bounds indices

| Operator | Index      | Atomic      | List          |
|----------|------------|-------------|---------------|
| `[`      | OOB        | `NA`        | `list(NULL)`  |
| `[`      | `NA_real_` | `NA`        | `list(NULL)`  |
| `[`      | `NULL`     | `x[0]`      | `list(NULL)`  |
| `'[[`    | OOB        | Error       | Error         |
| `'[[`    | `NA_real`  | Error       | `NULL`        |
| `'[[`    | `NULL`     | Error       | Error         |

```R
x <- 1:2
y <- as.list(x)

x[3]
x[NA_real_]
x[NULL]
y[3]
y[NA_real_]
y[NULL]

x[[3]]
x[[NA_real_]]
x[[NULL]]
y[[3]]
y[[NA_real_]]
y[[NULL]]
```

If the input vector is named, then the names of missing components will be `"<NA>"`.

## Subsetting + assignment

```R
x <- 1:5
x[c(1, 2)] <- 2:3

# The length of LHS needs to match the RHS
x[-1] <- 4:1

# Note that there's no checking for duplicate indices
x[c(1, 1)] <- 2:3

# You can't combining integer indices with NA
x[c(1, NA)] <- c(1, 2)
# But you can combine logical indices with NA
# (where they're counted as false)
x[c(T, F, NA)] <- 1
```

Indexing with a blank can be useful in conjunction with assignment. Compare the following two expressions. In the first, `mtcars` will remain as a dataframe, in the second `mtcars` will become a list.

```R
mtcars[] <- lapply(mtcars, as.integer)
mtcars <- lapply(mtcars, as.integer)
```

## Applications

The basic principles described above give rise to a wide variety of useful applications. Some of the most important are described below.

Many of these basic techniques are wrapped up into more concise functions (e.g. `subset()`, `merge()`, `plyr::arrange()`), nevertheless, it is useful to understand how they are implemented with basic subsetting alone, in case you come across a situation which can not be dealt with using pre-written functions.

### Lookup tables

Character matching provides a powerful way to make lookup tables.  Say you want to convert abbreviations:

```R
x <- c("m", "f", "u", "f", "f", "m", "m")
lookup <- c("m" = "Male", "f" = "Female", u = NA)
lookup[x]

c("m" = "Known", "f" = "Known", u = "Unknown")[x]
```

If you don't want the names, you can use `unname()` to strip them.

### Ordering

```R
mtcars[order(mtcars$disp), ]
mtcars[, order(names(mtcars))]
```

### Random samples/bootstrap

```R
mtcars[sample(nrow(mtcars), 10), ]
mtcars[sample(nrow(mtcars), 100, rep = T), ]
```

### Expanding aggregated counts

```R
df <- data.frame(x = c(2, 4, 1), n = c(3, 5, 1))
rep(1:nrow(df), df$n)
df[rep(1:nrow(df), df$n), ]
```

### Matching and merging by hand

`match()`

### Boolean algebra vs sets

There's a natural equivalence between sets operations and boolean algebra.

```R
X <- sample(10) < 4
x <- which(x)
Y <- sample(10) < 4
x <- which(y)

X & Y
intersect(x, y)
X | Y
union(x, y)
```

Why choose one or the other:

* In set representation, easier to find first (or last)
* For sparse data (i.e. few `TRUE`s) set representation may be much faster and require much less storage

* `X & Y`: `intersect(x, y)`
* `X | Y`: `union(x, y)`
* `X & !Y`: `setdiff(x, y)`

* `!X`: `setdiff(u, x)`
* `xor(X, Y)`: `setdiff(union(x, y), intersect(x, y))`

Also, remember [De Morgan's laws](http://en.wikipedia.org/wiki/De_Morgan's_laws), which can be useful when simplifying negations:

* `!(X && Y)` is the same as `!X || !Y`
* `!(X || Y)` is the same as `!X && !Y`

Note that `x[which(y)]` is suboptimal, and should be replaced by `x[y]`. `x[-which(y)]` is especially problematic as an alternative to `x[!y]` because if `y` is all FALSE, `which(y)` will be `integer(0)` and `-integer(0)` is still `integer(0)`, so you'll get no values, instead of all values.  In general, avoid `which()` unless you want a (e.g.) the first or last `TRUE` value.

It is especially problematic if 