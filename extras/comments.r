comments <- function(refs) {
  srcfile <- attr(refs[[1]], "srcfile")

  # first_line, first_byte, last_line, last_byte
  com <- vector("list", length(refs))
  for(i in seq_along(refs)) {
    # Comments begin after last line of last block, and continue to
    # first line of this block
    if (i == 1) {
      first_byte <- 1
      first_line <- 1
    } else {
      first_byte <- refs[[i - 1]][4] + 1
      first_line <- refs[[i - 1]][3]
    }

    last_line <- refs[[i]][1]
    last_byte <- refs[[i]][2] - 1
    if (last_byte == 0) {
      if (last_line == 1) {
        first_byte <- 0
        last_byte <- 0
        last_line <- 1
      } else {
        last_line <- last_line - 1
        last_byte <- 1e3
      }
    }

    lloc <- c(first_line, first_byte, last_line, last_byte)
    com[[i]] <- srcref(srcfile, lloc)
  }

  com
}
