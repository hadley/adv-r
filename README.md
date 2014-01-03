# Advanced R programming

This is code and text behind the [Advanced R programming](http://adv-r.had.co.nz)
book. 

The site is built using jekyll, with a custom plugin to render `.rmd` files with
knitr and pandoc. To create the site, you need:

* jekyll and s3_websiter gems: `gem install jekyll s3_website`
* [pandoc](http://johnmacfarlane.net/pandoc/)
* [knitr](http://yihui.name/knitr/): `install.packages("knitr")`

## Internal links

To link between sections, use internal links of the form `#header-id`. All header references are listed in `toc.yaml` and `_plugins/index.R` provides some other useful tools.