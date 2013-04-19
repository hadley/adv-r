# Special evaluation

R has powerful tools for computing not only on values, but also on expressions. These tools powerful and magical, and one of the most surprising features if you're coming from another programming language.  Take the following simple snippet of code that draws a sine curve:

```R
x <- seq(0, 2 * pi, length = 100)
sinx <- sin(x)
plot(x, sinx, type = "l")
```

Look at the labels on the axes! How did R know that the variable on the x axis was called `x` and the variable on the y axis was called `sinx`? In most programming languages, you can only values of the arguments provided to functions, but in R you can also access the expression used to computing them. Combined with R's lazy evaluation mechanism this gives function authors considerable power to both access the underlying expression and do special things with it.

Techniques based on these tools are generally called "computing on the language", and in R provide a set of tools with power equivalent to functional and object oriented programming.  This chapter will introduce you to the basic ideas of special evaluation, show you how they are used in base R, and how you can use them to create your own functions that save typing for interactive analysis. These tools are very useful for developing convenient user-facing functions because they can dramatically reduce the amount of typing required to specify an action.  

Computing on the language is an extremely powerful tool, but it can also create code that is hard for others to understand and is substantially harder to program with. Before you use it, make sure that you have exhausted all other possibilities. You'll also learn about the downsides: because these tools work with expressions rather than values this increases ambiguity in the function call, and makes the function difficult to call from another function.

The following chapters [[expressions]] and [[special-environments]], expand on these ideas, discussing the underlying data structures and how you can understand and manipulate them to create new tools.

In this chapter you'll learn:

* how many functions such as `plot()` and `data.frame()` capture the names of the variable supplied to them, and the downsides of this technique.

* Manipulate a data frame by referring to the variables:  `subset()`, `transform()`, `plyr::mutate()`, `plyr::arrange()`, `plyr::summarise()`, `with()`

* Work around non-standard evaluation with (like lattice functions) `substitute`.

* Capture an expression for later evaluation: ggplot2 and plyr

* Use formulas to describe computations: `lm()` and the lattice package

## Capturing expressions

The tool that makes non-standard evaluation possible in R is `substitute()`. It looks at a function argument, and instead of seeing the value, it looks to see how the value was computed:

```R
f <- function(x) {
  substitute(x)
}
f(1:10)
f(x)
f(x + y ^ 2 / z + exp(a * sin(b)))
```

We won't worry yet about exactly what sort of object `substitute()` returns (that's the topic of the [[Expressions]] chapter), but we'll call it an expression.  (Note that it's not the same thing as returned by the `expression()` function: we'll call that an expression _object_.)

`substitute()` works because function arguments in R are only evaluated when they are needed, not automatically when the function is called. This means that functions are not just a simple value, but instead store both the expression to compute the value and and the environment in which to compute it. Together these two things are called a __promise__. Most of the time in R, you don't need to anything about promises because the first time you access a promise it is seemlessly evaluated, returning its vaue.

We need one more function if we want to understand how `plot()` and `data.frame()` work: `deparse()`. This function takes an expression and converts it to a character vector.

```R
g <- function(x) deparse(substitute(x))
g(1:10)
g(x)
g(x + y ^ 2 / z + exp(a * sin(b)))
```

There's one important caveat with `deparse()`: it can return a multiple strings if the input is long:

```R
g(a + b + c + d + e + f + g + h + i + j + k + l + m + n + o + p + q + r + s + t + u + v + w + x + y + z)
```

If you need a single string, you can work around this by using the `width.cutoff` argument (which has a maximum value of 500), or by joining the lines back together again with `paste()`.

You might wonder we couldn't use our original `f()` to compute `g()`.  Let's try it:

```R
g <- function(x) deparse(f(x))
g(1:10)
g(x)
g(x + y ^ 2 / z + exp(a * sin(b)))
```

This is one of the downsides of functions that use `substitute()`: because they use the expression, not the value, of an argument, it becomes harder to call them from other functions.  We'll talk more about this problem and some remedies later on.

There are a lots of function in base R that use these ideas. Some use them to avoid quotes:

```R
library(ggplot2) 
library("ggplot2")
```

Others use them to provide default labels. For example, `plot.default()` has code that basically does (the real code is more complicated because of the way base plotting methods work, but it's effectively the same):

```R
plot.default <- function(x, y = NULL, xlabel = NULL, ylabel = NULL, ...) {
    ...
    xlab <- if (is.null(xlab) && !missing(x)) deparse(substitute(x))
    ylab <- if (is.null(xlab) && !missing(y)) deparse(substitute(y))
    ...
}
```

If a label is not set and the variable is present, then the expression used to generate the value of `x` is used as a default value for the label on the x axis.

`data.frame()` does a similar thing.  It automatically labels variables with the expression used to compute them:

```R
x <- 1:4
y <- letters[1:4]
names(data.frame(x, y))
```

This wouldn't be possible in most programming langauges because functions usually only see values (e.g. `1:4` and `c("a", "b", "c", "d")`), not the expressions that created them (`x` and `y`).

## Non-standard evaluation in subset

Just printing out the expression used to generate an argument value is useful, but we can do even more with the unevaluated function.  For exampple, take `subset()`. It's a useful interactive shortcut for subsetting data frames: instead of repeating the data frame you're working with again and again, you can save some typing:

```R
subset(mtcars, cyl == 4)
# equivalent to:
# mtcars[mtcars$cyl == 4, ]

subset(mtcars, vs == am)
# equivalent to:
# mtcars[mtcars$vs == mtcars$am, ]
```

Subset is special because `vs == am` or `cyl == 4` aren't evaluated in the global environment: instead they're evaluated in the data frame. In other words, `subset()` implements different [[scoping|Scoping]] rules so instead of looking for those variables in the current environment, `subset()` looks in the specified data frame. This is called __non-standard evaluation__: you are deliberately breaking R's usual rules in order to do something special.

How does `subset()` work?  We've already seen how to capture the expression that represents an argument, rather than its value, so we just need to figure out how to evaluate that expression in the right context: i.e. `cyl` should be interpreted as `mtcars$cyl`. To do this we need `eval()`, which takes an expression and evaluates it in the specified environment.

But before we can do that, we need to learn one more useful function: `quote()`. It's similar to `substitute()` but it always gives you back exactly the expression you entered. This makes it useful for interactive experimentation.

```R
quote(1:10)
quote(x)
quote(x + y ^ 2 / z + exp(a * sin(b)))
```

Now let's experiment with `eval()`.  If you only provide one argument, it evaluates the expression in the current environment.  This makes `eval(quote(x))` exactly equivalent to typing `x`, regardless of what `x` is: 

```R
eval(quote(x <- 1))
eval(quote(x))

eval(quote(cyl))
```

The second argument to `eval()` controls which environment the code is evaluated in:

```
x <- 10
eval(quote(x))

e <- new.env()
e$x <- 20
eval(quote(x), e)
```

Instead of an environments, the second argument can also be a list or a data frame.  This works because an environment is basically a set of mappings between names and values, in the same way as a list or data frame.

```R
eval(quote(x), list(x = 30))
eval(quote(x), data.frame(x = 40))
```

This is basically what we want for `subset()`:

```R
eval(quote(cyl == 4), mtcars)
eval(quote(vs == am), mtcars)
```

We can combine `eval()` and `substitute()` together to write `subset()`: we can capture the call representing the condition, evaluate it in the context of the data frame, and then use the result for subsetting:

```R
subset2 <- function(x, condition) {
  condition_call <- substitute(condition)
  r <- eval(condition_call, x)
  x[r, ]
}
subset2(mtcars, cyl == 6)
```

When you first start using `eval()` it's easy to make mistakes.  Here's a common one: forgetting to quote the input:

```R
eval(cyl, mtcars)
# Carefully look at the difference to this error
eval(quote(cyl1), mtcars)
```

### Exercises

* The real subset function (`subset.data.frame()`) does two other things to the result. What are they?

* The other component of the real subset function is variable selection. It allows you to work with variable names like they are positions, so you can do things like `subset(mtcars, -cyl)` to drop the cylinder variable, or `subset(mtcars, disp:drat)` to select all the variables between `disp` and `drat`.   How does select work? I've made it easier to understand by extracting it out into it's own function:

    ```R
    select <- function(df, vars) {
      vars <- substitute(vars)
      var_pos <- setNames(as.list(seq_along(df)), names(df))
      pos <- eval(vars, var_pos)
      df[, pos, drop = FALSE]
    }
    select(mtcars, -cyl)
    ```

* What does `evalq()` do? Use it to reduce the amount of typing for the examples above that use both `eval()` and `quote()`

## Scoping issues

While it certainly looks like our `subset2()` function works, whenever we're working with expressions instead of values, we need to test a little more carefully. For example, you might expect that the following uses of `subset2()` should all return the same value:

```R
y <- 4
x <- 4
condition <- 4
condition_call <- 4

subset2(mtcars, cyl == 4)
subset2(mtcars, cyl == y)
subset2(mtcars, cyl == x)
subset2(mtcars, cyl == condition)
subset2(mtcars, cyl == condition_call)
```

What's going wrong? You might get a hint given by the variable names I've chosen: they are all variables defined inside `subset2()`. It seems like if `eval()` can't find the variable instead of the data frame (it's second argument), it's looking in the function environment.  That's obviously not what we want, so we need some way to tell `eval()` to look somewhere else if it can't find the variables in the data frame.

The key is the third argument: `enclos`. This allows us to specify the parent (or enclosing) environment for objects that don't have one like lists and data frames (`enclos` is ignored if we pass in a real environment). The `enclos`ing environment is where any objects that aren't found in the data frame will be looked for. By default it uses the environment of the current function, which is not what we want.

We want to look for `x` in the environment in which `subset` was called. In R terminology this is called the __parent frame__ and is accessed with `parent.frame()`. This is an example of [dynamic scope](http://en.wikipedia.org/wiki/Scope_%28programming%29#Dynamic_scoping). With this modification our function works:

```R
subset2 <- function(x, condition) {
  condition_call <- substitute(condition)
  r <- eval(condition_call, x, parent.frame())
  x[r, ]
}

x <- 4
subset2(mtcars, cyl == x)
```

Using `enclos` is just a short cut for converting a list or data frame to an environment with the desired parent yourself.  For example, the function above is equivalent to:

```R
subset2 <- function(x, condition) {
  condition_call <- substitute(condition)
  env <- list2env(x, parent = parent.frame())
  r <- eval(condition_call, env)
  x[r, ]
}

x <- 4
subset2(mtcars, cyl == x)
```

When evaluating code in a non-standard way, it's also a good idea to test your code works when run outside of the global environment:

```R
f <- function() {
  x <- 6
  subset(mtcars, cyl == x)
}
f()
```

And it does work :)

### Exercises

* `plyr::arrange()` works similar to `subset()`, but instead of selecting rows, it reorders them. How does it work?  What does `substitute(order(...))` do?

* What does `transform()` do? (Hint: read the documentation). How does it work? (Hint: read the source code for `transform.data.frame`) What does `substitute(list(...))` do? (Hint: create a function that does only that and experiment with it).

* `plyr::mutate()` is similar to `transform()` but it applies the transformations sequentially so that transformation can refer to columns that were just created:

  ```R
  df <- data.frame(x = 1:5)
  transform(df, x2 = x * x, x3 = x2 * x)
  plyr::mutate(df, x2 = x * x, x3 = x2 * x)
  ```

  How does mutate work? What's the key difference between mutate and transform?

* What does `with()` do? How does it work? (Read the source code for `with.default()`)

* What does `within()` do? How does it work? (Read the source code for `within.data.frame()`). What makes the code so much more complicated that `with()`?

## Calling from another function

Typically, computing on the language is most useful for functions called directly by the user, not by other functions. While `subset` saves typing, it has one big disadvantage: it's now difficult to use non-interactively, e.g. from another function. For example, you might try using `subset()` from within a function that is given the name of a variable and it's desired value:

```R
colname <- "cyl"
val <- 6

subset(mtcars, colname == val)
# Zero rows because "cyl" != 6
```

Or imagine we want to create a function that randomly reorders a subset of the data. A nice way to write that function would be to write a function for random reordering and a function for subsetting (that we already have!) and combine the two together. Let's try that:

```R
scramble <- function(x) x[sample(nrow(x)), ]

subscramble <- function(x, condition) {
  scramble(subset(x, condition))
}
```

But when we run that we get:

```R
subscramble(mtcars, cyl == 4)
# Error in eval(expr, envir, enclos) : object 'cyl' not found
traceback()
# 5: eval(expr, envir, enclos)
# 4: eval(condition_call, x)
# 3: subset(x, condition)
# 2: scramble(subset(x, condition))
# 1: subscramble(mtcars, cyl == 4)
```

What's gone wrong? To figure it out, lets `debug` subset and work through the code line-by-line:

```R
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
```

Can you see what the problem is? `condition_call` contains the expression `condition` and when we try to evaluate that it looks up the symbol `condition` which has the value `cyl == 4`, which can't be computed in the parent environment because it doesn't contain an object called `cyl`. If `cyl` is set in the global environment, far more confusing things can happen:

```R
cyl <- 4
subscramble(mtcars, cyl == 4)

cyl <- sample(10, 100, rep = T)
subscramble(mtcars, cyl == 4)
```

This is an example of the general tension in R between functions that are designed for interactive use, and functions that are safe to program with. Generally any function that uses `substitute()` to retrieve an expression instead of a value, is more suitable for interactive use than use from within another function. 

As a developer you should also provide an alternative version that works when passed a call. 

Typically, it's better to avoid the function that does non-standard evaluation, and use the underlying verbose code.  In this case, use subsetting, not the subset function:

```R
mtcars[mtcars[[colname]] == val, ]
```

For example, we could rewrite:

```R
subset2_q <- function(x, condition) {
  r <- eval(condition_call, x, parent.frame())
  x[r, ]
}
subset2 <- function(x, condition) {
  subset2_q(substitute(x), condition)
}

subscramble <- function(x, condition) {
  condition <- substitute(condition)
  scramble(subset2(x, condition))
}
```

You might wonder why the function couldn't do this automatically:

```R
subset <- function(x, condition) {
  if (!is.call(condition)) {
    condition <- substitute(condition)
  }
  r <- eval(condition, x)
  x[r, ]
}
subset(mtcars, quote(cyl == 4))
subset(mtcars, cyl == 4)
```

But hopefully a little thought, or maybe some experimentation, will show why this doesn't work.

## Substitute

Following examples above, whenever you write your own functions that use non-standard evaluation, you always provide alternatives that others can use. But what happens if you want to call a function that uses non-standard evaluation and doesn't have a standard form? For example, imagine you want to create a lattice graphic given the names of two variables:

```R
library(lattice)
xyplot(mpg ~ displ, data = mtcars)

x <- quote(mpg)
y <- quote(displ)
xyplot(x ~ y, data = mtcars)
```

Again, we can turn to substitute and use it for its second purpose:  modifying expressions.  So far we've just used `substitute()` to capture the unevaluated expression associated with arguments. But it can actually do much much more, and is a very useful for manipulating expressions in general.

Unfortunately `substitute()` has a "feature" that makes experimenting with it interactively a bit of a pain: it never does substitutions when run from the global environment, and just behaves like `quote()`:

```R
a <- 1
b <- 2
substitute(a + b + x)
```

But if we run it inside a function, `substitute()` substitutes what it can and leaves everything else the same:

```R
f <- function() { 
  a <- 1
  b <- 2
  substitute(a + b + x)
}
f()
```

To make things easier, `pryr()` provides the `subs()` function.  It works exactly the same way as `substitute()` except it has a shorter name and if the second argument is the global environment it turns it into a list. Together, this makes it much easier to experiement with substitution:

```R
subs(a + b + x)
```

The second argument (to both `sub()` and `substitute()`) can override the use of the current environment, and provide an alternative list of name-value pairs to substitute in. The following example uses that technique to show some variations on substituting a string, variable name or function call:

```R
subs(a + b, list(a = "y"))
subs(a + b, list(a = quote(y)))
subs(a + b, list(a = quote(y())))
```

Note that it's quite possible to make nonsense commands with `substitute`:

```R
subs(y <- y + 1, list(y = 1))
```

And you can use substitute to insert any arbitrary object into an expression. This is technically ok, but often results in surprisingly and undesirable behaviour:

```R
df <- data.frame(x = 1)
(x <- subs(class(df)))
eval(x)
```

`substitute()` has two arguments: `expr`, an R expression captured with non-standard evaluation; and `env`, an environment used to modify `expr`.  The second argument is also useful if you want to control exactly what gets modified in the original call.

Formally, substitution takes place by examining each name in the expression, and replacing the name if it refers to:

* a promise, it's replaced by the expression associated with the promise. 
 
* an ordinary variable, it's replaced by the value of the variable.

* `...`, it's replaced by the contents of `...` (only if the substitution occurs in a function)

Otherwise the name is left as is. 

Note that `substitute` doesn't evaluate its first argument:

```R
x <- quote(a + b)
substitute(x, list(a = 1, b = 2))
```

But `pryr::substitute2` does:

```R
x <- quote(a + b)
substitute2(x, list(a = 1, b = 2))
```

Have a go at reading the source code to `substitute2()`. If you can figure out how it works, you're well on the way to becoming a computing-on-the language expert! Notice that we use the second argument to substitute twice: in the outer call to ensure that we only substitute `x`, not `env`; and in the inner call to make sure substitution happens using the variables in the user specified environment.

As a general principle, whenever you write a function that uses non-standard evaluation, you always also want to provide a version that uses standard evaluation, and expects the user to provide quoted inputs. Otherwise, they'll have to resort to `substitute()` tricks, like above. (`substitute()` is an exception to this, because there must be a built in base function that doesn't evaluate it's arguments otherwise we could never capture the first)



## When not to use substitute

There are a number of base functions that use `substitute()` to capture the expression you've typed instead of just the value.  These include `data.frame()` and `library()`.

For example, `data.frame()` uses the input expressions to automatically name the output variables if not otherwise provided:

```R
x <- 10
y <- "a"
df <- data.frame(x, y)
names(df)
```


When writing functions like this, I find it helpful to do the evaluation last, only after I've made sure that I've constructed the correct substitute call with a few test inputs. If you split the two pieces (call construction and evaluation) into two functions, it's also much easier to test more formally.

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

Generally, providing an argument that changes how other arguments are interpreted is a bad idea because it means you must completely and carefully read all of the function arguments to understand what one function argument means. Since you can't understand the effect of an argument in isolation, it's much harder to read the function and reason about it.

There are a lot of other R functions that use `substitute()` and `deparse()` so the you doesn't need to quote the input: `ls()`, `library()`, `require()`, `rm()`, `data()`, `demo()`, `example()`, `vignette()`. 

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

