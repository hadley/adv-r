# Package development philosophy

This book espouses a particular philosophy of package development - it is not shared by all R developers, but it is one connected to a specific set of tools that makes package development as easy as possible.

There are three packages we will use extensively:

* `devtools`, which provides a set of R functions that makes package
  development as easy as possible.

* `roxygen2`, which translates source code comments into R's official
  documentation format

* `testthat`, which provides a friendly unit testing framework for R.

Other styles of package development don't use these packages, but in my experience they provide a useful trade off between speed and rigour. That's a theme that we'll see a lot in this chapter: base R provides rigorous tools that guarantee correctness, but tend to be slow. Sometimes you want to be able to iterate more rapidly and the tools we discuss will allow you to do so.

## Getting started

To get started, make sure you have the latest version of R: if you want to submit your work to CRAN, you'll need to make sure you're running all checks with the latest R.

You'll also need to make sure you have the appropriate development tools installed:

* On windows, download Rtools: http://cran.r-project.org/bin/windows/Rtools/

* On mac, make sure you have either XCode (free, available in the app store)
  or the "Command Line Tools for Xcode" (needs a free apple id, available from
  http://developer.apple.com/downloads)

* On linux, make sure you've installed not only R, but the R development
  devtools. This a linux package called something like `r-base-dev`.

You can check you have everything installed and working by running this code:

    library(devtools)
    has_devel()

It will print out some compilation code (this is needed to help diagnose problems), but you're only interested in whether it returns `TRUE` (everything's ok) or an error (which you need to investigate further).