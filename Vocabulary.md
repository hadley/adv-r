# Vocabulary

An important part of being a competent R programming is having a good working vocabulary. Below, I have listed the functions that I believe consistute such a vocabulary. I don't expect you to be intimately familiar with the details of every function, but you should at least be aware that they all exist. 

I came up with this list by looking through all functions in `base`, `stats`, and `utils`, and extracting those those that I think are most useful. The list also included a few pointers to particularly important functions in other packages, some of the more important options.

## The basics

```R
# The first functions to learn
?
str

# Important operators and assignment
%in%, match
=, <-, <<-
$, [, [[, head, tail, subset
with
assign, get

# Comparison 
all.equal, identical
!=, ==, >, >=, <, <=
is.na, complete.cases
is.finite

# Basic math
*, +, -, /, ^, %%, %/%
abs, sign
acos, asin, atan, atan2
sin, cos, tan
ceiling, floor, round, trunc, signif
exp, log, log10, log2, sqrt

max, min, prod, sum
cummax, cummin, cumprod, cumsum, diff
pmax, pmin
range
mean, median, cor, sd, var
rle

# Functions
function
missing
on.exit
return, invisible

# Logical & sets 
&, |, !, xor
all, any
intersect, union, setdiff, setequal
which

# Vectors and matrices
c, matrix
# automatic coercion rules character > numeric > logical
length, dim, ncol, nrow
cbind, rbind
names, colnames, rownames
t
diag
sweep
as.matrix, data.matrix

# Making vectors 
c
rep, rep_len
seq, seq_len, seq_along
rev
sample
choose, factorial, combn
(is/as).(character/numeric/logical/...)

# Lists & data.frames 
list, unlist
data.frame, as.data.frame
split
expand.grid

# Control flow 
if, &&, || (short circuiting)
for, while
next, break
switch
ifelse
```


## Common data structures

```R
# Date time
ISOdate, ISOdatetime, strftime, strptime, date
difftime
julian, months, quarters, weekdays
library(lubridate)

# Character manipulation 
grep, agrep
gsub
strsplit
chartr
nchar
tolower, toupper
substr
paste
library(stringr)

# Factors 
factor, levels, nlevels
reorder, relevel
cut, findInterval
interaction
options(stringsAsFactors = FALSE)

# Array manipulation
array
dim
dimnames
aperm
library(abind)
```

## Statistics

```R
# Ordering and tabulating 
duplicated, unique
merge
order, rank, quantile
sort
table, ftable

# Linear models 
fitted, predict, resid, rstandard
lm, glm
hat, influence.measures
logLik, df, deviance
formula, ~, I
anova, coef, confint, vcov
contrasts

# Miscellaneous tests
apropos("\\.test$")

# Random variables 
(q, t, d, r) * (beta, binom, cauchy, chisq, exp, f, gamma, geom, 
  hyper, lnorm, logis, multinom, nbinom, norm, pois, signrank, t, 
  unif, weibull, wilcox, birthday, tukey)

# Matrix algebra 
crossprod, tcrossprod
eigen, qr, svd
%*%, %o%, outer
rcond
solve
```

## Working with R

```R
# Workspace 
ls, exists, rm
getwd, setwd
q
source
install.packages, library, require

# Help
help, ?
help.search
apropos
RSiteSearch
citation
demo
example
vignette

# Debugging
traceback
browser
recover
options(error = )
stop, warning, message
tryCatch, try
```

## I/O

```R
# Output
print, cat
message, warning
dput
format
sink, capture.output

# Reading and writing data
data
count.fields
read.csv, write.csv,
read.delim, write.delim
read.fwf
readLines, writeLines
readRDS, saveRDS
load, save
library(foreign)

# Files and directories 
dir
basename, dirname, tools::file_ext
file.path
path.expand, normalizePath
file.choose
file.copy, file.create, file.remove, file.rename, dir.create
file.exists, file.info
tempdir, tempfile
download.file, library(downloader)
```
