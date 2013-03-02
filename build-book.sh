# pandoc --chapters -o fp.pdf --latex-engine xelatex \
#   -f markdown+pipe_tables \
#   -V papersize:oneside -V links-as-notes \
#   Functional-programming.md \
#   Functionals.md

pandoc --chapters -o programming.pdf --latex-engine xelatex \
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
  Rcpp.md \
  C-interface.md

pandoc --chapters -o packages.pdf --latex-engine xelatex \
  -V papersize:oneside -V links-as-notes --toc \
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
  Data-structures.md
 
