# Controlling evaluation

In this document, we're going to write our own (slightly) simplified version of subset, and along the way, learn how we can capture and control evaluation in R. You might already be familiar with the `subset` function. If not sure, it's a useful interactive shortcut for subsetting data frames: instead of repeating the data frame you're working with again and again, you can save some typing:

    subset(mtcars, vs == am)
    # equivalent to:
    mtcars[mtcars$vs == mtcars$am, ]
    
    subset(mtcars, cyl == 4)
    # equivalent to:
    mtcars[mtcars$cyl == 4, ]

Subset is special because `vs == am` or `cyl == 4` aren't evaluated in the global environment (your usual workspace), they're evaluated in the context of the data frame. In other words, subset implements different [[scoping|Scoping]] rules so instead of looking for those variables in the current environment, subset looks in the specified data frame. (If you're unfamiliar with R's scoping rules, I'd suggest you read up on them before you continue.)

To do this, `subset` must be able to capture the meaning of your condition string without evaluating it. The next section describes how to do that.

## Quoting 

To talk about quoting, capturing a language object without evaluating it, we need some new vocabulary:

* a __symbol__, or __name__, describes the name of an object, like x or y, not it's value like `5` or `"a"`  (see `is.symbol` & `as.symbol`).
* a __call__ is an unevaluated expression, like `x == y`, rather than the result of that call (see `is.call` & `as.call`).
* an __expression__ is a list of calls and/or symbols (see `is.expression` & `as.expression`).
* a __language object__ is a name, call, or expression (`is.language`).

The most direct way quote a call is (surprise!) with `quote`:

    quote(vs == am)
    # vs == am

We could also build a call manually, using `call`:

    call("==", as.name("vs"), as.name("am"))
    # vs == am
    # We need to use as.name because we want to refer to the variables called
    # vs and am, not the strings "vs" and "am"
    call("==", "vs", "am")

Or we could create it from a string, with `parse`:

    parse(text = "vs == am")[[1]]
    # vs == am
    # Parse returns an expression, but we just want the first element, a call

The simplest way to write `subset` would be to require that the user supply a call created using one of the above techniques. But that requires extra typing, just what we were trying to avoid. We want capture the call inside the function, not outside of it. Think about why `quote` won't work, and then run the following code to check if your guess was correct:

    subset <- function(x, condition) {
      quote(condition)
    }
    subset(mtcars, cyl == 4)

We need a new approach. One way is to capture the ensure function call and then extract then the piece that corresponds to `condition`. This is what the `match.call` function lets us do:

    subset <- function(x, condition) {
      match.call()
    }
    subset(mtcars, vs == am)
    # subset(x = mtcars, condition = vs == am)
    
    subset <- function(x, condition) {
      match.call()$condition
    }
    subset(mtcars, vs == am)
    # subset(x = mtcars, condition = vs == am)

Another function that can capture the original call is `substitute`:

    subset <- function(x, condition) {
      substitute(condition)
    }    
    subset(mtcars, vs == am)

Substitute is the tool most commonly used for this task, but it's the hardest to explain because it relies on lazy evaluation. In R, function arguments are only evaluated when they are needed, not automatically when the function is called. Before the argument is evaluated (aka forced), it is stored as a __promise__. A promise stores two things: the call that should be evaluated and the environment in which to evaluate it. When substitute is passed a promise, it extracts the call, which is the thing we're looking for.

Once we have the call, we need to evaluate it in the way we want, as described next.

## Evaluation

Now we've have the call that represents the subset condition we want, we want to evaluate it in the right context, so that `cyl` is interpreted as `mtcars$cyl`.  To do this we need the `eval` function:

    eval(quote(cyl), mtcars)
    #  [1] 6 6 4 6 8 6 8 4 4 6 6 8 8 ...

    eval(quote(cyl1), mtcars)
    # Error in eval(expr, envir, enclos) : object 'cyl1' not found

    eval(cyl, mtcars)
    # Error in eval(cyk, mtcars) : object 'cyl' not found
    cyl <- quote(cyl)
    eval(cy, mtcars)
    #  [1] 6 6 4 6 8 6 8 4 4 6 6 8 8 ...

The first argument to `eval` is the language object to evaluate, and the second argument is the environment to use for evaluation.  If the second argument is a list or data frame, `eval` will convert it to a environment for you. (There are a number of short cut functions: `evalq`, `eval.parent`, and `local` that are also documented with `eval` - I won't use or explain these here, I'd recommend you read about them and figure out what they do.)

Now we have all the pieces we need to write the `subset` function: we can capture the call representing condition then evaluate it in the context of the data frame:

    subset <- function(x, condition) {
      condition_call <- substitute(condition)
      r <- eval(condition_call, x)
      x[r, ]
    }
    
    subset(mtcars, cyl == 4)

Unfortunately, we're not quite done because this function doesn't work as we always expect.

## Scoping issues

What do you expect the following to do:

    x <- 4
    subset(mtcars, cyl == x)

It should be the same as `subset(mtcars, cyl == 4)`, right? But how exactly does this work and where does subset look for the value of `x`? It's not going to be the right value inside the subset function because the first argument of `subset` is called `x`. Inside the subset function `x` will have the same value of `mtcars`.

The key is the third argument of `eval`: `enclos`. This allows us to specify the parent (or enclosing) environment for objects that don't have one like lists and data frames (`enclos` is ignored if we pass in a real environment). The `enclos`ing environment is where any objects that aren't found in the data frame will be looked for. By default it uses the current environment, which is not what we want.

We want to look for `x` in the environment in which `subset` was called. In R terminology this is called the __parent frame__ and is accessed with `parent.frame()`. This is an example of [dynamic scope](http://en.wikipedia.org/wiki/Scope_(programming)#Dynamic_scoping). With this modification our function works:

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
      subset(mtcars, cyl == 6)
    }
    f()

And it works :)

There is one other approach we could use: a formula. `~` works much like quote, but it also captures the environment in which it is created. We need to extract the second component of the formula because the first component is `~`.

    subset <- function(x, f) {
      r <- eval(f[[2]], x, environment(f))
      x[r, ]
    }
    subset(mtcars, ~ cyl == x)

## Calling from another function

While `subset` saves typing, it has one big disadvantage: it's now difficult to use non-interactively, e.g. from another function.

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

<!-- We can use this idea to crudely identify R functions that may be problematic to program with:
  
    library(parser)
    funs <- function(x) {
      if (!is.function(x)) return()
      parsed <- attr(parser(x), "data")
      subset(parsed, token.desc == "SYMBOL_FUNCTION_CALL")$text
    }
    is.interactive <- function(x) {
      any(c("substitute", "match.call") %in% funs(get(x)))
    }
    
    fs <- ls("package:base")
    fs[sapply(fs, is.interactive)] -->

## Conclusion

Now you understand how our version of subset works, go back and read the source code for `subset.data.frame`, the base R version which does a little more. Other functions that work similarly are `with.default`, `within.data.frame`, `transform.data.frame`, and in the plyr package `.`, `arrange`, and `summarise`. Look at the source code for these functions and see if you can figure out how they work.

<!-- # Appendix A: symbols, calls, expressions

    as.symbol("a")
    as.symbol("a b c")


    substitute(x, list(x = quote(2 + 2)))
    # 2 + 2
    substitute(x, list(x = expression(2 + 2)))
    # expression(2 + 2)

    # From R language definition
    eval(substitute(mode(x), list(x = quote(2 + 2))))
    # "numeric"
    eval(substitute(mode(x), list(x = expression(2 + 2))))
    # "expression" -->