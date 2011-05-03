# Computing on the language

Manipulating calls, expressions, formula and functions

* Code to text and back again
* Modifying an expression with `substitute` and `bquote`
* Extracting components of an expression
* Walking the code tree
* The parser package

## Basics of R code

There are three fundamental building blocks of R code:

* __names__s, which represent the name, not value, of a variable
* __constants__s, like `"a"` or `1:10`
* __calls__s, which represents a function call

Collectively I'll call these three thing code chunks, because they each represent a stand-alone piece of R code that you could run from the command line. 

A call is made up of two parts:

* a name, giving the name of the function to be called
* arguments, a list of code chunks

Calls are recursive because the arguments to a call can be other calls, e.g. `f(x, 1, g(), h(i()))`. This means we can think about calls as trees. For example, we can represent that call as:

    \- f()
       \- x
       \- 1
       \- g()
       \- h()
          \- i()

Everything in R parses into this tree structure - even things that don't look like calls such as `{`, `function`, control flow, infix operators and assignment. The figure below shows the parse tree for some of these special constructs.

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

Code chunks can be built up into larger structures in two ways: with expressions or braced expressions. Expressions are lists of code chunks, and are created when you parse a file. Braced expressions represent complex multiline functions as a call to the special function `{`, with one argument for each code chunk in the function. Despite the name, braced expressions are not actually expressions, although the accomplish much the same task.  



## Code to text and back again

`deparse`, `as.character`.  Be careful that you're prepared for multiple lines.

Common idiom: `deparse(substitute(x))`, but must be before the promise is evaluated.

Why you shouldn't use regular expressions on the textual representation of code.

`parse(text = ...)`

## Modifying an expression

Substitute.

A useful shorthand is bquote.

## Extracting components of an expression

Using srccode refs to provide information about location in original file.

* function calls
* ?
* control flow: if, while, etc.
* function "function"
* bracketed expressions
* replacement
* binary operators
* unary operators

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


