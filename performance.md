# Profiling performance and memory

"We should forget about small efficiencies, say about 97% of the time: premature optimization is the root of all evil" --- Donald Knuth.

What can you do if your code is slow?  Before you can figure out how to improve it, you first need to figure out why it's slow.  That's what this chapter will teach you.

* Build up your vocab, and use built-in vectorised operations where possible.

* Figure out what is slow and then optimise that

## Benchmarking

The basic tool for benchmarking, recording how long an operation takes, is `system.time`. 

There are two contributed packages that provide useful additional functionality:

* The [rbenchmark](http://code.google.com/p/rbenchmark/) package provides a convenient wrapper around `system.time` that allows you to compare multiple functions and run them multiple times

* The [microbenchmark][microbenchmark] function uses a more precise timing mechanism than `system.time` allowing it to accurately compare functions that take a small amount of time without having to repeat the function millions of time.  It also takes care to estimate the overhead associated with timing, and randomly orders the evaluation of each expression. It also times each expression individually, so you get a distribution of times, which helps estimate error.

The following example compares two different ways of computing means of random uniform numbers, as you might use for simulations teaching the central limit theorem (inspired by the rbenchmark documentation)

    sequential <- function(n, m) mean(replicate(n, runif(m)))
    parallel   <- function(n, m) colMeans(matrix(runif(n*m), m, n))

    library(rbenchmark)
    res1 <- benchmark(
      seq = sequential(100, 100),
      par = parallel(100, 100),
      replications=10^(0:2),
      order = c('replications', 'elapsed'))
    res1$elapsed <- res1$elapsed / res1$replications
    
    library(microbenchmark)
    res2 <- microbenchmark(
      seq = sequential(100, 100),
      par = parallel(100, 100),
      times = 100
    )
    print(res2, unit = "s")

## Performance profiling

R provides a built in tool for profiling: `Rprof`. When active, this records the current call stack to disk very `interval` seconds. This provides a fine grained report showing how long each function takes. 

The function `summaryRprof` provides a way to turn this list of call stacks into useful information. But I don't think it's terribly useful, because it makes it hard to see the entire structure of the program at once. Instead, we'll use the `profr` package, which turns the call stack into a data.frame that is easier to manipulate and visualise.

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