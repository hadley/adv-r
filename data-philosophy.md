# A philosophy of clean data

This paper defines clean data, and shows how clean data is easier to work with for modelling, transformation and visualisation. A good definition of clean data also makes dirty data easier to work with by showing exactly why it feels dirty and how it can be cleaned up.

My principles of clean data are inspired by databases and Codd's relational algebra, but the set algebra that powers SQL and relational databases is not good a good fit for most statistical problems. 

My definition of clean data is not exhaustive, and it focusses on the type of data that statisticians most commonly encounter: rectangular data defined by rows and columns. It is not a good fit for data on networks, ..., or ... Additional, because the focus of this definition is on explicit definition of the data, it may not be suitable for very large datasets - these may require special infrastructure for needed performance.

Defining clean data is important because getting data into the right form for analysis is very important, but there are few existing resources that rigorously define what clean data is and how to clean dirty data.  This paper will make: 

* It easier for data applied scientists Hopefully it will help guide the collection and storage of data, and

* Data cleaning easier to teach by providing a firm theoretical foundation.

* Real world data analysis easier because you can focus on the problem you are trying to solve, instead of data wrangling. 

The paper is divided into three sections:

* The definition of clean data: rectangular data with variables in columns and observations in rows. Data about each class of entity is stored in a single file.

* Cleaning dirty data: most real world data is not clean, and in this section what operations are needed to make messy data clean. These techniques will be illustrated by some of the messy datasets I've encountered in the course of an analysis.

* Working with clean data: I'll show how clean data is easy to model, transform and visualise, and how right data format plus the right tools makes previously difficult problems easy.  The right tools take clean data as input and return clean data as output, ensuring that data stays clean throughout the entire analysis process.

The examples will use R, because that is where I have developed the computational tools to support this philosophy of data, but I believe the principles apply to any programming language which deals with data. In R, the plyr and ggplot2 packages work well with clean data, and the reshape package provides tools useful for making dirty data clean. The principles of clean data will also help us critique existing R functions, and I will highlight some R functions that cause unnecessary work for the analyst.

# Defining clean data

"Happy families are all alike; every unhappy family is unhappy in its own way." ---Leo Tolstoy

"Clean datasets are all alike; every messy dataset is messy in its own way." ---Hadley Wickham

Statistical data usually comes in a rectangular format, made up of rows and columns. It is usually labelled with column names, and sometimes with row names. Such data is a collection of __value__s, each either a single number (if quantitative) or a single string (if qualitative). Multiple measurements made on the same __experimental unit__ form an __observation__. 

The following table shows a common data format.  What are the values and variables in this data set?  There are three variables: sex, pregnancy status and a count.

             | Pregnant  Not-Pregnant
      -------+-----------------------
      Male   |        0             5
      Female |        1             4

Data is messy or clean depending on how these structures are arranged. In clean, __long form__ data, these structures are arranged in a particular format: each variable lies in a column, and the values are organised in rows by observation. The following table shows how we'd represent the data above in long form:

      pregnant  sex    | n
      -----------------+-
      No        Female | 4
      No        Male   | 5
      Yes       Female | 1
      Yes       Male   | 0

While order of variables and observations does not affect analysis, a good ordering makes it easier to scan the raw data. Variables can be ordered by grouping them into identifier and measured variables. Identifier variables describe the experimental design and are known in advance (in a sense they're not really measurements). Measured variables are what we actually measure in the study. Identifier variables should come first first, ordered in terms of their natural hierarchy if present, otherwise alphabetically. Measured variables come next, ordered alphabetically. Rows can then be ordered so that the first id variable varies slowest, followed by the second, and so on.

# Cleaning dirty data

Dirty data can be dirty in any number of ways - it just needs to violate the restriction of variables in columns and observations in rows. Real data violates these restrictions in almost every way imaginable. In this section, I will focus on some of the most common problems, illustrated with specific datasets that I have worked with:

* column headers are values, not variable names (pew religion, billboard)
* multiple variables are stored in one column (tb)
* variables are stored in both rows and columns (weather)

Messy data, including types of messiness not explicitly described above, can be cleaned in a surprisingly small set of tools: melting, string splitting, and less often cast. The following sections discuss each type of problem in turn, introducing the tools needed to clean it.

## Column headers are values, not variables names

A common case of messy data is tabular data designed for presentation, where variables form both the rows and columns, and column headers are values, not variable names. While I call this type of data dirty, in some cases it can be extremely useful. It provides efficient storage for completely crossed designs, and it can provide extremely efficient computation if desired operations can be expressed as matrix operations. But it doesn't generalise well, requiring extensions into higher dimensions to deal with more variables, and can be very inefficient if there are a lot of missing values or variables are nested, not crossed. This makes it inappropriate as a general storage format.

Another common use of this data is for recording regularly spaced observations over time. For example, the billboard dataset records the date a song first entered the billboard top 100. To record its ranking in the following weeks, 75 variables, from week1 to week75, are needed.  This form of storage is useful for data entry because it reduces duplication - otherwise each song in each week would need its own row.

This type of data is so common that in R a number of graphical tools have been designed specifically to visualise it, e.g. `barplot`, `matplot`, `dotchart`, `mosaicplot`. Other tools are designed to provide common manipulations like `sweep`, `prop.table` and `margin.table`. Other tools can produce this type of output from formerly clean data: `table`, `xtabs`, `tapply`.

To clean up this type of data we need to melt, or stack it, turning columns into rows. Melting is parameterised by a list of variables to keep in columns (cvars), or equivalently a list of columns that should be turned into rows (rvars). It works by adding a new indicator variable to the dataset and stacking the repeated cvars.

## Multiple variables stored in one column

After melting, it often happens that the indicator variable actually records information about more than on variable. This is illustrated by the tb dataset - each column represents a subset conditioned on two variables: age and sex.  

    Original tb

After melting the data to combine variables spread across columns, we get

    Molten tb

Typically, column headers in this format are separated by some character (e.g. `.`, `-`, `_`, `:`) and we can simply split the string up based on that character.  In other cases, such as for this tb data, more careful string processing is required, or the variable names can be matched to a hand made table that converts compound values to multiple variables.

Doing this for the tb data yields:

    Clean tb

## Variables are stored in both rows and columns

The most complicated form of dirty data is when variables have been stored in both rows and columns. The weather data below has variables in single columns (id, year, month), spread across columns (day) and in rows (TMIN, TMAX).  

      Original weather data 

Using the methods above gets us to the following:

      Molten weather data
      
Which is mostly clean, but we have one variable stored in rows: observation type.  Fixing this requires the cast operation, which performs the inverse of melting, and rotates the `obs` variable back out into the columns to get:

      Clean weather data

# Working with clean data

Clean data is only worthwhile in so much as it makes the rest of the analysis easier. This section discusses general tools for working with clean data, divided into three sections.  

## Reformulation

mutate, summarise (+ colwise), arrange and subset.
group by
join

Specialised operators for speed: e.g. count. These need to return data in long form, so that they can easily be combined with the unaggregated data with join. The table function in base R does not do this - it returns a vector/matrix/array with names. This is problematic because it forces crossing of variables, so all combinations must be counted (many 0 zeros for combinations that don't exist in data), and it's difficult to combine back with the original data.

These ideas have developed iteratively - as my understanding of clean data improved, so to did these tools, which made me realise understand better what tools clean data needs.

## Modelling

<!-- Email r-sig-mixed-models -->

Modelling is the inspiration that has driven most of this work. Every statistical language has a way of describing a model as a connection between different variables:

* R:
* SAS:
* SPSS:

Some have also tried to adapt these methods for other wide data. Repeated measures in SAS.

## Visualisation

Lattice graphics tries to stick too closely to the modelling structure.

ggplot2: map variables to different 

# Conclusion``
