# pandoc --chapters -o fp.pdf --latex-engine xelatex \
#   -f markdown+pipe_tables \
#   -V papersize:oneside -V links-as-notes \
#   Functional-programming.md \
#   Functionals.md

pandoc --chapters -o book/adv-r.pdf --latex-engine xelatex \
  -V papersize:oneside -V links-as-notes --toc \
  -M monofont=Inconsolata \
  book/title.md \
  book/chapters/Introduction.md \
  book/part-foundations.md \
  book/chapters/Data-structures.md \
  book/chapters/Subsetting.md \
  book/chapters/Vocabulary.md \
  book/chapters/Functions.md \
  book/chapters/OO-essentials.md \
  book/chapters/Environments.md \
  book/chapters/Exceptions-debugging.md \
  book/part-fp.md \
  book/chapters/Functional-programming.md \
  book/chapters/Functionals.md \
  book/chapters/Function-operators.md \
  book/part-adv.md \
  book/chapters/Computing-on-the-language.md \
  book/chapters/Expressions.md \
  book/chapters/Formulas.md \
  book/chapters/Special-environments.md \
  book/chapters/dsl.md \
  book/part-perf.md \
  book/chapters/Performance.md \
  book/chapters/Profiling.md \
  book/chapters/Memory.md \
  book/chapters/Rcpp.md \
  book/chapters/C-interface.md

# pandoc --chapters -o packages.pdf --latex-engine xelatex \
#   -V papersize:oneside -V links-as-notes --toc \
#   Philosophy.md \
#   package-basics.md \
#   Package-development-cycle.md \
#   Documenting-packages.md \
#   Documenting-functions.md \
#   Testing.md \
#   style.md \
#   Namespaces.md \
#   git.md \
#   Release.md
 
