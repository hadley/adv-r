# The following version of local satisfies the contracts described below,
# but the built in version does not.
local <- function(expr, envir = NULL) {
  if (is.null(envir))
    envir <- new.env(parent = parent.frame())

  eval(substitute(expr), envir)
}

# Default environment created by local should be clean, and have
# globalenv as parent

e2 <- local({
  x <- 1
  environment()
})
ls(e2)
e2$x
parent.env(e2)

# Regardless of how you refer to globalenv(), the following should
# all return the same results, i.e.
# local(..., globalenv()) should be identical to running ... directly

x <- 1
e <- globalenv()

x
local(x, parent.frame())
local(x, environment())
local(x, e)

expr <- 1

expr
local(expr, parent.frame())
local(expr, environment())
local(expr, e)

x <- 1
local(x <- 2, parent.frame())
x
local(x <- 3, environment())
x
local(x <- 4, e)
x

local(x, new.env())
