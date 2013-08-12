# Expressions

<!-- 
library(pryr)
library(stringr)
special <- c("substitute", "eval", "match.call", "call", "as.call", "quote", "expression", "enquote", "bquote", "parse")
funs <- lapply(special, function(x) {
  match <- paste0("^", x, "$")
  c(
    find_funs("package:base", fun_calls, match),
    find_funs("package:utils", fun_calls, match),
    find_funs("package:stats", fun_calls, match)
  )
})
names(funs) <- special
ggplot2:::invert(funs)
-->

In [[computing on the language]], you learned the basics of accessing the expressions underlying computation in R, and evaluating them in new ways. In this chapter, you'll learn more about the underlying structure of expressions, and how you can compute on them directly.

* The structure of expressions (a tree made up of constants, names and calls) and how you can create and modify them directly

* How to flexibly convert expressions between their tree form and their text form, and learn how `source()` works.

* Create functions by hand as an alternative instead of using a closure, so that viewing the source of the function shows something meaningful

* Walk the code tree using recursive functions to understand how many of the functions in the codetools package work, and to you write your own functions that detect if a function uses logical abbreviations, list all assignments inside a function and understand how `bquote()` works.

It's generally a bad idea to create code by operating on its string representation: there is no guarantee that you'll create valid code.  Don't get me wrong: pasting strings together will often allow you to solve your problem in the least amount of time, but it may create subtle bugs that will take your users hours to track down. Learning more about the structure of the R language and the tools that allow you to modify it is an investment that will pay off by allowing you to make more robust code.

Thoroughout this chapter we're going to use tools from the `pryr` package to help see what's going on.  If you don't already have it, install it by running `devtools::install_github("pryr")`

## Structure of expressions

To compute on the language, we first need to be understand the structure of the language. That's going to require some new vocabulary, some new tools and some new ways of thinking about R code. The first thing you need to understand is the distinction between an operation and its result:

```R
x <- 4
y <- x * 10
```

We want to distinguish between the action of multiplying x by 10 and assigning the results to `y` versus the actual result (40).  In R, we can capture the action with `quote()`:

```R
z <- quote(y <- x * 10)
z
```

`quote()` gives us back an __expression__, an object that represents an action that can be performed by R. (Confusingly the `expression()` function produces expression lists, but since you'll never need to use that function we can safely ignore it).

An expression is also called an abstract syntax tree (AST) because it represents the abstract structure of the code in a tree form. We can use `pryr::call_tree()` to see the hierarchy more clearly:

```R
library(pryr)
call_tree(z)
```

There are three basic things you'll commonly see in a call tree: constants, names and calls.

* __constants__ are atomic vectors, like `"a"` or `10`. These appear as is. 

    ```R
    call_tree(quote("a"))
    call_tree(quote(1))
    call_tree(quote(1L))
    call_tree(quote(TRUE))
    ```

* __names__ which represent the name of a variable, not its value. (Names are also sometimes called symbols). These are prefixed with `'`

    ```R
    call_tree(quote(x))
    call_tree(quote(mean))
    call_tree(quote(`an unusual name`))
    ```

* __calls__ represent the action of calling a function, not its result. These are suffixed with `()`.  The arguments to the function are listed below it, and can be constants, names or other calls.

    ```R
    call_tree(quote(f()))
    call_tree(quote(f(1, 2)))
    call_tree(quote(f(a, b)))
    call_tree(quote(f(g(), h(1, a))))
    ```

    As mentioned in [[Functions]], even things that don't look like function calls still follow this same hierarchical structre:

    ```R
    call_tree(quote(a + b))
    call_tree(quote(if (x > 1) x else 1/x))
    call_tree(quote(function(x, y) {x * y}))
    ```

(In general, it's possible for any type of R object to live in a call tree, but these are the only three types you'll get from parsing R code. It's possible to put anything else inside an expression using the tools described below, but while technically correct, support is often patchy.)

Together, names and calls are sometimes called language objects, and can be tested for with `is.language()`. Note that `str()` is somewhat inconsistent with respect to this naming convention, describing names as symbols, and calls as a language objects:

```R
str(quote(a))
str(quote(a + b))
```

Together, constants, names and calls define the structure of all R code. The following section provides more detail about each in turn.

### Constants

Quoting a single atomic vector gives it back to you:

```R
is.atomic(quote(1))
identical(1, quote(1))
is.atomic(quote("test"))
identical("test", quote("test"))
```

But quoting a vector of values gives you something different because you always use a function to create a vector:

```R
identical(1:3, quote(1:3))
identical(c(FALSE, TRUE), quote(c(FALSE, TRUE)))
```

It's possible to use `substitute()` to directly insert a vector into a call tree, but use this with caution as you are creating a call that is not be generated during the normal operation of R.

```R
y <- substitute(f(x), list(x = 1:3))
is.atomic(y)
```

### Names

As well as capturing names with `quote()`, it's also possible to convert strings to names. This is mostly useful your function recieves strings as input, as it's more typing than using `quote()`:

```R
as.name("name")
identical(quote(name), as.name("name"))

as.name("a b")
```

Note that the second example produces the name ` `a + b` `: the backticks are the standard way of escape non-standard names in R. (And are explained more in [[Functions]])

There's one special name that needs a little extra discussion: the name that represents missing values. You can get this from the formals of a function, or with `alist()`:

```R
formals(plot)$x
alist(x =)[[1]]
```

It is basically a special name, that you can create by using `quote()` in a slightly unusual way:

```R
quote(expr =)
```

Note that this object is behaves strangely, and is rarely useful, except when (as we'll see later) you want to try a function with arguments that don't have defaults.

```
x <- quote(expr =)
x
```

### Calls

As well as capturing complete calls using `quote()`, modifing existing calls using `substitute()` you can also create calls from their constituent pieces using using `as.call()` or `call()`.  

The first argument to `call()` is a string giving a function name, and the other arguments should be expressions that are used as the arguments to the call.

```R
call(":", 1, 10)
call("mean", 1:10, na.rm = TRUE)
```

`as.call()` is a minor variation takes a list where the first argument is the _name_ of a function (not a string), and the subsequent values are the arguments. 

```R
mean_call <- as.call(list(quote(mean), x_call))
identical(mean_call, quote(mean(1:10)))
```

Note that the following two calls look the same, but are actually different:

```R
(a <- call("mean", 1:10))
(b <- call("mean", quote(1:10)))
identical(a, b)
call_tree(a)
call_tree(b)
```

In `a`, the first argument to mean is a integer vector containing the numbers 1 to 10, and in `b` the first argument is a call to `:`.  You can put any R object into an expression, but the printing of expression objects will not always show the difference.  

The key difference is where/when evaluation occurs:

```R
a <- call("print", Sys.time())
b <- call("print", quote(Sys.time()))
eval(a); Sys.sleep(1); eval(a)
eval(b); Sys.sleep(1); eval(b)
```

The first element of a call doesn't have to be the name of a function, and instead can be a call that generates a function:

```R
(function(x) x + 1)(10)
add <- function(y) function(x) x + y
add(1)(10)

# Note that you can't create this sort of call with call
call("add(1)", 10)
# But you can with as.call
as.call(list(quote(add(1)), 10))
```

#### An interesting use of `call()`

One interesting use of call lies inside the `mode<-` function which is an alternative way to change the mode of a vector. The important part of the function is extracted in the `mode2<-` function below.

```R
`mode2<-` <- function (x, value) {
  mde <- paste0("as.", value)
  eval(call(mde, x), parent.frame())
}
x <- 1:10
mode2(x) <- "character"
x
```

Another way to achieve the same goal would be find the function and then call it:

```R
`mode3<-` <- function(x, value) {
  mde <- match.fun(paste0("as.", value))
  mde(x)
}
x <- 1:10
mode3(x) <- "character"
x
```

Generally, I'd prefer `mode3<-` over `mode2<-` because it uses concepts familiar to more R programmers, and generally it's a good idea to use the simplest and most commonly understand techniques that solve a given problem. 

#### Extracting elements of a call

When it comes to modifying calls, they behave almost exactly like lists: a call has `length`, `'[[` and `[` methods. The length of a call minus 1 gives the number of arguments:

```R
x <- quote(read.csv("important.csv", row.names = FALSE))
length(x) - 1
```

The first element of the call is the _name_ of the function:

```R
x[[1]]
# read.csv
```

The remaining elements are the arguments to the function, which can be extracted by name or by position.

```R
x$row.names
x[[3]]

names(x)
```

#### Standardising function calls

Generally, extracting arguments by position is dangerous, because R's function calling semantics are so flexible. It's better to match by name, but all arguments might not be named. The solution to this problem is to use `match.call()`, which takes a function and a call as arguments:

```R
y <- match.call(read.csv, x)
names(y)
# Or if you don't know in advance what the function is
match.call(eval(x[[1]]), x)
# read.csv(file = x, header = "important.csv", row.names = FALSE)
```

This will be an important tool when we start manipulating existing function calls. If we don't use `match.call` we'll need a lot of extra code to deal with all the possible ways to call a function.

We can wrap this up into a function. To figure out the definition of the associated function we evaluate the first component of the call, the name of the function. We need to specify an environment here, because the function might be different in different places. Whenever we provide an environment parameter, `parent.frame()` is usually a good default. 

Note the check for primitive functions: they don't have `formals()` and handle argument matching specially, so there's nothing we can do.

```R
standardise_call <- function(call, env = parent.frame()) {
  stopifnot(is.call(call))
  f <- eval(call[[1]], env)
  if (is.primitive(f)) return(call)

  match.call(f, call)
}

standardise_call(y)
standardise_call(quote(standardise_call(y)))
```

#### Modifying a call

You can add, modify and delete elements of the call with the standard replacement operators, `$<-` and `[[<-`:

```R
y$row.names <- TRUE
y$col.names <- FALSE
y

y[[2]] <- "less-important.csv"
y[[4]] <- NULL
y

y$file <- quote(paste0(filename, ".csv"))
y
```

Calls also support the `[` method, but use it with care: since the first element is the function to call, removing it is unlikely to create a call that will evaluate without error.

```R
x[-3] # remove the second argument
x[-1] # remove the function name - but it's still a call!
x
```

If you want to get a list of the unevaluated arguments, explicitly convert it to a list:

```R
# A list of the unevaluated arguments
as.list(x[-1])
```

We can use these ideas to create an easy way modify a call given a list. 

```R
modify_call <- function(call, new_args) {
  call <- standardise_call(call)
  nms <- names(new_args) %||% rep("", length(new_args))

  if (any(nms == "")) {
    stop("All new arguments must be named", call. = FALSE)
  }

  for(nm in nms) {
    call[[nm]] <- new_args[[nm]]
  }
  call
}
modify_call(quote(mean(x, na.rm = TRUE)), list(na.rm = NULL))
modify_call(quote(mean(x, na.rm = TRUE)), list(na.rm = FALSE))
modify_call(quote(mean(x, na.rm = TRUE)), list(x = quote(y)))
```

### Exercises

* If you create a functional, you may want it to accept the name of a function as a string or the name of a function. Use `substitute()` and what you know about expressions to create a function that returns a list containing the name of the function (where you can determine it) and the function itself. 

  ```R
  fname(mean)
  list(name = "mean", f = mean)
  fname("mean")
  list(name = "mean", f = mean)
  fname(function(x) sum(x) / length(x))
  list(name = "<anonymous>", f = function(x) sum(x) / length(x))
  ```

  Create a version that uses standard evaluation suitable for calling from another function (Hint: it should have two arguments: an expression and an environment).


## Parsing and deparsing

You can convert quoted calls back and forth between text with `parse()` and `deparse()`. You've seen `deparse()` already it: takes an expression and returns a character vector. `parse()` does the opposite: it takes a character vector and returns a list of expressions, also known as an expression object or expression list.

Note that because the primary use of `parse()` is parsing files of code on disk, the first argument is a file path, and if you have the code in a character vector, you need to use the `text` argument.

```R
z <- quote(y <- x * 10)
deparse(z)

parse(text = deparse(z))
```

`deparse()` returns a character vector with an entry for each line, and by default it will try to make lines that are around 60 characters long. If you want a single string be sure to `paste()` it back together, and read the other options in the documentation. 

`parse()` can't return just a single expression, because there might be many top-level calls in an file. So instead it returns expression objects, or expression lists. You should never need to create expression objects yourself, and all you need to know about them is that they're a list of calls:

```R
exp <- parse(text = c("x <- 4\ny <- x * 10"))
length(exp)
exp[[1]]
is.call(exp[[1]])
call_tree(exp)
```

It's not possible for `parse()` and `deparse()` be completely symmetric. See the help for `deparse()` for more details.

### Sourcing files from disk

With `parse()` and `eval()` you can write your own simple version of `source()`. We read in the file on disk, `parse()` it and then `eval()` each component in the specified environment. This version defaults to a new environment, so it doesn't affect existing objects. `source()` invisibly returns the result of the last expression in the file, so `simple_source()` does the same.

```R
simple_source <- function(file, envir = new.env()) {
  stopifnot(file.exists(file))
  stopifnot(is.environment(envir))

  lines <- readLines(file, warn = FALSE)
  exprs <- parse(text = lines, n = -1)

  n <- length(exprs)
  if (n == 0L) return(invisible())

  for (i in seq_len(n - 1)) {
    eval(exprs[i], envir)
  }
  invisible(eval(exprs[n], envir))
}
```

The real `source()` is considerably more complicated because it preserves the underlying source course, can `echo` input and output, and has many additional settings to control behaviour.

### Exercises

## Capturing the current call

You may want to capture the expression that caused the current function to be run. There are two ways to do this: 

* `sys.call()` captures exactly what the user typed

* `match.call()` uses R's regular argument matching rules and converts everything to full name matching. This is usually easier to work with because you know that the call will always have the same structure.

The following example illustrates the difference:

```R
f <- function(abc = 1, def = 2, ghi = 3, ...) {
  list(sys = sys.call(), match = match.call())
}
f(d = 2, 2)
```

#### A cautionary tale: `write.csv`

`write.csv()` is a base R function where call manipulation is used in a suboptimal manner. It captures the call to `write.csv()` and mangles it to instead call `write.table()`:

```R
write.csv <- function (...) {
  Call <- match.call(expand.dots = TRUE)
  for (argname in c("append", "col.names", "sep", "dec", "qmethod")) {
    if (!is.null(Call[[argname]])) {
      warning(gettextf("attempt to set '%s' ignored", argname), domain = NA)
    }
  }
  rn <- eval.parent(Call$row.names)
  Call$append <- NULL
  Call$col.names <- if (is.logical(rn) && !rn) TRUE else NA
  Call$sep <- ","
  Call$dec <- "."
  Call$qmethod <- "double"
  Call[[1L]] <- as.name("write.table")
  eval.parent(Call)
}
```

We could write a function that behaves identically using regular function call semantics:

```R
write.csv <- function(x, file = "", sep = ",", qmethod = "double", ...) {
  write.table(x = x, file = file, sep = sep, qmethod = qmethod, ...)
}
```

This makes the function much easier to understand: it's just calling `write.table` with different defaults.  This also fixes a subtle bug in the original `write.csv`: `write.csv(mtcars, row = FALSE)` raises an error, but `write.csv(mtcars, row.names = FALSE)` does not. There's also no reason that `write.csv` shouldn't accept the `append` argument. Generally, you always want to use the simplest tool that will solve a problem - that makes it more likely that others will understand your code. Again, there's no point in using non-standard evaluation unless there's a big win: non-standard evaluation will make your function behave much less predictably.

### Other uses of call capturing

Many modelling functions use `match.call()` to capture the call used to create the model. (This is one reason that creating lists of models using a function doesn't give the greatest output). This is makes it possible to `update()` a model, modifying only a few components of the original model (but note that it doesn't preserve any of the computation, even if possible). Here's a quick example of `update()` in case you haven't used it before:

```R
mod <- lm(mpg ~ wt, data = mtcars)
update(mod, formula = . ~ . + cyl)
update(mod, subset = cyl == 4)
```

How does `update()` work?  We can rewrite it using some of the tools (`dots()` and `modify_call()`) we've developed in this chapter to make it easier to see exactly what's going on.  Once you've figured out what's going on here, you might want to read the source code for `update.default()` and see if you can how each component corresponds between the two versions.

```R
update_call <- function (object, formula., ...) {
  call <- object$call
  
  # Use a update.formula to deal with formulas like . ~ .
  if (!missing(formula.)) {
    call$formula <- update.formula(formula(object), formula.)
  }

  modify_call(call, dots(...))   
}
update2 <- function(object, formula., ...) {
  call <- update_call(object, formula., ...)
  eval(call, parent.frame())
}
update_call(mod, formula = . ~ . + cyl)
update_call(mod, subset = cyl == 4)
```

The original `update()` has an `evaluate` argument that controls whether the function returns a call or the result, but I think it's good principle for a function to only return one type of object (not different types depending on the arguments) so I split it into two.

This rewrite also allows us to fix a small bug in update: it evaluates the call in the global environment, when really we want to re-evaluate it in the environment where the model was original fit. This happens to be stored in the formula (called terms) so we can easily extract it.

```R
f <- function() {
  n <- 3
  lm(mpg ~ poly(wt, n), data = mtcars)
}
mod <- f()
update(mod, data = mtcars)

update2 <- function(object, formula., ...) {
  call <- update_call(object, formula., ...)
  eval(call, environment(object$terms))
}
update2(mod, data = mtcars)
```

This is a good principle to remember: if want to later replay the code you've captured using `match.call()` you really also need to capture the environment in which the code was evaluated.

There is a big potential downside: because you've captured that environment and saved it in an object, that environment will hang around and any objects in the environment will also hang around. That can have big implications for memory use.  For example, in the following code, the big `x` and `y` objects will be captured in memory.

```R
f <- function() {
  x <- runif(1e7)
  y <- runif(1e7)

  lm(mpg ~ wt, data = mtcars)
}
mod <- f()
object.size(environment(mod$terms)$x)
```

### Exercises

* Create a version of lm that doesn't do any special evaluation: all arguments should be quoted expressions, and it should construct a call to `lm` that preserves all information.

## Creating a function

There's one function call that's so special it's worth devoting a little extra attention to: the `function` function that creates functions. This is one place we'll see pairlists (the object type that predated lists in R's history).  The arguments of a function are stored as a pairlist: for our purposes we can treat a pairlist like a list, but we need to remember to cast arguments with `as.pairlist()`.

```R
str(quote(function(x, y = 1) x + y)[[2]])
````

Building up a function by hand is also useful when you can't use a closure because you don't know in advance what the arguments will be. We'll use `pryr::make_function` to build up a function from its component pieces: an argument list, a quoted body (the code to run) and the environment in which it is defined (which defaults to the.current environment). The function itself is fairly simple: it creates a call to `function` with the args and body as arguments, and then evaluates that in the correct environment so that the function has the right scope;

```R
make_function <- function(args, body, env = parent.frame()) {
  args <- as.pairlist(args)
  env <- to_env(env)

  eval(call("function", args, body), env)
}
```

(`pryr::make_function()` includes a little more error checking but is otherwise identical.)

Let's see a simple example

```R
a <- make_function(alist(a = 1, b = 2), quote(a + b))
add2(1)
add2(1, 2)
```

Note our use of the `alist()` (**a**rgument list) function.  We used this earlier when capturing unevaluated `...`, and we use it again here. Note that `alist()` doesn't evaluate it's arguments and supports arguments with and without defaults (although if you don't want a default you need to be explicit). There's one small trick if you want to have `...` in the argument list: you need to use it on the left-hand side of an equals sign.

```R
make_function(alist(a = , b = a), quote(a + b))
make_function(alist(a = , b = ), quote(a + b))
make_function(alist(a = , b = , ... =), quote(a + b))
```

If you want to mix evaluated and unevaluated functions, it might be easier to make the list by hand:

```R
x <- 1
args <- list()
args$a <- x
args$b <- quote(expr = )

make_function(args, quote(a + b))
```

### Unenclose

Most of the time it's simpler to use closures to create new functions, but `make_function()` is useful if we want to make it obvious to the user what the function does (printing out a closure isn't usually that helpful because all the variables are present by name, not by value).

We could use `make_function()` to create an `unenclose()` function that takes a closure and modifies it so when you look at the source you can see what's going on: 

```R
unenclose <- function(f) {
  env <- environment(f)
  new_body <- substitute2(body(f), env)
  make_function(formals(f), new_body, parent.env(env))
}

f <- function(x) {
  function(y) x + y
}
f(1)
unenclose(f(1))
```

### Exercises

* Why does `unenclose()` use `substitute2()`, not `substitute()`?

* Modify `unenclose` so it only substitutes in atomic vectors, not more complicated objects. (Hint: think about what the parent environment should be.)

* Read the documentation and source for `pryr::partial()` - what does it do? How does it work?

## Walking the call tree with recursive functions

We've seen a couple of examples modifying a single call using `substitute()` or `modify_call()`. What if we want to do something more complicated, drilling down into a nested set of function calls and either extracting useful information or modifying the calls.  The `codetools` package, included in the base distribution, provides some built-in tools for automated code inspection that use these ideas:

* `findGlobals`: locates all global variables used by a function.
  This can be useful if you want to check that your functions don't inadvertently rely on variables defined in their parent 
  environment.

* `checkUsage`: checks for a range of common problems including 
  unused local variables, unused parameters and use of partial 
  argument matching.

In this section you'll learn how to write functions that do things like that.

Because code is a tree, we're going to need recursive functions to work with it. You now have basic understanding of how code in R is put together internally, and so we can now start to write some useful functions. The key to any function that works with the parse tree right is getting the recursion right, which means making sure that you know what the base case is (the leaves of the tree) and figuring out how to combine the results from the recursive case. The nodes of a tree are always calls (except in the rare case of function arguments, which are pairlists), and the leaves are names, single argument calls or constants. R provides a helpful function to distinguish whether an object is a node or a leaf: `is.recursive()`.

### Finding F and T

We'll start with a function returns a single logical value, indicating whether or not a function uses the logical abbreviations `T` and `F`.  Using `T` and `F` is generally considered to be poor coding practice, and it's something that `R CMD check` will warn about.

When writing a recursive function, it's useful to first think about the simplest case: how do we tell if a leaf is a `T` or a `F`?  This is very simple since the set of possibilities is small enough to enumeriate explicitly:

```R
is_logical_abbr <- function(x) {
  identical(x, quote(T)) || identical(x, quote(F))
}
is_logical_abbr(quote(T))
is_logical_abbr(quote(TRUE))
is_logical_abbr(quote(true))
is_logical_abbr(quote(10))
```

Next we right the recursive function. The base case is simple: if the object isn't recursive, then we just return the value of `is_logical_abbr()` applied to the object. If the object is not a node, then we work through each of the elements of the node in turn, recursively calling `logical_abbr()`. We need a special case for functions because we can't iterate through their components, instead we need to explicitly operate on the body and formals separately.

```R
logical_abbr <- function(x) {
  # Base case
  if (!is.recursive(x)) return(is_logical_abbr(x))

  # Recursive cases
  if (is.function(x)) {
    if (logical_abbr(body(x))) return(TRUE)
    if (logical_abbr(formals(x))) return(TRUE)
  } else {
    for (i in seq_along(x)) {
      if (logical_abbr(x[[i]])) return(TRUE)
    }
  }

  FALSE
}

logical_abbr(quote(T))
logical_abbr(quote(mean(x, na.rm = T)))

f <- function(x = TRUE) {
  g(x + T)
}
logical_abbr(f)
```

### Finding all variables created by assignment

In this section, we will write a function that figures out all variables that are created by assignment in an expression. We'll start simply, and make the function progressively more rigorous. One reason to start with this function is because the recursion is a little bit simpler - we never need to go all the way down to the leaves because we are looking for assignment, a call to `<-`.  

This means that our base case is simple: if we're at a leaf, we've gone too far and can immediately return. We have two other cases: we have hit a call, in which case we should check if it's `<-`, otherwise it's some other recursive structure and we should call the function recursively on each element. Note the use of identical to compare the call to the name of the assignment function, and recall that the second element of a call object is the first argument, which for `<-` is the left hand side: the object being assigned to.

```R
is_call_to <- function(x, name) {
  is.call(x) && identical(x[[1]], as.name(name))
}

find_assign <- function(obj) {
  # Base case
  if (!is.recursive(obj)) return()

  if (is_call_to(obj, "<-")) {
    obj[[2]]
  } else {
    lapply(obj, find_assign)
  }
}
find_assign(quote(a <- 1))
find_assign(quote({
  a <- 1
  b <- 2
}))
```

This function seems to work for these simple cases, but the output is rather verbose. Instead of returning a list, let's keep it simple and stick with a character vector. We'll also test it with two slightly more complicated examples:

```R
find_assign <- function(obj) {
  # Base case
  if (!is.recursive(obj)) return(character())

  if (is_call_to(obj, "<-")) {
    as.character(obj[[2]])
  } else {
    unlist(lapply(obj, find_assign))
  }
}
find_assign(quote({
  a <- 1
  b <- 2
  a <- 3
}))
# [1] "a" "b" "a"
find_assign(quote({
  system.time(x <- print(y <- 5))
}))
# [1] "x"
```

This is better, but we have two problems: repeated names, and we miss assignments inside function calls. The fix for the first problem is easy: we need to wrap `unique()` around the recursive case to remove duplicate assignments. The second problem is a bit more subtle: it's possible to do assignment within the arguments to a call, but we're failing to recurse down in to this case. 

```R
find_assign <- function(obj) {
  # Base case
  if (!is.recursive(obj)) return(character())

  if (is_call_to(obj, "<-")) {
    call <- as.character(obj[[2]])
    c(call, unlist(lapply(obj[[3]], find_assign)))
  } else {
    unique(unlist(lapply(obj, find_assign)))
  }
}
find_assign(quote({
  a <- 1
  b <- 2
  a <- 3
}))
# [1] "a" "b"
find_assign(quote({
  system.time(x <- print(y <- 5))
}))
# [1] "x" "y"
```

There's one more case we need to test:

```R
find_assign(quote({
  ls <- list()
  ls$a <- 5
  names(ls) <- "b"
}))
# [1] "ls"        "ls$a"      "names(ls)"
draw_tree(quote({
  ls <- list()
  ls$a <- 5
  names(ls) <- "b"
}))
```

This behaviour might be ok, but we probably just want assignment into whole objects, not assignment that modifies some property of the object. Drawing the tree for that quoted object helps us see what condition we should test for - we want the object on the left hand side of assignment to be a name.  This gives the final version of the `find_assign` function.

```R
find_assign <- function(obj) {
  # Base case
  if (!is.recursive(obj)) return(character())

  if (is_call_to(obj, "<-")) {
    call <- if (is.name(obj[[2]])) as.character(obj[[2]])
    c(call, unlist(lapply(obj[[3]], find_assign)))
  } else {
    unique(unlist(lapply(obj, find_assign)))
  }
}
find_assign(quote({
  ls <- list()
  ls$a <- 5
  names(ls) <- "b"
}))
[1] "ls"
```

Making this function work absolutely correct requires quite a lot more work, because we need to figure out all the other ways that assignment might happen: with `=`, `assign()`, or `delayedAssign()`. But a static tool can never be perfect: the best you can hope for is a set of heuristics that catches the most common 90% of cases. 

### Modifying the call tree

Instead of returning vectors computed from the contents of an expression, you can also return a modified expression, such as base R's `bquote()`. `bquote()` is a slightly more flexible form of quote: it allows you to optionally quote and unquote some parts of an expression (it's similar to the backtick operator in lisp).  Everything is quoted, _unless_ it's encapsulated in `.()` in which case it's evaluated and the result is inserted.

```R
a <- 1
b <- 3
bquote(a + b)
bquote(a + .(b))
bquote(.(a) + .(b))
bquote(.(a + b))
```

This provides a fairly easy way to control what gets evaluated when you call `bquote()`, and what gets evaluated when the expression is evaluated. How does `bquote()` work? Below, I've rewritten `bquote()` to use the same style as our other functions: it expects input to be quoted already, and makes the base and recursive cases more explicit:

```R
bquote2 <- function (x, where = parent.frame()) {
  # Base case
  if (!is.recursive(x)) return(x)

  if (is.call(x)) {
    if (identical(x[[1]], quote(.))) {
      # Call to .(), so evaluate
      eval(x[[2]], where)
    } else {
      as.call(lapply(x, bquote2, where = where))
    }
  } else if (is.pairlist(x)) {
    as.pairlist(lapply(x, bquote2, where = where))
  } else {
    stop("Unknown case")
  }
}
x <- 1
bquote2(quote(x == .(x)))
y <- 2
bquote2(quote(function(x = .(x)) {
  x + .(y)
}))
```

Note that functions that modify the source tree are most useful for creating expressions that are used at run-time, not saved back into the original source file.  That's because all non-code information is lost:

```R
bquote2(quote(function(x = .(x)) {
  # This is a comment
  x +  # funky spacing
    .(y)
}))
```

It is possible to work around this problem using `srcrefs` and `getParseData`, but neither solution naturally fits this hierarchical framework. You effectively end up having to recreate huge chunks of R's internal code in order to handle the majority of R code.  So the above approach can be useful in simple cases (particularly when you don't care what the output code looks like), but it's very hard to automatically transform R code, and is beyond the scope of this book.

`bquote()` is rather like a macro from a languages like LISP.  
But unlike macros the modifications occur at runtime, not compile time (which doesn't have any meaning in R). And unlike a macro there is no restriction to return an expression: a macro-like function in R can return anything. More like `fexprs`. a fexpr is like a function where the arguments aren't evaluated by default; or a macro where the result is a value, not code. 

[Programmer’s Niche: Macros in R](http://www.r-project.org/doc/Rnews/Rnews_2001-3.pdf#page=11) by Thomas Lumley.

### Exercises

* Write a function that extracts all calls to a function. Compare your function to `pryr::fun_calls()`.

