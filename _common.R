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

# Previously in oldbookdown -----------------------------------------------

doc_type <- function() knitr::opts_knit$get('rmarkdown.pandoc.to')

begin_sidebar <- function(title = NULL) {
  if (identical(doc_type(), "latex")) {
    knitr::asis_output(paste0("\\begin{SIDEBAR}", title, "\\end{SIDEBAR}\n"))
  } else {
    knitr::asis_output(paste0("<div class = 'sidebar'><h3>", title, "</h3>\n\n"))
  }
}

end_sidebar <- function() {
  if (identical(doc_type(), "latex")) {
    knitr::asis_output("\\begin{ENDSIDEBAR}\\end{ENDSIDEBAR}\n")
  } else {
    knitr::asis_output("</div>\n")
  }
}

