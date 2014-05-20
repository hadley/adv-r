pos <- function(...) {
  mat <- matrix(c(...), byrow = T, ncol = 2)
  colnames(mat) <- c("x", "y")
  mat
}

midpoints <- function(f, a, b) {
  mid <- f((a + b) / 2)

  pos(
    a, mid,
    b, mid
  )
}

trapezoids <- function(f, a, b) {
  pos(
    a, f(a),
    b, f(b)
  )
}


# Graphically
plot(sin, xlim = c(0, pi))
lines(midpoints(sin, 0, pi), col = "red")
lines(trapezoids(sin, 0, pi), col = "blue")


composites <- function(f, a, b, n = 10, rule) {
  points <- seq(a, b, length = n + 1)

  pieces <- lapply(seq_len(n), function(i) {
    rule(f, points[i], points[i + 1])
  })
  do.call("rbind", pieces)
}

plot(sin, xlim = c(0, pi))
lines(composites(sin, 0, pi, 5, rule = midpoints), col = "red")
lines(composites(sin, 0, pi, 5, rule = trapezoids), col = "blue")
