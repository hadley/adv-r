nesting <- function(f) {
  if (!is.function(f)) return(0L)
  depth(body(f))
}
depth <- function(f, i = 0L) {
  if (!is.call(f) || length(f) == 1) return(i)

  if (identical(f[[1]], as.name("{"))) i <- i + 1L

  depths <- vapply(as.list(f[-1]), depth, i = i, FUN.VALUE = integer(1))
  max(depths)
}
nest <- vapply(ls("package:base"), function(x) nesting(get(x)), integer(1))
names(nest)[nest == max(nest)]
