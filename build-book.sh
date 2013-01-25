# pandoc --chapters -o book.pdf --latex-engine xelatex \
#   -V papersize:oneside -V links-as-notes \
#   Functions.md \
#   Environments.md && open book.pdf

pandoc --chapters -o book.pdf --latex-engine xelatex \
  -V papersize:oneside -V links-as-notes --toc \
  Introduction.md \
  Functions.md \
  Environments.md \
  Functional-programming.md \
  Functionals.md \
  Function-operators.md \
  Evaluation.md \
  Computing-on-the-language.md \
  Exceptions-debugging.md \
  SoftwareSystems.md \
  S3.md \
  S4.md \
  R5.md \
  Performance.md \
  Profiling.md \
  C-interface.md \
  Rcpp.md \
  Philosophy.md \
  package-basics.md \
  Package-development-cycle.md \
  Documenting-packages.md \
  Documenting-functions.md \
  Testing.md \
  style.md \
  Namespaces.md \
  git.md \
  Release.md \
  Vocabulary.md \
  Data-structures.md \
  && open book.pdf
