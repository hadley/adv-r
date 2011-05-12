cache <- function(name, code, cache_dir = ".cache") {
  if (!file.exists(cache_dir)) dir.create(cache_dir)

  # Create a new environment and evaluate the code in it, so we know
  # what was created
  parent <- parent.frame()
  res <- new.env(parent = parent)
  eval(substitute(code), res)

  # Iterate through each object, saving it to disk and copying it to the
  # parent environment
  objs <- ls(res)
  for(obj in objs) {
    assign(obj, res[[obj]], env = parent)

    file_path <- file.path(cache_dir, paste(obj, ".rds", sep =""))
    saveRDS(res[[obj]], f)
  }
  
}

clear_cache <- function(name, cache_dir = ".cache") {
  file.remove(dir(cache_dir, full.names = T))
}