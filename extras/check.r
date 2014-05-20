# Tools for checking that a data structure is of the right form

# Basics:
#   mode: character, numeric, integer, logical
#   length: exactly, >, <
#   identical, equal, equivalent
#
# Combining
#  AND, OR, NOT
#
# Recursive 
#  contains
# 
# Operators
#   &, |  (to replace and?or)
#   Logic
#   == (to replace check)

# Building a DSL:
# LENGTH() == 4, LENGTH() > 4, LENGTH() != 2
# LENGTH() %% 2 == 0
# PARTS(1, 3, 5) == c("A", "B", "C")
# PARTS() = rep(c(PATTERN("a", "b")))
# PARTS() = rep(c(PATTERN("a"), ANY()))
# MODE() == "character", IS_A(x, character)

# Exercises:
#  * do a similar thing for regular expressions or xpath (small part of each)

new_check <- function(attr, subclass = NULL) {
  structure(attr, class = c(subclass, "check"))
} 

is.check <- function(x) 
print.check <- function(x) cat(format(x), "\n")

length_equals <- function(n) {
  new_check(list(n = n), "length_equal")
}
check.length_equal <- function(check, x) length(x) == check$n
format.length_equal <- function(check) paste("length(x) ==", check$n)

NOT <- function(check) {
  stopifnot(is.check(check))
  new_check(list(check = check), "NOT")
}

check.NOT <- function(check, x) !(check$check(x))
format.NOT <- function(check) {
  paste("NOT: ", NextMethod())
}

length_between <- function(min = -Inf, max = Inf) {
  new_check(list(min = min, max = max), "length_between")
}
check.length_between <- function(check, x) {
  length(x) > check$min && length(x) < check$max
}
format.length_between <- function(check) {
  paste("length(x) in [", check$min, ", ", check$max, "]", sep = "")
}

ANY <- function() {
  new_check(list(), "any")
}
check.any <- function(check, x) TRUE

has_mode <- function()

# Either actual values or checks
# contains(ANY(), 1:4, AND(length_between(1, 10), is_character()))
contains <- function(...) {
  elements <- list(...)
}

or <- function(a, b) {
  list(
    check = function(x) a$check(x) || b$check(x),
    message = paste(a$name, "OR", b$name)
  )
}

and <- function(a, b) {
  list(
    check = function(x) a$check(x) && b$check(x),
    message = paste(a$name, "OR", b$name)
  )
}

