# Advanced R development
(Making reproducible code)

[[Introduction]]

## R fundamentals

In the following pages I try and explain how fundamental R components work, taking the [R language definition][lang-def] and making it easier to understand with plenty of examples to illustrate each idea. These tools are important because they allow to identify and reduce duplication in a wider variety of settings.

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
  * [[Exceptions and debugging|Exceptions-debugging]]

* Performant code
  * [[Performance and profiling|performance]]
  * [[R's C interface|c-interface]]
  * [[High performance functions with Rcpp|Rcpp]]

These sections are designed to be a primer for the more technical descriptions available in the [R language definition][lang-def] and [software for data analysis](http://amzn.com/0387759352).

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

## Miscellaneous

* [[How to make a reproducible example|Reproducibility]]

  [lang-def]:http://cran.r-project.org/doc/manuals/R-lang.html
  [r-ext]:http://cran.r-project.org/doc/manuals/R-exts.html