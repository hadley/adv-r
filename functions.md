# Functions

Functions are a fundamental building block of R: to master many of the more advanced techniques in this book, you need a solid foundation in how functions work. If you're reading this book, you've probably already created many R functions, and you're familiar with the basics of how they work. The focus of this chapter is to turn your existing, informal, knowledge of functions into a rigorous understanding of what functions are and how they work. You'll see some interesting tricks and techniques in this chapter, but most of what you'll learn is more important as building blocks for more advanced techniques.

Hopefully most of this chapter will be revision and you can skim through it quickly, but you'll clarify your understand of functions as you go.

In this chapter you will learn:

* The three main components of a function.
* How scoping works, the process looks up values from names.
* The three ways of supplying arguments to a function, and the impact of lazy evaluation.
* The two types of special functions: infix and replacement functions.

## Components of a function

There are three main components of a function

* the `body()`, the code inside the function

* the `formals()`, the argument list, that controls how you can call a function

* the `environment()` which determines how variables referred to inside the 

There are two other components function that are less important for our purspoes: the source of the function (which includes comments, unlike the `body()`), and if the function has been byte-code compiled, the byte code.

When you print a function in R, it shows you the formals, the source code and the environment. If the environment isn't displayed, it means that the function was created in the global environment. 

    f <- function(x) x
    f
    
    formals(f)
    body(f)
    environment(f)

There is an exeception to this rule: primitive functions, like `sum`:

    sum
    formals(sum)
    body(sum)
    environment(sum)

These are functions that call C code directly, (with `.Primitive()`). Primitive functions contain no R code and exist almost entirely in C, so their `formals()`, `body()` and `environment()` are all `NULL`. They are only found in the `base` package, and since they operate at a lower-level than most functions, they can be more efficient (primitive replacement functions don't have to make copies), and can have different rules for argument matching (e.g. `switch` and `call`). 

The assignment forms of `body()`, `formals()`, and `environment()` can also be used to modify functions. This is a useful technique which we'll explore in more detail in [[computing in the language]].

### Examples

* What function allows you to tell if a function is a primitive function or not?
* 

## Lexical scoping

Scoping is the set of rules that govern how R looks up the value of a symbol, or name. That is, scoping is the set rules that R applies to go from the symbol `x`, to its value `10` in the following example.

    x <- 10
    x
    # [1] 10

Understanding scoping allows you to:

* build tools by composing functions, as described in [[first-class-functions]]
* overrule the usual evaluation rules and [[computing-on-the-language]]

R has two types of scoping: __lexical scoping__, implemented automatically at the language level, and __dynamic scoping__, used in select functions to save typing during interactive analysis. We describe lexical scoping here because it is intimately tied to function creation. Dynamic scoping is described in the context of [[controlling evaluation|Evaluation]].

Lexical scoping looks up symbol values using how functions are nested when they were written, not when they were called. With lexical scoping, you can figure out where the value of each variable will be looked up only by looking at the definition of the function, you don't need to know anything about how the function is called.

The "lexical" in lexical scoping doesn't correspond to the usual English definition ("of or relating to words or the vocabulary of a language as distinguished from its grammar and construction") but comes from the computer science term "lexing", which is part of the process that converts code represented as text to meaningful pieces that the programming language understands. It's lexical in this sense, because you only need the definition of the functions, not how they are called.

There are four basic principles behind R's implementation of lexical scoping:

* name masking
* functions vs. variable
* a fresh start
* dynamic lookup

### Name masking

The following example illustrates the basic principle:

    f <- function() { 
      x <- 1
      y <- 2
      c(x, y)
    }
    f()
    rm(f)

If a name isn't defined inside a function, it will look one level up.

    x <- 1
    g <- function() { 
      y <- 2
      c(x, y)
    }
    g()
    rm(x, g)

The same rules apply if a `function` is defined inside another function.  First it looks inside the current function, then where that function was defined, and so on, all the way until the global environment. Run the following code in your head, then confirm the output by running the R code.

    x <- 1
    h <- function() { 
      y <- 2
      i <- function() {
        z <- 3
        c(x, y, z)
      }
      i()
    }
    h()
    rm(x, h)

The same rules apply to closures, functions that return functions. The following function, `j()`, returns a function.  What do you think this function will return when we call it?

    j <- function(x) {
      y <- 2
      function() {
        c(x, y)
      }
    }
    k <- j(1)
    k()
    rm(j, k)

This seems a little magical (how does R know what the value of `y` is after the function has been called), but it works because `k` keeps around the environment in which it was defined, which includes the value of `x`.  [[Environments]] gives some pointers on how you can dive in and figure out what some of the values are.

### Functions vs. variables

The same principles apply regardless of type of the associated value - finding functions works exactly the same way as finding variables:

    l <- function(x) x + 1
    m <- function() {
      l <- function(x) x * 2
      l(10)
    }
    rm(l, m)

There is one small tweak to the rule for functions. If you are using a name in a context where it's obvious that you want a function (e.g. `f(3)`), R will keep searching up the environments until it finds a function.  This means that in the following example `n` takes on a different value depending on whether R is looking for a function or a variable.

    n <- function(x) x / 2
    o <- function() {
      n <- 10
      n(n)
    }

### A fresh start

What happens to the values in between invocations of a function? What will happen the first time you run this function? What will happen the second time? (If you haven't seen `exists` before it returns `TRUE` if there's a variable of that name, otherwise it returns `FALSE`)

    j <- function() {
      if (!exists("a")) {  
        a <- 1
      } else {
        a <- a + 1
      }
      print(a)
    }

You might be surprised that it returns the same value, `1`, every time. This is because every time a function is called, a new environment is created to host execution. A function has no way to tell what happened the last time it was run; each invocation is completely independent.

### Dynamic lookup

Lexical scoping determines where to look for values, not when to look for them. R looks looks for values when the function is run, not when it's created. This means results from a function can be different depending on objects outside its environment:

    f <- function() x
    x <- 15
    f()

    x <- 20
    f()

You generally want to avoid this behavour because it means the function is no longer self-contained. This is a common error - if you make a spelling mistake in your code, you won't get an error when you create the function, and you might not even get one when you run the function, depending on what variables are defined in the global environment. 

One way to detect this problem is the `findGlobals()` function from `codetools`. This function list all the external dependencies of a function:

    f <- function() x + 1

    codetools::findGlobals(f)

Another way to try and solve the problem would be to manually change the environment of the function to the `emptyenv()`, an environment which contains absolutely nothing:

    environment(f) <- emptyenv()
    f()

This doesn't work because R relies on lexical scoping to find _everything_, even the `+` operator.  

You can use this same idea to do other things that are extremely ill-advised. For example, since all of the standard operators in R are functions, you can override them with your own alternatives.  If you ever are feeling particularly evil, run the following code while your friend is away from their computer:

    "(" <- function(e1) {
      if (is.numeric(e1) && runif(1) < 0.1) {
        e1 + 1
      } else {
        e1
      }
    }

This will introduce a particularly pernicious bug: 10% of the time, 1 will be added to any numeric operation carried out inside parentheses. This is yet another good reason to regularly restart with a clean R session!

Most of the time changing the behaviour of base functions is a really bad idea, but it can occassionally allow you to do something that would have otherwise been impossible. For example, this feature makes it for the `dplyr` package to translate R expressions into SQL expressions.

### Exercises

* What does the following code return? Why? What does each of the three `c`'s mean?

        c <- 10
        c(c = c)

* (From the R inferno 8.2.36): If `weirdFun()()()` is a valid command, what does `weirdFun()` return? Write an example.

* What does the following function return? Make a prediction before running the code yourself.

      f <- function(x) {
        f <- function(x) {
          f <- function(x) {
            x ^ 2
          }
          f(x) + 1
        }
        f(x) * 2
      }
      f(10)


## Function arguments

R's function call semantics

When calling a function you can specify arguments by position, or by name:

    mean(1:10)
    mean(x = 1:10)
    mean(x = 1:10, trim = 0.05)

Arguments are matched first by exact name, then by prefix matching and finally by position.

Generally, you only want to use positional matching for the first one or two arguments: they will be the mostly commonly used, and most readers will probably know what they are. Avoid using positional matching for less commonly used arguments, and only use readable abbreviations with partial matching.

### Lazy evaluation

By default, R function arguments are lazy - they're not evaluated when you call the function, but only when that argument is used:

    f <- function(x) {
      10
    }
    system.time(f(Sys.sleep(10)))
    # user  system elapsed 
    #    0       0       0  

If you want to ensure that an argument is evaluated you can use `force`: 

    f <- function(x) {
      force(x)
      10
    }
    system.time(f(Sys.sleep(10)))
    # user  system elapsed 
    #    0       0  10.001  

Default arguments are evaluated in the environment where they are defined. This means that if the expression depends on the current environment the results will be different depending on whether you use the default value or explicitly provide it.

    f <- function(x = ls()) {
      a <- 1
      g(x)
    }
    g <- function(x) {
      b <- 2
      x
    }
    f()
    f(ls())

More technically, an unevaluated argument is called a __promise__, or a thunk. A promise is made up of two parts:

* an expression giving the delayed computation, which can be accessed with
  `substitute` (see [[controlling evaluation|evaluation]] for more details)

* the environment where the expression was created and where it should be
  evaluated

You can find more information about a promise using `langr::promise_info`.  This uses some of R's C api to extract information about the promise without evaluating it (which is otherwise very tricky).

You may notice this is rather similar to a closure with no arguments, and in many languages that don't have laziness built in like R, this is how you can implement laziness.

<!-- When is it useful? http://lambda-the-ultimate.org/node/2273 -->

This is particularly useful in if statements:

    if (!is.null(x) && y > 0)

And you can use it to write functions that are not possible otherwise

    and <- function(x, y) {
      if (!x) FALSE else y
    }
    
    a <- 1
    and(!is.null(a), a > 0)

    a <- NULL
    and(!is.null(a), a > 0)

This function would not work without lazy evaluation because both `x` and `y` would always be evaluated, testing if `a > 0` even if `a` was NULL.

You could even write your own versions of `if`

    myif <- function(cond, true, false) if (cond) true else false
    only_if(cond, true) if (cond) true

### `...`

There is a special argument called `...`.  This argument will match any arguments not otherwise matched, and can be used to call other functions.  This is useful if you want to collect arguments to call another function, but you don't want to prespecify their possible names.

To capture `...` in a form that is easier to work with, you can use `list(...)`.

Using `...` comes with a cost - any misspelled arguments will be silently ignored.  It's often better to be explicit instead of explicit, so you might instead ask users to supply a list of additional arguments.  And this is certainly easier if you're trying to use `...` with multiple additional functions.


## Special functions

There are two special types of functions that behave differently to regular R functions: infix and replacement functions.

### Infix functions

Most functions are "prefix" operators: the name of the function comes before the arguments. In R you can also create infix functions where the function name comes in between its arguments, like `+` or `-`.  All infix functions names must start and end with `%` and R comes with the following infix functions predefined: `%%`, `%*%`, `%/%`, `%in%`, `%o%`,  `%x%`. 

For example, we could create a new operator that pastes together strings:

    "%+%" <- function(a, b) paste(a, b, sep = "")
    "new" %+% " string"

Note that you have to put the name of the function in quotes because it's a special name.

The names of infix functions are more flexible than regular R functions: they can contain any sequence of characters (except "%", of course). You will need to escape any special characters in the string used to define the function, but not when you call it:

    "% %" <- function(a, b) paste(a, b)
    "%'%" <- function(a, b) paste(a, b)
    "%/\\%" <- function(a, b) paste(a, b)

    "a" % % "b"
    "a" %'% "b"
    "a" %/\% "b"

R's default precedence rules mean that infix operators are composed from left to right:

    "%-%" <- function(a, b) paste("(", a, " - ", b, ")", sep = "")
    "a" %-% "b" %-% "c"

### Replacement functions

Replacement functions acts like they modify their arguments in place, and have the special name `xxx<-`. They typically have two arguments (`x` and `value`), although they can have more, and they must return the modified object. For example, the following function allows you to modify the second element of a vector:

    "second<-" <- function(x, value) {
      x[2] <- value
      x
    }
    x <- 1:10
    second(x) <- 5L
    x

If you want to supply additional arguments, they go in between `x` and `value`:

    "modify<-" <- function(x, position, value) {
      x[position] <- value
      x
    }
    modify(x, 1) <- 10
    x

It's often useful to combine replacement and subsetting, and this works out of the box:

    x <- c(a = 1, b = 2, c = 3)
    names(x)
    names(x)[2] <- "two"
    names(x)

This works because `names(x)[2] <- "two"` is evaluated as `x <- "names<-"(x, "[<-"(names(x), 2, "two"))`, i.e. it's efficient equivalent to:

    y <- names(x)
    y[2] <- "two"
    names(x) <- y

### Exercises



## Return values

The last expression evaluated in a function becomes the return value, the result of invoking the function. 

    f <- function(x) {
      if (x < 10) {
        0
      } else {
        10
      }
    }
    f(5)
    f(15)

Generally, I think it's good style to reserve the use of an explicit `return()` for when you are returning early, such as for an error, or a simple case of the function. This style of programming can also reduce the level of indentation, and generally make functions easier to understand because you can reason about them locally.

    f <- function(x, y) {
      if (!x) return(y)

      # complicated processing here
    }


Functions can return only a single value, but this is not a limitation in practice because you can always return a list containing any number of objects.

The functions that are the most easy understand and reason about are pure functions, functions that always map the same input to the same output and have no other impact on the workspace. R protects you from one type of side-effect: arguments are passed-by-value, so modifying a function argument does not change the original value:

    f <- function(x) {
      x$a <- 2
      x
    }
    x <- list(a = 1)
    f(x)
    x$a

This is a notable exception to languages like Java where you can modify the inputs to a function. This copy-on-modify behaviour has important performance consequences which are discussed in depth in [[profiling]]. (Note that the performance consequences are a result of R's implementation of copy-on-modify semantics, they are not true in general. Clojure is a new language that makes extensive use of copy-on-modify semantics with limited performance consequences.)

Most base R functions are pure, with a few notable exceptions:

* `library` which loads a package, and hence modifies the search path

* `setwd`, `Sys.setenv`, `Sys.setlocale` which change the working directory, evnironment variables and the locale respectively

* `plot` and friends which produce graphical output

* `write`, `write.csv`, `saveRDS` etc which save output to disk

* `options` and `par` which modify global settings

* random number generators which produce different numbers each time you run then

It's generally a good idea to minimise the use of side effects, and where possible have special functions that are called only for their side effects.  Pure functions are easier to test (because all you need to worry about are the input values and the output), and are less likely to work differently on different versions of R or on different platforms.  

Functions can return `invisible` values, which are not print out by default when you call the function.

    f1 <- function() 1
    f2 <- function() invisible(1)

    f1()
    f2()
    f1() == 1
    f2() == 1

You can always force an invisible value to be display by wrapping it in parentheses:

    (f2())

The most common function that returns invisibly is `<-`:

    a <- 2
    (a <- 2)

And this is what makes it possible to assign one value to multiple variables:

    a <- b <- c <- d <- 2

### Exercises
