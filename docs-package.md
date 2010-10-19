# Package documentation

Shows how to combine individual components to do something useful.  Critical part of package documentation - but a lot of work.  

* package help topic
* vignette(s)
* news file
* citation
* readme file
* demos

## Package help topic

Every package should contain an overview documentation topic that describes the overall purpose of the package, and points to the most important functions. This topic should have `@docType package` and be aliased to `package-pkgname` and `pkgname` (unless there is already a function by that name).

## Vignettes

Paper length. Consider submitting to R journal or JSS for formal recognition of your hard work.

## `NEWS`

List of changes.  

Format like.

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

Friendly introduction to your package. If you're using github, this will be appear on the package home page. Why should someone be interested in using it?  What are the main functions?

## Demos

In demo directory.  Like an example, but longer and combines together multiple functions.

Description of index file.