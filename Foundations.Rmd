# (PART) Foundations {-}

# Introduction {#foundations-intro  .unnumbered}

To start your journey in mastering R, the following six chapters will help you learn the foundational components of R. I expect that you've already seen many of these pieces before, but you probably have not studied them deeply. To help check your existing knowledge, each chapter starts with a quiz; if you get all the questions right, feel free to skip to the next chapter!

1.  In Chapter \@ref(names-values), you'll learn about an important distinction
    that you probably haven't thought deeply about: the difference between an 
    object and its name. Improving your mental model here will help you make 
    better predictions about when R copies data and hence which basic 
    operations are cheap and which are expensive.
   
1.  You use vectors every day in R, so Chapter \@ref(vectors-chap) will dive 
    into the details, helping you learn how the different types of vector fit 
    together. You'll also learn about attributes, which allow you to store 
    arbitrary metadata, and form the basis for two of R's object oriented 
    programming toolkits.
    
1.  To write clear, concise, and efficient R code it is important to fully 
    appreciate the power of subsetting with as described in Chapter 
    \@ref(subsetting). Understanding the fundamental components will allow you 
    to solve new problems by combining the building blocks in novel ways.

1.  The tools of control flow allow you to only execute code under certain
    conditions, or to repeatedly execute code with changing inputs. In Chapter
    \@ref(control-flow), you'll learn the important `if` and `for` constructs,
    as well as related tools like `switch()` and `while`.

1.  Functions are the most important building block of R code, and in Chapter
    \@ref(functions), you'll learn exactly how they work, including the 
    scoping rules, which govern how R looks up values from names. You'll also 
    learn more of the details behind lazy evaluation, and how you can 
    control what happens when you exit a function.
    
1.  In Chapter \@ref(environments), you'll learn about a data structure that
    is crucial for understanding how R works, but quite unimportant for data 
    analysis: the environment. Environments are the data structure that binds 
    names to values, and they power important tools like package namespaces. 
    Unlike most programming languages, environments in R are "first class" 
    which means that you can manipulate them just like other objects.

1.  Chapter \@ref(conditions) concludes the foundations of R with an 
    exploration of "conditions", the umbrella term used to describe errors, 
    warnings, and messages. You've certainly encountered these before, so in 
    this chapter you learn how to signal them appropriately in your own 
    functions, and how to handle them when signalled elsewhere.
