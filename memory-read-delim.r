read_delim <- function(file, header = TRUE, sep = ",") {
  # Determine number of fields by reading first line
  first <- scan(
    file, what = character(1), nlines = 1,
    sep = sep, quiet = TRUE
  )
  p <- length(first)

  # Load all fields as character vectors
  all <- scan(
    file, what = as.list(character(p)), sep = sep,
    skip = if (header) 1 else 0, quiet = TRUE
  )
  gc()

  # Convert from strings to appropriate types (never to factors)
  all[] <- lapply(all, type.convert, as.is = TRUE)
  gc()

  # Set column names
  if (header) {
    names(all) <- first
  } else {
    names(all) <- paste0("V", seq_along(all))
  }

  # Convert list into data frame
  as.data.frame(all)
}
