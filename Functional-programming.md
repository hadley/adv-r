# Functional programming

At it's core, R is a functional programming (FP) language which means it focusses on the creation and execution of function. In R, functions can be:

* created anonymously,
* assigned to variables and stored in data structures,
* returned from functions,
* passed as arguments to other functions

Together this set of four properties means that R supports "first class functions": functions are a first class feature of the language in the same way the vectors are. 

This chapter will explore the consequences of R's functional nature and introduce a new set of techniques for removing redundancy and duplication in your code. 

We'll start with a motivating example, showing how you can use functional programming techniques to reduce duplication in some typical code for cleaning data and summarising data. This example will introduce some of the most important functional programming concepts, which we will then dive into in more detail:

* __Anonymous functions__, functions that don't have a name

* __Closures__, functions written by other functions

* __Lists of functions__, storing functions in a list

The chapter conclues with a case study exploring __numerical integration__ showing how we can build a family of composite integration tools starting from very simple primitives. 

The exposition of functional programming continues in the following two chapters: [[functionals]] and [[functional operators]].

## Motivation

Imagine you've loaded a data file that uses -99 to represent missing values. When you first start writing R code, you might write code like this, dealing with duplication by using copy-and-paste:

```R
# Generate a sample dataset
set.seet(1014)
df <- data.frame(replicate(6, sample(c(1:10, -99), 10, rep = T)))
names(df) <- letters[1:6]

# Fix missing values
df$a[df$a == -99] <- NA
df$b[df$b == -99] <- NA
df$c[df$c == -98] <- NA
df$d[df$d == -99] <- NA
df$e[df$e == -99] <- NA
df$f[df$g == -99] <- NA
```

One problem with using copy-and-paste is that it's easy to make mistakes (can you spot the two in the block above?). The root cause is that one idea, that missing values are represent as -99, is duplicated many times. Duplication is bad because it allows for inconsistencies (aka bugs), and it mades the code harder to change: if the the representation of missing value changes from -99 to 9999, then we need to make the change in many places, not just one.

The "do not repeat yourself", or DRY, principle, was popularised by the [pragmatic programmers](http://pragprog.com/about), Dave Thomas and Andy Hunt. This principle states that "every piece of knowledge must have a single, unambiguous, authoritative representation within a system". Adhering to this principle prevents bugs caused by inconsistencies, and makes software that is easier to adapt to changing requirements. The ideas of FP are important because they give us new tools to reduce duplication.

We can start applying some of the ideas of FP to our example by writing a function that fixes the missing values in a single vector:

```R
fix_missing <- function(x) {
  x[x == -99] <- NA
  x
}
df$a <- fix_missing(df$a)
df$b <- fix_missing(df$b)
df$c <- fix_missing(df$c)
df$d <- fix_missing(df$d)
df$e <- fix_missing(df$e)
df$f <- fix_missing(df$e)
```

This reduces the scope for errors, but doesn't eliminate them.  We've still made an error, because we've repeatedly applied our function to each column. To prevent that error from occuring we need to remove the copy-and-paste application of our function to each column. To do this, we need to combine, or __compose__, our function for correcting missing values with a function that does something to each column in a data frame, like `lapply()`.  

`lapply()` takes three inputs: a list, a function, and other arguments to pass to the function. It applies the function to each element of the list and returns the as a new list (since data frames are also lists, `lapply()` also works on data frames). `lapply(x, f, ...)` is equivalent to the following for loop:

```R
out <- vector("list", length(x))
for (i in seq_along(x)) {
  out[[i]] <- f(x[[i]], ...)
}
```

The real `lapply()` is rather more complicated since it's implemented in C for efficiency, but the essence of the algorithm is the same. `lapply()` is a __functional__, because it takes a function as one of its arguments. Functionals are an important part of functional programming and we'll learn more about them in the [[functionals]] chapter.

We can apply `lapply()` to our problem with one small trick: rather than simply assigning the results to `df` we assign them to `df[]`, so R's usual subsetting rules take over and we get a data frame instead of a list.

```R
fix_missing <- function(x) {
  x[x == -99] <- NA
  x
}
df[] <- lapply(df, fix_missing)
```

As well as being more compact, there are two main advantages of this code over our previous code:

* If the representation of missing values changes, we only need to change it in one place, and there is no way for some columns to be treated differently than others.

* Our code works regardless of the number of columns in the data frame, and there is no way to miss a column because of a copy and paste error.

The key idea here is composition. We take two simple functions, one which does something to each column, and one which replaces -99 with NA, and compose them to replace -99 with NA in every column. An important technique for effective FP is writing simple functions than can be understood in isolation and then composed together to solve complex problems.

<!-- Why not add a second argument to fix_missing ?? -->

What if different columns use different indicators for missing values? You again might be tempted to copy-and-paste:

```R
fix_missing_99 <- function(x) {
  x[x == -99] <- NA
  x
}
fix_missing_999 <- function(x) {
  x[x == -999] <- NA
  x
}
fix_missing_9999 <- function(x) {
  x[x == -999] <- NA
  x
}
```

But as previously, it's easy to create bug. The next functional programming tool we'll talk about helps deal with this sort of duplication: we have multiple functions that all follow the same basic template. Closures, functions that return functions, allow us to make many functions from a template:

```R
missing_fixer <- function(na_value) {
  function(x) {
    x[x == na_value] <- NA
    x
  }
}
fix_missing_99 <- missing_fixer(-99)
fix_missing_999 <- missing_fixer(-999)
fix_missing_9999 <- missing_fixer(-9999)
```

Let's now consider a new problem: once we've cleaned up our data, we might want to compute the same set of numerical summaries for each variable.  We could write code like this:

```R
mean(df$a)
median(df$a)
sd(df$a)
mad(df$a)
IQR(df$a)

mean(df$b)
median(df$b)
sd(df$b)
mad(df$b)
IQR(df$b)

mean(df$c)
median(df$c)
sd(df$c)
mad(df$c)
IQR(df$c)
```

But we'd be better off identifying the sources of duplication and then removing them. Take a minute or two to think about how you might tackle this problem before reading on.

One approach would be to write a summary function and then apply it to each column:

```R
summary <- function(x) { 
  c(mean(x), median(x), sd(x), mad(x), IQR(x))
}
lapply(df, summary)
```

But there's still some duplication here. If we make the summary function slightly more realistic, it's easier to see the duplication:

```R
summary <- function(x) { 
 c(mean(x, na.rm = TRUE), 
   median(x, na.rm = TRUE), 
   sd(x, na.rm = TRUE), 
   mad(x, na.rm = TRUE), 
   IQR(x, na.rm = TRUE))
}
```

All five functions are called with the same arguments (`x` and `na.rm`) which we had to repeat five times. As before, this duplication makes our code fragile: it makes it easier to introduce bugs and harder to adapt to changing requirements. 

We can take advantage of another functional programming technique, storing functions in lists, to remove this duplication:

```R
summary <- function(x) {
  funs <- c(mean, median, sd, mad, iqr)
  lapply(funs, function(f) f(x, na.rm = TRUE))
}
```

The remainder of this chapter will discuss each technique in more detail. But before we can start on those more complicated techniques, we need to start by revising a simple functional programming tool, anonymous functions.

## Anonymous functions

In R, functions are objects in their own right. They aren't automatically bound to a name, unlike many other programming languages. You might have noticed this already, because when you create a function, you use the usual assignment operator to give it a name. Functions that don't have a name are called __anonymous functions__. 

Given the name of a function, like `"mean"`, it's possible to find the function using `match.fun()`. You can't do the opposite: given the object `f <- mean`, there's no way to find its name. Not all functions have a name, and some functions have more than one name. 

We use anonymous functions when it's not worth the effort of creating a named function:

```R
lapply(mtcars, function(x) length(unique(x)))
Filter(function(x) !is.numeric(x), mtcars)
integrate(function(x) sin(x) ^ 2, 0, pi)
```

Unfortunately the default R syntax for anonymous functions is quite verbose.  To make things a little more concise, `pryr` provides `f()`:

```R
lapply(mtcars, f(length(unique(x))))
Filter(f(!is.numeric(x)), mtcars)
integrate(f(sin(x) ^ 2), 0, pi)
```

I'm not still sure whether I like this style or not, but it sure is compact!

Like all functions in R, anoynmous functions have `formals()`, a `body()`, and a parent `environment()`:
  
```R
formals(function(x = 4) g(x) + h(x))
body(function(x = 4) g(x) + h(x))
environment(function(x = 4) g(x) + h(x))
```

You can call anonymous functions without giving them a name, but the code is a little tricky to read because you must use parentheses in two different ways: to call a function, and to make it clear that we want to call the anonymous function `function(x) 3`, not inside our anonymous function call a function called `3` (which isn't a valid function name!):

```R
(function(x) 3)()

# Exactly the same as
f <- function(x) 3
f()

function(x) 3()
```

The syntax extends in a straightforward way if the function has parameters:

```R
(function(x) x)(3)
(function(x) x)(x = 4)
```

If you're calling an anonymous function in a complicated way, it's a good sign that it needs a name.

One of the most common uses for anonymous functions is to create closures, functions made by other functions. Closures are the topic of the next section.

### Exercises

* Use `lapply()` and an anonymous function to find the coefficient of variation (the standard deviation divided by the mean) for all columns in the `mtcars` dataset

* A good rule of thumb is that an anonymous function should fit on one line and shouldn't need to use `{}`.  Review your code: where could you have used an anonymous function instead of a named function? Where should you have used a named function instead of an anonymous function?

## Introduction to closures

"An object is data with functions. A closure is a function with data." 
--- [John D Cook](http://twitter.com/JohnDCook/status/29670670701)

One important use of anonymous functions is to create small functions that it's not worth naming. The other important of use of anonymous functions is to create a closure, a function written by another function. Closures are so called because they __enclose__ the environment of the parent function, and can access all variables and parameters in that function. This is useful because it allows us to have two levels of parameters. One level of parameters (the parent) controls how the function works; the other level (the child) does the work. The following example shows how we can use this idea to generate a family of power functions. The parent function (`power()`) creates child functions (`square()` and `cube()`) that do the work.

```R
power <- function(exponent) {
  function(x) x ^ exponent
}

square <- power(2)
square(2)
square(4)

cube <- power(3)
cube(2)
cube(4)
```

In R, almost every function is a closure, because all functions remember the environment in which they are created, typically either the global environment, if it's a function that you've written, or a package environment, if it's a function that someone else has written. The only exception are primitive functions, which call directly in to C.

When you print a closure, you don't see anything terribly useful:

```R
square
cube
```

That's because the function itself doesn't change; it's the enclosing environment, e.g. `environment(square)`, that's different. One way to see the contents of the environment is to convert it to a list:

```R
as.list(environment(square))
as.list(environment(cube))
```

Another way to see what's going on is to use `pryr::unenclose()`, which substitutes the variables defined in the enclosing environment into the original functon:

```R
library(pryr)
unenclose(square)
unenclose(cube)
```

Note that the parent environment of the closure is the environment created when the parent function is called:

```R
power <- function(exponent) {
  print(environment())
  function(x) x ^ exponent
}
zero <- power(0)
environment(zero)
```

This environment normally disappears once the function finishes executing, but because we return a function, the environment is captured and attached to the new function. Each time we re-run `power()` a new environment is created, so each function produced by power is independent.

Closures are useful for making function factories, and are one way to manage mutable state in R. 

### Function factories

We've already seen one example of a function factory, `power()`. We might also need a function if our initial example was slightly more complicated: imagine the missing values were inconsistently recorded and in some columns they were -99, in others they were `9999` or `"."`. Rather than copying, pasting and modifying, we could use a closure to create a remove missing function for each case:

```R
missing_remover <- function(na) {
  x[x == na] <- NA
  x
}
remove_99 <- missing_remover(-99)
remove_9999 <- missing_remover(-9999)
remove_dot <- missing_remover(".")
```

We'll see another compelling using function factories when we learn more about functionals; they are very useful for maximum likelihood problems.

### Mutable state

Having variables at two levels makes it possible to maintain state across function invocations by allowing a function to modify variables in the environment of its parent. The key to managing variables at different levels is the double arrow assignment operator (`<<-`). Unlike the usual single arrow assignment (`<-`) that always assigns in the current environment, the double arrow operator will keep looking up the chain of parent environments until it finds a matching name. ([[Environments]] has more details on how it works)

This makes it possible to maintain a counter that records how many times a function has been called, as shown in the following example. Each time `new_counter` is run, it creates an environment, initialises the counter `i` in this environment, and then creates a new function.

```R
new_counter <- function() {
  i <- 0
  function() {
    i <<- i + 1
    i
  }
}
```

The new function is a closure, and its environment is the enclosing environment. When the closures `counter_one` and `counter_two` are run, each one modifies the counter in its enclosing environment and then returns the current count. 

```R
counter_one <- new_counter()
counter_two <- new_counter()

counter_one() # -> [1] 1
counter_one() # -> [1] 2
counter_two() # -> [1] 1
```

We can use our environment inspection tools to see what's going on here:

```R
as.list(environment(counter_one))
as.list(environment(counter_two))
```

The counters get around the "fresh start" limitation by not modifying variables in their local environment. Since the changes are made in the unchanging parent (or enclosing) environment, they are preserved across function calls.

What happens if we don't use a closure? What happens if we only use `<-` instead of `<<-`? Make predictions about what will happen if you replace `new_counter()` with each variant below, then run the code and check your predictions.

```R
i <- 0
new_counter2 <- function() {
  i <<- i + 1
  i
}
new_counter3 <- function() {
  i <- 0
  function() {
    i <- i + 1
    i
  }
}
```

Modifying values in a parent environment is an important technique because it is one way to generate "mutable state" in R. Mutable state is hard to achieve normally, because every time it looks like you're modifying an object, you're actually creating a copy and modifying that. That said, if you do need mutable objects, it's usually better to use the [[R5]] OO system, except in the simplest of cases. R5 objects are easier to document, and provide easier ways to inherit behaviour across functions.

The power of closures is tightly coupled to another important class of functions: higher-order functions (HOFs), which include functions that take functions as arguments. Mathematicians distinguish between functionals, which accept a function and return a scalar, and function operators, which accept a function and return a function. Integration over an interval is a functional, the indefinite integral is a function operator. The following two chapters discuss functionals and function operators in turn.

### Exercises

* What does the following statistical function do? What would be a better name for it? (The existing name is a bit of a hint)

    ```R
    bc <- function(lambda) {
      if (lambda == 0) {
        function(x) log(x)
      } else {
        function(x) (x ^ lambda - 1) / lambda
      }
    }
    ```

* Create a function that creates functions that compute the ith [central moment](http://en.wikipedia.org/wiki/Central_moment) of a numeric vector. You can test it by running the following code:

    ```R
    m1 <- moment(1)
    m2 <- moment(2)

    x <- runif(m1, 100)
    stopifnot(all.equal(m1(x), mean(x)))
    stopifnot(all.equal(m2(x), var(x) * 99 / 100))
    ```

* What does `approxfun()` return? What does it return? What does the `ecdf()` function do? What does it return? 

* Create a function `pick()`, that takes an index, `i`, as an argument and returns a function an argument `x` that subsets `x` with `i`.
  
  ```R
  lapply(mtcars, pick(5))
  ```

## Lists of functions

In R, functions can be stored in lists. Together with closures and higher-order functions, this gives us a set of powerful tools for reducing duplication in code.

We'll start with a simple example: benchmarking, when you are comparing the performance of multiple approaches to the same problem. For example, if you wanted to compare a few approaches to computing the mean, you could store each approach (function) in a list:

    compute_mean <- list(
      base = function(x) mean(x),
      sum = function(x) sum(x) / length(x),
      manual = function(x) {
        total <- 0
        n <- length(x)
        for (i in seq_along(x)) {
          total <- total + x[i] / n
        }
        total
      }
    )

Calling a function from a list is straightforward: just get it out of the list first:

    x <- runif(1e5)
    system.time(compute_mean$base(x))
    system.time(compute_mean[[2]](x))
    system.time(compute_mean[["manual"]](x))
    
If we want to call all functions to check that we've implemented them correctly and they return the same answer, we can use `lapply`, either with an anonymous function, or a new function that calls it's first argument with all other arguments:

    lapply(compute_mean, function(f) f(x))

    call_fun <- function(f, ...) f(...)
    lapply(compute_mean, call_fun, x)

We can time every function on the list with `lapply` or `Map` along with a simple anonymous function:
    
    lapply(compute_mean, function(f) system.time(f(x)))
    Map(function(f) system.time(f(x)), compute_mean)
    
If timing functions is something we want to do a lot, we can add another layer of abstraction: a closure that automatically times how long a function takes. We then create a list of timed functions and call the timers with our specified `x`.

    timer <- function(f) {
      force(f)
      function(...) system.time(f(...))
    }
    timers <- lapply(compute_mean, timer)
    lapply(timers, call_fun, x)

Another useful example is when we want to summarise an object in multiple ways.  We could store each summary function in a list, and run each function with `lapply` and `call_fun`:

    funs <- list(
      sum = sum,
      mean = mean,
      median = median
    )
    lapply(funs, call_fun, 1:10)

What if we wanted to modify our summary functions to automatically remove missing values?  One approach would be make a list of anonymous functions that call our summary functions with the appropriate arguments:

    funs2 <- list(
      sum = function(x, ...) sum(x, ..., na.rm = TRUE),
      mean = function(x, ...) mean(x, ..., na.rm = TRUE),
      median = function(x, ...) median(x, ..., na.rm = TRUE)
    )

But this leads to a lot of duplication - each function is almost identical apart from a different function name. We could write a closure to abstract this away:

    remove_missings <- function(f) {
      function(...) f(..., na.rm = TRUE)
    }
    funs2 <- lapply(funs, remove_missings)

We could also take a more general approach. A useful function here is `Curry` (named after the famous computer scientist Haskell Curry, not the food), which implements "partial function application". What the curry function does is create a new function that passes on the arguments you specify. A example will make this more clear:

    library(pryr)
    add <- function(x, y) x + y
    addOne <- function(x) add(x, 1)
    # Or:
    addOne <- Curry(add, y = 1)

With the `Curry` function we can reduce the code a bit:

    funs2 <- list(
      sum = Curry(sum, na.rm = TRUE),
      mean = Curry(mean, na.rm = TRUE),
      median = Curry(median, na.rm = TRUE)
    )

But if we look closely that will reveal we're just applying the same function to every element in a list, and that's the job of `lapply`. This drastically reduces the amount of code we need:

    funs2 <- lapply(funs, Curry, na.rm = TRUE)

Let's think about a similar, but subtly different case. Let's take a vector of numbers and generate a list of functions corresponding to trimmed means with that amount of trimming. The following code doesn't work because we want the first argument of `Curry` to be fixed to mean.  We could try specifying the argument name because fixed matching overrides positional, but that doesn't work because the name of the function to call in `lapply` is also `FUN`.  And there's no way to specify we want to call the `trim` argument.

    trims <- seq(0, 0.9, length = 5) 
    lapply(trims, Curry, "mean")
    lapply(trims, Curry, FUN = "mean")

Instead we could use an anonymous function

    funs3 <- lapply(trims, function(t) Curry("mean", trim = t))
    lapply(funs3, call_fun, c(1:100, (1:50) * 100))

But that doesn't work because each function gets a promise to evaluate `t`, and that promise isn't evaluated until all of the functions are run.  To make it work you need to manually force the evaluation of t:

    funs3 <- lapply(trims, function(t) {force(t); Curry("mean", trim = t)})
    lapply(funs3, call_fun, c(1:100, (1:50) * 100))

A simpler solution in this case is to use `Map`, as described in the last chapter, which works similarly to `lapply` except that you can supply multiple arguments by both name and position. For this example, it doesn't do a good job of figuring out how to name the functions, but that's easily fixed.

    funs3 <- Map(Curry, "mean", trim = trims)
    names(funs3) <- trims
    lapply(funs3, call_fun, c(1:100, (1:50) * 100))


### Moving lists of functions to the global environment

From time to time you may want to create a list of functions that you want to be available to your users without having to an special syntax.  There are a few ways to achieve that, based on the idea that lists and environments share very similar interfaces

* `with(fs, mycode)`

* `attach(fs)` - this makes a copy of the list so that there's no connection between the two, but it is easier to remove afterwards.

* `list2env(fs, environment())` - efficiently copies from a list into the `globalenv()` (or wherever the code is running - using `environment()` means that it will also work just within a function or as top-level code in a package.)

An alternative approach is to work with names of function with `get()` and `assign()` - I prefer the approach of keeping functions in a list as long as possible, because there are a richer set of functions for dealing with lists than there are for dealing with character vectors containing variable names.

### Exercises

* Write a compose function that takes a list of function and creates a new function that calls them in order from left to right. 

## Case study: numerical integration

To conclude this chapter, we will develop a simple numerical integration tool, and along the way, illustrate the use of many properties of first-class functions: we'll use anonymous functions, lists of functions, functions that make closures and functions that take functions as input. Each step is driven by a desire to make our approach more general and to reduce duplication.

We'll start with two very simple approaches: the midpoint and trapezoid rules. Each takes a function we want to integrate, `f`, and a range to integrate over, from `a` to `b`. For this example we'll try to integrate `sin x` from 0 to pi, because it has a simple answer: 2

    midpoint <- function(f, a, b) {
      (b - a) * f((a + b) / 2)
    }

    trapezoid <- function(f, a, b) {
      (b - a) / 2 * (f(a) + f(b))
    }
    
    midpoint(sin, 0, pi)
    trapezoid(sin, 0, pi)


Neither of these functions gives a very good approximation, so we'll do what we normally do in calculus: break up the range into smaller pieces and integrate each piece using one of the simple rules. To do that we create two new functions for performing composite integration:

    midpoint_composite <- function(f, a, b, n = 10) {
      points <- seq(a, b, length = n + 1)
      h <- (b - a) / n
      
      area <- 0
      for (i in seq_len(n)) {
        area <- area + h * f((points[i] + points[i + 1]) / 2)
      }
      area
    }

    trapezoid_composite <- function(f, a, b, n = 10) {
      points <- seq(a, b, length = n + 1)
      h <- (b - a) / n
      
      area <- 0
      for (i in seq_len(n)) {
        area <- area + h / 2 * (f(points[i]) + f(points[i + 1]))
      }
      area
    }
    
    midpoint_composite(sin, 0, pi, n = 10)
    midpoint_composite(sin, 0, pi, n = 100)
    trapezoid_composite(sin, 0, pi, n = 10)
    trapezoid_composite(sin, 0, pi, n = 100)
    
    mid <- sapply(1:20, function(n) midpoint_composite(sin, 0, pi, n))
    trap <- sapply(1:20, function(n) trapezoid_composite(sin, 0, pi, n))
    matplot(cbind(mid = mid, trap))

But notice that there's a lot of duplication across `midpoint_composite` and `trapezoid_composite`: they are basically the same apart from the internal rule used to integrate over a simple range. Let's extract out a general composite integrate function:

    composite <- function(f, a, b, n = 10, rule) {
      points <- seq(a, b, length = n + 1)
      
      area <- 0
      for (i in seq_len(n)) {
        area <- area + rule(f, points[i], points[i + 1])
      }
      
      area
    }
    
    midpoint_composite(sin, 0, pi, n = 10)
    composite(sin, 0, pi, n = 10, rule = midpoint)
    composite(sin, 0, pi, n = 10, rule = trapezoid)

This function now takes two functions as arguments: the function to integrate, and the integration rule to use for simple ranges. We can now add even better rules for integrating small ranges:

    simpson <- function(f, a, b) {
      (b - a) / 6 * (f(a) + 4 * f((a + b) / 2) + f(b))
    }
    
    boole <- function(f, a, b) {
      pos <- function(i) a + i * (b - a) / 4
      fi <- function(i) f(pos(i))
      
      (b - a) / 90 * 
        (7 * fi(0) + 32 * fi(1) + 12 * fi(2) + 32 * fi(3) + 7 * fi(4))
    }
    
Let's compare these different approaches.

    expt1 <- expand.grid(
      n = 5:50, 
      rule = c("midpoint", "trapezoid", "simpson", "boole"), 
      stringsAsFactors = F)
    
    abs_sin <- function(x) abs(sin(x))
    run_expt <- function(n, rule) {
      composite(abs_sin, 0, 4 * pi, n = n, rule = match.fun(rule))
    }
    
    library(plyr)
    res1 <- mdply(expt1, run_expt)
    
    library(ggplot2)
    qplot(n, V1, data = res1, colour = rule, geom = "line")

It turns out that the midpoint, trapezoid, Simpson and Boole rules are all examples of a more general family called Newton-Cotes rules. We can take our integration one step further by extracting out this commonality to produce a function that can generate any general Newton-Cotes rule:

    # http://en.wikipedia.org/wiki/Newton%E2%80%93Cotes_formulas
    newton_cotes <- function(coef, open = FALSE) {
      n <- length(coef) + open
      
      function(f, a, b) {
        pos <- function(i) a + i * (b - a) / n
        points <- pos(seq.int(0, length(coef) - 1))
        
        (b - a) / sum(coef) * sum(f(points) * coef)        
      }
    }
    
    trapezoid <- newton_cotes(c(1, 1))
    midpoint <- newton_cotes(1, open = T)
    simpson <- newton_cotes(c(1, 4, 1))
    boole <- newton_cotes(c(7, 32, 12, 32, 7))
    milne <- newton_cotes(c(2, -1, 2), open = TRUE)
    
    # Alternatively, make list then use lapply
    lapply(values, newton_cotes, closed)
    lapply(values, newton_cotes, open, open = TRUE)
    lapply(values, do.call, what = "newton_cotes")
    
    expt1 <- expand.grid(n = 5:50, rule = names(rules), stringsAsFactors = F)
    run_expt <- function(n, rule) {
      composite(abs_sin, 0, 4 * pi, n = n, rule = rules[[rule]])
    }
    

Mathematically, the next step in improving numerical integration is to move from a grid of evenly spaced points to a grid where the points are closer together near the end of the range. 

## Summary

## Exercises

1. Read the source code for `Filter`, `Negate`, `Find` and `Position`. Write a couple of sentences for each describing how they work.

1. Write an `And` function that given two logical functions, returns a logical And of all their results. Extend the function to work with any number of logical functions. Write similar `Or` and `Not` functions.

1. Write a general compose function that composes together an arbitrary number of functions. Write it using both recursion and looping.

1. How does the first version of `Curry` work?
