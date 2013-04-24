# pandoc --chapters -o fp.pdf --latex-engine xelatex \
#   -f markdown+pipe_tables \
#   -V papersize:oneside -V links-as-notes \
#   Functional-programming.md \
#   Functionals.md

pandoc --chapters -o programming.pdf --latex-engine xelatex \
  -V papersize:oneside -V links-as-notes --toc \
  Introduction.md \
  part-fp.md \
  Functions.md \
  Environments.md \
  Functional-programming.md \
  Functionals.md \
  Function-operators.md \
  part-oo.md \
  SoftwareSystems.md \
  S3.md \
  S4.md \
  R5.md \
  part-adv.md \
  Computing-on-the-language.md \
  Expressions.md \
  Formulas.md \
  Special-environments.md \
  Exceptions-debugging.md \
  part-perf.md \
  Profiling.md \
  Performance.md \
  Rcpp.md \
  appendix.md \
  Vocabulary.md \
  Data-structures.md \
  C-interface.md

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
 
