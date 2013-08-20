#!/usr/bin/Rscript
source("_plugins/knit2html.r")

args <- commandArgs(trailingOnly = TRUE)
path <- args[1]

if (!file.exists(path)) {
  stop("Can't find path ", path, call. = FALSE)
}

if (file.access(path, 4) != 0) {
  stop("Can't read path ", path, call. = FALSE)
}

hash <- digest::digest(path, file = TRUE)
cache_path <- paste0("_cache/", hash, ".html")

if (!file.exists(cache_path)) {
  out <- html(path)
  writeLines(out, cache_path)
  cat(out)
} else {
  cat(readLines(cache_path, warn = FALSE), sep = "\n")
}
