# Documenting your code

Documentation is one of the most important aspects of good code. Without it, users won't know how to use your package, and are unlikely to do so. Documentation is also useful for you in the future, and for other developers working on your package.

[roxygen](http://roxygen.org/) is the best way to make documentation in R. With roxygen, you write the documentation right next to each function in comments, and then it is turned into `.Rd` files by running the `roxygenise()` function. This has a number of advantages over writing `.Rd` by hand:

* code and documentation are adjacent so it's easier to remember when you 
  need to update the documentation

* roxygen generates as much as possible for you

Roxygen also makes it easy to generate a namespace for your package, as described in [[Namespaces]].

In my opinion, one of the most important parts of the documentation are the examples - these are what most people will look at first to figure out how to use the function.

When to combine documentation of multiple functions.

## Documenting

### Documenting a function

The following code shows the arrange function and its documentation from the plyr package.  The documentation is stored in comments with a special form (`#'`) and starts with a single line description of the function.  A paragraph provides more details and then specific tags provide additional information about the function.

    #' Order a data frame by its colums.
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
  `file.path(R.home(), "doc/KEYWORDS")`

* `@export` - a flag indicating that this function should be exported for use
  by others. Described in more detail in [[namespaces]].

* `@examples` - examples of the function in use.

Other tags that you might find useful are:

* `@author`
* `@title`
* `@name`, `@alias`
* `@usage`
* `@seealso`
* `@return`
* `@references`
* `@`

### Documenting a S3 method

### Documenting a S4 method

### Documenting a S4 class

### Documenting a package

See [[docs-package]]

### Documenting a R5 class

## Text formatting 

Within roxygen text you use the usual R documentation formatting rules, as summarised below. A fuller description is available in the [R extensions](http://cran.r-project.org/doc/manuals/R-exts.html#Sectioning) manual.

Sections and subsections are similar to latex, but take a second argument which is the contents of the section. Section titles should be in sentence case.

    \section{Warning}{
      You must not call this function unless ...
      
      \subsection{Exceptions}{
         Apart from the following special cases...
      }
      
    }

Lists:

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

Tables:

Mathematics:

Character formatting:

 * `\emph{text}`: emphasised text, usually displayed as _italics_
 * `\strong{text}`: strong test, usually displayed in __bold__
 * `\code{text}`, `\pkg{package_name}`, `\file{file_name}`
 * External links: `\email{email_address}`, `\url{uniform_resource_locator}`
 * `\link[package]{function}` - the first argument can be omitted if the link
    is in the current package, or a base package.


## Running roxygen

There are three ways to run roxygen:

  * `R CMD roxygen`
  * `roxygen::roxygenize`
  * `devtools::document`