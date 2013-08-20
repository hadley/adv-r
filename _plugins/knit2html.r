html <- function(rmd) {
  library(knitr)
  library(markdown)

  set.seed(1410)
  options(digits = 3)
#   render_html()

  knit_hooks$set(
    source = function(x, options) x, 
    output = function(x, options) x,
    warning = function(x, options) x, 
    error = function(x, options) x, 
    message = function(x, options) x,
    inline = function(x) x,
    plot = hook_plot_md,
    chunk = function(x, options) {
      paste0("```R\n", x, "```")
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

  # Convert to markdown
  md <- tempfile(fileext = ".md")
  knit(rmd, md, quiet = TRUE)
  
  # Convert to html
  cmd <- paste0("pandoc -f markdown -t html ", md)
  paste(system(cmd, intern = TRUE), collapse = "\n")

}
