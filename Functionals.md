# Functionals 

<!--  
  library(pryr)
  library(stringr)
  find_funs("package:base", fun_calls, fixed("match.fun"))
  find_funs("package:base", fun_args, ignore.case("^(fun|f)$"))
-->

"To become significantly more reliable, code must become more transparent. In particular, nested conditions and loops must be viewed with great suspicion. Complicated control flows confuse programmers. Messy code often hides bugs."
--- [Bjarne Stroustrup](http://www.stroustrup.com/Software-for-infrastructure.pdf)

Higher-order functions encompass any functions that either take a function as an input or return a function as output. We've seen our first example of a higher-order function, the closures, functions returned by another function. The complement to a closure is a __functional__, a function that takes a function as an input and returns a vector as output. 

In R, functionals are commonly used as a way to eliminate for loops. 


For loops have a bad rap in R, and many programmers try to eliminate them at all costs. We'll explore their speed in the [[performance]] chapter; but it's not as bad as many people believe. The real downside of for loops is that they're not very expressive: the only convey that you're iterating over something, not the higher-level task you're trying to achieve. Using functionals, allows you to more clearly express express what you're trying to achieve. As a side-effect, because existings functionals are used by many people, they are likely to have fewer errors and be more performant than a one-off for loop that you create. For example, most functionals in base R are written in C for high-performance.

We've seen one functional already, `lapply()`, which applies a function to each element of a list, storing the results in a list. It's informative to look at a pure R implementation:

```R
lapply2 <- function(x, f, ...) {
  out <- vector("list", length(x))
  for (i in seq_along(x)) {
    out[[i]] <- f(x[[i]], ...)
  }
  out
}
```

`lapply()` is just a wrapper around a common for loop pattern. The art of using functionals is to recognise what common looping patterns are implemented in existing base functionals, and then use them instead of loops. Once you've mastered the existing functionals, the next step is to start writing your own: if you discover you're duplicating the same looping pattern in many places, you should extract it out into its own function.  Once we've talked about the most important R functionals, we'll introduce some other loop patterns and start writing our own.

When using functionals that encapsulate for loops, it's useful to remember that there's usually three ways to loop over an object:

```R
for(x in xs) {}
for(i in seq_along(xs)) {}
for(nm in names(xs)) {}
```

And similarly, there are three ways to use `lapply()` with an object:

```R
lapply(xs, function(xs) {})
lapply(seq_along(xs), function(i) {})
lapply(names(xs), function(nm) {})
```

The last two ways are particularly useful because they give you both the position of the object (`i`, `nm`) and its value (`x[[i]]`, `x[[nm]]`).  If you're struggling to solve a problem using one form, you might find it easier with a different way.

In this chapter, you'll learn:

* mathematical functionals
* * common alternatives to for loops in base R
* more specialised alternatives to for loops in other packages
* how to create your own functionals
* when it's ill-advised to replace a for loop

## Mathematical functionals

<!-- 
  find_args("package:stats", "^f$")
  find_args("package:stats", "upper")
-->

Functionals are common in mathematics. In this section we'll explore some of the built in mathematical HOF functions in R. There are three functions that work with a 1d numeric function:

* `integrate`: integrate it over a given range
* `uniroot`: find where it hits zero over a given range
* `optimise`: find location of minima (or maxima)

(You may wonder how these fit in with the theme of removing loops - internally all of these mathematical functions use loops to implement the underlying numeric algorithms: you could implement them all by hand by writing your own loops)

Let's explore how these are used with a simple function:

```R
integrate(sin, 0, pi)
uniroot(sin, pi * c(1 / 2, 3 / 2))
optimise(sin, c(0, 2 * pi))
optimise(sin, c(0, pi), maximum = TRUE)
```

There is one function that works with a more general n-dimensional numeric function, `optim`, which finds the location of a minima. 

In statistics, optimisation is often used for maximum likelihood estimation. Maximum likelihood estimation is a natural match to closures because the arguments to a likelihood fall into two groups: the data, which is fixed for a given problem, and the parameters, which will vary as we try to find a maximum numerically. This naturally gives rise to an approach like the following:

```R
# Negative log-likelihood for Poisson distribution
poisson_nll <- function(x) {
  n <- length(x)
  function(lambda) {
    n * lambda - sum(x) * log(lambda) # + terms not involving lambda
  }
}

nll1 <- poisson_nll(c(41, 30, 31, 38, 29, 24, 30, 29, 31, 38)) 
nll2 <- poisson_nll(c(6, 4, 7, 3, 3, 7, 5, 2, 2, 7, 5, 4, 12, 6, 9)) 

optimise(nll1, c(0, 100))
optimise(nll2, c(0, 100))
```

`optim` is a high-dimension alternative to `optimise`: it takes a numerical vector as input.

`Rvmmin` is a pure R implementation of `optim`.

### Fixed points

There are better treatments of numerical optimisation elsewhere, but there are a couple of important threads that make applying loops here important.

* Need to give up at some point: either after too many iterations, or when difference (either absolute or relative is small)

## Common alternatives to for loops

The following sections discuss:

* `sapply()` and `vapply()`, variants of `lapply()` that produce vectors, matrices and arrays as output, instead of lists
* `Map()` and `mapply()` which iterate over multiple input data structures in parallel

The three most important HOFs you're likely to use are from the `apply` family. The family includes `apply`, `lapply`, `mapply`, `tapply`, `sapply`, `vapply`, and `by`.

### `sapply` and `vapply`

`sapply()` and `vapply()` are very similar to `lapply()` except they will simplify their output to produce an atomic vector. `sapply()` will guess the output, while with `vapply()` you have to be explicit. `sapply()` is useful for interactive use because it's a minimum amount of typing, but if you use it inside your functions you will get weird errors if you supply the wrong type of input. `vapply()` is more verbose, but gives more informative errors messages (it will never fail silently), so is better suited for programming with.

```R
sapply(mtcars, is.numeric)
vapply(mtcars, is.numeric, logical(1))
```

A pure R implementation of `sapply` and `vapply` follows:

```R
sapply2 <- function(x, f, ...) {
  res <- lapply2(x, f, ...)
  simplify2array(res)
}

vapply2 <- function(x, f, f.value, ...) {
  out <- matrix(rep(f.value, length(x)), nrow = length(x))
  for (i in seq_along(x)) {
    res <- f(x, ...)
    stopifnot(
      length(res) == length(f.value), 
      typeof(res) == typeof(f.value)
    )
    out[i, ] <- res
  }
  out
}
```

The real implementations of `vapply()` is somewhat more complicated because it takes more care with error messages, and is implemented in C for efficiency.

* `Filter`: returns a new vector containing only elements where the predicate is `TRUE`.


### `Map` (and `mapply`)

`Map` is useful when you have multiple sets of inputs that you want to iterate over in parallel. `Map(f, x, y, z)` is equivalent to

```R
for(i in seq_along(x)) {
  output[[i]] <- f(x[[i]], y[[i]], z[[i]])
}
```

In comparison with `lapply()`, `Map()` iterates over all of its arguments, not just the first one:

```R
a <- c(1, 2, 3)
b <- c("a", "b", "c")

str(lapply(FUN = list, a, b))
str(Map(f = list, a, b))
```

What if you have arguments that you don't want to be split up? Use an anonymous function!

```R
Map(function(x, y) f(x, y, zs), xs, ys)
```

You may be more familiar with `mapply()` than `Map()`. I prefer `Map()` because:

* it is equivalent to `mapply` with `simplify = FALSE`, which is almost always what you want. 

* `mapply` also has the `MoreArgs` arguments with which you can provide a list of extra arguments that will be supplied as is to each call; however this breaks R's usual lazy evaluation semantics, and is better done with an anonymous function.

In brief, `mapply()` is much more complicated for little gain.

### Matrix operations

```R
# apply
for(i in seq_len(dims(x)[i])) {
  out[i, ,] <- f(x[i, , ])
}
simplify2array(out)

# sweep
for(i in ) {
  x[i , , ] <- f(x[i , , ], y[i])
}

# outer
out <- matrix(nrow = length(x), ncol = length(y))
for (i in seq_along(x)) {
  for(j in seq_along(y)) {
    out[i, j] <- f(x, y)
  }
}
```

### Other functions

* `Find()`: return the first element that matches the predicate (or the last element if `right = TRUE`).

  ```R
  for(i in seq_along(x)) {
    if (f(x[[i]])) return(x[[i]])
  }
  ```

* `Position()`: return the position of the first element that matches the predicate (or the last element if `right = TRUE`).

    ```R
    for(i in seq_along(x)) {
      if (f(x[[i]])) return(i)
    }
    ```

* `tapply()`: apply function to subsets of input vector as defined by grouping variable:

    ```R
    tapply2 <- function(x, group, f, ...) {
      ugroup <- unique(group)
      out <- vector("list", length(ugroup))
      for (g in seq_along(ugroup)) {
        out[[g]] <- f(x[group == ugroup[g]])
      }  
      out
    }
    tapply2(1:10, rep(1:2, each = 5), mean)
    ```

* `Reduce()`: recursively reduces a vector to a single value by first calling `f` with the first two elements, then the result of `f` and the second element and so on. 

    ```R
    out <- x[[1]]
    for(i in seq(2, length(x)) {
      out <- f(out, x[[i]])
    }
    ```

    Reduce is useful for implementing many types of recursive operations: merges, finding smallest values, intersections, unions.

## Important functionals in other packages

Each of these functions processes breaks up a data structure in some way, applies the function to each piece and then joins them back together again. The `**ply` functions of the `plyr` package which attempt to unify the base apply functions by cleanly separating based on the type of input they break up and the type of output that they produce. 

* `rollmean`

## Loops that can't be replaced by functionals

That there are wide class of for loops that can not be simplified to a single existing function call in R. 

* rolling/running computations

    ```R
    out <- numeric(length(x) - n + 1)
    for(i in n:length(x)) {
      out[i] <- mean(x[i:(i + n - 1)])
    }
    ```

* Relationships that a defined recursively, like exponential smoothing.
    
```R
exps <- function(x, alpha) {
  s <- numeric(length(x) + 1)
  for (i in seq_along(s)) {
    if (i == 1) {
      s[i] <- x[i]
    } else {
      s[i] <- alpha * x[i - 1] + (1 - alpha) * s[i - 1]
    }
  }
}
```

Sometimes it's possible to [solve the recurrence relation](http://en.wikipedia.org/wiki/Recurrence_relation#Solving). In this case, it's possible to rewrite in terms of `i`:

```R
exps1 <- function(x, alpha) {
  function(t) {
    c(rep(alpha, t), 1) * x[-t] * (1 - alpha)^(rev(seq_along(head)))
  }
}
lapply(seq_along(x), expsm1(x, alpha = 0.5))
```



Another example that is difficult to 

```R
i <- 0
while(TRUE) {
  if (runif(1) > 0.9) break
  i <- i + 1
}
```


* modifying multiple elements in each cycle

* you don't know how long the answer will be. Examples: how long until you roll two sixes.  
 
* `while(TRUE) {if (condition) break;}


* you need to refer to multiple elements in the vector. e.g. `diff`, Fibonacci series, recursion.  Or you're doing a simulation where new values are based on the old.

It's certainly possible to write functions that encapsulate these types of loops, but they are not built in to R.  Whether or not it's worth building your own function depends on how often you'll be using, and how much more expressive a better function name would be.

## Writing your own functionals


### Exercises

* Implement the `arg_max` function. It should take a function, and a vector of inputs, returning the elements of the input where the function returns the highest number. For example, `arg_max(-10:5, function(x) x ^ 2)` should return -10. `arg_max(-5:5, function(x) x ^ 2)` should return `c(-5, 5)`.  Also implement the matching `arg_min`.
