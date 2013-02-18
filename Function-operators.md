# Function operators

The final functional programming technique we will discuss is function operators: functions that take (at least) one function as input and return a function as output. Function operators are similar to functionals, but where functionals abstract away common uses of loops, function operators instead abstract over common uses of anonymous functions. Function operators allow you to add extra functionality to existing functions, or combine multiple existing functions to make new tools. 

Here's an example of a simple function operator that makes a function chatty, showing its input and output (albeit in a very naive way). It's useful because it gives a window into functionals, and we can use it to see how `lapply()` and `mclapply()` execute code differently. (We'll explore this theme in more detail below with the fully-featured `tee` function)

```R
show_results <- function(f) {
  function(x) {
    res <- f(x)
    cat(format(x), " -> ", format(res, digits = 3), "\n", sep = "")
    res
  }
}
s <- c(0.4, 0.3, 0.2, 0.1)
x2 <- lapply(s, show_results(Sys.sleep))
x2 <- mclapply(s, show_results(Sys.sleep))
```

Function operators can make it possible to eliminate parameters by encapsulating common variations as function transformations. Like functionals, there's nothing you can't do without them; but they can make your code more readable and expressive. One advantage of using FOs instead of additional arguments is that your functions become more extensible: your users are not limited to functionality that you've thought up - as long as they modify the function in the right way, they can add functionality that you've never dreamed of. This in turn leads to small, simpler functions that are easier to understand and learn. 

In the last chapter, we saw that most built-in functionals in R have very few arguments (some have only one!), and we used anonymous functions to modify how they worked. In this chapter, we'll start to build up tools that replace standard anonymous functions with specialised equivalents that allow us to communicate our intent more clearly. For example, in the last chapter we saw how to use `Map` with some fixed arguments:

```R
Map(function(x, y) f(x, y, zs), xs, ys)
```

Later in this chapter, we'll learn about partial application, and the `partial()` function that implements it. Partial application allows us modify our original function directly, leading to the following code that is both more succint and more clear (assuming your vocabulary includes `partial()`).

```R
Map(partial(f, zs = zs), xs, yz)
```

<!-- If you're familiar with Python, decorates are function operators. : http://stackoverflow.com/questions/739654/understanding-python-decorators
 -->

In this chapter, we'll explore four classes of function operators (FOs). Function operators can:

* __add behaviour__, leaving the function otherwise unchanged, like automatically logging when the function is run, ensuring a function is run only once, or delaying the operation of a function.

* __change output__, for example, to return a value if the function throws an error, or to negate the result of a logical predictate

* __change input__, like partially evaluating the function, converting a function that takes multiple arguments to a function that takes a list, or automatically vectorising a functional.

* __combine functions__, for example, combining the results of predicate functions with boolean operators, or composing multiple function calls.

For each class, we'll show you useful function operators, and show you how you can use them as alternative means of describing tasks in R: as combinations of multiple functions instead of combinations of arguments to a single function. The goal is not to provide an exhaustive list of every possible functional operator that you could come up with, but to show a selection and demonstrate how well they work together and in concert with functionals. You will need to think about and experiment with what function operators help you solve recurring problems with your work. The examples in this chapter come from five years of creating function operators in different packages, and from reading about useful operators in other languages.

At a higher level, function operators allow you to define specialised languages for solving wide classes of problems. The building blocks are simple functions, which you combine together with function operators to solve more complicated problems. The final section of the chapter shows how you can do this to build a language that specifies what arguments to a function should look like.

## Add additional behaviour

The first class of FOs are those that leave the inputs and outputs of a function unchanged, but add some extra behaviour. In this section, we'll see functions that:

* log to disk everytime a function is run
* automatically print how long it took to run
* add a delay to avoid swamping a server
* print to console every n invocations (useful if you want to check on a long running process)
* save time by caching previous function results

To make this concrete, imagine we want to download a long vector of urls with `download.file()`. That's pretty simple with `lapply()`:

```R
lapply(urls, download.file, quiet = TRUE)
```

But because it's such a long list we want to print some output so that we know it's working (we'll print a `.` every ten urls), and we also want to avoid hammering the server, so we add a small delay to the function between each call. That leads to a rather more complicated for loop, since we can no longer use `lapply()` because we need an external counter:

```R
i <- 1
for(url in urls) {
  i <- i + 1
  if (i %% 10 == 0) cat(".")
  Sys.delay(1)
  download.file(url, quiet = TRUE) 
}
```

Reading this code is quite hard because we are using low-level functions, and it's not obvious (without some thought), what we're trying to do. In the remainder of this chapter we'll create FO that encapsulate each of the modifications, allowing us to instead do:

```R
lapply(urls, dot_every(10, delay_by(1, download.file)), quiet = TRUE)
```

### Useful behavioural FOs

Implementing the function are straightforward. `dot_every` is the most complicated because it needs to modify state in the parent environment using `<<-`.

* Delay a function by `delay` seconds before executing:

    ```R
    delay_by <- function(delay, f) {
      function(...) {
        Sys.sleep(delay)
        f(...)
      }
    }
    ```

* Print a dot to the console every `n` invocations of the function:
 
    ```R
    dot_every <- function(n, f) {
      i <- 1
      function(...) {
        if (i %% n == 0) cat(".")
        i <<- i + 1
        f(...)
      }
    }
    ```

* Log a time stamp and message to a file everytime a function is run:

    ```R
    log_to <- function(path, message, f) {
      stopifnot(file.exists(path))

      function(...) {
        cat(Sys.time(), ": ", message, sep = "", file = path, 
          append = TRUE)
        f(...)
      }
    }
    ```

* Ensure that if the first input is `NULL` the output is `NULL` (the name is inspired by Haskell's maybe monad which fills a similar role in Haskell, making it possible for functions to work with a default empty value).

    ```R
    maybe <- function(f) {
      function(x, ...) {
        if (is.null(x)) return(NULL)
        f(x, ...)
      }
    }
    ```

Notice that I've made the function the last argument to each FO, this make it reads a little better when we compose multiple function operators. If the function was the first argument, then instead of:

```R
download <- dot_every(10, delay_by(1, download.file))
```

we'd have

```R
download <- dot_every(delay_by(download.file, 1), 10)
```

which I think is a little harder to follow because the argument to `dot_every()` is far away from the function call.  That's sometimes called the [Dagwood sandwhich](http://en.wikipedia.org/wiki/Dagwood_sandwich) problem: you have too much filling (too many long arguments) between your slices of bread (parentheses).

### Memoisation

Another thing you might worry about when downloading multiple file is downloading the same file multiple times: that's a waste of time. You could work around it by calling `unique` on the list of input urls, or manually managing a data structure that mapped the url to the result. An alternative approach is to use memoisation: a way of modifying a function to automatically cache its results.

```R
library(memoise)
slow_function <- function(x) {
  Sys.sleep(1)
  10
}
system.time(slow_function())
system.time(slow_function())
fast_function <- memoise(slow_function)
system.time(fast_function())
system.time(fast_function())
```

Memoisation is an example of a classic tradeoff in computer science: we are trading space for speed.  A memoised function uses a lot more memory (because it stores all of the previous inputs and outputs), but is much much faster.

A slightly more realistic use case is implementing the Fibonacci series (a topic we'll come back to [[software systems]]).  The Fibonacci series is defined recursively: the first two values are 1 and 1, then f(n) = f(n - 1) + f(n - 2).  A naive version implemented in R is very slow because (e.g.) `fib(10)` computes `fib(9)` and `fib(8)`, and `fib(9)` computes `fib(8)` and `fib(7)`, and so on, so that the value for each location gets computed many many times.  Memoising `fib()` makes the implementation much faster because each value only needs to be computed once.

```R
fib <- function(n) {
  if (n < 2) return(1)
  fib(n - 2) + fib(n - 1)
}
system.time(fib(23))
system.time(fib(24))

fib2 <- memoise(function(n) {
  if (n < 2) return(1)
  fib2(n - 2) + fib2(n - 1)
})
system.time(fib2(23))
system.time(fib2(24))
```

It doesn't make sense to memoise all functions. The example below shows that a memoised random number generator is no longer random:

```R
runifm <- memoise(runif)
runif(10)
runif(10)
```

Once we understand `memoise()`, it's straightforward to apply it to our modified `download.file()`:

```R
download <- dot_every(10, memoise(delay_by(1, download.file)))
```

### Capturing function invocations

One challenge with functionals is that it can hard to be see what's going on - it's not easy to pry open the internals like it is with a for loop.  However, we can build a function operators to help us.  The `tee` function below has three arguments, all functions: `f`, the original function; `on_input`, a function that's called with the inputs to `f`, and `on_output` a function that's called with the output from `f`.

(The name is inspired by the tee shell command which is used to split streams of file operations up so that you can see what's happening or save intermediate results to a file - it's named after the `t` pipe in plumbing)

```R
ignore <- function(...) NULL
tee <- function(f, on_input = ignore, on_output = ignore) {
  function(...) {
    on_input(list(...))
    res <- f(...)
    on_output(res)
    res
  }
}
```

We can use `tee` to look into how `uniroot` finds where `x` and `cos(x)` intersect:

```R
f <- function(x) cos(x) - x
uniroot(f, c(-5, 5))

uniroot(tee(f, on_output = print), c(-5, 5))
uniroot(tee(f, on_input = print), c(-5, 5))
```

But that just prints out the results as they happen, which is not terribly useful. Instead we might want to capture the sequence of the calls. To do that we create a function called `remember()` that remembers every argument it was called with, and retrieves them when coerced into a list. (The small amount of S3 magic that makes this possible is explained in the [[S3]] chapter).

```R
remember <- function() {
  memory <- list()
  f <- function(...) {
    # Should use doubling strategy for efficiency
    memory <<- append(memory, list(...))
    invisible()
  }
  
  structure(f, class = "remember")
}
as.list.remember <- function(x, ...) {
  environment(x)$memory
}
print.remember <- function(x, ...) {
  cat("Remembering...\n")
  str(as.list(x))
}
```

Now we can see exactly what uniroot does:

```R
locs <- remember()
vals <- remember()
uniroot(tee(f, locs, vals), c(-5, 5))
x <- sapply(locs, "[[", 1)
y <- sapply(vals, "[[", 1)
plot(x, type = "b"); abline(h = 0.739, col = "grey50")
plot(y, type = "b"); abline(h = 0, col = "grey50")
```

### Exercises

* What does the following function do? What would be a good name for it?

  ```R
  f <- function(g) {
    result <- NULL
    function(...) {
      if (is.null(result)) {
        result <<- g(...)
      }
      result
    }
  }
  runif2 <- f(runif)
  runif2(10)
  ```

* Modify `delay_by` so that instead of delaying by a fixed amount of time, it ensures that a certain amount of time has elapsed since the function was last called. That is, if you called `g <- delay_by(1, f); g(); Sys.sleep(2); g()` there shouldn't be an extra delay.

* There are three places we could have added a memoise call: why did we choose the one we did?

  ```R
  download <- memoise(dot_every(10, delay_by(1, download.file)))
  download <- dot_every(10, memoise(delay_by(1, download.file)))
  download <- dot_every(10, delay_by(1, memoise(download.file)))
  ```

## Output modifications

The next step up in complexity is to modify the output of a function. This could be quite simple, modifying the output of a function in a deterministic way, or it could fundamentally change the operation of the function, returning something completely different to its usual output.

### Minor modifications

`base::Negate` and `plyr::failwith` offer two minor, but useful modifications of a function that are particularly handy in conjunction with functionals.

`Negate` takes a function that returns a logical vector (a predicate function), and returns the negation of that function. This can be a useful shortcut when the function you have returns the opposite of what you need.  Its essence is very simple:

```R
Negate <- function(f) {
  function(...) !f(...)
}

(Negate(is.null))(NULL)
```

One function I find handy based on this is `compact`: it removes all non-null elements from a list:

```R
compact <- function(x) Filter(Negate(is.null), x)
```

`plyr::failwith()` turns a function that throws an error with incorrect input into a function that returns a default value when there's an error.  Again, the essence of `failwith()` is simple, just a wrapper around `try()` (if you're not familiar with `try()` it's discussed in more detail in the [[exceptions and debugging|Exceptions-debugging]] chapter):

```R
failwith <- function(default = NULL, f, quiet = FALSE) {
  function(...) {
    out <- default
    try(out <- f(...), silent = quiet)
    out
  }
}
log("a")
failwith(NA, log)("a")
failwith(NA, log, quiet = TRUE)("a")
```

`failwith()` is very useful in conjunction with functionals: instead of the failure propagating and terminating the higher-level loop, you can complete the iteration and then find out what went wrong.  For example, imagine your fitting a set of generalised linear models to a list of data frames. Sometimes glms fail because of optimisation problems. You still want to try to fit all the models, and then after that's complete, look at the data sets that failed to fit:

```R
# If any model fails, all models fail to fit:
models <- lapply(datasets, glm, formula = y ~ x1 + x2 * x3)
# If a model fails, it will get a NULL value 
models <- lapply(datasets, failwith(NULL, glm), 
  formula = y ~ x1 + x2 * x3)

ok_models <- compact(models)
failed_data <- datasets[where(models, is.null)]
```

I think this is a great example of the power of combining functionals and function operators: it makes it easy to succinctly express what you want for a very common data analysis problem.

### Changing what a function does

Other output function operators can have a more profound affect on the operation of the function. Instead of returning the original return value, we can return some other effect of the function evaluation. Here's two examples:

* Return text that the function `print()`ed:

    ```R
    capture_it <- function(f) {
      function(...) {
        capture.output(f(...))
      }
    }
    str_out <- capture_it(str)
    str(1:10)
    str_out(1:10)
    ```

* Return how long a function took to run:
  
  ```R
  time_it <- function(f) {
    function(...) {
      system.time(f(...))
    }
  }
  ```

`time_it()` allows us to rewrite some of the code from the functionals chapter:

```
compute_mean <- list(
  base = function(x) mean(x),
  sum = function(x) sum(x) / length(x)
)
x <- runif(1e6)

# Instead of using an anonymous function to time
lapply(compute_mean, function(f) system.time(f(x)))

# We can compose function operators
lapply(compute_mean, time_it(call_fun), x)
```

In this case, there's not a huge benefit to the functional operator style, because the composition is simple, and we're applying the same operator to each function. Generally, using function operators are more useful when you are using multiple operators and the gap between creating them and using them is large.

### Exercises

* Create a `negative` function that flips the sign of the output from the function it's applied to.

* The `evaluate` package makes it easy to capture all the outputs (results, text, messages, warnings, errors and plots) from an expression.

* In the final example, use `fapply()` instead of `lapply()`.

## Input modification

Somewhat more complicated than modifying the outputs of a function is modifying the inputs, again this can slightly modify how a function works (for example, prefilling some of the arguments), or fundamental change the inputs.

### Prefilling function arguments: partial function application

A common task is making a variant of a function that has certain arguments "filled in" already. This is called "partial functiona application", and is implemented by `pryr::partial`. (As usual once you have read the computing on the language chapter, I encourage you to read the source code for `partial` and puzzle out how it works - it's only 4 lines of code, but it's somewhat subtle)

It allows us to replace

```R
f <- function(a) g(a, b = 1)
compact <- function(x) Filter(Negate(is.null), x)
Map(function(x, y) f(x, y, zs), xs, ys)
```

with

```
f <- partial(g, b = 1)
compact <- curry(Filter, Negate(is.null))
Map(Curry(f, zs = zs), xs, ys)
```

It is a useful replacement for `...` if you have multiple functions which might need additional arguments.

If you're interested in this idea, you might want to look at the alternative approach in https://github.com/crowding/ptools/blob/master/R/dots.R.

### Changing input types

There are a few existing functions that fundamentally change the input type of a function:

* `base::Vectorise` converts a scalar function to a vector function. `Vectorize` takes a non-vectorised function and vectorises with respect to the arguments given in the `vectorise.args` parameter. This doesn't give you any magical performance improvements, but it is useful if you want a quick and dirty way of making a vectorised function.

    An mildly useful extension of `sample` would be to vectorize it with respect to size: this would allow you to generate multiple samples in one call.

    ```R
    sample2 <- Vectorize(sample, "size", SIMPLIFY = FALSE)
    sample2(1:10, rep(5, 4))
    sample2(1:10, 2:5)
    ```

    In this example we have used `SIMPLIFY = FALSE` to ensure that our newly vectorised function always returns a list. This is usually a good idea. 


*  `plyr::splat` converts a function that takes multiple arguments to a function that takes a single list of arguments

    ```R
    splat <- function (f) {
      function(args) {
        do.call(f, args)
      }
    }
    unsplat <- function(f) {
      function(...) {
        f(list(...))
      }
    }
    ```

* `plyr::colwise` converts a vector function to one that works with data frames.

### Exercises

* Read the source code for `plyr::colwise()`: how does code work?  It performs three main tasks. What are they? And how could you make `colwise` simpler by implementing each separate task as a function operator? (Hint: think about `partial`)

* Look at all the examples of using an anonymous function to partially apply a function. Replace the anonymous function with `partial`. What do you think of the result?

## Combine multiple functions

Instead of operating on single functions, function operators can also take multiple functions as input. 

A simple version of compose looks like this:

```R
compose <- function(f, g) {
  function(...) f(g(...))
}
```

(`pryr::compose` provides a fuller-featured alternative that can accept multiple functions).

Mathematically, function composition is often denoted with an infix operator, o.  Haskell, a popular functional programming language, uses `.` in a similar manner.  In R, we can create our own infix function that works similarly:

```R
"%.%" <- compose
```

This, for example, allows us to natural express the standard deviation as the root mean squared deviation.

```R
square <- function(x) x ^ 2
deviation <- function(x, y) x - mean(x)

sd <- sqrt %.% mean %.% square %.% deviation
sd(1:10)
```

`compose` is particularly useful in conjunction with `partial` because there is no other way to supply additional arguments to the functions being composed.

One nice feature of `compose` + `partial` is that it keeps the arguments to each function near the function name. This is important because code gets progressively harder to understand the bigger chunk that you have to hold in your head at a time. If you can understand a line in isolation it's easy.

```R
download <- dot_every(10, memoise(delay_by(1, download.file)))download <- compose(
  partial(dot_every, 10),
  memoise, 
  partial(delay_by, 1), 
  download.file
)

download <- partial(dot_every, 10) %.% 
  memoise %.% 
  partial(delay_by, 1) %.% 
  download.file
```

This type of programming is called point-free (sometimes derogatorily known as pointless) because it you don't explicitly refer to variables (which are called points in some areas of computer science.)  Another way of looking at it is that because we're using only functions and not parameters we use verbs and not nouns, so code in this style tends to focus on what's being done, not what it's being done to.

* combine the results of two vectorised functions into a matrix (`plyr::each`) 
* combining logical predicates with boolean operators (the topic of the following section)

Rather than exploring these ideas in much depth here, we'll explore them in the following chapter which uses them to build 

### Exercises

* Implement your own version of `compose` using `Reduce` and `%.%`. For bonus points, do it without calling `function`.

## Common patterns

Most function operators follow a similar pattern:

```R
funop <- function(f, otherargs) {
  function(...) {
    # maybe do something
    res <- f(...)
    # maybe do something else
    res
  }
}
```

There's a subtle problem in the implementation of function operators as shown in this chapter (although the actual source code fixes this).  They do not work well with `lapply` because they lazily evaluate f, so if you're using them with a list of functions, they will all use the same (the last) function.

### Anonymous functions vs. computing on the language

The disadvantage of this technique is that when you print the function you won't get informative arguments.  One way around this is to write a function that replaces `...` with the concrete arguments from a specified function by [[computing on the language]].

```R
undot <- function(closure, f) {
  # Can't find out arguments to primitive function, so give up.
  if (is.primitive(f)) return(closure)

  body(closure) <- replace_dots(body(closure), formals(f))
  formals(closure) <- formals(f)

  closure
}

replace_dots <- function(expr, replacement) {
  if (!is.recursive(x)) return(x)
  if (!is.call(x)) {
    stop("Unknown language class: ", paste(class(x), collapse = "/"),
      call. = FALSE)
  }

  pieces <- lapply(y, modify_lang, replacement = replacement)
  as.call(pieces)
}
```

### `match.fun`

It's often useful to be able to pass in either the name of a function, or a function. `match.fun()`.  Also useful because it forces the evaluation of the argument: this is good because it raises an error right away (not later when the function is called), and makes it possible to use with `lapply`.

Caveat: http://stackoverflow.com/questions/14183766

Also need the opposite: to get the name of the function.  There are two basic cases: the user has supplied the name of the function, or they've supplied the function itself.  We cover this in more detail on computing in the language. But unfortunately it's difficult to 

```R
fname <- function(call) {
  f <- eval(call, parent.frame())
  if (is.character(f)) {
    fname <- f
    f <- match.fun(f)
  } else if (is.function(f)) {
    fname <- if (is.symbol(call)) as.character(call) else "<anonymous>"
  }
  list(f, fname)
}
f <- function(f) {
  fname(substitute(f))
}
f("mean")
f(mean)
f(function(x) mean(x))
```


### Function composition

```R
"%.%" <- compose <- function(f, g) {
  f <- match.fun(f)
  g <- match.fun(g)
  function(...) f(g(...))
}
compose(sqrt, "+")(1, 8)
(sqrt %.% `+`)(1, 8)
```

Then we could implement `Negate` as

```R
Negate <- partial(compose, `!`)
```

### Exercises

* What does the following function do? What would be a good name for it?

  ```R
  g <- function(f1, f2) {
    function(...) f1(...) || f2(...)
  } 
  Filter(g(is.character, is.factor), mtcars)
  ```

  Can you extend the function to take any number of functions as input? You'll probably need a loop.

* Write a function `and` that takes two function as input and returns a single function as an output that ands together the results of the two functions. Write a function `or` that combines the results with `or`.  Add a `not` function and you now have a complete set of boolean operators for predicate functions.

## Case study: checking function inputs and boolean algebra

We will explore function operators in the context of avoiding a common R programming problem: supplying the wrong type of input to a function.  We want to develop a flexible way of specifying what a function needs, using a minimum amount of typing. To do that we'll define some simple building blocks and tools to combine them. Finally, we'll see how we can use S3 methods for operators (like `+`, `|`, etc.) to make the description even less invasive.

The goal is to be able to succinctly express conditions about function inputs to make functions safer without imposing additional constraints.  Of course it's possible to do that already using `stopifnot()`:

```R
f <- function(x, y) {
  stopifnot(length(x) == 1 && is.character(x))
  stopifnot(is.null(y) || 
    (is.data.frame(y) && ncol(y) > 0 && nrow(y) > 0))
}
```

What we want to be able to express the same idea more evocatively.

```R
f <- function(x, y) {
  assert(x, and(eq(length, 1), is.character))
  assert(y, or(is.null, 
    and(is.data.frame, and(gt(nrow, 0), gt(ncol, 0)))))
}
f <- function(x, y) {
  assert(x, length %==% 1 %&% is.character)
  assert(y, is.null %|% 
    (is.data.frame %&% (nrow %>% 0) %&% (ncol %>% 0)))
}
f <- function(x, y) {
  assert(x, (length) == 1 && (is.character))
  assert(y, (is.null) || ((is.data.frame) & !empty))
}

is.string <- (length) == 0 && (is.character)
f <- function(x, y) {
  assert(x, (is.string))
  assert(y, (is.null) || ((is.data.frame) & !(empty)))
}
```

We'll start by implementation the `assert()` function. It should take two arguments, an object and a function.

```
assert <- function(x, predicate) {
  if (predicate(x)) return()

  x_str <- deparse(match.call()$x)
  p_str <- strwrap(deparse(match.call()$predicate), exdent = 2)
  stop(x_str, " does not satisfy condition:\n", p_str, call. = FALSE)
}
x <- 1:10
assert(x, is.numeric)
assert(x, is.character)
```


```R
and <- function(f1, f2) {
  function(...) {
    f1(...) && f2(...)
  }
}
or <- function(f1, f2) {
  function(...) {
    f1(...) || f2(...)
  }
}
not <- function(f1) {
  function(...) {
    !f1(...)
  }
}
```

```R
has_length <- function(n) {
  function(x) length(x) == n
}
or(and(is.character, has_length(4)), is.null)
```

It would be cool if we could rewrite to be:

```R
(is.character & has_length(4)) | is.null
```

but due to limitations of S3 it's not possible.  The closest we could get is:

```R
"%|%" <- function(e1, e2) function(...) e1(...) || e2(...)
"%&%" <- function(e1, e2) function(...) e1(...) && e2(...)

(is.character %&% has_length(4)) %|% is.null
```

Another approach would be do something like:

```R
Function <- function(x) structure(x, class = "function")
Ops.function <- function(e1, e2) {
  f <- function(y) {
    if (is.function(e1)) e1 <- e1(y)
    if (is.function(e2)) e2 <- e2(y)
    match.fun(.Generic)(e1, e2)
  }
  Function(f)
}
length <- Function(length)
length > 5
length * length + 3 > 5

is.character <- Function(is.character)
is.numeric <- Function(is.numeric)
is.null <- Function(is.null)

is.null | (is.character & length > 5)
```

If you wanted to make the syntax less invasive (so you didn't have to manually cast `functions` to `Functions`) you could maybe override the parenthesis:

```R
"(" <- function(x) if (is.function(x)) Function(x) else x 
(is.null) | ((is.character) & (length) > 5)
```

If we wanted to eliminate the use of `()` we could extract all variables from the expression, look at the variables that are functions and then wrap them automatically, put them in a new environment and then call in that environment.

### Exercises

* Something with `Negate`

* Extend `and`, `or` and `not` to deal with any number of input functions. Can you keep them lazy?

* Implement a corresponding `xor` function. Why can't you give it the most natural name?  What might you call it instead? Should you rename `and`, `or` and `not` to match your new naming scheme?

* Once you have read the [[S3]] chapter, replace `and`, `or` and `not` with appropriate methods of `&`, `|` and `!`.  Does `xor` work?


