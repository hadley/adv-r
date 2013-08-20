require 'tempfile'

module Jekyll
  class RMarkdownConverter < Converter
    safe :false
    priority :high

    def matches(ext)
      ext =~ /^\.(rmd|rmarkdown)$/i
    end

    def output_ext(ext)
      ".html"
    end

    def convert(content)
      Tempfile.open(['knitr', '.Rmd']) do |f|
        f.write(content)
        f.write("\n")
        f.flush

        # http://rubyquicktips.com/post/5862861056/execute-shell-commands
        content = `_plugins/knit.r #{f.path}`
        raise "Knitting failed" if $?.exitstatus != 0
        content
      end
    end
  end
end