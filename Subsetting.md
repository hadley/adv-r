# Subsetting

R's subsetting operators are powerful and fast, and mastering them will give you much power. Subsetting operators allow you to express common data manipulation operations very succinctly, in a way few other languages can match (except perhaps APL). 

* Three subsetting operators.
* Six types of subsetting.
* Extensions to more than 1d.

The subsetting operators are a natural complement to `str()`. `str()` allows you to determine the structure of any arbitrary object, and the subsetting operators allow you to pull out the pieces that you're interested in.

All basic data structures can be teased apart using the subsetting operators: `[`, `'[[` and `$`.  (There is one additional subsetting operator for S4 `@` - behaves basically like `$` but returns an error instead of NULL.)

* lookup tables
* expanding aggregated counts
* ordering
* matching by hand
* logical vs integer, boolean vs sets


## 1d subsetting

It's easiest to explain subsetting for 1d first, and then show how it generalises to higher dimensions. You can subset by six different types of thing:

* blank: return everything (not useful in 1d, but very useful in 2d and higher)

* integers:
  * positive: return elements at those positions
  * zero: returns nothing (useful mainly for generating test data)
  * negative: return all elements except at those positions

* character vector: return elements with matching names

* logical vector: return all elements where the corresponding logical value is `TRUE`

(Note for positive integers that it's not just subsetting that you can do.)

## nd subsetting

For higher dimensions these are separated by commas.

You can also subset with matrices.

```R
mtcars[0, ]
mtcars[, 0]
```

## Simplifying vs. preserving subsetting

"If list x is a train carrying objects, then x[[5]] is the object in car 5; x[4:6] is a train of cars 4-6." --- [@RLangTip](http://twitter.com/#!/RLangTip/status/118339256388304896)


|                      | Simplifying | Preserving               |
|----------------------|-------------|--------------------------|
| Vectors              | `x[[1]]`    | `x[1]`                   |
| Matrices/data frames | `x[1:4, ]`  | `x[1:4, , drop = FALSE]` |

* For atomic vectors, simplifying means removing names. For lists, simplifying means returning the object inside the list, not a single element list
* For matrices and data frames, simplifying means reducing the dimensionality, if possible

### "$"

There's one very common used subsetting operator that we haven't mentioned yet: `$`. `$` is a shorthand operator, where `x$y` is basically equivalent to `x[["y"]]` (with one caveat, see below).  It's commonly used to access columns of a dataframe, e.g. `mtcars$cyl`, `diamonds$carat`. 

One common mistake with `$` is to try and use it when you have the name of a column stored in a variable:

```R
var <- "cyl"
# Doesn't work - mtcars$var translated to mtcars[["var"]]
mtcars$var

# Instead use [[
mtcars[[var]]
```

There's one important different between `$` and `[[` - `$` does partial matching:

```R
x <- list(abc = 1)
x$a
x[["a"]]
```

If you want to avoid this behaviour you can do `options(warnPartialMatchDollar = TRUE)` - but because this is a global option it will also affect any packages you have loaded.

## Applications

### Lookup tables

Character matching provides a powerful way to make lookup tables

### Ordering

```R
mtcars[order(mtcars$disp), ]
mtcars[, order(names(mtcars))]
```

### Expanding aggregated counts


### Matching and merging by hand

`match()`

### Boolean algebra vs sets

De Morgan's law

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

* X & Y: intersect(x, y)
* X | Y: union(x, y)
* X & !Y: setdiff(x, y)

* !X: setdiff(u, x)
* xor(X, Y): setdiff(union(x, y), intersect(x, y))

