# (PART) Functional programming {-}

# Introduction {#fp .unnumbered}  
\index{functional programming}

R, at its heart, is a functional programming (FP) language. This means that it provides many tools for the creation and manipulation of functions.

FP is a technical term that defines certain properties of a programming language. But it's also a programming style.

In R, the tools for working with functions, the tools of functional programming, are more important than the tools for working with objects or classes, the tools of object oriented programming.

R has what's known as first class functions. You can do anything with functions that you can do with vectors: you can assign them to variables, store them in lists, pass them as arguments to other functions, create them inside functions, and even return them as the result of a function. 
A higher-order function is a function that takes a function as an input or returns a function as output. This part of the book is broken down by the three types of higher-order functions:

* __Functionals__, Chapter \@ref(functionals) where functions are the input.
  Functionals are by far and away the most immediately useful application of
  FP ideas, and you'll use them all the time in data analyses.

* __Function factories__, Chapter \@ref(function-factories), functions as 
  output. You can almost always avoid function factories in favour of a 
  different technique, but they are occassionally useful.

* __Function operators__, Chapter \@ref(function-operators), discusses function 
  as input and output. These are like adverbs, because they typically modify
  the operation of a function.

#### Other languages

While FP techniques form the core of languages like Haskell, OCaml and F#, those techniques can also be found in other languages. They are well supported in multi-paradigm systems like Lisp, Scheme, Clojure and Scala. Also, while they tend not to be the dominant technique used by programmers, they can be used in modern scripting languages like Python, Ruby and JavaScript. In contrast, C, Java and C# provide few functional tools, and while it's possible to do FP in those languages, it tends to be an awkward fit. In sum, if you Google for it you're likely to find a tutorial on functional programming in any language. But doing so can often be syntactically awkward or used so rarely that other programmers won't understand your code.

Recently FP has experienced a surge in interest because it provides a complementary set of techniques to object oriented programming, the dominant style for the last several decades. Since FP functions tend to not modify their inputs, they make for programs that are easier to reason about using only local information, and are often easier to parallelise. The traditional weaknesses of FP languages, poorer performance and sometimes unpredictable memory usage, have been largely eliminated in recent years.
