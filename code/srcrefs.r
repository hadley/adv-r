
f <- function(x) {
 if (x > 2) {
    y <- 2
    z <- x + 1
 }
}

That function has a nested structure.  If you look at the attributes of body(f), you'll see it has 3:  srcref, srcfile, and wholeSrcref. wholeSrcref includes the whole assignment to f.  srcref is the thing I was calling the one on the container.

srcref[[1]] is the opening brace, and srcref[[2]] is the whole if statement.  They correspond to the two components of body(f).

body(f)[[1]] is not recursive, so you can stop looking at it.

body(f)[[2]] is recursive, with 3 elements:  if, x > 2, and the compound statement.  The compound statement is the thing that will also have a srcref attached:

attributes(body(f)[[2]][[3]])

will show it (plus another srcfile and wholeSrcref; those are probably not needed, but I forget right now).
