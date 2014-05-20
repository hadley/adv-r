library(stringr)
source("comments.r")


time_comment <- function(x) {
  if (is.null(x)) return("")
  if (x[3] == 0) return("")

  out <- sprintf("%.3f", x[1:3])
  names(out) <- c("user", "system", "elapsed")

  out <- capture.output(print(noquote(out)))
  str_c("#: ", out, collapse = "\n")
}
comment_ref <- function(x) {
  if (x[1] == 1 && x[4] == 0) return("")
  str_c(c(as.character(x), ""), collapse = "\n")
}

time_file <- function(path) {
  lines <- readLines(path)

  # Remove any line starting with #:
  lines <- lines[!str_detect(lines, "^#:")]

  # Parse file, and capture comments.
  parsed <- parse(text = lines)
  refs <- attr(parsed, "srcref")

  comments <- comments(refs)

  env <- new.env(parent = globalenv())
  out <- vector("list", length(refs) * 3)
  for(i in seq_along(refs)) {
    t <- system.time(eval(parsed[[i]], env))
    call <- parsed[[i]][[1]]
    if (identical(call, as.name("{"))) t <- NULL

    out[[3 * (i - 1) + 1]] <- comment_ref(comments[[i]])
    out[[3 * (i - 1) + 2]] <- str_c(c(as.character(refs[[i]]), ""), collapse = "\n")
    out[[3 * (i - 1) + 3]] <- time_comment(t)
  }

  out <- unlist(out)
  out <- out[out != ""]
  cat(str_c(out, collapse = ""), "\n", file = path)
}
