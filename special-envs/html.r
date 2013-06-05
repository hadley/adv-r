# Extracted from Shiny

# tags$body(tags$p(tags$b("Bold")), "Text", tags$h1("Heading"))
# with_html(body(p(b("Bold")), "Text", h1("Heading")))
with_html <- function(code) {
  eval(substitute(code), tags)
}

tag <- function(`_tag_name`, ...) {
  args <- list(...)
  arg_names <- names(args) %||% rep("", length(args))

  attribs <- args[arg_names != ""]
  children <- collapse_children(args[arg_names == ""])

  structure(
    list(name = `_tag_name`, attribs = attribs, children = children),
    class = "tag"
  )
}
as.character.tag <- function(x, ...) html(x)
format.tag <- function(x, ...) html(x)
print.tag <- function(x, ...) cat(format(x), "\n", sep = "")

void_tag <- function(`_tag_name`, ...) {
  args <- list(...)
  arg_names <- names(args)
  if (is.null(arg_names) || any(arg_names == "")) {
    stop(`_tag_name`, " can not have children", call. = FALSE)
  }

  structure(
    list(name = `_tag_name`, attribs = attribs),
    class = c("void_tag", "tag")
  )
}
is.tag <- function(x) inherits(x, "tag")

html <- function(x, indent = 0) UseMethod("html")
html.tag <- function(x, indent = 0) {
  multi <- length(x$children) > 1

  attribs <- html_attributes(x$attrib)
  children <- html(x$children, indent = if (multi) indent + 1 else 0)

  paste0(
    indent_text(indent),
    "<", x$name, if (nzchar(attribs)) " ", attribs, ">", if (multi) "\n",
    children, if (multi) "\n",
    "</", x$name, ">", if (multi) "\n"
  )
}
html.void_tag <- function(x, indent = 0) {
  attribs <- html_attributes(x$attrib)

  paste0(indent_text(indent), "<", x$name, attribs, "/>")
}

html_attributes <- function(list) {
  attr <- Map(html_attribute, names(list), list)
  paste0(unlist(attr, recursive = FALSE, use.names = FALSE), collapse = " ")
}
html_attribute <- function(name, value) {
  if (length(value) == 0) return(name)
  if (length(value) != 1) stop("value must be NULL or of length 1")

  if (is.logical(value)) {
    value <- to_lower(value)
  } else {
    value <- html_escape(value, attribute=TRUE)
  }
  paste0(name, " = '", value, "'")
}

html.list <- function(x, indent = 0) {
  pieces <- vapply(x, html, indent = indent, FUN.VALUE = character(1))
  paste(pieces, collapse = "\n")
}
html.character <- function(x, indent = 0) {
  paste0(indent_text(indent), html_escape(x, attrib = FALSE))
}

indent_text <- function(x) {
  paste0(rep(" ", x * 2), collapse = "")
}

collapse_children <- function(children) {
  if (is.tag(children) || is.character(children)) {
    list(children)
  } else if (is.list(children)) {
    unlist(lapply(children, collapse_children),
      recursive = FALSE, use.names = FALSE)
  } else {
    list(as.character(children))
  }
}

html_escape <- local({
  .htmlSpecials <- list(
    `&` = '&amp;',
    `<` = '&lt;',
    `>` = '&gt;'
  )
  .htmlSpecialsPattern <- paste(names(.htmlSpecials), collapse='|')
  .htmlSpecialsAttrib <- c(
    .htmlSpecials,
    "\'" = '&#39;',
    "\"" = '&quot;',
    `\r` = '&#13;',
    `\n` = '&#10;'
  )
  .htmlSpecialsPatternAttrib <- paste(names(.htmlSpecialsAttrib), collapse='|')

  function(text, attribute=TRUE) {
    pattern <- if(attribute)
      .htmlSpecialsPatternAttrib
    else
      .htmlSpecialsPattern

    # Short circuit in the common case that there's nothing to escape
    if (!grepl(pattern, text))
      return(text)

    specials <- if(attribute)
      .htmlSpecialsAttrib
    else
      .htmlSpecials

    for (chr in names(specials)) {
      text <- gsub(chr, specials[[chr]], text, fixed=TRUE)
    }

    return(text)
  }
})

tag_names <- c("a", "abbr", "address", "area", "article", "aside", "audio", "b",
  "base", "bdi", "bdo", "blockquote", "body", "br", "button", "canvas",
  "caption", "cite", "code", "col", "colgroup", "command", "data", "datalist",
  "dd", "del", "details", "dfn", "div", "dl", "dt", "em", "embed",
  "eventsource", "fieldset", "figcaption", "figure", "footer", "form", "h1",
  "h2", "h3", "h4", "h5", "h6", "head", "header", "hgroup", "hr", "html", "i",
  "iframe", "img", "input", "ins", "kbd", "keygen", "label", "legend", "li",
  "link", "mark", "map", "menu", "meta", "meter", "nav", "noscript", "object",
  "ol", "optgroup", "option", "output", "p", "param", "pre", "progress", "q",
  "ruby", "rp", "rt", "s", "samp", "script", "section", "select", "small",
  "source", "span", "strong", "style", "sub", "summary", "sup", "table",
  "tbody", "td", "textarea", "tfoot", "th", "thead", "time", "title", "tr",
  "track", "u", "ul", "var", "video", "wbr")

void_tags <- c("area", "base", "br", "col", "command", "embed", "hr",
  "img", "input", "keygen", "link", "meta", "param",
  "source", "track", "wbr")

tag_f <- function(tag_name) {
  force(tag_name)
  if (tag_name %in% void_tags) {
    function(...) void_tag(tag_name, ...)
  } else {
    function(...) tag(tag_name, ...)
  }
}
tags <- list2env(lapply(setNames(tag_names, tag_names), tag_f))

"%||%" <- function(a, b) if (is.null(a)) b else a
