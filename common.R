library(methods)

set.seed(1014)
options(digits = 3, str = strOptions(strict.width = "cut"))

knitr::opts_chunk$set(
  comment = "#>",
  collapse = TRUE,
  cache = TRUE,
  fig.retina = 0.8, # figures are either vectors or 300 dpi diagrams
  dpi = 300,
  out.width = "70%",
  fig.align = 'center',
  fig.width = 6,
  fig.asp = 0.618,  # 1 / phi
  fig.show = "hold"
)

if (knitr::is_latex_output()) {
  knitr::opts_chunk$set(width = 69)
  options(width = 69)
}

knitr::knit_hooks$set(
  small_mar = function(before, options, envir) {
    if (before) {
      par(mar = c(4.1, 4.1, 0.5, 0.5))
    }
  }
)

# Make error messages closer to base R
registerS3method("wrap", "error", envir = asNamespace("knitr"),
  function(x, options) {
    call <- conditionCall(x)
    message <- conditionMessage(x)

    if (is.null(call)) {
      msg <- paste0("Error: ", message)
    } else {
      msg <- paste0("Error in ", deparse(call), ":\n  ", message)
    }

    knitr:::msg_wrap(msg, "error", options)
  }
)
