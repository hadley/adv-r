#' The next DSL we're going to tackle is to convert R expression into their
#' latex math equivalents. (This is a bit like plotmath, but for text output
#' instead of graphical output.).  It is more complicated than the HTML dsl,
#' because not only do we need to convert functions, we also need to convert
#' symbols.  We'll also add a "default" conversion, so that if we don't know
#' how to convert a function, we'll fall back to a standard representation.
#' Like the HTML dsl, we'll also write functionals to make it easier to
#' generated the translators.
#'
#' Before you begin, make sure you're familiar with
#'
#' * scoping rules
#' * creating and manipulating functions
#' * computing on the language
#'
#' Some cases that we'll want to handle:
#'
#' * `x` -> `x`
#' * `pi` -> `pi`
#' * `(a + b) / (c * d)` # simple math & parentheses
#' * `x[1]^2` -> `x_1^2  # subsetting and
#' * `sin(x + pi / 2)` -> `\sin(x + \pi / 2)` # recognise special symbols and functions

#' This time we'll work in the opposite direction: we'll start with the
#' infrastructure and work our way down to generate all the functions we need
#'
#' First we need a wrapper function that we'll use to convert R expressions into
#' latex math expressions. This works the same way as `to_html`: we capture
#' the unevaluated expression and evaluate it in a special environment.

to_math <- function(x) {
  expr <- substitute(x)
  eval(expr, latex_env(expr))
}

#' This time we're going to create that environment with a function, because
#' it's going to be slightly different for every invocation.  We'll start by
#' creating an environment that allows us to convert the special latex symbols
#' used for Greek.  This is the same basic trick used in `subset` to make it
#' possible to select column ranges by name (`subset(mtcars, cyl:wt)`): we
#' just bind a name to a string in a special environment.

greek <- c(
  "alpha", "theta", "tau", "beta", "vartheta", "pi", "upsilon", "gamma", "gamma",
  "varpi", "phi", "delta", "kappa", "rho", "varphi", "epsilon", "lambda",
  "varrho", "chi", "varepsilon", "mu", "sigma", "psi", "zeta", "nu", "varsigma",
  "omega", "eta", "xi", "Gamma", "Lambda", "Sigma", "Psi", "Delta", "Xi",
  "Upsilon", "Omega", "Theta", "Pi", "Phi")
greek_list <- setNames(paste0("\\", symbols), symbols)
greek_env <- list2env(as.list(slatex), parent = emptyenv())

latex_env <- function(expr) {
  greek_env
}

to_math(pi)
to_math(beta)

#' Next, we'll leave any other symbols as is.  This is trickier because we don't
#' know in advance what symbols will be used, and we can't possibly generate
#' them all.  So we'll use a little bit of computing on the language to
#' figure it out: we need a fairy simple recursive function to do this. It takes
#' an expression. If its a name, it converts it to a string. If it's a call,
#' it recurses down through its arguments.

all_names <- function(x) {
  # Base cases
  if (is.name(x)) return(as.character(x))
  if (!is.call(x)) return(NULL)

  # Recursive case
  children <- lapply(x[-1], all_names)
  unique(unlist(children))
}

all_names(quote(x + y + f(a, b, c, 10)))

#' We now want to take that list of names, and convert it to an environment
#' so that each symbol is mapped to a string giving its name. Given a character
#' vector, we need to make it into a list and then convert that list into a
#' environment.

latex_env <- function(expr) {
  names <- all_names(expr)
  symbol_list <- setNames(as.list(names), names)
  symbol_env <- list2env(symbol_list)

  symbol_env
}

to_math(x)
to_math(longvariablename)
to_math(pi)

#' But we want to use both the greek symbols and the default symbols, so we
#' need to combine the environments somehow in the function. Since we want to
#' prefer Greek to the defaults (e.g. `to_math(pi)` should give `"\\pi", not
#' `"pi"`), `symbol_env` needs to be the parent of `greek_env`.  That
#' necessitates copying `greek_env`.  Strangely R doesn't come with a function
#' for cloning environments, but we can easily create one by combining two
#' existing functions:

clone_env <- function(env, parent = parent.env(env)) {
  list2env(as.list(env), parent = parent)
}

latex_env <- function(expr) {
  # Default for names in expression is to convert to string equivalent
  names <- all_names(expr)
  symbol_list <- setNames(as.list(names), names)
  symbol_env <- list2env(symbol_list)

  #
  clone_env(greek_env, symbol_env)
}

to_math(x)
to_math(longvariablename)
to_math(pi)

#' Next we want add some functions to our DSL.  We'll start with a couple of
#' helper closures that make it easy to add new unary and binary operators.
#' These functions are very simple since they only have to assemble strings.

unary_op <- function(left, right) {
  function(e1) {
    paste0(left, e1, right)
  }
}

binary_op <- function(sep) {
  function(e1, e2) {
    paste0(e1, sep, e2)
  }
}

#' Then we'll populate an environment with functions created this way. The list
#' below isn't comprehensive, but it should give a good flavour of the
#' possibilities

# Binary operators
fenv <- new.env(parent = emptyenv())
fenv$"+" <- binary_op(" + ")
fenv$"-" <- binary_op(" - ")
fenv$"*" <- binary_op(" * ")
fenv$"/" <- binary_op(" / ")
fenv$"^" <- binary_op("^")
fenv$"[" <- binary_op("_")

# Grouping
fenv$"{" <- unary_op("\\left{ ", " \\right}")
fenv$"(" <- unary_op("\\left( ", " \\right)")
fenv$paste <- paste

# Other math functions
fenv$sqrt <- unary_op("\\sqrt{", "}")
fenv$sin <- unary_op("\\sin(", ")")
fenv$log <- unary_op("\\log(", ")")
fenv$abs <- unary_op("\\left| ", "\\right| ")
fenv$frac <- function(a, b) {
  paste0("\\frac{", a, "}{", b, "}")
}

# Labelling
fenv$hat <- unary_op("\\hat{", "}")
fenv$tilde <- unary_op("\\tilde{", "}")

#' We again modify `latex_env()` to include this environment. It should be
#' the first environment in which names are looked for (because of R's matching
#' rules wrt functions vs. other objects)

latex_env <- function(expr) {
  # Default symbols
  names <- all_names(expr)
  symbol_list <- setNames(as.list(names), names)
  symbol_env <- list2env(symbol_list)

  # Known symbols
  greek_env <- clone_env(greek_env, parent = symbol_env)

  # Known functions
  clone_env(f_env, greek_env)
}

to_math(sin(x + pi))
to_math(log(x_i^2))


#' Finally, we'll add a default for functions that we don't know about. Like the
#' unknown names, we can't know in advance what these will be, so we again use
#' a little computing on the language to figure them out:

all_calls <- function(x) {
  # Base name
  if (!is.call(x)) return(NULL)

  # Recursive case
  fname <- as.character(x[[1]])
  children <- lapply(x[-1], all_calls)
  unique(c(fname, unlist(children, use.names = FALSE)))
}

all_calls()

#' And we need a closure that will generate the functions for each unknown
#' call

unknown_op <- function(op) {
  force(op)
  function(...) {
    contents <- paste(..., collapse=", ")
    paste0("\\mathtt{", op, "} \\left( ", contents, " \\right )")
  }
}

#' And again we update `latex_env()`:

latex_env <- function(expr) {
  # Default symbols
  symbols <- all_names(expr)
  symbol_list <- setNames(as.list(symbols), symbols)
  symbol_env <- list2env(symbol_list)

  # Known symbols
  greek_env <- clone_env(greek_env, parent = symbol_env)

  # Default functions
  calls <- all_calls(expr)
  call_list <- lapply(calls, unknown_op)
  call_env <- list2env(call_list, parent = greek_env)

  # Known functions
  clone_env(f_env, greek_env)
}

# character vector -> environment
ceply <- function(x, f, ..., parent = parent.frame()) {
  l <- lapply(x, f, ...)
  names(l) <- x
  list2env(l, parent = parent)
}

latex_env <- function(expr) {
  # Default symbols
  symbol_env <- ceply(all_names(expr), identity, parent = emptyenv())

  # Known symbols
  greek_env <- clone_env(greek_env, parent = symbol_env)

  # Default functions
  call_env <- ceply(all_calls(expr), unknown_op, parent = greek_env)

  # Known functions
  clone_env(f_env, greek_env)
}

#' Exercises:
#'
#' * complete this DSL to support all the functions that `plotmath` supports
#'
