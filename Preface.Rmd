# Preface

Welcome to the work-in-progress 2nd edition of __Advanced R__. This preface describes the major changes that I have made to the book.

The 2nd edition has been published in colour, which as well as improving the syntax highlighting of the code chunks, has considerably increased the scope for helpful diagrams. I have taken advantage of this and included many more diagrams throughout the book. 

## rlang

A big change since the first edition of the book is the creation of the [rlang](http://rlang.r-lib.org) package, written primarily by Lionel Henry. The goal of this package is to provide a clean interface to low-level data structures and operations. I use this package in favour of base R because I believe it makes easier to understand how the R language works. Instead of struggling with the incidentals of functions that evolved organically over many years, the more consistent rlang API makes it easier to focus on the big ideas.

In each section, I'll briefly outline the base R equivalents to rlang code. But if you want to see the purest base R expression of these ideas, I recommend reading the first edition of the book, which you can find online at <http://adv-r.had.co.nz>.

Overall, rlang is still a work in progress, and much of the API continues to mature. However, the code used in this book is part of the rlang's testing process and will continue to work in the future. You can also see our confidence in the stability of rlang functions with the lifecycle badges at the documentation.

## Foundations

*   Environments: more pictures. Much improved discussion of frames and how they
    relate to the call stack.

*   New chapter on "Names and values" that helps you form a better mental 
    of `<-`, and to better understand when R makes copies of existing 
    data structures. Understanding the distinction between names and values is
    important for functional programming, and understanding when R makes copies
    is critical for accurate performance predictions.

*   Vectors (previously data structures) has been rewritten 
    with more diagrams to focus on vector types. More information
    about other important S3 vectors, and information about tibbles,
    a modern re-imagining of data frames.

*   Exceptions and debugging has been split into two chapters, "debugging"
    and "conditions". The contents of conditions has been expanded. The section
    of defensive programming has been removed, because discussing type stability
    is more natural in the context of functional programming, and programming
    with NSE is not the challenge it once was (now that tidy evaluation exists).

## Programming paradigms

After foundations, the book is now organised around the three most important programming paradigms in R:

* Functional programming has been updated to focus on the tools provided by
  the purrr package. The greatear consistency in the purrr package makes 
  it possible to focus more on the underlying ideas without being distracted by 
  incidental details.  Divided more cleanly into functionals, function 
  factories, and function operators. Greater focus on what time has shown to
  be important in practice. Less math + stat, and more data science.

* Object oriented programming (OOP) now forms a major section of the book with 
  individual chapters on base types, S3, S4, R6, and the tradeoffs between 
  the systems.
  
* Metaprogramming, formerly computing on the language, describes the suite
  of tools that you can use to generate code with code. Compared to the 
  first edition has been substantially expanded (from three chapters to five)
  and reorganised. More diagrams.

## Techniques

Final section discusses programming techniques, including both debugging, profiling, improving performance, and connecting R and C++.

## Removals

* Chapter of base R vocabulary was removed.

* The style guide has moved to http://style.tidyverse.org/. It is now
  paired with the [styler](http://styler.r-lib.org/) package which can
  automatically apply many of the rules.

* R's C interface moving to the work-in-progress 
  <https://github.com/hadley/r-internals>

* Memory chapter either integrated in names and values, or removed because
  it's excessively technical and not that important to understand (unless
  you're working with C code in which case it belongs in internals).
