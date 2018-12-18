# (PART) Techniques {-}

# Introduction {.unnumbered}

This book concludes with four chapters on general R programming techniques. Finding the source of errors can be frustrating, but a good general strategy can make a big difference. In Chapter \@ref(debugging) you'll learn techniques and tools that help you find the root cause of errors. 

The remaining three chapters focus on performance, first measuring it (Chapter \@ref(perf-measure)) and then improving it (Chapters \@ref(perf-improve) and \@ref(rcpp)). This is important because R is not a fast language. This is not an accident. R was purposely designed to make data analysis and statistics easier for you to do. It was not designed to make life easier for your computer. While R is slow compared to other programming languages, for most purposes, it's fast enough. If you'd like to learn more about the performance characteristics of the R language and how they affect real code, I highly recommend "Evaluating the Design of the R Language" [@r-design]. It draws conclusions by combining a modified R interpreter with a wide set of code found in the wild.
