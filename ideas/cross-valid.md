* In the following example, we're going to use cross-validation to select the best value of the loess `span` parameter. 
    
    We'll start by setting up some sample data and plotting it.  Our aim is to fit a smooth curve through the noisy data that does the best job of reproducing the original data.

    ```R
    x <- seq(0, pi / 2, length = 100)
    y <- sin(x) + rt(length(x), df = 5) / 5

    plot(x, y)
    lines(x, sin(x), col = "grey50")
    ```

    Next we'll perform a 

    ```R

    select_fold <- function(x, keep = 0.1) {

    }

    ```