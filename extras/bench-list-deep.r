# ------------------------------------------------------------------------------
# Does modifying a list make a deep copy?

z1 <- list(runif(1e7))
z2 <- list(1:10)

system.time({
  for(i in 1:1e4) z1[1 + i] <- 1L
})
#  user  system elapsed
# 0.283   0.034   0.317
system.time({
  for(i in 1:1e4) z2[1 + i] <- 1L
})
#  user  system elapsed
# 0.284   0.034   0.319

# For reference
system.time({
  for(i in 1:1e4) z1[[1]][i] <- 1
})
#  user  system elapsed
# 0.025   0.000   0.025

# Modifying 10,000 times takes the same amount of time, regardless of whether
# the first element is length 10 or 10,000,000 -> modifying a list does not
# make a deep copy

# ------------------------------------------------------------------------------
# Does pre-allocating space save time for a list

z1 <- list(1:10)
z2 <- list(1:10)

system.time({
  for(i in 1:1e4) z1[1 + i] <- 1L
})
#  user  system elapsed
# 0.283   0.031   0.313
system.time({
  length(z2) <- 1e4 + 1
  for(i in 1:1e4) z2[1 + i] <- 1L
})
#  user  system elapsed
# 0.018   0.000   0.019
all.equal(z1, z2)

# Preallocation saves a considerable amount of time, even with lists - the
# copy isn't deep, but it still has to do a shallow copy every time, leading to
# quadratic behaviour.
