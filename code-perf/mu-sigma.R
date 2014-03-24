require(mvtnorm)

GetConditionalMu <- function(omega, Sigma.mu, y, method = "svd") {
  nsteps <- length(omega)
  one <- rep(1, nsteps)
  mean.mu.cond <- c(omega + (1 / sum(Sigma.mu)) * (Sigma.mu %*% one) *
      c(nsteps*y - t(one) %*% omega))
  Sigma.mu.cond <- Sigma.mu - (1 / sum(Sigma.mu)) *
    (Sigma.mu %*% one %*% t(one) %*% Sigma.mu)

  rmvnorm(1, mean.mu.cond, Sigma.mu.cond, method = method)
}

GetSigmaMu <- function(nsteps, sigma_ar, rho1, rho2) {
  rho <- c(rho1, rho2)
  cor <- ARMAacf(ar = rho, pacf = FALSE, lag.max = nsteps)
  var <- sigma_ar ^ 2 / (1 - sum(rho * cor[2:3]))
  cov <- cor * var
  Sigma.mu <- matrix(NA, nsteps, nsteps)
  for (i in 1:nsteps) {
    for (k in 1:nsteps) {
      Sigma.mu[i,k] <- cov[abs(i-k)+1]
    }
  }
  Sigma.mu
}

input_jp <- function(omega, sigma_ar, rho1, rho2, y_lastobs = 0.3) {
  Sigma.mu <- GetSigmaMu(length(omega), sigma_ar, rho1, rho2)
  GetConditionalMu(omega, Sigma.mu, y_lastobs)
}

input_jp(rnorm(300, 0.1, 0.1), rnorm(1, 0.02, 0.05), rnorm(1, 0.8, 0.1),
  rnorm(1, 0.8, 0.1))
