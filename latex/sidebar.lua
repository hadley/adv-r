-- https://github.com/jgm/pandoc/issues/2106#issuecomment-371355862
function Div(el)
  if el.classes:includes("sidebar") then
    return {
      pandoc.RawBlock("latex", "\\begin{kframe}"),
      el,
      pandoc.RawBlock("latex", "\\end{kframe}")
    }
  end
end
