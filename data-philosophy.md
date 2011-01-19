# A philosophy of clean data

This paper defines clean data, and shows how clean data is easier to work with for modelling, transformation and visualisation. A good definition of clean data also makes dirty data easier to work with by showing exactly why it feels dirty and how it can be cleaned up.

My principles of clean data are inspired by databases and Codd's relational algebra, but the set algebra that powers SQL and relational databases is not good a good fit for most statistical problems. 

My definition of clean data is not exhaustive, and it focusses on the type of data that statisticians most commonly encounter: rectangular data defined by rows and columns. It is not a good fit for data on networks, ..., or ... Additional, because the focus of this definition is on explicit definition of the data, it may not be suitable for very large datasets - these may require special infrastructure for performance.

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

A common case of messy data is tabular data designed for presentation, where variables form both the rows and columns, and column headers are values, not variable names. While I call this type of data dirty, in some cases it can be extremely useful. It provides efficient storage for completely crossed designs, and it can provide extremely efficient computation if desired operations can be expressed as matrix operations. It is also necessary for many multivariate methods whose underlying theory is based on manipulation of matrices. But it doesn't generalise well, requiring extensions into higher dimensions to deal with more variables, and can be very inefficient if there are a lot of missing values or variables are nested, not crossed. This makes it inappropriate as a general storage format.

    Pew religion-income data

Another common use of this data is for recording regularly spaced observations over time. For example, the billboard dataset records the date a song first entered the billboard top 100. To record its ranking in the following weeks, 75 variables, from week1 to week75, are needed.  This form of storage is useful for data entry because it reduces duplication - otherwise each song in each week would need its own row.

    Billboard data

This type of data is so common that in R a number of graphical tools have been designed specifically to visualise it, e.g. `barplot`, `matplot`, `dotchart`, `mosaicplot`. Other tools are designed to provide common manipulations like `sweep`, `prop.table` and `margin.table`. Other tools can produce this type of output from formerly clean data: `table`, `xtabs`, `tapply`.  The final section of the paper will alternative tools that work with clean data, and provide more flexibility for an analysis.

To clean up this type of data we need to melt, or stack it, turning columns into rows. Melting is parameterised by a list of variables to keep in columns (cvars), or equivalently a list of columns that should be turned into rows (rvars). It works by adding a new indicator variable to the dataset and stacking the repeated cvars.

    Cleaned pew data
    Cleaned billboard data

## Multiple variables stored in one column

After melting, it often happens that the indicator variable actually records information about more than on variable. This is illustrated by the tb dataset - each column represents two values: age and sex.  

    Original tb

After melting the data to combine variables spread across columns, we get

    Molten tb

Typically, column headers in this format are separated by some character (e.g. `.`, `-`, `_`, `:`) and we can simply split the string up based on that character.  In other cases, such as for this tb data, more careful string processing is required, or the variable names can be matched to a hand made table that converts compound values to multiple variables.

Doing this for the tb data yields:

    Clean tb

Storing the data in this form resolves another problem in the original data: it's more informative to compare tb rates across countries, rather than counts, but to compute this we need to know the population of each category. In the original data format, there is no easy way to add this information, it had to be stored in separate file and was difficult to correctly match up to the counts. In clean form, adding populations (and rates) are easier: they just become additional columns.

## Variables are stored in both rows and columns

The most complicated form of dirty data is when variables have been stored in both rows and columns. The weather data below has variables in single columns (id, year, month), spread across columns (day) and in rows (TMIN, TMAX).  

    Original weather data 

Melting the data gets us to:

    Molten weather data

Which is mostly clean, but we have one variable stored in rows: the observation type. Fixing this requires the cast, or unstack, operation, which performs the inverse of melting, and rotates the `obs` variable back out into the columns to get:

    Clean weather data

# Working with clean data

Clean data is only worthwhile in so much as it makes the rest of the analysis easier. This section discusses general tools for working with clean data, organised into three components of data analysis: transformation, modelling and visualisation.

## Transformation

Here I define transformation very generally - any operation that takes the data as input and returns modified data. It includes variable-by-variable transformation (e.g. `log` or `sqrt`), as well as aggregation, filtering and reordering. In my experience there are four extremely common operations that are performed over and over again in the course of an analysis.  These are the four fundamental verbs of data manipulation:

* filtering, or subsetting, where some observations are removed
* aggregation, where multiple values are collapsed into a single value
* reordering, where the order of observations is changed
* mutation, where new variables are added or existing variables modified 

Each operation takes a data frame and some parameters as input and returns a data frame as output - this makes them easily composable to solve more difficult problems.  

These four verbs are often modified by the __by__ preposition. Many times we need group-wise aggregates, transformations or subsets: pick the biggest in each group, average over replicates, ...

Some aggregations occur so frequently they deserve their own optimised implementations. An example of one such operation is (weighted) counting, which occurs so often that optimisation is worthwhile. Any such operator

These need to return data in long form, so that they can easily be combined with the unaggregated data with join. The table function in base R does not do this - it returns a vector/matrix/array with names. This is problematic because it forces crossing of variables, so all combinations must be counted (many 0 zeros for combinations that don't exist in data), and it's difficult to combine back with the original data.

This raises another important issue - when doing data analysis we don't usually work with a single set of data, but need to be able to fluidly combine multiple data sets, whether they are related data or the same data at multiple levels of aggregation. We need two additional operators for dealing with multiple datasets:

* join: An advantage of long form data is the ease with which it can be combined: we just need a join operator which works by matching common variables and adding new columns. Compare this to the difficulty of combining wide datasets stored in arrays - these typically require painstaking alignment before matrix operations can be used, and errors are very hard to detect. 

* match: Another common operation is subsetting individual level data based on some summary level statistic. This is accomplished using a function very similar to join that only returns matching rows instead of trying to combine the columns.

These ideas have developed iteratively - as my understanding of clean data improved, so to did these tools, which made me realise understand better what tools clean data needs.

### Case study

The following examples illustrates these ideas.  

In this snippet of code, we first count the number of deaths in each hour of the day (`hod`) for each cause of death (`cod`), then remove missing hours, join on fuller descriptions of the disease codes, and transform to compute proportions within a disease.

    hod2 <- count(deaths, c("hod", "cod"))
    hod2 <- subset(hod2, !is.na(hod))
    hod2 <- join(hod2, codes)
    hod2 <- ddply(hod2, "cod", transform, prop = freq / sum(freq))
    
    # Idea for new syntax
    
    deaths &
      count(c("hod", "cod")) &
      subset(!is.na(hod)) &
      join(codes) &
      by("cod", transform, prop = freq / sum(freq))

In the following code, for each disease we calculate the deviation from a uniform pattern over time, find unusual diseases, and then go back to extract matching records from the original data.

    uni_dist <- function(x) sqrt(mean((x - 1/23) ^ 2))

    devi <- ddply(hod2, "cod", summarise, n = sum(freq), 
      dist = uni_dist(prop))
    unusual <- subset(devi, n > 1200 & dist >= 0.009)
    hod_unusual <- match_df(hod2, unusual)
    
    devi <- by("cod", summarise, n = sum(freq), dist = uni_dist(prop))
    deaths & match(devi & subset(n > 1200 & dist >= 0.009)) 

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
