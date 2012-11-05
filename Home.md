# Advanced R development
(Making reproducible code)

[[Introduction]]

## R programming

* Functional programming
  * [[Functions]]
  * [[Environments]]
  * [[First class functions|First-class-functions]]
* Objected oriented programming
  * [[The S3 object system|S3]]
  * [[The S4 object system|S4]]
  * [[Reference based classes|R5]]
  * [[Software systems|SoftwareSystems]]
* Advanced programming techniques
  * [[Controlling evaluation|Evaluation]]
  * [[Computing on the language|Computing-on-the-language]]
  * [[Exceptions, debugging and getting help|Exceptions-debugging]]
* Performant code
  * [[Profiling and benchmarking|profiling]]
  * [[General performance tips and tricks|performance]]
  * [[R's C interface|c-interface]]
  * [[High performance functions with Rcpp|Rcpp]]

## Package development

Packages are the fundamental unit of reproducible R code. They include reusable R functions, the documentation that describes how to use them, and sample data. In this section you'll learn how to turn your code into packages that others can easily download and use. Writing a package can seem overwhelming at first, but start with the basics and then improve it over time. It doesn't matter if your first version isn't perfect as long as the next version is better.

  * [[Philosophy]]
  * [[Package basics]]
  * [[Development]]
  * Documentation at both the [[function|docs-function]] and
    [[package|docs-package]] levels
  * [[Testing]]
  * Good code [[style]]
  * [[Namespaces]], to minimise conflict with other packages
  * [[Source code control|git]]: git + github
  * [[Ready for release|Release]]

## Appendices

* Introduction to markdown
* [[Basics]]
* [[Vocabulary]]

  [lang-def]:http://cran.r-project.org/doc/manuals/R-lang.html
  [r-ext]:http://cran.r-project.org/doc/manuals/R-exts.html