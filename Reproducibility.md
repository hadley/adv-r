# How to write a reproducible example.

You are most likely to get good help with your R problem if you provide a reproducible example. A reproducible example allows someone else to recreate your problem by just copying and pasting R code. 

There are four things you need to include to make your example reproducible: required packages, data, code, and a description of your R environment.

* **Packages** should be loaded at the top of the script, so it's easy to
 see which ones the example needs.

* The easiest way to include **data** in an email is to use dput() to generate
  the R code to recreate it. For example, to recreate the mtcars dataset in R,
  I'd perform the following steps:

   1. Run `dput(mtcars)` in R
   2. Copy the output
   3. In my reproducible script, type `mtcars <- ` then paste.

* Spend a little bit of time ensuring that your **code** is easy for others to
  read:

  * make sure you've used spaces and your variable names are concise, but
    informative

  * use comments to indicate where your problem lies

  * do your best to remove everything that is not related to the problem.  
   The shorter your code is, the easier it is to understand.

* Include the output of sessionInfo() as a comment. This summarises your **R
  environment** and makes it easy to check if you're using an out-of-date
  package.

You can check you have actually made a reproducible example by starting up a fresh R session and pasting your script in.  

Before putting all of your code in an email, consider putting it on http://gist.github.com/.  It will give your code nice syntax highlighting, and you don't have to worry about anything getting mangled by the email system.
