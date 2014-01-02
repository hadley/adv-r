library(RJSONIO)

parse_md <- function(in_path) {
  out_path <- tempfile()
  on.exit(unlink(out_path))
  cmd <- paste0("pandoc -f markdown -t json -o ", out_path, " ", in_path)
  system(cmd)
  
  fromJSON(out_path)
}

type <- function(x) vapply(x, "[[", "t", FUN.VALUE = character(1))
contents <- function(x) lapply(x, "[[", "c")
id <- function(x) x[[2]][[1]]

headers <- function(in_path) {
  x <- parse_md(in_path)
  body <- x[[2]]
  headers <- contents(body[type(body) == "Header"])
  
  vapply(headers, id, FUN.VALUE = character(1))  
}

# action(key, value, format, meta)
#  key is the type of the pandoc object (e.g. 'Str', 'Para')
#  value is the contents of the object (e.g. a string for 'Str', a list of 
#     inline elements for 'Para')
#  format is the target output format (which will be taken for the first 
#    command line argument if present)
#  meta is the document's metadata. 
#
# Return values: 
#   NULL, the object to which it applies will remain unchanged. 
#   If it returns an object, the object will be replaced. 
#   If it returns a list, the list will be spliced in to the list to which the 
#     target object belongs. (So, returning an empty list deletes the object.)
  stopifnot(length(x) == 2, identical(names(x[[1]]), "unMeta"))
walk <- function(x, action) {
  meta <- contents(x[[1]]$unMeta)
  names(meta) <- names(type(x[[1]]$unMeta))
  
  
  
}