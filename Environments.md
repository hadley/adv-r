# Environments

## Introduction

An __environment__ is very similar to a list, with two important differences. Firstly, an environment has reference semantics: R's usual copy on modify rules do not apply. Secondly, an environment has a parent: if an object is not found in an environment, then R will look in its parent. Technically, an environment is made up of a __frame__, a collection of named objects (like a list), and link to a parent environment.

You can create environments with `new.env()`, see their contents with `ls()`, and inspect their parent with `parent.env()`:

```R
e <- new.env()
parent.env(e)
ls(e)
e$a <- 1
ls(e)
e$a
```

You can extract their contents using `$` or `\\[[`, or `get`.  `$` and `\\[[` will only look in that environment, but `get` will also look in all parents.

```R
b <- 2
e$b
e[["b"]]
get("b", e)
```

Environments can be also useful datastructures because unlike almost every other type of object in R, modification takes place without a copy. This is not something that should be undertaken lightly: it will violate users expectations about how R code works, but it can sometimes be critical for high performance code. The following example shows how you can use an environment to do this. It's important to make the parent environment the empty environment so that you don't accidentally inherit behaviour from the global environment.

```R
e <- new.env(parent = emptyenv())
f <- e

exists("a", e)
e$a
ls(e)

# Environments are reference object: R's usual copy-on-modify semantics
# do not apply
e$a <- 10
ls(e)
ls(f)
f$a
```

Environments can be used as hashes.  See the CRAN package hash for an example. However, since the addition of [[R5]], you're generally better of using reference classes instead of raw environments.

There are a few special environments that you can access directly:

  * `globalenv()`: the user's workspace
  * `baseenv()`: the environment of the base package
  * `emptyenv()`: the ultimate ancestor of all environments

The only environment that doesn't have a parent is emptyenv(), which is the eventual parent of every other environment. The most common environment is the global environment (globalenv()) which corresponds to the to your top-level workspace. The parent of the global environment is one of the packages you have loaded (the exact order will depend on which packages you have loaded in which order). The eventual parent will be the base environment, which is the environment of "base R" functionality, which has the empty environment as a parent.

## Function environments

Environments are the data structure that powers scoping.  There are multiple environments associated with each function, and it's easy to get confused between them. 

* the environment where the function was defined
* the environment that is created every time a function is run
* the environment where the function lives
* the environment where a function is called from

To make things a little easier to understand, we'll create a `where` function that tells us where a variable was defined:

    where <- function(name, env = parent.frame()) {
      # Base case of recursion
      if (identical(env, emptyenv())) {
        stop("Can't find ", name, call. = FALSE)
      }

      if (name %in% ls(env)) {
        env
      } else {
        where(name, parent.env(env))
      }
    }
    where("where")
    where("mean")
    where("t.test")

It works in the same way as regular variable look up in R, but instead of returning the value it returns the environment.

### The environment where the function was defined.

When a function is created, it gains a pointer to the environment where it was made. You can access this environment with the `environment` function. 

```R
x <- 1
f <- function(y) x + y
environment(f)

environment(plot)
environment(t.test)
```

It's also possible to modify the environment of a function, using the assignment form of `environment`.  This is rarely useful, but we can use it to illustrate how fundamental scoping is to R.

One complaint that people sometimes make about R is that the function `f` defined above really should generate an error, because there is no variable `y` defined inside of R.  Well, we could fix that by manually modifying the environment of `f` so it can't find y inside the global environment:

```R
f <- function(x) x + y
environment(f) <- emptyenv()
f(1)
```

But when we run it, we don't get the error we expect.  Because R uses its scoping rules consistently for everything (including looking up functions), we get an error that `f` can't find the `+` function.

### The environment created every time a function is run

What do you think the following function will return the first time we run it?  What about the second?

    f <- function(x) {
      if (!exists("a")) {
        message("Defining a")
        a <- 1
      } else {
        a <- a + 1 
      }
      a
    }
    f()

You might be surprised that it returns the same value every time.  This is because every time a function is called, a new environment is created to host execution. You can see this more easily by returning the environment inside the function: using `environment()` with no arguments returns the current environment (try running it at the top-level)  Each time you run the function a new function is created.  But they all have the same parent environment - that's the environment where the function was defined.

```R
f <- function(x) {
  list(
    e = environment(),
    p = parent.env(environment())
  )
}
f()
f()
```

### The environment where the function was called

Note that a called function has a call stack, and an environment has an environment stack. 

To make these distinctions easier to understand and explore, let's define some consistently named functions:

  parent_c <- function(n = 1) {
    parent.frame(c)
  }

  parent_d <- function(n = 1) {
    env <- parent_c()
    for (i in seq_len(n)) env <- parent.env(env)
    env
  }

Can we draw a graph that connects them all together?

### The environment where the function lives

The environment of a function, and the environment where it lives might be different. In the example above, we changed the environment of `f` to be the `emptyenv()`, but it still lived in the `globalenv()`.  

The environment where the function lives determines how we find the function, the environment of the function determins how it finds values inside the function. This important distinction is what enables package [[namespaces]] to work.

For example, take the `mean` function:

  environment(mean)
  where("mean")

## Modifying and assigning values

You already know the standard ways of modifying and accessing values in the current environment (e.g. `x <- 1; x`).  To modify values in other environments we have a few new techniques:

* treating environments like lists

```R
e <- new.env()
e$a <- 1
e$a
```

* assign and get

```R
e <- new.env()
assign("a", 1, envir = e)
get("a", envir = e)
```

* evaluating expressions inside an environment

```R
e <- new.env()
eval(quote(a <- 1), e)
eval(quote(a), e)
# OR 
evalq(a <- 1, e)
evalq(a, e)
```

I generally prefer to use the first form, because it is so compact.  However, you'll see all three forms in R code in the wild.

### `<<-`

Another way to change values is `<<-`. The regular assignment arrow, `<-`, always creates a variable in the current environmnt.  The special assignment arrow, `<<-`, tries to modify an existing variable by walking up the parent environments. If it doesn't find one, it will create a new variable in the global environment.

```R
f <- function() {
  g <- function() {
    x <<- 2
  }
  x <- 1
  g()
  x
}
f()
```

If it doesn't find an existing variable of that name, it will create one in the global environment. This is usually undesirable, because global variables are usually undesirable. There's only one global environment so you can only store a single value, and it introduces non-obvious dependencies between functions.

We'll come back to this idea in depth in [[first-class-functions]].

### delayedAssign

Another special type of assignment is `delayedAssign`: rather than assigning the result of an expression immediately, it creates and stores a promise to evaluate the expression is needed (much like the default lazy evaluation of arguments in R functions).

To create a variable `x`, that is the sum of the values `a` and `b`, but is not evaluated until we need, we use `delayedAssign`:

    a <- 1
    b <- 2
    delayedAssign("x", a + b)
    a <- 10
    x
    # [1] 12

`delayedAssign` also provides two parameters that control where the evaluation happens (`eval.env`) and which in environment the variable is assigned in (`assign.env`).

We could make an infix version of this function. The main complication is that `delayedAssign` uses non-standard evaluation (to capture the representation of the second argument), so we need to use substitute to construct the call manually.

    "%<d-%" <- function(x, value) {
      x <- substitute(x)
      if (!is.name(x)) stop("Left-hand side must be a name")

      value <- substitute(value)

      env <- parent.frame()
      eval(substitute(delayedAssign(deparse(x), value, 
        eval.env = env, assign.env = env), list(value = value)))
    }

    a %<d-% 1
    a
    b %<d-% {Sys.sleep(1); 1}
    b

One application of `delayedAssign` is `autoload`, a wrapper for functions or data in a package that makes R behave as if the package is loaded, but it doesn't actually load it (i.e. do any work) until you call one of the functions.  This is the way that data sets in most packages work - you can call (e.g.) `diamonds` after `library(ggplot2)` and it just works, but it isn't loaded into memory unless you actually use it.

### Active bindings

`makeActiveBinding` allows you to create names that look like variables, but act like zero-argument functions. Every time you access the object a function is run. This lets you do crazy things like:

    makeActiveBinding("x", function(...) rnorm(1), globalenv())
    x
    # [1] 0.4754442
    x
    # [1] -1.659971
    x
    # [1] -1.040291

We could also make an infix version of this function:

    "%<a-%" <- function(x, value) {
      x <- substitute(x)
      if (!is.name(x)) stop("Left-hand side must be a name")

      value <- substitute(value)
      env <- parent.frame()
      f <- make_function(list(), value, env)

      makeActiveBinding(deparse(x), f, env)
    }

    x %<a-% runif(1)
    x
    x

### Explicit scoping with `local`

Sometimes it's useful to be able to create a new scope without embedding inside a function.  The `local` function allows you to do exactly that - it can be useful if you need some temporary variables to make an operation easier to understand, but want to throw them away afterwards:

```R
df <- local({
  x <- 1:10
  y <- runif(10)
  data.frame(x = x, y = y)
})
```

`local` has relatively limited uses (typically because most of the time scoping is best accomplished using R's regular function based rules) be particularly useful in conjunction with `<<-`. You can use this if you want to make a private variable that's shared between two functions:

```R
get <- NULL
set <- NULL
local({
  a <- 1
  get <<- function() a
  set <<- function(value) a <<- value
})
get()
set(10)
a
get()
```

If you have read [[computing-on-the-language]], you should be able to make sense of the source code of `local`:

```R
local <- function (expr, envir = new.env()) {
  eval.parent(substitute(eval(quote(expr), envir)))  
}
eval.parent <- function (expr, n = 1) {
  p <- parent.frame(n + 1)
  eval(expr, p)
}
```
