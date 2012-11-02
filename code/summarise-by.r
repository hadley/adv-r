{
  load_all("~/documents/plyr/plyr")
  load_all("~/documents/plyr/dplyr")
  library(data.table)
  data("baseball", package = "plyr")
  vars <- list(n = quote(length(id)), m = quote(n + 1))
}

# Baseline case: use ddply
a <- ddply(baseball, "id", summarise, n = length(id))
#:    user  system elapsed
#:   0.451   0.003   0.453

# New summary method: ~20x faster
b <- summarise_by(baseball, group("id"), vars)
#:    user  system elapsed
#:   0.029   0.000   0.029

# But still not as fast as specialised count, which is basically id + tabulate
# so maybe able to eke out a little more with a C loop ?
count(baseball, "id")
#:    user  system elapsed
#:   0.008   0.000   0.008

baseball2 <- data.table(baseball)
#:    user  system elapsed
#:   0.002   0.001   0.003

# Holy shit that's fast, but now only ~5x faster than summarise_by
baseball2[, list(n = length(year)), by = id]
#:    user  system elapsed
#:   0.007   0.000   0.007

# Individual operation faster if key set, but setttng the key takes
# as much time as doing the op
setkey(baseball2, id)
#:    user  system elapsed
#:   0.008   0.000   0.008

baseball2[, length(year), by = id]
#:    user  system elapsed
#:   0.002   0.000   0.002
