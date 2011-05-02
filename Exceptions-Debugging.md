# Dealing with errors and exceptions

## Exceptions

### Creating

* don't use `cat()` or `print()`, except for print methods, or for optional
  debugging information.

* use `message()` to inform the user about something expected - I often do
  this when filling in important missing arguments that have a non-trivial
  computation or impact. Two examples are `reshape2::melt` package which
  informs the user what melt and id variables where used if not specific, and
  `plyr::join` which informs which variables where used to join the two
  tables.

* use `warning()` for unexpected problems that aren't show stoppers

* use `stop()` when the problem is so big you can't continue

### Handling

  * `try`
  * `tryCatch`

Examples:

  * capturing all messages or warnings produced by a function
  * capturing user interrupts: `Ctrl + C`

`suppressWarnings`, `suppressMessages`

## Debugging

* `traceback`: show where error occurred
* `browser`: interact inside function environment.  `c`, `n`, `return`, `Q`, `where`
* `debug`/`undebug`, `debugonce`: automatically inserts browser
* `trace`, `untrace`: automatically inserts any code
* `recover`, `options(error = recover)`: automatic traceback + browser on error

If you're trying to track down where a warning occurs, it can be useful to turn it into an error with `options(warn = 2)`.  Turn back to default behaviour with `options(warn = 0)`.

Don't forget that you can combine `if` statements with `browser()` to only debug when a certain situation occurs.