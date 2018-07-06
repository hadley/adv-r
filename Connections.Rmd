# Connections

In R, every time you read data in or write data out, you are using a connection behind the scenes. Connections abstract away the underlying implementation so that you can read and write data the same way, regardless of whether you're writing to a file, an HTTP connnection, a pipe, or something more exotic.

* http://biostatmatt.com/R/R-conn-ints/index.html#Top
* `?file`
* https://cran.r-project.org/doc/Rnews/Rnews_2001-1.pdf
* https://cran.r-project.org/doc/manuals/r-release/R-data.html#Connections

## Basics

* default connections: stdin, stderr, stdout
* `cat()` + `cat_line()`
* survey of base connections: file, compressed file, url, pipe, socket, text
* important packages: curl
* blocking vs non-blocking
* pattern: `close()` with `on.exit()` if you opened

## Reading and writing binary data

* `raw()`
* `readBin()` vs `writeBin()`
* text vs binary (newlines and nulls)


## Reading and writing text data

Reading and writing text is more complicated than reading and writing binary data because as soon as you move beyond regular ASCII characters (e.g. a-z, 0-9) there are many different ways of representing the same text. The way in which text data is stored in binary is known as the __encoding__.

* Encodings   
    * https://kevinushey.github.io/blog/2018/02/21/string-encoding-and-r/
    * in general vs `Encoding`
    * `encoding` vs `fileEncoding`
    * converting with iconv
   
* UTF-8 everywhere
* Reliably reading and writing UTF-8
