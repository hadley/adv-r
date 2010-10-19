# Dealing with errors and exceptions

## Exceptions

### Creating

  * `stop()`
  * `warning()`
  * `message()`
  
### Handling

  * `try`
  * `tryCatch`

Examples:

  * capturing all messages or warnings produced by a function
  * capturing user interrupts: `Ctrl + C`

## Debugging

* `traceback`: show where error occurred
* `browser`: interact inside function environment.  `c`, `n`, `return`, `Q`, `where`
* `debug`/`undebug`, `debugonce`: automatically inserts browser
* `trace`, `untrace`: automatically inserts any code
* `recover`, `options(error = recover)`: automatic traceback + browser on error

If you're trying to track down where a warning occurs, it can be useful to turn it into an error with `options(warn = 2)`.  Turn back to default behaviour with `options(warn = 0)`.

Don't forget that you can combine `if` statements with `browser()` to only debug when a certain situation occurs.