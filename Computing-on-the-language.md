# Computing on the language

R has powerful tools for computing not only on values, but also on expressions

These tools are very useful for developing convenient user-facing functions because they dramatically reduce the amount of typing required to specify an action.  This abbreviation comes at a cost of somewhat increasing ambiguity in the function call, and by making the function difficult to call from another function.

Accessing expressions, not just value:

* Basic terminology

* understand how many functions capture the name of the variable supplied to them: `data.frame()`, `save()`, and many functions in the graphics and stats packages

* Learn why the use of understand special evaluation to avoid quotes can be problematic: `library()`, `require()`, `rm()`, `data()`, `demo()`, `example()`, `vignette()`  (Less desirable)

* Work around non-standard evaluation with (like lattice functions) `substitute`.

* Manipulate a data frame by referring to the variables:  `subset()`, `transform()`, `plyr::mutate()`, `plyr::arrange()`, `plyr::summarise()`, `with()`

* Capture an expression for later evaluation: ggplot2 and plyr

* Use formulas to describe computations: `lm()` and the lattice package

Downsides: unlike other languages no formal way to distinguish between regular and special evaluation. Must document!

## Motivation: subset

You might already be familiar with the `subset` function. If not sure, it's a useful interactive shortcut for subsetting data frames: instead of repeating the data frame you're working with again and again, you can save some typing:

    subset(mtcars, vs == am)
    # equivalent to:
    mtcars[mtcars$vs == mtcars$am, ]
    
    subset(mtcars, cyl == 4)
    # equivalent to:
    mtcars[mtcars$cyl == 4, ]

Subset is special because `vs == am` or `cyl == 4` aren't evaluated in the global environment (your usual workspace), they're evaluated in the context of the data frame. In other words, subset implements different [[scoping|Scoping]] rules so instead of looking for those variables in the current environment, subset looks in the specified data frame. 

To do this, `subset` must be able to capture the meaning of your condition string without evaluating it. Generally, this is called __non-standard evaluation__: you are deliberately breaking R's usual rules in order to do something special

## Capturing expressions, not values

Another function that can capture the original call is `substitute`:

    subset <- function(x, condition) {
      substitute(condition)
    }    
    subset(mtcars, vs == am)
    # vs == am

Substitute is the tool most commonly used for this task, but it's the hardest to explain because it relies on lazy evaluation. In R, function arguments are only evaluated when they are needed, not automatically when the function is called. Before the argument is evaluated (aka forced), it is stored as a __promise__. A promise stores two things: the call that should be evaluated and the environment in which to evaluate it. When substitute is passed a promise, it extracts the call, which is the thing we're looking for.

We'll discuss in more detail what a call object looks like in ...

Once we have the call, we need to evaluate it in the way we want, as described next.

## Evaluation

Now that we have the call that represents the subset condition we want, we want to evaluate it in the right context, so that `cyl` is interpreted as `mtcars$cyl`.  To do this we need the `eval` function:

    eval(quote(cyl), mtcars)
    #  [1] 6 6 4 6 8 6 8 4 4 6 6 8 8 ...

    eval(quote(cyl1), mtcars)
    # Error in eval(expr, envir, enclos) : object 'cyl1' not found

    eval(cyl, mtcars)
    # Error in eval(cyl, mtcars) : object 'cyl' not found

    eval(as.name('cyl'), mtcars)
    # [1] 6 6 4 6 8 6 8 4 4 6 6 8 8 8 8 8 8 4 4 4 4 8 8 8 8 4 4 4 8 6 8 4

    cyl <- quote(cyl)
    eval(cyl, mtcars)
    #  [1] 6 6 4 6 8 6 8 4 4 6 6 8 8 ...

The first argument to `eval` is the language object to evaluate, and the second argument is the environment to use for evaluation.  If the second argument is a list or data frame, `eval` will convert it to an environment for you. (There are a number of short cut functions: `evalq`, `eval.parent` that are also documented with `eval` - I won't use or explain these here, I'd recommend you read about them and figure out what they do.)

Now we have all the pieces we need to write the `subset` function: we can capture the call representing condition then evaluate it in the context of the data frame:

    subset <- function(x, condition) {
      condition_call <- substitute(condition)
      r <- eval(condition_call, x)
      x[r, ]
    }
 
Unfortunately, we're not quite done because this function doesn't work as we always expect.

    subset(mtcars, cyl == 4)
    #      mpg cyl disp hp drat wt qsec vs am gear carb
    # NA     NA  NA   NA NA   NA NA   NA NA NA   NA   NA
    # NA.1   NA  NA   NA NA   NA NA   NA NA NA   NA   NA
    # NA.2   NA  NA   NA NA   NA NA   NA NA NA   NA   NA
    # NA.3   NA  NA   NA NA   NA NA   NA NA NA   NA   NA
    # NA.4   NA  NA   NA NA   NA NA   NA NA NA   NA   NA
    # NA.5   NA  NA   NA NA   NA NA   NA NA NA   NA   NA

## Scoping issues

What do you expect the following to do:

    x <- 4
    subset(mtcars, cyl == x)

It should be the same as `subset(mtcars, cyl == 4)`, right? But how exactly does this work and where does subset look for the value of `x`? It's not going to be the right value inside the subset function because the first argument of `subset` is called `x`. Inside the subset function `x` will have the same value of `mtcars`.

The key is the third argument of `eval`: `enclos`. This allows us to specify the parent (or enclosing) environment for objects that don't have one like lists and data frames (`enclos` is ignored if we pass in a real environment). The `enclos`ing environment is where any objects that aren't found in the data frame will be looked for. By default it uses the current environment, which is not what we want.

We want to look for `x` in the environment in which `subset` was called. In R terminology this is called the __parent frame__ and is accessed with `parent.frame()`. This is an example of [dynamic scope](http://en.wikipedia.org/wiki/Scope_%28programming%29#Dynamic_scoping). With this modification our function works:

    subset <- function(x, condition) {
      condition_call <- substitute(condition)
      r <- eval(condition_call, x, parent.frame())
      x[r, ]
    }
    
    x <- 4
    subset(mtcars, cyl == x)

When evaluating code in a non-standard way, it's also a good idea to test your code outside of the global environment:

    f <- function() {
      x <- 6
      subset(mtcars, cyl == x)
    }
    f()

And it works :)



## Calling from another function

While `subset` saves typing, it has one big disadvantage: it's now difficult to use non-interactively, e.g. from another function.

Computing on the language is an extremely powerful tool, but it can also create code that is hard for others to understand. Before you use it, make sure that you have exhausted all other possibilities. This section shows a couple of examples of inappropriate use of computing on the language that you should avoid reproducing.

Typically, computing on the language is most useful for functions called directly by the user, not by other functions. For example, you might try using `subset()` from within a function that is given the name of a variable and it's desired value:

```R
colname <- "cyl"
val <- 6

subset(mtcars, colname == val)
# Zero rows because "cyl" != 6

col <- as.name(colname)
substitute(subset(mtcars, col == val), list(col = col, val = val))
bquote(subset(mtcars, .(col) == .(val)))
```

Typically, it's better to avoid the function that does non-standard evaluation, and use the underlying verbose code.  In this case, use subsetting, not the subset function:

```R
mtcars[mtcars[[colname]] == val, ]
```


Imagine we want to create a function that randomly reorders a subset of the data. A nice way to write that function would be to write a function for random reordering and a function for subsetting (that we already have!) and combine the two together. Let's try that:

    scramble <- function(x) x[sample(nrow(x)), ]
    
    subscramble <- function(x, condition) {
      scramble(subset(x, condition))
    }

But when we run that we get:

    subscramble(mtcars, cyl == 4)
    # Error in eval(expr, envir, enclos) : object 'cyl' not found
    traceback()
    # 5: eval(expr, envir, enclos)
    # 4: eval(condition_call, x)
    # 3: subset(x, condition)
    # 2: scramble(subset(x, condition))
    # 1: subscramble(mtcars, cyl == 4)

What's gone wrong? To figure it out, lets `debug` subset and work through the code line-by-line:

    > debugonce(subset)
    > subscramble(mtcars, cyl == 4)
    debugging in: subset(x, condition)
    debug: {
        condition_call <- substitute(condition)
        r <- eval(condition_call, x)
        x[r, ]
    }
    Browse[2]> n
    debug: condition_call <- substitute(condition)
    Browse[2]> n
    debug: r <- eval(condition_call, x)
    Browse[2]> condition_call
    condition
    Browse[2]> eval(condition_call, x)
    Error in eval(expr, envir, enclos) : object 'cyl' not found
    Browse[2]> condition
    Error: object 'cyl' not found
    In addition: Warning messages:
    1: restarting interrupted promise evaluation 
    2: restarting interrupted promise evaluation

Can you see what the problem is? `condition_call` contains the call `condition` and when we try to evaluate that it looks up the symbol `condition` which has the value `cyl == 4`, which can't be computed in the parent environment because it doesn't contain an object called `cyl`. If `cyl` is set in the global environment, far more confusing things can happen:

    cyl <- 4
    subscramble(mtcars, cyl == 4)
    
    cyl <- sample(10, 100, rep = T)
    subscramble(mtcars, cyl == 4)

This is an example of the general tension in R between functions that are designed for interactive use, and functions that are safe to program with. Generally any function that uses `substitute` or `match.call` to retrieve a call, instead of a value, is more suitable for interactive use. 

As a developer you should also provide an alternative version that works when passed a call. You might wonder why the function couldn't do this automatically:

    subset <- function(x, condition) {
      if (!is.call(condition)) {
        condition <- substitute(condition)
      }
      r <- eval(condition, x)
      x[r, ]
    }
    subset(mtcars, quote(cyl == 4))
    subset(mtcars, cyl == 4)

But hopefully a little thought, or maybe some experimentation, will show why this doesn't work.

## Substitute

`substitute()` is a general purpose tool with two main jobs: modifying expressions and capturing the expressions associated with function arguments. It's used most commonly for the second purpose (e.g. as in `plot()`, where its used to label the x and y axes appropriately), but the other purpose is tremendously useful when you're constructing calls by yourself.

`substitute()` has two arguments: `expr`, an R expression captured with non-standard evaluation; and `env`, an environment used to modify `expr`.  If `env` is the global environment then `expr` is returned unchanged. This makes `subsitute()` a little harder to play with interactively, because we always need to run it inside another environment. The following example shows the basic job of `substitute()`: modifying an expression to replace names with values.

```R
local({
  a <- 1
  b <- 2
  substitute(a + b + x)
})
```

Note that if we run this code in the global environment, nothing happens:

```R
a <- 1
b <- 2
substitute(a + b + x)
```

If you do want to use `substitute()` in the global environment (or you want to be careful elsewhere), you can use the second argument to provide a list or environment of values to be substituted:

```R
substitute(a + b + x, list(a = a, b = b))
substitute(a + b + x, as.list(globalenv()))
```

The second argument is also useful if you want to control exactly what gets modified in the original call.

Formally, substitution takes place by examining each name in the expression, and replacing the name if it refers to:

* a promise, it's replaced by the expression associated with the promise. 
 
* an ordinary variable, it's replaced by the value of the variable.

* `...`, it's replaced by the contents of `...`.

Otherwise the name is left as is. 

It's quite possible to make nonsense commands with `substitute`

```R
substitute(y <- y + 1, list(y = 1))
```

If you want to substitute in a variable or function name, you need to be careful to supply the right type object to substitute:
    
```R
substitute(a + b, list(a = y))
# Error: object 'y' not found

substitute(a + b, list(a = "y"))
# "y" + b

substitute(a + b, list(a = as.name("y")))
# y + b

substitute(a + b, list(a = quote(y)))
# y + b

substitute(a + b, list(a = y()))
# Error: could not find function "y"

substitute(a + b, list(a = quote(y())))
# y() + b
```

Note that `substitute` doesn't evaluate its first argument:

```R
x <- quote(a + b)
substitute(x, list(a = 1, b = 2))
# x
```

We can create our own adaption of `substitute` (that uses `substitute`!) to work around this: (This function is also available in `pryr`)

```R
substitute2 <- function(x, env) {
  call <- substitute(substitute(x, env), list(x = x))
  eval(call)
}
x <- quote(a + b)
substitute2(x, list(a = 1, b = 2))
```

Notice that we use the second argument to substitute twice: in the outer call to ensure that we only substitute `x`, not `env`; and in the inner call to make sure substitution happens using the variables in the user specified environment.

When writing functions like this, I find it helpful to do the evaluation last, only after I've made sure that I've constructed the correct substitute call with a few test inputs. If you split the two pieces (call construction and evaluation) into two functions, it's also much easier to test more formally.

As a general principle, whenever you write a function that uses non-standard evaluation, you always also want to provide a version that uses standard evaluation, and expects the user to provide quoted inputs. Otherwise, they'll have to resort to `substitute()` tricks, like above. (`substitute()` is an exception to this, because there must be a built in base function that doesn't evaluate it's arguments otherwise we could never capture the first)

A common idiom in R functions is `deparse(substitute(x))` - this will capture the character representation of the code provided for the argument `x`.  Remember that if expression of x is long, this will create a character vector with multiple elements, so prepare accordingly.

As mentioned above, you can put any arbitrary R object into a call, not just atomic vectors, names and other calls. This is technically ok, but often results in undesiderable behaviour:

```R
df <- data.frame(x = 1)
x <- substitute(class(df), list(df = df))
x
deparse(x)
eval(x)
```

## When not to use substitute

There are a number of base functions that use `substitute()` to capture the expression you've typed instead of just the value.  These include `data.frame()` and `library()`.

For example, `data.frame()` uses the input expressions to automatically name the output variables if not otherwise provided:

```R
x <- 10
y <- "a"
df <- data.frame(x, y)
names(df)
```

We could use this same idea to implement a function for lists:

```R
list2 <- function(...) {
  out <- list(...)
  nms_out <- names(out)
  nms_in <- vapply(eval(substitute(alist(...))), deparse, character(1))

  if (is.null(nms_out)) {
    names(out) <- nms_in
  } else {
    missing <- nms_out == ""
    names(out)[missing] <- nms_in[missing]
  }
  out
}
list2(x, y)
list2(x, z = y)
```

There are also a number of functions in R that use this in a less effective way, just to avoid using quotes.  For example `library()` and `require()` allow you to call them either with or without quotes. These two lines do exactly the same thing:

```R
library(ggplot2)
library("ggplot2")
```

Things start to get complicated however, when you want to load a package given by a variable.  What do you think the following lines of code will do?

```R
x <- "plyr"
library(x)

ggplot2 <- "plyr"
library(ggplot2)
```

For these to work, you have to use an additional argument:

```R
library(x, character.only = TRUE)
```

In my opinion this is not an effective use of substitute because it is confusing, needs an extra argument for a common scenario and only saves two characters.

`ls()` is another offender:

```R
objs <- ls(package:base)

rm(x)
ls(x)

x <- "package:plyr"
ls(x)
```

Here it has different behaviour based on whether or not x is defined!

This is what the code inside `ls()` looks like, and you can easily imagine situations where it will fail.

```R
if (!missing(name)) {
    nameValue <- try(name, silent = TRUE)
    if (identical(class(nameValue), "try-error")) {
        name <- substitute(name)
        if (!is.character(name)) 
            name <- deparse(name)
        warning(gettextf("%s converted to character string", 
            sQuote(name)), domain = NA)
        pos <- name
    }
    else pos <- nameValue
}

```

Generally you want to avoid creating situations where the regular behaviour of R (only value matters, not name) is broken, unless there is significant gain. In my mind, eliminating two quotes does not meet this threshold.  It is useful in `data.frame()` because it eliminates a lot of redundancy in the common scenario when you're creating a data frame from existing variables.


## Formulas

There is one other approach we could use: a formula. `~` works much like quote, but it also captures the environment in which it is created. We need to extract the second component of the formula because the first component is `~`.

    subset <- function(x, f) {
      r <- eval(f'[[2]], x, environment(f))
      x[r, ]
    }
    subset(mtcars, ~ cyl == x)


## Plyr

The plyr package uses this ideas to make a small DSL for manipulating data frames: in addition to the base `subset()` and `transform()` function, plyr provides `mutate()`, `summarise()` and `arrange()`. Each of these functions has the same interface: the first argument is a data frame and the subsequent arguments are evaluated in the context of that data frame (i.e. they look there first for variables, and then in the current environment) and they return a data frame.

```R
subset <- function(x, subset) {
  r <- eval(substitute(subset), x, parent.frame())
  r <- r & !is.na(r)

  x[r, vars, drop = drop]
}
arrange <- function (.data, ...) {
  ord <- eval(substitute(order(...)), .data, parent.frame())
  .data[ord, , drop = FALSE]
}
mutate <- function (.data, ...) {
  cols <- eval(substitute(alist(...)))
  for (col in names(cols)) {
    .data[[col]] <- eval(cols[[col]], .data, parent.frame())
  }
  .data
}
summarise2 <- function (.data, ...) {
  env <- list2env(.data, parent = parent.frame())

  cols <- eval(substitute(alist(...)))
  for (col in names(cols)) {
    env[[col]] <- eval(cols[[col]], env)
  }
  quickdf(mget(names(cols), env))
}
```

## Conclusion

Now that you understand how our version of subset works, go back and read the source code for `subset.data.frame`, the base R version which does a little more. Other functions that work similarly are `with.default`, `within.data.frame`, `transform.data.frame`, and in the plyr package `.`, `arrange`, and `summarise`. Look at the source code for these functions and see if you can figure out how they work.

## Exercises

1. Compare the simplified `subset` function described in this chapter with the real `subset.data.frame`.  What's different? Why? How does the select parameter work?

2. Read the code for `transform.data.frame` and `subset.data.frame`. What do they do and how do they work? Compare `transform.data.frame` to `plyr::mutate` what's different?
