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

The `parse` function converts a string into an expression. It's called parse because this is the formal CS name for converting a string representing code into a format that the computer can work with. Note that parse defaults to work within files - if you want to parse a string, you need to use the `text` argument.

The `deparse` function is an almost inverse of `parse` - it converts an call into a text string representing that call. It's an almost inverse because it's impossible to be completely symmetric. Deparse will returns character vector with an entry for each line - if you want a single string be sure to `paste` it back together. 

A common idiom in R functions is `deparse(substitute(x))` - this will capture the character representation of the code provided for the argument `x`. Note that you must run this code before you do anything to `x`, because substitute can only access the code which will be used to compute `x` before the promise is evaluated.

## Modifying calls

It's a bad idea to create code by operating on it's string representation: there is no guarantee that you'll create valid code. Instead, you should use tools like `substitute` and `bquote` to modify expressions, where you are guaranteed to produce syntactically correct code (although of course it's still easy to make code that doesn't work).

We've seen `substitute` used for it's ability to capture the unevalated expression of a promise, but it also has another important role for modifying expressions. The second argument to `substitute`, `env`, can be an environment or list giving a set of replacements. It's easiest to see this with an example:

    substitute(a + b, list(a = 1, b = 2))
    # 1 + 2

Note that `substitute` expects R code in it's first, not parsed code:

    x <- quote(a + b)
    substitute(x, list(a = 1, b = 2))
    # x

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

You can also modify calls because of their list-like behaviour: just like a list, a call has `length`, `'[[` and `[` methods. The length of a call minus 1 gives the number of arguments:

    x <- quote(write.csv(x, "important.csv", row.names = FALSE))
    length(x) - 1
    # [1] 3

The first element of the call is the name of the function:

    x'[[1]]
    # write.csv

    is.name(x'[[1]])
    # [1] TRUE

The remaining elements are the arguments to the function, which can be extracted by name or by position.

    x$row.names
    # FALSE
    x'[[3]]
    # [1] "important.csv"

You can modify elements of the call with replacement operators:

    x$col.names <- FALSE
    x
    # write.csv(x, "important.csv", row.names = FALSE, col.names = FALSE)

    x'[[5]] <- NULL
    x'[[3]] <- "less-imporant.csv"
    x
    # write.csv(x, "less-imporant.csv", row.names = FALSE)

Calls also support the `[` method, but use it with care: it produces a call object, and it's easy to produce invalid calls. If you want to get a list of the arguments, explicitly convert to a list.

    x[-3] # remove the second arugment
    # write.csv(x, row.names = FALSE)

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


## Walking the code tree

Code as a tree.  So need recursive function to walk it.

Example: given a code block, find all the locations where assignment happens, or all function calls. Or all uses of T and F. Or all assignment. Or build a graph that shows dependencies within a code block.

### Codetools

The `codetools` packages provides some pre-built tools based on these ideas:

* `findGlobals`
* `checkUsage`
* `showTree`

## Missing argument

The missing argument object is a strange beast that's not at all easy to deal with:

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

## The parser package

Use the parser package to extract all function calls.

<!-- We can use this idea to crudely identify R functions that may be problematic to program with: -->


