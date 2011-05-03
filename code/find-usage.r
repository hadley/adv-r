
find_calls <- function(obj) {  
  if (is.call(obj)) {
    f <- deparse(obj[[1]])
    c(f, compact(lapply(as.list(obj[-1]), find_calls)))
  }
}

funs <- function(x) {
  if (!is.function(x)) return()
  unlist(find_calls(body(x)))
  # parsed <- attr(parser::parser(text = deparse(body(x))), "data")
  # subset(parsed, token.desc == "SYMBOL_FUNCTION_CALL")$text
}
is.interactive <- function(x) {
  any("match.call" %in% funs(get(x)))
  # any(c("substitute", "match.call") %in% funs(get(x)))
}

fs <- ls("package:stats")
fs[sapply(fs, is.interactive)]

# Examples of what you shouldn't do
#  data.framedas
#  write.csv
 -->


bdy <- body(write.csv)
is.call(bdy)
bdy[[1]]

as.list(body(write.csv)[-1]))

f <- function() { 
  x <- 1
  y <- 2
  
  g <- function() {
    x + y
  }
  
  z <- 3
  g()
}

bdy <- as.expression(as.list(body(f)[-1]))
compact <- function(x) Filter(Negate(is.null), x)


find_calls <- function(obj) {  
  if (is.call(obj)) {
    f <- deparse(obj[[1]])
    c(f, compact(lapply(as.list(obj[-1]), find_calls)))
  }
}
find_calls(body(match.call))
find_calls(body(write.csv))


find_assign <- function(obj) {  
  assigns <- character(0)
  
  if (is.call(obj)) {
    f <- deparse(obj[[1]])
    if (f == "<-") {
      assigns <- deparse(obj[[2]])
    }
    c(assigns, sapply(as.list(obj[-1]), find_assign))
  }
}
find_assign(body(write.csv))

unlist(find_assign(body(write.csv)), use.names = F)

f <- function(x) {
  stopifnot(is.call(x))
  
  x[[1]]
}
arguments <- function(x) {
  stopifnot(is.call(x))
  
  as.list(x[-1])
}

make.call <- function(f, arguments) {
  as.call(c(list(f), arguments))
}

x <- quote(f(a + 1, b = c))
identical(make.call(f(x), arguments(x)), x)

x <- quote(function(x) {x + 1}(3))
identical(make.call(f(x), arguments(x)), x)


find_logical_abbr <- function(obj) {
  if (is.name(obj)) {
    identical(obj, as.name("T")) || identical(obj, as.name("F"))
  } else if (is.recursive(obj)) {
    any(vapply(obj, find_logical_abbr, logical(1)))
  } else {
    FALSE
  }
}


fix_logical_abbr <- function(obj) {
  if (is.name(obj)) {
    if (identical(obj, as.name("T"))) {
      quote(TRUE)
    } else if (identical(obj, as.name("F"))) {
      quote(FALSE)
    } else {
      obj
    }
  } else if (is.call(obj)) {
    args <- lapply(obj[-1], fix_logical_abbr)
    as.call(c(list(obj[[1]]), args))
  } else if (is.pairlist(obj)) {
    as.pairlist(lapply(obj, fix_logical_abbr))
  } else if (is.list(obj)) {
    lapply(obj, fix_logical_abbr)
  } else if (is.expression(obj)) {
    as.expression(lapply(obj, fix_logical_abbr))
  } else {
    obj
  }
}


f <- quote(function(x = T) 3)
fix_logical_abbr(f)

g <- parse(text = "f <- function(x = T) {
  # This is a comment
  if (x)                  return(4)
  if (emergency_status()) return(T)
}")
