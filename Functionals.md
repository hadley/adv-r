# Functionals 

<!--  
  library(pryr)
  library(stringr)
  find_funs("package:base", fun_calls, fixed("match.fun"))
  find_funs("package:base", fun_args, ignore.case("^(fun|f)$"))
-->

## Introduction

"To become significantly more reliable, code must become more transparent. In particular, nested conditions and loops must be viewed with great suspicion. Complicated control flows confuse programmers. Messy code often hides bugs."
--- [Bjarne Stroustrup](http://www.stroustrup.com/Software-for-infrastructure.pdf)

Higher-order functions encompass any functions that either take a function as an input or return a function as output. We've already seen closures, functions returned by another function. The complement to a closure is a __functional__, a function that takes a function as an input and returns a vector as output. 

Here's a simple functional, it takes an input function and calls it with some random input:

```R
randomise <- function(f) f(runif(1e3))
randomise(mean)
randomise(sum)
```

This function is not terribly useful, but it illustrates the basic idea: since functions are first class objects in R, there's no difference between calling a function with a vector or function as input. The chances are that you've already used a functional: the most frequently used are `lapply()`, `apply()` and `tapply()`. These three functions all take a function as input (among other things) and give a vector as output.

Many functionals (like `lapply()`) offer alternatives to for loops. For loops have a bad rap in R, and some programmers try to eliminate them at all costs. The performance story is a little more complicated than what you might have heard (we'll explore that in the [[performance]] chapter); the real downside of for loops is that they're not very expressive. A for loop conveys that you're iterating over something, but it doesn't communicate the higher-level task you're trying to complete. Functionals are not as general as for loops, but by being more specific they allow you to communicate more clearly. A functional allows you to say I want to transform each element of this list, or each row of this array.

As well as more clearly communicating intent, functionals reduce the chances of bugs, and can be more efficient. Both of these features occur because functionals are used by many people, so they will be well tested, and may have been implemented with an eye to performance. For example, many functionals in base R are written in C, and often use a few tricks to get extra performance.

As well as replacements for for loops, functionals do play other roles. They are also useful tools for encapsulating common data manipulation tasks, the split-apply-combine pattern; for thinking "functionally"; and for working with mathematical functions. In this chapter, you'll learn about:

* Functionals that replace a common pattern of for-loop use, like `lapply`, `vapply` and `Map`.

* Functionals for manipulating common R data structures, like `apply`, `split`, `tapply` and the plyr package.

* Popular functionals from other programming languages, like `Map`, `Reduce` and `Filter`.

* Mathematical functionals, like `integrate`, `uniroot`, and `optim`.

We'll also talk about how (and why) you might convert loop to use a functional. The chapter concludes with a case study where we take simple scalar addition and use functionals to build a complete family of addition functions including vectorised addition, sum, cumulative sum, and row- and column-wise summation. 

The focus in this chapter is on clear communication with your code, and developing tools to solve wide classes of problems. This will not always produce the fastest code, but it is a mistake to focus on speed until you know it will be a problem. Once you do have clear, correct code you can make it fast using the techniques in the [[performance]] chapter.

## My first functional: `lapply()`

The simplest functional is `lapply()`, which you may already be familiar with. `lapply()` takes a function and applies it to each element of a list, saving the results back into a list.  `lapply()` is the building block for many other functionals, so it's important to understand how it works

![A sketch of how `lapply()` works](diagrams/lapply.png)

`lapply()` is written in C for performance, but we can create a simple R implementation that works the same way:

```R
lapply2 <- function(x, f, ...) {
  out <- vector("list", length(x))
  for (i in seq_along(x)) {
    out[[i]] <- f(x[[i]], ...)
  }
  out
}
```

From this code, you can see that `lapply()` is a wrapper around a common for loop pattern: we create a space for output, and then fill it in, applying `f()` to each component of the list. All other for loop functionals build on this base, modifying either the input, the output, or what data the function is applied to. From this code you can see that `lapply()` will also works with vectors: both `length()` and `'[[` work the same way for lists and vectors.

`lapply()` makes it easier to work with lists by eliminating much of the boilerplate, focussing on the operation you're applying to each piece:

```R
# Create some random data
l <- replicate(20, runif(sample(1:10, 1)), simplify = FALSE)

# With a for loop
out <- vector("list", length(l))
for (i in seq_along(l)) {
  out[[i]] <- length(l[[i]])    
}
unlist(out)

# With lapply
unlist(lapply(l, length))
```

Since data frames are also lists, `lapply()` is useful when you want to do something to each column of a data frame:

```R
# What class is each column?
lapply(mtcars, class)

# Divide each column by the mean
mtcars[] <- lapply(mtcars, function(x) x / mean(x))
```

The pieces of `x` are always supplied as the first argument to `f`. You can override this using R's regular function calling semantics, supplying additional named arguments. For example, imagine you wanted to compute various trimmed means of the same dataset. `trim` is the second parameter of `mean()`, so we want to vary that, keeping the first argument (`x`) fixed.  It's easy provided that you remember that the following two calls are equivalent 

```R
mean(1:100, trim = 0.1)
mean(0.1, x = 1:100)
```

So to use `lapply()` with the second argument, we just need to name the first argument:

```R
trims <- c(0, 0.1, 0.2, 0.5)
x <- rcauchy(100)
lapply(trims, mean, x = x)
```

### Looping patterns

When using `lapply()` and friends, it's useful to remember that there are usually three ways to loop over an vector: 

1. loop over the elements of the vector: `for(x in xs)`
2. loop over the numeric indices of the vector: `for(i in seq_along(xs))`
3. loop over the names of the vector: `for(nm in names(xs))`

If you're saving the results from a for loop, you usually can't use the first form because it makes very inefficient code.  When extending an existing data structure, all the existing data must be copied every time you extend it:

```R
xs <- runif(1e3)
res <- c()
for(x in xs) {
  # This is slow!
  res <- c(res, sqrt(x))
}
```

It's much better to create enough space for the output and then fill it in, using the second looping form:

```R
res <- numeric(length(xs))
for(i in seq_along(xs)) {
  res[i] <- sqrt(xs[i])
}
```

Corresponding to the three ways to use a for loop there are three ways to use `lapply()` with an object:

```R
lapply(xs, function(x) {})
lapply(seq_along(xs), function(i) {})
lapply(names(xs), function(nm) {})
```

Typically you use the first form because `lapply()` takes care of saving the output for you. However, if you need to know the position or the name of the element you're working with, you'll need to use the second or third form; they give you both the position of the object (`i`, `nm`) and its value (`xs[[i]]`, `xs[[nm]]`). If you're struggling to solve a problem using one form, you might find it easier with a different form.

If you're working with a list of functions, remember to use `call_fun`:

```R
call_fun <- function(f, ...) f(...)
f <- list(sum, mean, median, sd)
lapply(f, call_fun, x = runif(1e3))
```

Or you could create a variant, `fapply()`, specifically for working with lists of functions:

```R
fapply <- function(fs, ...) {
  out <- vector("list", length(fs))
  for (i in seq_along(fs)) {
    out[[i]] <- fs[[i]](...)
  }
  out
}
fapply(f, x = runif(1e3))
```


### Exercises

* The function `scale01()` given below scales a vector to have range 0-1. How would you apply it to every column in a data frame? How would you apply it to every numeric column in a data frame?

    ```R
    scale01 <- function(x) {
      rng <- range(x, na.rm = TRUE)
      (x - rng[1]) / (rng[2] - rng[1])
    }
    ```

* For each formula in the list below, use a for-loop and lapply to fit the corresponding model to the `mtcars` dataset

    ```R
    formulas <- list(
      mpg ~ disp,
      mpg ~ I(1 / disp),
      mpg ~ disp + wt,
      mpg ~ I(1 / disp) + wt
    )
    ```

* Fit the model `mpg ~ disp` to each of the bootstrap replicates of `mtcars` in the list below, using a for loop and then `lapply()`. Can you do it without an anonymous function?

    ```R
    bootstraps <- lapply(1:10, function(i) {
      rows <- sample(1:nrow(mtcars), rep = TRUE)
      mtcars[rows, ]
    })
    ```

* For each model in the previous two exercises extract the R^2 using the function below.

  ```R
  rsq <- function(mod) summary(mod)$r.squared
  ```

## For loop functionals: friends of `lapply()`

The art of using functionals is to recognise what common looping patterns are implemented in existing base functionals, and then use them instead of loops. Once you've mastered the existing functionals, the next step is to start writing your own: if you discover you're duplicating the same looping pattern in many places, you should extract it out into its own function. 

The following sections build on `lapply()` and discuss:

* `sapply()` and `vapply()`, variants of `lapply()` that produce 
vectors, matrices and arrays as __output__, instead of lists.

* `Map()` and `mapply()` which iterate over multiple __input__ data structures in parallel.

* __Parallel__ versions of `lapply()` and `Map()`, `mclapply()` and `mcMap()`

* __Rolling computations__, showing how a new problem can be solved with for loops, or by building on top of `lapply()`.

### Vector output: `sapply` and `vapply`

`sapply()` and `vapply()` are very similar to `lapply()` except they will simplify their output to produce an atomic vector. `sapply()` guesses, while `vapply()` takes an additional argument specifying the output type. `sapply()` is useful for interactive use because it saves typing, but if you use it inside your functions you will get weird errors if you supply the wrong type of input. `vapply()` is more verbose, but gives more informative errors messages and never fails silently, so is better suited for use inside other functions.

The following example illustrates these differences.  When given a data frame `sapply()` and `vapply()` give the same results. When given an empty list, `sapply()` has no basis to guess the correct type of output, and returns `NULL`, instead of the more correct zero-length logical vector.

```R
sapply(mtcars, is.numeric)
vapply(mtcars, is.numeric, logical(1))
sapply(list(), is.numeric)
vapply(list(), is.numeric, logical(1))
```

If the function returns results of different types or lengths, `sapply()` will silently return a list, while `vapply()` will throw an error. `sapply()` is fine for interactive use because you'll normally notice if something went wrong, but it's dangerous when writing functions. 

The following example illustrates a possible problem when extracting the class of columns in data frame: if you falsely assume that class only has one value and use `sapply()` you won't find out about the problem until some future function is given a list instead of a character vector.

```R
df <- data.frame(x = 1:10, y = letters[1:10])
sapply(df, class)
vapply(df, class, character(1))

df2 <- data.frame(x = 1:10, y = Sys.time() + 1:10)
sapply(df2, class)
vapply(df2, class, character(1))
```

`sapply()` is a thin wrapper around `lapply()`, transforming a list into a vector in the final step; `vapply()` reimplements `lapply()` but assigns results into a vector (or matrix) of the appropriate type instead of into a list. The following code shows pure R implementation of the essence of `sapply()` and `vapply()`; the real functions have better error handling and preserve names, among other things. 

```R
sapply2 <- function(x, f, ...) {
  res <- lapply2(x, f, ...)
  simplify2array(res)
}

vapply2 <- function(x, f, f.value, ...) {
  out <- matrix(rep(f.value, length(x)), nrow = length(x))
  for (i in seq_along(x)) {
    res <- f(x[i], ...)
    stopifnot(
      length(res) == length(f.value), 
      typeof(res) == typeof(f.value)
    )
    out[i, ] <- res
  }
  out
}
vapply2(1:10, f, logical(1))
```

![Schematics of `sapply` and `vapply`, cf `lapply`.](diagrams/sapply-vapply.png)

`vapply()` and `sapply()` are like `lapply()`, but with different outputs; the following section discusses `Map()`, which is like `lapply()` but with different inputs. 

### Multiple inputs: `Map` (and `mapply`)

With `lapply()`, only one argument to the function varies; the others are fixed. This makes it poorly suited for some problems. For example, how would you find the weighted means when you have two lists, one of observations and the other of weights:

```R
# Generate some sample data
xs <- replicate(10, runif(10), simplify = FALSE)
ws <- replicate(10, rpois(10, 5) + 1, simplify = FALSE)
```

It's easy to use `lapply()` to compute the unweighted means:

```R
lapply(xs, means)
```

But how could we supply the weights to `weighted.mean()`? `lapply(x, means, w)` won't work because the additional arguments to `lapply()` are passed to every call. We could change looping forms:

```R
lapply(seq_along(x), function(i) weighted.mean(xs[[i]], ws[[i]]))
```

This works, but is a little clumsy. A cleaner alternative is to use `Map`, a variant of `lapply()`, where all arguments vary.  This lets us write:

```R
Map(weighted.mean, xs, ws)
```

(Note that the order of arguments is a little different: with `Map()` the function is the first argument, with `lapply()` it's the second.

This is equivalent to:

```R
stopifnot(length(x) == length(w))
out <- vector("list", length(x))
for (i in seq_along(x)) {
  out[[i]] <- weighted.mean(x[[i]]], w[[i]])
}
```

There's a natural equivalence between `Map()` and `lapply()` because you can always convert a `Map()` to an `lapply()` that iterates over indices, but using `Map()` is more concise, and more clearly indicates what you're trying to do.

`Map` is useful whenever you have two (or more) lists (or data frames) that you need to process in parallel. For example, another way of standardising columns, is to first compute the means and then divide by them. We could do this with `lapply()`, but if we do it in two steps, we can more easily check the results at each step, which is particularly important if the first step is more complicated.

```R
mtmeans <- lapply(mtcars, mean)
mtmeans[] <- Map(`/`, mtcars, mtmeans)

# In this case, equivalent to
mtcars[] <- lapply(mtcars, function(x) x / mean(x))
```

If some of the arguments should be fixed, and not varying, you need to use an anonymous function:

```R
Map(function(x, w) weighted.mean(x, w, na.rm = TRUE), xs, ys)
```

We'll see a more compact way to express the same idea in the next chapter.

<!-- This should be a sidebar -->

You may be more familiar with `mapply()` than `Map()`. I prefer `Map()` because:

* it is equivalent to `mapply` with `simplify = FALSE`, which is almost always what you want. 

* Instead of using an anonymous function to provide constant inputs, `mapply` has the `MoreArgs` argument which takes a list of extra arguments that will be supplied, as is, to each call. This breaks R's usual lazy evaluation semantics, and is inconsistent with other functions.

In brief, `mapply()` is more complicated for little gain.

### Rolling computations

What if you need a for-loop replacement that doesn't exist in base R? You can often create your own by recognising common looping structures and implementing your own wrapper. For example, you might be interested in smoothing your data using a rolling (or running) mean function:

```R
rollmean <- function(x, n) {
  out <- rep(NA, length(x))

  offset <- trunc(n / 2)
  for (i in (offset + 1):(length(x) - n + offset - 1)) {
    out[i] <- mean(x[(i - offset):(i + offset - 1)])
  }
  out
}
x <- seq(1, 3, length = 1e2) + runif(1e2)
plot(x)
lines(rollmean(x, 5))
lines(rollmean(x, 10), col = "red")
```

But if the noise was more variable (i.e. it had a longer tail) you might worry that your rolling mean was too sensitive to the occassional outlier and instead implement a rolling median. 

```R
x <- seq(1, 3, length = 1e2) + rt(1e2, df = 2) / 3
plot(x)
lines(rollmean(x, 5))
```

To modify `rollmean()` to `rollmedian()` all you need to do is replace `mean` with `median` inside the loop, but instead of copying and pasting to create a new function, you might think about abstracting out the notion of computing a rolling summary.

```R
rollapply <- function(x, n, f, ...) {
  out <- rep(NA, length(x))

  offset <- trunc(n / 2)
  for (i in (offset + 1):(length(x) - n + offset - 1)) {
    out[i] <- f(x[(i - offset):(i + offset - 1)], ...)
  }
  out
}
lines(rollapply(x, 5, median), col = "red")
```

You might notice that this is pretty similar to what `vapply` does, and in fact we could rewrite it as

```R
rollapply <- function(x, n, f, ...) {
  offset <- trunc(n / 2)
  locs <- (offset + 1):(length(x) - n + offset - 1)
  vapply(locs, function(i) f(x[(i - offset):(i + offset - 1)], ...),
    numeric(1))
})
```

which is effectively how `zoo::rollapply` implements it, albeit with many more features and much more error checking.

### Parallelisation

One thing that's interesting about the defintions of `lapply()` and variants is that because each iteration is isolated from all others, the order in which they are computed doesn't matter. For example, while `lapply3()`, defined below, scrambles the order in which computation occurs, the results are same every time:

```R
lapply3 <- function(x, f, ...) {
  out <- vector("list", length(x))
  for (i in sample(seq_along(x))) {
    out[[i]] <- f(x[[i]], ...)
  }
  out
}
unlist(lapply3(1:10, sqrt))
unlist(lapply3(1:10, sqrt))
```

This has a very important consequence: since we can compute each element in any order, it's easy to dispatch the tasks to different cores, and compute in parallel.  This is what `mclapply()` (and `mcMap`) in the parallel package do:

```R
library(parallel)
mclapply(1:10, sqrt, mc.cores = 4)
```

In this case `mclapply()` is actually slower than `lapply()`, becuase the cost of the individual computations is low, and some additional work is needed to send the computation to the different cores and then collect the results together. If we take a more realistic example, generating bootstrap replicates of a linear model, we see the advantage of parallel computation:

```R
boot_df <- function(x) x[sample(nrow(x), rep = T), ]
rsquared <- function(mod) summary(mod)$r.square
boot_lm <- function(i) {
  rsquared(lm(mpg ~ wt + disp, data = boot_df(mtcars)))
}

system.time(lapply(1:500, boot_lm))
system.time(mclapply(1:500, boot_lm, mc.cores = 2))
```

It is rare to get a linear improvement with increasing number of cores, but if your code uses `lapply()` or `Map()`, this is an easy way to improve performance.

### Exercises

* Use `vapply()` to:

  * Compute the standard deviation of every column in a numeric data frame.
  
  * Compute the standard deviation of of every numeric column in a mixed data frame (you'll need to use `vapply()` twice)

* Recall: why is using `sapply()` to get the `class()` of each element in a data frame dangerous?

* The following code simulates the performance of a t-test for non-normal data. Use `sapply()` and an anonymous function to extract the p value from every trial. Extra challenge: get rid of the anonymous function and use the `'[[` function.  

    ```R
    trials <- replicate(100, t.test(rpois(10, 10), rpois(7, 10)), 
      simplify = FALSE)
    ```

* Implement a combination of `Map()` and `vapply()` to create an `lapply()` variant that iterates in parallel over all of its inputs and stores its outputs in a vector (or a matrix).  What arguments should the function take?

* What does `replicate()` do? What sort of for loop does it eliminate? Why do its arguments differ from `lapply()` and friends?

* Implement `mcsapply()`, a multicore version of `sapply()`.  Can you implement `mcvapply()` a parallel version of `vapply()`? Why/why not?

* Implement a version of `lapply()` that supplies `f()` with both the name and the value of each component.

## Data structure functionals

As well as functionals that exist to eliminate common looping constructs, another family of functionals works to eliminate loops for common data manipulation tasks.

In this section, we'll give a brief overview of the available options. The focus is to show you some of the options that are available, hint at how they can help you, and point you in the right direction to learn more:

* base matrix functions `apply()`, `sweep()` and `outer()`

* `tapply()`, which summarises a vector divided into groups by the values of another vector

* the `plyr` package, which generalises the ideas of `tapply()` to work with inputs of data frames, lists and arrays, and outputs of data frames, lists, arrays and nothing

### Matrix and array operations

So far, all the functionals we've seen work with 1d input structures. The three functionals in this section provide useful tools for working with high-dimensional data strucures. 

`apply()` is like a variant of `sapply()` that works with matrices and arrays, and you can think of it as an operation that summarises a matrix or array, collapsing a row or column to a single number.  It has four arguments: 

* `X`, the matrix or array to summarise
* `MARGIN`, an integer vector giving the dimensions to summarise over, 1 = rows, 2 = columns, etc
* `FUN`, a summary function
* `...` other arguments passed on to `FUN`

A typical example of `apply()` looks like this

```R
a <- matrix(1:20, nrow = 5)
apply(a, 1, mean)
apply(a, 2, mean)
```

There are a few caveats apply to using `apply()`: it does not have a simplify argument, so you can never be completely sure what type of output you will get. This generally means that `apply()` is not safe to program with, unless you very carefully check the inputs.  `apply()` is also not idempotent in the sense that if the summary function is the identity operator, the output is not always the same as the input:

```R
a1 <- apply(a, 1, identity)
identical(a, a1)
identical(a, t(a1))
```

(You can put high-dimensional arrays back in the right order using `aperm()`, or use `plyr::aaply()`, which is idempotent.)

`sweep()` is a function that allows you to "sweep" out the values of a summary statistic. It is most often useful in conjunction with `apply()` and it often used to standardise arrays in some way.

```R
# Scale matrix to [0, 1]
x <- matrix(runif(20), nrow = 4)
x1 <- sweep(x, 1, apply(x, 1, min))
x2 <- sweep(x1, 1, apply(x1, 1, max), "/")
```

The final matrix functional is `outer()`. It's a little different in that it takes multiple vector inputs and creates a matrix or array output where the input function is run over every combination of the inputs:

```R
# Create a times table
outer(1:10, 1:10, "*")
```

Good places to learn more about `apply()` are:

* [Using apply, sapply, lapply in R](http://petewerner.blogspot.com/2012/12/using-apply-sapply-lapply-in-r.html) by Peter Werner.
* [The infamous apply function](http://rforpublichealth.blogspot.no/2012/09/the-infamous-apply-function.html) by Slawa Rokicki.
* [The R apply function – a tutorial with examples](http://forgetfulfunctor.blogspot.com/2011/07/r-apply-function-tutorial-with-examples.html) by axiomOfChoice.
* The stackoverflow question [R Grouping functions: sapply vs. lapply vs. apply. vs. tapply vs. by vs. aggregate vs](http://stackoverflow.com/questions/3505701).

### Group apply

In some sense, `tapply()` is a generalisation to `apply()` that allows for "ragged" arrays, where each row can have different numbers of rows. This often comes about when you're trying to summarise a data set. For example, imagine you've collected some pulse rate from a medical trial, and you want to compare the two groups:

```R
pulse <- round(rnorm(22, 70, 10 / 3)) + rep(c(0, 5), c(10, 12))
group <- rep(c("A", "B"), c(10, 12))

tapply(pulse, group, length)
tapply(pulse, group, mean)
```

It's easiest to understand how `tapply()` works by first creating a "ragged" data structure from the inputs. This is the job of the `split()` function, which takes two inputs and returns a list, where all the elements in the first vector with equal entries in the second vector get put in the same element of the list:

```R
split(pulse, group)
```

Then you can see that `tapply()` is just the combination of `split()` and `sapply()`:

```R
tapply2 <- function(x, group, f, ..., simplify = TRUE) {
  pieces <- split(x, group)
  sapply(pieces, f, simplify = simplify)
}
tapply2(pulse, group, length)
tapply2(pulse, group, mean)
```

This is a common pattern: if you have a good foundational set of functionals, you can solve many problems by combining them in new ways.

### The plyr package

One challenge with using the functionals provided by the base package is that they have grown organically over time, and have been written by multiple authors.  This means that they are not very consistent. For example,

* The simplify argument is called `simplify` in `tapply()` and `sapply()`, but `SIMPLIFY` for `mapply()`, and `apply()` lacks the argument altogether.

* `vapply()` provides a variant of `sapply()` where you describe what the output should be, but there are not corresponding variants for `tapply()`, `apply()`, or `Map()`.

* The first to most apply functions is the input `x`, but the first argument to `Map()` is the function `f`.

This makes learning these operators challenging, as you have to memorise all of the variations. Additionally, if you think about the combination of input and output types, base R only provides a partial set of functions:

|            | list   | data frame | array  |
|------------|--------|------------|--------|
| list       | lapply |            | sapply |
| data frame | by     |            |        |
| array      |        |            | apply  |

This was one of the driving forces behind the creation of the plyr package, which provides consistently named functions with consistently named arguments, that implement all combinations of input and output data structures:

|            | list   | data frame | array | 
|------------|--------|------------|-------|
| list       | llply  | ldply      | laply |
| data frame | dlply  | ddply      | daply |
| array      | alply  | adply      | aaply |

Each of these functions processes breaks up a data structure in some way, applies a function to each piece and then joins the results back together. 

You can read more about these plyr function in [The Split-Apply-Combine Strategy for Data Analysis](http://www.jstatsoft.org/v40/i01/), an open-access article published in the Journal of Statistical Software.

### Exercises

* How does `apply()` arrange the output.  Read the documentation and perform some experiments.

* There's no equivalent to `split()` + `vapply()`. Should there be? When would it be useful? Implement it yourself.

* Implement a pure R version of `split()`. (Hint: use unique and subseting)

* What other types of input and output are missing? Brainstorm before you look up in the answers in the [plyr paper](http://www.jstatsoft.org/v40/i01/)

## Functional programming

<!-- 
  http://www.haskell.org/ghc/docs/latest/html/libraries/base/Prelude.html
  http://docs.scala-lang.org/overviews/collections/trait-traversable.html#operations_in_class_traversable

  Clojure and python documentation is not so useful
 -->

The three most important functionals, implemented in almost every functional programming language are `Map()`, `Reduce()`, and `Filter()`. We've seen `Map()` already, `Reduce()` is a powerful tool for extending two-argument functions, and `Filter()` is a member of an important class of functions that work with predicate functions, functions that return a single boolean.

### `Reduce()`

`Reduce()` recursively reduces a vector to a single value by first calling `f` with the first two elements, then the result of `f` and the third element and so on. In some languages, reduce is known as fold.

```R
Reduce(`+`, 1:3)
((1 + 2) + 3)

Reduce(sum, 1:3)
sum(sum(1, 2), 3)
```

As you might have come to expect by now, the essence of `Reduce()` can be described by a simple for loop: 

```R
out <- x[[1]]
for(i in seq(2, length(x)) {
  out <- f(out, x[[i]])
}
```

The real `Reduce()` is more complicated because it includes arguments to control whether the values are reduced from the left or from the right (`right`), an optional initial value (`init`), and an option to output every intermediate result (`accumulate`).

Reduce is useful for implementing many types of recursive operations: merges, finding smallest values, intersections, unions. For example, imagine you had a list of numeric vectors, and you wanted to find the values that occured in each vector:

```R
l <- replicate(5, sample(1:10, 15, rep = T), simplify = FALSE)
```

You could do that by intersecting each element in turn:

```R
intersect(intersect(intersect(intersect(l[[1]], l[[2]]), l[[3]]), l[[4]]), l[[5]])
Reduce(intersect, l)
```

Reduce is an elegant way of turning binary functions into functions that can deal with any number of arguments, and we'll see another use in the final case study. 

### Predicate functionals

A __predicate__ is a function that returns a single `TRUE` or `FALSE`, like `is.character`, `all`, or `is.NULL`. 

`is.na` is not a predicate function because it returns a vector of values.  

The predicate functionals make it easy to apply predicates to lists

* `Filter`: returns a new vector containing only elements where the predicate is `TRUE`.

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

Another useful function is the ability to apply a non-vectorised predicate to a vectorised predicate:

```R
where <- function(x, f) {
  vapply(x, f, logical(1))
}
where(mtcars, is.character)
```

Once we have that function, `Filter` is particularly easy to implement:

```R
Filter <- function(f, x) x[where(x, f)]
```

But `where` makes for a better low level function because there are many ways to combine logical vectors.

* STL: `find_if`, `count_if`, `replace_if`, `remove_if`, `none_of`, `any_of`, `stable_partition`

### Exercises

* Implement `Any` which takes a list and a predicate function, and returns `TRUE` if the predicate function returns `TRUE` for any of the inputs.  Implement a similar `All` function.

* Implement a more efficient version of break that avoids finding the location of the true value twice.

* Implement the `span` function from Haskell, which given a list `x` and a predicate function `f`, returns the longest sequential run of elements where the predicate is true.


## Mathematical functionals

<!-- 
  find_funs("package:stats", fun_args, "upper")
  find_funs("package:stats", fun_args, "^f$")
-->

Functionals are very common in mathematics: the limit, the maximum, the roots (the set of points where `f(x) = 0`), and the definite integral are all functionals; given a function, they return a single number (or a vector of numbers). At first glance, these functions don't seem to fit in with the theme of eliminating loops, but if you dig deeper you'll see all of them are implemented using an algorithm that involves iteration.

In this section we'll explore some of R's built-in mathematical functionals. There are three functions that work with a 1d numeric function:

* `integrate`: integrate it over a given range
* `uniroot`: find where it hits zero over a given range
* `optimise`: find location of minima (or maxima)

Let's explore how these are used with a simple function:

```R
integrate(sin, 0, pi)
uniroot(sin, pi * c(1 / 2, 3 / 2))
optimise(sin, c(0, 2 * pi))
optimise(sin, c(0, pi), maximum = TRUE)
```

In statistics, optimisation is often used for maximum likelihood estimation. Maximum likelihood estimation (MLE) is a natural fit for functional programming.  We have a problem and a general technique to solve it.  MLE also works well with closures because the arguments to a likelihood fall into two groups: the data, which is fixed for a given problem, and the parameters, which will vary as we try to find a maximum numerically. This naturally gives rise to an approach like the following.

First, we create a function that computes the negative log likelihood (NLL) for a given dataset.  In in R, it's common to use the negative since `optimise()` defaults to findinging the minimum.

```R
poisson_nll <- function(x) {
  n <- length(x)
  function(lambda) {
    n * lambda - sum(x) * log(lambda) # + terms not involving lambda
  }
}
```

With the general NLL in hand, we create two specific NLL functions for two datasets, and use `optimise()` to find the best values, given a generous starting range.

```R
nll1 <- poisson_nll(c(41, 30, 31, 38, 29, 24, 30, 29, 31, 38)) 
nll2 <- poisson_nll(c(6, 4, 7, 3, 3, 7, 5, 2, 2, 7, 5, 4, 12, 6, 9)) 

optimise(nll1, c(0, 100))
optimise(nll2, c(0, 100))
```

Another important mathmatical functional is `optim()`. It is a generalisation of `optim()` to more than one direction. If you're interested in how `optim()` works, you might want to explore the `Rvmmin` package, which provides a pure-R implementation of R. Interestingly `Rvmmin` is no slower than `optim()`, even though it is written in R, not C: for this problem, the bottleneck is evaluating the function multiple times, not controlling the optimisation.

### Exercises

* Implement the `arg_max` function. It should take a function, and a vector of inputs, returning the elements of the input where the function returns the highest number. For example, `arg_max(-10:5, function(x) x ^ 2)` should return -10. `arg_max(-5:5, function(x) x ^ 2)` should return `c(-5, 5)`.  Also implement the matching `arg_min`.

* Read about the fixed point algorithm in http://mitpress.mit.edu/sicp/full-text/book/book-Z-H-12.html#%_sec_1.3.  Complete the exercises using R.

## Converting loops to functionals, and when it's not possible

That there are wide class of for loops that can not be simplified to a single existing function call in R.  It is not always a good idea to eliminate a for-loop: for loops are verbose and not very expressive, but all R programmers are familiar with them. For example, it's sometimes possible to work around the limitations of `lapply` by using more estoeric language features like `<<-`

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

We've eliminated the obvious for loop, but our code is longer, and we've had to use a language feature that few people are familiar with `<<-`.  And to really understand what `mtcars[[var]] <<-` is doing, you need to have a good mental model of how replacement functions really work.  So we've taken something simple and made more complicated, for effectively no gain.

There is 
Good stackoverflow discussions on converting loops to more efficient/expressive code:

* http://stackoverflow.com/a/14520342/16632
* http://stackoverflow.com/a/2970284/16632


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

