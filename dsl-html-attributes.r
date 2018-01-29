html_attributes <- function(list) {
  if (length(list) == 0) return("")

  attr <- map2_chr(names(list), list, html_attribute)
  paste0(" ", unlist(attr), collapse = "")
}
html_attribute <- function(name, value = NULL) {
  if (length(value) == 0) return(name) # for attributes with no value
  if (length(value) != 1) stop("`value` must be NULL or length 1")

  if (is.logical(value)) {
    # Convert T and F to true and false
    value <- tolower(value)
  } else {
    value <- escape_attr(value)
  }
  paste0(name, "='", value, "'")
}
escape_attr <- function(x) {
  x <- escape.character(x)
  x <- gsub("\'", '&#39;', x)
  x <- gsub("\"", '&quot;', x)
  x <- gsub("\r", '&#13;', x)
  x <- gsub("\n", '&#10;', x)
  x
}
