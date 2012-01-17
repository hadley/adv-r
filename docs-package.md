# Package documentation

Shows how to combine individual components to do something useful.  Critical part of package documentation - but a lot of work.  

The following code is an excerpt from the package documentation for lubridate, which is located in the  file
['odesk_sql/worker_applications/b_job_appl.sql'](https://github.com/johnjosephhorton/odesk_sql/blob/master/worker_applications/worker_applications_panel.sql)


 [`lubridate/R/help.r`](https://github.com/hadley/lubridate/blob/master/R/help.r)

    #' Dates and times made easy with lubridate.
    #'
    #' Lubridate provides tools that make it easier to parse and 
    #' manipulate dates. These tools are grouped below by common 
    #' purpose. More information about each function can be found in 
    #' its help documentation.
    #'
    #' Parsing dates
    #'
    #' Lubridate's parsing functions read strings into R as POSIXct 
    #' date-time objects. Users should choose the function whose name 
    #' models the order in which the year ('y'), month ('m') and day 
    #' ('d') elements appear the string to be parsed: 
    #' \code{\link{dmy}}, \code{\link{myd}}, \code{\link{ymd}}, 
    #' \code{\link{ydm}}, \code{\link{dym}}, \code{\link{mdy}}, 
    #' \code{\link{ymd_hms}}). 
    #'    
    #' ...
    #'
    #' @docType package
    #' @name lubridate
    #' @aliases lubridate package-lubridate 
    NULL

## Vignettes

Paper length. Consider submitting to R journal or JSS for formal recognition of your hard work.  Must use Sweave.  If you don't want to use sweave, then ...

## `NEWS`

The `NEWS` file should list all changes that have occurred since the last release of the package. The following sample shows the `NEWS` file from the `stringr` package.

    stringr 0.4
    ===========

     * all functions now vectorised with respect to string, pattern (and
       where appropriate) replacement parameters
     * fixed() function now tells stringr functions to use fixed matching, rather
       than escaping the regular expression.  Should improve performance for 
       large vectors.
     * new ignore.case() modifier tells stringr functions to ignore case of
       pattern.
     * str_replace renamed to str_replace_all and new str_replace function added.
       This makes str_replace consistent with all functions.
     * new str_sub<- function (analogous to substring<-) for substring replacement
     * str_sub now understands negative positions as a position from the end of
       the string. -1 replaces Inf as indicator for string end.
     * str_pad side argument can be left, right, or both (instead of center)
     * str_trim gains side argument to better match str_pad
     * stringr now has a namespace and imports plyr (rather than requiring it)


If you have many changes, you can use subheadings to divide them into sections.  A subheading should be ...

Use `devtools::show_news` to automatically load your news file and show that it works correctly.

## `CITATION`

Should be located in the `inst` directory. Describes how to cite the package.

See `?readCitationFile` for description of format.  

Example from base R:

    citHeader("To cite R in publications use:")

    citEntry(entry="Manual",
             title = "R: A Language and Environment for Statistical Computing",
             author = person(last="R Development Core Team"),
             organization = "R Foundation for Statistical Computing",
             address      = "Vienna, Austria",
             year         = version$year,
             note         = "{ISBN} 3-900051-07-0",
             url          = "http://www.R-project.org",
         
             textVersion = 
             paste("R Development Core Team (", version$year, "). ", 
                   "R: A language and environment for statistical computing. ",
                   "R Foundation for Statistical Computing, Vienna, Austria. ",
                   "ISBN 3-900051-07-0, URL http://www.R-project.org.",
                   sep="")
             )

    citFooter("We have invested a lot of time and effort in creating R,",
              "please cite it when using it for data analysis.",
              "See also", sQuote("citation(\"pkgname\")"),
              "for citing R packages.")

## `README`

Friendly introduction to your package. If you're using github, this will be appear on the package home page. Why should someone be interested in using it?  What are the main functions?  You'll also use this when you announce a new version of a package.

  * https://github.com/hadley/plyr/blob/master/README.md
  * https://github.com/hadley/stringr/blob/master/README.md
  * https://github.com/hadley/lubridate/blob/master/README.md
  * https://github.com/hadley/devtools/blob/master/README.md

I use markdown format, so my `README` files have the `.md` extension.  Markdown is a simple plaintext format that reads well when you're looking at the source and converts nicely to html (and to latex).

## Demos

In demo directory.  Like an example, but longer and combines together multiple functions.

Description of index file.