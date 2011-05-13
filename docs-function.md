# Documenting your code

Documentation is one of the most important aspects of good code. Without it, users won't know how to use your package, and are unlikely to do so. Documentation is also useful for you in the future (so you remember what the heck you were thinking!), and for other developers working on your package.

[roxygen](http://roxygen.org/) is the best way to make documentation in R. With roxygen, you write the documentation in comments right next to each function. Roxygen has a number of advantages over writing `.Rd` by hand:

* code and documentation are adjacent so when you modify your code, it's easy
  to remember when you need to update the documentation.

* roxygen can automatically derive a lot of the required documentation from
  the source code.

* it's easy to automatically generate a [[namespace]] for your package.

To convert roxygen comments to the official `.Rd` files, you can use one of the commands below:

* From the command line: `R CMD roxygen mypackage`

* Within R, with the roxygen package: `roxygenize(path_to_package)`

* Using the [[devtools package|development]]: `document("mypackage")`

Please note that the chapter currently works best with my [unofficial roxygen fork](https://github.com/hadley/roxygen). My modifications will be ported to the main trunk in the near future.

This chapter is broken down into two main segments.  First you'll see how to 

## Documenting

### Documenting a function

When documenting a function, the first decision you need to make is whether you want to export it or not. Exporting is described more in [[namespaces]], but basically when you export a function you are saying it is ready for use and you are making a commitment to keep it around in a similar form for the near future.

All exported functions need to be documented. It's also a good idea to document your more complicated internal functions, at least so when you come back to them in the future you don't need to struggle to recall what the inputs and outputs are.

The following code shows the arrange function and its documentation from the
plyr package. Roxygen documentation is stored in comments with a special form
(`#'`) and starts with a single line description of the function. A paragraph
provides more details and then specific tags provide additional metadata
about the function.

    #' Order a data frame by its columns.
    #'
    #' This function completes the subsetting, transforming and ordering triad
    #' with a function that works in a similar way to \code{\link{subset}} and 
    #' \code{\link{transform}} but for reordering a data frame by its columns.
    #' This saves a lot of typing!
    #'
    #' @param df data frame to reorder
    #' @param ... expressions evaluated in the context of \code{df} and 
    #'   then fed to \code{\link{order}}
    #' @keywords manip
    #' @export
    #' @examples
    #' mtcars[with(mtcars, order(cyl, disp)), ]
    #' arrange(mtcars, cyl, disp)
    #' arrange(mtcars, cyl, desc(disp))
    arrange <- function(df, ...) {
      ord <- eval(substitute(order(...)), df, parent.frame())
      unrowname(df[ord, ])
    }

The tags used here are:

* `@param arg description` - a description for each function argument

* `@keywords` - one or more (space-separated) keywords from
  `file.path(R.home(), "doc/KEYWORDS")`. These are currently only used in very
  limited ways, but might be used more in the future.

* `@export` - a flag indicating that this function should be exported for use
  by others. Described in more detail in [[namespaces]].

* `@examples` - examples of the function in use. In my opinion, this is the
  most important part of the documentation - these are what most people will
  look at first to figure out how to use the function. I always put this last.

The content of a tag extends from the tag name to the next tag, and they can span multiple lines.

Other tags that you might find useful are:

* `@author`, in the form `Firstname Lastname <email@address.com>`. Use this if
  some of the functions are written by different people

* `@seealso` - to provide pointers to other related topics

* `@return` - the type of object that the function returns

* `@references` - references to scientific literature on this topic

* `@alias` - a list of topic names that will be mapped to this documentation
  when the user looks them up from the command line.

By default, roxygen will automatically set the name of the topic to the name of the function, the title to the first sentence of the description, and takes the usage string from the function definition. In some cases, it can be useful to override each of these.

* Functions with non alpha-numeric names: the topic name will be the same as
  the filename, so use `@name` to change it to something that doesn't have
  special characters, and then use `@alias` to set the alias to the actual
  function name.

* Multiple functions in a single topic: make sure to set `@alias` to all the
  function names, and use `@usage` to describe both functions. It's generally
  better to document functions separately, unless they are particularly
  closely related.

### Documenting a dataset

The following documentation excerpt comes from the diamonds dataset in ggplot2.

    #' Prices of 50,000 round cut diamonds.
    #' 
    #' A dataset containing the prices and other attributes of almost 54,000
    #'  diamonds. The variables are as follows:
    #' 
    #' \itemize{
    #'   \item price. price in US dollars (\$326--\$18,823)  
    #'   \item carat. weight of the diamond (0.2--5.01) 
    #'   ...
    #' }
    #' 
    #' @docType data
    #' @keywords datasets
    #' @name diamonds
    #' @usage diamonds
    #' @format A data frame with 53940 rows and 10 variables
    NULL

There are a few new tags:

* `@docType data` which indicates that this is documentation for a dataset.

* `@usage diamonds`, which just gives the name of the dataset.

* `@format`, which gives an overview of the structure of the dataset

### Documenting a S3 generic functions and methods

S3 generic functions should be documented in the same way as any other function. You should give a general run down of the purpose of the function, and pointers to the most important methods.

You should also document particularly important or complex methods, and ensure that all methods are appropriately exported

* Use `@method` when you are writing a full documentation topic for this
  method. It has format `@method function-name class` and tells roxygen that
  this is a S3 method, not an ordinary function

* All exported methods need the `@S3method` tag. It has the same format as
  `@method`. This exports the method, not the function - i.e.
  `generic(myobject)` will work, but `generic.mymethod(myobject)` will not.

### Documenting a S4 methods and classes

A consensus has yet to emerge on the best way to document S4 methods and classes. I will update this section as I learn more.

### Documenting a R5 class

R5 classes are documented in rather different way, similar to the way that python documentation works. Each R5 method should begin with a "doctstring" that describes what the function does. R5 is still under development and I expect that more conventions will emerge in time.

### Documenting a package

As well [[package level documentation|docs-package]] resources, every package should also have it's own documentation page.

This documentation topic should contain an overview documentation topic that describes the overall purpose of the package, and points to the most important functions. This topic should have `@docType package` and be aliased to `package-pkgname` and `pkgname` (unless there is already a function by that name) so that you can get an overview of the package by doing `?pkgname` or `package?pkgname`.

The example below shows the basic structure, as taken from the documentation for the `lubridate` package:

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
    #' @references Garrett Grolemund, Hadley Wickham (2011). Dates and Times
    #'   Made Easy with lubridate. Journal of Statistical Software, 40(3),
    #'   1-25. \url{http://www.jstatsoft.org/v40/i03/}.
    #' @import plyr stringr
    #' @docType package
    #' @name lubridate
    #' @aliases lubridate package-lubridate
    NULL

Important components are:

* The general overview of the package: what it does, and what are the
  important pieces.

* `@docType package` to indicate that it's documentation for a package and
  `@aliases lubridate package-lubridate` so users can find it using either
  standard form.

* `@name` is needed because we're not documenting a real object, and that's
  the name that will be used for the file.

* `@references` point to any published material about the package that users
  might find help.

## Text formatting 

Within roxygen text you use the usual R documentation formatting rules, as summarised below. A fuller description is available in the [R extensions](http://cran.r-project.org/doc/manuals/R-exts.html#Sectioning) manual.

Sections and subsections are similar to latex, but take a second argument which is the contents of the section. Section titles should be in sentence case.

    \section{Warning}{
      You must not call this function unless ...
      
      \subsection{Exceptions}{
         Apart from the following special cases...
      }
      
    }

### Lists

* Ordered (numbered) lists:

      \enumerate{
        \item First item
        \item Second item
      }
      
* Unordered (bulleted) lists

      \itemised{
        \item First item
        \item Second item
      }
      
* Definition (named) lists

      \describe{
        \item{One}{First item}
        \item{Two}{Second item}
      }

### Tables

### Mathematics

### Character formatting

* `\emph{text}`: emphasised text, usually displayed as _italics_

* `\strong{text}`: strong text, usually displayed in __bold__

* `\code{text}`, `\pkg{package_name}`, `\file{file_name}`

* External links: `\email{email_address}`, `\url{uniform_resource_locator}`

* `\link[package]{function}` - the first argument can be omitted if the link
  is in the current package, or a base package.