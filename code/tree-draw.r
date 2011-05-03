# Draw R expressions as ascii trees
library(stringr)
library(testthat) # for the colourise function

str_trunc <- function(x, width = getOption("width")) {
  ifelse(str_length(x) <= width, x, str_c(str_sub(x, 1, width - 3), "..."))
}

is.constant <- function(x) !is.language(x)
is.leaf <- function(x) {
  is.constant(x) || is.name(x) || (is.call(x) && length(x) == 1)
}

tree <- function(x, level = 1, width = getOption("width")) {
  indent <- str_c(str_dup("   ", level - 1), "\\- ")
  label <- label(x, width - nchar(indent))

  if (is.leaf(x)) {
    str_c(indent, label)
  } else {
    leaves <- vapply(as.list(x[-1]), tree, character(1), 
      level = level + 1, width = width)
    
    str_c(indent, label, "\n", str_c(leaves, collapse = "\n"))
  }
}

label <- function(x, width = getOptions(width)) {
  if (is.call(x)) {
    label <- str_c(deparse(x[[1]])[[1]], "()")
    colour <- "red"
  } else if (is.name(x)) {
    label <- deparse(x)[[1]]
    colour <- "blue"
  } else {
    label <- deparse(x)[[1]]
    colour <- "black"
  }
  colourise(str_trunc(label, width), colour)
}

draw_tree <- function(x, width = getOption("width")) {
  if (is.expression(x) || is.list(x)) {
    trees <- vapply(x, tree, character(1), width = width)
    out <- str_c(trees, collapse = "\n\n")
  } else {
    out <- tree(x, width = width)
  }
  
  cat(out, "\n")
}


draw_tree(quote(f(x, 1, g(), h(i()))))
draw_tree(quote(if (TRUE) 3 else 4))
draw_tree(expression(1, 2, 3))
