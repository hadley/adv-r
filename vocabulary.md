# Vocabulary

The following functions outline my expectation for a working vocabulary of R functions. I don't expect you to be intimately conscious of the details of every function, but you should at least be aware that they all exist, so that if you do encounter a problem that requires a special tool, you're already aware of it. The functions come from the `base` and `stats` packages, but include a few pointers to other packages and important options.

To get the most out of this book, you should be familiar with "the basics".  For data analysis, you also need I/O and special data.  

## The basics

    # Operators
    %in%, match
    =, <-, <<-, assign
    $, [, [[, replace, head, tail, subset
    with
    within

    # Comparison 
    all.equal, identical
    !=, ==, >, >=, <, <=
    is.na, is.nan, is.finite
    complete.cases

    # Basic math
    *, +, -, /, ^, %%, %/%
    abs, sign
    acos, acosh, asin, asinh, atan, atan2, atanh
    sin, sinh, cos, cosh, tan, tanh
    ceiling, floor, round, trunc, signif
    exp, log, log10, log1p, log2, logb, sqrt

    cummax, cummin, cumprod, cumsum, diff
    max, min, prod, sum
    range
    mean, median, cor, cov, sd, var
    pmax, pmin
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
    length, dim, ncol, nrow
    cbind, rbind
    names, colnames, rownames
    t
    diag
    sweep
    
    # Making vectors 
    rep, seq, seq_along, seq_len
    rev
    sample
    choose, factorial, combn
    
    # Lists & data.frames 
    list, unlist
    data.frame
    split
    expand.grid
    
    # Control flow 
    if, &&, || (short circuiting)
    for, while
    next, break

    switch
    ifelse
    
## Statistics

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
    beta, binom, cauchy, chisq, exp, f, gamma, geom, hyper, lnorm, logis,
    multinom, nbinom, norm, pois, signrank, t, unif, weibull, wilcox, 
    birthday, tukey

    # Matrix algebra 
    crossprod, tcrossprod
    eigen, qr, svd
    %*%, %o%, outer
    rcond
    solve
    
    # Ordering and tabulating 
    duplicated, unique
    merge
    order, rank, quantile
    sort
    table, ftable

## Working with R

    # Workspace 
    ls, exists, get, rm
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

## I/O

    # Output
    print, cat
    message, warning
    dput
    format
    summary
    sink

    # Reading and writing data
    data
    count.fields
    read.csv, read.delim, read.fwf, read.table
    library(foreign)
    write.table
    readLines, writeLines
    load, save
    readRDS, saveRDS

    # Files and directories 
    dir
    basename, dirname, file.path, path.expand
    file.choose
    file.copy, file.create, file.remove, file.rename, dir.create
    file.exists
    tempdir, tempfile
    download.file

## Special data

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
    factor, levels
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