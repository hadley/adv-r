# Function operators

In this chapter, you'll learn about function operators: functions that take (at least) one function as input and return a function as output. Function operators are a FP technique related to functionals, but where functionals abstract away common uses of loops, function operators instead abstract over common uses of anonymous functions. Function operators allow you to add extra functionality to a function, modify how it works, or combine multiple functions to make new tools. 

Here's an example of a simple function operator that makes a function chatty, showing its input and output (albeit in a very naive way). It's useful because it gives a window into functionals, and we can use it to see how `lapply()` and `mclapply()` execute code differently. (We'll explore this theme in more detail below with the fully-featured `tee` function below)

```R
chatty <- function(f) {
  function(x) {
    res <- f(x)
    cat(format(x), " -> ", format(res, digits = 3), "\n", sep = "")
    res
  }
}
s <- c(0.4, 0.3, 0.2, 0.1)
x2 <- lapply(s, chatty(Sys.sleep))
x2 <- mclapply(s, chatty(Sys.sleep))
```

Like functionals, there's nothing you can't do without functional operators; but they can make your code more readable, more expressive and faster to write. Function operators make it possible to eliminate parameters to functionals by encapsulating common variations. This means that your code becomes more extensible: your users are not limited to functionality that you've thought up - as long as the keep the inputs and outputs of the function the same, they can extend it in ways you've never dreamed of. 

In the last chapter, we saw that most built-in functionals in R have very few arguments (some have only one!), and we used anonymous functions to modify how they worked. In this chapter, we'll start to build up tools that replace standard anonymous functions with specialised equivalents that allow us to communicate our intent more clearly. For example, in the last chapter we saw how to use `Map` with fixed arguments:

```R
Map(function(x, y) f(x, y, zs), xs, ys)
```

Later in this chapter, we'll learn about partial application, and the `partial()` function that implements it. Partial application allows us modify our original function directly, leading to the following code that is both more succint and more clear, once you learn what `partial()` does.

```R
Map(partial(f, zs = zs), xs, yz)
```

In this chapter, we'll explore four classes of function operators (FOs). Function operators can:

* __add behaviour__, leaving the function otherwise unchanged, like automatically logging when the function is run, ensuring a function is run only once, or delaying the operation of a function.

* __change output__, for example, to return a value if the function throws an error, or to negate the result of a logical predictate

* __change input__, like partially evaluating the function, converting a function that takes multiple arguments to a function that takes a list, or automatically vectorising a functional.

* __combine functions__, for example, combining the results of predicate functions with boolean operators, or composing multiple function calls.

For each class, we'll show you useful function operators, and show you how you can use them as alternative means of describing tasks in R: as combinations of multiple functions instead of combinations of arguments to a single function. The goal is not to provide an exhaustive list of every possible functional operator that you could come up with, but to show a selection and demonstrate how well they work together and in concert with functionals. For your own work, you will need to think about and experiment with what function operators help you solve recurring problems. 

The examples in this chapter come from five years of creating function operators in different R packages, and from reading about useful operators in other languages.

### In other languages

Function operators are used extensively in FP languages like haskell, and are common in lisp, scheme and clojure. They are an important part of modern javascript programming, like in the [underscore.js](http://underscorejs.org/) library, and are particularly common in coffescript, since the syntax for anonymous functions is so concise. Stack based languages like Forth and Factor use function operators almost exclusively, since it is rare to refer to variables by name. Python's decorators are just function operators by a different name, as explained in detail by the answers to this [stackoverflow question](http://stackoverflow.com/questions/739654/). They are very rare in Java, because it's difficult to manipulate functions (although possible if you wrap them up in stategy-type objects, such), and also rare in C++; while it's possible to create objects that work like functions ("functors") by overloading the `()` operator, modifying these objects with other functions is not a common programming technique. C++ 11 adds partial application (`std::bind`) to the standard library.

## Behavioural FOs

The first class of FOs are those that leave the inputs and outputs of a function unchanged, but add some extra behaviour. In this section, we'll see functions that:

* log to disk everytime a function is run
* automatically print how long it took to run
* add a delay to avoid swamping a server with work
* print to console every n invocations (useful if you want to check on a long running process)
* save time by caching previous function results

To make these use cases concrete, imagine we want to download a long vector of urls with `download.file()`. That's pretty simple with `lapply()`:

```R
lapply(urls, download.file, quiet = TRUE)
```

But because it's such a long list we want to print some output so that we know it's working (we'll print a `.` every ten urls), and we also want to avoid hammering the server, so we add a small delay to the function between each call. That leads to a rather more complicated for loop; we can no longer use `lapply()` because we need an external counter.

```R
i <- 1
for(url in urls) {
  i <- i + 1
  if (i %% 10 == 0) cat(".")
  Sys.delay(1)
  download.file(url, quiet = TRUE) 
}
```

Reading this code is quite hard because we are using low-level functions, and it's not obvious (without some thought), what the overall objective is. In the remainder of this chapter we'll create FOs that encapsulate each of the modifications, allowing us to write:

```R
lapply(urls, dot_every(10, delay_by(1, download.file)), quiet = TRUE)
```

### Useful behavioural FOs

Implementing the `delay_by` is straightforward, and follows a template that we're going to see again and again:

```R
delay_by <- function(delay, f) {
  function(...) {
    Sys.sleep(delay)
    f(...)
  }
}
system.time(runif(100))
system.time(delay_by(1, runif)(100))
```

`dot_every` is a little bit more complicated because it needs to modify state in the parent environment using `<<-`.  If you're not sure how this works, you might want to re-read the mutable state section in [[Functional programming]].

```R
dot_every <- function(n, f) {
  i <- 1
  function(...) {
    if (i %% n == 0) cat(".")
    i <<- i + 1
    f(...)
  }
}
x <- lapply(1:1000, runif)
x <- lapply(1:1000, dot_every(10, runif))
```

Notice that I've made the function the last argument to each FO. This make it reads a little better when we compose multiple function operators. If the function was the first argument, then instead of:

```R
download <- dot_every(10, delay_by(1, download.file))
```

we'd have

```R
download <- dot_every(delay_by(download.file, 1), 10)
```

which I think is a little harder to follow because the argument to `dot_every()` is far away from the function call.  That's sometimes called the [Dagwood sandwhich](http://en.wikipedia.org/wiki/Dagwood_sandwich) problem: you have too much filling (too many long arguments) between your slices of bread (parentheses).  I've also tried to give my FOs names that you can read easily: delay by 1 (second), (print a) dot every 10 (invocations).

Two other tasks that FOs can help solve are:

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

### Memoisation

Another thing you might worry about when downloading multiple file is accidentally downloading the same file multiple times: that's a waste of time. You could work around it by calling `unique` on the list of input urls, or manually managing a data structure that mapped the url to the result. An alternative approach is to use memoisation: a way of modifying a function to automatically cache its results.

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

Memoisation is an example of a classic tradeoff in computer science: trading space for speed. A memoised function uses a lot more memory (because it stores all of the previous inputs and outputs), but is much much faster.

A somewhat more realistic use case is implementing the Fibonacci series (a topic we'll come back to [[software systems]]). The Fibonacci series is defined recursively: the first two values are 1 and 1, then f(n) = f(n - 1) + f(n - 2).  A naive version implemented in R is very slow because (e.g.) `fib(10)` computes `fib(9)` and `fib(8)`, and `fib(9)` computes `fib(8)` and `fib(7)`, and so on, so that the value for each location gets computed many many times.  Memoising `fib()` makes the implementation much faster because each value is only computed once, and then remembered.

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

This gives a function that we can easily use with `lapply()`. If something goes wrong with the loop inside `lapply()`, it can be difficult to tell what's going on; the next section shows how we can use FOs to open the curtain and look inside.

### Capturing function invocations

One challenge with functionals is that it can hard to be see what's going on - it's not easy to pry open the internals like it is with a for loop. However, we can build a function operators to help us.  The `tee` function, defined below, has three arguments, all functions: `f`, the original function; `on_input`, a function that's called with the inputs to `f`, and `on_output` a function that's called with the output from `f`.

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

(The name is inspired by the `tee` shell command which is used to split streams of file operations up so that you can see what's happening or save intermediate results to a file - it's named after the `t` pipe in plumbing)

We can use `tee` to look into how `uniroot` finds where `x` and `cos(x)` intersect:

```R
f <- function(x) cos(x) - x
uniroot(f, c(-5, 5))

uniroot(tee(f, on_output = print), c(-5, 5))
uniroot(tee(f, on_input = print), c(-5, 5))
```

Using print allows us to see what's happening at the time, but doesn't give us any ability to work with the values. Instead we might want to capture the sequence of the calls. To do that we create a function called `remember()` that remembers every argument it was called with, and retrieves them when coerced into a list. (The small amount of S3 magic that makes this possible is explained in the [[S3]] chapter).

```R
remember <- function() {
  memory <- list()
  f <- function(...) {
    # This is inefficient!
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

Now we can see exactly how uniroot zeros in on the final answer:

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

* Why is the `remember()` function inefficient? How could you implement it in more efficient way?

## Output FOs

The next step up in complexity is to modify the output of a function. This could be quite simple, or it could fundamentally change the operation of the function, returning something completely different to its usual output. In this section you'll learn about two simple modifications, `Negate` and `failwith`, and two fundamental modifications, `capture_it` and `time_it`.

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

`plyr::failwith()` turns a function that throws an error with incorrect input into a function that returns a default value when there's an error. Again, the essence of `failwith()` is simple, just a wrapper around `try()` (if you haven't seen `try()` before, it's discussed in more detail in the [[exceptions and debugging|Exceptions-debugging]] chapter):

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

`failwith()` is very useful in conjunction with functionals: instead of the failure propagating and terminating the higher-level loop, you can complete the iteration and then find out what went wrong.  For example, imagine you're fitting a set of generalised linear models (glms) to a list of data frames. Sometimes glms fail because of optimisation problems. You still want to try to fit all the models, then once that's complete, look at the data sets that failed to fit:

```R
# If any model fails, all models fail to fit:
models <- lapply(datasets, glm, formula = y ~ x1 + x2 * x3)
# If a model fails, it will get a NULL value 
models <- lapply(datasets, failwith(NULL, glm), 
  formula = y ~ x1 + x2 * x3)

ok_models <- compact(models)
failed_data <- datasets[where(models, is.null)]
```

I think this is a great example of the power of combining functionals and function operators: it makes it easy to succinctly express what you need to solve for a common data analysis problem.

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

In this case, there's not a huge benefit to the functional operator style, because the composition is simple, and we're applying the same operator to each function. Generally, using function operators are more useful when you are using multiple operators or if the gap between creating them and using them is large.

### Exercises

* Create a `negative` function that flips the sign of the output from the function it's applied to.

* The `evaluate` package makes it easy to capture all the outputs (results, text, messages, warnings, errors and plots) from an expression. Create a function like `capture_it()` that returns all the warnings and errors generated by a function.

* Modify the final example to use `fapply()` from the [[functionals]] chapter instead of `lapply()`.

## Input FOs

Somewhat more complicated than modifying the outputs of a function is modifying the inputs. Again, this can slightly modify how a function works (for example, prefilling some of the arguments), or fundamentally change the inputs (by converting to scalar to vector, or vector to matrix).

### Prefilling function arguments: partial function application

A common task is making a variant of a function that has certain arguments "filled in" already. This is called "partial functiona application", and is implemented by `pryr::partial`. (Once you have read the computing on the language chapter, I encourage you to read the source code for `partial` and puzzle out how it works - it's only 4 lines of code!)

`partial()` allows us to replace code like

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

Partial function application is straightforward in many functional programming languages, but it's not entirely clear how it should interact with R's lazy evaluation rules. The approach of `plyr::partial` is to create a function as similar as possible to the anonymous function you'd create by hand. Peter Meilstrup takes a different approach in his [ptools package](https://github.com/crowding/ptools/); you might want to read about this if you're interested in the topic.

### Changing input types

There are a few existing functions that fundamentally change the input type of a function:

* `base::Vectorise` converts a scalar function to a vector function. `Vectorize` takes a non-vectorised function and vectorises with respect to the arguments given in the `vectorise.args` parameter. This doesn't give you any magical performance improvements, but it is useful if you want a quick and dirty way of making a vectorised function.

    A mildly useful extension of `sample` would be to vectorize it with respect to size: this would allow you to generate multiple samples in one call.

    ```R
    sample2 <- Vectorize(sample, "size", SIMPLIFY = FALSE)
    sample2(1:10, rep(5, 4))
    sample2(1:10, 2:5)
    ```

    In this example we have used `SIMPLIFY = FALSE` to ensure that our newly vectorised function always returns a list. This is usually what you want. 

*  `splat` converts a function that takes multiple arguments to a function that takes a single list of arguments.

    ```R
    splat <- function (f) {
      function(args) {
        do.call(f, args)
      }
    }
    ```

    This is useful if you want to invoke a function with varying arguments:

    ```R
    x <- c(NA, runif(100), 1000)
    args <- list(
      list(x),
      list(x, na.rm = TRUE),
      list(x, na.rm = TRUE, trim = 0.1)
    )
    lapply(args, splat(mean))
    ```

* `plyr::colwise` converts a vector function to one that works with data frames:

    ```R
    library(plyr)
    median(mtcars)
    median(mtcars$mpg)
    colwise(median)(mtcars)
    ```

### Exercises

* Our previous `download()` function will only download a single file. How can you use `partial()` and `lapply()` to create a function that downloads multiple files at once? What are the pros and cons of using `partial()` vs. writing a function by hand.

* Read the source code for `plyr::colwise()`: how does code work?  It performs three main tasks. What are they? And how could you make `colwise` simpler by implementing each separate task as a function operator? (Hint: think about `partial`)

* Write FOs that convert a function to return a matrix instead of a data frame, or a data frame instead of a matrix. (If you already know [[S3]], make these methods of `as.data.frame` and `as.matrix`)

* You've seen five functions that modify a function to change it's output from one form to another. What are they? Draw a table: what should go in the rows and what should go in the columns? What function operators might you want to write to fill in the missing cells? Come up with example use cases.

* Look at all the examples of using an anonymous function to partially apply a function in this chapter. Replace the anonymous function with `partial`. What do you think of the result? Is it easier to read or harder?

## Combining FOs

Instead of operating on single functions, function operators can take multiple functions as input. One simple example of this is `plyr::each()` which takes a list of vectorised functions and returns a single function that applies each in turn to the input:

```R
library(plyr)
summaries <- each(mean, sd, median)
summaries(1:10)
```

Two more complicated examples are combining functions through composition, or through boolean algebra. Because they combine multiple functions they are particularly useful when combined with all the other FOs defined in this chapter.

### Function composition

An important way of combining functions is composition: `f(g(x))`.  Composition takes a list of functions and applies them sequentially to the input. It's a replacement for the common anonymous function pattern where you chain together multiple functions to get the result you want:

```R
sapply(mtcars, function(x) length(unique(x)))
```

A simple version of compose looks like this:

```R
compose <- function(f, g) {
  function(...) f(g(...))
}
```

(`pryr::compose` provides a fuller-featured alternative that can accept multiple functions).

This allows us to write:

```R
sapply(mtcars, compose(length, unique))
```

Mathematically, function composition is often denoted with an infix operator, o, `(f o g)(x)`.  Haskell, a popular functional programming language, uses `.` in a similar manner.  In R, we can create our own infix function that works similarly:

```R
"%.%" <- compose
sapply(mtcars, length %.% unique)

sqrt(1 + 8)
compose(sqrt, "+")(1, 8)
(sqrt %.% `+`)(1, 8)
```

Compose also allows for a very succinct implement of `Negate`: it composes another function with `!`.

```R
Negate <- partial(compose, `!`)
```

We could also implement the standard deviation by breaking it down into a separate set of function compositions:

```R
square <- function(x) x ^ 2
deviation <- function(x) x - mean(x)

sd <- sqrt %.% mean %.% square %.% deviation
sd(1:10)
```

This type of programming is called tacit or point free programming.  (The term point free comes from use the of the word point to refer values in topology; this style is also derogatorily known as pointless). In this style of programming you don't explicitly refer to variables, focussing on the high-level composition of functions, rather than the low level flow of data. Since we're using only functions and not parameters, we use verbs and not nouns, so this style leads to code that focusses on what's being done, not what it's being done to. This style is common in Haskell, and is the typical style in stack based programming languages like Forth and Factor.

`compose()` is particularly useful in conjunction with `partial()`, because `partial()` allows you to supply additional arguments to the functions being composed.  One nice side effect of this style of programming is that it keeps the arguments to each function near the function name. This is important because code gets progressively harder to understand the bigger chunk that you have to hold in your head at a time.

Below I take the example from the first section of the chapter and modify it to use the two styles of function composition defined above. They are both longer than the original code but maybe easier to understand because the function and its arguments are closer together.  Note that we still have to read them from right to left (bottom to top): the first function called is the last one written. We could define `compose()` to work in the opposite direction, but in the long run, this is likely to lead to confusion since we'd create a small part of the langugage that reads differently to every other part.

```R
download <- dot_every(10, memoise(delay_by(1, download.file)))

download <- compose(
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

### Logical predicates and boolean algebra

When we use `Filter()` and other functionals that work with logical predicates, I often find myself using anonymous functions to combine multiple conditions:

```R
Filter(iris, function(x) is.character(x) || is.factor(x))
```

As an alternative, we could define some function operators that combine logical predicates:

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

which would allow us to write:

```R
Filter(iris, or(is.character, is.factor))
```

This allows us to express arbitrarily complicated boolean expressing involving functions in a succinct way.

### Exercises

* Implement your own version of `compose` using `Reduce` and `%.%`. For bonus points, do it without calling `function`.

* Extend `and()` and `or()` to deal with any number of input functions. Can you do it with `Reduce()`? Can you keep them lazy (so e.g. for `and()` the function returns as soon as it sees the first `FALSE`)?

* Implement the `xor()` binary operator. Implement it using the existing `xor()` function. Implement it as a combination of `and()` and `or()`. What are the advantages and disadvantages of each approach? Also think about what you'll call the resulting function, and how you might need to change the names of `and()`, `not()` and `or()` in order to keep them consistent.

* Above, we implemented boolean algebra for functions that return a logical function. Implement elementary algebra (`plus()`, `minus()`, `multiply()`, `divide()`, `exponentiate()`, `root()`) for functions that return numeric vectors. 

## The common pattern and a subtle bug

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

There's a subtle problem with this implementation. It does not work well with `lapply()` because `f` is lazily evaluated.  This means that if you give `lapply()` a list of functions and a FO to apply it to each of them, it will look like it repeatedly applied the FO to the last function:

```R
maybe <- function(f) {
  function(x, ...) {
    if (is.null(x)) return(NULL)
    f(x, ...)
  }
}
fs <- list(sum = sum, mean = mean, min = min)
maybes <- lapply(fs, maybe)
maybes$sum(1:10)
maybes$min(1:10)
```

Another problem is that as designed, we have to pass in a funtion object, not the name of a function, which is often convenient. We can solve both problems by using `match.fun()`: it forces evaluation of `f`, and will find the function object if given its name:

```R
maybe <- function(f) {
  f <- match.fun(f)
  function(x, ...) {
    if (is.null(x)) return(NULL)
    f(x, ...)
  }
}
fs <- c(sum = "sum", mean = "mean", min = "min")
maybes <- lapply(fs, maybe)
maybes$sum(1:10)
```
