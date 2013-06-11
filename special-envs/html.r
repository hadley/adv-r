#' We first start by creating a way of escaping the characters that have special
#' meaning for html, while making sure we don't end up double-escaping at any
#' point. The easiest way to do this is to create an S3 class that allows us to
#' distinguish between regular text (that needs escaping) and html (that
#' doesn't).
#'
#' We then write an escape method that leaves html unchanged and escapes the
#' special characters (&, <, >) in ordinary text. We also add a method for lists
#' for convenience

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

#' ```R
#' escape("This is some text.")
#' escape("x > 1 & y < 2")
#' escape(escape("x > 1 & y < 2"))
#'
#' # Double escaping is not a problem
#' escape(escape("This is some text. 1 > 2"))
#'
#' # And text we know is html doesn't get escaped.
#' escape(html("<hr />"))
#' ```

#' Next we'll write a few simple tag functions and then figure out how to
#' generalise for all possible html tags.  Let's start with a paragraph
#' tag since that's probably the most commonly used.
#'
#' HTML tags can have both attributes (e.g. id, or class) and children (like <b>
#' or <i>). We need some way of separating these in the function call: since
#' attributes are named values and children don't have names, it seems natural
#' to separate using named vs. unnamed arguments. Then a call to `p()` might look
#' like:
#'
#' ```R
#' p("Some text.", b("Some bold text"), i("Some italic text"), class = "mypara")
#' ```
#'
#' We could list all the possible attributes of the p tag in the function
#' definition, but that's hard because there are so many, and it's possible to
#' use [custom attributes](http://html5doctor.com/html5-custom-data-attributes/)
#' Instead we'll just use ... and separate the components based on whether
#' or they are named. To do this correctly, we need to be aware of a "feature" of
#' `names()`:
#'
#' ```R
#' names(c(a = 1, b = 2))
#' names(c(a = 1, 2))
#' names(c(1, 2))
#' ```
#'
#' With this in mind we create two helper functions to extract the named
#' and unnamed components of a vector:

named <- function(x) {
  if (is.null(names(x))) return(NULL)
  x[names(x) != ""]
}
unnamed <- function(x) {
  if (is.null(names(x))) return(x)
  x[names(x) == ""]
}

#' With this in hand, we can create our p function. There's one new function
#' here: `html_attributes()`. This takes a list of name-value pairs and
#' creates the correct html attributes specification from them. It's a little
#' complicated, not that important and doesn't introduce any important new
#' ideas, so I won't discuss it here, but you might want to read the source
#' code to see how it works

p <- function(...) {
  args <- list(...)
  attribs <- html_attributes(named(args))
  children <- unlist(escape(unnamed(args)))

  html(paste0("<p", attribs, ">", paste(children, collapse = ""), "</p>"))
}

#' ```R
#' p("Some text")
#' p("Some text", id = "myid")
#' p("Some text", image = NULL)
#' p("Some text", class = "important", "data-value" = 10)
#' ```

#' With this definition of `p()` it's pretty easy to see what will change
#' for different tags.  We'll use a function operator to make it easy to generate
#' a tag function given a tag name:

tag <- function(tag) {
  force(tag)
  function(...) {
    args <- list(...)
    attribs <- html_attributes(named(args))
    children <- unlist(escape(unnamed(args)))

    html(paste0(
      "<", tag, attribs, ">",
      paste(children, collapse = ""),
      "</", tag, ">"
    ))
  }
}

#' Now we can run our earlier example:
#'
#' ```R
#' p <- tag("p")
#' b <- tag("b")
#' i <- tag("i")
#' p("Some text.", b("Some bold text"), i("Some italic text"), class = "mypara")
#' ```
#'
#' Before we continue to generate functions for every possible html tag, we
#' need a variant of tag for void tags: tags that can not have children.

void_tag <- function(tag) {
  function(...) {
    args <- list(...)
    if (length(unnamed(args)) > 0) {
      stop("Tag ", tag, " can not have children", call. = FALSE)
    }
    attribs <- html_attributes(named(args))

    html(paste0("<", tag, attribs, " />"))
  }
}

#' ```R
#' img <- void_tag("img")
#' img(src = "diamonds.png", width = 10, height = 10)
#' ```

#' Next we need a list of all the html tags:

tags <- c("a", "abbr", "address", "article", "aside", "audio", "b", "bdi",
  "bdo", "blockquote", "body", "button", "canvas", "caption", "cite",
  "code", "colgroup", "data", "datalist", "dd", "del", "details",
  "dfn", "div", "dl", "dt", "em", "eventsource", "fieldset", "figcaption",
  "figure", "footer", "form", "h1", "h2", "h3", "h4", "h5", "h6",
  "head", "header", "hgroup", "html", "i", "iframe", "ins", "kbd",
  "label", "legend", "li", "mark", "map", "menu", "meter", "nav",
  "noscript", "object", "ol", "optgroup", "option", "output", "p",
  "pre", "progress", "q", "ruby", "rp", "rt", "s", "samp", "script",
  "section", "select", "small", "span", "strong", "style", "sub",
  "summary", "sup", "table", "tbody", "td", "textarea", "tfoot",
  "th", "thead", "time", "title", "tr", "u", "ul", "var", "video")

void_tags <- c("area", "base", "br", "col", "command", "embed", "hr",
  "img", "input", "keygen", "link", "meta", "param",
  "source", "track", "wbr")

#' If you look at this list carefully, you'll see there are quite a few tags
#' that have the same name as base R functions (body, col, q, source, sub,
#' summary, table), and others that clash with popular packages (e.g. map).
#' So we don't want to make all the functions available (in either the global
#' environment or a package environment) by default.  So what we'll do is
#' put them in a list, and add some additional code to make it easy to use
#' them when desired.

tag_fs <- c(
  setNames(lapply(tags, tag), tags),
  setNames(lapply(void_tags, void_tag), void_tags)
)

#' This gives us a way to call tag functions explicitly, but is a little
#' verbose:
#'
#' ```R
#' tags$p("Some text.", tags$b("Some bold text"), tags$i("Some italic text"))
#' ```

#' We finish off our HTML DSL by creating a function that allows us to evaluate
#' code in the context of that list:

with_html <- function(code) {
  eval(substitute(code), tag_fs)
}

#' This gives us a succinct API which allows us to write html when we need it
#' without cluttering up the namespace when we don't. Inside `with_html` if you
#' want to access the R function overridden by an html tag of the same name, you
#' can use the full `package::function` specification.
#'
#' ```R
#' with_html(p("Some text.", b("Some bold text"), i("Some italic text")))
#' ```

# ------------------------------------------------------------------------------

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
