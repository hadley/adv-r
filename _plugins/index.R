library(RJSONIO)
library(yaml)

# Strategy: before running jekyll, parse all .Rmd files and build index
# Modify rmd2md to add json pass that modifies links

# Use pandoc to parse a markdown file
parse_md <- function(in_path) {
  out_path <- tempfile()
  on.exit(unlink(out_path))
  cmd <- paste0("pandoc -f markdown -t json -o ", out_path, " ", in_path)
  system(cmd)
  
  fromJSON(out_path, simplify = FALSE)
}

type <- function(x) vapply(x, "[[", "t", FUN.VALUE = character(1))
contents <- function(x) lapply(x, "[[", "c")
id <- function(x) x[[2]][[1]]

extract_headers <- function(in_path) {
  x <- parse_md(in_path)
  body <- x[[2]]
  headers <- contents(body[type(body) == "Header"])
  
  vapply(headers, id, FUN.VALUE = character(1))  
}

build_index <- function() {
  rmd <- dir(pattern = "\\.rmd$")
  headers <- lapply(rmd, extract_headers)
  names(headers) <- rmd
  
  # Save in human readable and R readable
  cat(as.yaml(headers), file = "toc.yaml")
  saveRDS(invert(headers), "toc.rds")
}

link_type <- function(url) {
  ifelse(grepl("^#", url), "internal", 
    ifelse(grepl("^[a-z]+://", url), "external", 
      "bad"))
}

# Check that all the links in a file are good
check_file <- function(path) {
  index <- readRDS("toc.rds")
  body <- parse_md(path)[[2]]
  
  get_link <- function(type, contents, format, meta) {
    if (type == "Link") 
      contents[[2]][[1]]
  }
  links <- walk_inline(body, get_link)
  type <- link_type(links)
  
  links_by_type <- split(links, type)
  if (length(links_by_type$bad) > 0) {
    message("Bad links: ", paste0(links_by_type$bad, collapse = ", "))
  }
  lapply(links_by_type$interal, lookup, index)
  invisible()
}

lookup <- function(name, index = readRDS("toc.rds")) {
  path <- index[[name]]
  if (length(path) == 0) {
    stop("Can't find ref '", name, "'", call. = FALSE)
  } else if (length(path) > 1) {
    stop("Amibugous ref '", name, "' found in ", paste0(path, collapse = ", "),
      call. = FALSE)
  }
  
  paste0(gsub(".rmd", ".html", path), "#", name)
}

invert <- function(x) {
  if (length(x) == 0) return()
  unstack(rev(stack(x)))
}

# Walkers ----------------------------------------------------------------------

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

# Walker translated from
# https://github.com/jgm/pandocfilters/blob/master/pandocfilters.py
# Data types at
# http://hackage.haskell.org/package/pandoc-types-1.12.3/docs/Text-Pandoc-Definition.html
walk <- function(x, action, format = NULL, meta = NULL) {  
  # Base cases
  if (is.null(x)) return()
  if (is.node(x)) return(action(x$t, action$c, format, meta))
  
  lapply(walk, x, action, format = format, meta = meta)
}

# action must return homogenous output
walk_inline <- function(x, action, format = NULL, meta = NULL) {
  
  recurse <- function(x) {
    unlist(lapply(x, walk_inline, action, format = format, meta = meta), 
      recursive = FALSE)
  }

  # Bare list 
  if (is.null(names(x))) return(recurse(x))
  if (!is.list(x)) browser()
  
  switch(x$t, 
    # A list of inline elements
    Plain = ,
    Para = recurse(x$c),
    CodeBlock = NULL,
    RawBlock = NULL,
    # A list of blocks
    BlockQuote = recurse(x$c),
    # Attributes & a list of items, each of which is a list of blocks
    OrderedList = unlist(lapply(x$c[[2]], recurse)),
    # List of items, each a list of blocks
    BulletList = unlist(lapply(x$c, recurse)),
    # Each list item is a pair consisting of a term (a list of inlines) and 
    # one or more definitions (each a list of blocks)
    DefintionList = unlist(lapply(x$c, function(x) recurse(x[[1]]), recurse(x[[2]]))),
    # Third element is list of inlines  
    Header = recurse(x$c[[3]]),
    HorizontalRule = NULL,
    # First element is caption, 4th element column eaders, 5th table rows (list
    # of cells)
    Table = c(recurse(x$c[[1]]), recurse(x$c[[4]]), unlist(lapply(x$c[[5]], recurse))),
    # Second element is list of blocks
    Div = recurse(x$c[[2]]),
    Null = Null,
    # Anything else must be a inline element
    action(x$t, x$c, format = format, meta = meta)
  )
}
