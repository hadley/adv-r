# (PART) Foundations {-}

# Introduction {#foundations-intro  .unnumbered}

To start your journey in mastering R, the following six chapters will help you learn the foundational components of R. I expect that you've already seen many of these pieces before, but you probably have not studied them deeply. To help check your existing knowledge, each chapter starts with a quiz; if you get all the questions right, feel free to skip to the next chapter!

1.  Chapter \@ref(names-values) teaches you about an important distinction
    that you probably haven't thought deeply about: the difference between an 
    object and its name. Improving your mental model here will help you make 
    better predictions about when R copies data and hence which basic 
    operations are cheap and which are expensive.
   
1.  Chapter \@ref(vectors-chap) dives into the details of vectors, helping you 
    learn how the different types of vector fit 
    together. You'll also learn about attributes, which allow you to store 
    arbitrary metadata, and form the basis for two of R's object-oriented 
    programming toolkits.
    
1.  Chapter \@ref(subsetting) describes how to use subsetting to write 
    clear, concise, and efficient R code. Understanding the fundamental 
    components will allow you to solve new problems by combining the building 
    blocks in novel ways.

1.  Chapter \@ref(control-flow) presents tools of control flow that allow you to
    only execute code under certain conditions, or to repeatedly execute code 
    with changing inputs. These include the important `if` and `for` constructs, as well as 
    related tools like `switch()` and `while`.

1.  Chapter \@ref(functions) deals with functions, the most important building 
    blocks of R code. You'll learn exactly how they work, including the 
    scoping rules, which govern how R looks up values from names. You'll also 
    learn more of the details behind lazy evaluation, and how you can 
    control what happens when you exit a function.
    
1.  Chapter \@ref(environments) describes a data structure that is crucial for 
    understanding how R works, but quite unimportant for data analysis: the 
    environment. Environments are the data structure that binds 
    names to values, and they power important tools like package namespaces. 
    Unlike most programming languages, environments in R are "first class" 
    which means that you can manipulate them just like other objects.

1.  Chapter \@ref(conditions) concludes the foundations of R with an 
    exploration of "conditions", the umbrella term used to describe errors, 
    warnings, and messages. You've certainly encountered these before, so in 
    this chapter you learn how to signal them appropriately in your own 
    functions, and how to handle them when signalled elsewhere.
