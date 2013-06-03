# User facing function
#
# to_math(x[1] + 1^{2 + 4} + 5 + sqrt(y) / 5 %/% 10)
# to_math(paste(x^2, y - 1, z_i))
# to_math(hat(tilde(ring(x))))
# to_math(pi*r^2)
# to_math(unknown_call(x, floor(sqrt(z))))
# to_math(u1(x) + u2(x))
to_math <- function(x) {
  x <- substitute(x)
  env <- latex_env(x)
  eval(x, env)
}

latex_env <- function(expr) {
  # Default for unknown functions
  unknown <- setdiff(all_calls(expr), ls(fenv))
  default_env <- ceply(unknown, unknown_op, parent = emptyenv())

  # Known R -> latex functions
  special_calls <- copy_env(fenv, parent = default_env)

  # Existing symbols in expression
  names <- all_names(expr)
  name_env <- ceply(names, force, parent = special_calls)

  # Known latex expressions
  symbol_env <- copy_env(senv, parent = name_env)
  symbol_env
}

# Functions --------------------------
fenv <- new.env(parent = emptyenv())

unknown_op <- function(op) {
  force(op)
  function(...) {
    contents <- paste(..., collapse=", ")
    paste0("\\mathtt{", op, "} \\left( ", contents, " \\right )")
  }
}

# Helper functions
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

# Binary operators
fenv$"+" <- binary_op(" + ")
fenv$"-" <- binary_op(" - ")
fenv$"*" <- binary_op(" * ")
fenv$"/" <- binary_op(" / ")
fenv$"%+-%" <- binary_op(" \\pm ")
fenv$"%/%" <- binary_op(" \\ ")
fenv$"%*%" <- binary_op(" \\times ")
fenv$"%.%" <- binary_op(" \\cdot ")
fenv$"[" <- binary_op("_")
fenv$"^" <- binary_op("^")

# Grouping
fenv$"{" <- unary_op("\\left{ ", " \\right}")
fenv$"(" <- unary_op("\\left( ", " \\right)")
fenv$paste <- paste

# Other math functions
fenv$sqrt <- unary_op("\\sqrt{", "}")
fenv$log <- unary_op("\\log{", "}")
fenv$inf <- unary_op("\\inf{", "}")
fenv$sup <- unary_op("\\sup{", "}")
fenv$abs <- unary_op("\\left| ", "\\right| ")
fenv$floor <- unary_op("\\lfloor", " \\rfloor ")
fenv$ceil <- unary_op(" \\lceil ", " \\rceil ")
fenv$frac <- function(a, b) {
  paste0("\\frac{", a, "}{", b, "}")
}

# Labelling
fenv$hat <- unary_op("\\hat{", "}")
fenv$tilde <- unary_op("\\tilde{", "}")
fenv$dot <- unary_op("\\dot{", "}")
fenv$ring <- unary_op("\\ring{", "}")

# Symbols --------------------------
symbols <- c(
  "alpha", "theta", "tau", "beta", "vartheta", "pi", "upsilon", "gamma", "gamma",
  "varpi", "phi", "delta", "kappa", "rho", "varphi", "epsilon", "lambda",
  "varrho", "chi", "varepsilon", "mu", "sigma", "psi", "zeta", "nu", "varsigma",
  "omega", "eta", "xi", "Gamma", "Lambda", "Sigma", "Psi", "Delta", "Xi",
  "Upsilon", "Omega", "Theta", "Pi", "Phi")
slatex <- setNames(paste0("\\", symbols), symbols)
senv <- list2env(as.list(slatex), parent = emptyenv())

# Utility functions --------------

all_calls <- function(x) {
  if (!is.call(x)) return(NULL)

  fname <- as.character(x[[1]])
  unique(c(fname, unlist(lapply(x[-1], all_calls), use.names = FALSE)))
}

all_names <- function(x) {
  if (is.name(x)) return(as.character(x))
  if (!is.call(x)) return(NULL)

  unique(unlist(lapply(x[-1], all_names), use.names = FALSE))
}

copy_env <- function(env, parent = parent.env(env)) {
  list2env(as.list(env), parent = parent)
}

# character vector -> environment
ceply <- function(x, f, ..., parent = parent.frame()) {
  l <- lapply(x, f, ...)
  names(l) <- x
  list2env(l, parent = parent)
}
