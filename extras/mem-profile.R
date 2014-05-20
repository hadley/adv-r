m_delta <- function(expr) {
  # Evaluate in clean environment to limit effects
  e <- new.env(parent = parent.frame())
  # Force gc to flush any values no longer attached to names
  gc()
  old <- memory.profile()
  
  eval(substitute(expr), env = e)

  gc()
  new <- memory.profile()
  
  report <- cbind(old, new, delta = new - old)
  # Only show rows where something changed
  report[report[, 3] != 0, ]
}

# Why does this create 3 pairlists, 1 integer and 1 character,
# but no doubles?
m_delta(x <- 1.5)

# No different
m_delta({x <- 1.5})
# Create an extra pairlist compared to previous?
m_delta({x <- 1.5; y <- 2.5})

m_delta(1)
