# OO essentials

Central to any object-oriented system are the concepts of class and method. A __class__ defines a type of object, describing what properties it possesses, how it behaves, and how it relates to other types of objects. Every object must be an instance of some class. A __method__ is a function associated with a particular type of object.

R has four object oriented systems:

* __base__: implemented at C-level and switches between different types of base data structures. Not user extensible.

* __S3__, which implements a style of object oriented programming called generic-function OO. This is different to most programming languages, like Java, C++ and C#, which implement message-passing OO. In message-passing style, messages (methods) are sent to objects and the object determines which function to call. Typically this object has a special appearance in the method call, usually appearing before the name of the method/message: e.g. `canvas.drawRect("blue")`. S3 is different. While computations are still carried out via methods, a  special type of function called a __generic function__ decides which method to call, and calls look like `drawRect(canvas, "blue")`. S3 is a very casual system, and has no formal definition of classes.

* __S4__, which works simiarly to S3, but is more formal and more strict. There are two major differences to S3. S4 has formal class definitions, which describe the representation and inheritance for each class. S4 also has multiple dispatch, which means the generic function can be dispatched to a method based on the class of any number of arguments, not just one.

* __RefClasses__, sometimes called R5 for short, is quite different to S3 and S4. In ref classes, methods belong to classes (not functions, like in S3 and S4), and objects are mutable.  Ref classes implements message-passing OO, using `$` to separate object and method: `canvas$drawRect("blue")`, and are built on top of environments and S4.

This leads to four types of object in R: base objects (no OO), S3, S4 and ref classes. It's most important to understand what sort of object you have, and how method dispatch works for each type.

### Picking a system

Three OO systems is a lot for one language, but for most R programming, S3 suffices. In R you usually create fairly simple objects, and use OO programming to add special behaviour to generic functions like `print()`, `summary()` and `plot()`. S3 is well suited to this domain, and the majority of OO code that I have written in R is S3. S3 is also a little quirky, and relatively poorly documented elsewhere so this capture will focus on S3, only providing a broad overview of the details of S4 and reference classes. Once you have mastered S3, S4 is relatively easy to pickup - the ideas are all the same, it is just more formal, and more verbose. If you've programmed in another language, ref classes will be natural.

If you are creating more complicated systems of interrelated objects, S4 may be more appropriate. S4 is used extensively by Bioconductor. The `Matrix` package by Douglas Bates and Martin Maechler is another package for which S4 is particularly well suited. It is designed to efficiently store and compute with many different special types of sparse matrix. As at version 0.999375-50 it defines 130 classes and 24 generic functions. The package is well written, well commented and fairly easy to read. The accompanying [vignette](http://cran.r-project.org/web/packages/Matrix/vignettes/Intro2Matrix.pdf) gives a good overview of the structure of the package.

* [S4 system development in Bioconductor](http://www.bioconductor.org/help/course-materials/2010/AdvancedR/S4InBioconductor.pdf)

Reference classes differ from S3 and S4 in two important ways: 

These properties makes this object system behave much more like Java and C#. Surprisingly, the implementation of reference classes is almost entirely in R code - they are a combination of S4 methods and environments.

Note that when using reference based classes we want to minimise side effects, and use them only where mutable state is absolutely required. The majority of functions should still be "functional", and side effect free. This makes code easier to reason about (because you don't need to worry about methods changing things in surprising ways), and easier for other R programmers to understand.

## S3

### Object class

The class of an object is determined by its `class` attribute, a character vector of class names. The following example shows how to create an object of class `foo`: 

```R
x <- 1
attr(x, "class") <- "foo"
x

# Or in one line
x <- structure(1, class = "foo")
x
```

Class is stored as an attribute, but it's better to modify it using the `class()` function, since this communicates your intent more clearly:

```R
class(x) <- "foo"
class(x)
# [1] "foo"
```

You can use this approach to turn any object into an object of class "foo", whether it makes sense or not.

Objects are not limited to a single class, and can have many classes:

```R
class(x) <- c("A", "B")
class(x) <- LETTERS
```

As discussed in the next section, R looks for methods in the order in which they appear in the class vector. So in this example, it would be like class A inherits from class B - if a method isn't defined for A, it will fall back to B. However, if you switched the order of the classes, the opposite would be true! This is because S3 doesn't define any formal relationship between classes, or even any definition of what an individual class is. If you're coming from a strict environment like Java, this will seem pretty frightening (and it is!) but it does give your users a tremendous amount of freedom. While it's very difficult to stop someone from doing something you don't want them to do, your users will never be held back because there is something you haven't implemented yet.

### Creating a new class

Two basic ways to create an object in S3: with a list or with attributes.  With attributes is best if your object behaves like a vector, list if you're starting from scratch.

If you're creating a new class, it's customary to also provide a constructor function that checks that the inputs are of the correct type and then creates the object.

```R
myclass <- function(a, b) {
  stopifnot(is.numeric(a))
  stopifnot(is.character(b))

  structure(list(a = a, b = b), class = "myclass")
}

```

You should also provide a function that tests for your class:

```R
is.myclass <- function(x) inherits(x, "myclass")
```

### Generic functions and method dispatch

Method dispatch starts with a generic function that decides which specific method to dispatch to. Generic functions all have the same form: a call to `UseMethod` that specifies the generic name and the object to dispatch on. This means that generic functions are usually very simple, like `mean`:

```R
 mean <- function (x, ...) {
   UseMethod("mean", x)
 }
```

Methods are ordinary functions that use a special naming convention: `generic.class`:

```R
mean.numeric <- function(x, ...) sum(x) / length(x)
mean.data.frame <- function(x, ...) sapply(x, mean, ...)
mean.matrix <- function(x, ...) apply(x, 2, mean)
```

(These are somewhat simplified versions of the real code).  

As you might guess from this example, `UseMethod` uses the class of x to figure out which method to call. If `x` had more than one class, e.g. `c("foo","bar")`, `UseMethod` would look for `mean.foo` and if not found, it would then look for `mean.bar`. As a final fallback, `UseMethod` will look for a default method, `mean.default`, and if that doesn't exist it will raise an error. The same approach applies regardless of how many classes an object has:

```R
x <- structure(1, class = letters)
bar <- function(x) UseMethod("bar", x)
bar.z <- function(x) "z"
bar(x)
# [1] "z"
```

Once `UseMethod` has found the correct method, it's invoked in a special way. Rather than creating a new evaluation environment, it uses the environment of the current function call (the call to the generic), so any assignments or evaluations that were made before the call to UseMethod will be accessible to the method. The arguments that were used in the call to the generic are passed on to the method in the same order they were received.

Because methods are normal R functions, you can call them directly. However, you shouldn't do this because you lose the benefits of having a generic function:

```R
bar.x <- function(x) "x"
# You can call methods directly, but you shouldn't!
bar.x(x)
# [1] "x"
bar.z(x)
# [1] "z"
```

### Methods

To find out which classes a generic function has methods for, you can use the `methods` function. Remember, in R, that methods are associated with functions (not objects), so you pass in the name of the function, rather than the class, as you might expect:

```R
methods("bar")
# [1] bar.x bar.z
methods("t")
# [1] t.data.frame t.default    t.ts*       
# Non-visible functions are asterisked
```

Non-visible functions are functions that haven't been exported by a package, so you'll need to use the `getAnywhere` function to access them if you want to see the source.

### Internal generics

Some internal C functions are also generic, which means that the method dispatch is not performed by R function, but is instead performed by special C functions. It's important to know which functions are internally generic, so you can write methods for them, and so you're aware of the slight differences in method dispatch. It's not easy to tell if a function is internally generic, because it just looks like a typical call to a C:

```R
length <- function (x)  .Primitive("length")
cbind <- function (..., deparse.level = 1) 
  .Internal(cbind(deparse.level, ...))
```

As well as `length` and `cbind`, internal generic functions include `dim`, `c`, `as.character`, `names` and `rep`. A complete list can be found in the global variable `.S3PrimitiveGenerics`, and more details are given in `?InternalMethods`.

Internal generic have a slightly different dispatch mechanism to other generic functions: before trying the default method, they will also try dispatching on the __mode__ of an object, i.e. `mode(x)`. The following example shows the difference:

```R
x <- structure(as.list(1:10), class = "myclass")
length(x)
# [1] 10

mylength <- function(x) UseMethod("mylength", x)
mylength.list <- function(x) length(x)
mylength(x)
# Error in UseMethod("mylength", x) : 
#  no applicable method for 'mylength' applied to an object of class
#  "myclass"
```

### Inheritance

The `NextMethod` function provides a simple inheritance mechanism, using the fact that the class of an S3 object is a vector. This is very different behaviour to most other languages because it means that it's possible to have different inheritance hierarchies for different objects:

```R
baz <- function(x) UseMethod("baz", x)
baz.A <- function(x) "A"
baz.B <- function(x) "B"

ab <- structure(1, class = c("A", "B"))
ba <- structure(1, class = c("B", "A"))
baz(ab)
baz(ba)
```

`NextMethod()` works like `UseMethod` but instead of dispatching on the first element of the class vector, it will dispatch based on the second (or subsequent) element:

```R
baz.C <- function(x) c("C", NextMethod())
ca <- structure(1, class = c("C", "A"))
cb <- structure(1, class = c("C", "B"))
baz(ca)
baz(cb)
```

The exact details are a little tricky: `NextMethod` doesn't actually work with the class attribute of the object, it uses a global variable (`.Class`) to keep track of which class to call next. This means that manually changing the class of the object will have no impact on the inheritance:

```R
# Turn object into class A - doesn't work!
baz.D <- function(x) {
  class(x) <- "A"
  NextMethod()
}
da <- structure(1, class = c("D", "A"))
db <- structure(1, class = c("D", "B"))
baz(da)
baz(db)
```

Methods invoked as a result of a call to `NextMethod` behave as if they had been invoked from the previous method. The arguments to the inherited method are in the same order and have the same names as the call to the current method, and are therefore are the same as the call to the generic. However, the expressions for the arguments are the names of the corresponding formal arguments of the current method. Thus the arguments will have values that correspond to their value at the time NextMethod was invoked. Unevaluated arguments remain unevaluated. Missing arguments remain missing.

If `NextMethod` is called in a situation where there is no second class it will return an error. A selection of these errors are shown below so that you know what to look for.

```R
c <- structure(1, class = "C")
baz(c)
# Error in UseMethod("baz", x) : 
#   no applicable method for 'baz' applied to an object of class "C"
baz.c(c)
# Error in NextMethod() : generic function not specified
baz.c(1)
# Error in NextMethod() : object not specified
```

(Contents adapted from the [R language definition](http://cran.r-project.org/doc/manuals/R-lang.html#Object_002doriented-programming).  This document is licensed with the GPL-2 license.)

### Best practices

* When implementing a vector class, you should implement these methods: `length`, `[`, `[<-`, `[[`, `[[<-`, `c`.  (If `[` is implemented `rev`, `head`, and `tail` should all work). 

* When implementing anything mathematical, implement `Ops`, `Math` and `Summary`.

* When implementing a matrix/array class, you should implement these methods: `dim` (gets you nrow and ncol), `t`, `dimnames` (gets you rownames and colnames), `dimnames<-` (gets you colnames<-, rownames<-), `cbind`, `rbind`.

* If you're implementing more complicated `print()` methods, it's a better idea to implement `format()` methods that return a string, and then implement `print.class <- function(x, ...) cat(format(x, ...), "\n"`. This makes for methods that are much easier to compose, because the side-effects are isolated to a single place.


## S4

S3 and S4 basically work the same way.

Is a rigorous re-write of S3. Adds formal class, multiple inheritance and multiple dispatch. 

Useful for large problems. Used extensively by Bioconductor. No evidence that it will replace S3.

I use S3 95% of the time. Occassionally for more complicated problems I'll use S4. 

## RefClasses

Works like Java OO. Useful for truly mutable objects, e.g. GUIs or connecting to other programming languages. If you're coming from another programming language, this is likely to feel the most natural, but you will get more out of R if you understand why S3 and S4 work the way they do.

## What does a function call

How to find the code:

* Regular function (including ref class methods)
* S3 generic: `methods(f)`, `getS3method()`
* S4 generic: `showMethods(f)`, `findMethod()`
* Internal generic (may be S3 or S4): 
* Internal or primitive function: `names.c`

## What type of object?

```R
pryr::otype
a <- 1
b <- factor(letters)

setClass("C", contains = "list")
c <- new("C")
setRefClass("D")
d <- new("D")
```