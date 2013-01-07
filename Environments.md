# Environments

## Introduction

An __environment__ is very similar to a list, with two important differences. Firstly, an environment has reference semantics: R's usual copy on modify rules do not apply. Secondly, an environment has a parent: if an object is not found in an environment, then R will look in its parent. Technically, an environment is made up of a __frame__, a collection of named objects (like a list), and link to a parent environment.  

The job of an environment is to associate, or __bind__, a set of names (this is a set in the formal sense: only one name) to their corresponding values.

You can create environments with `new.env()`, see their contents with `ls()`, and inspect their parent with `parent.env()`:

```R
e <- new.env()
parent.env(e)
ls(e)
e$a <- 1
ls(e)
e$a
```

By default `ls` only shows names that don't begin with `.`.  Use `all.names = TRUE` (or `all` for short) to list absolutely all bindings in an environment.

```R
e$.a <- 2
ls(e)
ls(e, all = TRUE)
```

You can extract their contents using `$` or `\[\[`, or `get`.  `$` and `\[\[` will only look in that environment, but `get` will also look in all parents.

```R
b <- 2
e$b
e[["b"]]
get("b", e)
```

Environments can be also useful data structures because unlike almost every other type of object in R, modification takes place without a copy. This is not something that you should use without thought: it will violate users expectations about how R code works, but it can sometimes be critical for high performance code. The following example shows how you can use an environment to do this. It's important to make the parent environment the empty environment so that you don't accidentally inherit bindings from the global environment.

```
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

Environments can be to simulate hashmaps common in other packages, because internally name lookup is implemented with a hash, which means that lookup is O(1). See the CRAN package hash for an example. However, since the addition of [[R5]], you're generally better of using reference classes instead of raw environments.

There are a few special environments that you can access directly:

  * `globalenv()`: the user's workspace
  * `baseenv()`: the environment of the base package
  * `emptyenv()`: the ultimate ancestor of all environments

The only environment that doesn't have a parent is emptyenv(), which is the eventual parent of every other environment. The most common environment is the global environment (globalenv()) which corresponds to the to your top-level workspace. The parent of the global environment is one of the packages you have loaded (the exact order will depend on which packages you have loaded in which order). The eventual parent will be the base environment, which is the environment of "base R" functionality, which has the empty environment as a parent.

## Function environments

There are multiple environments associated with each function, and it's easy to get confused between them. 

* the environment where the function was created
* the environment where the function lives
* the environment that is created every time a function is run
* the environment where a function is called from

To make things a little easier to understand, we'll create a `where` function that tells us where a variable was defined:

```R
where <- function(name, env = parent.frame()) {
  if (identical(env, emptyenv())) {
    stop("Can't find ", name, call. = FALSE)
  }

  if (name %in% ls(env, all.names = TRUE)) {
    env
  } else {
    where(name, parent.env(env))
  }
}
where("where")
where("mean")
where("t.test")
```

This function works in the same way as regular variable look up in R, recursing up the stack of environments until the name is found, but instead of returning the value it returns the environment.

It's easiest to work with environments recursively, so we'll see this basic structure a lot. There are three main components: the base case (what happens when we've recursed down to the empty environment), a boolean that determines if we've found what we wanted, and the recursive statement that uses `parent.env()`.  `parent.frame()` confusingly returns the environment from which our function is run, we'll learn more about that later in the chapter.

```R
f <- function(..., env = parent.frame()) {
  if (identical(env, emptyenv())) {
    # base case
  }

  if (success) {
    # return value
  } else {
    # inspect parent
    f(..., env = parent.env(env))
}
```

Note that we could also write this function with a loop instead of with recursion. This might run slightly faster (because we eliminate some function calls), but I find it harder to understand what's going on.

```R
is.emptyenv <- function(x) identical(x, emptyenv())

f2 <- function(..., env = parent.frame()) {
  while(!is.emptyenv(env)) {
    if (success) {
      # return value
      return()
    }
    # inspect parent
    env <- parent.env(env)
  }

  # base case
}
```

### The environment where the function was created

When a function is created, it gains a pointer to the environment where it was made. This is commonly known as the environment of the function. You can access this environment with the `environment()` function. 

```R
x <- 1
f <- function(y) x + y
environment(f)

environment(plot)
environment(t.test)
```

We'll make a function an equivalent function that is safer (it throws an error if the input isn't a function), more consistent (can take a function name as an argument not just a function), and more informative (better name), we'll create `funenv()`:

```R
funenv <- function(f) {
  f <- match.fun(f)
  environment(f)
}
```

This is the parent enviroment of the function used by scoping.

It's also possible to modify the environment of a function, using the assignment form of `environment`.  This is rarely useful, but we can use it to illustrate how fundamental scoping is to R. One complaint that people sometimes make about R is that the function `f` defined above really should generate an error, because there is no variable `y` defined inside of R.  Well, we could fix that by manually modifying the environment of `f` so it can't find y inside the global environment:

```R
f <- function(x) x + y
environment(f) <- emptyenv()
f(1)
```

But when we run it, we don't get the error we expect. Because R uses its scoping rules consistently for everything (including looking up functions), we get an error that `f` can't find the `+` function. (See the discussion in [[scoping]] for alternatives that actually work).

### The environment where the function lives

The environment of a function, and the environment where it lives might be different. In the example above, we changed the environment of `f` to be the `emptyenv()`, but it still lived in the `globalenv()`.  

The environment where the function lives determines how we find the function, the environment of the function determins how it finds values inside the function. This important distinction is what enables package [[namespaces]] to work.

For example, take the `t.test` function:

```R
funenv("t.test")
where("t.test")
```

It is defined in the `package::stats` environment, but its parent (where it looks up values) is the `namespace::stats` environment. The _package_ environment contains only functions and objects that should be visible to the user, but the _namespace_ environment contains both internal and external functions. There are over 400 objects that a defined in the `stats` package 
but not available to the user:

```
length(ls(funenv("t.test")))
length(ls(where("t.test")))
```

### The environment created every time a function is run

What do you think the following function will return the first time we run it?  What about the second?

```R
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
```

You might be surprised that it returns the same value every time. This is because every time a function is called, a new environment is created to host execution. You can see this more easily by returning the environment inside the function: using `environment()` with no arguments returns the current environment (try running it at the top level). Each time you run the function a new function is created. But they all have the same parent environment, the environment where the function was created.

```R
f <- function(x) {
  list(
    e = environment(),
    p = parent.env(environment())
  )
}
f()
f()
funenv("f")
```

### The environment where the function was called

Look at the following code. What do you expect `g()` to return when the code is run?

```R
f <- function(x) {
  function() {
    x
  }
}
g <- f(10)
x <- 20
g()
```

The top-level `x` is a red herring: using the regular scoping rules, `g()` looks first where it is defined and finds the value of `x` is 10.  However, it is still meaningful to ask what value `x` is associated in the environment where the function is called.  So `x` is 10 in the environment where `g()` is defined, but it is 20 in the environment from which `g()` is __called__.  

We can access this environment using the confusingly named function, `parent.frame()`. This function returns the __environment__ from which the function was called.  We can use that to look up the value of names in the environment from which the funtion was called.

```R
f <- function(x) {
  function() {
    def <- get("x", environment())
    cll <- get("x", parent.frame())
    list(def = def, cll = cll)
  }
}
g <- f(10)
x <- 20
g()
```

In more complicated scenarios, there's not just one parent call, but also a parent of a parent and so on. We can get a list of all calling environments using `sys.frames()`

```R
y <- 10
f <- function(x) {
  x <- 1
  g(x)
}
g <- function(x) {
  x <- 2
  h(x)
}
h <- function(x) {
  x <- 3
  i(x)
}
i <- function(x) {
  x <- 4
  sys.frames()
}

es <- f()
lapply(es, function(e) get("x", e))
lapply(es, function(e) get("y", e))
```

So there are two separate strands of parents when a function is called: the calling environments, and the definition environments. And each of the calling environment will also have a stack of environments in which it was defined.

The practical implications of this idea are discussed in [[controlling evaluation]]

Note that a called function has a call stack, and an environment has an environment stack. 


## Binding names to values

Assigning means that we are binding (or rebinding) a name to a value in an environment.

There are a suprising number of ways to do assignment in R:

* The regular behaviour, `name <- value`, where the name is immediately associated with the value in the current environment. `assign("name", value)` works similarly, but allows assignment in any environment.

* Assignment with the double arrow, `name <<- value` which assigns in a similar way to how variable lookup works so that `i <<- i + 1` modifies the binding of the original `i`.

* Lazy assignment, `delayedAssign("name", expression)`, where the expression isn't evaluated until you look up the name.

* Active assignment, `makeActiveBinding("name", function)` where the value evaluates a function every time it is accessed, so it is "active", and can return different values.

The following sections explain each behaviour in more detail.

### Usual behaviour

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

Another way to modify the binding between name and value is `<<-`. The regular assignment arrow, `<-`, always creates a variable in the current environmnt.  The special assignment arrow, `<<-`, tries to modify an existing variable by walking up the parent environments. If it doesn't find one, it will create a new variable in the global environment.

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

The prefix equivalent of `name <<- value` is `assign("name", value, inherits = TRUE)`.

To give you more idea how this works, we could implement it ourselves.  We use the same basic recipe as before. For the base case, we'll throw an error (where normally R will assign in the global environment), this should make it a little easier to see if we've made an error, and makes it more clear that the purpose of this function is to rebind existing names, not create a new binding. Otherwise we check to see if the name is found in the current environment, and if it is we do the assignment there. 

```R
reassign <- function(name, value, env = parent.frame()) {
  if (identical(env, emptyenv())) {
    stop("Can't find ", name, call. = FALSE)
  }

  if (name %in% ls(env, all = TRUE)) {
    assign(name, value, env)
  } else {
    reassign(name, value, parent.env(env))
  }
}
reassign("a", 10)
a <- 5
reassign("a", 10)
a

f <- function() {
  g <- function() {
    reassign("x", 2)
  }
  x <- 1
  g()
  x
}
f()
```

We'll come back to this idea in depth in [[first-class-functions]].

### Lazy evaluation

Another special type of assignment is `delayedAssign`: rather than assigning the result of an expression immediately, it creates and stores a promise to evaluate the expression is needed (much like the default lazy evaluation of arguments in R functions).

To create a variable `x`, that is the sum of the values `a` and `b`, but is not evaluated until we need, we could use `delayedAssign`:

```R
a <- 1
b <- 2
delayedAssign("x", a + b)
a <- 10
x
# [1] 12
```

`delayedAssign` also provides two parameters that control where the evaluation happens (`eval.env`) and which in environment the variable is assigned in (`assign.env`).

We could make an infix version of this function. The main complication is that `delayedAssign` uses non-standard evaluation (to capture the representation of the second argument), so we need to use substitute to construct the call manually. 

```R
"%<d-%" <- function(x, value) { #">
  name <- substitute(x)
  if (!is.name(name)) stop("Left-hand side must be a name")

  value <- substitute(value)

  env <- parent.frame()
  eval(substitute(delayedAssign(deparse(name), value, 
    eval.env = env, assign.env = env), list(value = value)))
}

a %<d-% 1
a
b %<d-% {Sys.sleep(1); 1}
b
```

One application of `delayedAssign` is `autoload`, a function that powers `library()`. `autoload` makes R behave as if the code and data in a package is loaded in memory, but it doesn't actually do any work until you call one of the functions or access a dataset. This is the way that data sets in most packages work - you can call (e.g.) `diamonds` after `library(ggplot2)` and it just works, but it isn't loaded into memory unless you actually use it.

### Repeated evaluation

`makeActiveBinding` allows you to create names that look like variables, but act like zero-argument functions. Every time you access the object a function is run. This lets you do crazy things like:

```R
makeActiveBinding("x", function(...) rnorm(1), globalenv())
x
# [1] 0.4754442
x
# [1] -1.659971
x
# [1] -1.040291
```

We could also make an infix version of this function:

```R
"%<a-%" <- function(x, value) { #">
  x <- substitute(x)
  if (!is.name(x)) stop("Left-hand side must be a name")

  value <- substitute(value)
  env <- parent.frame()
  f <- make_function(list(), value, env)

  makeActiveBinding(deparse(x), f, env)
}

x %<a-% runif(1) #>
x
x
```

### Exercises


## Explicit scoping with `local`

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
a <- 10
local({
  a <- 1
  my_get <<- function() a
  my_set <<- function(value) a <<- value
})
my_get()
my_set(10)
a
my_get()
```

### How does local work?

The source code for `local` is relatively hard to understand because it is very concise. If you have read [[computing-on-the-language]], you should be able to puzzle it out, but to make it a bit easier I have rewritten it in a simpler style below. 

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
local3({
  b <- a + sample(10, 1)
  my_get <<- function() b
})
my_get()

local({
  a <- 2
  eval <- function(...) print("1")
  local(a <- 1)
  a
})

local3({
  a <- 2
  eval <- function(...) print("1")
  local3(a <- 1)
  a
})

```

