# Introduction

This book has grown out of over 10 years of programming in R, and constantly struggling to understand the best way of doing things. 

Overall, this is an opinionated book. There are many ways to do things in R; this book will focus on what we think is the best way.  We've spent the time to figure out what's the best approach so that you don't have to.

R is still a relatively young language, and the resources to help you understand it are still maturing. In my personal journey to understand R, I've found it particularly helpful to refer to resources that describe how other programming languages work. R has aspects of both functional and object-oriented (OO) programming languages, and learning how these aspects are expressed in R, will help you translate your existing knowledge from other programming languages, and to help you identify areas where you can improve.

Functional

* First class functions
* Pure functions: a goal, not a prerequisite
* Recursion: no tail call elimination. Slow
* Lazy evaluation: but only of function arguments. No infinite streams
* Untyped

OO

* Has three distinct OO frameworks built in to base. And more available in add on packages.  Two of the OO styles are built around generic functions, a style of OO that comes from lisp.

I found the following two books particularly helpful:

* [The structure and interpretation of computer programs](http://mitpress.mit.edu/sicp/full-text/book/book.html) by Harold Abelson and Gerald Jay Sussman.

* [Concepts, Techniques and Models of Computer Programming](http://amzn.com/0262220695?tag=hadlwick-20) by Peter van Roy and Sef Haridi

These are both extremely dense books, but very rewarding. They really helped me to understand the tradeoffs behind the way that R does things.

It's also very useful to learn a little about lisp and scheme, because many of the ideas in R are adapted from lisp, and there are often good descriptions of the basic ideas, even if the implementation differs somewhat. Part of the purpose of this book is so that you don't have to consult these original source, but if you want to learn more, this is a great way to develop a deeper understanding of how R works.

Other websites that helped me to understand smaller pieces of R are:

* [Getting Started with Dylan](http://opendylan.org/documentation/intro-dylan/index.html) for understanding S4

* [Frames, Environments, and Scope in R and S-PLUS](http://cran.r-project.org/doc/contrib/Fox-Companion/appendix-scope.pdf). Section 2 is recommended as a good introduction to the formal vocabulary used in much of the R documentation. 

* [Lexical scope and statistical computing](http://www.stat.auckland.ac.nz/~ihaka/downloads/lexical.pdf) gives more examples of the power and utility of closures.

Other recommendations for becoming a better programmer:

* [The pragmatic programmer](http://amzn.com/020161622X?tag=hadlwick-20), by Andrew Hunt and David Thomas.

## What you will get out of this book

This book describes the skills that I think you need to be an advanced R developer, producing reproducible code that can be used in a wide variety of circumstances.

After reading this book, you will be:

* Familiar with the fundamentals of R, so that you can represent complex data
  types and simplify the operations performed on them. You have a deep
  understanding of the language, and know how to override default behaviours
  when necessary

* Able to produce packages to make your work available to a wider audience,
  and how to efficiently program "in the large", so you spend your time
  solving new problems not struggling with old code.

* Comfortable reading and understanding the majority of R code. Important so
  you can learn from and critique others code.

## Who should read this book

* Experienced programmers from other languages who want to learn about the
  features of R that make it special

* Existing package developers who want to make it less work.

* R developers who want to take it to the next level - who are ready to
  release their own code into the wild

To get the most out of this look you should already be familiar with the basics of R as described in the [[basics]], and you should have started developing your R [[vocabulary]].

## Acknowledgements

I would particularly like to thank the tireless contributors to R-help. There are too many that have helped me over the years to list individually, but I'd particularly like to thank Luke Tierney, John Chambers, and Brian Ripley for correcting countless of my misunderstandings and helping me to deeply understand R.

More recently, [stackoverflow](http://stackoverflow.com/questions/tagged/r) has become a fantastic resource.

Feedback of the many people who read draft versions of the book (wiki), especially those who fixed many typos: 

Twitter
