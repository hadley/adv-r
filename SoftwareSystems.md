# Writing Software Systems

At the most basic level, an R program, like any other program is a sequence
of instructions written to perform a task. Programs consist of data 
structures, which hold data, and functions, which define things a program
can do. You are already familiar with the native R data structures: vectors,
lists, data frames, etc. And you have already seen the functions that 
access and manipulate these functions. However, as you design your 
own systems on top of R you will eventually want to create your own
data structures.  After these new types are defined you may want 
to create specialized functions that operate on your new data structures. 
In other cases you may want to extend existing systems to take advantage
of your new functionality. This chapter shows you how to build new 
software systems that can "plug into" R's existing functionality
and allows other users to extend your new capabilities.

Data structures are generally associated with a set of functions that
are created to work with them. The data structures and their functions
can be encapsulated to create classes. Classes help us to compartmentalize
conceptually coherent pieces of software. For example, an R vector is
class holding a sequence of atomic types in R. We can create an instance 
a vector using one of R's vector creation routines.

  x <- 1:10
  length(x)

The variable x is an object of type vector. Where the class
describes what the data structure will look like an object is an actual
instance of that type. 
Objects are associated with functions that let us do things like access and
manipulate the data held by an object. In the previous example the
length function is associated with vectors and allows us to find out how many 
elements the vector holds.

R provides three different constructs for programming with classes, also 
called object oriented (OO) programming, S3, S4, and R5. The first two S3 and S4
are written in a style called generic-function OO. Functions that may be
associated with a class are first defined as being generic functions. Then
methods, or functions associated with a specific class, are defined much
like any other function. However, when an instance of an object is passed
to the generic function as a parameter, it is dispatched to its associated 
method. R5 is implemented in a style called message-passing OO. In this style
a methods are directly associated with classes and it is the object that
determines which function to call.

For the rest of this chapter we are going to explore the use of S3, S4, and
R5 to generate sequences. Along with building a general system
for generating sequences we are going to create classes that generate 
the Fibonacci numbers, one by one. As you probably already know, the 
Fibonacci numbers follow the integer sequence

  0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144...

and are defined by the recurrence

  F(0) = 0
  F(1) = 1
  F(k) = F(k-1) + F(k-2). 

These numbers can easily be generated in R using the familiar vectors and 
functions that you already know. An example of how to do this is 
provided below. It's important to realize that the techniques shown in this
chapter will not allow you to express algorithms your couldn't express 
with R's native data structures and functions. The techniques do allow you
to organize data structures and functions to create a general system
or framework for generating sequences. 

  fibonacci <- function(lastTwo=c()) {
    if (length(lastTwo) == 0) {
      lastTwo <- 1
    } else {
      lastTwo <- c(lastTwo, sum(lastTwo))
      if (length(lastTwo) > 2) {
        lastTwo <- lastTwo[-1]
      }
    }
    return(lastTwo)
  }

  # Get the first 10 fibonacci numbers
  fibs <- fibonacci()
  for (i in 1:10) {
    print(tail(fibs, 1))
    fibs <- fibonacci(fibs)
  }

Creating a general system for sequences has two advantages. First, it allows
for abstraction. In our example we've defined a vector to hold the last two
values in the Fibonacci sequence along with a function that gets the next
value in the sequence. By realizing that any integer sequence that we might like
to generate can be expressed computationally as data, the last two value
for the Fibonacci sequence, and a function to get the next value. We've 
identified the essential pieces generating sequences. From here we can 
start thinking about the types of things we might like to do with any sequence,
not just the Fibonaccis. Second, we can make our system extensible. That is,
we can write code for other types of sequences
that work within our framework. Extensibility allows you to
create new sequences, like the factorial numbers, based on the abstract 
notion of a sequence. It will even allow others to define their own sequences
that will work within our sequence framework.

## S3

## Advanced S3 

## S4

## Mutable closure

## R5
