# Data stuctures

The table below shows the most important R data structures, organised by their dimensionality and whether they're homogeneous (all contents must be of the same type) or heterogeneous (the contents can be of different types):

|    | Homogenous | Heterogenous |
|----|------------|--------------|
| 1d | Atomic vector | List      |
| 2d | Matrix     | Data frame   |
| nd | Array      |              |

Given an arbitrary object in R, `str` (short for structure), is probably the most useful function: it will give a compact human readable description of any R data structure.

## Quiz

Take this short quiz to determine if you need to read this chapter or not:

* What are the three properties of a vector? (apart from its contents)
* What are the four common atomic vectors? What are the two rarer atomic vectors?
* How is a list different to a vector?
* How is a matrix different to a data frame?
* Can a data frame have a column that is a list?

## Vectors (1d)

The basic data structure in R is the vector, which comes in two basic flavours: atomic vectors and lists. Vectors have three properties: their `typeof()` (what it is), `length()` (how long it is) and `attributes()` (additional arbitrary metadata).  The most common attribute is `names()`.

Beware `is.vector()`: for historical reasons returns `TRUE` only if the object is a vector with no attributes apart from names.  Use `is.atomic(x) || is.list(x)` instead.

### Atomic vectors

Atomic vectors can be logical, integer, double (often called numeric), or character, or less commonly complex or raw.  Atomic vectors are typically created with `c`:

```R
logical <- c(T, FALSE, TRUE, FALSE)
numeric <- c(1, 2.5, 4.5)
# Note the L suffix which distinguishes numeric from integers
integer <- c(1L, 6L, 10L)
character <- c("these are", "some strings")
```

Atomic vectors are flat, and nesting `c()` just creates a flat vector:

```R
c(1, c(2, c(3, 4)))
```

#### Types and tests

Given a vector, you can determine what type it is using `typeof()`, or a specific tests: `is.character()`, `is.double()`, `is.integer()`, `is.logical()`, or generically `is.atomic()`.  

Beware `is.numeric()`: it's a general test for the "numberliness" of a vector, not a specific test for double vectors, which are commonly called numeric. `is.numeric()` is an S3 generic.

```R
typeof(integer)
is.integer(integer)
is.double(integer)
is.numeric(integer)

typeof(numeric)
is.integer(numeric)
is.double(numeric)
is.numeric(numeric)
```

#### Coercion

An atomic vector can only be of one type, so when you attempt to combine different types they will be __coerced__ into one type, picking the first matching class from character, double, integer and logical.

```R
c("a", 1)
```

When a logical vector is coerced to double or integer, `TRUE` becomes 1 and `FALSE` becomes 0.  This is very useful in conjunction with `sum()` and `mean()`

```
c("a", T)
c(1, T, F)
# Total number of TRUEs
sum(mtcars$cyl == 4)
# Proportion of TRUEs
mean(mtcars$cyl == 4)
```

You can also manually force one type of vector to another using a coercion function: `as.character()`, `as.double()`, `as.integer()`, `as.logical()`.

Coercion also happens automatically. Most mathematical functions (`+`, `log`, `abs`, etc.) will coerce to a double or integer, and most logical operations (`&`, `|`, `any`, etc) will coerce to a logical. You will usually get a warning message if the coercion might lose information. If there's any possible confusion, it's usually better to explicitly coerce.

### Lists

Lists are different from atomic vectors in that they can contain any other type of vector, including lists. You construct them using `list()` instead of `c()`

```R
x <- list(1:3, "a", c(T, F, T), c(2.3, 5.9))
str(x)
```

Lists are sometimes called __recursive__ vectors, because a list can contain other lists. This makes them fundamentally different from atomic vectors.

```R
x <- list(list(list(list())))
str(x)
is.recursive(x)
```

The `typeof()` a list is `list`, and you can test and coerce with `is.list()` and `as.list()`.

Lists are used to build up most more complicated datastructures in R: both data frames (described below), and linear models are lists:

```R
is.list(mtcars)
names(mtcars)
str(mtcars$mpg)

mod <- lm(mpg ~ wt, data = mtcars)
is.list(mod)
names(mod)
str(mod$qr)
```

## Attributes

All object can have additional arbitrary attributes. These can be thought of as a named list (although the names must be unique). Attributes can be accessed individually with `attr()` or all at once (as a list) with `attributes()`.

```R
y <- 1:10
attr(y, "comment") <- "This is a vector"
attr(y, "comment")
str(attributes(y))
```

The `structure()` returns a new object with modified attributes:

```R
structure(1:10, comment = "This is a vector")
```

By default, most attributes are lost when modifying a vector:

```R
y + 1
y[1]
sum(y)
```

The exceptions are for the most common attributes:

* `names()`, character vector of element names
* `class()`, used to implement the S3 object system.
* `dim()`, used to turn vectors into high-dimensional structures

When an accessor function is available, it's usually better to use that: use `names(x)`, `class(x)` and `dim(x)`, not `attr(x, "names")`, `attr(x, "class")`, and `attr(x, "dim")`.

## Higher dimensions

Atomic vectors and lists are the building blocks for higher dimensional data structures. Atomic vectors extend to matrices and arrays, and lists are used to create data frames.

## Matrices and arrays

A vector becomes a matrix (2d) or array (>2d) with the addition of a `dim()` attribute. They can be created using the `matrix()` and `array()` functions, or by using the replacement form of `dim()`:

```R
a <- matrix(1:6, ncol = 3)
b <- array(1:12, c(2, 3, 2))

c <- 1:6
dim(c) <- c(3, 2)
c
dim(c) <- c(2, 3)
c
```

`length()` generalises to `nrow()` and `ncol()` for matrices, and `dim()` for arrays. `names()` generalises to `rownames()` and `colnames()` for matrices, and `dimnames()` for arrays.

```R
length(a)
nrow(a)
ncol(a)
rownames(a) <- c("A", "B")
colnames(a) <- c("a", "b", "c")
a

length(b)
dim(b)
dimnames(b) <- list(c("one", "two"), c("a", "b", "c"), c("A", "B"))
b
```

`c()` generalises to `cbind()` and `rbind()` for matrices, and to `abind::abind()` for arrays.

You can test if an object is a matrix or array using `is.matrix()` and `is.array()`, or by looking at the length of the `dim()`. Because of the behaviour described above, `is.vector()` will return FALSE for matrices and arrays, even though they are implemented as vectors internally. `as.matrix()` and `as.array()` make it easy to turn an existing vector into a matrix or array.

Becareful of the difference between vectors, row vectors, column vectors, and 1d arrays:

```R
vec <- 1:3
col_vec <- matrix(1:3, ncol = 1)
row_vec <- matrix(1:3, nrow = 1)
arr <- array(1:3, 3)
```

They may print similarly, but will behave differently.

While atomic vectors are most commonly turned into matrices, the dimension attribute can also be set on lists to make list-matrices or list-arrays:

```R
l <- list(1:3, "a", T, 1.0)
dim(l) <- c(2, 2)
l
```

## Data frames

A data frame is a list of equal-length vectors. This makes it a 2d dimensional structure, so it shares the properties of a matrix and a list.  This means that a data frame has `names()`, `colnames()` and `rownames()`, although `names()` and `colnames()` are the same thing. The `length()` of a data frame is the length of the underlying list and so is the same as `ncol()`, `nrow()` gives the number of rows.

### Creation

You create a data frame using `data.frame()`, which takes named vectors as input:

```R
df <- data.frame(x = 1:3, y = c("a", "b", "c"))
str(df)
```

Beware the default behaviour of `data.frame()` to convert strings into factors. Use `stringAsFactors = FALSE` to suppress this behaviour:

```R
df <- data.frame(
  x = 1:3, 
  y = c("a", "b", "c"), 
  stringsAsFactors = FALSE)
str(df)
```

### Testing and coercion

Because a data frame is an S3 class, the type of a data frame reflects the underlying vector used to build it: `list`. Instead you can look at its `class()` or test for a data frame with `is.data.frame()`:

```R
typeof(df)
class(df)
is.data.frame(df)
```

### Combining data frames

You can combine data frames using `cbind()` and `rbind()`:

```R
cbind(df, data.frame(y = 4))
rbind(df, data.frame(x = 10))
```

When combining by column, the rows must match (or match with vector recycling), when combining by rows, the columns must match. If you want to combine data frames that may not have all the same rows, see `plyr::rbind.fill()`

It's a common mistake to try and create a data frame by `cbind()`ing vectors together:

```R
bad <- data.frame(cbind(a = 1:3, b = c("a", "b", "c")))
str(bad)
```

But this doesn't work because `cbind()` will create a matrix unless one of the arguments is already a data frame. The conversion rules for `cbind()` are complicated and best avoided by ensuring all the inputs are of the same type.

### Special columns

Since a data frame is a list of vectors, it is possible for a data frame to have a column that is a list:

```R
df <- data.frame(x = 1:3)
df$y <- list(1:2, 1:3, 1:4)
df
```

But you can't do this in one step because `data.frame()` uses special rules for processing lists:

```R
data.frame(x = 1:3, y = list(1:2, 1:3, 1:4))
```

Note that this is not recommended as many functions that work with data frames assume that you can not have a list in a column. Similarly, it's also possible (although not recommended) to have a column of a data frame that's a matrix or array.

As described in the following chapter, you can subset a data frame like a 1d structure (where it behaves like a list), or a 2d structure (where it behaves like a matrix).
