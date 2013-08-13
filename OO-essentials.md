# OO field guide

This chapter provides a field guide for recognising and working with R's objects in the wild. R has three object oriented systems (plus the base data structures), so it can be a bit intimidating. The goal of this guide is not to make you an expert in all three systems, but to help you identify what system you're working with, and ensure you know the basics of that system. The systems are organised by their abundance in the wild.

Central to any object-oriented system are the concepts of class and method. A __class__ defines the bevahiour of an __object__, describing the data fields that it possesses, function calls that are specialised for it , and how it relates to other classes. Every object must be an instance of some class. A __method__ is a function associated with a particular type of object.  Classes are usually organised in a hierarchy: a parent class, defines default behaviour not otherwise overriden by the child class.

R's three OO systems differ in how objects and methods are defined:

* __S3__, which implements a style of object oriented programming called generic-function OO. This is different to most programming languages, like Java, C++ and C#, which implement message-passing OO. In message-passing style, messages (methods) are sent to objects and the object determines which function to call. Typically this object has a special appearance in the method call, usually appearing before the name of the method/message: e.g. `canvas.drawRect("blue")`. S3 is different. While computations are still carried out via methods, a  special type of function called a __generic function__ decides which method to call, and calls look like `drawRect(canvas, "blue")`. S3 is a very casual system, and has no formal definition of classes.

* __S4__, which works simiarly to S3, but is more formal and more strict. There are two major differences to S3. S4 has formal class definitions, which describe the representation and inheritance for each class. S4 also has multiple dispatch, which means the generic function can be dispatched to a method based on the class of any number of arguments, not just one.

* __RefClasses__, sometimes called R5 for short, is quite different to S3 and S4. In ref classes, methods belong to classes (not functions, like in S3 and S4), and objects are mutable.  Ref classes implements message-passing OO, using `$` to separate object and method: `canvas$drawRect("blue")`, and are built on top of environments and S4.

There's also one other system that's not quite OO, but it's important to mention here, and that's 

* __primitive__: implemented at C-level and switches between different types of base data structures. Not user extensible. This is basically equivalent to writing an R function that uses `switch(typeof(x))`. 

This leads to four types of object in R: base objects (no OO), S3, S4 and ref classes. It's most important to understand what sort of object you have, and how method dispatch works for each type.

## Primitive types

We discussed base objects are discussed in [[data structures]].  Only R core can create new types of base object, and they do this very very rarely. 

Everything else is built on top of this system: S3 objects are primitive objects with a special attributes, S4 objects are a special type of primitive object, and RC objects are a combination of S4 and environments (another primitive type). 

In R code you can get the primitive type using `typeof()`, but the names are used terribly consistently through the documentation (and in the names of `is.*()` functions - for example `is.numeric()` doesn't test only for numeric type.) An alternative is `pryr::typename()` which returns the type name used in C code.  You can find out more about these types in [[C-interface]].

Primitive dispatch is written in C code, and it looks like

```R
switch(TYPEOF(a)) {
  case LGLSXP:
    ...
    break
  case INTSXP:
    ...
    break
  default:
    ...
}
```

## S3

S3 is R's first and most simple OO system. Its age means it's the only OO system used in the base and stats packages, and its simplicity means that it's the most commonly used system in packages.

### Recognising objects, generic functions and methods

Most objects you encounter in R are likely to be S3 objects. Unfortunately, you can only confirm that by process of elimination: S3 objects have a class attribute (`attr(x, "class")`) but are not S4 objects (`!isS4(x)`). This check is automated by `pryr::otype()`, which provides an easy way to determine the OO system of an object:

```R
library(pryr)

df <- data.frame(x = 1:10, y = letters[1:10])
otype(df)    # A data frame is an S3 class
otype(df$x)  # A numeric vector isn't
otype(df$y)  # A factor is
```

In S3, methods are associated with functions, called generics, not objects or classes. This is different from most other programming languages, but is a legimitate OO style. 

To determine if a function is an S3 generic function, you can look at its source code for a call to `UseMethod()`:

```R
mean
```

It's the job of `UseMethod()` to find the correct method (given the input) and call it. There are also some S3 generic functions don't call `UseMethod()`. For example, the following three functions are also S3 generics:

```R
`[`
sum
cbind
```

These functions are implemented in C (instead of R) and do their S3 dispatch in C code. If you looked at the C source code for these functions you'd see a call to `DispatchGroup` or `DispatchOrEval`. You can also figure out if a function is an S3 generic without reading C code by using `pryr::ftype()`:

```R
ftype(`[`)
ftype(sum)
ftype(cbind)
```

Functions where method dispatch is handled in C code are called "internal generics" and you can read more about them in the documentation, `?"internal generic"`.

S3 methods use a special naming scheme: `generic.class`. For example, the mean method for Date objects is called `mean.Date`, and the print method for factors is called `print.frame`. This is the reason that modern style guides discourage the use of `.` in function names: it makes them look like S3 methods. For example, is `t.test` the `test` method for `t`? Similarly, the use of `.` in class names can also be confusing: is `print.data.frame` the `print` method for `data.frames`, or the `print.data` method for `frames`?

`pryr::ftype()` knows all about these exceptions, so you can use it to reliably figure out if a function is an S3 method or generic:

```R
ftype(t.test)       # generic function for t tests
ftype(t.data.frame) # data frame method for t()

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

S3 is a simple and adhoc system: there is no formal definition of a class. To make an object an instance of a class, you just take an existing primitive object and set the class attribute. You can do that with `attr()`, `class()`, or during creation of the object with `structure()`:

```R
foo <- list()
attr(foo, "class") <- "foo"
class(foo) <- "foo"

foo <- structure(list(), class = "foo")
```

You can do this for any object described in [[data-strutures]] and for functions. More exotic objects (like symbols and environments) will need to be wrapped in a list.

While class is stored as an attribute, it's better to modify it using the `class()` function, since this communicates your intent more clearly. 

Most S3 classes will provide a constructor function:

```R
foo <- function(x) {
  structure(list(x), class = "foo")
}
```

If a constructor exists for the class, like it does for `factor()` and `data.frame()`, you should use it. This ensures that you're creating the class with the correct components. The convention is that constructor functions have the same name as the class, which is usually lower case. As mentioned above, it's a good idea to avoid using `.` in function names to avoid confusion; otherwise opinion is mixed whether to use underscores or camel case for multiword class names.

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

If you've used other object oriented languages, this probably makes you feel queasy. But surprisingly, this flexibility causes few problems: while you _can_ change the type of an object, you never should. R doesn't protect you from yourself: you can easily shoot yourself in the foot, but if you don't aim the gun at your foot and pull the trigger, you won't have a problem.

You can determine the class of any object using `class(x)`, and check if an object inherits from a specific class using `inherits(x, "classname")`.  The class of an S3 object can be a vector, which describes behaviour from most specific to least specific. For example, the class of the `glm()` object is `c("glm", "lm")` indicating that it inherits behaviour from `"lm"`.

### Creating new methods and generics

### Method dispatch

Method dispatch in S3 is relatively simple. S3 generics look at the class of one argument, usually the first (if not, it will be listed as the second argument to `UseMethod()`). If `x` has more than one class, e.g. `c("foo","bar")`, `UseMethod` would look for `mean.foo` and if not found, it would then look for `mean.bar`. As a final fallback, `UseMethod` will look for a default method, `mean.default`, and if that doesn't exist it will raise an error. The same approach applies regardless of how many classes an object has:

```R
# An object with 26 classes, from "a" to "z"
z <- structure(1, class = letters)
bar <- function(x) UseMethod("bar", x)
bar.z <- function(x) "z"
bar(z)
```

Once `UseMethod` has found the correct method, it's invoked in a special way. Rather than creating a new evaluation environment, it uses the environment of the current function call (the call to the generic), so any assignments or evaluations that were made before the call to UseMethod will be accessible to the method. The arguments that were used in the call to the generic are passed on to the method in the same order they were received.

Because methods are normal R functions, you can call them directly. However, this is just as dangerous as changing the class of an object so you shouldn't do it: please don't point the loaded gun at your foot!

```R
bar.x <- function(x) "x"
# You can call methods directly, but you shouldn't!
bar.x(z)
# [1] "x"
```

(The only exception is when you're writing OO code, not using someone else's, sometimes you can get considerably performance improvements by skipping regular method lookup and directly calling the correct method)

## S4

S4 works in a similar way to S3, but it is more formal and rigorous. Methods still belong to functions, not classes, but:

* Classes have a formal definition, describing their fields and inheritance structure (parent classes).

* Method dispatch can be based on multiple arguments to a generic function, not just one.

* There is a specific operator, `@`, for extracting fields out of an S4 object.

There aren't any S4 classes in the commonly used base packages (stats, graphics, utils, datasets, and base), so we'll start by creating an S4 object from the built-in stats4 package, which provides some S4 classes and methods associated with maximum likelihood estimation:

```R
library(stats4)

# From example(mle)
y <- c(26, 17, 13, 12, 20, 5, 9, 8, 5, 4, 8)
nLL <- function(lambda) -sum(dpois(y, lambda, log = TRUE))
fit <- mle(nLL, start = list(lambda = 5), nobs = length(y))
```

Most S4 related functions have global effects.

### Recognising objects, generic functions and methods

Recognising S4 objects, generics and methods is easy. You can identify an S4 object because `str()` describes it as a "formal" class, `isS4()` is true, and `pryr::otype()` returns "S4". S4 generics and methods are also easy to identify because they are S4 objects with well defined classes:

```R
isS4(fit)
class(fit)
otype(fit)

isS4(nobs)
class(nobs)
ftype(nobs)

# Retrieve an S4 method
mle_nobs <- method_from_call(nobs(fit))
isS4(mle_nobs)
class(mle_nobs)
ftype(mle_nobs)
```

In source code, you can recognise the creation of S4 classes, generics and methods by the use of `setClass()`, `setGeneric()` and `setMethod()` respectively.  If a function already exists, `setGeneric()` will turn it into a S4 generic, preserving an existing behaviour: most packages that use S4 well convert existing generics into S4 generics in this way.

You can get a list of all S4 generics with `getGenerics()`. Similarly, you can see all classes with `getClasses()`, but note that this list includes shim classes for some S3 and primitive classes. Also note that different packages may define different classes with the same name, so functions that list generics, classes or methods will also say which package they're defined in.

You can list all S4 methods with `showMethods()`, optionally restricting either by generic or by class (or both).  It's also a good idea to supply `where = search()` to restrict to methods defined by attached packages, not all packages loaded by other packages. 

### Defining classes and creating objects

In S3, you can turn any object into an object of a particular class just by setting the class attribute.  S4 is much stricter: you must define the representation of the call using `setClass()`, and the only way to create it is through the constructer function `new()`.

An S4 class has three key properties:

* a __name__: an alpha-numeric string that identifies the class

* __representation__: a list of __slots__ (fields), giving
  their names and classes. For example, a person class might be represented by a character name and a numeric age, as follows: 
  `representation(name = "character", age = "numeric")`

* a character vector of classes that it inherits from, or in 
  S4 terminology, __contains__. You can also use basic classes like `numeric`, `character` and `matrix`. A matrix of (e.g.) characters will have class `matrix` - even though a matrix is not an S3 class. You can also dispatch on S3 classes provided that you have made S4 aware of them by calling `setOldClass`. 

You create a class with `setClass()` and create an instance of a class with `new()`

```R
setClass("Person", 
  representation(name = "character", age = "numeric"))
setClass("Employee", 
  representation(boss = "Person"), contains = "Person")

hadley <- new("Person", name = "Hadley", age = 33)
```

You can find the documentation for a class with `class?className`: compare `class?mle` to `?mle`. Most S4 classes also come with a constructor function with the same name as the class - if that exists, use it instead of calling `new()` directly. 

Unlike S3 objects, which can be built on top of any primitive type, S4 objects are all built on top of a special S4 type. To access slots of an S4 object you use `@` or `slot()`:

```R
hadley@age
slot(hadley, "age")
```

If an S4 object contains (inherits) from another primitive, S3, or S4 class, you can get that object using the special `.Data` slot. This is equivalent to `unclass()`ing an S3 object.

S4 classes have two other optional defined properties, a __validity method__ which tests to see if the values of an object are valid, and a __prototype__ object, which defines default values for fields not supplied when `new()` is called.

Note that there's some tension between the usual interactive functional style of R and the global side-effect causing S4 class definitions. In most programming languages, class definition occurs at compile-time, while object instantiation occurs at run-time - it's unusual to be able to create new classes interactively. In particular, note that the examples rely on the fact that multiple calls to `setClass` with the same class name will silently override the previous definition unless the first definition is sealed with `sealed = TRUE`. 

```R
setClass("A", list(x = "numeric"))
a1 <- new("A", x = 1:10)

setClass("A", list(x = "character"))
a2 <- new("A", x = "a")
```

This can be a problem when you're interactively experimenting: make sure to recreate objects whenever you modify a class, otherwise you'll end up with invalid or out-of-date objects. 

### Creating new methods and generics

### Method dispatch

S4 method dispatch is the same as S3 dispatch if your classes only inherit from a single parent, and you only dispatch on one class. The main difference is how you set up default values: S4 uses the special classes "ANY" and "missing" to match any class, or a missing value respectively.

Things get more complicated when you dispatch on multiple arguments, or you have multiple parents. It's not important to know all the details, but you should understand the broad picture so that you have some ability to predict what method will get called. More details can be found in `?Methods` and in [Software for data analysis](http://amzn.com/0387759352?tag=hadlwick-20).

As well as understanding the principles yourself, there are two functions which will tell you exactly which method will get called:

*  `pryr::method_from_call()` takes an unevaluated function call: `method_from_call(nobs(fit))`

* `selectMethod()` takes the name of the generic and a named vector of class names: `selectMethod("nobs", "mle4")`

To make the ideas in this section concrete, we'll create a simple class structure. We have three classes, C which inherits from a character vector, B inherits from C and A inherits from B. We then instantiate an object from each class.

```R
setClass("C", contains = "character")
setClass("B", contains = "C")
setClass("A", contains = "B")

a <- new("A", "a")
b <- new("B", "b")
c <- new("C", "c")
```

This creates a class graph that looks like this:

![](diagrams/class-graph-1.png)

Next, we create a generic f, which will dispatch on two arguments: `x` and `y`.

```R
setGeneric("f", function(x, y) standardGeneric("f"))
```

To predict which method a generic will dispatch to, you need to know:

* the name and arguments to the generic
* the signatures of the methods
* the class of arguments supplied to the generic

The simplest type of method dispatch occurs if there's an exact match between the class of arguments (arg-classes) and the signature of (sig-classes). In the following example, we define methods with sig-classes `c("C", "C")` and `c("A", "A")`, and then call them with arg classes `c("C", "C")` and `c("A", "A")`.

```R
setMethod("f", signature("C", "C"), function(x, y) "c-c")
setMethod("f", signature("A", "A"), function(x, y) "a-a")

f(c, c)
f(a, a)
```

If there isn't an exact match, R looks for the closest method. The distance between the sig-class and arg-class is the sum of the distances between each class (matched by named and excluding ...). The distance between classes is the shortest distance between them in the class graph. For example, the distance A -> B is 1, A -> C is 2 and B -> C is 1. The distances C -> B, C -> A and B -> A are all infinite. That means that of the following two calls will dispatch to the same method:

```R
f(b, b)
f(a, c)
```

If we added another class, BC, that inherited from both B and C, then this class would have distance one to both B and C, and distance two to A. As you can imagine, this can get quite tricky if you have a complicated class graph: for this reason it's better to avoid multiple inheritance unless absolutely necessary.

![](diagrams/class-graph-2.png)

```R
setClass("BC", contains = c("B", "C"))
bc <- new("BC", "bc")
```

Let's add a more complicated case:

```
setMethod("f", signature("B", "C"), function(x, y) "b-c")
setMethod("f", signature("C", "B"), function(x, y) "c-b")
f(b, b)
```

Now we have two signatures that have the same distance (1 = 1 + 0 = 0 + 1), and there is not unique closest method. In this situation R gives a warning and calls the method that comes first alphabetically.

There are two special classes that can be used in the signature: `missing` and `ANY`. `missing` matches the case where the argument is not supplied, and `ANY` is used for setting up default methods. `ANY` has the lowest possible precedence in method matching - in other words, it has a distance value higher than any other parent class.

```R
setMethod("f", signature("C", "ANY"), function(x,y) "C-*")
setMethod("f", signature("C", "missing"), function(x,y) "C-?")

setClass("D", contains = "character")
d <- new("D", "d")

f(c)
f(c, d)
```

It's also possible to dispatch on `...` under special circumstances. See `?dotsMethods` for more details.

### Exercises

* Imagine we added a class `AC`, which inherited from `A` and `C`. What would the distance between `AC` and `A`, `B` and `C` be? What about the distance between `AC` and `AB`?

## RC

Reference classes (or RC for short) are new in R 2.12. They fill a long standing need for mutable objects that had previously been filled by contributed packages like `R.oo`, `proto` and `mutatr`. While the core functionality is solid, reference classes are still under active development and some details will change. The most up-to-date documentation for Reference Classes can always be found in `?ReferenceClasses`.

There are two main differences between RC and S3/S4:

* RC methods belong to objects, not functions.

* RC objects are mutable: the usual R copy on modify semantics do not apply

These properties make RC behave much more like python/ruby/java/C#/... 

Surprisingly, the implementation of reference classes is almost entirely in R code - they are a combination of S4 methods and environments.  This is a testament to the flexibility of S4.

### Recognising objects and methods

### Defining classes and creating objects

Creating a new reference based class is straightforward: you use `setRefClass`. Unlike `setClass` from S4, you want to keep the results of that function around, because that's what you use to create new objects of that type:

    # Or keep reference to class around.
    Person <- setRefClass("Person")
    Person$new()

A reference class has three main components, given by three arguments to `setRefClass`:

* `contains`, the classes which the class inherits from. These should be other
  reference class objects:

        setRefClass("Polygon")
        setRefClass("Regular")

        # Specify parent classes
        setRefClass("Triangle", contains = "Polygon")
        setRefClass("EquilateralTriangle", 
          contains = c("Triangle", "Regular"))

* `fields` are the equivalent of slots in `S4`. They can be specified as a
  vector of field names, or a named list of field types:

        setRefClass("Polygon", fields = c("sides"))
        setRefClass("Polygon", fields = list(sides = "numeric"))

  The most important property of refclass objects is that they are mutable, or
  equivalently they have reference semantics:
  
        Polygon <- setRefClass("Polygon", fields = c("sides"))
        square <- Polygon$new(sides = 4)
        
        triangle <- square
        triangle$sides <- 3
        
        square$sides        

* `methods` are functions that operate within the context of the object and
  can modify its fields. These can also be added after object creation, as
  described below.

        setRefClass("Dist")
        setRefClass("DistUniform", c("a", "b"), "Dist", methods = list(
          mean <- function() {
            (a + b) / 2
          }
        ))


### Method dispatch

Refclass methods are associated with objects, not with functions, and are called using the special syntax `obj$method(arg1, arg2, ...)`. (You might recall we've seen this construction before when we called functions stored in a named list). Methods are also special because they can modify fields. This is different

We've also seen this construct before, when we used closures to create mutable state. Reference classes work in a similar manner but give us some extra functionality:

* inheritance
* a way of documenting methods
* a way of specifying fields and their types

## Comparison

### Call parent method

* base: usually not possible. Sometimes special function available e.g. `.subset2` is the default for `[[`

* S3: `NextMethod()`

* S4: `callNextMethod()`

* R5: `$callSuper(...)`

## Picking a system

Three OO systems is a lot for one language, but for most R programming, S3 suffices. In R you usually create fairly simple objects, and use OO programming to add special behaviour to generic functions like `print()`, `summary()` and `plot()`. S3 is well suited to this domain, and the majority of OO code that I have written in R is S3. S3 is also a little quirky, and relatively poorly documented elsewhere so this capture will focus on S3, only providing a broad overview of the details of S4 and reference classes. Once you have mastered S3, S4 is relatively easy to pickup - the ideas are all the same, it is just more formal, and more verbose. If you've programmed in another language, ref classes will be natural.

If you are creating more complicated systems of interrelated objects, S4 may be more appropriate. S4 is used extensively by Bioconductor. The `Matrix` package by Douglas Bates and Martin Maechler is another package for which S4 is particularly well suited. It is designed to efficiently store and compute with many different special types of sparse matrix. As at version 0.999375-50 it defines 130 classes and 24 generic functions. The package is well written, well commented and fairly easy to read. The accompanying [vignette](http://cran.r-project.org/web/packages/Matrix/vignettes/Intro2Matrix.pdf) gives a good overview of the structure of the package.

* [S4 system development in Bioconductor](http://www.bioconductor.org/help/course-materials/2010/AdvancedR/S4InBioconductor.pdf)

Reference classes differ from S3 and S4 in two important ways: these properties makes this object system behave much more like Java and C#. Surprisingly, the implementation of reference classes is almost entirely in R code - they are a combination of S4 methods and environments. Note that when using reference based classes we want to minimise side effects, and use them only where mutable state is absolutely required. The majority of functions should still be "functional", and side effect free. This makes code easier to reason about (because you don't need to worry about methods changing things in surprising ways), and easier for other R programmers to understand.
