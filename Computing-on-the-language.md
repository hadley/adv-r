# Computing on the language

Manipulating calls, expressions, formula and functions

* Code to text and back again
* Modifying an expression with `substitute` and `bquote`
* Extracting components of an expression
* Walking the code tree
* The parser package

Make sure that you're familiar with:

* symbols:
* calls:
* expressions:

## Code to text and back again

`deparse`, `as.character`

Why you shouldn't use regular expressions on the textual representation of code.

## Modifying an expression

A useful shorthand is bquote.

## Extracting components of an expression

Using srccode refs to provide information about location in original file.

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


