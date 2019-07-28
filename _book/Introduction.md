\mainmatter



# Introduction

I have now been programming in R for over 15 years, and have been doing it full-time for the last five years. This has given me the luxury of time to examine how the language works. This book is my attempt to pass on what I've learned so that you can understand the intricacies of R as quickly and painlessly as possible. Reading it will help you avoid the mistakes I've made and dead ends I've gone down, and will teach you useful tools, techniques, and idioms that can help you to attack many types of problems. In the process, I hope to show that, despite its sometimes frustrating quirks, R is, at its heart, an elegant and beautiful language, well tailored for data science.

## Why R?

If you are new to R, you might wonder what makes learning such a quirky language worthwhile. To me, some of the best features are:

* It's free, open source, and available on every major platform. As a result, if 
  you do your analysis in R, anyone can easily replicate it, regardless of 
  where they live or how much money they earn.

* R has a diverse and welcoming community, both online (e.g. 
  [the #rstats twitter community][rstats-twitter]) and in person (like the 
  [many R meetups][r-meetups]). Two particularly inspiring community groups are
  [rweekly newsletter][rweekly] which makes it easy to keep up to date with
  R, and [R-Ladies][r-ladies] which has made a wonderfully welcoming community
  for women and other minority genders.
  
* A massive set of packages for statistical modelling, machine learning,
  visualisation, and importing and manipulating data. Whatever model or
  graphic you're trying to do, chances are that someone has already tried
  to do it and you can learn from their efforts.

* Powerful tools for communicating your results. [RMarkdown][rmarkdown] makes
  it easy to turn your results into HTML files, PDFs, Word documents,
  PowerPoint presentations, dashboards and more. [Shiny][shiny] allows you to
  make beautiful interactive apps without any knowledge of HTML or javascript.

* RStudio, [the IDE](http://www.rstudio.com/ide/), provides an integrated
  development environment, tailored to the needs of data science, interactive 
  data analysis, and statistical programming.

* Cutting edge tools. Researchers in statistics and machine learning will often
  publish an R package to accompany their articles. This means immediate
  access to the very latest statistical techniques and implementations.

* Deep-seated language support for data analysis. This includes features
  like missing values, data frames, and vectorisation.

* A strong foundation of functional programming. The ideas of functional
  programming are well suited to the challenges of data science, and the 
  R language is functional at heart, and provides many primitives needed
  for effective functional programming.
  
* RStudio, [the company](https://www.rstudio.com), which makes money by 
  selling professional products to teams of R users, and turns around and 
  invests much of that money back into the open source community (over 50%
  of software engineers at RStudio work on open source projects). I work for 
  RStudio because I fundamentally believe in its mission.
  
* Powerful metaprogramming facilities. R's metaprogramming capabilities allow 
  you to write magically succinct and concise functions and provide an excellent 
  environment for designing domain-specific languages like ggplot2, dplyr,
  data.table, and more.

* The ease with which R can connect to high-performance programming languages 
  like C, Fortran, and C++.

Of course, R is not perfect. R's biggest challenge (and opportunity!) is that most R users are not programmers. This means that:

* Much of the R code you'll see in the wild is written in haste to solve
  a pressing problem. As a result, code is not very elegant, fast, or easy to
  understand. Most users do not revise their code to address these shortcomings.

* Compared to other programming languages, the R community is more focussed on 
  results than processes. Knowledge of software engineering best practices is 
  patchy. For example, not enough R programmers use source code control or
  automated testing.

* Metaprogramming is a double-edged sword. Too many R functions use
  tricks to reduce the amount of typing at the cost of making code that
  is hard to understand and that can fail in unexpected ways.

* Inconsistency is rife across contributed packages, and even within base R.
  You are confronted with over 25 years of evolution every time you use R,
  and this can make learning R tough because there are so many special cases to 
  remember.

* R is not a particularly fast programming language, and poorly written R code
  can be terribly slow. R is also a profligate user of memory. 

Personally, I think these challenges create a great opportunity for experienced programmers to have a profound positive impact on R and the R community. R users do care about writing high quality code, particularly for reproducible research, but they don't yet have the skills to do so. I hope this book will not only help more R users to become R programmers, but also encourage programmers from other languages to contribute to R.

## Who should read this book {#who-should-read}

This book is aimed at two complementary audiences:

* Intermediate R programmers who want to dive deeper into R, understand how
  the language works, and learn new strategies for solving diverse problems.

* Programmers from other languages who are learning R and want to understand
  why R works the way it does.

To get the most out of this book, you'll need to have written a decent amount of code in R or another programming language. You should be familiar with the basics of data analysis (i.e. data import, manipulation, and visualisation), have written a number of functions, and be familiar with the installation and use of CRAN packages.

This book walks the narrow line between being a reference book (primarily used for lookup), and being linearly readable. This involves some tradeoffs, because it's difficult to linearise material while still keeping related materials together, and some concepts are much easier to explain if you're already familiar with specific technical vocabulary. I've tried to use footnotes and cross-references to make sure you can still make sense even if you just dip your toes in a chapter.  

## What you will get out of this book {#what-you-will-get}

This book delivers the knowledge that I think an advanced R programmer should possess: a deep understanding of the fundamentals coupled with a broad vocabulary that means that you can tactically learn more about a topic when needed.

After reading this book, you will:

* Be familiar with the foundations of R. You will understand complex data types
  and the best ways to perform operations on them. You will have a deep
  understanding of how functions work, you'll know what environments are, and 
  how to make use of the condition system.

* Understand what functional programming means, and why it is a useful tool for
  data science. You'll be able to quickly learn how to use existing tools, and
  have the knowledge to create your own functional tools when needed.

* Know about R's rich variety of object-oriented systems. You'll be most 
  familiar with S3, but you'll know of S4 and R6 and where to look for more
  information when needed.

* Appreciate the double-edged sword of metaprogramming. You'll be able to
  create functions that use tidy evaluation, saving typing and creating elegant 
  code to express important operations. You'll also understand the dangers 
  and when to avoid it.

* Have a good intuition for which operations in R are slow or use a lot of
  memory. You'll know how to use profiling to pinpoint performance
  bottlenecks, and you'll know enough C++ to convert slow R functions to
  fast C++ equivalents.

## What you will not learn

This book is about R the programming language, not R the data analysis tool. If you are looking to improve your data science skills, I instead recommend that you learn about the [tidyverse](https://www.tidyverse.org/), a collection of consistent packages developed by me and my colleagues. In this book you'll learn the techniques used to develop the tidyverse packages; if you want to instead learn how to use them, I recommend ["R for Data Science"](http://r4ds.had.co.nz/).

If you want to share your R code with others, you will need to make an R package. This allows you to bundle code along with documentation and unit tests, and easily distribute it via CRAN. In my opinion, the easiest way to develop packages is with [devtools](http://devtools.r-lib.org), [roxygen2](http://klutometis.github.io/roxygen/), [testthat](http://testthat.r-lib.org), and [usethis](http://usethis.r-lib.org). You can learn about using these packages to make your own package in ["R packages"](http://r-pkgs.had.co.nz/).

## Meta-techniques {#meta-techniques}

There are two meta-techniques that are tremendously helpful for improving your skills as an R programmer: reading source code and adopting a scientific mindset.

Reading source code is important because it will help you write better code. A great place to start developing this skill is to look at the source code of the functions and packages you use most often. You'll find things that are worth emulating in your own code and you'll develop a sense of taste for what makes good R code. You will also see things that you don't like, either because its virtues are not obvious or it offends your sensibilities. Such code is nonetheless valuable, because it helps make concrete your opinions on good and bad code.

A scientific mindset is extremely helpful when learning R. If you don't understand how something works, develop a hypothesis, design some experiments, run them, and record the results. This exercise is extremely useful since if you can't figure something out and need to get help, you can easily show others what you tried. Also, when you learn the right answer, you'll be mentally prepared to update your world view.

## Recommended reading {#recommended-reading}

Because the R community mostly consists of data scientists, not computer scientists, there are relatively few books that go deep in the technical underpinnings of R. In my personal journey to understand R, I've found it particularly helpful to use resources from other programming languages. R has aspects of both functional and object-oriented (OO) programming languages. Learning how these concepts are expressed in R will help you leverage your existing knowledge of other programming languages, and will help you identify areas where you can improve.

To understand why R's object systems work the way they do, I found "The Structure and Interpretation of Computer Programs"[^SICP] [@SICP] (SICP) to be particularly helpful. It's a concise but deep book, and after reading it, I felt for the first time that I could actually design my own object-oriented system. The book was my first introduction to the encapsulated paradigm of object-oriented programming found in R, and it helped me understand the strengths and weaknesses of this system. SICP also teaches the functional mindset where you create functions that are simple individually, and which become powerful when composed together.

[^SICP]: You can read it online for free at <https://mitpress.mit.edu/sites/default/files/sicp/full-text/book/book.html>

To understand the trade-offs that R has made compared to other programming languages, I found "Concepts, Techniques and Models of Computer Programming" [@ctmcp] extremely helpful. It helped me understand that R's copy-on-modify semantics make it substantially easier to reason about code, and that while its current implementation is not particularly efficient, it is a solvable problem.

If you want to learn to be a better programmer, there's no place better to turn than "The Pragmatic Programmer" [@pragprog]. This book is language agnostic, and provides great advice for how to be a better programmer.

## Getting help {#getting-help}
\index{help}
\index{reprex}

Currently, there are three main venues to get help when you're stuck and can't figure out what's causing the problem: [RStudio Community](https://community.rstudio.com/), [StackOverflow](http://stackoverflow.com) and the [R-help mailing list][r-help]. You can get fantastic help in each venue, but they do have their own cultures and expectations. It's usually a good idea to spend a little time lurking, learning about community expectations, before you put up your first post. 

Some good general advice:

* Make sure you have the latest version of R and of the package (or packages)
  you are having problems with. It may be that your problem is the result of
  a recently fixed bug.

* Spend some time creating a **repr**oducible **ex**ample, or reprex.
  This will help others help you, and often leads to a solution without
  asking others, because in the course of making the problem reproducible you 
  often figure out the root cause. I highly recommend learning and using
  the [reprex](https://reprex.tidyverse.org/) package.

<!-- GVW: is someone going to go through once you're done and create a glossary? If you've flagged things like "reprex" in bold, it ought to be easy to find terms. -->

## Acknowledgments {#intro-ack}

I would like to thank the many contributors to R-devel and R-help and, more recently, Stack Overflow and RStudio Community. There are too many to name individually, but I'd particularly like to thank Luke Tierney, John Chambers, JJ Allaire, and Brian Ripley for generously giving their time and correcting my countless misunderstandings.

This book was [written in the open](https://github.com/hadley/adv-r/), and chapters were advertised on [twitter](https://twitter.com/hadleywickham) when complete. It is truly a community effort: many people read drafts, fixed typos, suggested improvements, and contributed content. Without those contributors, the book wouldn't be nearly as good as it is, and I'm deeply grateful for their help. Special thanks go to Jeff Hammerbacher,  Peter Li, Duncan Murdoch, and Greg Wilson, who all read the book from cover-to-cover and provided many fixes and suggestions.



A big thank you to all 379 contributors (in alphabetical order by username): Aaron Wolen (\@aaronwolen), \@absolutelyNoWarranty, Adam Hunt (\@adamphunt), \@agrabovsky, Alexander Grueneberg (\@agrueneberg), Anthony Damico (\@ajdamico), James Manton (\@ajdm), Aaron Schumacher (\@ajschumacher), Alan Dipert (\@alandipert), Alex Brown (\@alexbbrown), \@alexperrone, Alex Whitworth (\@alexWhitworth), Alexandros Kokkalis (\@alko989), \@amarchin, Amelia McNamara (\@AmeliaMN), Bryce Mecum (\@amoeba), Andrew Laucius (\@andrewla), Andrew Bray (\@andrewpbray), Andrie de Vries (\@andrie), Angela Li (\@angela-li), \@aranlunzer, Ari Lamstein (\@arilamstein), \@asnr, Andy Teucher (\@ateucher), Albert Vilella (\@avilella), baptiste (\@baptiste), Brian G. Barkley (\@BarkleyBG), Mara Averick (\@batpigandme), Byron (\@bcjaeger), Brandon Greenwell (\@bgreenwell), Brandon Hurr (\@bhive01), Jason Knight (\@binarybana), Brett Klamer (\@bklamer), Jesse Anderson (\@blindjesse), Brian Mayer (\@blmayer), Benjamin L. Moore (\@blmoore), Brian Diggs (\@BrianDiggs), Brian S. Yandell (\@byandell), \@carey1024, Chip Hogg (\@chiphogg), Chris Muir (\@ChrisMuir), Christopher Gandrud (\@christophergandrud), Clay Ford (\@clayford), Colin Fay (\@ColinFay), \@cortinah, Cameron Plouffe (\@cplouffe), Carson Sievert (\@cpsievert), Craig Citro (\@craigcitro), Craig Grabowski (\@craiggrabowski), Christopher Roach (\@croach), Peter Meilstrup (\@crowding), Crt Ahlin (\@crtahlin), Carlos Scheidegger (\@cscheid), Colin Gillespie (\@csgillespie), Christopher Brown (\@ctbrown), Davor Cubranic (\@cubranic), Darren Cusanovich (\@cusanovich), Christian G. Warden (\@cwarden), Charlotte Wickham (\@cwickham), Dean Attali (\@daattali), Dan Sullivan (\@dan87134), Daniel Barnett (\@daniel-barnett), Daniel (\@danielruc91), Kenny Darrell (\@darrkj), Tracy Nance (\@datapixie), Dave Childers (\@davechilders), David Rubinger (\@davidrubinger), David Chudzicki (\@dchudz), Deependra Dhakal (\@DeependraD), Daisuke ICHIKAWA (\@dichika), david kahle (\@dkahle), David LeBauer (\@dlebauer), David Schweizer (\@dlschweizer), David Montaner (\@dmontaner), \@dmurdoch, Zhuoer Dong (\@dongzhuoer), Doug Mitarotonda (\@dougmitarotonda), Dragoș Moldovan-Grünfeld (\@dragosmg), Jonathan Hill (\@Dripdrop12), \@drtjc, Julian During (\@duju211), \@duncanwadsworth, \@eaurele, Dirk Eddelbuettel (\@eddelbuettel), \@EdFineOKL, Eduard Szöcs (\@EDiLD), Edwin Thoen (\@EdwinTh), Ethan Heinzen (\@eheinzen), \@eijoac, Joel Schwartz (\@eipi10), Eric Ronald Legrand (\@elegrand), Ellis Valentiner (\@ellisvalentiner), Emil Hvitfeldt (\@EmilHvitfeldt), Emil Rehnberg (\@EmilRehnberg), Daniel Lee (\@erget), Eric C. Anderson (\@eriqande), Enrico Spinielli (\@espinielli), \@etb, David Hajage (\@eusebe), Fabian Scheipl (\@fabian-s), \@flammy0530, François Michonneau (\@fmichonneau), Francois Pepin (\@fpepin), Frank Farach (\@frankfarach), \@freezby, Frans van Dunné (\@FvD), \@fyears, \@gagnagaman, Garrett Grolemund (\@garrettgman), Gavin Simpson (\@gavinsimpson), Brooke Anderson (\@geanders), \@gezakiss7, \@gggtest, Gökçen Eraslan (\@gokceneraslan), Josh Goldberg (\@GoldbergData), Georg Russ (\@gr650), \@grasshoppermouse, Gregor Thomas (\@gregorp), Garrett See (\@gsee), Ari Friedman (\@gsk3), Gunnlaugur Thor Briem (\@gthb), Greg Wilson (\@gvwilson), Hamed (\@hamedbh), Jeff Hammerbacher (\@hammer), Harley Day (\@harleyday), \@hassaad85, \@helmingstay, Henning (\@henningsway), Henrik Bengtsson (\@HenrikBengtsson), Ching Boon (\@hoscb), \@hplieninger, Iain Dillingham (\@iaindillingham), \@IanKopacka, Ian Lyttle (\@ijlyttle), Ilan Man (\@ilanman), Imanuel Costigan (\@imanuelcostigan), Thomas Bürli (\@initdch), Os Keyes (\@Ironholds), \@irudnyts, i (\@isomorphisms), Irene Steves (\@isteves), Jan Gleixner (\@jan-glx), Jannes Muenchow (\@jannes-m), Jason Asher (\@jasonasher), Jason Davies (\@jasondavies), Chris (\@jastingo), jcborras (\@jcborras), John Blischak (\@jdblischak), \@jeharmse, Lukas Burk (\@jemus42), Jennifer (Jenny) Bryan (\@jennybc), Justin Jent (\@jentjr), Jeston (\@JestonBlu), Jim Hester (\@jimhester), \@JimInNashville, \@jimmyliu2017, Jim Vine (\@jimvine), Jinlong Yang (\@jinlong25), J.J. Allaire (\@jjallaire), \@JMHay, Jochen Van de Velde (\@jochenvdv), Johann Hibschman (\@johannh), John Baumgartner (\@johnbaums), John Horton (\@johnjosephhorton), \@johnthomas12, Jon Calder (\@jonmcalder), Jon Harmon (\@jonthegeek), Julia Gustavsen (\@jooolia), JorneBiccler (\@JorneBiccler), Jeffrey Arnold (\@jrnold), Joyce Robbins (\@jtr13), Juan Manuel Truppia (\@juancentro), \@juangomezduaso, Kevin Markham (\@justmarkham), john verzani (\@jverzani), Michael Kane (\@kaneplusplus), Bart Kastermans (\@kasterma), Kevin D'Auria (\@kdauria), Karandeep Singh (\@kdpsingh), Ken Williams (\@kenahoo), Kendon Bell (\@kendonB), Kent Johnson (\@kent37), Kevin Ushey (\@kevinushey), 电线杆 (\@kfeng123), Karl Forner (\@kforner), Kirill Sevastyanenko (\@kirillseva), Brian Knaus (\@knausb), Kirill Müller (\@krlmlr), Kriti Sen Sharma (\@ksens), Kai Tang (唐恺） (\@ktang), Kevin Wright (\@kwstat), suo.lawrence.liu@gmail.com (\@Lawrence-Liu), \@ldfmrails, Kevin Kainan Li (\@legendre6891), Rachel Severson (\@leighseverson), Laurent Gatto (\@lgatto), C. Jason Liang (\@liangcj), Steve Lianoglou (\@lianos), Likan (\@likanzhan), \@lindbrook, Lingbing Feng (\@Lingbing), Marcel Ramos (\@LiNk-NY), Zhongpeng Lin (\@linzhp), Lionel Henry (\@lionel-), Lluís (\@llrs), myq (\@lrcg), Luke W Johnston (\@lwjohnst86), Kevin Lynagh (\@lynaghk), \@MajoroMask, Malcolm Barrett (\@malcolmbarrett), \@mannyishere, \@mascaretti, Matt (\@mattbaggott), Matthew Grogan (\@mattgrogan), \@matthewhillary, Matthieu Gomez (\@matthieugomez), Matt Malin (\@mattmalin), Mauro Lepore (\@maurolepore), Max Ghenis (\@MaxGhenis), Maximilian Held (\@maxheld83), Michal Bojanowski (\@mbojan), Mark Rosenstein (\@mbrmbr), Michael Sumner (\@mdsumner), Jun Mei (\@meijun), merkliopas (\@merkliopas), mfrasco (\@mfrasco), Michael Bach (\@michaelbach), Michael Bishop (\@MichaelMBishop), Michael Buckley (\@michaelmikebuckley), Michael Quinn (\@michaelquinn32), \@miguelmorin, Michael (\@mikekaminsky), Mine Cetinkaya-Rundel (\@mine-cetinkaya-rundel), \@mjsduncan, Mamoun Benghezal (\@MoBeng), Matt Pettis (\@mpettis), Martin Morgan (\@mtmorgan), Guy Dawson (\@Mullefa), Nacho Caballero (\@nachocab), Natalya Rapstine (\@natalya-patrikeeva), Nick Carchedi (\@ncarchedi), Pascal Burkhard (\@Nenuial), Noah Greifer (\@ngreifer), Nicholas Vasile (\@nickv9), Nikos Ignatiadis (\@nignatiadis), Nina Munkholt Jakobsen (\@nmjakobsen), Xavier Laviron (\@norival), Nick Pullen (\@nstjhp), Oge Nnadi (\@ogennadi), Oliver Paisley (\@oliverpaisley), Pariksheet Nanda (\@omsai), Øystein Sørensen (\@osorensen), Paul (\@otepoti), Otho Mantegazza (\@othomantegazza), Dewey Dunnington (\@paleolimbot), Parker Abercrombie (\@parkerabercrombie), Patrick Hausmann (\@patperu), Patrick Miller (\@patr1ckm), Patrick Werkmeister (\@Patrick01), \@paulponcet, \@pdb61, Tom Crockett (\@pelotom), \@pengyu, Jeremiah (\@perryjer1), Peter Hickey (\@PeteHaitch), Phil Chalmers (\@philchalmers), Jose Antonio Magaña Mesa (\@picarus), Pierre Casadebaig (\@picasa), Antonio Piccolboni (\@piccolbo), Pierre Roudier (\@pierreroudier), Poor Yorick (\@pooryorick), Marie-Helene Burle (\@prosoitos), Peter Schulam (\@pschulam), John (\@quantbo), Quyu Kong (\@qykong), Ramiro Magno (\@ramiromagno), Ramnath Vaidyanathan (\@ramnathv), Kun Ren (\@renkun-ken), Richard Reeve (\@richardreeve), Richard Cotton (\@richierocks), Robert M Flight (\@rmflight), R. Mark Sharp (\@rmsharp), Robert Krzyzanowski (\@robertzk), \@robiRagan, Romain François (\@romainfrancois), Ross Holmberg (\@rossholmberg), Ricardo Pietrobon (\@rpietro), \@rrunner, Ryan Walker (\@rtwalker), \@rubenfcasal, Rob Weyant (\@rweyant), Rumen Zarev (\@rzarev), Nan Wang (\@sailingwave), Samuel Perreault (\@samperochkin), \@sbgraves237, Scott Kostyshak (\@scottkosty), Scott Leishman (\@scttl), Sean Hughes (\@seaaan), Sean Anderson (\@seananderson), Sean Carmody (\@seancarmody), Sebastian (\@sebastian-c), Matthew Sedaghatfar (\@sedaghatfar), \@see24, Sven E. Templer (\@setempler), \@sflippl, \@shabbybanks, Steven Pav (\@shabbychef), Shannon Rush (\@shannonrush), S'busiso Mkhondwane (\@sibusiso16), Sigfried Gold (\@Sigfried), Simon O'Hanlon (\@simonohanlon101), Simon Potter (\@sjp), Leo Razoumov (\@slonik-az), Richard M. Smith (\@Smudgerville), Steve (\@SplashDance), Scott Ritchie (\@sritchie73), Tim Cole (\@statist7), \@ste-fan, \@stephens999, Steve Walker (\@stevencarlislewalker), Stefan Widgren (\@stewid), Homer Strong (\@strongh), Dirk (\@surmann), Sebastien Vigneau (\@svigneau), Scott Warchal (\@Swarchal), Steven Nydick (\@swnydick), Taekyun Kim (\@taekyunk), Tal Galili (\@talgalili), \@Tazinho, Tyler Bradley (\@tbradley1013), Tom B (\@tbuckl), \@tdenes, \@thomasherbig, Thomas (\@thomaskern), Thomas Lin Pedersen (\@thomasp85), Thomas Zumbrunn (\@thomaszumbrunn), Tim Waterhouse (\@timwaterhouse), TJ Mahr (\@tjmahr), Thomas Nagler (\@tnagler), Anton Antonov (\@tonytonov), Ben Torvaney (\@Torvaney), Jeff Allen (\@trestletech), Tyler Rinker (\@trinker), Chitu Okoli (\@Tripartio), Kirill Tsukanov (\@tskir), Terence Teo (\@tteo), Tim Triche, Jr. (\@ttriche), \@tyhenkaline, Tyler Ritchie (\@tylerritchie), Tyler Littlefield (\@tyluRp), Varun Agrawal (\@varun729), Vijay Barve (\@vijaybarve), Victor (\@vkryukov), Vaidotas Zemlys-Balevičius (\@vzemlys), Winston Chang (\@wch), Linda Chin (\@wchi144), Welliton Souza (\@Welliton309), Gregg Whitworth (\@whitwort), Will Beasley (\@wibeasley), William R Bauer (\@WilCrofter), William Doane (\@WilDoane), Sean Wilkinson (\@wilkinson), Christof Winter (\@winterschlaefer), Jake Thompson (\@wjakethompson), Bill Carver (\@wmc3), Wolfgang Huber (\@wolfganghuber), Krishna Sankar (\@xsankar), Yihui Xie (\@yihui), yang (\@yiluheihei), Yoni Ben-Meshulam (\@yoni), \@yuchouchen, Yuqi Liao (\@yuqiliao), Hiroaki Yutani (\@yutannihilation), Zachary Foster (\@zachary-foster), \@zachcp, \@zackham, Sergio Oller (\@zeehio), Edward Cho (\@zerokarmaleft), Albert Zhao (\@zxzb).

## Conventions {#conventions}

Throughout this book I use `f()` to refer to functions, `g` to refer to variables and function parameters, and `h/` to paths. 

Larger code blocks intermingle input and output. Output is commented (`#>`) so that if you have an electronic version of the book, e.g., <https://adv-r.hadley.nz/>, you can easily copy and paste examples into R.

Many examples use random numbers. These are made reproducible by `set.seed(1014)`, which is executed automatically at the start of each chapter.

## Colophon {#colophon}

This book was written in [bookdown](http://bookdown.org/) inside [RStudio](http://www.rstudio.com/ide/). The [website](https://adv-r.hadley.nz/) is hosted with [netlify](http://netlify.com/), and automatically updated after every commit by [travis-ci](https://travis-ci.org/). The complete source is available from [GitHub](https://github.com/hadley/adv-r). Code in the printed book is set in [inconsolata](http://levien.com/type/myfonts/inconsolata.html). Emoji images in the printed book come from the open-licensed [Twitter Emoji](https://github.com/twitter/twemoji).

This version of the book was built with R version 3.5.3 (2019-03-11) and the following packages.


|package     |version    |source                              |
|:-----------|:----------|:-----------------------------------|
|bench       |1.0.1      |Github (r-lib/bench\@f7cd4d8)       |
|bookdown    |0.9        |CRAN (R 3.5.2)                      |
|dbplyr      |1.2.2      |CRAN (R 3.5.1)                      |
|desc        |1.2.0      |CRAN (R 3.5.0)                      |
|emo         |0.0.0.9000 |Github (hadley/emo\@02a5206)        |
|ggbeeswarm  |0.6.0      |CRAN (R 3.5.2)                      |
|ggplot2     |3.1.0.9000 |Github (tidyverse/ggplot2\@9eae13b) |
|knitr       |1.21       |CRAN (R 3.5.2)                      |
|lobstr      |1.0.1      |CRAN (R 3.5.2)                      |
|memoise     |1.1.0      |CRAN (R 3.5.0)                      |
|png         |0.1-7      |CRAN (R 3.5.1)                      |
|profvis     |0.3.5      |CRAN (R 3.5.0)                      |
|Rcpp        |1.0.0      |CRAN (R 3.5.1)                      |
|rlang       |0.3.1      |CRAN (R 3.5.2)                      |
|rmarkdown   |1.11       |CRAN (R 3.5.2)                      |
|RSQLite     |2.1.1      |CRAN (R 3.5.1)                      |
|scales      |1.0.0      |CRAN (R 3.5.1)                      |
|sessioninfo |1.1.1.9000 |Github (r-lib/sessioninfo\@ac8fcc1) |
|sloop       |1.0.1      |CRAN (R 3.5.2)                      |
|testthat    |2.0.1      |CRAN (R 3.5.1)                      |
|tidyr       |0.8.2      |CRAN (R 3.5.1)                      |
|vctrs       |0.1.0      |CRAN (R 3.5.2)                      |
|zeallot     |0.1.0      |CRAN (R 3.5.1)                      |



[r-help]: https://stat.ethz.ch/mailman/listinfo/r-help
[rstats-twitter]: https://twitter.com/search?q=%23rstats
[r-meetups]: https://www.meetup.com/topics/r-programming-language/
[rweekly]: https://rweekly.org
[r-ladies]: http://r-ladies.org
[rmarkdown]: https://rmarkdown.rstudio.com
[shiny]: http://shiny.rstudio.com
