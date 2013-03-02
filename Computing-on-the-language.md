# Computing on the language

In this section you'll learn how to write R code that modifies other R code.  Why might you want to do this?

* to work around functions that use non-standard evaluation rules (like lattice functions, )

* to create refactoring tools that modify your existing functions

* to create tools that inspect functions and warn you of common problems

* to extend the tools you learned in [[evaluation]] to create even more flexible functions for interactive data analysis

## Basics of R code

To compute on the language, we first need to be understand the structure of the language. That's going to require some new vocabulary, some new tools and some new ways of thinking about R code. Thoroughout this chapter we're going to use tools from the `pryr` package to help see what's going on.  If you don't already have it, install it by running `devtools::install_github("pryr")`

The first thing we need to discuss is the distinction between an operation and it's result:

```R
x <- 4
y <- x * 10
```

We want to distinguish between the operation of multiplying x by 10 and assinging the result to `y`, vs. the actual result.  In R, we can capture the operation with `quote()`:

```R
quote(y <- x * 10)
```

`quote()` gives us back exactly the expression that we typed in. Every expression is a tree, and we can use `pryr::call_tree()` to see the hierarchy more clearly.

```R
call_tree(quote(y <- x * 10))
```

There are three basic things you'll see in a call tree.  Names and constants form the leaves, or terminal nodes of the tree:

* __names__, which represent the name, not value, of a variable. These are prefixed with `'`

* __constants__, are atomic vectors, like `"a"` or `1:10`

Whereas the internal nodes are all made up of calls:

* __calls__, which represents a function call. These are suffixed with `()`.

Even things in R that don't look like calls still follow this same hierarchical structre:

```R
call_tree(quote(a + b))
call_tree(quote(if (x > 1) x else 1/x))
call_tree(quote(function(x, y) {x * y}))
```

There are three fundamental building blocks of R code:

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
      {a + b; 2},
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

Calls can be built up into larger structures in two ways: with expressions or braced expressions:

* Expressions are lists of code chunks, and are created when you parse a file.
  Expressions have one special behaviour compared to lists: when you `eval()`
  a expression, it evaluates each piece in turn and returns the result of last
  piece of parsed code.

* Braced calls represent complex multiline functions as a call to the
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

## Capturing calls

### `...`

```R
substitute(list(...))
match.call(expand.dots= FALSE)$`...`
```


## Modifying calls

It's generally a bad idea to create code by operating on its string representation: there is no guarantee that you'll create valid code.  Don't get me wrong: pasting strings together will often allow you to solve your problem in the least amount of time, but it may create subtle bugs that will take your users hours to track down. Learning more about the structure of the R language and the tools that allow you to modify it is an investment that will pay off by allowing you to make more robust code.

[Some examples]

Instead, you should use tools like `substitute` and `bquote` to modify expressions, where you are guaranteed to produce syntactically correct code (although of course it's still easy to make code that doesn't work).  

## `substitute`

We've seen `substitute` used for it's ability to capture the unevaluated expression of a promise, but it also has another important role for modifying expressions. The second argument to `substitute`, `env`, can be an environment or list giving a set of replacements. It's easiest to see this with an example:

    substitute(a + b, list(a = 1, b = 2))
    # 1 + 2

Note that `substitute` doesn't evaluate its first argument:

    x <- quote(a + b)
    substitute(x, list(a = 1, b = 2))
    # x

We can create our own adaption of `substitute` (that uses `substitute`!) to work around this:

    substitute2 <- function(x, env) {
      call <- substitute(substitute(x, env), list(x = x))
      eval(call)
    }
    x <- quote(a + b)
    substitute2(x, list(a = 1, b = 2))

When writing functions like this, I find it helpful to do the evaluation last, only after I've made sure that I've constructed the correct substitute call with a few test inputs. If you split the two pieces (call construction and evaluation) in to two functions, it's also much easier to test more formally.

If you want to substitute in a variable or function name, you need to be careful to supply the right type object to substitute:
    
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

A special case of `substitute()` is `bquote()`.  It quotes an call, except for any terms wrapped in `.()` which it evaluates:

    x <- 5
    bquote(y + x)
    # y + x
    
    bquote(y + .(x))
    # y + 5

Substitute does have some limitations: you can't change the number of arguments or their names. To do that, you'll need to modify the call directly, the topic of the next section.

## Modifying calls directly

You can also modify calls by taking advantage of their list-like behaviour.  List a list, a call has `length`, `'[[` and `[` methods. The length of a call minus 1 gives the number of arguments:

    x <- quote(read.csv(x, "important.csv", row.names = FALSE))
    length(x) - 1
    # [1] 3

The first element of the call is the name of the function:

```R
x[[1]]
# read.csv

is.name(x[[1]])
# [1] TRUE
```

The remaining elements are the arguments to the function, which can be extracted by name or by position.

```R
x$row.names
# FALSE
x[[3]]
# [1] "important.csv"

names(x)
```

Generally, extracting arguments by position is dangerous, because R's function calling semantics are so flexible. It's better to match by name, but all arguments might not be named. The solution to this problem is to use `match.call` which takes a function and a call as arguments:

```R
match.call(read.csv, x)
# Or if you don't know in advance what the function is
match.call(eval(x[[1]]), x)
# read.csv(file = x, header = "important.csv", row.names = FALSE)
```

You can modify (or add) elements of the call with replacement operators:

```R
x$col.names <- FALSE
x
# read.csv(x, "important.csv", row.names = FALSE, col.names = FALSE)

x[[5]] <- NULL
x[[3]] <- "less-imporant.csv"
x
# read.csv(x, "less-imporant.csv", row.names = FALSE)
```

Calls also support the `[` method, but use it with care: it produces a call object, and it's easy to produce invalid calls. If you want to get a list of the arguments, explicitly convert to a list.

```R
x[-3] # remove the second arugment
# read.csv(x, row.names = FALSE)

x[-1] # just look at the arguments - but is still a call!
x("important.csv", row.names = FALSE)

as.list(x[-1])
# [[1]]
# x
# 
# [[2]]
# [1] "important.csv"
# 
# $row.names
# [1] FALSE
```

### Cautions

Computing on the language is an extremely powerful tool, but it can also create code that is hard for others to understand. Before you use it, make sure that you have exhausted all other possibilities. This section shows a couple of examples of inappropriate use of computing on the language that you should avoid reproducing.

Typically, computing on the language is most useful for functions called directly by the user, not by other functions. For example, you might try using `subset()` from within a function that is given the name of a variable and it's desired value:

      colname <- "cyl"
      val <- 6

      subset(mtcars, colname == val)
      # Zero rows because "cyl" != 6

      col <- as.name(colname)
      substitute(subset(mtcars, col == val), list(col = col, val = val))
      bquote(subset(mtcars, .(col) == .(val)))

Typically, it's better to avoid the function that does non-standard evaluation, and use the underlying verbose code.  In this case, use subsetting, not the subset function:

```R
mtcars[mtcars[[colname]] == val, ]
```

`write.csv` is a base R function where call manipulation is used inappropriately:

```R
write.csv <- function (...) {
  Call <- match.call(expand.dots = TRUE)
  for (argname in c("append", "col.names", "sep", "dec", "qmethod")) {
    if (!is.null(Call[[argname]])) {
      warning(gettextf("attempt to set '%s' ignored", argname), domain = NA)
    }
  }
  rn <- eval.parent(Call$row.names)
  Call$append <- NULL
  Call$col.names <- if (is.logical(rn) && !rn) TRUE else NA
  Call$sep <- ","
  Call$dec <- "."
  Call$qmethod <- "double"
  Call[[1L]] <- as.name("write.table")
  eval.parent(Call)
}
```

We could write a function that behaves identically using regular function call semantics:

```R
write.csv <- function(x, file = "", sep = ",", qmethod = "double", ...) {
  write.table(x = x, file = file, sep = sep, qmethod = qmethod, ...)
}
```

This makes the function much much easier to understand - it's just calling `write.table` with different defaults.  This also fixes a subtle bug in the original `write.csv` - `write.csv(mtcars, row = FALSE)` does not turn off rownames, but `write.csv(mtcars, row.names = FALSE)` does. Generally, you always want to use the simplest tool that will solve a problem - that makes it more likely that others will understand your code.

### Exercises

* Read the source code for `pryr::partial` and refer to XXX for uses. How does it work?

## Getting the name of an argument


```R
fname <- function(call) {
  f <- eval(call, parent.frame())
  if (is.character(f)) {
    fname <- f
    f <- match.fun(f)
  } else if (is.function(f)) {
    fname <- if (is.symbol(call)) as.character(call) else "<anonymous>"
  }
  list(f, fname)
}
f <- function(f) {
  fname(substitute(f))
}
f("mean")
f(mean)
f(function(x) mean(x))
```


## Creating a function

Building up a function by hand is also useful when you can't use a closure because you don't know in advance what the arguments will be. We'll use `pryr::make_function` to build up a function from its components pieces: an argument list, a quoted body (the code to run) and the environment in which it is defined (which defaults to the current environment):

```R
add <- make_function(alist(a = 1, b = 2), quote(a + b))
```

Note that to use this function we need to use the special `alist` function to create an **a**rgument list.

```R
add2 <- make_function(alist(a = 1, b = a), quote(a + b))
add(1)
add(1, 2)

add3 <- make_function(alist(a = , b = ), quote(a + b))
```

We could use `make_function` to create an `unenclose` function that takes a closure and modifies it so when you look at the source you can see what's going on: 

```R
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
```

(Note we need to use `substitute2` here, because `substitute` doesn't evaluate its arguments).

(Exercise: modify this function so it only substitutes in atomic vectors, not more complicated objects.)

## Walking the code tree

Because code is a tree, we're going to need recursive functions to work with it. You now have basic understanding of how code in R is put together internally, and so we can now start to write some useful functions. In this section we'll write functions to:

* List all assignments in a function
* Replace `T` with `TRUE` and `F` with `FALSE`
* Replace all calls with their full form

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

The nodes of the tree can be any recursive data structure that can appear in a quoted object: pairlists, calls, and expressions. The leaves can be 0-argument calls (e.g. `f()`), atomic vectors, names or `NULL`. The easiest way to tell the difference is the `is.recursive` function.

In this section, we will write a function that figures out all variables that are created by assignment in an expression. We'll start simply, and make the function progressively more rigorous. One reason to start with this function is because the recursion is a little bit simpler - we never need to go all the way down to the leaves because we are looking for assignment, a call to `<-`.  

This means that our base case is simple: if we're at a leaf, we've gone too far and can immediately return. We have two other cases: we have hit a call, in which case we should check if it's `<-`, otherwise it's some other recursive structure and we should call the function recursively on each element. Note the use of identical to compare the call to the name of the assignment function, and recall that the second element of a call object is the first argument, which for `<-` is the left hand side: the object being assigned to.

```R
is_call_to <- function(x, name) {
  is.call(x) && identical(x[[1]], as.name(name))
}

find_assign <- function(obj) {
  # Base case
  if (!is.recursive(obj)) return(character())

  if (is_call_to(obj, "<-")) {
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
  # Base case
  if (!is.recursive(obj)) return(character())

  if (is_call_to(obj, "<-")) {
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

This is better, but we have two problems: repeated names, and we miss assignments inside function calls. The fix for the first problem is easy: we need to wrap `unique` around the recursive case to remove duplicate assignments. The second problem is a bit more subtle: it's possible to do assignment within the arguments to a call, but we're failing to recurse down in to this case. 

```R
find_assign <- function(obj) {
  # Base case
  if (!is.recursive(obj)) return(character())

  if (is_call_to(obj, "<-")) {
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
  # Base case
  if (!is.recursive(obj)) return(character())

  if (is_call_to(obj, "<-")) {
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

A more useful function might solve a common problem encountered when running `R CMD check`: you've used `T` and `F` instead of `TRUE` and `FALSE`.  Again, we'll pursue the same strategy of starting simple and then gradually building up our function to deal with more cases.

First we'll start just by locating logical abbreviations. A logical abbreviation is the name `T` or `F`. We need to recursively breakup any recursive objects, anything else is not a short cut.

    find_logical_abbr <- function(obj) {
      if (!is.recursive(obj)) {
        identical(obj, as.name("T")) || identical(obj, as.name("F"))
      } else {
        any(vapply(obj, find_logical_abbr, logical(1)))
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

* pairlists, which are used for function formals, can be processed as lists,
  but need to be turned back into pairlists with `as.pairlist`

* expressions, again can be processed like lists, but need to be turned back
  into expressions objects with `as.expression`. You won't find these inside a
  quoted object, but this might be the quoted object that you're passing in.

* calls require the most special treatment: don't process first element
  (that's the name of the function), and turn back into a call with `as.call`

We'll wrap this behaviour up into a function

```R
capply <- function(X, FUN, ...) {
  if (is.call(X)) {
    args <- lapply(X[-1], FUN, ...)
    as.call(c(list(X[[1]]), args))
  } else {
    out <- lapply(X, FUN, ...)

    if (is.function(X)) {
      out <- as.function(out, environment(X))
    } else {
      mode(out) <- mode(X)
    }
    out
  }
}
capply(expression(1, 2, 3), identity)
capply(quote(f(1, 2, 3)), identity)
capply(formals(data.frame), identity)
capply(quote(function(x) x + 1), identity)
```  

This leads to:

    fix_logical_abbr <- function(obj) {
      # Base case
      if (!is.recursive(obj)) {
        if (identical(obj, as.name("T"))) return(TRUE)
        if (identical(obj, as.name("F"))) return(FALSE)
        return(obj)
      }

      capply(obj, fix_logical_abbr)
    }

However, this function is still not that useful because it loses all non-code structure:

    g <- parse(text = "f <- function(x = T) {
      # This is a comment
      if (x)                  return(4)
      if (emergency_status()) return(T)
    }")
    f <- function(x = T) {
      # This is a comment
      if (x)                  return(4)
      if (emergency_status()) return(T)
    }
    fix_logical_abbr(g)
    fix_logical_abbr(f)

If we want to be able to apply this function to an existing code base, we need to be able to maintain all the non-code structure. This leads us to our next code: srcrefs.

## Source references

Srcrefs are a fourth property of functions. R also stores a pointer to the original location of the function (this is why you can see the comments and when you get errors you see the line number).  You can read more about srcrefs in `?srcref` and in the [R journal][srcrefs].

We're going to focus on `getParseData` (a new feature in R 2.16) which gives us the parsed data in a flat data frame format, and includes all of the original comments.


  [srcrefs]: http://journal.r-project.org/archive/2010-2/RJournal_2010-2_Murdoch.pdf


<!-- Idea:
Destructuring assignment
  https://gist.github.com/4543212
  https://github.com/crowding/ptools/blob/master/R/bind.R -->
