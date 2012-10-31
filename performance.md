# Profiling performance and memory

"We should forget about small efficiencies, say about 97% of the time: premature optimization is the root of all evil" --- Donald Knuth.

Your code should be correct, maintainable and fast. Notice that speed comes last - if your function is incorrect or unmaintainable (i.e. will eventually become incorrect) it doesn't matter if it's fast. As computers get faster and R is optimised, your code will get faster all by itself. Your code is never going to automatically become correct or elegant if it is not already.

That said, sometimes there are times where you need to make your code faster: spending several hours of your day might save days of computing time for others. The aim of this chapter is to give you the skills to figure out why your code is slow, what you can do to improve it, and ensure that you don't accidentally make it slow again in the future.  You may already be familiar with `system.time`, which tells you how long a block of code takes to run. This is a useful building block, but is a crude tool.

In this chapter, you'll learn five skills for making your code performant:

* recognising the most common cause of poor performance in R

* profiling with `profr`, to find out what parts of your code are taking up the most time

* microbenchmarking with `microbenchmark` to explore alternative implementations of small parts of your code

* comparing alternatives with `system.time`

* checking for performance regressions with `TBA`. ([Vbench](http://wesmckinney.com/blog/?p=373))

Along the way, you'll also learn about the most common causes of poor performance in R, and how to address them. Sometimes there's no way to improve performance within R, and you'll need to use [[Rcpp]], the topic of the next chapter.

Having a good test suite is important when tuning the performance of your code: you don't want to make your code fast at the expense of making it incorrect. We won't discuss testing any further in this chapter, but we strongly recommend having a good set of test cases written before you begin optimisation.

## Copy-on-modify semantics

The most common cause of performance problems in R are its copy on modify semantics: it's easy to think that you're modifying an object in place, but you're actually creating a new copy each time.  It's not that loops are slow, it's that if you're not careful every time you modify an object inside a list it makes a complete copy.

C functions are usually faster not because the loop is written in C, but because C's default behaviour is to modify in place, not make a copy. This is less safe, but much more efficient. If you're modifying a data structure in a loop, you can often get big performance gains by switching to the vectorised equivalent.  When working with matrices and data frames, this often means creating a large object that you can combine with a single operation.

Take the following code that subtracts the median from each column of a large data.frame:

    x <- data.frame(matrix(runif(100 * 1e4), ncol = 100))
    medians <- vapply(x, median, numeric(1))

    system.time({
      for(i in seq_along(medians)) {
        x[, i] <- x[, i] - medians[i]
      }
    })

It's rather slow - we only have 100 columns and 10,000 rows, but it's still taking over second. We can use `address()` to see what's going on. This function returns the memory address that the object occupies:

    system.time({
      for(i in seq_along(medians)) {
        x[, i] <- x[, i] - medians[i]
        print(address(x))
      }
    })

We can rewrite it to be much faster by eliminating all those copies, and instead relying on vectorised data frame subtraction. That loop occurs at the C-level, which means the data frame is only copied once, not many many times.

    system.time({
      y - as.list(medians)
    })

The art of R performance improvement is to build up a good intuitions for what operations incur a copy, and what occurs in place. Each version of R usually implements a few performance improvements that eliminates copies, so it's impossible to give an up-to-date list, but some rules of thumb are:

* `structure(x, class = "c")` makes a copy.  `class(x) <- c` does not.

* Modifying a vector in place with `[<-` or `[[<-` does not make a copy.  Modifying a data frame in place does make a copy.  Modifying a list in place makes a copy, but it's a shallow copy: each individual component of the list is not copied. 

* `names<-`, `attr<-` and `attributes<-` don't make a copy

* Avoid modifying complex objects (like data frames) repeatedly and instead pull out the component you want to modify, modify it, and then put it back in.  If that doesn't work, converting it to a simpler object type and then converting back might help:

      system.time({
        y <- as.list(x)
        for(i in seq_along(medians)) {
          y[[i]] <- y[[i]] - medians[i]
        }
        x <- as.data.frame(y)
      })

If you thinking copying is causing a bottleneck in your program, then I recommend running some small experiments using `address()` and `microbenchmark` as described below. 

## Performance profiling

R provides a built in tool for profiling: `Rprof`. When active, this records the current call stack to disk very `interval` seconds. This provides a fine grained report showing how long each function takes. The function `summaryRprof` provides a way to turn this list of call stacks into useful information. But I don't think it's terribly useful, because it makes it hard to see the entire structure of the program at once. Instead, we'll use the `profr` package, which turns the call stack into a data.frame that is easier to manipulate and visualise.

## Micro-benchmarking

Once you have identified the performance bottleneck in your code, you'll want to try out many variant approaches.

The [microbenchmark][microbenchmark] function uses a more precise timing mechanism than `system.time` allowing it to accurately compare functions that take a small amount of time without having to repeat the function many times.  It also takes care to estimate the overhead associated with timing, and randomly orders the evaluation of each expression. It also times each expression individually, so you get a distribution of times, which helps estimate error. 

Generally, microbenchmark makes it easier to profile very small parts of your code, without having to worry about padding the results so that `system.time` can pick it up.

The following example compares two different ways of computing means of random uniform numbers, as you might use for simulations teaching the central limit theorem (inspired by the rbenchmark documentation)
    
    library(microbenchmark)
    res2 <- microbenchmark(
      seq = sequential(100, 100),
      par = parallel(100, 100),
      times = 100
    )
    print(res2, unit = "s")

When doing microbenchmarking, you not only need to figure out what the best method is now, but you need to make sure that fact is recorded somewhere so that when you come back to the code in the future, you remember your reasoning and don't have to redo it again.  I find it really useful to write microbenchmarking code as Rmarkdown documents so that I can easily integrate the benchmarking code as well as text describing my hypotheses about why one method is better than another, and listing things that I tried that wasn't so effective.

### Method dispatch

We can also use `microbenchmark` to explore the costs of method dispatch in R.  The following microbenchmark compares the cost of generating one uniform number directly, with a function, with a S3 method

    runif(1)
    f <- function(x) runif(1)

    s3 <- function(x) UseMethod("s3")
    s3.integer <- function(x) runif(1)

    setClass("A", representation(a = "list"))
    setGeneric("s4", function(x) standardGeneric("s4"))
    setMethod(s4, "A", function(x) runif(1))
    a <- new("A")

    microbenchmark(
      bare = runif(1),
      fun = f(),
      s3 = s3(1L),
      s4 = s4(a)
    )

On my computer, the bare call takes about 2.5 µs. Wrapping it in a function adds about an extra 0.2 µs - this is the cost of creating the environment where the function execution happens. S3 method dispatch adds around 3 µs and S4 around 12 µs.

However, it's important to notice the units: microseconds. There are a million microseconds in a second, so it will take hundreds of thousands of calls before the cost of S3 or S4 dispatch appreciable. Most problems don't involve hundreds of thousands of function calls, so it's unlikely to be a bottleneck in practice.This is why microbenchmarks can not considering in isolation: they must be  carefully considered in the context of your real problem.

### Extracting variables out of a data frame

For the plyr package, I did a lot of experimentation to figure out the fastest way of extracting data out of a data frame.

    n <- 1e5
    df <- data.frame(matrix(runif(n * 100), ncol = 100))
    x <- df[[1]]
    x_ran <- sample(n, 1e3)

    microbenchmark(
      x[x_ran]
      df[x_ran, 1],
      df[[1]][x_ran],
      df$X1[x_ran],
      df[["X1"]][x_ran],
      .subset2(df, 1)[x_ran],
      .subset2(df, "X1")[x_ran],
    )

Again, the units are in microseconds, so you only need to care if you're doing hundreds of thousands of data frame subsets - but for plyr I am doing that so I do care.

## Caching

`readRDS`, `saveRDS`, `load`, `save`

### Byte code compilation

R 2.13 introduced a new byte code compiler which can increase the speed of certain types of code 4-5 fold. This improvement is likely to get better in the future as the compiler implements more optimisations - this is an active area of research.

Using the compiler is an easy way to get speed ups - it's easy to use, and if it doesn't work well for your function, then you haven't invested a lot of time in it, and so you haven't lost much.

## Memory profiling

`object.size`

There are three ways to explore memory usage:

  * `tracemem`
  * `Rprof` + `memory`
  * `Rprofmem`

[microbenchmark]: http://cran.r-project.org/web/packages/microbenchmark/index.html
