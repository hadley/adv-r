library(stringr)

# Convert an Rmd file to a md file using custom knitr options
# Inputs and outputs paths
rmd2md <- function(in_path, out_path = tempfile(fileext = ".md")) {
  library(knitr)

  collapse <- function(x, options) {
    paste0("\n", paste0(x, collapse = "\n"))
  }
  
  set.seed(1410)
  options(digits = 3)
  knit_hooks$set(
    source = function(x, options) paste(x, collapse = "\n"),
    output = collapse,
    warning = collapse,
    error = collapse,
    message = collapse,
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
      out <- paste0("```", options$engine, "\n", x, "```")

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
    comment = "#>",
    error = FALSE,
    tidy = FALSE,
    cache.path = "_cache/",
    fig.width = 4,
    fig.height = 4,
    dev = "png"
  )
  
  knit(in_path, out_path, quiet = TRUE)
  out_path
}

# Convert a md file to html using pandoc
md2html <- function(in_path, out_path = tempfile(fileext = ".html")) {
  cmd <- paste0("pandoc -f markdown -t html -o ", out_path, " ", in_path)
  system(cmd)
  
  out_path
}

rmd2html <- function(path, cache = FALSE, fix_links = TRUE) {
  
  if (cache) {
    md_path <- cache_file(path, rmd2md, ".md")
    if (fix_links) update_links(md_path)
    cache_file(md_path, md2html, ".html")
  } else {
    md_path <- rmd2md(path)
    if (fix_links) update_links(md_path)
    md2html(md_path)
  }
  
}

#' @param f A function with two input arguments: in_path and out_path
cache_file <- function(in_path, f, ext) {
  hash <- digest::digest(in_path, file = TRUE)
  cache_path <- paste0("_cache/", hash, ext)

  if (!file.exists("_cache")) {
    dir.create("_cache")
  }
    
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

check_all <- function(start = NULL) {
  
  files <- dir(pattern = "\\.rmd$")
  if (!is.null(start)) {
    match <- grep(start, files)[1]
    if (length(match) > 0) {
      files <- files[match:length(files)]
    }
  }
  
  for (file in files) {
    message("Knitting ", file)
    message("----------------------------------------------------")
    rmd2md(file)
  }
}

# Convert internal links to explicit links also containing the file name
update_links <- function(path) {
  contents <- paste0(readLines(path, warn = FALSE), collapse = "\n")
  
  int_link_pos <- str_locate_all(contents, "\\(#([^)]*)\\)")[[1]]
  int_link <- str_sub(contents, 
    int_link_pos[, "start"] + 2, # (#
    int_link_pos[, "end"] - 1    # )
  )
  
  replacement <- vapply(int_link, lookup, character(1))
  
  for(i in rev(seq_len(nrow(int_link_pos)))) {
    start <- int_link_pos[i, "start"] + 1
    end <- int_link_pos[i, "end"] - 1
    str_sub(contents, start, end) <- replacement[i]
  }
  
  writeLines(contents, path)
}
