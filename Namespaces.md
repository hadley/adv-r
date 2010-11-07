# Namespaces

Namespaces control what functions and methods that your package exports for
use by others. Namespaces make it easier to come up with you own function
names without worrying about what names other packages have used. A namespace
means you can use any name you like for internal functions, and when there is
a conflict with an exported function, there is a standard disambiguation
procedure.

The easiest way to use namespaces is with roxygen, because it keeps the
namespace definitions next to the function that it concerns.

## Exporting 

It's not always easy to tell whether or not a function is internal or
external. A few rules of thumb:

* Is the purpose of the function different to the purpose of the package? If
  not, make it internal. (A package should provide a set of closely related
  functions for a well-defined problem domain - someone should be able to look
  at all the functions in your package and say this is a package about X - if
  not, you should consider splitting it up into two packages)

* Does the function have a clear purpose and can you easily explain it? Every
  external function needs to be documented, and there's an implicit contract
  that that function will continue to exist in the future. If that's not the
  case, don't export it.

If a function isn't exported, you don't need to document it. This doesn't mean
you shouldn't document it, but you only need to if it's complicated enough
that you think you won't remember what it does.

To export a function, add the roxygen `@export` tag.

To export a method for a S3 generic function, add `S3method` roxygen tag: `@S3method function class`

## Importing 

In your package `DESCRIPTION` there are two ways to indicate that you package requires another package to work: by listing it in either `Depends` or `Imports`. `Depends` works just like using library to load a package, but `Imports` is a little more subtle: the dependency doesn't get loaded in a way the user can see. This is good practice because it reduces the chances of conflict, and it makes the code clearer by requiring the every package used be explicitly loaded. For example, ggplot2 currently depends on the plyr package - this means that once you've loaded ggplot2, you don't need to load plyr to get access to (e.g) `ddply`. This is bad because you can't see which packages a block of code uses.

There are two places you need to record your package's dependency:

* In the `Imports` field in the `DESCRIPTION` file, used by
 `install.packages` to download package dependencies automatically.

* In the `NAMESPACE` file, to make all the functions in the dependency
  available to your code. The easiest way to do this is to add `@imports
  package-name` to your package documentation:

      #' @docType package
      #' ...
      #' @imports stringr MASS

There are two alternatives to using `@imports`, but these are not currently
recommended:

* `@importFrom` imports only selected functions from another package. This is
  currently a pain in roxygen because it doesn't automatically remove
  duplicates - this means that if you use a function in more than one place,
  you have to arbitrarily choose where to import it. Hopefully this will be
  fixed in a future version of roxygen.

* `::` refers to a function within a package directly. I don't recommend this
  method because it doesn't work well during package development -- it will
  always use the installed version of the package, rather than the development
  version

Other types of imports:

* Compiled code: If you have C or Fortran code in your package, you'll need to
  add `@useDynLib mypackage` to your package documentation to ensure your
  functions can access it. This means you don't need to specify `PACKAGE` in
  `.Call`.

* S3 methods: If you are adding a new S3 method for an existing function, use
  `@S3method function class` instead of `@export`. If you have created a new
  generic function, use `@export` to export it, and then `@S3method` for each
  methods.

* S4 methods: See the [R extensions][S4] manual

* You should very very very rarely use `:::`. This is a sign that you're using
  an internal function from someone else - and there is no guarantee that that
  function won't change from version to version. It would be better to
  encourage the author to make it an external, exported function, or ask if
  you could include a copy of it in your package.


[S4]: http://cran.r-project.org/doc/manuals/R-exts.html#Name-spaces-with-S4-classes-and-methods