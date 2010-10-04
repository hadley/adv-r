# A unified philosophy of data

This paper outlines a unified philosophy of data, a philosophy that helps to motivate an optimal form of data storage for data analysis.

Hopefully it will help guide the collection and storage of data, and make it easy to teach this important foundation of statistics.

It does not attempt to be completely comprehensive: there are many special cases in which it will not apply. For example, multivariate statistics are better suited to thinking about the data as a mathematical matrix. Very large data has other special requirements for efficiency (both time and space) (for the purposes of this paper, this means data that take up gigabytes, rather than megabytes). My expectation is that this philosophy covers the most common 90% of data analyses.

I call this is a unified philosophy of data because it covers the three most common types of operations in an analysis: reformation, visualisation and modelling.

I will use examples from R, because that is where I have developed the computational tools to support this philosophy of data, but I believe the principles apply to any programming language which deals with data. These principles are a particularly good fit to SQL, although the types of processing (set based) easy in SQL, are not always the operations that are most useful for statistics. Many of the tools from R that I discuss can be used in other ways for other purposes, here I focus only on their use for manipulating data for analysis (not, e.g. presentation/communication/display).

In R, the plyr, reshape2 and ggplot2 packages have been written in light of this philosophy and naturally fit together. The majority of modelling families also work this way. Allows to focus on the problems you are trying to solve, not on data wrangling. (May not be perfect for every situation, but should save enough time to be worth the investment in learning)

Principles:

  * it's better to be explicit than implicit
    * explicit variables not row names
    * do data transformation yourself
  * don't worry about efficiency (speed or time) unless it actually matters
  * consistency

## Data formats

Data frame: rectangular structure, each column homogeneous, but different columns may have different data types.  This is the data frame of R, and the table of SQL.

* Long form: observations in rows, variables in columns
* Wide form: any other format

The first restriction on the data is that it should have observations in rows and variables in the columns. This seems like a simple condition, but it is violated surprisingly often in practice.

A couple of examples - e.g. tb from WHO.

Often this form is not the most natural for data collection or recording because it can require a lot of duplication.

Variables come in two types: id or measured. ID variables describe the experimental design and are known in advance. ID variables can not contain missing values - that would indicate that we don't know what our experimental design is. Measured variables are (as the name suggested) those things that we don't know and must measure.

To get data from wide form to long form, it's typically easiest to go through an intermediate form I call molten form, where we have single column of values, identified by other variables (useful intermediate form). The reshape package provides tools to do these sorts of reshaping operations in R.

Crossing vs. nesting.

# Use

## Reformulation

transform, summarise (+ colwise), arrange and subset.
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

