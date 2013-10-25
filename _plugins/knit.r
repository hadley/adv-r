#!/usr/bin/Rscript
source("_plugins/rmd2html.r")
library(methods)

args <- commandArgs(trailingOnly = TRUE)
path <- args[1]

if (!file.exists(path)) {
  stop("Can't find path ", path, call. = FALSE)
}

if (file.access(path, 4) != 0) {
  stop("Can't read path ", path, call. = FALSE)
}

html_path <- rmd2html(path, cache = TRUE)
cat(read_file(html_path))
