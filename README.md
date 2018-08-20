# Advanced R programming

[![Build Status](https://travis-ci.org/hadley/adv-r.svg?branch=master)](https://travis-ci.org/hadley/adv-r)

This is code and text behind the [Advanced R programming](http://adv-r.hadley.nz)
book.  The site is built with [bookdown](https://bookdown.org/yihui/bookdown/).

## Diagrams

Omnigraffle:
  
* Make sure that 100% is "one postscript point": this ensures canvas
  size matches physical size.
  
* Use inconsolata 10pt, and export at 300 dpi scaled to 100%.

* Set grid to 1cm with 10 minor units. Default scalar size is 6mm x 6mm.

Book:

* Inconsolata scaled (by fontspec) to match main font is 9.42pt.

* Preview at 100% matches physical size of book. Maxiumum diagram width is 11cm.

RMarkdown

* Remove dpi specification from `include_graphics()`, instead relying
  on `common.R`. Chunk should have `output.width = NULL`.
