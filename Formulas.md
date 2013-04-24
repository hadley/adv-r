## Formulas

There is one other approach we could use: a formula. `~` works much like quote, but it also captures the environment in which it is created. We need to extract the second component of the formula because the first component is `~`.

```R
subset <- function(x, f) {
  r <- eval(f'[[2]], x, environment(f))
  x[r, ]
}
subset(mtcars, ~ cyl == x)
```
