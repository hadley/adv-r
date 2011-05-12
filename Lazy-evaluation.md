# Laziness

R has a number of features designed to help you do as little work as possible. These are collectively known as lazy loading tools, and allow you to put off doing work as long as possible (so hopefully you never have to do it). You are probably familiar with lazy function arguments, but there are a few other ways you can make operations lazy by hand.

To demonstrate the use of `delayedAssign` we're going to create a caching function that saves the results of an expensive operation to disk, and then we you next load it, it lazy loads the objects - this means if we cached something you didn't need, we only pay a small disk usage penalty, we don't use up any data in R.

Challenge: if we do it one file per object, how do we know whether the cache has been run before or not?



Should print message when loading from cache. Can we make caching robust enough that some objects can be retrieved from disk and some can be computed afresh?


