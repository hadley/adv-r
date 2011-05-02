# First class functions

R supports "first class functions", functions that can be:

* created anonymously
* assigned to variables and stored in data structures
* returned from functions (closures)
* passed as arguments to other functions (higher-order functions)

This chapter explores these properties in more depth. You should be familiar with the basic properties of [[scoping and environments|Scoping]] before reading this chapter

## Anonymous functions

## List of functions

Using lapply etc. to generate lists of functions.

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

A more technical description is available in [Frames, Environments, and Scope in R and S-PLUS](http://cran.r-project.org/doc/contrib/Fox-Companion/appendix-scope.pdf). Section 2 is recommended as a good introduction to the formal vocabulary used in much of the R documentation. [Lexical scope and statistical computing](http://www.stat.auckland.ac.nz/~ihaka/downloads/lexical.pdf) gives more examples of the power and utility of closures.

## Higher-order functions

The power of closures is tightly connected to another important class of functions: higher-order functions (hofs), also known as functionals. HOFs are functions that take a function as an argument. These typically come from a mathematical or CS background.  In this section we will explore some of their properties and uses.

### List manipulation

* filter
* map
* find
* position
* reduce 

* negate

* apply family of functions

### Mathematical higher order functions

* find minimum/maximum/zero
* derivative

* integral: midpoint, trapezoid, Simpson's rule, Boole's rule: two functional inputs: function to derive, and rule to use for approximation 


### Statistical applications

* ecdf 
* maximum likelihood estimation

