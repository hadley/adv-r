# Environments

## Introduction

Understand environment objects is an important next step of understanding scoping. This chapter will teach you:

* what an environment is and how to inspect and manipulate them
* the four types of environment associated with a function
* working in an fresh environment outside of a function with `local()`
* four ways of binding names to values in an environment

The [[functions]] chapter focusses on the essence of how scoping works, where this chapter will focus more on the details and show you how you can implement the behaviour yourself.

This chapter uses many functions found in the `pryr` package to pry bar the covers of R and look inside the messy details.  Install `pryr` by running `devtools::install_github("pryr")`

## What is an environment?

An __environment__ is very similar to a list, with two important differences. Firstly, an environment has reference semantics: R's usual copy on modify rules do not apply. Secondly, an environment has a parent: if an object is not found in an environment, then R will look in its parent. Technically, an environment is made up of a __frame__, a collection of named objects (like a list), and link to a parent environment.  

We extend the family metaphor to other environments: the grandparent of a environment would be the parent's parent, the ancestors include all parent environments all the way up to the `emptyenv()`.  We rarely talk about the children of an environment because there are no back links: given an environment we have no way to find its children.

The job of an environment is to associate, or __bind__, a set of names (this is a set in the formal sense: only one name) to their corresponding values.

You can create environments with `new.env()`, see their contents with `ls()`, and inspect their parent with `parent.env()`:

```R
e <- new.env()
# the default parent provided by new.env() is the calling environment
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

You can extract elements of an environment using `$` or `\[\[`, or `get`.  `$` and `\[\[` will only look in that environment, but `get` looks up variable names using the regular scoping rules and so will also look in the parent environment, if neeeded.

```R
b <- 2
e$b
e[["b"]]
get("b", e)
```

You can determine if a binding exists in a environment with the `exists()` function, but beware that the default is to also check all parent environments, so you should usually call it with `inherits = FALSE`:

```R
exists("b", e)
exists("b", e, inherits = FALSE)
exists("a", e, inherits = FALSE)
```

Environments can be also useful data structures because unlike almost every other type of object in R, modification takes place without a copy. This is not something that you should use without thought: it will violate users expectations about how R code works, but it can sometimes be critical for high performance code. The following example shows how you can use an environment to do this. However, since the addition of [[R5]], you're generally better of using reference classes instead of raw environments.

It's important to make the parent environment the empty environment so that you don't accidentally inherit bindings from the global environment.

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

Environments can also be to simulate hashmaps common in other packages, because name lookup is implemented with a hash, which means that lookup is O(1). See the CRAN package hash for an example. 

There are a few special environments that you can access directly:

  * `globalenv()`: the user's workspace
  * `baseenv()`: the environment of the base package
  * `emptyenv()`: the ultimate ancestor of all environments

The only environment that doesn't have a parent is `emptyenv()`, which is the eventual parent of every other environment. The most common environment is the global environment (`globalenv()`) which corresponds to the to your top-level workspace. The parent of the global environment is one of the packages you have loaded (the exact order will depend on which packages you have loaded in which order). The eventual parent will be the base environment, which is the environment of "base R" functionality, which has the empty environment as a parent.

Most of the time when you are working with environments, you will not create them directly, but they will be created as a consequence of working with functions. The following section discuss the four types of environment associated with a function.

### Where

We can apply our new knowledge of environments to create a helpful function called `where` function that tells us where a variable was defined:

```R
library(pryr)
where("where")
where("mean")
where("t.test")
x <- 5
where("x")
```

`where()` works in the same way as regular variable look up in R, recursing up the stack of environments until the name is found, but instead of returning the value it returns the environment. Note that to check if the environment is the same as the empty environment, we need to use `identical()`: this is the scalar equivalent of the vectorised `==` and works with any object type.

```R
where
```

It's natural work with environments recursively, so we'll see this style of function structure frequency. There are three main components: the base case (what happens when we've recursed down to the empty environment), a boolean that determines if we've found what we wanted, and the recursive statement that re-calls the function using the parent of the current environment. `parent.frame()` is often a good default for the environment, and we'll learn more about it later in the chapter.

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

### Exercises

* Using `parent.env()` and a loop (or a recursive function), verify that `globalenv()` ancestors include `baseenv()` and `emptyenv()`

* Write your own version of `get()` using a function written in the style of `where()`.  
 
* Write a function called `fget()` that finds only function objects. It should have two arguments, `name` and `env`, and should obey the regular scoping rules for functions: if there's an object with a matching name that's not a function, look in the parent. (This function should be a equivalent to `match.fun()` extended to take a second argument).  For an added challenge, also add an `inherits` argument which controls whether the function recurses down the parents or only looks in one environment.

* Write your own version of `exists(inherits = FALSE)` (Hint: use `ls()`).  Write a recursive version that behaves like `inherits = TRUE`.

* Something to do with `search()`?

* Something with `lockBinding()`?

## Function environments

There are multiple environments associated with each function, and it's easy to get confused between them. 

* the environment where the function was created
* the environment where the function lives
* the environment that is created every time a function is run
* the environment where a function is called from

The following sections will explain why each of these environments are important, how to access them, and how you might use them.

### The environment where the function was created

When a function is created, it gains a pointer to the environment where it was made. This is the parent enviroment of the function used by scoping. You can access this environment with the `environment()` function. 

```R
x <- 1
f <- function(y) x + y
environment(f)

environment(plot)
environment(t.test)
```

To make a function an equivalent function that is safer (it throws an error if the input isn't a function), more consistent (can take a function name as an argument not just a function), and more informative (better name), we'll create `funenv()`:

```R
funenv <- function(f) {
  f <- match.fun(f)
  environment(f)
}
```

It's also possible to modify the environment of a function, using the assignment form of `environment`. This is rarely useful, but we can use it to illustrate how fundamental scoping is to R. One complaint that people sometimes make about R is that the function `f` defined above really should generate an error, because there is no variable `y` defined inside of R.  Well, we could fix that by manually modifying the environment of `f` so it can't find y inside the global environment:

```R
f <- function(x) x + y
environment(f) <- emptyenv()
f(1)
```

But when we run it, we don't get the error we expect. Because R uses its scoping rules consistently for everything (including looking up functions), we get an error that `f` can't find the `+` function. (See the discussion in [[scoping]] for alternatives that actually work).

### The environment where the function lives

The environment of a function, and the environment where it lives might be different. In the example above, we changed the environment of `f` to be the `emptyenv()`, but it still lived in the `globalenv()`:

```R
f <- function(x) x + y
funenv("f")
where("f")
environment(f) <- emptyenv()
funenv("f")
where("f")
```

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

Recall how function scoping works. What will the following function will return the first time we run it?  What about the second?

```R
f <- function(x) {
  if (!exists("a", inherits = FALSE)) {
    message("Defining a")
    a <- 1
  } else {
    a <- a + 1 
  }
  a
}
f()
```

You should recall that it returns the same value every time. This is because every time a function is called, a new environment is created to host execution. We can see this more easily by returning the environment inside the function: using `environment()` with no arguments returns the current environment (try running it at the top level). Each time you run the function a new function is created. But they all have the same parent environment, the environment where the function was created.

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

The top-level `x` is a red herring: using the regular scoping rules, `g()` looks first where it is defined and finds the value of `x` is 10.  However, it is still meaningful to ask what value `x` is associated in the environment where `g()` is called.  So `x` is 10 in the environment where `g()` is defined, but it is 20 in the environment from which `g()` is __called__.  

We can access this environment using the confusingly named function `parent.frame()`. This function returns the __environment__ from which the function was called.  We can use that to look up the value of names in the environment from which the funtion was called.

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

In more complicated scenarios, there's not just one parent call, but a sequence of calls all the way back to the initiating function called from the top-level. We can get a list of all calling environments using `sys.frames()`

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

There are two separate strands of parents when a function is called: the calling environments, and the defining environments. Each calling environment will also have a stack of defining environments. Note that while called function has both a stack of called environemnts and a stack of defining environments, an environment (or a function object) has only a stack of defining environments.

Looking up variables in the calling environment rather than in the defining argument is called __dynamic scoping__.  Few languages implement dynamic scoping (emac's lisp is a [notable exception](http://www.gnu.org/software/emacs/emacs-paper.html#SEC15)) because dynamic scoping makes it much harder to reason about how a function operates: not only do you need to know how it was defined, you also need to know in what context it was called.  Dynamic scoping is primarily useful for developing functions that aid interactive data analysis, and is one of the topics discussed in [[controlling evaluation]]

## Explicit scoping with `local`

Sometimes it's useful to be able to create a new scope without embedding inside a function.  The `local` function allows you to do exactly that - it can be useful if you need some temporary variables to make an operation easier to understand, but want to throw them away afterwards:

```R
df <- local({
  x <- 1:10
  y <- runif(10)
  data.frame(x = x, y = y)
})
```

This is equivalent to:

```R
df <- (function() {
  x <- 1:10
  y <- runif(10)
  data.frame(x = x, y = y)
})()
```

`local` has relatively limited uses (typically because most of the time scoping is best accomplished using R's regular function based rules) but it can be particularly useful in conjunction with `<<-`. You can use this if you want to make a private variable that's shared between two functions:

```R
a <- 10
my_get <- NULL
my_set <- NULL
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

## Assignment: binding names to values

Assignment is the act of binding (or rebinding) a name to a value in an environment. It is the counterpart to scoping, the set of rules that determines how to find the value associated with a name. Compared to most languages, R has extremely flexible tools for binding names to values. In fact, you can not only bind values to names, but you can also bind expressions (promises) or even functions, so that every time you access the value associated with a name, you get something different!

The remainder of this section will discuss the four main ways of binding names to values in R:

* With the regular behaviour, `name <- value`, the name is immediately associated with the value in the current environment. `assign("name", value)` works similarly, but allows assignment in any environment.

* The double arrow, `name <<- value`, assigns in a similar way to variable lookup, so that `i <<- i + 1` modifies the binding of the original `i`, which is not necessarily in the current environment.

* Lazy assignment, `delayedAssign("name", expression)`, binds an expression isn't evaluated until you look up the name.

* Active assignment, `makeActiveBinding("name", function)` binds the name to a function, so it is "active" and can return different a value each time the name is found.

The following sections explain each behaviour in more detail.

### Regular binding

You have probably used regular assignment in R thousands of times. Regular assignment immediately creates a binding between a name and a value in the current environment. 

There are two types of names: syntactic and non-syntactic. Generally, syntactic names consist of letters, digits, `.` and `_`, and must start with a letter or `.` not followed by a number (so `.a` and `._` are syntactic but `.1` is not).  There are also a number of reserved words (e.g. `TRUE`, `NULL`, `if`, `function`, see `make.names()`).  A syntactic name can be used on the left hand side of `<-`:

```R
a <- 1
._ <- 2
a_b <- 3
```

However, a name can actually be any sequence of characters; if it's non-syntactic you just need to do a little more work:

```R
`a + b` <- 3
`:)` <- "smile" 
`    ` <- "spaces"
ls()
```

`<-` creates a binding in the current environment. There are three techniques to create a binding in another environmnent:

* treating an environment like a list

  ```R
  e <- new.env()
  e$a <- 1
  ```

* use `assign()`, which has three important arguments: the name, the value, and the environment in which to create the binding

  ```R
  e <- new.env()
  assign("a", 1, envir = e)
  ```

* evaluate `<-` inside the environment. (More on this in [[evaluation]])

  ```R
  e <- new.env()
  eval(quote(a <- 1), e)
  # alternatively, you can use the helper function evalq
  # evalq(x, e) is exactly equivalent to eval(quote(x), e)
  evalq(a <- 1, e)
  ```

I generally prefer to use the first form because it is so compact. However, you'll see all three forms in R code in the wild.

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

If it doesn't find an existing variable of that name, it will create one in the global environment. This is usually undesirable, because global variables introduce non-obvious dependencies between functions.

`name <<- value` is equivalent to `assign("name", value, inherits = TRUE)`.

To give you more idea how this works, we could implement `<<-` ourselves. I'm going to call it `rebind`, and emphasise that it's normally used to modify an existing binding. We'll implement it with our recursive recipe for working with environments. For the base case, we'll throw an error (where `<<-` would assign in the global environment), which emphasises the rebinding nature of this function. Otherwise we check to see if the name is found in the current environment: if it is, we do the assignment there; if not, we recurse.

```R
reassign <- function(name, value, env = parent.frame()) {
  if (identical(env, emptyenv())) {
    stop("Can't find ", name, call. = FALSE)
  }

  if (exists(name, env, inherits = FALSE)) {
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

We'll come back to this idea in depth, and see where it is useful in [[functional programming]].

### Delayed bindings

Another special type of assignment is a delayed binding: rather than assigning the result of an expression immediately, it creates and stores a promise to evaluate the expression when needed (much like the default lazy evaluation of arguments in R functions).  We can create delayed bindings with the special assignment operator `%<d-%`, provided by the pryr package.

```R
library(pryr)
a %<d-% 1 #>
a
b %<d-% {Sys.sleep(1); 1} #>
b
```

Note that we need to be careful with more complicated expressions because user created infix functions have the lowest possible precendence: `x %<d-% a + b` is interpreted as `(x %<d-% a) + b`, so we need to use parentheses ourselves:

```R
x %<d-% (a + b) #>
a <- 5
b <- 5
a + b
```

`%<d-%` is a wrapper around the base `delayedAssign()` function, which you may need to use directly if you need more control. `delayedAssign()` has four parameters:

* `x`: a variable name given as a quoted string
* `value`: an unquoted expression to be assigned to x
* `eval.env`: the environment in which to evaluate the expression
* `assign.env`: the environment in which to create the binding

Writing `%<d-%` is straightforward, bearing in mind that `makeActiveBinding` uses non-standard evaluation to capture the representation of the second argument, so we need to use substitute to construct the call manually. 

One application of `delayedAssign` is `autoload`, a function that powers `library()`. `autoload` makes R behave as if the code and data in a package is loaded in memory, but it doesn't actually do any work until you call one of the functions or access a dataset. This is the way that data sets in most packages work - you can call (e.g.) `diamonds` after `library(ggplot2)` and it just works, but it isn't loaded into memory unless you actually use it.

### Active bindings

You can create __active__ bindings where the value is recomputed every time you access the name:

```R
x %<a-% runif(1) #>
x
x
```

`%<a-%` is a wrapper for the base function `makeActiveBinding()`. You may want to use this function directly if you want more control. It has three arguments:

* `sym`: a variable name, represented as a name object or a string
* `fun`: a single argument function. Getting the value of `sym` calls `fun` with zero arguments, and setting the value of `sym` calls `fun` with one argument, the value.
* `env`: the environment in which to create the binding.

### Exercises

* In `rebind()` it's unlikely that we want to assign in an ancestor of the global environment (i.e. a loaded package), modify the function to avoid recursing past the global environment.
