# First class functions

R supports "first class functions", functions that can be:

* created anonymously
* assigned to variables and stored in data structures
* returned from functions (closures)
* passed as arguments to other functions (higher-order functions)

This chapter explores these properties in more depth. You should be familiar with the basic properties of [[scoping and environments|Scoping]] before reading this chapter

New levels of abstraction give us more tools to identify and remove redundancy from our code. For loops abstract repetition, giving us general tools to repeat an action multiple time. Functions abstract tasks, allowing us to separate the general principles of a task from the specific data it is applied to. The properties of first class functions give us new tools for problems that involve working with multiple functions.

## Anonymous functions

The key to all more advanced techniques described below is that in R, functions are objects in their own right. Unlike many other programming languages functions aren't automatically bound to a name - they can exist independently in their own right. You're probably aware of this already, because when you create a named function, you use the usual assignment operator to give it a name. If you don't do that - you get an anonymous function. The remainder of this chapter explores the consequences of this idea.

Anonymous functions are not that useful by themselves, so this section will introduce the basic ideas, and show useful applications in the following sections.

Given the name of a function as a string, you can retrieve the function using `match.fun`.  Given a function, there is no general way to retrieve its name because it may not have a name, or may have more than one name.  Named functions are a subclass of all functions in R.

The tool we use for creating functions is `function` - it is very close to being an ordinary R function, but it has special syntax: the last argument to the function is outside the call to function and provides the body of the new function.

    function(x) 3
    # function(x) 3

You can also call anonymous functions. The following code is a little tricky to read because parentheses are used in two different ways: to call a function, and to make it clear that we want to call the anonymous function `function(x) 3` not inside our anonymous function call a function called `3` (not a valid function name)

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

Functions have three important components

* `body()`: the quoted object representing the code inside the function
* `formals()`: the argument list to the function
* `environment()`: the environment in which the function was defined

These can both also be used to modify the structure of the function in their assignment form.
  
These are illustrated below:
  
    formals(function(x = 4) g(x) + h(x))
    # $x
    # [1] 4

    body(function(x = 4) g(x) + h(x))
    # g(x) + h(x)

## Closures 

"An object is data with functions. A closure is a function with data." 
--- [John D Cook](http://twitter.com/JohnDCook/status/29670670701)

A closure is a function written by another function. Closures are so called because they __enclose__ the environment of the parent function, and can access all variables and parameters in that function. This is useful because it allows us to have two levels of parameters. One level of parameters (the parent) controls how the function works. The other level (the child) does the work. The following example shows how can use this idea to generate a family of power functions. The parent function (`power`) creates child functions (`square` and `cube`) that actually do the hard work.

    power <- function(exponent) {
      function(x) x ^ exponent
    }

    square <- power(2)
    square(2) # -> [1] 4
    square(4) # -> [1] 16

    cube <- power(3)
    cube(2) # -> [1] 8
    cube(4) # -> [1] 64

The ability to manage variables at two levels also makes it possible to maintain the state across function invocations by allowing a function to modify variables in the environment of its parent. Key to managing variables at different levels is the double arrow assignment operator (`<<-`). Unlike the usual single arrow assignment (`<-`) that always works on the current level, the double arrow operator will look for a variable with that name in the parent scope.

This makes it possible to maintain a counter that records how many times a function has been called, as the following example shows. Each time `new_counter` is run, it creates an environment, initialises the counter `i` in this environment, and then creates a new function.

    new_counter <- function() {
      i <- 0
      function() {
        # do something useful, then ...
        i <<- i + 1
        i
      }
    }

The new function is a closure, and its environment is the enclosing environment. When the closures `counter_one` and `counter_two` are run, each one modifies the counter in its enclosing environment and then returns the current count.

    counter_one <- new_counter()
    counter_two <- new_counter()

    counter_one() # -> [1] 1
    counter_one() # -> [1] 2
    counter_two() # -> [1] 1

This is an important technique because it is one way to generate "mutable state" in R.

Basically every function in R is a closure, because all functions remember the environment in which they are created, typically either the global environment, if it's a function that you're written, or a package environment, if it's a function that someone else has written. When you print a function in R, it always shows you which environment it comes from. If the environment isn't displayed, it doesn't mean it doesn't have an environment, it means that it was created in the global environment. The environment inside an arbitrary function doesn't have a special name, so the environment of closures that you've created will have random names.

    f <- function(x) x
    f
    # function(x) x
    environment(f)
    # <environment: R_GlobalEnv>
    
    print
    # function (x, ...) 
    # UseMethod("print")
    # <environment: namespace:base>
    
    counter_one
    # function() {
    #         # do something useful, then ...
    #         i <<- i + 1
    #         i
    #       }
    # <environment: 0x1022be7f0>
    

A more technical description is available in [Frames, Environments, and Scope in R and S-PLUS](http://cran.r-project.org/doc/contrib/Fox-Companion/appendix-scope.pdf). Section 2 is recommended as a good introduction to the formal vocabulary used in much of the R documentation. [Lexical scope and statistical computing](http://www.stat.auckland.ac.nz/~ihaka/downloads/lexical.pdf) gives more examples of the power and utility of closures.

## Higher-order functions

The power of closures is tightly connected to another important class of functions: higher-order functions (hofs), also known as functionals. HOFs are functions that take a function as an argument. These typically come from a mathematical or CS background.  In this section we will explore some of their properties and uses.

### List manipulation

* apply family of functions

* filter
* map
* find
* position
* reduce 

* negate


### Mathematical higher order functions

* find minimum/maximum/zero
* derivative

* integral: midpoint, trapezoid, Simpson's rule, Boole's rule: two functional inputs: function to derive, and rule to use for approximation 


### Statistical applications

* ecdf 
* maximum likelihood estimation


## List of functions

These components join together to make lists of functions surprisingly powerful.

Storing functions in lists is also useful for benchmarking, when you are comparing the performance of multiple different approaches to the same problem.  For example, if 

Using lapply etc. to generate lists of functions. Need helper function to actually call them elegantly.

    funs <- list(
      sum = sum,
      mean = mean,
      median = median
    )
    lapply(funs, function(x) x(1:10))

    callfun <- function(f, ...) f(...)
    lapply(funs, funcall, 1:10)

If we wanted to add parameters we have to duplicate a lot of code:

    funs2 <- list(
      sum = function(x, ...) sum(x, ..., na.rm = TRUE),
      mean = function(x, ...) mean(x, ..., na.rm = TRUE),
      median = function(x, ...) median(x, ..., na.rm = TRUE)
    )

How could we reduce this duplication?  A useful function here is `Curry` (named after a famous computer scientist Haskell Curry, not the food), which implements "partial function application".  What the curry function does is create a new function that passes on the arguments you specify.  A example will make this more clear:

    add <- function(x, y) x + y
    addOne <- funtion(x) add(x, 1)
    addOne <- Curry(add, y = 1)

A possible way to implement `Curry` is as follows:

    Curry <- function(FUN,...) { 
      .orig <- list(...)
      function(...) {
        args <- list(...)
        do.call(FUN, c(.orig, list(...)))
      }
    }

But implementing it like this prevents arguments from being lazily evaluated, so it has a somewhat more complicated implementation, basically working by building up an anonymous function by hand. You should be able to work out how this works after you've read the [[computing on the language]] chapter.  (Hopefully this function will be included in a future version of R.)

    Curry <- function(FUN, ...) {
      args <- match.call(expand.dots = FALSE)$...
      args$... <- as.name("...")
      
      env <- parent.frame()
      
      if (is.name(FUN)) {
        fname <- FUN
      } else if (is.character(FUN)) {
        fname <- as.name(FUN)
      } else if (is.function(FUN)){
        fname <- as.name("FUN")
        env$FUN <- FUN
      } else {
        stop("FUN not function or name of function")
      }
      curry_call <- as.call(c(list(fname), args))

      f <- eval(call("function", as.pairlist(alist(... = )), curry_call))
      environment(f) <- env
      f
    }

But back to our problem. With the `Curry` function we can reduce the code a bit:

    funs2 <- list(
      sum = Curry(sum, na.rm = TRUE),
      mean = Curry(mean, na.rm = TRUE),
      median = Curry(median, na.rm = TRUE)
    )

But if we look closely that will reveal we're just applying the same function to every element in a list, and that's the job of `lapply`. This drastically reduces the amount of code we need:

    funs2 <- lapply(funs, Curry, na.rm = TRUE)

Let's think about a similar, but subtly different case. Let's take a vector of numbers and generate a list of functions corresponding to trimmed means with that amount of trimming.  The following code doesn't work because we want the first argument of `Curry` to be fixed to mean.  We could try specifying the argument name because fixed matching overrides positional, but that doesn't work because the name of the function to call in `lapply` is also `FUN`.  And there's no way to specify we want to call the `trim` argument.

    trims <- seq(0, 0.9, length = 5) 
    lapply(trims, Curry, "mean")
    lapply(trims, Curry, FUN = "mean")

Instead we could use an anonymous function

    funs3 <- lapply(trims, function(t) Curry("mean", trim = t))
    lapply(funs3, funcall, c(1:100, (1:50) * 100))

But that doesn't work because each function gets a promise to evaluate `t`, and that promise isn't evaluated until all of the functions are run.  To make it work you need to manually force the evaluation of t:

    funs3 <- lapply(trims, function(t) {force(t); Curry("mean", trim = t)})
    lapply(funs3, funcall, c(1:100, (1:50) * 100))

A somewhat simpler solution in this case is to use `mapply` which is a special version of lapply which allows you call vary multiple arguments, not just the first one.

    funs3 <- mapply(Curry, "mean", trim = trims,
      SIMPLIFY = FALSE, USE.NAMES = FALSE)
    names(funs3) <- trims
    lapply(funs3, funcall, c(1:100, (1:50) * 100))

A similar is approach is to use `plyr::mlply`
    
    plyr::mlply(data.frame(FUN = "mean", trim = trims, stringsAsFactors = F), Curry)
    ldply(funs3, funcall, c(1:100, (1:50) * 100))
