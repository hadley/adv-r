# Functionals 

<!--  
  library(pryr)
  library(stringr)
  find_funs("package:base", fun_calls, fixed("match.fun"))
  find_funs("package:base", fun_args, ignore.case("^(fun|f)$"))
-->

"To become significantly more reliable, code must become more transparent. In particular, nested conditions and loops must be viewed with great suspicion. Complicated control flows confuse programmers. Messy code often hides bugs."
--- [Bjarne Stroustrup](http://www.stroustrup.com/Software-for-infrastructure.pdf)

## Introduction

Higher-order functions encompass any functions that either take a function as an input or return a function as output. We've seen our first example of a higher-order function, the closures, functions returned by another function. The complement to a closure is a __functional__, a function that takes a function as an input and returns a vector as output. 

Here's a simple functional, it takes an input function and calls it with some random input:

```R
randomise <- function(f) f(runif(1e3))
randomise(mean)
randomise(sum)
```

Functionals effectively offer an alternative to for loops for many problems. For loops have a bad rap in R, and many programmers try to eliminate them at all costs. We'll explore their speed in the [[performance]] chapter; but it's not as bad as many people believe. The real downside of for loops is that they're not very expressive: the only convey that you're iterating over something, not the higher-level task you're trying to achieve. Using functionals, allows you to more clearly express express what you're trying to achieve. As a side-effect, because existings functionals are used by many people, they are likely to have fewer errors and be more performant than a one-off for loop that you create. For example, most functionals in base R are written in C for high-performance.

In this chapter, you'll learn about:

* Mathematical functionals, like `integrate`, `uniroot`, and `optim`.

* Functionals that encapulsate a common pattern of for-loop use, like `lapply`, `vapply` and `Map`.

* Functionals for manipulating common R data structures, like `apply`, `split`, `tapply` and the plyr package.

* Popular functionals from other programming languages, like `Map`, `Reduce` and `Filter`

* how to convert a loop to a functionals, and when you shouldn't do it.

Focus in this chapter is on expression/clarity of intent.  Once you have clear, correct code you can focus on optimising it use the techniques in the [[Performance]] chapter.

## Mathematical functionals

<!-- 
  find_args("package:stats", "^f$")
  find_args("package:stats", "upper")
-->

Functionals are common in mathematics. 

limit, inverse, definite integral, 

In this section we'll explore some of the built in mathematical HOF functions in R. There are three functions that work with a 1d numeric function:

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

First, we create a function that computes the negative log likelihood (it's common to use the negative in R since optim defaults to findinging the minimum)

```R
poisson_nll <- function(x) {
  n <- length(x)
  function(lambda) {
    n * lambda - sum(x) * log(lambda) # + terms not involving lambda
  }
}
```

```R

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

### Exercises

* Implement the `arg_max` function. It should take a function, and a vector of inputs, returning the elements of the input where the function returns the highest number. For example, `arg_max(-10:5, function(x) x ^ 2)` should return -10. `arg_max(-5:5, function(x) x ^ 2)` should return `c(-5, 5)`.  Also implement the matching `arg_min`.

## For-loop functions: `lapply` and friends

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

The following sections discuss:

* `sapply()` and `vapply()`, variants of `lapply()` that produce vectors, matrices and arrays as output, instead of lists
* `Map()` and `mapply()` which iterate over multiple input data structures in parallel

The three most important HOFs you're likely to use are from the `apply` family. The family includes `apply`, `lapply`, `mapply`, `tapply`, `sapply`, `vapply`, and `by`.

### Vector output: `sapply` and `vapply`

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

### Multiple inputs: `Map` (and `mapply`)

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


### Rolling computations

```R
out <- numeric(length(x) - n + 1)
for(i in n:length(x)) {
  out[i] <- f(x[i:(i + n - 1)], ...)
}
```

You might notice that this is pretty similar to what `vapply` does, and in fact we could rewrite it as

```R
g <- function(i) f(x[i:(i + n - 1)], ...)
vapply(n:length(x), g)
```

which is effectively how `zoo::rollapply` implements it. (Albeit with a lot more features and error checking)

```R
rollapply(x, n, f, ...)
```

### Parallelisation

No side effects means that functions can be run in any order, and potential on different cores or different computers.

Another advantage of using common functionals is that parallelised versions may be available: `mclapply` and `mcMap`.



## Data structure 

### Group apply

`tapply()`: apply function to subsets of input vector as defined by grouping variable:

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

Can also think of it as a combination of split and sapply:

```R
tapply3 <- function(x, group, f, ...) {
  pieces <- split(x, group)
  sapply(pieces, group)
}
```

* `tapply(..., simplify = F)` is equivalent to `split()` + `lapply()`
* there's no equivalent to `split()` + `vapply()`.  Should there be? When would it be useful?
* `by` is a thin wrapper around 

```R
split <- function(x, group) {
  ugroup <- unqiue(group)
  out <- vector("list", length(ugroup))
  for (g in seq_along(ugroup)) {
    out[[g]] <- x[group == ugroup[g]]
  }  
  out
}
```

### Data frames

Each of these functions processes breaks up a data structure in some way, applies the function to each piece and then joins them back together again. The `**ply` functions of the `plyr` package which attempt to unify the base apply functions by cleanly separating based on the type of input they break up and the type of output that they produce. 

### Matrix and array operations

apply
```R
for(i in seq_len(dims(x)[i])) {
  out[i, ,] <- f(x[i, , ])
}
simplify2array(out)
```

sweep
```R
for(i in ) {
  x[i , , ] <- f(x[i , , ], y[i])
}

outer
```
out <- matrix(nrow = length(x), ncol = length(y))
for (i in seq_along(x)) {
  for(j in seq_along(y)) {
    out[i, j] <- f(x, y)
  }
}
```

## Functional programming

<!-- 
  http://www.haskell.org/ghc/docs/latest/html/libraries/base/Prelude.html
  http://docs.scala-lang.org/overviews/collections/trait-traversable.html#operations_in_class_traversable

  Clojure and python documentation is not so useful
 -->

The three most important functionals, implemented in almost every other functional programming language are `Map()`, `Reduce()`, and `Filter()`. We've seen `Map()` already, `Reduce()` is a powerful tool for extending two-argument functions, and `Filter()` is a member of an important class of functions that work with predicate functions, functions that return a single boolean.

### `Reduce()`

`Reduce()`: recursively reduces a vector to a single value by first calling `f` with the first two elements, then the result of `f` and the second element and so on. 

```R
out <- x[[1]]
for(i in seq(2, length(x)) {
  out <- f(out, x[[i]])
}
```

Reduce is useful for implementing many types of recursive operations: merges, finding smallest values, intersections, unions.

Reduce is an elegant way of turning binary functions into functions that can deal with any number of arguments, but it is generally of limited use in R because it will produce functions that are much slower than equivalent hand-vectorised code.

Can you implement unlist with reduce? + c?

### Predicates

A __predicate__ is a function that returns `TRUE` or `FALSE`. 

Predicate functions are more useful in non-vectorised languages: you don't need them in R, because many useful predictates are already vectorised: `is.na`, comparisons, boolean operators

* `Filter`: returns a new vector containing only elements where the predicate is `TRUE`.

One function that I find very helpful is `compact`.

As well as filter, two other functions are useful when you have logical predicates

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

Other languages like Haskell and clojure provide more functions:

```R
take_while <- function(x, f) {
  x[1:Position(x, f, nomatch = length(x))]
}
drop_while <- function(x, f) {
  x[1:Position(x, f, nomatch = length(x))]
}
break <- function(x, f) {
  list(take_while(x, f), drop_while(x, f))
}
```

* STL: `find_if`, `count_if`, `replace_if`, `remove_if`, `none_of`, `any_of`, `stable_partition`

### Exercises

* Implement `Any` which takes a list and a predicate function, and returns `TRUE` if the predicate function returns `TRUE` for any of the inputs.  Implement a similar `All` function.

* Implement a more efficient version of break that avoids finding the location of the true value twice.

* Implement the `span` function from Haskell, which given a list `x` and a predicate function `f`, returns the longest sequential run of elements where the predicate is true.


## Converting loops to functionals, and when it's not possible

That there are wide class of for loops that can not be simplified to a single existing function call in R, and a wide class that can never be

Good stackoverflow discussions on converting loops to more efficient/expressive code:

* http://stackoverflow.com/a/14520342/16632
* http://stackoverflow.com/a/2970284/16632

It is not always a good idea to eliminate a for-loop: for loops are verbose and not very expressive, but all R programmers are familiar with them. For example, it's sometimes possible to work around the limitations of `lapply` by using more estoeric language features like `<<-`

```R
trans <- list(
  disp = function(x) x * 0.0163871,
  am = function(x) factor(x, levels = c("auto", "manual"))
)
for(var in names(trans)) {
  mtcars[[var]] <- trans[[var]](mtcars[[var]])
}
```

You could rewrite this as

```R
lapply(names(trans), function(var) {
  mtcars[[var]] <<- trans[[var]](mtcars[[var]])
})
```

From 

```R
df <- 1:10
lapply(2:3, function(i) df <- df * i)
for(i in 2:3) df <- df * i
```

We've eliminated the obvious for loop, but our code is longer, and we've had to use a language feature that few people are familiar with `<<-`.  And to really understand what `mtcars[[var]] <<-` is doing, you need to have a good mental model of how replacement functions really work.  So we've taken something simple and made more complicated, for effectively no gain.

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
exps(x, 0.5)
```

(What's the key feature? Dependening on previously calculated values? Or is it just a cumulative weighted sum?)

```R
lbapply <- function(x, f, init = x[1], ...) {
  out <- numeric(length(x))
  out[1] <- init
  for(i in seq(2:length(x))) {
    out[i] <- f(x[i - 1], out[i - 1], ...)
  }  
}

f <- function(x, out, alpha) alpha * x + (1 - alpha) * out
lbapply(x, f, alpha = 0.5)

lbapply(x, function(x, out) x + y, 0)
```

Closures vs `...`.  `...` usually requires less typing, but there can be confusion about which function arguments belong to.  If you're passing in more than one function, definitely go with closures.


Sometimes it's possible to [solve the recurrence relation](http://en.wikipedia.org/wiki/Recurrence_relation#Solving). In this case, it's possible to rewrite in terms of `i`:

```R
exps1 <- function(x, alpha) {
  function(t) {
    c(rep(alpha, t), 1) * x[-t] * (1 - alpha)^(rev(seq_along(head)))
  }
}
lapply(seq_along(x), expsm1(x, alpha = 0.5))
```

We'll see another example of a function defined recursively, the Fibonacci series, in the [[SoftwareSystems]] chapter.

Another family of looping constructs in R is the `while` loop: this runs code until a condition is met.  `while` loops are more general than `for` loops because every for loop than rewriting into a while loop:

```R
for (i in 1:10) print(i)

i <- 1
while(i <= 10) {
  print(i)
  i <- i + 1
}
```

Not every while loop can be turned into a for loop, because for many while loops you don't know in advance how many times it will be run:

```R
i <- 0
while(TRUE) {
  if (runif(1) > 0.9) break
  i <- i + 1
}
```

This is a common situation when you're writing simulations: one of the random parameters in your simulation may be how many times it is run.  

In some cases, like above, you may be able to remove the loop by recongnising some special feature of the problem. For example, the above problem is counting how many times a Bernoulli trial with p = 0.1 is run before it is successful: this is a geometric random variable so you could replace the above code with `i <- rgeom(1, 0.1)`.  Similar to solving recurrence relations, this is extremely difficult to do in general, but you'll get big gains if you manage to. In most cases it is difficult to write code like that efficiently in R, and if you are calling the code a lot, you may need to convert it to [[C++|Rcpp]].

It's certainly possible to write functions that encapsulate these types of loops, but they are not built in to R. Whether or not it's worth building your own function depends on how often you'll be using, and how much more expressive a better function name would be.

It is also possible to create more sophisticated control flow structures by [[computing on the language]] - developing these might be appropriate if you have a special need not otherwise met, e.g. you want to access a variable defined elsewhere, but this come with a high cost of increased complexity, and will be harder for new readers of the code to understand.

Often the trick is to not to solve the problem in complete generality, but identify what patterns common recur in your code, and then develop functions to automate them. Once you have done this a few times, you might start to recognise bigger patterns.


## A family of functions

The following case study shows how you can use functionals to start small, with very simple functions, then build them up into more complicated and featureful tools. We'll start with a simple idea, adding two numbers together, and show how we can extending to summing any number inputs, or computing parallel sums, or cumulative sums, and sums for arrays in various structures. 

We'll start with addition, and show how we can use exactly the same ideas for multiplication, smallest and largest, and string concatenation to generate a wide family of functions, including over 20 functions provided in base R.

We'll start by defining a very simple plus function, that takes two scalar arguments:

```R
add <- function(x, y) {
  stopifnot(length(x) == 1, length(y) == 1, 
    is.numeric(x), is.numeric(y))
  x + y
}
```

(We're using R's existing addition operator here, which does much more, but the focus in this section is on how we can take very very simple functions and extend them to do more).

We really should also have some way to deal with missing values. A helper function will make this a bit easier -  if x is missing it returns y, if y is missing it returns x, and if both inputs are missing then it returns another argument to the function: `identity`. (We'll talk a bit later about while we've called it identity later).  This function is probably a bit more general than what we need now, but it will come in handy when you implement other binary operators.

```R
rm_na <- function(x, y, identity) {
  if (is.na(x) && is.na(y)) {
    identity
  } else if (is.na(x)) {
    y
  } else {
    x
  }  
}
```

That allows us to write a version of `add` that can deal with missing values if needed: (and it often is!)

```R
add <- function(x, y, na.rm = FALSE) {
  if (na.rm && (is.na(x) || is.na(y))) rm_na(x, y, 0) else x + y
}
```

Why should `add(NA, NA, na.rm = TRUE)` return 0?  Well for every other input it returns a numeric vector of length 1, so it should probably do that too even if both arguments are missing values.  There's also something special about add: it's associative, which means if you're adding together multiple numbers, it shouldn't matter in which order you're doing it.  In other words, the following two function calls should return the same value:

```R
add(add(3, NA, na.rm = TRUE), NA, na.rm = TRUE)
add(3, add(NA, NA, na.rm = TRUE), na.rm = TRUE)
```

Which implies that `add(NA, NA, na.rm = TRUE)` must be 0.

The first way we might want to extend this function is to make it possible to add multiple numbers together.  This is a simple application of `Reduce`: if the input is `c(1, 2, 3)`, then we want to compute `add(1, add(2, 3))`:

```R
r_add <- function(xs, na.rm = TRUE) {
  Reduce(function(x, y) add(x, y, na.rm = na.rm), xs)
}
r_add(c(1, 4, 10))
```

This looks good, but we need to test it for a few special cases:

```R
r_add(NA, na.rm = TRUE)
r_add(numeric())
```

These are incorrect: in the first case we get a missing value even thought we've explicitly asked for them to be ignored, and in the second case we get a null, instead of a length 1 numeric vector (as for every other set of inputs).

The two problems are related: if we give `Reduce()` a length one vector it doesn't have anything to reduce, so it just returns the same value. And if we give it a length 0 input it returns `NULL`.  There are two ways to fix this: we can add `0` to every input vector, or we can use the `init` argument to `Reduce()` which effectively does the same thing:

```R
r_add <- function(xs, na.rm = TRUE) {
  Reduce(function(x, y) add(x, y, na.rm = na.rm), c(0, xs))
}
r_add(c(1, 4, 10))
r_add(NA, na.rm = TRUE)
r_add(numeric())
```

(There is of course a function in R that already does that: `sum`)

But it would be nice to have a vectorised version so that we could give it two vectors of numbers and they were added together.

We have two options to implement this, neither of which are perfect.  We could use `Map`, but that will give us a list, or we could use `vapply` by looping over the indices.  That gives us a better output data structure, but a version of `Map` where we could specify the output type would be even better.

A few test cases makes sure that it behaves as we expect: the output is always the same as the input (we're a bit stricter than base R here because we don't do recyclying - you could add that if you wanted, but I find you get fewer bugs by avoidingin recycling and being specific anyway.)

```R
v_add <- function(x, y, na.rm = TRUE) {
  stopifnot(length(x) == length(x), is.numeric(x), is.numeric(y))
  Map(function(x, y) add(x, y, na.rm = na.rm), x, y)
}

v_add <- function(x, y, na.rm = TRUE) {
  stopifnot(length(x) == length(x), is.numeric(x), is.numeric(y))
  vapply(seq_along(x), function(i) add(x[i], y[i], na.rm = na.rm),
    numeric(1))
}
v_add(1:10, 1:10)
v_add(numeric(), numeric())
v_add(c(1, NA), c(1, NA), na.rm = TRUE)
```

(This is of course exactly the usual behavior of `+` in R, although we don't have the same control over missing values - there's no way to tell `+` to remove missing values)

Another variant of adding is the cumulative sum: it's like the reductive version, but we see every step along the way to the final result. This is easy to implement with `Reduce()`'s `accumuate` argument:

```R
c_add <- function(xs, na.rm = FALSE) {
  Reduce(function(x, y) add(x, y, na.rm = na.rm), xs, 
    accumulate = TRUE)
}
c_add(1:10)
c_add(10:1)
```

(This function also already has an existing R equivalent)

Finally, we might want to define versions for more complicated data structures, like matrices.  We could create `row` and `col` variants that sum across rows and columns respectively, or we could go the whole hog and define an array version that would sum across any arbitrary dimensions of an array.  These are easy to implement: they're a combination of `add` and `apply`

```R
row_sum <- function(x, na.rm = TRUE) apply(x, 1, add, na.rm = na.rm)
col_sum <- function(x, na.rm = TRUE) apply(x, 2, add, na.rm = na.rm)
arr_sum <- function(x, dim, na.rm = TRUE) apply(x, dim, add, na.rm = na.rm)
```

(And again we have the existing `rowSums` and `colSums` functions that do the same thing)

So if every function we have created already has an existing equivalent in base R, why did we bother? There are three main reasons:

* because we've created all our variants from a primitive binary operator (`add`) and a functional (`Reduce`, `Map` and `apply`), we know all the functions will behave absolutely consistently.

* we've seen the infrastructure for addition, and now we can adapt it to other operators.

The downside of this approach is that these implementations are unlikely to be very efficient.  However, even if they don't turn out to be fast enough for your purposes they are still a good starting point because they are less likely to have bugs - when you create faster versions (maybe using [[Rcpp]]), you can compare results to make sure your fast versions are still correct.

### Exercises

* Implement `smaller` and `larger` functions that given two inputs return either the small or the large value. Implement `na.rm = TRUE`: what should the identity be? (Hint: `smaller(x, smaller(NA, NA, na.rm = TRUE), na.rm = TRUE)` must be `x`, so `smaller(NA, NA, na.rm = TRUE)` must be bigger than any other value of x.).  Use `smaller` and `larger` to implement equivalents of `min`, `max`, `pmin`, `pmax`, and new functions `row_min` and `row_max`

* Create a table that has:
  * columns: add, multiple, smaller, larger, and, or
  * rows: binary operator, reducing version, vectorised version, array versions
  
  * Fill in the cells with the names of base R functions that perform each of the roles
  * Compare the names and arguments of the existing R functions. How consistent are they? How could you improve them?
  * Complete the matric by implementing versions

* How does `paste` fit into this structure? What is the primitive function that underlies paste? What are the `sep` and `collapse` arguments equivalent to? Are there are any components that are missing for paste?

