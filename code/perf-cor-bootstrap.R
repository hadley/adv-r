# Inspired by http://stackoverflow.com/questions/18492523

library(microbenchmark)

# Generate data
n <- 1e6
set.seed(1)
q <- data.frame(a = rnorm(n), b = rnorm(n))
a <- q$a
b <- q$b

i <- sample(seq(n), n * 0.01)
cor_df <- function(i)  cor(q[i, , drop = FALSE])[2,1]
cor_vec <- function(i) cor(q$a[i], q$b[i])
cor_vec2 <- function(i) cor(a[i], b[i])
cor_man <- function(i) {
  .Call(stats:::C_cor, q$a[i], q$b[i], 4L, FALSE)
}
cor_me <- function(i) {
  std <- function(x) (x - mean(x)) / sd(x)
  crossprod(std(q$a[i]), std(q$b[i])) / (length(i) - 1)
}

microbenchmark(
  sample(seq(n), n * 0.01),
  sample.int(n, n * 0.01),
  cor_df(i),
  cor_df2(i),
  cor_vec(i),
  cor_vec_sort(i),
  cor_vec2(i),
  cor_man(i),
  cor_me(i)
)

