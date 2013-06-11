# Domain specific languages

The combination of first class environments and lexical scoping gives us a powerful toolkit for creating domain specific languages in R. There's much to be said about domain specific languages, and most of it is said very well by Martin Fowler in his book [Domain Specific Languages](http://amzn.com/0321712943). In this section we'll explore how you can new languages that use R's syntax but have different behaviours.

We'll first look at html, making it possible to write code that produces html structured in a way very similar to the output html.

```R
with_html(
  body(
    h1("A heading", id = "first"),
    p("Some text. ", b("Some bold text."), "Some more text")
  )
)
```

## Html

We first start by creating a way of escaping the characters that have special meaning for html, while making sure we don't end up double-escaping at any point. The easiest way to do this is to create an S3 class that allows us to distinguish between regular text (that needs escaping) and html (that doesn't).

We then write an escape method that leaves html unchanged and escapes the special characters (`&`, `<`, `>`) in ordinary text. We also add a method for lists for convenience

```r
html <- function(x) structure(x, class = "html")
escape <- function(x) UseMethod("escape")
escape.html <- function(x) x
escape.character <- function(x) {
  x <- gsub("&", "&amp;", x)
  x <- gsub("<", "&lt;", x)
  x <- gsub(">", "&gt;", x)
  
  html(x)
}
escape.list <- function(x) {
  lapply(x, escape)
}

# Now we check that it works
escape("This is some text.")
escape("x > 1 & y < 2")
escape(escape("x > 1 & y < 2"))

# Double escaping is not a problem
escape(escape("This is some text. 1 > 2"))

# And text we know is html doesn't get escaped.
escape(html("<hr />"))
```

Next we'll write a few simple tag functions and then figure out how to generalise for all possible html tags.  Let's start with a paragraph tag since that's probably the most commonly used.

HTML tags can have both attributes (e.g. id, or class) and children (like `<b>` or `<i>`). We need some way of separating these in the function call: since attributes are named values and children don't have names, it seems natural to separate using named vs. unnamed arguments. Then a call to `p()` might look like:

```R
p("Some text.", b("Some bold text"), i("Some italic text"), 
  class = "mypara")
```

We could list all the possible attributes of the p tag in the function definition, but that's hard because there are so many, and it's possible to use [custom attributes](http://html5doctor.com/html5-custom-data-attributes/) Instead we'll just use ... and separate the components based on whether or they are named. To do this correctly, we need to be aware of a "feature" of `names()`:

```R
names(c(a = 1, b = 2))
names(c(a = 1, 2))
names(c(1, 2))
```

With this in mind we create two helper functions to extract the named and unnamed components of a vector:

```r
named <- function(x) {
  if (is.null(names(x))) return(NULL)
  x[names(x) != ""]
}
unnamed <- function(x) {
  if (is.null(names(x))) return(x)
  x[names(x) == ""]
}
```

With this in hand, we can create our `p()` function. There's one new function here: `html_attributes()`. This takes a list of name-value pairs and creates the correct html attributes specification from them. It's a little complicated, not that important and doesn't introduce any important new ideas, so I won't discuss it here, but you might want to read the source code to see how it works

```r
p <- function(...) {
  args <- list(...)
  attribs <- html_attributes(named(args))
  children <- unlist(escape(unnamed(args)))
  
  html(paste0("<p", attribs, ">", paste(children, collapse = ""), "</p>"))
}
```

```R
p("Some text")
p("Some text", id = "myid")
p("Some text", image = NULL)
p("Some text", class = "important", "data-value" = 10)
```

With this definition of `p()` it's pretty easy to see what will change for different tags.  We'll use a function operator to make it easy to generate a tag function given a tag name:

```r
tag <- function(tag) {
  force(tag)
  function(...) {
    args <- list(...)
    attribs <- html_attributes(named(args))
    children <- unlist(escape(unnamed(args)))
    
    html(paste0("<", tag, attribs, ">", 
      paste(children, collapse = ""), 
      "</", tag, ">"))
  }
}
```

Now we can run our earlier example:

```R
p <- tag("p")
b <- tag("b")
i <- tag("i")
p("Some text.", b("Some bold text"), i("Some italic text"), 
  class = "mypara")
```

Before we continue to generate functions for every possible html tag, we need a variant of tag for void tags: tags that can not have children.

```r
void_tag <- function(tag) {
  force(tag)
  function(...) {
    args <- list(...)
    if (length(unnamed(args)) > 0) {
      stop("Tag ", tag, " can not have children", call. = FALSE)
    }
    attribs <- html_attributes(named(args))
    
    html(paste0("<", tag, attribs, " />"))
  }
}
```

```R
img <- void_tag("img")
img(src = "diamonds.png", width = 10, height = 10)
```

Next we need a list of all the html tags:

```r
tags <- c("a", "abbr", "address", "article", "aside", "audio", "b", 
  "bdi", "bdo", "blockquote", "body", "button", "canvas", "caption", 
  "cite", "code", "colgroup", "data", "datalist", "dd", "del", 
  "details", "dfn", "div", "dl", "dt", "em", "eventsource", 
  "fieldset", "figcaption", "figure", "footer", "form", "h1", "h2", 
  "h3", "h4", "h5", "h6", "head", "header", "hgroup", "html", "i", 
  "iframe", "ins", "kbd", "label", "legend", "li", "mark", "map", 
  "menu", "meter", "nav", "noscript", "object", "ol", "optgroup", 
  "option", "output", "p", "pre", "progress", "q", "ruby", "rp", 
  "rt", "s", "samp", "script", "section", "select", "small", "span", 
  "strong", "style", "sub", "summary", "sup", "table", "tbody", 
  "td", "textarea", "tfoot", "th", "thead", "time", "title", "tr", 
  "u", "ul", "var", "video") 

void_tags <- c("area", "base", "br", "col", "command", "embed", 
  "hr", "img", "input", "keygen", "link", "meta", "param", "source", 
  "track", "wbr")
```

If you look at this list carefully, you'll see there are quite a few tags that have the same name as base R functions (`body`, `col`, `q`, `source`, `sub`, `summary`, `table`), and others that clash with popular packages (e.g. `map`). So we don't want to make all the functions available (in either the global environment or a package environment) by default.  So what we'll do is put them in a list, and add some additional code to make it easy to use them when desired.

```r
tag_fs <- c(
  setNames(lapply(tags, tag), tags), 
  setNames(lapply(void_tags, void_tag), void_tags)
)
```

This gives us a way to call tag functions explicitly, but is a little
verbose:

```R
tags$p("Some text.", tags$b("Some bold text"), 
  tags$i("Some italic text"))
```

We finish off our HTML DSL by creating a function that allows us to evaluate code in the context of that list:

```r
with_html <- function(code) {
  eval(substitute(code), tag_fs)
}
```

This gives us a succinct API which allows us to write html when we need it without cluttering up the namespace when we don't. Inside `with_html` if you want to access the R function overridden by an html tag of the same name, you can use the full `package::function` specification.

```R
with_html(p("Some text", b("Some bold text"), i("Some italic text")))
```

### Code to make html attributes

```r
html_attributes <- function(list) {
  if (length(list) == 0) return("")

  attr <- Map(html_attribute, names(list), list)
  paste0(" ", unlist(attr), collapse = "")
}
html_attribute <- function(name, value = NULL) {
  if (length(value) == 0) return(name)
  if (length(value) != 1) stop("value must be NULL or of length 1")

  if (is.logical(value)) {
  value <- tolower(value)
  } else {
  value <- escape_attr(value)
  }
  paste0(name, " = '", value, "'")
}
escape_attr <- function(x) {
  x <- escape.character(x)
  x <- gsub("\'", '&#39;', x)
  x <- gsub("\"", '&quot;', x)
  x <- gsub("\r", '&#13;', x)
  x <- gsub("\n", '&#10;', x)
  x
}
```

### Exercises

* The escaping rules for `<script>` and `<style>` tags are different: you don't want to escape angle brackets or ampersands, but you do want to escape `</`.  Adapt the code above to follow these rules.

* The use of ... for all functions has some big downsides: there's no input validation and there will be little information in the documentation or autocomplete about how to use the function. Create a new function that when given a named list of tags and their attribute names (like below), creates functions with those signatures.

  ```R
  list(
    a = c("href"),
    img = c("src", "width", "height")
  )
  ```

  All tags should get `class` and `id` attributes.

## Latex

The next DSL we're going to tackle is to convert R expression into their latex math equivalents. (This is a bit like plotmath, but for text output instead of graphical output.).  It is more complicated than the HTML dsl, because not only do we need to convert functions, we also need to convert symbols.  We'll also add a "default" conversion, so that if we don't know how to convert a function, we'll fall back to a standard representation. Like the HTML dsl, we'll also write functionals to make it easier to generated the translators.

Before you begin, make sure you're familiar with

* scoping rules
* creating and manipulating functions
* computing on the language

Some cases that we'll want to handle:

* `x` -> `x`
* `pi` -> `pi`
* `(a + b) / (c * d)` # simple math & parentheses
* `x[1]^2` -> `x_1^2  # subsetting and
* `sin(x + pi / 2)` -> `\sin(x + \pi / 2)` # recognise special symbols and functions

This time we'll work in the opposite direction: we'll start with the
infrastructure and work our way down to generate all the functions we need

First we need a wrapper function that we'll use to convert R expressions into latex math expressions. This works the same way as `to_html`: we capture the unevaluated expression and evaluate it in a special environment.

```r
to_math <- function(x) {
  expr <- substitute(x)
  eval(expr, latex_env(expr))
}
```

This time we're going to create that environment with a function, because it's going to be slightly different for every invocation.  We'll start by creating an environment that allows us to convert the special latex symbols used for Greek.  This is the same basic trick used in `subset` to make it possible to select column ranges by name (`subset(mtcars, cyl:wt)`): we just bind a name to a string in a special environment.

```r
greek <- c(
  "alpha", "theta", "tau", "beta", "vartheta", "pi", "upsilon", 
  "gamma", "gamma", "varpi", "phi", "delta", "kappa", "rho", 
  "varphi", "epsilon", "lambda", "varrho", "chi", "varepsilon", 
  "mu", "sigma", "psi", "zeta", "nu", "varsigma", "omega", "eta", 
  "xi", "Gamma", "Lambda", "Sigma", "Psi", "Delta", "Xi", "Upsilon", 
  "Omega", "Theta", "Pi", "Phi")
greek_list <- setNames(paste0("\\", greek), greek)
greek_env <- list2env(as.list(greek_list), parent = emptyenv())
```

```R
latex_env <- function(expr) {
  greek_env
}

to_math(pi)
to_math(beta)
```

Next, we'll leave any other symbols as is.  This is trickier because we don't know in advance what symbols will be used, and we can't possibly generate them all.  So we'll use a little bit of computing on the language to figure it out: we need a fairy simple recursive function to do this. It takes an expression. If its a name, it converts it to a string. If it's a call, it recurses down through its arguments.

```r
all_names <- function(x) {
  # Base cases
  if (is.name(x)) return(as.character(x))
  if (!is.call(x)) return(NULL)

  # Recursive case
  children <- lapply(x[-1], all_names)
  unique(unlist(children))
}

all_names(quote(x + y + f(a, b, c, 10)))
# [1] "x" "y" "a" "b" "c"
```

We now want to take that list of names, and convert it to an environment so that each symbol is mapped to a string giving its name. Given a character vector, we need to make it into a list and then convert that list into a environment.

```r
latex_env <- function(expr) {
  names <- all_names(expr)
  symbol_list <- setNames(as.list(names), names)
  symbol_env <- list2env(symbol_list)

  symbol_env
}

to_math(x)
to_math(longvariablename)
to_math(pi)
```

But we want to use both the greek symbols and the default symbols, so we need to combine the environments somehow in the function. Since we want to prefer Greek to the defaults (e.g. `to_math(pi)` should give `"\\pi", not `"pi"`), `symbol_env` needs to be the parent of `greek_env`.  That necessitates copying `greek_env`.  Strangely R doesn't come with a function for cloning environments, but we can easily create one by combining two existing functions:

```r
clone_env <- function(env, parent = parent.env(env)) {
  list2env(as.list(env), parent = parent)
}

latex_env <- function(expr) {
  # Default for names in expression is to convert to string equivalent
  names <- all_names(expr)
  symbol_list <- setNames(as.list(names), names)
  symbol_env <- list2env(symbol_list)

  #
  clone_env(greek_env, symbol_env)
}

to_math(x)
to_math(longvariablename)
to_math(pi)
```

Next we want add some functions to our DSL.  We'll start with a couple of helper closures that make it easy to add new unary and binary operators. These functions are very simple since they only have to assemble strings.

```r
unary_op <- function(left, right) {
  function(e1) {
    paste0(left, e1, right)
  }
}

binary_op <- function(sep) {
  function(e1, e2) {
    paste0(e1, sep, e2)
  }
}
```

Then we'll populate an environment with functions created this way. The list below isn't comprehensive, but it should give a good flavour of the possibilities

```r
# Binary operators
fenv <- new.env(parent = emptyenv())
fenv$"+" <- binary_op(" + ")
fenv$"-" <- binary_op(" - ")
fenv$"*" <- binary_op(" * ")
fenv$"/" <- binary_op(" / ")
fenv$"^" <- binary_op("^")
fenv$"[" <- binary_op("_")

# Grouping
fenv$"{" <- unary_op("\\left{ ", " \\right}")
fenv$"(" <- unary_op("\\left( ", " \\right)")
fenv$paste <- paste

# Other math functions
fenv$sqrt <- unary_op("\\sqrt{", "}")
fenv$sin <- unary_op("\\sin(", ")")
fenv$log <- unary_op("\\log(", ")")
fenv$abs <- unary_op("\\left| ", "\\right| ")
fenv$frac <- function(a, b) {
  paste0("\\frac{", a, "}{", b, "}")
}

# Labelling
fenv$hat <- unary_op("\\hat{", "}")
fenv$tilde <- unary_op("\\tilde{", "}")
```

We again modify `latex_env()` to include this environment. It should be the first environment in which names are looked for (because of R's matching rules wrt functions vs. other objects)

```r
latex_env <- function(expr) {
  # Default symbols
  names <- all_names(expr)
  symbol_list <- setNames(as.list(names), names)
  symbol_env <- list2env(symbol_list)

  # Known symbols
  greek_env <- clone_env(greek_env, parent = symbol_env)

  # Known functions
  clone_env(f_env, greek_env)
}

to_math(sin(x + pi))
to_math(log(x_i^2))
```

Finally, we'll add a default for functions that we don't know about. Like the unknown names, we can't know in advance what these will be, so we again use a little computing on the language to figure them out:

```r
all_calls <- function(x) {
  # Base name
  if (!is.call(x)) return(NULL)

  # Recursive case
  fname <- as.character(x[[1]])
  children <- lapply(x[-1], all_calls)
  unique(c(fname, unlist(children, use.names = FALSE)))
}

all_calls(quote(f(g + b, c, d(a))))
```

And we need a closure that will generate the functions for each unknown call

```r
unknown_op <- function(op) {
  force(op)
  function(...) {
    contents <- paste(..., collapse=", ")
    paste0("\\mathtt{", op, "} \\left( ", contents, " \\right )")
  }
}
```

And again we update `latex_env()`:

```r
latex_env <- function(expr) {
  # Default symbols
  symbols <- all_names(expr)
  symbol_list <- setNames(as.list(symbols), symbols)
  symbol_env <- list2env(symbol_list)

  # Known symbols
  greek_env <- clone_env(greek_env, parent = symbol_env)

  # Default functions
  calls <- all_calls(expr)
  call_list <- lapply(calls, unknown_op)
  call_env <- list2env(call_list, parent = greek_env)

  # Known functions
  clone_env(f_env, greek_env)
}

# character vector -> environment
ceply <- function(x, f, ..., parent = parent.frame()) {
  l <- lapply(x, f, ...)
  names(l) <- x
  list2env(l, parent = parent)
}

latex_env <- function(expr) {
  # Default symbols
  symbol_env <- ceply(all_names(expr), identity, parent = emptyenv())

  # Known symbols
  greek_env <- clone_env(greek_env, parent = symbol_env)

  # Default functions
  call_env <- ceply(all_calls(expr), unknown_op, parent = greek_env)

  # Known functions
  clone_env(f_env, greek_env)
}
```

### Exercises:

* complete this DSL to support all the functions that `plotmath` supports

