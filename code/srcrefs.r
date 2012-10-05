
g <- parse(text = "f <- function(x = T) {
  # This is a comment
  if (x)                  return(4)
  if (emergency_status()) return(T)
}")
attr(g, "srcref")
attr(g, "srcref")[[1]]
as.character(attr(g, "srcref")[[1]])
source(textConnection("f <- function(x = T) {
  # This is a comment
  if (x)                  return(4)
  if (emergency_status()) return(T)
}"))


f <- function(x) {
 if (x > 2) {
    y <- 2
    z <- x + 1
 }
}
