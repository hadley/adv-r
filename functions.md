# Functions

Functions are a fundamental building block of R: to master many of the more advanced techniques in this book, you need a solid foundation in how functions work. If you're reading this book, you've probably already created many R functions, and you're familiar with the basics of how they work. The focus of this chapter is to turn your existing, informal, knowledge of functions into a rigorous understanding of what functions are and how they work. You'll see some interesting tricks and techniques in this chapter, but most of what you'll learn is more important as building blocks for more advanced techniques.

Functions in R are considerably more flexible than most languages. As with much of R, there are few guard rails: it's quite possible to do things that are extremely ill-advised. For example, all of the standard operators in R are functions and you can override with your own alternatives:

    "+" <- function(e1, e2) sum(e1, e2, runif(1))

Most of the time this is a really bad idea, but occassionally it can allow you to do something that would have otherwise been impossible. (For example, it made it possible to write the `dplyr` package which can translate R expressions into SQL expressions).

This chapter is organised around the three main components of a function:

* the `body()`, the code inside the function

* the `formals()`, the argument list, that controls how you can call a function

* the `environment()` which determines how variables referred to inside the 

* (There's also one more component of a function that we won't talk about here, the source code of the function, which you can access with `attr(, "source"))`

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

## `environment(f)`: lexical scoping

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

### Name masking

The following example illustrates the basic principle:

    f <- function() { 
      x <- 1
      y <- 2
      c(1, 2)
    }
    f()
    rm(f)

If a name isn't defined inside a function, it will look one level up.

    x <- 1
    g <- function() { 
      y <- 2
      c(x, y)
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

This seems a little magical (how does R know what the value of `y` is after the function has been called), but it's because every function stores the environment in which it's defined. [[Environments]] gives some pointers on how you can dive in and figure out what some of the values are.

That the same principles apply regardless of what the variable contains - finding functions works exactly the same way as finding variables:

    l <- function(x) x + 1
    m <- function() {
      l <- function(x) x * 2
      l(10)
    }
    rm(l, m)

There is one small tweak to the rule of functions. If you are using a variable in a context where it's obvious that you want a function (e.g. `f(3)`), R will keep searching up the environments until it finds a function.  This means that in the following example `n` takes on a different value depending on whether R is looking for a function or a regular value.

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

You might be surprised that it returns the same value, `1`, every time. This is because every time a function is called, a new environment is created to host execution. A function has no way to tell what happened the last time it was run.

### Dynamic lookup

Lexical scoping determines where to look for values, not when to look for them. Unlike some languages, R looks up at the values at run-time, not when the function is created.  This means results from a function can be different depending on objects outside its environment:

    f <- function() x
    x <- 15
    f()

    x <- 20
    f()

Generally, this is behaviour to be avoided.  To detect this situation, you can use `codetools::findGlobals`. Manually overriding the environment to the empty environment doesn't work, because R relies on lexical scoping to find _everything_, even the `+` operator.

    f <- function() x + 1

    codetools::findGlobals(f)

    environment(f) <- emptyenv()
    f()

### Exercises

* What does the following code return? Why? How is each of the 3 `c`'s interpreted?

        c <- 10
        c(c = c)

## `body(f)`: types of functions




### Infix operators

Most functions are "prefix" operators: the name of the function comes before the arguments.  In R you can also create infix functions where the function name comes in between it's arguments.  All infix functions names must start and end with `%`.

For example, we could create a new operator for combining strings:

    "%+%" <- function(a, b) paste(a, b)
    "new" %+% "string"

Note that you have to put the name of the function in quotes because it's a special name.

### Replacement functions

Replacement functions acts like they modify their arguments in place, and have the special name `xxx<-`. They typically have two arguments (`x` and `value`), although they can have more, and they must return the modified object. 

For example, the following function allows you to modify the second element of a vector:

    "second<-" <- function(x, value) {
      x[2] <- value
      x
    }
    x <- 1:10
    .Internal(inspect(x))
    second(x) <- 5L
    x
    .Internal(inspect(x))

It's often useful to combine replacement and subsetting:

    x <- setNames(1:3, letters[1:3])
    names(x)[2] <- "two"
    names(x)

This works because `names(x)[2] <- "two"` is evaluated as `x <- "names<-"(x, "[<-"(names(x), 2, "two"))`, i.e. it's equivalent to:

    y <- names(x)
    y[2] <- "two"
    names(x) <- y

Typically, modifying in place will not create a copy of the data, but if you're depending on that for high performance, it's best to double check.


## Return values

Pure functions.

Invisable value.

In R arguments are passed-by-value, so the only way a function can affect the outside world is through its return value:

    f <- function(x) {
      x$a <- 2
    }
    x <- list(a = 1)
    f()
    x$a

Functions can return only a single value, but this is not a limitation in practice because you can always return a list containing any number of objects.

## `formals(f)`: function arguments

R's function call semantics

When calling a function you can specify arguments by position, or by name:

    mean(1:10)
    mean(x = 1:10)
    mean(x = 1:10, trim = 0.05)

Arguments are matched first by exact name, then by prefix matching and finally by position.



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

### `...`

There is a special argument called `...`.  This argument will match any arguments not otherwise matched, and can be used to call other functions.  This is useful if you want to collect arguments to call another function, but you don't want to prespecify their possible names.

To capture `...` in a form that is easier to work with, you can use `list(...)`.

Using `...` comes with a cost - any misspelled arguments will be silently ignored.  It's often better to be explicit instead of explicit, so you might instead ask users to supply a list of additional arguments.  And this is certainly easier if you're trying to use `...` with multiple additional functions.


## Exercises

* (From the R inferno 8.2.36): If `weirdFun()()()` is a valid command, what does `weirdFun()` return? Write an example.