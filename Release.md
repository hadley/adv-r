# Releasing a package

## Checking

* from within R, run `roxygenise()`, or `devtools::document()` to update
  documentation

* from the command line, run `R CMD check`

Passing `R CMD check` is the most frustrating part of package development, and it usually takes some time the first time. Hopefully by following the tips elsewhere in this document you'll be in a good place to start - in particular, using roxygen and only exporting the minimal number of function is likely to save a lot of work.

One place that it is frustrating to have problems with is the examples. If you discover a mistake, you need to fix it in the roxygen comments, rerun roxygen and then rerun `R CMD check`. The examples are one of the last things checked, so this process can be very time consuming, particularly if you have more than one bug. The `devtools` package contains a function, `run_examples` designed to make this somewhat less painful: all it does is run functions. It also has an optional parameter which tells it which function to start at - that way once you've discovered an error, you can rerun from just that file, not all the files that lead up to.

## Publishing on CRAN

Once you have passed the checking process, you need to upload your package to CRAN.  The checks will be run again with the latest development version of R, and on all platforms that R supports - this means that you should be prepare for more bugs to crop up.  Don't get excited too soon!

* update `NEWS`, checking that dates are correct. Use `devtools::show_news` to
  check that it's in the correct format.

* `R CMD build` then upload to CRAN: 
  `ftp -u ftp://cran.R-project.org/incoming/ package_name.tar.gz`

* send an email to `cran@r-project.org` - this is optional, but if you don't
  you'll only hear back if something went wrong with the checking process. An example email would be something like: Hello, I just uploaded package name to cran. Please let me know if anything goes wrong. Thank you, Me

Once all the checks have passed you'll get a friendly email from the CRAN maintainer and you'll be ready to start publicising your package.

## Publicising

Once you've received confirmation that all checks have passed on all platforms, you have a couple of technical operations to do:

* `git tag`, so you can mark exactly what version of the code this release
  corresponds to

* bump version in `DESCRIPTION` and `NEWS` files

Then you need to publicise your package.  This is vitally important - for you hard work to be useful to someone, they need to know that it exists!

* send release announcement to `r-packages@stat.math.ethz.ch`. A release
  announcement should consist of a general introduction to your package (i.e.
  why should people care that you released a new version), and as well as
  what's new. I usually make these announcements by pasting together the
  package `README` and the appropriate section from the `NEWS`.

* announce on twitter, blog etc.

* Finally, don't forget to update your package webpage. If you don't have a
  package webpage - create one! There you can announce new versions, point to
  help resources, videos and talks about the package. If you're using github,
  I'd recommend using [github pages](http://pages.github.com/) to create the
  website.