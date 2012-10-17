# Functions

If you're reading this book, you've probably already created many R functions, and you're familiar with the basics of how they work. This chapter will help make concrete your knowledge of functions, and help you understand some of the more important underlying details.

The knowledge in this chapter is an important building block for doing useful things with functions.

All functions have four components

* `body(f)`: the quoted object representing the code inside the function
* `formals(f)`: the argument list to the function
* `environment(f)`: the environment in which the function was defined
* `attr(f, "srcref")`: the source code used to create the function

(There is an exeception to this rule: primitive functions, which use `.Primitive` to call C code directly are handled specially: e.g. `formals(sum)`, `body(sum)`, `environment(sum)`)

These can also be used to modify the structure of the function in their assignment form.

When you print a function in R, it shows you the formals, the source code and the environment. If the environment isn't displayed, it means that the function was created in the global environment. 

    f <- function(x) x
    f
    # function(x) x
    environment(f)
    # <environment: R_GlobalEnv>
    
    print
    # function (x, ...) 
    # UseMethod("print")
    # <environment: namespace:base>

## Creating functions

The tool we use for creating functions is `function`. It is very close to being an ordinary R function, but it has special syntax: the last argument to the function is outside the call and provides the body of the new function.  If we don't assign the results of `function` to a variable we get an anonymous function:

    function(x) 3
    # function(x) 3

## Anonymous functions

In R, functions are objects in their own right. Unlike many other programming languages, functions aren't automatically bound to a name: they can exist independently. You might have noticed this already, because when you create a function, you use the usual assignment operator to give it a name. 

Given the name of a function as a string, you can find that function using `match.fun`. The inverse is not possible: because not all functions have a name, or functions may have more than one name. Functions that don't have a name are called __anonymous functions__. 

You can call anonymous functions, but the code is a little tricky to read because you must use parentheses in two different ways: to call a function, and to make it clear that we want to call the anonymous function `function(x) 3` not inside our anonymous function call a function called `3` (not a valid function name):

    (function(x) 3)()
    # [1] 3
    
    # Exactly the same as
    f <- function(x) 3
    f()
    
    function(x) 3()
    # function(x) 3()

The syntax extends in a straightforward way if the function has parameters

    (function(x) x)(3)
    # [1] 3
    (function(x) x)(x = 4)
    # [1] 4

Like all functions in R, anoynmous functions have `formals`, `body` and `environment`
  
    formals(function(x = 4) g(x) + h(x))
    # $x
    # [1] 4

    body(function(x = 4) g(x) + h(x))
    # g(x) + h(x)
    
    environment(function(x = 4) g(x) + h(x))
    # <environment: R_GlobalEnv>

## Closures 

"An object is data with functions. A closure is a function with data." 
--- [John D Cook](http://twitter.com/JohnDCook/status/29670670701)

Anonymous functions are most useful in conjunction with closures, a function written by another function. Closures are so called because they __enclose__ the environment of the parent function, and can access all variables and parameters in that function. This is useful because it allows us to have two levels of parameters. One level of parameters (the parent) controls how the function works. The other level (the child) does the work. The following example shows how can use this idea to generate a family of power functions. The parent function (`power`) creates child functions (`square` and `cube`) that actually do the hard work.

    power <- function(exponent) {
      function(x) x ^ exponent
    }

    square <- power(2)
    square(2) # -> [1] 4
    square(4) # -> [1] 16

    cube <- power(3)
    cube(2) # -> [1] 8
    cube(4) # -> [1] 64

An interesting property of functions in R is that basically every function in R is a closure, because all functions remember the environment in which they are created, typically either the global environment, if it's a function that you've written, or a package environment, if it's a function that someone else has written. 

But this isn't very useful because functions in R rely on lexical scoping:

    f(1)
    # Error in f(1) : could not find function "+"

## Lexical scoping

Scoping is the set of rules that govern how R looks up the value of a symbol, or name. That is, scoping is the set rules that R applies to go from the symbol `x`, to its value `10` in the following example.

    x <- 10
    x
    # [1] 10

R has two types of scoping: __lexical scoping__, implemented automatically at the language level, and __dynamic scoping__, used in select functions to save typing during interactive analysis. This document describes lexical scoping, as well as environments (the underlying data structure). Dynamic scoping is described in the context of [[controlling evaluation|Evaluation]].

Understanding scoping allows you to:

* build tools by composing functions, as described in [[first-class-functions]]
* overrule the usual evaluation rules and [[computing-on-the-language]]

Lexical scoping looks up symbol values using how functions are nested when they were written, not when they were called. With lexical scoping, you can figure out where the value of each variable will be looked up only by looking at the definition of the function, you don't need to know anything about how the function is called.

The "lexical" in lexical scoping doesn't correspond to the usual English definition ("of or relating to words or the vocabulary of a language as distinguished from its grammar and construction") but comes from the computer science term "lexing", which is part of the process that converts code represented as text to meaningful pieces that the programming language understands.  It's lexical in this sense, because you only need the definition of the functions, not how they are called.

The following example illustrates the basic principle:

    x <- 5
    f <- function() { 
      y <- 10
      c(x = x, y = y)
    }
    f()
    #  x  y 
    #  5 10

Lexical scoping is the rule that determines where values are looked for, not when. Unlike some languages, R looks up at the values at run-time, not when the function is created.  This means results from a function can be different depending on objects outside its environment:

    x <- 15
    f()
    #  x  y 
    # 15 10
    x <- 20
    f()
    #  x  y 
    # 20 10

Generally, this is behaviour to be avoided.  To detect this situation, you can use `codetools::findGlobals`, which is automatically run by `R CMD check`.  Manually overriding the environment to the empty environment doesn't work, because R relies on lexical scoping to find _everything_, even the `+` operator.

    f <- function(x) x + 1
    environment(f) <- emptyenv()
    f
    # function(x) x + 1
    # <environment: R_EmptyEnv>

If a name is defined inside a function, it will mask the top-level definition:

    g <- function() { 
      x <- 21
      y <- 11
      c(x = x, y = y)
    }
    f()
    #  x  y 
    # 20 10
    g()
    #  x  y 
    # 21 11

The same rules apply to closures, functions that return functions:

```R
x <- 10
f <- function() {
  y <- 1
  function() {
    c(x = x, y = y)
  }
}
g <- f()
g()
```

This seems a little magical (how does R know what the value of `y` is after the function has been called), but it's because every function stores the environment in which it's defined.  [[Environments]] gives some pointers on how you can dive in and figure out what some of the values are.

## Lazy evaluation of function arguments

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

