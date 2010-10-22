# Advanced R development

This wiki describes the three sets of skills that I think you need to be an advanced R developer:

* You know the three specialised languages needed to extract data from the
  types of data that analysts encounter most often: regular expressions for
  strings, SQL for databases, and xpath for xml.

* You are familiar with the fundamentals of R, so that you can represent
  complex data types and simplify the operations performed on them. You have a
  deep understanding of the language, and know how to override default
  behaviours when necessary

* You know how to produce packages to make your work available to a wider
  audience, and how to efficiently program "in the large", so you spend your
  time solving new problems not struggling with old code.

## Specialised data languages

These types of data come up so frequently it's useful to know a little about them and the specialised languages that you use to work with them:

  * [[Strings and regular expressions|lang-regexp]]  (outline)
  * [[Databases and SQL|lang-sql]]  (outline)
  * [[XML and XPath|lang-xml]]   (outline)

## R fundamentals

In the following pages I try and explain how fundamental R components work, taking the [R language definition][lang-def] and making it easier to understand with plenty of examples to illustrate each idea.

  * [[The S3 object system|S3]]  (draft)
  * [[The S4 object system|S4]]  (draft)
  * [[Scoping, environments and closures|Scoping]]  (draft)
  * Reference based classes 
  * [[Controlling evaluation|Evaluation]]  (complete)
  * [[Lazy evaluation|Lazy-evaluation]]  (draft)
  * [[Computing on the language|Computing-on-the-language]]  (outline)
  * [[Exceptions and debugging|Exceptions-debugging]]  (outline)

These sections are designed to be a primer for the more technical descriptions available in the [R language definition][lang-def] and [software for data analysis](http://amzn.com/0387759352).

## Package development

Learn how to get started with a package in [[package basics]], and then read up on the following topics to master package development:

  * [[well tested||Testing]]
  * clearly documented, at both the [[function|docs-function]] and
    [[package|docs-package]] level  (outline)
  * readable, with well defined [[style]]  (complete)
  * uses [[namespaces]] to minimise conflict with other packages  (draft)
  * [[source code control|git]]: git + github  (outline)
  * [[ready for release|Release]]  (complete)

The canonical reference for package development will always be [writing R extensions][r-ext] - these pages attempt to expand on the more important points and discuss more of the why and what of best practices.

## Miscellaneous

* [[How to make a reproducible example|Reproducibility]]
* [[A philosophy of data|data-philosophy]]
* Mastering the command line

  [lang-def]:http://cran.r-project.org/doc/manuals/R-lang.html
  [r-ext]:http://cran.r-project.org/doc/manuals/R-exts.html