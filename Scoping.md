# Lexical scoping

# Dynamic scoping

# Lazy evaluation

Arguments are lazily evaluated in their original environment.

    f <- function() {
      y <- "f"
      g(y)
    }    
    g <- function(x) {
      y <- "g"
      x
    }
    y <- "toplevel"
    f()
    # [1] "f"
