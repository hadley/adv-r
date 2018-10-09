
emoji <- function(x) {
  x <- emo::ji(x)

  if (knitr::is_latex_output()) {
    path <- emoji_png(x)
    paste0("\\raisebox{-.1\\height}{\\includegraphics[height=10pt]{", path, "}}")
  } else {
    x
  }
}

emoji_png <- function(x) {
   local <- paste0("emoji/", emoji_code(x), ".png")
   if (!file.exists(local)) {
     src <- paste0(
       "https://github.com/twitter/twemoji/raw/gh-pages/2/72x72/",
       emoji_code(x),
       ".png"
     )
     download.file(src, local, quiet = TRUE)
   }
   local
}

emoji_code <- function(x) {
  sprintf("%x", utf8ToInt(x))
}
