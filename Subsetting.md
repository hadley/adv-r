# Subsetting

* Three subsetting operators.
* Five types of subsetting.
* Extensions to more than 1d.

All basic data structures can be teased apart using the subsetting operators: `[`, `'[[` and `$`. 

## 1d subsetting

It's easiest to explain subsetting for 1d first, and then show how it generalises to higher dimensions. You can subset by 6 different things:

* blank: return everything
* positive integers: return elements at those positions
* zero: returns nothing
* negative integers: return all elements except at those positions
* character vector: return elements with matching names
* logical vector: return all elements where the corresponding logical value is `TRUE`

(Note for integers that it's not just subsetting that you can do.)

* lookup tables
* expanding aggregated counts
* ordering
* matching by hand
* logical vs integer, boolean vs sets

## nd subsetting

For higher dimensions these are separated by commas.

You can also subset with matrices.

## Simplifying vs. preserving subsetting

* `[` .  Drop argument controls simplification.
* `'[[` returns an element
* `x$y` is equivalent to `x'[["y"]]`
