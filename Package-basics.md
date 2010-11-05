# Package basics

An R package is the basic unit of reusable code. You need to master the art of making R packages if you want others to use your code. This document explains how to get started, with a description of package structure, tips for naming your package, and more details about the `DESCRIPTION` file.

The best resource for up-to-date details on package development is always the official [writing R extensions][r-ext] guide. Compared to that, this document focusses more on the basics, providing many more examples, and on the most commonly used features. Once you are familiar with the content here, you should find R extensions easier to read.

## Package structure

There are only three elements that you must have:

* the `DESCRIPTION` file describes the package, and is detailed below.

* the `R/` directory where your R code lives (in `.R` or `.r` files). See
  [[style|Style]] for information on how these should be formatted.

* the `man/` directory where your [[function documentation|docs-function]],
  produced with roxygen, lives.

After the code and function documentation, the most important optional components of an R package help your users learn how to use your package. The following files and directories and described in more detail in [[package documentation|docs-package]].

* the `NEWS` file describes the changes in each version of the package. Using
  the standard R format will allow you to take advantage of many automated
  tools for displaying changes between versions.

* the `README` file gives a general overview of your package, including why
  it's important. This text should be included in any package announcement, to
  give people a general idea of why your package is useful.

* the `inst/CITATION` file describes how to cite your package. If you have
  published a peer reviewed article which you'd like people to cite when they
  use your software, this is the place to put it.

* the `inst/demo/` directory contains larger scale demos, that use many 
  features of the package.

* the `inst/doc/` directory is used for larger scale documentation, like
  vignettes.
  
Other optional files and directories are part of good development practice:

* a `NAMESPACE` file describes which functions are part of the formal API of
  the package and are exported for others to use. See [[namespaces]] for more
  details.

* the `inst/tests/` directory contains [[tests|testing]] which ensure that
  your package is operating as designed.

* the `data/` directory contains `.rdata` files, used to include sample
  datasets (or other R objects) with your package.

* the `src/` directory includes source code for any C or fortran functions you
  have written for high-performance computing. Writing these functions is
  beyond the scope of this text and they will not be described further.

## Getting started

When creating a package the first thing (and sometimes the most difficult) is to come up with a name for it. Follow these rules to make a good name:

* The package name can only consist of letters and numbers, and must start
  with a letter.

* I strongly recommend making the package name googleable, so that if you
  google the name you can easily find it. This makes it easy for potential
  users to find your package, and it's also useful for you, because it makes
  it easier to find out who is using it.

* Avoid using both upper and lower case letters: they make the package name
  hard to type and hard to remember. For example, I can never remember if it's
  `Rgtk2` or `RGTK2` or `RGtk2`.

Once you have a name, create a directory with that name, and inside that create an `R` subdirectory. Copy your existing code into that directory. It's up to you how you arrange your functions into files, but I suggest grouping related functions into a single file. My rule of thumb is that if I can't remember which file a function lives in, I probably need to split them up into more files - having one function per file is perfectly reasonable, particularly if the functions are large or have a lot of documentation.

The next step is to create a `DESCRIPTION` file that defines package metadata.

## DESCRIPTION

The `DESCRIPTION` contains important information that describes how your package fits into the R ecosystem. I've included the the `DESCRIPTION` file for the `plyr` package below so that you can see what the basic components are. 

    Package: plyr
    Title: Tools for splitting, applying and combining data
    Description: plyr is a set of tools that solves a common set of
        problems: you need to break a big problem down into manageable
        pieces, operate on each pieces and then put all the pieces back
        together.  For example, you might want to fit a model to each
        spatial location or time point in your study, summarise data by
        panels or collapse high-dimensional arrays to simpler summary
        statistics. The development of plyr has been generously supported
        by BD (Becton Dickinson).
    URL: http://had.co.nz/plyr
    Version: 1.3
    Maintainer: Hadley Wickham <h.wickham@gmail.com>
    Author: Hadley Wickham <h.wickham@gmail.com>
    Depends: R (>= 2.11.0)
    Suggests: abind, testthat (>= 0.2), tcltk, foreach
    Imports: itertools, iterators
    License: MIT
    LazyData: true

There are six required elements:

* `Package`: name of the package - this should be the same as the directory
  name.

* `Title`: a one line description of the package.

* `Description`: a more detailed paragraph-length description.

* `Version`: the version number, which should be of the the form
  `major.minor.patchlevel`. See `?package_version` for more details on the
  package version formats.

* `Maintainer`: a single name and email address for the person responsible for
  package maintenance.

* `Author`: a free-form text string listing all contributors to the package.

There are a number of other components that are optional, but still important: 

* `Depends`, `Suggests`, `Imports` and `Enhances` describe the which packages
  this package needs. They are described in more detail in [[namespaces]].

* `License`: a standard abbreviation for an open source license, like `GPL-2`
  or `BSD`. A complete list of possibilities can be found by running
  `file.show(file.path(R.home(), "share/licenses/license.db"))`. If you are
  using a non-standard license (not recommended), put `file LICENSE` and then
  include the full text of the license in a `LICENSE`.

* `URL`: a url to the package website. Multiple urls can be separated with a
  comma or whitespace.

[r-ext]:http://cran.r-project.org/doc/manuals/R-exts.html#Creating-R-packages