# Performance

General techniques for improving performance


## Caching

`readRDS`, `saveRDS`, `load`, `save`

### Memoisation

## Byte code compilation

R 2.13 introduced a new byte code compiler which can increase the speed of certain types of code 4-5 fold. This improvement is likely to get better in the future as the compiler implements more optimisations - this is an active area of research.

Using the compiler is an easy way to get speed ups - it's easy to use, and if it doesn't work well for your function, then you haven't invested a lot of time in it, and so you haven't lost much.

## Important vectorised functions

    cumsum
    rowSums, colSums, rowMeans, colMeans
    rle
    