### Fixed points


There are better treatments of numerical optimisation elsewhere, but there are a couple of important threads that make applying loops here important. Need to give up at some point: either after too many iterations, or when difference (either absolute or relative is small)


```R
fixed_point <- function(f, init, max_iter = 100, tol = 1e-3) {
  i <- 1
  prv <- f(init)
  cur <- f(prv)
  
  while(i < max_iter && abs(prv - cur) > tol) {
    i <- i + 1
    prv <- cur
    cur <- f(prv)
  }

  structure(cur, iter = i)
}
fixed_point(function(x) x, 5)
fixed_point(cos, 5)
fixed_point(cos, 500)
fixed_point(cos, 50000)
fixed_point(function(x) 1 + 1/x, 0)
```

Average damping 

```R
damp <- function(f) function(x) (x + f(x)) / 2
```

Can use that to calculate square roots:

```R
sqrt2 <- function(x) fixed_point(damp(function(y) x / y), x)
```
