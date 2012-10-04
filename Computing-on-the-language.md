# Computing on the language

Writing R code that modifies R code.

## Basics of R code

There are three fundamental building blocks of R code:

* __names__, which represent the name, not value, of a variable
* __constants__, like `"a"` or `1:10`
* __calls__, which represents a function call

Collectively I'll call these three things parsed code, because they each represent a stand-alone piece of R code that you could run from the command line. 

A call is made up of two parts:

* a name, giving the name of the function to be called
* arguments, a list of parsed code

Calls are recursive because the arguments to a call can be other calls, e.g. `f(x, 1, g(), h(i()))`. This means we can think about calls as trees. For example, we can represent that call as:

    \- f()
       \- x
       \- 1
       \- g()
       \- h()
          \- i()

Everything in R parses into this tree structure - even things that don't look like calls such as `{`, `function`, control flow, infix operators and assignment. The figure below shows the parse tree for some of these special constructs. All calls are labelled with "()" even if we don't normally think of them as function calls.

    draw_tree(expression(
      { a + b; 2},
      function(x, y = 2) 3,
      (a - b) * 3,
      if (x < 3) y <- 3 else z <- 4,
      name(df) <- c("a", "b", "c"),
      -x
    ))
    
    # \- {()
    #    \- +()
    #       \- a
    #       \- b
    #    \- 2
    # 
    # \- function()
    #    \- list(x = , y = 2)
    #    \- 3
    #    \- "function(x, y = 2) 3"
    # 
    # \- *()
    #    \- (()
    #       \- -()
    #          \- a
    #          \- b
    #    \- 3
    # 
    # \- if()
    #    \- <()
    #       \- x
    #       \- 3
    #    \- <-()
    #       \- y
    #       \- 3
    #    \- <-()
    #       \- z
    #       \- 4
    # 
    # \- <-()
    #    \- name()
    #       \- df
    #    \- c()
    #       \- "a"
    #       \- "b"
    #       \- "c"
    # 
    # \- -()
    #    \- x

Code chunks can be built up into larger structures in two ways: with expressions or braced expressions:

* Expressions are lists of code chunks, and are created when you parse a file.
  Expressions have one special behaviour compared to lists: when you `eval()`
  a expression, it evaluates each piece in turn and returns the result of last
  piece of parsed code.

* Braced expressions represent complex multiline functions as a call to the
  special function `{`, with one argument for each code chunk in the function.
  Despite the name, braced expressions are not actually expressions, although
  the accomplish much the same task.

## Code to text and back again

As well as representation as an AST, code also has a string representation. This section shows how to go from a string to an AST, and from an AST to a string.

The `parse` function converts a string into an expression. It's called parse because this is the formal CS name for converting a string representing code into a format that the computer can work with. Note that parse defaults to work within files - if you want to parse a string, you need to use the `text` argument.  Technically, parse returns an expression, or a list of calls. 

The `deparse` function is an almost inverse of `parse` - it converts an call into a text string representing that call. It's an almost inverse because it's impossible to be completely symmetric. Deparse will returns character vector with an entry for each line - if you want a single string be sure to `paste` it back together. 

A common idiom in R functions is `deparse(substitute(x))` - this will capture the character representation of the code provided for the argument `x`. Note that you must run this code before you do anything to `x`, because substitute can only access the code which will be used to compute `x` before the promise is evaluated.

### The missing argument

If you experiment with the structure function arguments, you might come across a rather puzzling beast: the "missing" object:

    formals(plot)$x
    x <- formals(plot)$x
    x
    # Error: argument "x" is missing, with no default

It is basically an empty symbol, but you can't create it directly:

    is.symbol(formals(plot)$x)
    # [1] TRUE
    deparse(formals(plot)$x)
    # [1] ""
    as.symbol("")
    # Error in as.symbol("") : attempt to use zero-length variable name
    
You can either capture it from a missing argument of the formals of a function, as above, or create with `substitute()` or `bquote()`.

## Modifying calls

It's a bad idea to create code by operating on it's string representation: there is no guarantee that you'll create valid code. Instead, you should use tools like `substitute` and `bquote` to modify expressions, where you are guaranteed to produce syntactically correct code (although of course it's still easy to make code that doesn't work).

## `substitute`

We've seen `substitute` used for it's ability to capture the unevalated expression of a promise, but it also has another important role for modifying expressions. The second argument to `substitute`, `env`, can be an environment or list giving a set of replacements. It's easiest to see this with an example:

    substitute(a + b, list(a = 1, b = 2))
    # 1 + 2

Note that `substitute` doesn't evaluate its first argument:

    x <- quote(a + b)
    substitute(x, list(a = 1, b = 2))
    # x

We can create our own adaption of substitute (that uses substitute!) to work around this:

    substitute2 <- function(x, env) {
      call <- substitute(substitute(x, env), list(x = x))
      eval(call)
    }
    x <- quote(a + b)
    substitute2(x, list(a = 1, b = 2))

When writing functions like this, I find it helpful to do the evaluation last, only after I've made sure that I've constructed the correct substitute call with a few test inputs.

If you want to substitute in a variable or function call, you need to be careful to supply the right type object to substitute:
    
    substitute(a + b, list(a = y))
    # Error: object 'y' not found
    
    substitute(a + b, list(a = "y"))
    # "y" + b
    
    substitute(a + b, list(a = as.name("y")))
    # y + b
    
    substitute(a + b, list(a = quote(y)))
    # y + b
    
    substitute(a + b, list(a = y()))
    # Error: could not find function "y"
    
    substitute(a + b, list(a = call("y")))
    # y() + b
    
    substitute(a + b, list(a = quote(y())))
    # y() + b

Another useful tool is `bquote`.  It quotes an expression apart from any terms wrapped in `.()` which it evaluates:

    x <- 5
    bquote(y + x)
    # y + x
    
    bquote(y + .(x))
    # y + 5

### Limitations of substitute

Can't change argument names or number.

### Modifying calls directly

You can also modify calls because of their list-like behaviour: just like a list, a call has `length`, `'[[` and `[` methods. The length of a call minus 1 gives the number of arguments:

    x <- quote(read.csv(x, "important.csv", row.names = FALSE))
    length(x) - 1
    # [1] 3

The first element of the call is the name of the function:

    x'[[1]]
    # read.csv

    is.name(x'[[1]])
    # [1] TRUE

The remaining elements are the arguments to the function, which can be extracted by name or by position.

    x$row.names
    # FALSE
    x'[[3]]
    # [1] "important.csv"

    names(x)

Generally, extract arguments by position is dangerous, because R's function calling semantics are so flexible. It's better to match by name, but all arguments might not be named. The solution to this problem is to use `match.call` which takes a function and a call as arguments:

    match.call(read.csv, x)
    # Or if you don't know in advance what the function is
    match.call(eval(x[[1]]), x)
    # read.csv(file = x, header = "important.csv", row.names = FALSE)

You can modify or add) elements of the call with replacement operators:

    x$col.names <- FALSE
    x
    # read.csv(x, "important.csv", row.names = FALSE, col.names = FALSE)

    x'[[5]] <- NULL
    x'[[3]] <- "less-imporant.csv"
    x
    # read.csv(x, "less-imporant.csv", row.names = FALSE)

Calls also support the `[` method, but use it with care: it produces a call object, and it's easy to produce invalid calls. If you want to get a list of the arguments, explicitly convert to a list.

    x[-3] # remove the second arugment
    # read.csv(x, row.names = FALSE)

    x[-1] # just look at the arguments - but is still a call!
    x("important.csv", row.names = FALSE)

    as.list(x[-1])
    # '[[1]]
    # x
    # 
    # '[[2]]
    # [1] "important.csv"
    # 
    # $row.names
    # [1] FALSE

### Cautions

Substitute + eval is an extremely powerful tool, but it can also create code that is hard for others to understand. Before you use it, make sure that you have exhaustive all other possibilities. This section shows a couple of examples of inappropriate use of computing on the language that you should avoid recreeating.

For example, given the name of a variable and it's desired value, you might write something like this:

      colname <- "cyl"
      val <- 6

      subset(mtcars, colname == val)
      # Zero rows because "cyl" != 6

      col <- as.name(colname)
      substitute(subset(mtcars, col == val), list(col = col, val = val))
      bquote(subset(mtcars, .(col) == .(val)))

But in this case, there's a much better solution: use subsetting, not the subset function.

      mtcars[mtcars[[colname]] == val, ]

`write.csv` is a base R function where call manipulation is used inappropriately:

     write.csv <- function (...) {
        Call <- match.call(expand.dots = TRUE)
        for (argname in c("append", "col.names", "sep", "dec", "qmethod")) if (!is.null(Call[[argname]])) 
            warning(gettextf("attempt to set '%s' ignored", argname), 
                domain = NA)
        rn <- eval.parent(Call$row.names)
        Call$append <- NULL
        Call$col.names <- if (is.logical(rn) && !rn) TRUE else NA
        Call$sep <- ","
        Call$dec <- "."
        Call$qmethod <- "double"
        Call[[1L]] <- as.name("write.table")
        eval.parent(Call)
    }

We could write a function that behaves identically using regular function call semantics:

     write.csv <- function(x, file = "", sep = ",", qmethod = "double", ...) {
      write.table(x = x, file = file, sep = sep, qmethod = qmethod, ...)
     }

This makes the function much much easier to understand - it's just calling `write.table` with different defaults.  This also fixes a subtle bug in the original `write.csv` - `write.csv(mtcars, row = FALSE)` does not turn off rownames, but `write.csv(mtcars, row.names = FALSE)` does.

## Creating a function

A function has three components: it's arguments, body (code to run) and the environment in which it's defined. There are a few ways we can create a  function from these three components.  The third is probably the most straightforward (create an empty function and then modify it).  But you might want to read the others and figure out how they work - it's good practice for your computing on the language skills.


    make_function1 <- function(args, body, env = parent.frame()) {
      args <- as.pairlist(args)
      eval(call("function", args, body), env)
    }
    make_function2 <- function(args, body, env = parent.frame()) {
      f <- function() {}
      formals(f) <- args
      body(f) <- body
      environment(f) <- env

      f
    }
    make_function3 <- function(args, body, env = parent.frame()) {
      as.function(c(args, body), env)
    }
    make_function4 <- function(args, body, env = parent.frame()) {
      subs <- list(args = as.pairlist(args), body = body)
      eval(substitute(`function`(args, body), subs), env)
    }

    args <- alist(a = 1, b = 2)
    body <- quote(a + b)
    make_function1(args, body)
    make_function2(args, body)
    make_function3(args, body)
    make_function4(args, body)
    
    library(microbenchmark)
    microbenchmark(
      make_function1(args, body),
      make_function2(args, body),
      make_function3(args, body),
      make_function4(args, body),
      function(a = 1, b = 2) a + b
    )


There are two tricks here: first of all we use the `alist` function to create a **a**rugment list.

    add <- make_function(alist(a = 1, b = a), quote(a + b))
    add(1)
    add(1, 2)

    add2 <- make_function(alist(a = 1, b = a), quote(a + b + d))
    d <- 3
    add2(1)

We don't use any special evaluation tricks here because we want `make_function` to be a building block for other functions.  For example, we could create an `unenclose` function that takes a closure and modifies it so when you look at the source you can see what's going on:  (Note we need to use `substitute2` here, because `substitute` doesn't evaluate its arguments).

    unenclose <- function(f) {
      stopifnot(is.function(f))
      env <- environment(f)

      make_function(formals(f), substitute2(body(f), env), parent.env(env))
    }

    f <- function(x) {
      function(y) { 
        x + y
      }
    }
    f(1)
    unenclose(f(1))

Building up a function by hand is also useful when you can't use a closure because you don't know in advance what the arguments will be, and similarly you can't use substitute.

## Walking the code tree

Because code is a tree, we're going to need recursive functions to work with it. You now have basic understanding of how code in R is put together internally, and so we can now start to write some useful functions. In this section we'll write some functions to tackle some useful problems.  In particular, we will look at two common development mistakes.

* Find assignments
* Replace `T` with `TRUE` and `F` with `FALSE`

<!-- For each we'll tackle it first just looking at the raw code, and next we'll figure out how to use source refs to modify the code to keep as much of the original formatting, comments etc as possible. -->

The `codetools` package, included in the base distribution, provides some other built-in tools based for automated code inspection:

* `findGlobals`: locates all global variables used by a function. This can be
  useful if you want to check that your functions don't inadvertently rely on
  variables defined in their parent environment.

* `checkUsage`: checks for a range of common problems including unused local
  variables, unused parameters and use of partial argument matching.

* `showTree`: works in a similar way to the `drawTree` used above, but
  presents the parse tree in a more compact format based on Lisp's
  S-expressions

### Find assignment

The key to any function that works with the parse tree right is getting the recursion right, which means making sure that you know what the base case is (the leaves of the tree) and figuring out how to combine the results from the recursive case. 

The nodes of the tree can be any recursive data structure that can appear in a quoted object: pairlists, calls, and expressions. The leaves can be 0-argument calls (e.g. `f()`), atomic vectors, names or `NULL`. One way to detect a leaf is that it's length is less than or equal to 1. One way to detect a node is to use `is.recursive`.

In this section, we will write a function that figures out all variables that are created by assignment in an expression. We'll start simply, and make the function progressively more rigorous. One reason to start with this function is because the recursion is a little bit simpler - we never need to go all the way down to the leaves because we are looking for assignment, a call to `<-`.  

This means that our base case is simple: if we're at a leaf, we've gone too far and can immediately return. We have two other cases: we have hit a call, in which case we should check if it's `<-`, otherwise it's some other recursive structure and we should call the function recursively on each element. Note the use of identical to compare the call to the name of the assignment function, and recall that the second element of a call object is the first argument, which for `<-` is the left hand side: the object being assigned to.

```R
find_assign <- function(obj) {
  if (length(obj) <= 1) {
    NULL
  } else if (is.call(obj) && identical(obj[[1]], as.name("<-"))) {
    obj[[2]]
  } else {
    lapply(obj, find_assign)
  }
}
find_assign(quote(a <- 1))
find_assign(quote({
  a <- 1
  b <- 2
}))
```

This function seems to work for these simple cases, but it's a bit verbose.  Instead of returning a list, let's keep it simple and stick with a character vector. We'll also test it with two slightly more complicated examples:

```R
find_assign <- function(obj) {
  if (length(obj) <= 1) {
    character(0)
  } else if (is.call(obj) && identical(obj[[1]], as.name("<-"))) {
    as.character(obj[[2]])
  } else {
    unlist(lapply(obj, find_assign))
  }
}
find_assign(quote({
  a <- 1
  b <- 2
  a <- 3
}))
# [1] "a" "b" "a"
find_assign(quote({
  system.time(x <- print(y <- 5))
}))
# [1] "x"
```

The fix for the first problem is easy: we need to wrap `unique` around the recursive case to remove duplicate assignments. The second problem is a bit more subtle: it's possible to do assignment within the arguments to a call, but we're failing to recurse down in to this case. 

```R
find_assign <- function(obj) {
  if (length(obj) <= 1) {
    character(0)
  } else if (is.call(obj) && identical(obj[[1]], as.name("<-"))) {
    call <- as.character(obj[[2]])
    c(call, unlist(lapply(obj[[3]], find_assign)))
  } else {
    unique(unlist(lapply(obj, find_assign)))
  }
}
find_assign(quote({
  a <- 1
  b <- 2
  a <- 3
}))
# [1] "a" "b"
find_assign(quote({
  system.time(x <- print(y <- 5))
}))
# [1] "x" "y"
```

There's one more case we need to test:

```R
find_assign(quote({
  ls <- list()
  ls$a <- 5
  names(ls) <- "b"
}))
# [1] "ls"        "ls$a"      "names(ls)"
draw_tree(quote({
  ls <- list()
  ls$a <- 5
  names(ls) <- "b"
}))
# \- {()
#    \- <-()
#       \- ls
#       \- list()
#    \- <-()
#       \- $()
#          \- ls
#          \- a
#       \- 5
#    \- <-()
#       \- names()
#          \- ls
#       \- "b"
```

This behaviour might be ok, but we probably just want assignment into whole objects, not assignment that modifies some property of the object. Drawing the tree for that quoted object helps us see what condition we should test for - we want the object on the left hand side of assignment to be a name.  This gives the final version of the `find_assign` function.

```R
find_assign <- function(obj) {
  if (length(obj) <= 1) {
    character(0)
  } else if (is.call(obj) && identical(obj[[1]], as.name("<-"))) {
    call <- if (is.name(obj[[2]])) as.character(obj[[2]])
    c(call, unlist(lapply(obj[[3]], find_assign)))
  } else {
    unique(unlist(lapply(obj, find_assign)))
  }
}
find_assign(quote({
  ls <- list()
  ls$a <- 5
  names(ls) <- "b"
}))
[1] "ls"
```

Making this function absolutely correct requires quite a lot more work, because we need to figure out all the other ways that assignment might happen: with `=`, `assign`, or `delayedAssign`.

### Replacing logical shortcuts 

First we'll start just by locating logical abbreviations. A logical abbreviation is the name `T` or `F`. We need to recursively breakup any recursive objects, anything else is not a short cut.

    find_logical_abbr <- function(obj) {
      if (is.name(obj)) {
        identical(obj, as.name("T")) || identical(obj, as.name("F"))
      } else if (is.recursive(obj)) {
        any(vapply(obj, find_logical_abbr, logical(1)))
      } else {
        FALSE
      }
    }

    
    f <- function(x = T) 1
    g <- function(x = 1) 2
    h <- function(x = 3) T
    
    find_logical_abbr(body(f))
    find_logical_abbr(formals(f))
    find_logical_abbr(body(g))
    find_logical_abbr(formals(g))
    find_logical_abbr(body(h))
    find_logical_abbr(formals(h))
  
To replace `T` with `TRUE` and `F` with `FALSE`, we need to make our recursive function return either the original object or the modified object, making sure to put calls back together appropriately. The main difference here is that we need to be much more careful with recursive objects, because each type needs to be treated differently:

<!-- * lists - which you might wonder why we need to recurse down into, but we
  could have a list of functions or a list of calls -->

* pairlists, which are used for function formals, can be processed as lists,
  but need to be turned back into pairlists with `as.pairlist`

* expressions, again can be processed like lists, but need to be turned back
  into expressions objects with `as.expression`. You won't find these inside a
  quoted object, but this might be the quoted object that you're passing in.

* calls require the most special treatment: don't process first element
  (that's the name of the function), and turn back into a call with `as.call`

This leads to:

    fix_logical_abbr <- function(obj) {
      if (is.name(obj)) {
        if (identical(obj, as.name("T"))) {
          quote(TRUE)
        } else if (identical(obj, as.name("F"))) {
          quote(FALSE)
        } else {
          obj
        }
      } else if (is.call(obj)) {
        args <- lapply(obj[-1], fix_logical_abbr)
        as.call(c(list(obj'[[1]]), args))
      } else if (is.pairlist(obj)) {
        as.pairlist(lapply(obj, fix_logical_abbr))
      } else if (is.expression(obj)) {
        as.expression(lapply(obj, fix_logical_abbr))
      } else {
        obj
      }
    }

However, this function is still not that useful because it loses all non-code structure:

    g <- quote(f <- function(x = T) {
      # This is a comment
      if (x)                  return(4)
      if (emergency_status()) return(T)
    })
    fix_logical_abbr(g)
    # f <- function(x = TRUE) {
    #     if (x) 
    #         return(4)
    #     if (emergency_status()) 
    #         return(TRUE)
    # }

    g <- parse(text = "f <- function(x = T) {
      # This is a comment
      if (x)                  return(4)
      if (emergency_status()) return(T)
    }")
    attr(g, "srcref")
    attr(g, "srcref")[[1]]
    as.character(attr(g, "srcref")[[1]])
    source(textConnection("f <- function(x = T) {
      # This is a comment
      if (x)                  return(4)
      if (emergency_status()) return(T)
    }"))


If we want to be able to apply this function to an existing code base, we need to be able to maintain all the non-code structure.  This leads us to our next code: srcrefs.

## Source references

<!-- http://journal.r-project.org/archive/2010-2/RJournal_2010-2_Murdoch.pdf -->

Would have to recursively parse.

## The parser package

