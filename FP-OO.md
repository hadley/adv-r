## Case study: checking function inputs and boolean algebra

We will explore function operators in the context of avoiding a common R programming problem: supplying the wrong type of input to a function.  We want to develop a flexible way of specifying what a function needs, using a minimum amount of typing. To do that we'll define some simple building blocks and tools to combine them. Finally, we'll see how we can use S3 methods for operators (like `+`, `|`, etc.) to make the description even less invasive.

The goal is to be able to succinctly express conditions about function inputs to make functions safer without imposing additional constraints.  Of course it's possible to do that already using `stopifnot()`:

```R
f <- function(x, y) {
  stopifnot(length(x) == 1 && is.character(x))
  stopifnot(is.null(y) ||
    (is.data.frame(y) && ncol(y) > 0 && nrow(y) > 0))
}
```

What we want to be able to express the same idea more evocatively.

```R
f <- function(x, y) {
  assert(x, and(eq(length, 1), is.character))
  assert(y, or(is.null,
    and(is.data.frame, and(gt(nrow, 0), gt(ncol, 0)))))
}
f <- function(x, y) {
  assert(x, length %==% 1 %&% is.character)
  assert(y, is.null %|%
    (is.data.frame %&% (nrow %>% 0) %&% (ncol %>% 0)))
}
f <- function(x, y) {
  assert(x, (length) == 1 && (is.character))
  assert(y, (is.null) || ((is.data.frame) & !empty))
}

is.string <- (length) == 0 && (is.character)
f <- function(x, y) {
  assert(x, (is.string))
  assert(y, (is.null) || ((is.data.frame) & !(empty)))
}
```

We'll start by implementation the `assert()` function. It should take two arguments, an object and a function.

```
assert <- function(x, predicate) {
  if (predicate(x)) return()

  x_str <- deparse(match.call()$x)
  p_str <- strwrap(deparse(match.call()$predicate), exdent = 2)
  stop(x_str, " does not satisfy condition:\n", p_str, call. = FALSE)
}
x <- 1:10
assert(x, is.numeric)
assert(x, is.character)
```


```R
and <- function(f1, f2) {
  function(...) {
    f1(...) && f2(...)
  }
}
or <- function(f1, f2) {
  function(...) {
    f1(...) || f2(...)
  }
}
not <- function(f1) {
  function(...) {
    !f1(...)
  }
}
```

```R
has_length <- function(n) {
  function(x) length(x) == n
}
or(and(is.character, has_length(4)), is.null)
```

It would be cool if we could rewrite to be:

```R
(is.character & has_length(4)) | is.null
```

but due to limitations of S3 it's not possible.  The closest we could get is:

```R
"%|%" <- function(e1, e2) function(...) e1(...) || e2(...)
"%&%" <- function(e1, e2) function(...) e1(...) && e2(...)

(is.character %&% has_length(4)) %|% is.null
```

Another approach would be do something like:

```R
Function <- function(x) structure(x, class = "function")
Ops.function <- function(e1, e2) {
  f <- function(y) {
    if (is.function(e1)) e1 <- e1(y)
    if (is.function(e2)) e2 <- e2(y)
    match.fun(.Generic)(e1, e2)
  }
  Function(f)
}
length <- Function(length)
length > 5
length * length + 3 > 5

is.character <- Function(is.character)
is.numeric <- Function(is.numeric)
is.null <- Function(is.null)

is.null | (is.character & length > 5)
```

If you wanted to make the syntax less invasive (so you didn't have to manually cast `functions` to `Functions`) you could maybe override the parenthesis:

```R
"(" <- function(x) if (is.function(x)) Function(x) else x
(is.null) | ((is.character) & (length) > 5)
```

If we wanted to eliminate the use of `()` we could extract all variables from the expression, look at the variables that are functions and then wrap them automatically, put them in a new environment and then call in that environment.

### Exercises

* Implement a corresponding `xor` function. Why can't you give it the most natural name?  What might you call it instead? Should you rename `and`, `or` and `not` to match your new naming scheme?

