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

* Working with clean data: I'll show how clean data is easy to model, transform and visualise, and how right data format plus the right tools makes previously difficult problems easy.  The right tools take clean data as input and return clean data as output, ensuring that data stays clean throughout the entire analysis process.

* Cleaning dirty data: most real world data is not clean, and in this section what operations are needed to make messy data clean. These techniques will be illustrated by some of the messy datasets I've encountered in the course of an analysis.

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

The complement of long data is __wide__, or messy, data. Messy data can be messy in any number of ways - it just needs to somehow violate the restriction of variables in columns and observations in rows. The real data violates these restrictions in almost every way imaginable. In this section, I will focus on some of the most common problems, illustrated with specific datasets that I have worked with:

* column headers are values, not variable names (pew religion)
* one variable is spread over multiple columns (billboard)
* variables are stored in both rows and columns (weather)
* multiple variables are stored in one column (tb)

Messy data, including types of messiness not explicitly described above, can be cleaned in a surprisingly small set of tools: stacking, unstacking, and string splitting. 

# Working with clean data

## Reformulation

mutate, summarise (+ colwise), arrange and subset.
group by
join

Specialised operators for speed: e.g. count. These need to return data in long form, so that they can easily be combined with the unaggregated data with join. The table function in base R does not do this - it returns a vector/matrix/array with names. This is problematic because it forces crossing of variables, so all combinations must be counted (many 0 zeros for combinations that don't exist in data), and it's difficult to combine back with the original data.

## Modelling

Modelling is the inspiration that has driven most of this work. Every statistical language has a way of describing a model as a connection between different variables:

* R:
* SAS:
* SPSS:

Some have also tried to adapt these methods for other wide data. Repeated measures in SAS.

## Visualisation

Lattice graphics tries to stick too closely to the modelling structure.

ggplot2: map variables to different 

