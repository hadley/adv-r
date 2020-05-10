# Preface {-}

Welcome to the second edition of _Advanced R_. I had three main goals for this edition:

* Improve coverage of important concepts that I fully understood only after
  the publication of the first edition.

* Reduce coverage of topics time has shown to be less useful, or that I think
  are really exciting but turn out not to be that practical.

* Generally make the material easier to understand with better text, clearer
  code, and many more diagrams.

If you're familiar with the first edition, this preface describes the major changes so that you can focus your reading on the new areas. If you're reading a printed version of this book you'll notice one big change very quickly: _Advanced R_ is now in colour! This has considerably improved the syntax highlighting of code chunks, and made it much easier to create helpful diagrams. I have taken advantage of this and included over 100 new diagrams throughout the book.

Another big change in this version is the use of new packages, particularly [rlang](http://rlang.r-lib.org), which provides a clean interface to low-level data structures and operations. The first edition used base R functions almost exclusively, which created some pedagogical challenges because many functions evolved independently over multiple years, making it hard to see the big underlying ideas hidden amongst the incidental variations in function names and arguments. I continue to show base equivalents in sidebars, footnotes, and where needed, in individual sections, but if you want to see the purest base R expression of the ideas in this book, I recommend reading the first edition, which you can find online at <http://adv-r.had.co.nz>.

The foundations of R have not changed in the five years since the first edition, but my understanding of them certainly has. Thus, the overall structure of "Foundations" has remained roughly the same, but many of the individual chapters have been considerably improved:

*   Chapter \@ref(names-values), "Names and values", is a brand new chapter
    that helps you understand the difference between objects and names of
    objects. This helps you more accurately predict when R will make a copy of
    a data structure, and lays important groundwork to understand functional
    programming.

*   Chapter \@ref(vectors-chap), "Vectors" (previously called data structures),
    has been rewritten to focus on vector types like integers, factors, and
    data frames. It contains more details of important S3 vectors (like dates
    and date-times), discusses the data frame variation provided by the
    tibble package [@tibble], and generally reflects my improved understanding
    of vector data types.

*   Chapter \@ref(subsetting), "Subsetting", now distinguishes between `[` and
    `[[` by their intention: `[` extracts many values and `[[` extracts a
    single value (previously they were characterised by whether they "simplified"
    or "preserved"). Section \@ref(subset-single) draws the "train" to help you
    understand how `[[` works with lists, and introduces new functions that
    provide more consistent behaviour for out-of-bounds indices.

*   Chapter \@ref(control-flow), "Control flow", is a new chapter: somehow
    I previously forgot about important tools like `if` statements and `for`
    loops!

*   Chapter \@ref(functions), "Functions", has an improved ordering,
    introduces the pipe (`%>%`) as a third way to compose functions (Section
    \@ref(function-composition)), and has considerably improved coverage of
    function forms (Section \@ref(function-forms)).

*   Chapter \@ref(environments), "Environments", has a reorganised treatment of
    special environments (Section \@ref(special-environments)), and a much
    improved discussion of the call stack (Section \@ref(call-stack)).

*   Chapter \@ref(conditions), "Conditions", contains material previously
    in "Exceptions and debugging", and much new content on how R's condition
    system works. It also shows you how to create your own custom condition
    classes (Section \@ref(custom-conditions)).

The chapters following Part I, Foundations, have been re-organised around the three most important programming paradigms in R: functional programming, object-oriented programming, and metaprogramming.

* Functional programming is now more cleanly divided into the three main
  techniques: "Functionals" (Chapter \@ref(functionals)), "Function
  factories" (Chapter \@ref(function-factories)), and "Function operators"
  (Chapter \@ref(function-operators)). I've focussed in on ideas that have
  practical applications in data science and reduced the amount of pure theory.

  These chapters now use functions provided by the purrr package [@purrr],
  which allow me to focus more on the underlying ideas and less on the
  incidental details. This led to a considerable simplification of the
  function operators chapter since a major use was to work around the absence
  of ellipses (`...`) in base functionals.

* Object-oriented programming (OOP) now forms a major section of the book with
  completely new chapters on base types (Chapter \@ref(base-types)),
  S3 (Chapter \@ref(s3)), S4 (Chapter \@ref(s4)), R6 (Chapter \@ref(r6)),
  and the tradeoffs between the systems (Chapter \@ref(oo-tradeoffs)).

  These chapters focus on how the different object systems work,
  not how to use them effectively. This is unfortunate, but necessary, because
  many of the technical details are not described elsewhere, and effective use
  of OOP needs a whole book of its own.

* Metaprogramming (previously called "computing on the language") describes the
  suite of tools that you can use to generate code with code. Compared to the
  first edition this material has been substantially expanded and now focusses on
  "tidy evaluation", a set of ideas and theory that make metaprogramming
  safe, well-principled, and accessible to many more R programmers.
  Chapter \@ref(meta-big-picture), "Big picture" coarsely lays out how all
  the pieces fit together; Chapter \@ref(expressions), "Expressions", describes
  the underlying data structures; Chapter \@ref(quasiquotation),
  "Quasiquotation", covers quoting and unquoting; Chapter \@ref(evaluation),
  "Evaluation", explains evaluation of code in special environments; and Chapter
  \@ref(translation), "Translations", pulls all the themes together to show
  how you might translate from one (programming) language to another.

The final section of the book pulls together the chapters on programming techniques: profiling, measuring and improving performance, and Rcpp. The contents are very similar to the first edition, although the organisation is a little different. I have made light updates throughout these chapters particularly to use newer packages (microbenchmark -> bench, lineprof -> profvis), but the majority of the text is the same.

While the second edition has mostly expanded coverage of existing material, five chapters have been removed:

* The vocabulary chapter has been removed because it was always a bit of an odd
  duck, and there are more effective ways to present vocabulary lists than in a
  book chapter.

* The style chapter has been replaced with an online style guide,
  <http://style.tidyverse.org/>. The style guide is paired with the new
  styler package [@styler] which can automatically apply many of the rules.

* The C chapter has been moved to <https://github.com/hadley/r-internals>, which, over time, will provide
  a guide to writing C code that works with R's data structures.

* The memory chapter has been removed. Much of the material has been integrated
  into Chapter \@ref(names-values) and the remainder felt excessively technical
  and not that important to understand.

* The chapter on R's performance as a language was removed. It delivered
  few actionable insights, and became dated as R changed.
