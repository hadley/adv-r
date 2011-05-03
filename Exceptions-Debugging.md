# Dealing with errors and exceptions

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

* use `warning()` for unexpected problems that aren't show stoppers

* use `stop()` when the problem is so big you can't continue

### Handling

  * `try`
  * `tryCatch`

Examples:

  * capturing all messages or warnings produced by a function
  * capturing user interrupts: `Ctrl + C`

`suppressWarnings`, `suppressMessages`

## Debugging

* `traceback`: show where error occurred
* `browser`: interact inside function environment.  `c`, `n`, `return`, `Q`, `where`
* `debug`/`undebug`, `debugonce`: automatically inserts browser
* `trace`, `untrace`: automatically inserts any code
* `recover`, `options(error = recover)`: automatic traceback + browser on error

If you're trying to track down where a warning occurs, it can be useful to turn it into an error with `options(warn = 2)`.  Turn back to default behaviour with `options(warn = 0)`.

Don't forget that you can combine `if` statements with `browser()` to only debug when a certain situation occurs.

## Trace

Our first step is to find all functions that have a `na.rm` argument.  We'll do this by first building a list of all functions in base and stats, then inspecting their formals.

  objs <- c(ls("package:base", "package:stats"))
  has_missing_arg <- function(name) {
    x <- get(name)
    if (!is.function(x)) return(FALSE)
    
    args <- names(formals(x))
    "na.rm" %in% args
  }
  f_miss <- Filter(has_missing_arg, objs)
  
  trace_all <- function(fs, tracer) {
    sapply(fs, trace, tracer = tracer, print = FALSE)
    return()
  }
  
  trace_all(f_miss, quote(if(missing(na.rm)) stop("na.rm not set")))
  # But misses primitives
  
  pmin(1:10, 1:10)
  # Error in eval(expr, envir, enclos) : na.rm not set
  pmin(1:10, 1:10, na.rm = T)
  # [1]  1  2  3  4  5  6  7  8  9 10

## Exercises

1. Write a function that walks the code tree to find all functions that are missing an explicit drop argument that need them.