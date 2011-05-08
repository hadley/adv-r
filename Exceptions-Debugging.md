# Dealing with errors and exceptions

This chapter describes techniques to use when things go wrong:

* Exceptions: dealing with errors in your code

* Debugging: understanding or figuring out problems in other people's codes
  (debugging) The debugging techniques are also useful when you're trying to
  understand other people's R code, or R code that I've highlighted through
  out this book that you should be able to tease apart and figure out how it
  works.

* Getting help: what to do if you can't figure out what the problem is

## Interactive analysis vs. programming

There is a tension between interactive analysis and programming. When you a doing an analysis, you want R to do what you mean, and if it guesses wrong, then you'll discover it right away and can fix it. If you're creating a function, then you want to make it as robust as possible so that any problems become apparent right away (see fail fast below).

* Be explicit:

  * Be explicit about missings

  * Use `TRUE` and `FALSE` instead of `T` and `F`

  * Try to avoid relying on position matching or partial name matching when
    calling functions

* Avoid functions that can return different types of objects:

  * Always use `drop = FALSE`

  * Don't use `sapply`: use `vapply`, or `lapply` plus the appropriate
    transformation

## Debugging

The key function for performing a post-mortem on an error is `traceback`, which shows all the calls leading up to the error. This can help you figure out where the error occurred, but often you'll need the interactive environment created by `browser`:

* `c`: leave interactive debugging and continue execution

* `n`: execute the next step. Be careful if you have a variable named `n`: to
  print it you'll need to be explicit `print(n)`.

* `return`: the default behaviour is the same as `c`, but this is somewhat
  dangerous as it makes it very easy to accidentally continue during
  debugging. I recommend `options(browserNLdisabled = TRUE)` so that `return`
  is simply ignored.

* `Q`: stops debugging, terminate the function and return to the global
  workspace

* `where`: prints stack trace of active calls (the interactive equivalent of
  `traceback`)

You can add Don't forget that you can combine `if` statements with `browser()` to only debug when a certain situation occurs.

### Browsing arbitrary R code

There are two ways to insert `browser()` statements in arbitrary R code:

* `debug` inserts a browser statement in the first line of the specified
  function. `undebug` will remove it, or you can use `debugonce` to insert a
  browser call for the next run, and have it automatically removed afterwards.

* `utils::setBreakpoint` does the same thing, but instead inserts `browser` in
  the function corresponding to the specified file name and line number.

These two functions are both special cases of `trace()`, which allows you to insert arbitrary code in any position in an existing function. The complement of `trace` is `untrace`. You can only perform one trace per function - subsequent traces will replace prior.

Locating warnings is a little trickier. The easiest way to turn it in an error with `options(warn = 2)` and then use the standard functions described above. Turn back to default behaviour with `options(warn = 0)`.

### Browsing on error

It's also possible to start `browser` automatically when an error occurs, by setting `option(error = browser)`. This will start the interactive debugger in the environment in which the error occurred. Other functions that you can supply to `error` is:

* `recover`: a step up from `browser`, as it allows you to drill down into any
  of the calls in the call stack. This is useful because often the cause of
  the error is a number of calls back - you're just seeing the consequences.
  This is the result of "fail-slow" code

* `dump.frames`: an equivalent to `recover` for non-interactive code. Will
  save an `rdata` file containing the nested environments where the error
  occurred. This allows you to later use `debugger` to re-create the error as
  if you had called `recover` from where the error occurred

* `NULL`: the default. Prints an error message and stops function execution.

### Create uses of trace

Trace is a useful debugging function that along with some of our computing on the language tools can be used to set up warnings on a large number of functions at a time. This is useful if you for automatically detecting some of the errors described above. The first step is to find all functions that have a `na.rm` argument. We'll do this by first building a list of all functions in base and stats, then inspecting their formals.

  objs <- c(ls("package:base", "package:stats"))
  has_missing_arg <- function(name) {
    x <- get(name)
    if (!is.function(x)) return(FALSE)
    
    args <- names(formals(x))
    "na.rm" %in% args
  }
  f_miss <- Filter(has_missing_arg, objs)

Next, we write a version of trace vectorised over the function name, and then use that function to add a warning to every function that we found above.

  trace_all <- function(fs, tracer, ...) {
    lapply(fs, trace, tracer = tracer, print = FALSE, ...)
    invisible(return())
  }
  
  trace_all(f_miss, quote(if(missing(na.rm)) stop("na.rm not set")))
  # But misses primitives
  
  pmin(1:10, 1:10)
  # Error in eval(expr, envir, enclos) : na.rm not set
  pmin(1:10, 1:10, na.rm = T)
  # [1]  1  2  3  4  5  6  7  8  9 10

One disadvantage of this approach is that we don't automatically pick up any `primitive` functions, because for these functions formals returns `NULL`.

## Exceptions

### Creating

* don't use `cat()` or `print()`, except for print methods, or for optional
  debugging information.

* use `message()` to inform the user about something expected - I often do
  this when filling in important missing arguments that have a non-trivial
  computation or impact. Two examples are `reshape2::melt` package which
  informs the user what melt and id variables where used if not specific, and
  `plyr::join` which informs which variables where used to join the two
  tables.

* use `warning()` for unexpected problems that aren't show stoppers.  `options(warning = 2)` will turn errors into warnings

* use `stop()` when the problem is so big you can't continue

* `stopifnot`

### Handling

  * `try`
  * `tryCatch`

Examples:

  * capturing all messages or warnings produced by a function
  * capturing user interrupts: `Ctrl + C`

`suppressWarnings`, `suppressMessages`

### Fail fast

A general principle for errors is to "fail fast" - as soon as you figure out something as wrong, and your inputs are not as expected, you should raise an error.


### Ensuring stuff happens

When 

* return `options`, `par` and locale
* close connections, delete temporary files and directories
* close graphics devices
* working directory
* environment variables

`on.exit`

`tryCatch` + finally.

## Getting help

stackoverflow
r-help

## Exercises

1. Write a function that walks the code tree to find all functions that are missing an explicit drop argument that need them.

1. Write a function that takes code as an argument and runs that code with `options(warn = 2)` and returns options back to their previous values on exit (either from an exception or a normal exit)