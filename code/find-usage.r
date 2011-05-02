library(parser)
funs <- function(x) {
  if (!is.function(x)) return()
  parsed <- attr(parser(text = deparse(body(x))), "data")
  subset(parsed, token.desc == "SYMBOL_FUNCTION_CALL")$text
}
is.interactive <- function(x) {
  any("match.call" %in% funs(get(x)))
  # any(c("substitute", "match.call") %in% funs(get(x)))
}

fs <- ls("package:stats")
fs[sapply(fs, is.interactive)]

# Examples of what you shouldn't do
#  data.frame
#  write.csv
 -->
