# OO field guide

This chapter provides a field guide for recognising and working with R's objects in the wild. R has three object oriented systems (plus the base types), so it can be a bit intimidating. The goal of this guide is not to make you an expert in all four systems, but to help you identify what system you're working with, and ensure you know the basics of how it works.

Central to any object-oriented system are the concepts of class and method. A __class__ defines the behaviour of an __object__, describing the attributes that it possesses and how it relates to other classes. The class is also used when selecting __methods__, functions that behaviour differently depending on the class of their input. Classes are usually organised in a hierarchy: a parent class defines default behaviour not otherwise overriden by the child class.

R's three OO systems differ in how classes and methods are defined:

* __S3__ implements a style of OO programming called generic-function OO. This is different to most programming languages, like Java, C++ and C#, which implement message-passing OO. In message-passing style, messages (methods) are sent to objects and the object determines which function to call. Typically this object has a special appearance in the method call, usually appearing before the name of the method/message: e.g. `canvas.drawRect("blue")`. S3 is different. While computations are still carried out via methods, a  special type of function called a __generic function__ decides which method to call, and calls look like `drawRect(canvas, "blue")`. S3 is a very casual system, and has no formal definition of classes.

* __S4__ works simiarly to S3, but is more formal. There are two major differences to S3. S4 has formal class definitions, which describe the representation and inheritance for each class, and has special helper functions for defining generics and methods. S4 also has multiple dispatch, which means that generic functions can pick method based on the class of any number of arguments, not just one.

* __Reference classes__, called RC for short, are quite different to S3 and S4. RC implements message passing OO, so that methods belong to classes not functions. `$` is used to separate objects and method, so method calls look like `canvas$drawRect("blue")`. RC objects are also mutable: they don't use R's usual copy-on-modify semantics, and are modified in place. This makes them harder to reason about, but allows them to solve problems that are difficult to solve without mutability.

There's also one other system that's not quite OO, but it's important to mention here, and that's 

* __base types__, the internal C-level types that underlie the other OO systems. Base types distinguish between 

The following sections describes each system in turn, starting with base types. You'll learn how to recognise the OO system that an object belongs to, how method dispatch works, and how to create new objects, classes, generics and methods for that system. 

## Base types

Underlying every R object is a C "struct" that describes how the object is stored in memory. The struct includes the contents of the object, information needed for memory management, and most importantly for this section, a __type__.  This is the __base type__ of an R object. Base types are not really an object system, because only R core can create new types and every new type makes base R a little more complicated. New base types are added very rarely: the most recent change in 2011 was to add two exotic types that you never see in R, but are useful for diagnosing memory problems (`NEWSXP` and `FREESXP`). Before that the last change was made in 2005, where a special base type for S4 objects (`S4SXP`) was added. 

[[Data structures]] explained the most common base types (atomic vectors and lists), but base types also encompass functions, environments and other more exotic objects that you'll learn about later in the book, likes names, calls and promises. You can find out the the base type of an object with `typeof()`, or see a complete list of types in `?typeof()`. Beware that the names of base types are are not used consistently throughout R: the type, and the corresponding "is" function may have different names. 

```R
# The type of a function is "closure", and the
# type of a primitive function is "builtin"
f <- function() {}
typeof(f)
is.function(f)

typeof(sum)
is.primitive(sum)
```

Another option is `pryr::typename()` which returns the type name used in C code. You can find out more about these types in [[C-interface]]. You may have also heard of `mode()` and `storage.mode()`. I recommend ignoring them: they just alias some of the names returned by `typeof()` for S compatibility. Read their sources to see exactly what they do.

Functions that behave differently for different base types are almost always written in C, where dispatch occurs using switch statements (`switch(TYPEOF(x))`). Even if you never write C code, it's important to understand base types because everything else is built on top of them: S3 objects can be built on top of any base type, S4 objects use a special base type, and RC objects are a combination of S4 and environments (another base type). To figure out if an object is a pure primitive type (i.e. doesn't also have S3, S4 or RC behaviour), use `is.object()` - it will return `FALSE` for primitive objects.

## S3

S3 is R's first and simplest OO system. It is the only OO system used in the base and stats packages, and it's the most commonly used system in packages. S3 is informal and adhoc, but it has a certain elegance in it's minimalism: it does the bare minimum necessary for a useful OO system.

### Recognising objects, generic functions and methods

Most objects that you encounter are probably S3 objects. You can check by testing that it's an object (`is.object(x)`) but it's not S4 (`!isS4(x)`). This check is automated by `pryr::otype()`, which provides an easy way to determine the OO system of an object:

```R
library(pryr)

df <- data.frame(x = 1:10, y = letters[1:10])
otype(df)    # A data frame is an S3 class
otype(df$x)  # A numeric vector isn't
otype(df$y)  # A factor is
```

In S3, methods are associated with functions, called __generic functions__, or generics for short, not objects or classes. This is different from most other programming languages, but is a legimitate OO style. To determine if a function is an S3 generic function, you can look at its source code for a call to `UseMethod()`. It's the job of `UseMethod()` to find the correct method and call it: this is called __method dispatch__.

```R
mean
```

Some S3 generic functions don't call `UseMethod()`. For example, the following three functions are also S3 generics:

```R
`[`
sum
cbind
```

These functions are implemented in C, and hence can't call `UseMethod()`. Instead they call the C functions `DispatchGroup()` or `DispatchOrEval()`. Functions that do method dispatch in C code are called __internal generics__ and are documented in `?"internal generic"`. Instead of reading the source code to determine if a function is an internal generic, you can use `pryr::ftype()`:

```R
ftype(mean)
ftype(`[`)
ftype(sum)
ftype(cbind)
```

S3 methods use a special naming scheme: `generic.class`. For example, the Date method for the `mean()` generic is called `mean.Date()`, and the factor method for `print()` is called `print.factor()`. Most modern style guides discourage the use of `.` in function names because it makes them look like S3 methods. For example, is `t.test()` the `test` method for `t` objects? Similarly, the use of `.` in class names can also be confusing: is `print.data.frame()` the `print()` method for `data.frames`, or the `print.data()` method for `frames`?

`pryr::ftype()` knows about these exceptions, so you can use it to figure out if a function is an S3 method or generic:

```R
ftype(t.data.frame) # data frame method for t()
ftype(t.test)       # generic function for t tests

ftype(is.numeric)   # naming convention for testing and coercion
ftype(as.numeric)   # there are no S3 generics for is and as
```

You can see all the methods of a generic using the `methods()` function:

```R
methods("mean")
methods("t")
```

You can also list all generics that have a method for a given class:

```R
methods(class = "ts")
```

There's no way to get a list of all S3 classes, because there's no central repository of them, as you'll learn in the following section.

### Defining classes and creating objects

S3 is a simple and adhoc system: there is no formal definition of a class. To make an object an instance of a class, you just take an existing base object and set the class attribute. You can do that during creation with `structure()`, or after the fact with `attr<-()`.  However, if you're modifying an existing object, it's better to use `class()` since this communicates your intent more clearly. 

```R
# Create and assign class in one step
foo <- structure(list(), class = "foo")

# Create, then set class
foo <- list()
class(foo) <- "foo"
```

S3 objects are usually built on top of lists, or atomic vectors with other attributes. You can also turn functions in to S3 objects. Other base types are either rarely seen in R, or have unusual semantics that don't work well with attributes - but you can always wrap the object in a list, and set the class of the list.

You can determine the class of any object using `class(x)`, and see if an object inherits from a specific class using `inherits(x, "classname")`.  The class of an S3 object can be a vector, which describes behaviour from most specific to least specific. For example, the class of the `glm()` object is `c("glm", "lm")` indicating that generalised linear models inherit behaviour from linear models. Class names are usually lower case, and you should avoid `.`. Otherwise, opinion is mixed whether to use underscores (`my_class`) or upper camel case (`MyClass`) for multiword class names.

Most S3 classes provide a constructor function:

```R
foo <- function(x) {
  structure(list(x), class = "foo")
}
```

and you should use it if it's available (like for `factor()` and `data.frame()`). This ensures that you're creating the class with the correct components. The convention is that constructor functions have the same name as the class.

Apart from developer supplied constructor functions, S3 has no checks for correctness. This means you can change the class of existing objects:

```R
# Create a linear model
mod <- lm(log(mpg) ~ log(disp), data = mtcars)
class(mod)

# Turn it into a table (?!)
class(mod) <- "table"
# But unsurprisingly this doesn't work very well
print(mod)
```

If you've used other OO languages, this might make you feel queasy. But surprisingly, this flexibility causes few problems: while you _can_ change the type of an object, you never should. R doesn't protect you from yourself: you can easily shoot yourself in the foot, but if you don't aim the gun at your foot and pull the trigger, you won't have a problem.

### Creating new methods and generics

To add a new generic, create a function that calls `UseMethod()`. `UseMethod()` takes two arguments: the name of the generic function, and the argument to use for method dispatch. If you omit the second argument it will dispatch on the first argument to the function.

```R
f <- function(x) UseMethod("f")
```

A generic isn't useful without some methods. An S3 method is just a regular function name with the `generic.class` naming convention:

```R
f.a <- function(x) "Class a"

a <- structure(list(), class = "a")
f(a)
```

Adding a method to an existing generic works in the same way:

```R
mean.a <- function(x) "a"
mean(a)
```

As you can see, there's no check to make sure that the method returns a class compatible with the generic. However, while you can do this, you shouldn't, as it will violate the expectations of existing code.

### Method dispatch

S3 method dispatch is relatively simple. S3 generics look at the class of one argument, usually the first. If `x` has more than one class, e.g. `c("foo", "bar")`, `UseMethod()` would look for `mean.foo()` and if not found, it would then look for `mean.bar()`. As a final fallback, `UseMethod` will look for a default method, `mean.default()`, and if that doesn't exist it will raise an error. The same approach applies regardless of how many classes an object has:

```R
# An object with 26 classes, from "a" to "z"
z <- structure(list(), class = letters)
bar <- function(x) UseMethod("bar", x)
bar.z <- function(x) "z"
bar(z)
```

There is one more complication: the group generics, Math, Ops, Complex and Summary. These generics make it possible to define the behaviour of multiple methods simultaneously. They are a relatively advanced feature typically used in conjunction with `NextMethod()`, the syntax for calling the parent method directly. You can read about the details in `?groupGeneric` and `?NextMethod`

Because methods are normal R functions, you can call them directly. However, this is just as dangerous as changing the class of an object, so you shouldn't do it: please don't point the loaded gun at your foot! (The only reason to call the method directly is that sometimes when you're writing OO code, not using someone else's, you can get considerable speedups by skipping regular method dispatch).

```R
bar.x <- function(x) "x"
# You can call methods directly, but you shouldn't!
bar.x(z)
# [1] "x"
```

You can also call an S3 generics with a non-S3 object. Non-internal S3 generics will dispatch on the __implicit class__ of base types. (Internal generics don't do that for performance reasons.) The rules to determine the implicit class of a primitive type are somewhat complex, but are shown in the function below:

```R
iclass <- function(x) {
  if (is.object(x)) stop("x is not a primitive type", call. = FALSE)

  c(
    if (is.matrix(x)) "matrix",
    if (is.array(x) && !is.matrix(x)) "array",
    if (is.double(x)) "double",
    if (is.integer(x)) "integer",
    mode(x)
  )
}
iclass(matrix(1:5))
iclass(array(1.5))
```

### Exercises

* R has two classes for representing date time data, `POSIXct` and `POSIXlt` which both inherit from `POSIXt`. Which generics have different behaviour for the two classes? Which generics share the same behaviour?

* Which generic defined in the base package has the most methods defined for it?

* `UseMethod()` calls methods in a special way. Predict what the following code will return, then run it and read the help for `UseMethod()` to figure out what's going on. Write down the rules in the simplest form possible.

    ```R
    y <- 1
    g <- function(x) { 
      y <- 2
      UseMethod("g")
    }
    g.numeric <- function(x) y
    g(10)

    h <- function(x) {
      x <- 10
      UseMethod("h")
    }
    h.character <- function(x) paste("char", x)
    h.numeric <- function(x) paste("num", x)

    h("a")
    ```

* Internal generics don't dispatch on the implicit class of base types. Carefully read `?"internal generic"` to determine why the length of `f` and `g` is different in the example below. What function helps distinguish between the behaviour of `f` and `g`?

    ```R
    f <- function() 1
    g <- function() 2
    class(g) <- "function"
    class(f)
    class(g)

    length.function <- function(x) "function"

    length(f)
    length(g)
    ```

## S4

S4 works in a similar way to S3, but it is formal and rigorous. Methods still belong to functions, not classes, but:

* Classes have a formal definition, describing their fields and inheritance structure (parent classes).

* Method dispatch can be based on multiple arguments to a generic function, not just one.

* There is a specific operator, `@`, for extracting fields out of an S4 object.

All S4 related code is stored in the methods package. This package is always available when you're running R interactively, but is not always loaded automatically when running R from the command line. For this reason, it's a good idea to include an explicit `library(methods)` whenever you're using S4.

S4 is a rich and complex system, and there's no way to explain it fully in a few pages. Here I'll focus on the key ideas underlying S4 so that you can use existing S4 objects effectively. To learn more, some good references are:

* [S4 system development in Bioconductor](http://www.bioconductor.org/help/course-materials/2010/AdvancedR/S4InBioconductor.pdf)

* [Software for data analysis](http://amzn.com/0387759352?tag=devtools-20)

### Recognising objects, generic functions and methods

Recognising S4 objects, generics and methods is easy. You can identify an S4 object because `str()` describes it as a "formal" class, `isS4()` is true, and `pryr::otype()` returns "S4". S4 generics and methods are also easy to identify because they are S4 objects with well defined classes.

There aren't any S4 classes in the commonly used base packages (stats, graphics, utils, datasets, and base), so we'll start by creating an S4 object from the built-in stats4 package, which provides some S4 classes and methods associated with maximum likelihood estimation:

```R
library(stats4)

# From example(mle)
y <- c(26, 17, 13, 12, 20, 5, 9, 8, 5, 4, 8)
nLL <- function(lambda) -sum(dpois(y, lambda, log = TRUE))
fit <- mle(nLL, start = list(lambda = 5), nobs = length(y))

isS4(fit)
otype(fit)

isS4(nobs)
ftype(nobs)

# Retrieve an S4 method, described later
mle_nobs <- method_from_call(nobs(fit))
isS4(mle_nobs)
ftype(mle_nobs)
```

You can determine the class of an S4 object with `class()` and test if an object inherits from a specific class with `is()`:

```R
class(fit)
is(fit, "mle")
```

You can get a list of all S4 generics with `getGenerics()`, and all S4 classes with `getClasses()`, but note that this list includes shim classes for S3 classes and base types. Different packages may define different classes with the same name, so functions that list generics, classes or methods will also say which package they're defined in. You can list all S4 methods with `showMethods()`, optionally restricting either by generic or by class (or both).  It's also a good idea to supply `where = search()` to restrict to methods defined by attached packages, not by packages loaded by attached packages. 

### Defining classes and creating objects

In S3, you can turn any object into an object of a particular class just by setting the class attribute.  S4 is much stricter: you must define the representation of the call using `setClass()`, and the only way to create it is through the constructer function `new()`. An S4 class has three key properties:

* a __name__: an alpha-numeric string that identifies the class

* a named list of __slots__ (fields), providing slot names and 
  permitted classes. For example, a person class might be represented by a character name and a numeric age: 
  `list(name = "character", age = "numeric")`

* a string giving the class it inherits from, or in S4 terminology, 
  __contains__. You can provide multiple classes to get multiple 
  inheritance, but this is best avoided because it's 

The representation and contains classes can S4 classes, S3 classes registered with `setOldClass()`, or the the implicit class of a base type. You can also use the special class "ANY" which allows any type as input.

The following example creates a Person class with fields name and age, and an Employee class that inherits from person. The Employee class inherits the slots and methods from the Person, and adds an additional slot, boss.

```R
setClass("Person", 
  slots = list(name = "character", age = "numeric"))
setClass("Employee", 
  slots = list(boss = "Person"), 
  contains = "Person")

john <- new("Person", name = "John", age = 40)
```

You can find the documentation for a class with a special help syntax: `class?className`, e.g. `class?mle`. Most S4 classes also come with a constructor function with the same name as the class - if that exists, use it instead of calling `new()` directly. 

Unlike S3 objects, which can be built on top of any base type, S4 objects are all built on top of a special S4 type. To access slots of an S4 object you use `@` or `slot()`:

```R
hadley@age
slot(hadley, "age")
```

If an S4 object contains (inherits) from an S3 class or a base type, you can get the value of that object using the special `.Data` slot. This is equivalent to `unclass()`ing an S3 object to get at the underlying base type.

```R
setClass("minmax", 
  contains = "numeric", 
  slots = list(min = "numeric", max = "numeric"))
mm <- new("minmax", 1:10, min = 1, max = 10)
mm@min
mm@.Data
```

S4 classes have two other important optional properties, a __validity method__ which tests to see if the values of an object are valid, and a __prototype__ object, which defines default values for fields not supplied when `new()` is called.  See `?setClass` for more details.

Since R is an interactive programming language, it's possible to create new classes or redefine existing classes at any time. This can be a problem when you're interactively experimenting with S4. If you modify a class, make sure you also recreate any objects of that class you'll end up with invalid or out-of-date objects. 

### Creating new methods and generics

S4 provides special functions for creating new generics and methods. `setGeneric()` allows you to create a new generic, or turn an existing function into a generic. `setMethod()` takes the name of the generic, a specification for the classes and a function.

For example, we could take `union()`, which usually just works on vectors, and make it work with data frames:

```R
setGeneric("union")
setMethod("union", c(x = "data.frame", y = "data.frame"), function(x, y) {
  unique(rbind(x, y))
})
```

If you create a new generic from scratch, the function needs to call `standardGeneric`:

```R
setGeneric("myGeneric", function(x) {
  standardGeneric("myGeneric")
})
```

### Method dispatch

S4 method dispatch is the same as S3 dispatch if your classes only inherit from a single parent, and you only dispatch on one class. The main difference is how you set up default values: S4 uses the special classes "ANY" match any class and "missing" to match a missing argument. Things get more considerably more complicated when you dispatch on multiple arguments, or you have multiple parents. The rules are described in `?Methods`, but when I've created more complicated class inheritance graphs I've found it very difficult to predict which method will be called. I strongly recommend you avoid multiple inheritance in S4.

Instead of trying to figure it out yourself, you can use an existing R function:

*  `pryr::method_from_call()` takes an unevaluated function call: `method_from_call(nobs(fit))`

* `selectMethod()` takes the name of the generic and a named vector of class names: `selectMethod("nobs", "mle4")`

You can call the parent method directly with `callNextMethod()`

### Exercises

* Which S4 generic has the most methods defined for it? Which S4 class has the most methods associated with it?

## RC

Reference classes (or RC for short) are new in R 2.12. They are fundamentally different to S3 and S4 because:

* RC methods belong to objects, not functions.

* RC objects are mutable: the usual R copy on modify semantics do not apply

These properties make RC behave more like the style of OO found in most other programming languages like python, ruby, java and C#.Surprisingly, reference classes are implemented in R, not code: they are special S4 class that wraps around an environment.

### Recognising objects and methods

You can recognise RC objects because they are S4 classes (`isS4(x)`) that inherit from "refClass" (`is(x, "refClass")`).

### Defining classes and creating objects

Creating a new reference based class is straightforward: you use `setRefClass()`. While you can use `new()` to create new reference classes, it's good style to use the object returned by `setRefClass()` to generate new objects:

```R
Person <- setRefClass("Person")
Person$new()
```

A reference class has four main components, given by three arguments to `setRefClass`:

* a __name__: an alpha-numeric string that identifies the class

  ```R
  setRefClass("Distribution")
  ```

* the class which __contains__ or inherits. This should be the name
  of another references class.  (Again, like S4 reference classes
  can inherit from multiple parents, but it's not a good idea.)

  ```R
  DistributionUniform <- setRefClass("DistributionUniform", 
    contains = "Distribution")
  ```

* the __fields__, which are equivalent to slots in S4, and should 
  be a named list:

  ```R
  DistributionUniform <- setRefClass("DistributionUniform", 
    contains = "Distribution",
    fields = list(a = "numeric", b = "numeric"))
  ```

  Note that RC objects are __mutable__, i.e. they have reference semantics, and are not copied-on-modify:
  
  ```R
  a <- DistributionUniform(a = 0, b = 1)
  b <- a

  b$a <- 10
  a$a
  ```

* a set of __methods__, functions that operate within the context of 
  the object and can modify its fields. These can also be added 
  after object creation, as described below.

  ```R
  DistributionUniform <- setRefClass("DistributionUniform", 
    contains = "Distribution",
    fields = list(a = "numeric", b = "numeric"),
    methods = list(
      mean = function() (a + b) / 2
    )
  ) 
  a <- DistributionUniform(a = 0, b = 1)
  a$mean()
  ```

### Method dispatch

RC methods are associated with objects, not with functions, and are called using the special syntax `obj$method(arg1, arg2, ...)`. Method dispatch is straightforward: if the method is not found for the base class, then the parent is tried, and so on up.

You can call the parent method directly with `$callSuper(...)`

## Picking a system

Three OO systems is a lot for one language, but for most R programming, S3 suffices. In R you usually create fairly simple objects, and use OO programming to add special behaviour to generic functions like `print()`, `summary()` and `plot()`. S3 is well suited to this domain, and the majority of OO code that I have written in R is S3. S3 is a little quirky, but once you've mastered it S4 is relatively easy to pickup: the ideas are all the same, it is just more formal, more strict and more verbose. 

If you are creating more complicated systems of interrelated objects, S4 may be more appropriate. S4 is used extensively by Bioconductor. The `Matrix` package by Douglas Bates and Martin Maechler is another package for which S4 is particularly well suited. It is designed to efficiently store and compute with many different special types of sparse matrix. As at version 0.999375-50 it defines 130 classes and 24 generic functions. The package is well written, well commented and fairly easy to read. The accompanying [vignette](http://cran.r-project.org/web/packages/Matrix/vignettes/Intro2Matrix.pdf) gives a good overview of the structure of the package.

If you've programmed in another language, ref classes will be natural. But because they introduce side-effects through mutable state, they can be much harder to reason about. Note that when using reference based classes we want to minimise side effects, and use them only where mutable state is absolutely required. The majority of functions should still be "functional", and side effect free. This makes code easier to reason about (because you don't need to worry about methods changing things in surprising ways), and easier for other R programmers to understand.
