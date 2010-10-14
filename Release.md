# Release checklist

  * update `NEWS`, checking that dates are correct
  * `R CMD build` then upload to CRAN: `ftp -u ftp://cran.R-project.org/incoming/ package_name.tar.gz`
  * send email to `cran@r-project.org`

Once you've received confirmation that all checks have passed on all platforms:

  * `git tag`
  * bump version in `DESCRIPTION` and `NEWS` files
  * send release announcement to `r-packages`
  * announce on twitter, blog etc.
  * update package webpage
