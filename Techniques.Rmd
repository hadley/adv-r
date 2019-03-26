# (PART) Techniques {-}

# Introduction {#techniques .unnumbered}

The final four chapters cover two general programming techniques: finding and fixing bugs, and finding and fixing performance issues. Tools to measure and improve performance are particularly important because R is not a fast language. This is not an accident: R was purposely designed to make interactive data analysis easier for humans, not to make computers as fast as possible. While R is slow compared to other programming languages, for most purposes, it's fast enough. These chapters help you handle the cases where R is no longer fast enough, either by improving the performance of your R code, or by switching to a language, C++, that is designed for performance.

1.  Chapter \@ref(debugging) talks about debugging, because finding the root cause of
error can be extremely frustrating. Fortunately R has some great tools for debugging, and when they're coupled with a solid strategy, you should be able to find the root cause for most problems rapidly and relatively painlessly.

1.  Chapter \@ref(perf-measure) focuses on measuring performance. 

1.  Chapter \@ref(perf-improve) then shows how to improve performance.

