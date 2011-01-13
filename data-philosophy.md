# A philosophy of clean data

This paper provides a definition of clean data, and a justification as why it is important in terms of the common operations of data analysis, reformation, visualisation and modelling. Hopefully it will help guide the collection and storage of data, and make it easy to teach this important foundation of statistics. I will also provide examples of many datasets in the wild that violate these constraints, and show steps to convert them to clean data.

Once have clean data in long format, and a set of tools that keeps it in that format, you can focus on the problem you are trying to solve, rather than on further data wrangling. 

This framework is not comprehensive: there are many special cases in which it will not apply. For example, multivariate statistics are better suited to thinking about the data as a mathematical matrix. Very large data has other special requirements for efficiency (both time and space), and for the purposes of this paper, this means data that take up gigabytes, rather than megabytes. My expectation is that this philosophy covers the most common 90% of data analyses.

I will focus on R, because that is where I have developed the computational tools to support this philosophy of data, but I believe the principles apply to any programming language which deals with data. My principles of clean data are partly inspired by relational data and normalised form, but the tools of SQL are not the tools of statistics. I will also provide examples of functions in R that don't work well with this type of data, and hopefully explain why some tasks seem so hard to do.

In R, the plyr, reshape2 and ggplot2 packages have been written in light of this philosophy and naturally fit together. These tools can be used in other ways, for other purposes, here I focus only on their use for manipulating data for analysis, not presentation or communication. The majority of modelling families also work this way. 

<!-- Principles:

  * it's better to be explicit than implicit
    * explicit variables not row names
    * do data transformation yourself
  * don't worry about efficiency (speed or time) unless it actually matters
  * consistency
 -->

## Data formats

"Happy families are all alike; every unhappy family is unhappy in its own way." ---Leo Tolstoy

"Clean datasets are all alike; every messy dataset is messy in its own way." ---Hadley Wickham

Statistical data usually comes in a rectangular format, made up of rows and columns. Such data is made up of values, each which belong to a variable, and describe something about a class of entities. A variable is a homogenous collection of values. In clean data, these structures are arranged in a particular format: each type of entity has its own table, each variable lives in a column, and the values are stored in rows corresponding for each observation. The first row of the data, lists the variable name, and the file name normally provides information about the class.

I call this form of data long data.  Other useful descriptions are molten data and wide data. To get data from wide form to long form, it's typically easiest to go through an intermediate form I call molten form, where we have single column of values, identified by other variables (useful intermediate form). The reshape package provides tools to do these sorts of reshaping operations in R.

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

# Use

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

