# Subsetting

R's subsetting operators are powerful and fast, and mastering them will give you much power. Subsetting operators allow you to express common data manipulation operations very succinctly, in a way few other languages can match (except perhaps APL). Subsetting is a natural complement to `str()`: `str()` shows you the structure of any object, and subsetting allow you to pull out the pieces that you're interested in.

To master subsetting, you need to understand

* the three subsetting operators,
* the six types of subsetting, and 
* how to extend 1d subsetting to higher dimensions.

This chapter briefly reviews these important ideas, and then shows how you can apply them to solve a variety of real problems.

## 1d subsetting

It's easiest to explain subsetting for 1d first, and then show how it generalises to higher dimensions. All basic data structures can be teased apart using one of the three subsetting operators: `[`, `'[[` and `$`.  (There is one additional subsetting operator for S4 objects: `@`. It behaves like `$` but returns an error instead of NULL if the object does not exist.)

We'll start by exploring the use of `[`, as it's the most commonly used operator. Given a vector, `x`, you can subset by six different types of thing:

* blank: return everything (not useful in 1d, but very useful in 2d and higher)

* integers:
  * positive: return elements at those positions. (Note that by supplying an integer multiple times the corresponding value will be repeated.)
  * zero: returns nothing (useful mainly for generating test data)
  * negative: return all elements except at those positions

* character vector: return elements with matching names

* logical vector: return all elements where the corresponding logical value is `TRUE`

```R
# (Note that the decimal gives the original position)
x <- c(2.1, 4.2, 3.3, 5.4)

# Blank
x[]

# Real numbers are silently truncated to integers
x[c(2.1, 2.9)]

# Integers
x[c(3, 1)]
x[order(x)]
x[0]
x[-c(3, 1)]

# Logical vector
x[c(TRUE, TRUE, FALSE, FALSE)]
x[x > 3]

# Character vector
y <- setNames(x, letters[1:4])
y[c("d", "c", "a")]
```

## nd subsetting

Subsetting 2d and higher dimension structures is a basic generalisation of 1d subsetting, with each dimension separated by a comma.

```R
mtcars[0, ]
mtcars[, 0]
```

It is also possible to subset high-d datastructures with an integer matrix (or if named, a character matrix).  In this case, the result will be a vector of values:

```R
vals <- outer(1:5, 1:5, FUN = paste, sep = ",")
vals

select <- matrix(ncol = 2, byrow = 2, c(
  1, 1,
  3, 1,
  2, 4
))
vals[select]
```

## Simplifying vs. preserving subsetting

|         | Simplifying         | Preserving           |
|---------|---------------------|----------------------|
| Vector  | `x'[[1]]`           | `x[1]`               |
| Factor  | `x[1:4, drop = T]`  | `x[1:4]`             |
| Matrix  | `x[1:4, ]`          | `x[1:4, , drop = F]` |

* For atomic vectors, simplifying means removing names. For lists, simplifying means returning the object inside the list, not a single element list

  "If list `x` is a train carrying objects, then `x'[[5]]` is the object in car 5; `x[4:6]` is a train of cars 4-6." --- [@RLangTip](http://twitter.com/#!/RLangTip/status/118339256388304896)

* For matrices and data frames, simplifying means reducing the dimensionality, if possible

### "$"

There's one very common used subsetting operator that we haven't mentioned yet: `$`. `$` is a shorthand operator, where `x$y` is basically equivalent to `x'[["y"]]` (with one caveat, see below).  It's commonly used to access columns of a dataframe, e.g. `mtcars$cyl`, `diamonds$carat`. 

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

### Subsetting + assignment

```R
x <- 1:5
x[c(1, 2)] <- 2:3
x[-1] <- 4:1

x[c(1, NA)] <- c(1, 2)
x[c(T, F, NA)] <- 1
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