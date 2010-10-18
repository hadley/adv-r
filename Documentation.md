# Documenting your code

Documentation is one of the most important aspects of good code. Without it, users won't know how to use your package, and are unlikely to do so. Documentation is also useful for you in the future, and for other developers working on your package.

# roxygen

[roxygen](http://roxygen.org/) is the best way to make documentation in R. With roxygen, you write the documentation right next to each function in comments, and then it is turned into `.Rd` files by running the `roxygenise()` function. This has a number of advantages over writing `.Rd` by hand:

  * code and documentation are adjacent so it's easier to remember when you 
    need to update the documentation
  * roxygen generates as much as possible for you

Roxygen also makes it easy to generate a namespace for your package, as described in [[Namespaces]].

## General tips

In my opinion, one of the most important parts of the documentation are the examples - these are what most people will look at first to figure out how to use the function.

When to combine documentation of multiple functions.

## Basic tags

## Other tags

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

# Package documentation

## Topic

Every package should contain an overview documentation topic that describes the overall purpose of the package, and points to the most important functions. This topic should have `@docType package` and be aliased to `package-pkgname` and `pkgname` (unless there is already a function by that name).

## Vignettes

## `NEWS`

## `CITATION`

## Demos
