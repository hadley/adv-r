# Style guide

Good coding style is like using correct punctuation when writing: you can manage without it, but it sure makes things easier to read. As with punctuation, there are many possible variations, and the main thing is to be consistent. The following guide describes the style that I use - you don't have to use it, but you need to have some consistent style that you do follow.  My style is  based on Google's [R style guide][1], with a few tweaks.

Good style is important because while your code only has one author, it will usually have multiple readers, and when you know you will be working with multiple people on the same code, it's a good idea to agree on a common style up-front.

## Notation and naming

### File names

File names should end in `.r` and be meaningful.

When handing in an electronic copy of your assignment code, put your files in a directory called `firstname-lastname-hw-x` then email me a zip of that directory.

    # Good
    explore-diamonds.r
    hadley-wickham-hw-1.r
    # Bad
    foo.r
    my-homework.R

### Identifiers

Variable and function names should be lowercase. Use `_` to separate words within a name. Generally, variable names should be nouns and function names should be verbs. Strive for concise but meaningful names (this is not easy!)

    # Good
    day_one
    day_1
    # Bad
    first_day_of_the_month
    DayOne
    dayone
    djm1

## Syntax

### Spacing

Place spaces around all binary operators (`=`, `+`, `-`, `<-`, etc.). Do not place a space before a comma, but always place one after a comma.

    # Good
    average <- mean(feet / 12 + inches, na.rm = T)
    # Bad
    average<-mean(feet/12+inches,na.rm=T)

Place a space before left parentheses, except in a function call.

    # Good
    `if (debug)`
    `plot(x, y)`

    # Bad
    `if(debug)`
    `plot (x, y)`

Extra spacing (i.e., more than one space in a row) is okay if it improves alignment of equals signs or arrows (`<-`).

    list(
      x = call_this_long_function(a, b), 
      y = a * e / d ^ f)
    
    list(
      total = a + b + c, 
      mean  = (a + b + c) / n)

Do not place spaces around code in parentheses or square brackets. (Except if there's a trailing comma: always place a space after a comma, just like in ordinary English.)

    # Good
    if (debug)
    diamonds[5, ]

    # Bad
    if ( debug )  # No spaces around debug
    x[1,]  # Needs a space after the comma
    x[1 ,]  # Space goes after, not before

### Curly braces

An opening curly brace should never go on its own line and should always be followed by a new line; a closing curly brace should always go on its own line, unless followed by `else`.

Always indent the code inside the curly braces.

    # Good

    if (y < 0 && debug) {
      message("Y is negative")
    }
    
    if (y == 0) {
      log(x)
    } else {
      y ^ x
    }

    # Bad

    if (y < 0 && debug)
    message("Y is negative")
    
    if (y == 0) {
      log(x)
    } 
    else {
      y ^ x
    }

It's ok to leave very short statements on the same line:

    if (y < 0 && debug) message("Y is negative")    

### Indentation

When indenting your code, use two spaces. Never use tabs or mix tabs and spaces. 

### Line length

Keep your lines less than 80 characters. This is the amount that will fit comfortably on a printed page at a reasonable size. If you find you are running out of room, this is probably an indication that you should encapsulate some of the work in a separate function.

### Assignment

Use `<-`, not `=`, for assignment.

    # Good
    x <- 5
    # Bad
    x = 5

## Organisation

### Commenting guidelines

Comment your code. Entire commented lines should begin with `#` and one space. Comments should explain the why, not the what.

Use commented lines of `-` and `=` to break up your files into scannable chunks.

 [1]: http://google-styleguide.googlecode.com/svn/trunk/google-r-style.html