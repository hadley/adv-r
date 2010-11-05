# Package development

How do you write code when you are developing a package?  How do you make sure that the code is correct, without constantly running `R CMD install` or `R CMD check`.

## devtools package

I developed the `devtools` package to simplify the package development cycle. Currently `devtools` is only available from github (not CRAN). To install, [download the latest version][devtools-down] and install with `R CMD install`.

### Set up

All `devtools` functions accept either a path or a package name. If you specify a name it will load `~/.Rpackages`, and try the path given by the default function, if it's not there, it will look up the package name in the list and use that path.  

For example, a small section of my `~/.Rpackages` looks like this:

    list(
        default = function(x) {
          file.path("~/documents/", x, x)
        }, 

      "describedisplay" = "~/ggobi/describedisplay",
      "tourr" =    "~/documents/tour/tourr", 
      "mutatr" = "~/documents/oo/mutatr"
    )

This means by default it will look in `~/document/pkg/pkg`. I use the other directories to store related files like conference presentations or journal articles.  Other packages that don't follow this same pattern are listed explicitly.

### Useful functions

The functions that you'll use most often are:

* `load_all(pkg)`, which loads code (`load_code`), data (`load_data`) and C
  files (`load_c`). These are loaded into a non-global environment to avoid
  conflicts, and so all functions can easily be removed. By default `load_all`
  will only load changed files to save time - if you want to reload everything
  from scratch, run `load_all(pkg, T)`

* `document(pkg)` runs roxygen on the package to update all documentation. 

* `test(pkg)` runs all tests in `inst/test/` and reports the results

## Development cycle

It's useful to distinguish between exploratory programming and confirmatory programming because the development cycle differs in several important ways.  

* Exploratory programming: you have some idea of what you want to do, but
  you're not sure about the details. You're not sure what the functions should
  look like, what arguments they should have and what they should return. You
  may not even be sure how you are going to break down the problem into
  pieces. In exploratory programming, you're exploring the solution space by
  writing functions, and you need to freedom to rewrite large chunks of the
  code as you understand the problem domain better.

* Confirmatory programming is when you know what you need to do. There's a new
  feature you want to add, or you've discovered a bug that you want to fix.
  You know exactly what you need to do, and what the results of the changes
  will be (new feature X appears or known bug Y disappears) you just need to
  figure out the way to do it.

### Exploratory programming

1. edit code
2. `load_all()`
3. test interactively
4. repeat 1-3 until code works.
5. write automated tests and `test()`
6. write documentation.

### Confirmatory programming

Test driven development (TDD).

1. write automated test
2. `test()` to make sure test fails (so you know you've captured the bug correctly)
3. edit code and `load_all()`
4. repeat until all tests pass

[devtools-down]:https://github.com/hadley/devtools/tarball/master