png <- function(path, dpi = NULL) {
  meta <- attr(png::readPNG(path, native = TRUE, info = TRUE), "info")
  if (!is.null(dpi)) meta$dpi <- rep(dpi, 2)
  meta$path <- path

  structure(meta, class = "png")
}
knit_print.png <- function(x, options) {
  knitr::asis_output(paste0(
    "<img src='", x$path, "'",
    " width=", x$dim[1] / (x$dpi[1] / 96),
    " height=", x$dim[2] / (x$dpi[2] / 96),
    " />"
  ))
}
