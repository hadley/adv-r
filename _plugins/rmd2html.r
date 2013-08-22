# Convert an Rmd file to a md file using custom knitr options
# Inputs and outputs paths
rmd2md <- function(in_path, out_path = tempfile(fileext = ".md")) {
  library(knitr)

  set.seed(1410)
  options(digits = 3)
  knit_hooks$set(
    source = function(x, options) x, 
    output = function(x, options) x,
    warning = function(x, options) x, 
    error = function(x, options) x, 
    message = function(x, options) x,
    inline = function(x) x,
    plot = hook_plot_md,
    chunk = function(x, options) {
      ind <- options$indent
      out <- paste0("```R\n", x, "```")

      if (is.null(ind)) return(out)
      paste0(ind, gsub("\n", paste0("\n", ind), out))
    }
  )
  opts_chunk$set(
    comment = "#",
    error = TRUE,
    tidy = FALSE,
    cache.path = "_cache/",
    fig.width = 4,
    fig.height = 4
  )
  opts_knit$set(
    stop_on_error = 0L
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

rmd2html <- function(path, cache = FALSE) {
  if (cache) {
    hash <- digest::digest(path, file = TRUE)
    cache_path <- paste0("_cache/", hash, ".html")
    
    if (file.exists(cache_path)) {
      if (interactive()) message("Use cache for ", path)
      return(cache_path)
    }
  }
  
  md_path <- rmd2md(path)
  html_path <- md2html(md_path)
  
  if (cache) {
    file.copy(html_path, cache_path)
  }
  html_path
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