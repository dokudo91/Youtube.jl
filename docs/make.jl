using Documenter
using Youtube
DocMeta.setdocmeta!(Youtube, :DocTestSetup, :(using Youtube); recursive=true)
makedocs(
    sitename="Youtube",
    format=Documenter.HTML(),
    modules=[Youtube],
    pages=["index.md", "cmd.md"]
)
deploydocs(
    repo="github.com/dokudo91/Youtube.jl.git",
)