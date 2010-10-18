# Package basics

An R package is the basic unit of reusable code.  This document explains how to get started creating your own package.  Full details are available in the [writing R extensions](http://cran.r-project.org/doc/manuals/R-exts.html#Creating-R-packages) guide.

# Package structure

There are only three elements that you must have:

* a `DESCRIPTION` file which gives metadata about the package

* an `R/` directory where you R code lives (in `.R` or `.r` files)

* a `man/` directory where your [[documentation]], produced with roxygen,
  lives

Most packages will also include the following files and directories:

* `data/` which contains `.rdata` files if you want to include
  sample datasets (or other R objects) with your package.

* `inst/doc/` for larger scale documentation like vignettes.

* `inst/tests/` to contain your package [[testing]] code.

* `inst/demo/`

* `src` for the source code for any C or fortran functions you have written.

* the `NEWS` file describes the changes in each version of the package. Using
  the standard R format will allow you to take advantage of many automated
  tools for displaying changes between versions.

* a `README` file should give a general overview of your package, including
  why it's important.  I usually include this text in any package announcement
  that I make.

* a `NAMESPACE` file describes which functions are part of the formal API of
  the package and are exported for others use. See [[namespaces]] for more
  details.

* a `CITATION` file describes how to cite your package. If you have published
  a peer reviewed article which you'd like people to cite when they use your
  software, this is the place to put it.

# Getting started

To create a package the first thing (and sometimes the most difficult) is to come up with a name for it. Following the following rules for coming up with a name:

* The package name can only consist of letters and numbers, and must start
  with a letter

* I strongly recommend making the package name googleable, i.e. if you google
  for the name there are very few existing hits. This is very useful as it
  makes it easy to track who is using your package, and is particularly useful
  when searching full text journal articles.

* Avoid capital letters: they make the package name harder to type, and harder
  to remember what combination of upper and lower case letters is correct
  (e.g. I can never remember if it's `Rgtk2` or `RGTK2` or `RGtk2`).

Once you have your name, create a directory of that same name, and inside that create an `R` subdirectory copy your existing code into that directory. It's up to you how you arrange your functions into files, but I suggest grouping related functions into a single file. My rule of thumb is that if I can't remember which file a function lives in, I probably need to split them up into more files - having one function per file is perfectly reasonable, particularly if the functions are large or have a lot of documentation.

The next step is to create a description file that gives the run down of basic information about your package.  I normally copy one from another package and modify it to suit.

# `DESCRIPTION`

I've included the the `DESCRIPTION` file for the `plyr` package below so that you can see what the basic components R.

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
    Author: Hadley Wickham <h.wickham@gmail.com>
    Maintainer: Hadley Wickham <h.wickham@gmail.com>
    Depends: R (>= 2.11.0)
    Suggests: abind, testthat (>= 0.2), tcltk, foreach
    Imports: itertools, iterators
    License: MIT
    LazyData: true

These are describe in more detail below

  * package: name of the package - should be the same as the directory name
  * title: a one-line description of the package
  * description: a more detailed paragraph-length description
  * version: version number, usually of the form `major.minor.patchlevel`. 
    See `?package_version` for more details on the package version format
  * author: a free-form text string listing all contributors to the package
  * maintainer: a single name and email address for the person responsible for
    package maintenance

Optional components

  * depends, suggests, imports and enhances describe the package dependencies
    and are described more in [[namespaces]]
  * the package __license__: a standard abbreviation for an open source
    license or "file LICENSE" if non-standard (not recommended)
  * URL: a pointer to the package website.  Multiple urls can be separated 
    with a comma or whitespace.

Other optional (and less used) fields are:

  * Date
  * Collate
  * Type
  * BugReports
  * CopyRight
  * Language
  * Classification
