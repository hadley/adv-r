embed_png <- function(path, dpi = NULL) {
  meta <- attr(png::readPNG(path, native = TRUE, info = TRUE), "info")
  if (!is.null(dpi)) meta$dpi <- rep(dpi, 2)
  meta$path <- path

  structure(meta, class = "png")
}
knit_print.png <- function(x, options) {
  # To get more formatting info, see:
  # opts_knit$get('rmarkdown.pandoc.to')
  # opts_knit$get('out.format')

  if (doc_type() == "latex") {
    knitr::asis_output(paste0(
      "\\includegraphics[",
      "width=", round(x$dim[1] / x$dpi[1], 2), "in,",
      "height=", round(x$dim[2] / x$dpi[2], 2), "in",
      "]{", x$path, "}"
    ))
  } else {
    knitr::asis_output(paste0(
      "<img src='", x$path, "'",
      " width=", x$dim[1] / (x$dpi[1] / 96),
      " height=", x$dim[2] / (x$dpi[2] / 96),
      " />"
    ))
  }
}

doc_type <- function() knitr::opts_knit$get('rmarkdown.pandoc.to')
