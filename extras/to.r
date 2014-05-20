"%to%" <- function(a, b) {
 a <- deparse(substitute(a))
 b <- deparse(substitute(b))

 # Find environment in which the variables both live
 obj_a <- apropos(a, where = T)
 obj_v <- apropos(b, where = T)

 pos <- as.numeric(intersect(names(obj_a), names(obj_v))[1])
 if (length(pos) == 0) {
   stop("No matching variable names found")
 }

 # Find the position of the variables and then return all variables
 # between them
 vars <- ls(pos)
 sel <- vars[which(vars == a):which(vars == b)]
 as.data.frame(mget(sel, as.environment(pos)))
}

mat <- matrix(runif(1000), ncol = 100)
df <- as.data.frame(mat)
names(df) <- c(paste("x", 1:50, sep = ""), paste("y", 1:50, sep = ""))
attach(df)
summary(x1 %to% x5)
detach(df)

with(df, summary(x1 %to% x5))