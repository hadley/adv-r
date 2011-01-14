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

# Clean data

"Happy families are all alike; every unhappy family is unhappy in its own way." ---Leo Tolstoy

"Clean datasets are all alike; every messy dataset is messy in its own way." ---Hadley Wickham

Statistical data usually comes in a rectangular format, made up of rows and columns. Such data is made up of values, each which belong to a variable, and describe something about a class of entities. 

* A value is a single measurement, where continuous or discrete.

* A variable is a homogenous collection of values, multiple measurements of the same underlying property.

* An entity, or experimental unit, ...

Clean data is defined by how these structures are arranged. In clean data, these structures are arranged in a particular format: each type of entity has its own table, each variable lives in a column, and the values are stored in rows corresponding for each observation. The first row of the data, lists the variable name, and the file name normally provides information about the class.

I call this form of data long data.  Other useful descriptions are molten data and wide data. To get data from wide form to long form, it's typically easiest to go through an intermediate form I call molten form, where we have single column of values, identified by other variables (useful intermediate form). The reshape package provides tools to do these sorts of reshaping operations in R.

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

# Cleaning dirty data

Data in the wild violates these restrictions in almost every way imaginable, often because this form is not the most natural for data collection or recording. Here I want to focus on some of the most common problems, illustrated with specific datasets that I have worked with:

  * one variable is spread over multiple columns (billboard)
  * variables are placed in both rows and columns (weather, pew religion)
  * multiple variables are stored in one column (tb, renae)
  * columns represent values, not variables (tb, pew religion)

These wide range of problems can be resolved with a surprisingly small set of tools: melting, casting, and string manipulation/joining. (An algebra of data cleaning)

Dealing with problems related to entities:

* multiple classes are stored in the same file (billboard)
* data about a single class is spread over multiple files (simat2 weather)

only requires two more tools: the ability to combine multiple files into a single

Ordering: while order of variables and observations does not affect analysis, it can make it difficult to read the data. It's best to group variables into two sets: id and measured. ID variables describe the experimental design and are known in advance. ID variables can not contain missing values - that would indicate that we don't know what our experimental design is. Measured variables are (as the name suggested) those things that we don't know and must measure. The table should list ID variables first, ordered in terms of their natural hierarchy, or alphabetically if none present. Measured variables come next, ordered alphabetically. In user interfaces, id variables (or dimensions) should always be visible.  Rows should be ordered by the values of the id variable.
