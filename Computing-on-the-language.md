# Computing on the language

Manipulating calls, expressions, formula and functions

   * `substitute` and `bquote`
   * Pulling an expression into pieces
   * Custom interpretation of a formula
   * The parser package

## Missing argument

The missing argument object is a strange beast, that's not at all easy to deal with:

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


## Pulling an expression in to pieces

Example: given a code block, find all the locations where assignment happens, or all function calls. Or all uses of T and F.

Using srccode refs to provide information about location in original file.


## The parser package

Use the parser package to extract all function calls.