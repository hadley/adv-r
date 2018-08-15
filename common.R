library(methods)

set.seed(1014)
options(digits = 3)

knitr::opts_chunk$set(
  comment = "#>",
  collapse = TRUE,
  cache = TRUE,
  fig.retina = 1, # figures are either vectors or 300 dpi diagrams
  dpi = 300,
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
