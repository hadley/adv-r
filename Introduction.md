# Introduction

This book has grown out of my 10 years of R programming, and my  constant struggle to understand the best way of doing things. The aim of this book is to help you understand R in much much faster than I did, and become an effective R programmer as quickly as possible. 

This book, particularly the package development part, is opinionated. You might not agree with everything we say, but it is much easier to learn from a cohesive viewpoint. Just because we don't talk about it in the book, doesn't mean it isn't right: there are so many techniques to solve problems in R that we couldn't include them all. There's a big difference between "I wouldn't do it this way", "I don't think that's the right way to do it", and "that's the wrong way to do it", and it's not always easy to capture that in writing. 

## Who should read this book

* Have you written a substantial amount of code (perhaps for data analysis), and you now want to learn better techniques for managing all that code, and gain a better understand of how R works?

* Have you tried to write a R package to distribute your code or data, but given up because the process is so frustrating?

* Have you come to R from another language and been driven up the wall by R's way of doing things?  Do you want to learn why on earth it works the way it does, and how you can be productive in R?

If the answer to any of those questions is yes, then this book is right for you. To get the most out of it, you should already be familiar with the basic [[data structures]], understand how [[subsetting]] works, and you should have started developing your R [[vocabulary]]. You should be somewhat familiar with the apply family of functions (like `apply()` and `lapply()`), although you may currently struggle to use them effectively.

## What you will get out of this book

This book describes the skills that I think you need to be an advanced R developer, producing reusable code that can be used in a wide variety of circumstances.

After reading this book:

* You will be comfortable reading and understanding the majority of R code.  You'll recognise common idioms (even if you wouldn't use them yourself) and be able to critique other code.

* You will be familiar with the fundamentals of R, so that you can represent complex data types and simplify the operations performed on them. You will have a deep understanding of the language, and know how to override default behaviours when necessary.

* You will be able to produce packages to make your work available to a wider audience, and be able to efficiently program "in the large", so you spend your time solving new problems not struggling with old code.

## What makes R special

* R has a massive set of packages for statistical modelling, machine learning, visualisation, data import, data manipulation and so on (over 4,000 at the time of writing). The chances are if you're trying to fit some sort of statistical model standard in your field, someone has already implemented it as an R package. This is probably why you're using R in the first place! 

* Most people writing R code are not programmers, but are interested in solving their problems with data. This makes the R community unlike the community around most programming languages. There is much less of a culture of best practices and more focus on results, no matter how bad the underlying code is.

* At the heart of R is a tension between interactive data analysis and programming. If you recognise and understand this tension, you'll understand why some functions drive you crazy when you're programming. For interactive use, you want functions that require as little typing as possible, and sometimes use a little magic to simplify your life. It's not a problem if they fail silently because you'll notice right away. For programming, you want to trade your time now for users time in the future. You're willing to spend a little more time to be explicit and verbose and spell out exactly what you want if it's going to save time in the future or produce more informative error messages.

* R is mostly a functional programming language with a dash of object orientedness. It has three three distinct OO frameworks in base R, and others available in add on packages (it's somewhat like Perl in this sense). Two of the OO styles are built around generic functions, a style of OO that comes from lisp, and is unfamiliar to most contemporary programmers.

* R has a strong ability to compute on the language; not only can functions access the values of their arguments, but they can also access the expressions that computed then. This is a double edged sword: computing on the language gives powerful tools for creating succinct domain specific languages, but if used incorrectly can lead to code that fails in unpredictable ways.

## Meta-techniques

There are two meta-techniques that are tremendously helpful for improving your skills as an R programmer: reading the source, and adopting a scientific mindset.

Reading source code is a tremedously useful technique because it exposes you to new ways of doing things. Over time you'll develop a sense of taste as an R programmer, and even if you find something your taste violently objects to, it's still helpful: emulate the things you like and avoid the things you don't like. I think the clarity of my code increased considerably once I started grading code in the classroom, and was exposed to a lot of code I couldn't make heads nor tails of! We'll talk about this much more in the package development section of the book, but I think it's a great idea to start by reading the source code for the functions and packages that you use most frequently. Reading the source becomes even more important when you start using more esoteric parts of R; often the documentation will be lacking, and you'll need to figure out how a function works by reading the source and experimenting.

A scientific mindset is extremely helpful when learning R. If you don't understand how something, develop a hypothesis, come up with some experiments and then perform them.  This exercise is extremely useful if you can't figure it out and need to get help from others: you can easily show what you tried, and when you learn the right answer, you'll be mentally prepared to update your world view. I find that the effort of explaining a problem so that others can understand and help be solve it (the art of a [reproducible example](http://stackoverflow.com/questions/5963269)) I figure out the solution myself.

## Recommended readings

R is still a relatively young language, and the resources to help you understand it are still maturing. In my personal journey to understand R, I've found it particularly helpful to refer to resources from other programming languages. R has aspects of both functional and object-oriented (OO) programming languages, and learning how these aspects are expressed in R, will help you translate your existing knowledge from other programming languages, and to help you identify areas where you can improve.

To understand why R's object systems work the way they do, I found [The structure and interpretation of computer programs](http://mitpress.mit.edu/sicp/full-text/book/book.html) by Harold Abelson and Gerald Jay Sussman.  It is a concise but deep book, and after reading it I felt for the first time that I could actually design my own object oriented system. It was my first introduction to the generic function style of OO common in R, and it helped me understand. SICP also talks a lot about functional programming, and creating functions that are simple in isolation and powerful in combination.

To understand more generally about the tradeoffs that R has made differently to other programming languages, I found [Concepts, Techniques and Models of Computer Programming](http://amzn.com/0262220695?tag=hadlwick-20) by Peter van Roy and Sef Haridi, extremely helpful. It helped me understand that R's copy-on-modify semantics make it substantially easier to reason about code, and while their current implementation in R is not so efficient, that's is a solvable problem.

If you want to learn to be a programmer, there's no place better to turn than [The pragmatic programmer](http://amzn.com/020161622X?tag=hadlwick-20), by Andrew Hunt and David Thomas.  This book is program language agnostic, and provides great advice for how to be a better programmer.

## Acknowledgements

I would particularly like to thank the tireless contributors to R-help and, more recently, [stackoverflow](http://stackoverflow.com/questions/tagged/r). There are too many to name individually,  but I'd particularly like to thank Luke Tierney, John Chambers, Dirk Eddelbuettel, JJ Allaire and Brian Ripley for giving deeply of their time and correcting countless of my misunderstandings.

This book was [written in the open](https://github.com/hadley/devtools/wiki) and advertised on [twitter](https://twitter.com/hadleywickham). Many people read the drafts, fixed typos, suggested improvements and contributed content. Without those contributors, the book wouldn't be nearly as good as it is, and I'm deeply greatful for their help.

(Before final version, remember to use `git shortlog` to list all contributors)