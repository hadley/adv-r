# OO essentials

R has three object oriented systems:

* S3
* S4
* RefClasses

The aim of this chapter is to teach you the basics of S3, how to recognise S4 and RefClasses, and how to figure what method gets called in a given situation and what the underlying code is. 

Teaching you to use OO effectively is beyond the scope of this book.

## S3

Is the simplest OO system that might possibly work.

Method creation looks like:

`generic.class <- function(...) {}`

## S4

Is a rigorous re-write of S3. Adds formal class, multiple inheritance and multiple dispatch. Useful for large problems.

## RefClasses

Works like Java OO. Useful for truly mutable objects, e.g. GUIs or connecting to other programming languages. If you're coming from another programming language, this is likely to feel the most natural, but you will get more out of R if you understand why S3 and S4 work the way they do.