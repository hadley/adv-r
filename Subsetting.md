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

Apart from `[`, there are two other subsetting operators: `'[[` and `$`. `'[[` is similar to `[`, except it only ever returns a single value, and it allows you to pull pieces out of a list. `$` is a useful shortcut for `'[[` combined with character subsetting.

`'[[` is most important for working with lists. `[` will only ever give you a list back - it never gives you the contents of the list:

>  "If list `x` is a train carrying objects, then `x'[[5]]` is 
> the object in car 5; `x[4:6]` is a train of cars 4-6." --- 
> [@RLangTip](http://twitter.com/#!/RLangTip/status/118339256388304896)

This means that you can only use `'[[` with positive integers and strings:

```R
a <- list(a = 1, b = 2)
a[[1]]
a[["a"]]

# If you do supply a vector it indexes recursively
b <- list(a = list(b = list(c = list(d = 1))))
b[[c("a", "b", "c", "d")]]
# Same as
b[["a"]][["b"]][["c"]][["d"]]
```

Because data frames are lists of their columns, you can use `'[[` to extract columns from data frames: `mtcars'[[1]]`, `mtcars'[["cyl"]]`.

Note that S3 and S4 objects can override the standard behaviour of `[` and `'[[` so they may behave differently for different types of objects, but generally it's a bad idea to redefine their behaviour.

The key distinction between the types of subsetting operators is whether they are simplifying or preserving.

### Simplifying vs. preserving subsetting

It's important to understand the distinction between simplifying and preserving subsetting. Simplifying subsets return the simplest possible data structure that can represent the output. They are useful interactively because they usually give you what you want.  Preserving subsetting keeps the structure of output the same as input, and is generally better for programming, because the result will always be of the same type. Omitting `drop = FALSE` when subsetting matrices and data frames is one of the most common sources of programming errors.

Unfortunately, how you switch between subsetting and preserving differs for different data types, as summarised in the table below.

|             | Simplifying         | Preserving                 |
|-------------|---------------------|----------------------------|
| Vector      | `x'[[1]]`           | `x[1]`                     | 
| List        | `x'[[1]]`           | `x[1]`                     | 
| Factor      | `x[1:4, drop = T]`  | `x[1:4]`                   | 
| Array       | `x[1, ]`, `x[, 1`]  | `x[1, , drop = F]`, `x[, 1, drop = F]` | 
| Data frame  | `x[, 1]`, `x[[1]]`  | `x[, 1, drop = F]`, `x[1]` | 

Preserving is the same for all data types: you get the same output as you do input. Preserving varies a little between data types, as described below:

* __atomic vector__: removes names

    ```R
    x <- c(a = 1, b = 2)
    x[1]
    x[[1]]
    ```

* __list__: return the object inside the list, not a single element list

    ```R
    y <- list(a = 1, b = 2)
    str(y[1])
    str(y[[1]])
    ```

* __factor__: drops any unnused levels

    ```R
    z <- factor(c("a", "b"))
    z[1]
    z[1, drop = TRUE]
    ```

* __matrix__ or __array__: if any of the dimensions has length 1, drops that dimension.

    ```R
    a <- matrix(1:4, nrow = 2)
    a[1, drop = FALSE]
    a[1, ]
    ```

* __data frame__: if output is a single column, returns a vector instead of a data frame

    ```R
    df <- data.frame(a = 1:2, b = 1:2)
    str(df[1])
    str(df[[1]])
    str(df[, "a", drop = FALSE])
    str(df[, "a"])
    ```

### `$`

`$` is a shorthand operator, where `x$y` is equivalent to `x'[["y", exact = FALSE]]`.  It's commonly used to access columns of a dataframe, e.g. `mtcars$cyl`, `diamonds$carat`. 

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

`[` and `'[[` also differ slightly in their behaviour when the index is out of bounds (OOB), e.g. trying to extract the fifth element of a length four vector, missing, or `NULL`.  Generally, it's preferable to use a function that throws an error when the input is incorrect so that mistakes aren't silently ignored.

| Operator | Index      | Atomic      | List          |
|----------|------------|-------------|---------------|
| `[`      | OOB        | `NA`        | `list(NULL)`  |
| `[`      | `NA_real_` | `NA`        | `list(NULL)`  |
| `[`      | `NULL`     | `x[0]`      | `list(NULL)`  |
| `'[[`    | OOB        | Error       | Error         |
| `'[[`    | `NA_real`  | Error       | `NULL`        |
| `'[[`    | `NULL`     | Error       | Error         |

<!--
```R
numeric()[1]
numeric()[NA_real_]
numeric()[NULL]
numeric()[[1]]
numeric()[[NA_real_]]
numeric()[[NULL]]

list()[1]
list()[NA_real_]
list()[NULL]
list()[[1]]
list()[[NA_real_]]
list()[[NULL]]
```
-->

If the input vector is named, then the names of OOB, missing, or `NULL` components will be `"<NA>"`.

### Exercises

* Given a linear model, e.g. `mod <- lm(mpg ~ wt, data = mtcars)`, extract the residual degrees of freedom. Extract the R squared from the model summary (`summary(mod))`)

## Subsetting + assignment

All subsetting operators can be combined with assignment to modify selected values of the input vector. 

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
# (where they're counted as false). 
x[c(T, F, NA)] <- 1

# This is mostly useful when modifying data frames
df <- data.frame(a = c(1, 10, NA))
df$a[df$a < 5] <- 0
df$a
```

Indexing with a blank can be useful in conjunction with assignment. Compare the following two expressions. In the first, `mtcars` will remain as a dataframe, in the second `mtcars` will become a list.

```R
mtcars[] <- lapply(mtcars, as.integer)
mtcars <- lapply(mtcars, as.integer)
```

### Modifying in place vs. modifying a copy

```R
library(pryr)
x <- 1:5
address(x)
x[2] <- 3L
address(x)

# Assigning in a real number forces conversion of x to real
x[2] <- 3
address(x)

# Modifying class or other attributes modifies in place
attr(x, "a") <- "a"
class(x) <- "b"
address(x)

# But making a reference to x elsewhere, will create a modified
# copy when you modify x - no longer modifies in place
y <- x
x[1] <- 2
address(x)
```

### Lists

You can use 

```R
x <- list(a = 1)
x[["b"]] <- NULL

y <- list(a = 1)
y["b"] <- list(NULL)

str(x)
str(y)
```

## Applications

The basic principles described above give rise to a wide variety of useful applications. Some of the most important are described below.

Many of these basic techniques are wrapped up into more concise functions (e.g. `subset()`, `merge()`, `plyr::arrange()`), nevertheless, it is useful to understand how they are implemented with basic subsetting alone, in case you come across a situation which can not be dealt with using pre-written functions.

### Lookup tables (character subsetting)

Character matching provides a powerful way to make lookup tables.  Say you want to convert abbreviations:

```R
x <- c("m", "f", "u", "f", "f", "m", "m")
lookup <- c("m" = "Male", "f" = "Female", u = NA)
lookup[x]

# Or with fewer output values
c("m" = "Known", "f" = "Known", u = "Unknown")[x]
```

If you don't want names in the result, use `unname()` to remove them.

### Matching and merging by hand (integer subsetting)

You may have a more complicated look up table which has multiple columns of information. Assume we have an vector of integer codes, and a table that describes their properties:

```R
codes <- sample(3, 10, rep = T)

info <- data.frame(
  code = 1:3,
  desc = c("Poor", "Good", "Excellent"),
  fail = c(T, F, F)
)
```

We want to duplicate the info table so that we have a row for each value in `codes`. We can do this in two ways, either using `match()` and integer subsetting, or `rownames()` and character subsetting:

```R
# Using match
id <- match(codes, info$code)
info[id, ]

# Using rownames
rownames(info) <- info$code
info[as.character(codes), ]
```

If you have multiple columns that you need to match on, you'll need to collapse them to a single column (with `interaction()`, `paste()`, or `plyr::id()`).  You can also use `merge()` or `plyr::join()`, which does the same thing for you - read the source code to see how.

### Ordering (integer subsetting)

`order()` takes a vector as input and returns an integer vector describing how the vector should be subset to put it in sorted order: 

```R
x <- c(2, 3, 1)
order(x)
x[order(x)]
```

To break ties, you can supply additional variables to `order()`, and you can change from ascending to descending order using `decreasing = TRUE`.  By default, any missing values will be put at the end of the vector: you can instead remove with `na.last = NA` or put at the front with `na.last = FALSE`.

For two and higher dimensions, `order()` and integer subsetting makes it easy to order either the rows or columns of an object:

```R
mtcars[order(mtcars$disp), ]
mtcars[, order(names(mtcars))]
```

More concise, but less flexible, functions are available for sorting vectors, `sort()`, and data frames, `plyr::arrange()`.

### Random samples/bootstrap (integer subsetting)

You can use integer indices to perform random sampling or bootstrapping of a vector or data frame. You use `sample()` to generate a vector of indices, and then use subsetting to access the values:

```R
mtcars[sample(nrow(mtcars), 10), ]
mtcars[sample(nrow(mtcars), 100, rep = T), ]
```

The arguments to `sample()` control the number of samples to extract, and whether or not sampling with replacement is done. If you just want to randomly reorder the rows, index with `sample(nrow(df))`.

### Expanding aggregated counts (integer subsetting)

Sometimes you get a data frame where identical rows have been collapsed into one, and a count column has been added. `rep()` | integer subsetting makes it easy to uncollapse the data, but subsetting with a repeated row index:

```R
df <- data.frame(x = c(2, 4, 1), y = c(9, 11, 6), n = c(3, 5, 1))
rep(1:nrow(df), df$n)
df[rep(1:nrow(df), df$n), ]
```

### Removing columns from data frame (character subsetting)

There are two ways to remove columns from a data frame. You can set individual columns to NULL:

```R
df <- data.frame(x = 1:3, y = 3:1, z = letters[1:3])
df$z <- NULL
```

Or you can subset to return only the columns you want:

```R
df <- data.frame(x = 1:3, y = 3:1, z = letters[1:3])
df[c("x", "y")]
```

If you know only the columns you don't want, use set operations to work out which colums to keep:

```R
df[setdiff(names(df), "z")]
```

### Selecting rows based on a condition (logical subsetting)

Logical subsetting is probably the mostly commonly used technique for extracting rows out of a data frame, because it allows you to easily combine conditions from multiple columns. Remember to use the vector boolean operators `&` and `|`, not the short-circuiting scalar operators `&&` and `||` which are more useful inside if statements.

```R
mtcars[mtcars$cyl == 4, ]
mtcars[mtcars$cyl == 4 & mtcars$gear == 4, ]
```

Don't forget [De Morgan's laws](http://en.wikipedia.org/wiki/De_Morgan's_laws), which can be useful when simplifying negations:

* `!(X & Y)` is the same as `!X | !Y`
* `!(X | Y)` is the same as `!X & !Y`

If you have a complicated expression like `!(X & !(Y | Z))` it will simplify to `!X | !!(Y|Z)`, then `!X | Y | Z`.

`subset()` is a specialised function for subsetting data frames, and saves some typing because you don't need to repeat the name of the data frame. You'll learn how it works in [[Computing on the language]].

```R
subset(mtcars, cyl == 4)
subset(mtcars, cyl == 4 & gear == 4)
```

### Boolean algebra vs sets (logical & integer subsetting)

It's useful to be aware of the natural equivalence between set operations (integer subsetting) and boolean algebra (logical subsetting). Using set operations is more effective when:

* You want to find the first (or last) `TRUE`

* You have very few `TRUE`s and very many `FALSE`s; a set representation may be faster and require less storage

`which()` allows you to convert from a boolean representation to a logical representation. There's no reverse operation in base R, but we can easily add one:

```R
x <- sample(10) < 4
which(x)

unwhich <- function(x, n) {
  out <- rep_len(FALSE, n)
  out[x] <- TRUE
  out
}
unwhich(which(x), 10)
```

Let's create two logical vectors and their integer equivalents and then explore the relationship between boolean and set operations.

```R
(x1 <- 1:10 %% 2 == 0)
(x2 <- which(x1))
(y1 <- 1:10 %% 5 == 0)
(y2 <- which(y1))

# & <-> intersect
x1 & y1
intersect(x2, y2)

# | <-> union
x1 | y1
union(x2, y2)

# X & !Y <-> setdiff(x, y)
x1 & !y1
setdiff(x2, y2)

# xor(X, Y) <-> setdiff(union(x, y), intersect(x, y))
xor(x1, x2)
setdiff(union(x, y), intersect(x, y))    
```

When first learning subsetting, a common mistake is to use `x[which(y)]` instead of `x[y]`.  Here the `which()` achieves nothing: it switches from logical to integer subsetting, but the result will be exactly the same. Also beware that `x[-which(y)]` is __not__ equivalent to `x[!y]`: `y` is all FALSE, `which(y)` will be `integer(0)` and `-integer(0)` is still `integer(0)`, so you'll get no values, instead of all values. In general, avoid switching from logical to integer subsetting unless you want (e.g.) the first or last `TRUE` value.

### Examples

* How would you take a random sample from the columns of a data frame? (This is used an important technique in random forests.) Can you simultaneously sample the rows and columns in one step?

* How would you select a random contiguous sample of m rows from a data frame containing n rows?
