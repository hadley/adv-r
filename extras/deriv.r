# Chain rule: d/dx f(g(x)) =f'(g(x)) g'(x)
# How to specify variable? (i.e. how to pass additional variables in )
# http://mitpress.mit.edu/sicp/full-text/sicp/book/node39.html

is.variable <- function(x) is.name(x)
is.constant <- function(x) is.numeric(x) && length(x) == 1

denv <- new.env(parent = emptyenv())

denv$"+" <- function(e1, e2) {
  d1 <- deriv(substitute(e1))
  d2 <- deriv(substitute(e2))

  substitute(d1 + d2)
}

denv$"*" <- function(e1, e2) {
  d1 <- deriv(substitute(e1))
  d2 <- deriv(substitute(e2))

  substitute(e1 * d2 + e2 * d1)
}

denv$exp <- function(x) {
  substitute(exp(x))
}

denv$log <- function(x) {
  substitute(1 / x)
}
denv$"^" <- function(e1, e2) {
  e1 <- substitute(e1)
  e2 <- substitute(e2)

  if (is.numeric(e1) && is.numeric(e2)) return(e1 ^ e2)


  if (is.name(e1) && is.numeric(e2)) {
    exp <- e2 - 1
    if (exp == 0) return(1L)
    if (exp == 1) return(e1)
    substitute(e1 ^ exp)
  } else if (is.name(e2) && is.numeric(e1)) {
    substitute(log(e1) * e1 ^ x)
  } else {
    # chain rule
    stop()
  }
}

denv$sin <- function(x) {
  substitute(cos(x))
}

denv$cos <- function(x) {
  x <- substitute(x)

  if (is.constant(x) return(0)
  if (is.wrt(x)) substitute(-sin(x))

  chain_rule(cos, x)
}

chain_rule <- function(f, g) {
  deriv(substitute(f))
}

get_var <- function() denv$wrt
set_var <- function(x) {
  old <- denv$wrt
  denv$wrt <- x
  old
}
is.wrt <- function(x) identical(x, get_var())

with_var <- function(x, var) {
  old <- set_var(substitute(x))
  on.exit(set_var(old))
}

is.constant <- function(x) {
  is.numeric(x) || (is.name(x) && !is.wrt(x))
}

deriv <- function(x) {
  if (is.constant(x)) return(0)
  if (is.wrt(x)) return(1)

  eval(x, denv)
}

set_var(quote(x))
