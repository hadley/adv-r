# Computing on the language

Manipulating calls, expressions, formula and functions

   * `substitute` and `bquote`
   * Pulling an expression into pieces
   * Custom interpretation of a formula

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