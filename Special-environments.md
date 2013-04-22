# Special environments

Why?

* to extend the tools you learned in [[evaluation]] to create even more flexible functions for interactive data analysis


Evaluating code in different environments

* Evaluate code in a special context: `local`, `capture.output`, `with_*`

* parseNamespace

* Supply an expression instead of a function: `curve` (
Anaphoric functions), anaphoric if, http://www.arcfn.com/doc/anaphoric.html, http://www.perlmonks.org/index.pl?node_id=666047


Anaphoric functions (http://amalloy.hubpages.com/hub/Unhygenic-anaphoric-Clojure-macros-for-fun-and-profit): e.g. curve - expects to have x defined. `with_file`.

```R
curve2 <- function(expr, xlim, n = 100, env = parent.frame()) {
  env2 <- new.env(parent = env)
  env$x <- seq(xlim[1], xlim[2], length = n)
  
  y <- eval(expr, env2)
  plot(x, y, type = "l", ylab = deparse(substitute(expr)))
}
curve2(sin(x ^ (-2)), c(0.01, 2), 10000)
```

* Combine evaluation with extra processing: `test_that`, `assert_that`

* Create a full-blown DSL: `html`, `plotmath`, `deriv`


## How does local work?

Rewrite to emphasise what local should do, and how you could implement it yourself.

The source code for `local` is relatively hard to understand because it is very concise and uses some sutble features of evaluation (including non-standard evaluation of both arguments). If you have read [[computing-on-the-language]], you might be able to puzzle it out, but to make it a bit easier I have rewritten it in a simpler style below. 

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

`local` is effectively identical to 

```R
local4 <- function(expr, envir = new.env()) {
  envir <- eval(substitute(envir), parent.frame())
  eval(substitute(expr), envir)
}
local4(9+9)
```

But a better implementation might be

```R
local5 <- function(expr, envir = NULL) {
  if (is.null(envir))
    envir <- new.env(parent = parent.frame())

  eval(substitute(expr), envir)  
}
```


## Special environments

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


