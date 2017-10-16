library(methods)

set.seed(1014)
options(digits = 3)

knitr::opts_chunk$set(
  comment = "#>",
  collapse = TRUE,
  cache = TRUE,
  out.width = "70%",
  fig.align = 'center',
  fig.width = 6,
  fig.asp = 0.618,  # 1 / phi
  fig.show = "hold"
)

# options("crayon.enabled" = TRUE, "crayon.colors" = 256L)
# crayon::num_colors(TRUE)
#
# colourise_chunk <- function(x, options) {
#   fence = paste(rep("`", 3), collapse = '')
#
#   x = gsub(paste0('[\n]{2,}(', fence, '|    )'), '\n\n\\1', x)
#   x = gsub('[\n]+$', '', x)
#   x = gsub('^[\n]+', '\n', x)
#   if (isTRUE(options$collapse)) {
#     x = gsub(paste0('\n([', fence_char, ']{3,})\n+\\1(', tolower(options$engine), ')?\n'), "\n", x)
#   }
#   x <- ansistrings::ansi_to_html(x, fullpage = FALSE)
#
#   if (is.null(s <- options$indent)) return(x)
#   line_prompt(x, prompt = s, continue = s)
# }

knitr::knit_hooks$set(
  small_mar = function(before, options, envir) {
    if (before) {
      par(mar = c(4.1, 4.1, 0.5, 0.5))
    }
  }
  # chunk = colourise_chunk
)

# Previously in oldbookdown -----------------------------------------------

doc_type <- function() knitr::opts_knit$get('rmarkdown.pandoc.to')

begin_sidebar <- function(title = NULL) {
  if (identical(doc_type(), "latex")) {
    # Suppress sidebars for now - pandoc doesn't convert markdown inside
    # a latex environment, so this technique required post-processing,
    # and I don't want to bother with that until I start building the
    # final block

    # knitr::asis_output(paste0("\\begin{SIDEBAR}", title, "\\end{SIDEBAR}\n"))
  } else {
    knitr::asis_output(paste0("<div class = 'sidebar'><h3>", title, "</h3>\n\n"))
  }
}

end_sidebar <- function() {
  if (identical(doc_type(), "latex")) {
    # knitr::asis_output("\\begin{ENDSIDEBAR}\\end{ENDSIDEBAR}\n")
  } else {
    knitr::asis_output("</div>\n")
  }
}

