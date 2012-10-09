#' Short cut for evaluating a string - we need this to ensure we
#'
evals <- function(x, env = parent.frame()) {
  old <- options(keep.source = TRUE)
  on.exit(options(old))

  expr <- parse(text = x)
  eval(expr, envir = env)
}
evals("f <- function(x = T) {
  # This is a comment
  if (x)                  return(4)
  if (emergency_status()) return(T)
}")

# For each src ref, find the whitespace block preceeding it
whitespace <- function(refs) {
  n <- nrow(refs)

  empty <- rep(NA_real_, n)
  wht <- data.frame(line1 = empty, col1 = empty, line2 = empty, col2 = empty)

  for(i in seq_len(n)) {
    # Comments begin after last line of last block, and continue to
    # first line of this block
    if (i == 1) {
      col1 <- 1
      line1 <- 1
    } else {
      col1 <- refs$col1[[i - 1]] + 1
      line1 <- refs$line1[[i - 1]]
    }

    line2 <- refs$line2[[i]]
    col2 <- refs$col2[[i]] - 1
    if (col2 == 0) {
      if (line2 == 1) {
        col2 <- 1
        line2 <- 1
      } else {
        line2 <- line2 - 1
        col2 <- 1e3
      }
    }

    wht[i, ] <- list(line1, col1, line2, col2)
  }

  wht
}

nodes <- subset(getParseData(f), terminal)
whitespace(nodes)
