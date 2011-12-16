# Dealing with errors and exceptions

This chapter describes techniques to use when things go wrong:

* Exceptions: dealing with errors in your code

* Debugging: understanding or figuring out problems in other people's codes
  (debugging) The debugging techniques are also useful when you're trying to
  understand other people's R code, or R code that I've highlighted through
  out this book that you should be able to tease apart and figure out how it
  works.

* Getting help: what to do if you can't figure out what the problem is

As with many other parts of R, the approach to dealing with errors and exceptions comes from a LISP-heritage, and is quite different (although some of the terminology is the same) to that of languages like Java.

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

It's also possible to  start `browser` automatically when an error occurs, by setting `option(error = browser)`. This will start the interactive debugger in the environment in which the error occurred. Other functions that you can supply to `error` are:

* `recover`: a step up from `browser`, as it allows you to drill down into any
  of the calls in the call stack. This is useful because often the cause of
  the error is a number of calls back - you're just seeing the consequences.
  This is the result of "fail-slow" code

* `dump.frames`: an equivalent to `recover` for non-interactive code. Will
  save an `rdata` file containing the nested environments where the error
  occurred. This allows you to later use `debugger` to re-create the error as
  if you had called `recover` from where the error occurred

* `NULL`: the default. Prints an error message and stops function execution.

We can use `withCallingHandlers` to set up something similar for warnings. The following function will call the specified action when a warning is generated. The code is slightly tricky because we need to find the right environment to evaluate the action - it should be the function that calls warning.

    on_warning <- function(action, code) {
      q_action <- substitute(action)
      
      withCallingHandlers(code, warning = function(c) {
        for(i in seq_len(sys.nframe())) {
          f <- as.character(sys.call(i)[[1]])
          if (f == "warning") break;
        }
        
        eval(q_action, sys.frame(i - 1))
      })
    }
    
    x <- 1
    f <- function() {
      x <- 2
      g()
    }
    g <- function() {
      x <- 3
      warning("Leaving g")
    }
    on_warning(browser(), f())
    on_warning(recover(), f())

### Creative uses of trace

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

One problem of this approach is that we don't automatically pick up any `primitive` functions, because for these functions formals returns `NULL`.

## Exceptions

Defensive programming is the art of making code fail in a well-defined manner even when something unexpected occurs. There are two components of this art related to exceptions: raising exceptions as soon as you notice something has gone wrong, and responding to errors as cleanly as possible.

A general principle for errors is to "fail fast" - as soon as you figure out something as wrong, and your inputs are not as expected, you should raise an error.  

### Creating

There are a number of options for letting the user know when something has gone wrong:

* don't use `cat()` or `print()`, except for print methods, or for optional
  debugging information.

* use `message()` to inform the user about something expected - I often do
  this when filling in important missing arguments that have a non-trivial
  computation or impact. Two examples are `reshape2::melt` package which
  informs the user what melt and id variables where used if not specific, and
  `plyr::join` which informs which variables where used to join the two
  tables.

* use `warning()` for unexpected problems that aren't show stoppers.
  `options(warn = 2)` will turn warnings into errors into. Warnings are often
  more appropriate for vectorised functions when a single value in the vector
  is incorrect, e.g. `log(-1:2)` and `sqrt(-1:2)`.

* use `stop()` when the problem is so big you can't continue

* `stopifnot()` is a quick and dirty way of checking that pre-conditions for
  your function are met. The problem with `stopifnot` is that if they aren't
  met, it will display the test code as an error, not a more informative
  message. Checking pre-conditions with `stopifnot` is better than nothing,
  but it's better still to check the condition yourself and return an
  informative message with `stop()`

### Handling

<!-- 
http://www.nhplace.com/kent/Papers/Condition-Handling-2001.html
http://www.stat.uiowa.edu/~luke/R/exceptions/simpcond.html 
-->

Error handling is performed with the `try` and `tryCatch` functions. `try` is a simpler version, so we'll start with that first. The `try` functions allows execution to continue even if an exception occurs, and is particularly useful when operating on elements in a loop. The `silent` argument controls whether or not the error is still printed. 

    elements <- list(1:10, c(-1, 10), c(T, F), letters)
    results <- lapply(elements, log)
    results <- lapply(elements, function(x) try(log(x)))

If code fails, `try` invisibly returns an object of class `try-error`. There isn't a built in function for testing for this class, so we'll define one. Then we can easily strip all errors out of a list with `Filter`:

    is.error <- function(x) inherits(x, "try-error")
    successful <- Filter(Negate(is.error), results)
    
Of if we want to know where the successes and failures were, when can use `sapply` or `vapply`:

    vapply(results, is.error, logical(1))
    sapply(results, is.error)
    
    # (Aside: vapply is preferred when you're writing a function because
    # it guarantees you'll always get a logical vector as a result, even if
    # you list has length zero)
    sapply(NULL, is.error)
    vapply(NULL, is.error, logical(1))    
    
If we wanted to avoid the anonymous function call, we could create our own function to automatically wrap a call in a `try`:

    try_to <- function(f, silent = FALSE) {
      function(...) try(f(...), silent = silent)
    }
    results <- lapply(elements, try_to(log))

`tryCatch` gives more control than `try`, but to understand how it works, we first need to learn a little about conditions, the S3 objects that represent errors, warnings and messages.

    is.condition <- function(x) inherits(x, "condition")
    
There are three convenience methods for creating errors, warnings and messages.  All take two arguments: the `message` to display, and an optional `call` indicating where the condition was created

    e <- simpleError("My error", quote(f(x = 71)))
    w <- simpleWarning("My warning")
    m <- simpleMessage("My message")
  
There is one class of conditions that can't be directly: interrupts, which occur when the user presses Ctrl + Break, Escape, or Ctrl + C (depending on the platform) to terminate execution.

The components of a condition can be extracted with `conditionMessage` and `conditionCall`:
    
    conditionMessage(e)
    conditionCall(e)

Conditions can be signalled using `signalCondition`. By default, no one is listening, so this doesn't do anything.

    signalCondition(e)
    signalCondition(w)
    signalCondition(m)

To listen to signals, we have two tools: `tryCatch` and `withCallingHandlers`.  
`tryCatch` is an exiting handler: it catches the condition, but the rest of the code after the exception is not run. `withCallingHandlers` sets up calling handlers: it catches the condition, and then resumes execution of the code.  We will focus first on `tryCatch`.

The `tryCatch` call has three arguments:

* `expr`: the code to run.

* `...`: a set of named arguments setting up error handlers. If an error
  occurs, `tryCatch` will call the first handler whose name matches one of the
  classes of the condition. The only useful names for built-in conditions are
  `interrupt`, `error`, `warning` and `message`.

* `finally`: code to run regardless of whether `expr` succeeds or fails. This
  is useful for clean up, as described below. All handlers have been turned
  off by the time the `finally` code is run, so errors will propagate as
  usual.

The following examples illustrate the basic properties of `tryCatch`:

    # Handlers are passed a single argument
    tryCatch(stop("error"), 
      error = function(...) list(...)
    )
    # This argument is the signalled condition, so we'll call
    # it c for short.

    # If multiple handlers match, the first is used
    tryCatch(stop("error"), 
      error = function(c) "a",
      error = function(c) "b"
    )

    # If multiple signals are nested, the the most internal is used first.
    tryCatch(
      tryCatch(stop("error"), error = function(c) "a"),
      error = function(c) "b"
    )

    # Uncaught signals propagate outwards. 
    tryCatch(
      tryCatch(stop("error")),
      error = function(c) "b"
    )

    # The first handler that matches a class of the condition is used, 
    # not the "best" match:
    a <- structure(list(message = "my error", call = quote(a)), 
      class = c("a", "error", "condition"))

    tryCatch(stop(a), 
      error = function(c) "error",
      a = function(c) "a"
    )
    tryCatch(stop(a), 
      a = function(c) "a",
      error = function(c) "error"
    )

    # No matter what happens, finally is run:
    tryCatch(stop("error"), 
      finally = print("Done."))
    tryCatch(a <- 1, 
      finally = print("Done."))
      
    # Any errors that occur in the finally block are handled normally
    a <- 1
    tryCatch(a <- 2, 
      finally = stop("Error!"))

What can handler functions do?

* Return a value.

* Pass the condition along, by re-signalling the error with `stop(c)`, or
  `signalCondition(c)` for non-error conditions.

* Kill the function completely and return to the top-level with
  `invokeRestart("abort")`

A common use for `try` and `tryCatch` is to set a default value if a condition fails. The easiest way to do this is to assign within the `try`:

    success <- FALSE
    try({
      # Do something that might fail
      success <- TRUE
    })

We can write a simple version of `try` using `tryCatch`. The real version of `try` is considerably more complicated to preserve the usual error behaviour.

    try <- function(code, silent = FALSE) {
      tryCatch(code, error = function(c) {
        if (!silent) message("Error:", conditionMessage(c))
        invisible(structure(conditionMessage(c), class = "try-error"))
      })
    } 
    try(1)
    try(stop("Hi"))
    try(stop("Hi"), silent = TRUE)
    
    rm(try)
    
    withCallingHandlers({
      a <- 1
      stop("Error")
      a <- 2
    }, error = function(c) {})

### Using `tryCatch`

With the basics in place, we'll next develop some useful tools based the ideas we just learned about.

<!-- * capturing all messages or warnings produced by a function
* returning a value even when a user interrupts: `Ctrl + C` -->

      browse_on_error <- function(f) {
        function(...) {
          tryCatch(f(...), error = function(c) browser())
        }
      }


The `finally` argument to `tryCatch` is very useful for clean up, because it is always called, regardless of whether the code executed successfully or not. This is useful when you have:

* modified `options`, `par` or locale
* opened connections, or created temporary files and directories
* opened graphics devices
* changed the working directory
* modified environment variables

The following function changes the working directory, executes some code, and always resets the working directory back to what it was before, even if the code raises an error.

    in_dir <- function(path, code) {
      cur_dir <- getwd()
      tryCatch({
        setwd(path)
        force(code)
      }, finally = setwd(cur_dir))
    }
    
    getwd()
    in_dir(R.home(), dir())
    getwd()
    in_dir(R.home(), stop("Error!"))
    getwd()

Another more casual way of cleaning up is the `on.exit` function, which is called when the function terminates.  It's not as fine grained as `tryCatch`, but it's a bit less typing.

## Getting help

Currently, there are two main venues to get help when you are stuck and can't figure out what's causing the problem: [stackoverflow](http://stackoverflow.com) and the R-help mailing list..

While you can get some excellent advice on R-help, fools are not tolerated gladly, so follow the tips below for getting the best help:

* Make sure you have the latest version of R, and the package (or packages)
  you are having problems with. It may be that your problem is the result of a
  bug that has been fixed recently.

* If it's not clear where the problem is, include the results of
  `sessionInfo()` so others can see your R setup.

* Spend some time creating a reproducible example. Make sure you have run your
  script in a vanilla R sessions (`R --vanilla`). This is often a useful
  example by itself, because in the course of making the problem reproducible
  you figure out what's causing the problem.

## Exercises

1. Write a function that walks the code tree to find all functions that are missing an explicit drop argument that need them.

1. Write a function that takes code as an argument and runs that code with `options(warn = 2)` and returns options back to their previous values on exit (either from an exception or a normal exit).

1. Write a function that opens a graphics device, runs the supplied code, and closes the graphics device (always, regardless of whether or not the plotting code worked).