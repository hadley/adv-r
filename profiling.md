# Profiling and benchmarking

"We should forget about small efficiencies, say about 97% of the time: premature optimization is the root of all evil" --- Donald Knuth.

Your code should be correct, maintainable and fast. Notice that speed comes last - if your function is incorrect or unmaintainable (i.e. will eventually become incorrect) it doesn't matter if it's fast. As computers get faster and R is optimised, your code will get faster all by itself. Your code is never going to automatically become correct or elegant if it is not already.

That said, sometimes there are times where you need to make your code faster: spending several hours of your day might save days of computing time for others. The aim of this chapter is to give you the skills to figure out why your code is slow, what you can do to improve it, and ensure that you don't accidentally make it slow again in the future.  You may already be familiar with `system.time`, which tells you how long a block of code takes to run. This is a useful building block, but is a crude tool.

Making fast code is a four part process:

1. Profiling helps you discover parts of your code are taking up the most time

2. Microbenchmarking lets you experiment with small parts of your code to find faster approaches.

3. Timing helps you check that the micro-optimisations have a macro effect, and helps experiment with larger changes (like totally rethinking your approach)

4. A performance testing tool makes sure your code stays fast in the future  (e.g. [Vbench](http://wesmckinney.com/blog/?p=373))

Along the way, you'll also learn about the most common causes of poor performance in R, and how to address them. Sometimes there's no way to improve performance within R, and you'll need to use [[Rcpp]], the topic of the next chapter.

Having a good test suite is important when tuning the performance of your code: you don't want to make your code fast at the expense of making it incorrect. We won't discuss testing any further in this chapter, but we strongly recommend having a good set of test cases written before you begin optimisation.

## Performance profiling

R provides a built in tool for profiling: `Rprof`. When active, this records the current call stack to disk very `interval` seconds. This provides a fine grained report showing how long each function takes. The function `summaryRprof` provides a way to turn this list of call stacks into useful information. But I don't think it's terribly useful, because it makes it hard to see the entire structure of the program at once. Instead, we'll use the `profr` package, which turns the call stack into a data.frame that is easier to manipulate and visualise.

Example showing how to use profr.

Sample pictures.

### Copy-on-modify semantics

If much of your time is taken up by `[` or `[[` then you may be victim of the most common cause of performance problems in R: its copy on modify semantics.  In R, it's easy to think that you're modifying an object in place, but you're actually creating a new copy each time. 

It's not that loops are slow, it's that if you're not careful every time you modify an object inside a list it makes a complete copy. C functions are usually faster not because the loop is written in C, but because C's default behaviour is to modify in place, not make a copy. This is less safe, but much more efficient. If you're modifying a data structure in a loop, you can often get big performance gains by switching to the vectorised equivalent.  When working with matrices and data frames, this often means creating a large object that you can combine with a single operation.

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
        print(address(x[[i]]))
      }
    })

Each iteration of the loop prints a different memory address - the complete data frame is being modified and copied for each iteration.

We can rewrite it to be much faster by eliminating all those copies, and instead relying on vectorised data frame subtraction: if you subtract a list from a data frame, the elements of the list are matched up with the elements of the data frame. That loop occurs at the C-level, which means the data frame is only copied once, not many many times.

    system.time({
      y - as.list(medians)
    })

The art of R performance improvement is to build up a good intuitions for what operations incur a copy, and what occurs in place. Each version of R usually implements a few performance improvements that eliminates copies, so it's impossible to give an up-to-date list, but some rules of thumb are:

* `structure(x, class = "c")` makes a copy.  `class(x) <- c` does not.

* Modifying a vector in place with `[<-` or `[[<-` does not make a copy.  Modifying a data frame in place does make a copy. Modifying a list in place makes a copy, but it's a shallow copy: each individual component of the list is not copied. 

* `names<-`, `attr<-` and `attributes<-` don't make a copy

* Avoid modifying complex objects (like data frames) repeatedly and instead pull out the component you want to modify, modify it, and then put it back in.  If that doesn't work, converting it to a simpler object type and then converting back might help:

      system.time({
        y <- as.list(x)
        for(i in seq_along(medians)) {
          y[[i]] <- y[[i]] - medians[i]
        }
        x <- as.data.frame(y)
      })

Generally, building up a rich vocabulaory of vectorised functions will help you write performant code.  Vectorisation basically means pushing a for-loop from R in C so that only one copy of the data structure is made.

If you thinking copying is causing a bottleneck in your program, then I recommend running some small experiments using `address()` and `microbenchmark` as described below. 

## Micro-benchmarking

Once you have identified the performance bottleneck in your code, you'll want to try out many variant approaches.

The [microbenchmark][microbenchmark] package is much more precise than `system.time`, nanosecond rather than millisecond precision. This makes it much easier to compare operations that only take a small amount of time. For example, we can determine the overhead of calling a function: (for an example in the package)

    f <- function() NULL
    microbenchmark(
      NULL,
      f())

It's about ~150 ns on my computer (that's the time taken to set up the new environment for the function etc). 

It's hard to accurately compute this difference with `system.time` because we need to repeat the operation about a million times, and we get no information about the variability of the estimate.  The results may also be systematically biased if some other computation is happening in the background during one of the runs.
  
    x <- 1:1e6
    system.time(for (i in x) NULL) * 1e3
    system.time(for (i in x) f()) * 1e3

Running both examples on my computer a few times reveals that the estimate from `system.time` is about 20 nanoseconds higher than the median from `microbenchmark`.

By default, microbenchmark evaluates each expression 100 times, and in random order to control for any systematic variability. It also provides times each expression individually, so you get a distribution of times, which helps estimate error.  You can also display the results visually using either `boxplot`, or if you have `ggplot2` loaded, `autoplot`:

    f <- function() NULL
    g <- function() f()
    h <- function() g()
    i <- function() h()
    m <- microbenchmark(
      NULL,
      f(), 
      g(),
      h(),
      i())
    boxplot(m)
    library(ggplot2)
    autoplot(m)

<!-- The following example compares two different ways of computing means of random uniform numbers, as you might use for simulations teaching the central limit theorem:
    
    sequential <- function(m, n) replicate(m, mean(runif(n)))
    parallel <- function(m, n) rowMeans(matrix(runif(m * n), ncol = n))

    library(microbenchmark)
    microbenchmark(
      seq = sequential(100, 100),
      par = parallel(100, 100)
    )
 -->
 - 
Microbenchmarking allows you to take the very small parts of a program that profiling has identified as being bottlenecks and explore alternative approaches.  It is easier to do this with very small parts of a program because you can rapidly try out alternatives without having to worry too much about correctness (i.e. you are comparing alternatives that are so simple it's obvious whether they're correct or not.)

Useful to think about the first part of the process, generating possible alternatives as brainstorming.  You want to come up with as many different approaches to the problem as possible.  Don't worry if some of the approaches seem like they will _obviously_ be slow: you might be wrong, or that approach might be one step towards a better approach.  To get out of a local maxima, you must go down hill.

When doing microbenchmarking, you not only need to figure out what the best method is now, but you need to make sure that fact is recorded somewhere so that when you come back to the code in the future, you remember your reasoning and don't have to redo it again. I find it really useful to write microbenchmarking code as Rmarkdown documents so that I can easily integrate the benchmarking code as well as text describing my hypotheses about why one method is better than another, and listing things that I tried that weren't so effective.

Microbenchmarking is also a powerful tool to improve your intuition about what operations in R are fast and what are slow. The following XXX examples show how to use microbenchmarking to determine the costs of some common R actions, but I really recommend setting up some experiments for the R functions that you use most commonly.

* What's the cost of function vs S3 or S4 method dispatch? 
* What's the fastest way to extract a column out of data.frame?

### Method dispatch

The following microbenchmark compares the cost of generating one uniform number directly, with a function, with a S3 method, with a S4 method and a R5 

    f <- function(x) NULL

    s3 <- function(x) UseMethod("s3")
    s3.integer <- function(x) NULL

    A <- setClass("A", representation(a = "list"))
    setGeneric("s4", function(x) standardGeneric("s4"))
    setMethod(s4, "A", function(x) NULL)

    B <- setRefClass("B")
    B$methods(r5 = function(x) NULL)

    a <- A()
    b <- B$new()

    microbenchmark(
      bare = NULL,
      fun = f(),
      s3 = s3(1L),
      s4 = s4(a),
      r5 = b$r5()
    )

On my computer, the bare call takes about 40 ns. Wrapping it in a function adds about an extra 200 ns - this is the cost of creating the environment where the function execution happens. S3 method dispatch adds around 3 µs and S4 around 12 µs.

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

### Vectorised operations on a data frame

    df <- data.frame(a = 1:10, b = -(1:10))
    l <- list(0, 10)
    l_2 <- list(rep(0, 10), rep(10, 10))
    m <- matrix(c(0, 10), ncol = 2, nrow = 10, byrow = TRUE)
    df_2 <- as.data.frame(m)
    v <- as.numeric(m)

    microbenchmark(
      df + v,
      df + l,
      df + l_2,
      df + m,
      df + df_2
    )

## Timing

## Performance testing

<!-- ## Memory profiling

`object.size`

There are three ways to explore memory usage:

  * `tracemem`
  * `Rprof` + `memory`
  * `Rprofmem`
 -->

[microbenchmark]: http://cran.r-project.org/web/packages/microbenchmark/index.html
