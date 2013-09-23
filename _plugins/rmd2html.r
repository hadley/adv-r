# Convert an Rmd file to a md file using custom knitr options
# Inputs and outputs paths
rmd2md <- function(in_path, out_path = tempfile(fileext = ".md")) {
  library(knitr)

  set.seed(1410)
  options(digits = 3)
  knit_hooks$set(
    source = function(x, options) paste(x, collapse = "\n"), 
    output = function(x, options) {
      paste0("\n", paste0(x, collapse = "\n"))
    }, 
    warning = function(x, options) paste(x, collapse = "\n"), 
    error = function(x, options) paste(x, collapse = "\n"), 
    message = function(x, options) paste(x, collapse = "\n"), 
    plot = function(x, options) {
      url <- paste(x, collapse = ".")
      img <- paste0("<img src='", url, "' ",  
        "width = '", options$out.width %||% 300, "' ", 
        "height = '", options$out.height %||% 300, "' ", 
        "title = '", options$caption, "' ", 
        "/>\n")
      paste0("\n```\n", img, "\n```R\n")
    },
    chunk = function(x, options) {
      ind <- options$indent
      x <- add_trailing_nl(x)
      out <- paste0("```R\n", x, "```")

      if (is.null(ind)) return(out)
      paste0(ind, gsub("\n", paste0("\n", ind), out))
    }, 
    document = function(x, options) {
      x <- paste0(x, collapse = "\n")
      # Remove empty blocks (produced by plot)
      x <- gsub("\n```R\n```\n", "", x)
      x
    }
  )
  opts_chunk$set(
    comment = "#",
    error = TRUE,
    tidy = FALSE,
    cache.path = "_cache/",
    fig.width = 4,
    fig.height = 4,
    dev = "png"
  )
#   opts_knit$set(
#     stop_on_error = 0L
#   )
  
  knit(in_path, out_path, quiet = TRUE)
  out_path
}

# Convert a md file to html using pandoc
md2html <- function(in_path, out_path = tempfile(fileext = ".html")) {
  cmd <- paste0("pandoc -f markdown -t html -o ", out_path, " ", in_path)
  system(cmd)
  
  out_path
}

rmd2html <- function(path, cache = FALSE) {
  
  if (cache) {
    md_path <- cache_file(path, rmd2md, ".md")
    cache_file(md_path, md2html, ".html")
  } else {
    md_path <- rmd2md(path)
    md2html(md_path)
  }
  
}

#' @param f A function with two input arguments: in_path and out_path
cache_file <- function(in_path, f, ext) {
  hash <- digest::digest(in_path, file = TRUE)
  cache_path <- paste0("_cache/", hash, ext)
    
  if (file.exists(cache_path)) {
    if (interactive()) message("For ", in_path, " using cache ", cache_path)
    return(cache_path)
  }
  
  f(in_path, cache_path)
}

add_trailing_nl <- function(x) {
  last <- nchar(x)
  if (substr(x, last, last) == "\n") return(x)
  
  paste0(x, "\n")
}

read_file <- function(path) {
  size <- file.info(path)$size
  readChar(path, size, useBytes = TRUE)
}

subl <- function(path) {
  system(paste0("~/bin/subl ", path))
}

clear_cache <- function() {
  caches <- dir("_cache", pattern = "\\.html$", full.names = TRUE)
  file.remove(caches)
}

"%||%" <- function(a, b) if (is.null(a)) b else a