# The package development cycle

How do you write code when you are developing a package? How do you make sure that the code is correct, without constantly running `R CMD install` or `R CMD check`? This chapter discusses the development cycle of an R package, and introduces software to support it: the `devtools` package.

## Development cycles

It's useful to distinguish between exploratory programming and confirmatory programming (in the same sense as exploratory and confirmatory data analysis) because the development cycle differs in several important ways.

### Confirmatory programming

Confirmatory programming happens when you know what you need to do, and what the results of yours changes will be (new feature X appears or known bug Y disappears) you just need to figure out the way to do it. Confirmatory programming is also known as [test driven development][tdd] (TDD), a development style that grew out of extreme programming. The basic idea is that before you implement any new feature, or fix a known bug, you should:

1. Write automated test, and run `test()` to make sure test fails (so you know
   you've captured the bug correctly)

2. Modify code to fix the bug or implement the new feature.

3. Run `load_all(pkg) && test(pkg)` to reload the file and re-run the tests.

4. Repeat 2&ndash;4 until all tests pass.

You might also want to use the `testthat::autotest()` which will watch your tests and code and will automatically rerun the tests when either changes. This allows you to skip step three - you just modify your code and watch to see if the tests pass or fail.

### Exploratory programming

Exploratory programming is the complement of confirmatory programming, when you have some idea of what you want to achieve, but you're not sure about the details. You're not sure what the functions should look like, what arguments they should have and what they should return. You may not even be sure how you are going to break down the problem into pieces. In exploratory programming, you're exploring the solution space by writing functions, and you need to freedom to rewrite large chunks of the code as you understand the problem domain better.

The exploratory programming cycle is similar to confirmatory, but it's not usually worth writing the tests before writing the code, because the interface will change so much:

1. Edit code and reload with `load_all()`.
2. Test interactively.
3. Repeat 1&ndash;2 until code works.
4. Write automated tests and `test()`.

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

This means by default devtools will look for a package called `pkg` in `~/document/pkg/pkg`. (I use the other directories to store related files like conference presentations or journal articles.) Other packages that don't follow this same pattern are listed explicitly.

### Useful functions

The functions that you'll use most often are:

* `load_all(pkg)`, which loads code (`load_code`), data (`load_data`) and C
  files (`load_c`). These are loaded into a non-global environment to avoid
  conflicts, and so all functions can easily be removed. By default `load_all`
  will only load changed files to save time&mdash;if you want to reload everything
  from scratch, run `load_all(pkg, T)`

* `test(pkg)` runs all tests in `inst/test/` and reports the results


* `document(pkg)` runs roxygen on the package to update all documentation. 

[devtools-down]:https://github.com/hadley/devtools/tarball/master
[tdd]:http://en.wikipedia.org/wiki/Test-driven_development
