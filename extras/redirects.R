library(whisker)

redirects <- c(
  "Philosophy.html" = "intro.html",
  "Package-basics.html" = "description.html",
  "Package-development-cycle.html" = "r.html",
  "Package-quick-reference.html" = "r.html",
  "Documenting-packages.html" = "vignettes.html",
  "Documenting-functions.html" = "man.html",
  "Namespaces.html" = "namespace.html",
  "Testing.html" = "tests.html",
  "Git.html" = "git.html",
  "Release.html" = "release.html"
)

data <- list(rule = lapply(seq_along(redirects), function(i) list(old = names(redirects)[i], new = redirects[[i]])))

template <- "
<RoutingRules>
{{#rule}}
  <RoutingRule>
    <Condition>
      <KeyPrefixEquals>{{{old}}}</KeyPrefixEquals>
    </Condition>
    <Redirect>
      <HostName>r-pkgs.had.co.nz</HostName>
      <ReplaceKeyWith>{{{new}}}</ReplaceKeyWith>
    </Redirect>
  </RoutingRule>
{{/rule}}
</RoutingRules>
"

cat(whisker.render(template, data))
