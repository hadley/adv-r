# library(parser)
library(stringr)

compact <- function(x) Filter(Negate(is.null), x)

find_calls <- function(obj) {  
  if (is.call(obj)) {
    f <- as.character(obj[[1]])
    c(f, unlist(lapply(obj[-1], find_calls), use.names = FALSE))
  }
}
# find_calls(body(match.call))
# find_calls(body(write.csv))

calls <- function(x) find_calls(body(x))
args <- function(x) names(formals(x))

#' @examples
#' find_f("package:stats", calls, fixed("match.fun"))
#' find_f("package:stats", args, "^[A-Z]+$")
find_f <- function(env, extract, pattern) {
  if (length(pattern) > 1) pattern <- str_c(pattern, collapse = "|")

  fs <- ls(env)
    
  test <- function(x) {
    f <- get(x, env)
    if (!is.function(f)) return(FALSE)

    any(str_detect(extract(x), pattern))
  }
  
  Filter(test, fs)
}

find_uses <- function(env, pattern) find_f(env, calls, pattern)
find_args <- function(env, pattern) find_f(env, args, pattern)
