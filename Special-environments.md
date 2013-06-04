# Special contexts

R's lexical scoping rules, lazy argument evaluation and first-class environments make it an excellent environment for designing special environments that allow you to create domain specific languages (DSLs). This chapter shows how you can use these ideas to evaluate code in special contexts that pervert the usual behaviour of R.  We'll start with simple modifications then work our way up to evaluations that completely redefine ordinary function semantics in R.

* Evaluate code in a special context: `local`, `capture.output`, `with_*`

* Supply an expression instead of a function: `curve` 

* Combine evaluation with extra processing: `test_that`, `assert_that`

* Create a full-blown DSL: `html`, `plotmath`, `deriv`, `parseNamespace`, `sql`

## Evaluate code in a special context

It's often useful to evaluate a chunk of code in a special context

* Temporarily modifying global state, like the working directory, environment variables, plot options or locale.

* Capture side-effects of a function, like the text it prints, or the warnings it emits

* Evaluate code in a new environment

### `with_something`

There are a number of parameters in R that have global state (e.g. `option()`, environmental variables, `par()`, ...) and it's useful to be able to run code temporarily in a different context.  devtools provides `with_something()` function to make this a little eaiser:

```R
with_something <- function(set) {
  function(new, code) {
    old <- set(new)
    on.exit(set(old))
    force(code)
  }
}
```

You then combine `with_something()` with a setter function that returns the previous values.  There are a number of base R functions that already behave this way:

```R
in_dir <- with_something(setwd)
with_options <- with_something(options)
with_par <- with_something(par)
```

Others, like `Sys.setlocale()`, need more wrapping:

```R
set_locale <- function(cats) {
  stopifnot(is.named(cats), is.character(cats))

  old <- vapply(names(cats), Sys.getlocale, character(1))

  mapply(Sys.setlocale, names(cats), cats)
  invisible(old)
}
with_locale <- with_something(set_locale)
```

### `capture.output`

`capture.output()` is a useful function when the output you really want from a function is printed to the console. It also allows you to work around badly written functions that have no way to suppress output to the console.  For example, it's difficult to capture the output of `str()`:

```R
y <- 1:10
y_str <- str(y)
y_str

y_str <- capture.output(str(y))
y_str
```

To work its magic, `capture.output()` uses `sink()`, which allows you to redirect the output stream to an arbitrary connection. We'll first write a helper function that allows us to execute code in the context of a `sink()`, automatically un-`sink()`ing when the function finishes:

```
with_sink <- function(connection, code, ...) {
  sink(connection, ...)
  on.exit(sink())

  code
}
with_sink("temp.txt", print("Hello"))
readLines("temp.txt")
```

With this in hand, we just need to add a little extra wrapping to our `capture.output2()` to write to a temporary file, read from it and clean up after ourselves:

```R
capture.output2 <- function(code) {
  temp <- tempfile()
  on.exit(file.remove(temp))
  
  with_sink(temp, force(code))
  readLines(temp)
}
capture.output2(cat("a", "b", "c", sep = "\n"))
```

The real `capture.output()` is a bit more complicated: it uses a local `textConnection` to capture the data sent to sink, and it allows you to supply multiple expressions which are evaluated in turn. Using `with_sink()` this looks like `capture.output3()`

```R
capture.output3 <- function(..., env = parent.frame()) {
  txtcon <- textConnection("rval", "w", local = TRUE)
  
  with_sink(txtcon, {
    args <- dots(...)
    for(i in seq_along(args)) {
      out <- withVisible(eval(args[[i]], env))
      if (out$visible) print(out$value)
    }
  })

  rval
}
```

You might want to compare this function to the real `capture.output()` and think about the simplifications I've made. Is the code easier to understand or harder? Have I removed important functionality? 

If you want to capture more types of output (like messages and warnings), you may find the `evaluate` package helpful. It powers `knitr`, and does it's best to ensure high fidelity between its output and what you'd see if you copy and pasted the code at the console.

### How does local work?

In the process of performing a data analysis, you may create variables that are necessarily because they help break a complicated sequence of steps down in to easily digestible chunks, but are not needed afterwards. For example, in the following example, we might only want to keep the value of c:

```R
a <- 10
b <- 30
c <- a + b
```

It's useful to be able to store only the final result, preventing the intermediate results from cluttering your workspace.  We already know one way of doing this using a function:

```R
c <- (function() {
  a <- 10
  b <- 30
  a + b
})()
```

(In javascript this is called the immediately invoked function expression (IIFE))

R provides another tool that's a little less verbose, the `local()` function:

```R
c <- local({
  a <- 10
  b <- 30
  a + b
})
```

The idea of local is to create a new environment (inheriting from the current environment) and run the code in that:

```R
local2 <- function(expr) {
  envir <- new.env(parent = parent.frame())
  eval(substitute(expr), envir)  
}
```

The real `local()` code is considerably more complicated because it adds a second environment parameter. I don't think this is necessary because if you have an explicit environment parameter, then you can already evaluate code in that environment with `evalq()`.  The source code for `local` is relatively hard to understand because it is very concise and uses some sutble features of evaluation (including non-standard evaluation of both arguments). If you have read [[computing-on-the-language]], you might be able to puzzle it out, but to make it a bit easier I have rewritten it in a simpler style below. 

```R
local2 <- function(expr, envir = new.env()) {
  env <- parent.frame()
  call <- substitute(eval(quote(expr), envir))

  eval(call, env)
}
a <- 100
local2({
  b <- a + sample(10, 1)
  my_get <<- function() b
})
my_get()
```

You might wonder we can't simplify to this:

```R
local3 <- function(expr, envir = new.env()) {
  eval(substitute(expr), envir)
}
```

But it's because of how the arguments are evaluated - default arguments are evalauted in the scope of the function so that `local(x)` would not the same as `local(x, new.env())` without special effort.  

## Anaphoric functions

(
Anaphoric functions), anaphoric if, http://www.arcfn.com/doc/anaphoric.html, http://www.perlmonks.org/index.pl?node_id=666047

Anaphoric functions (http://amalloy.hubpages.com/hub/Unhygenic-anaphoric-Clojure-macros-for-fun-and-profit), are functions that use pronouns. This is easiest to understand with an example using an interesting anaphoric function in base R: `curve()`.  `curve()` draws a plot of the specified function, but interestingly you don't need to use a function, you just supply an expression that uses `x`:

```R
curve(x ^ 2)
curve(sin(x), to = 3 * pi)
curve(log(x))
```

`curve()` works by evaluating the expression in a special environment in which the appropriate `x` exists:

```R
curve2 <- function(expr, xlim, n = 100, env = parent.frame()) {
  env2 <- new.env(parent = env)
  env$x <- seq(xlim[1], xlim[2], length = n)
  
  y <- eval(expr, env2)
  plot(x, y, type = "l", ylab = deparse(substitute(expr)))
}
curve2(sin(x ^ (-2)), c(0.01, 2), 10000)
```

Another way to solve the problem would be to turn the expression into a function using `make_function()`:

```R
curve3 <- function(expr, xlim, n = 100, env = parent.frame()) {
  f <- make_function(alist(x = ), substitute(expr), env)
  
  x <- seq(xlim[1], xlim[2], length = n)
  y <- f(x)
  
  plot(x, y, type = "l", ylab = deparse(substitute(expr)))
}
curve3(sin(x ^ (-2)), c(0.01, 2), 1000)
```

As you can see the approaches take about as much code, and require knowing about the same amount of fundamental R concepts. I would have a slight preference for the second because it would be easier to reuse the part of the `curve3()` that turns an expression into a function.

Anaphoric functions need careful documentation so that the user knows that some variable will have special properties inside the anaphoric function and must otherwise be avoided. (And recall the caveats with any use of non-standard evaluation)

### With connection

We could use this idea to create a function that allows you to use a connection and guarantee that it's closed at the end. A simple implementation like this doesn't work:

```R
with_conn <- function(conn, code) {
  open(conn)
  on.exit(close(conn))

  force(code)
}
```

Because the code has no way to refer to the connection.  Instead we could use an anaphoric function and create the variable `it` in the environment in which the code is evaluated.

```R
with_conn <- function(conn, code, env = parent.frame()) {
  if (!isOpen(conn)) {
    open(conn)
    on.exit(close(conn))
  }

  env2 <- new.env(parent = env)
  env$it <- conn

  eval(substitute(code), env)
}

con <- file("test.txt", "r+")
with_conn(con, {
  writeLines("This is a test", it)
  x <- readChar(it, 5)
  print(x)
  while(isIncomplete(it)) {
    x <- readChar(it, 5)
    print(x)
  }
})
```

## Special environments for run-time checking

We can take the idea of special evaluation contexts and use the idea to implement run-time checks, by executing code in a special environment that warns or errors when the user does something that we think is a bad idea.

### Logical abbreviations

A better approach is to construct a special environment and evaluate the code in that. For example, instead of automatically trying to modify the code, we could create an environment like:

```R
check_logical_abbr <- function(code, env = parent.frame()) {
  new_env <- new.env(parent = env)
  delayedAssign("T", stop("Use TRUE not T"), assign.env = new_env)
  delayedAssign("F", stop("Use FALSE not F"), assign.env = new_env)

  eval(substitute(code), new_env)
}

f <- function(x = T) x
check_logical_abbr(f(T))
check_logical_abbr(f())

check_logical_abbr <- function(code, env = parent.frame()) {
  new_env <- new.env(parent = env)
  on.exit(copy_env(new_env, env))
  delayedAssign("T", stop("Use TRUE not T"), assign.env = new_env)
  delayedAssign("F", stop("Use FALSE not F"), assign.env = new_env)

  eval(substitute(code), new_env)
}

copy_env <- function(src, dest) {
  for(i in ls(src, all.names = TRUE)) {
    dest[[i]] <- src[[i]]
  }
}
```

Note that functions look in the environment in which they were defined so to test large bodies of code, you'll need to run `check_logical_abbr()` as far as out as possible:

```R
check_logical_abbr(source("my-file.r"))
check_logical_abbr(load_all())
# ...
```

### Test that

```R
testthat_env <- new.env()
testthat_env$reporter <- StopReporter$new()

set_reporter <<- function(value) {
  old <- testthat_env$reporter
  testthat_env$reporter <- value
  old
}
get_reporter <<- function() {
  testthat_env$reporter
}
```

```R
with_reporter <- function(reporter, code) {
  reporter <- find_reporter(reporter)

  old <- set_reporter(reporter)
  on.exit(set_reporter(old))

  reporter$start_reporter()
  res <- force(code)
  reporter$end_reporter()

  res
}
```