module NotebookToLatex

using ReadableRegex
using Plots
using Makie
using CairoMakie
export notebooktolatex

include("templates.jl")
include("auxiliarytex.jl")
include("markdowntolatex.jl")
include("helperfunctions.jl")


"""
    Runner is a module for controling the scope
    when running the notebook files, avoinding that any
    command interferes with the "outside" script.
"""
module Runner
end

"""
    extractnotebook(notebook)
Reads a Pluto notebook file, extracts the code
and returns a dictionary with the code in organized form.
The output is a dictionary containing
* `codes`        - The cell code of each running cell;
* `notebookname` - Name of the notebook;
* `notebookdir`  - Directory location of the notebook file;
* `contents`     - Only the Julia code in the cell;
* `outputtag`    - Whether the output is hidden or showing (read the `tagcelloutput()` function);
* `celltype`     - Whether cell contains code or markdown;
* `order`        - Order that the cells are displayed in the notebook;
* `view`         - Whether the code is hidden or showing (the "eye" icon in the notebook);

e.g. `extractnotebook("./mynotebook.jl")`
notebookdata = Dict(:codes => codes, :notebookname => notebookname, :notebookdir => notebookdir,
                        :contents => contents, :outputtag=>outputtag,
                        :celltype => celltype,:order=> order,:view=>view)
"""
function extractnotebook(notebook)
    s = read(notebook, String)
    cells = split(s, "# ╔═╡ ");
    # The first cell and the final 3 are not used
    codes, contents, outputtag, celltype = [],[],[],[]
    for cell in cells[2:end-3]
        push!(codes, cell[1:36])
        push!(contents, cell[38:end])
        push!(outputtag, endswith(rstrip(cell),";") ? "hideoutput" : "showoutput")
        push!(celltype, cell[38:42] == "md\"\"\"" ? "markdown" : "code")
    end
    
    # Get order and view type
    r = either("# ╠","# ╟")
    sortedcells = split(cells[end],Regex(r))
    sortedcodes = [cell[4:39] for cell in sortedcells[2:end-2]]
    order = [findfirst(isequal(scode),codes) for scode in  sortedcodes[1:end]]
    view  = [occursin("═",c) ? "showcode" : "hidecode" for c in sortedcells[2:end-2]]
    # Matching running order
    view  = view[[findfirst(isequal(scode),sortedcodes) for scode in  codes]]

    # inferring the notebook name
    # base on the notebook file path.
    notebookname = split(notebook,"/")[end]
    if endswith(notebookname,".jl")
        # removes the ".jl" in the end
        notebookname = notebookname[1:end-3]
    end
    notebookdir = dirname(notebook) == "" ? "./" : dirname(notebook)
    
    notebookdata = Dict(:codes => codes, :notebookname => notebookname, :notebookdir => notebookdir,
                        :contents => contents, :outputtag=>outputtag,
                        :celltype => celltype,:order=> order,:view=>view)
    return notebookdata
end

function collectoutputs(notebookdata, path)
    figureindex = Dict(:i => 0)
    runpath = pwd()
    cd(notebookdata[:notebookdir])
    outputs = []
    for (i, content) ∈ enumerate(notebookdata[:contents])
        if notebookdata[:celltype][i] == "code"
            if startswith(lstrip(content),"begin") && endswith(rstrip(content),"end")
                ex = :($(Meta.parse(strip(content))))
            else
                ex = :($(Meta.parse("begin\n"*content*"\n end")))
            end
            
            s = string(ex.args[end])
            if contains(s, Regex(either("PlutoUI.LocalResource","LocalResource")))
                if findfirst(Regex(look_for(one_or_more(ANY),after="(\"",before="\")")),s) === nothing
                    Core.eval(Runner, ex)
                    pathvariable = s[findfirst(Regex(look_for(one_or_more(ANY),after="(",before=")")),s)]
                    imagepath = Core.eval(Runner,Meta.parse(pathvariable))
                else
                    imagepath = s[findfirst(Regex(look_for(one_or_more(ANY),after="(\"",before="\")")),s)]
                end
                push!(outputs,(:image,pwd()*"/"*imagepath))
            else
                io = IOBuffer();
                Base.invokelatest(show,
                    IOContext(io, :limit => true),"text/plain",
                    dispatch_output(Core.eval(Runner,ex), notebookdata[:notebookname], path, figureindex));
                celloutput = String(take!(io))
                if celloutput == "nothing"
                    push!(outputs,(:nothing, ""))
                elseif startswith(celloutput, "Plot{Plots.")
                    push!(outputs,
                    (:plot,notebookdata[:notebookname]*"_"*"figure"*string(figureindex[:i])*".png"))
                elseif startswith(celloutput, "FigureAxisPlot()")
                    push!(outputs,
                    (:plot,notebookdata[:notebookname]*"_"*"figure"*string(figureindex[:i])*".pdf"))
                else
                    push!(outputs,(:text, celloutput))
                end
            end
        else
            push!(outputs,nothing)
        end
    end
    cd(runpath)
    return outputs
end

function dispatch_output(command_eval::Makie.FigureAxisPlot, notebookname, path, figureindex)
    figureindex[:i]+=1
    save(path*"/figures/"*notebookname*"_"*"figure"*string(figureindex[:i])*".pdf", command_eval)
    return command_eval
end

function dispatch_output(command_eval::Plots.Plot, notebookname, path, figureindex)
    figureindex[:i]+=1
    savefig(command_eval,path*"/figures/"*notebookname*"_"*"figure"*string(figureindex[:i])*".png")
    return command_eval
end

function dispatch_output(command_eval, notebookname, path, figureindex)
   return command_eval 
end

"""
    notebooktolatex(notebook, targetdir="./build_latex"; template=:book, fontpath=nothing)
Takes a notebook file, converts it to Latex and creates a file structure
with figures, fonts and listing files.
* `targetdir` is the target directory where the Latex project will be created.
If the directory does no exists, it is created.
* `template` - The template for the Latex file. It's based on Latex templates.
Current supported templates are `:book`, `:mathbook`.
* `fontpath` - The output Latex files uses JuliaMono fonts in order to support the
unicodes that are also supported in Julia. If the user already has JuliaMono installed,
he can provide the path to where the `.ttf` files are stored. If `nothing` is passed,
then the font files will be downloaded and saved in the `./fonts/` folder.
"""
function notebooktolatex(notebook::String, targetdir="./build_latex"; template=:book, fontpath=nothing)
    if endswith((notebook),".jl")
        plutotolatex(notebook, targetdir, template=template, fontpath=fontpath)
    elseif endswith((notebook),".ipynb")
        println("Jupyter no yet implemented")
    else
        throw(ArgumentError(notebook, "extension must be either .jl or .ipynb"))
    end
end

"""
    plutotolatex(notebookname, targetdir="./build_latex"; template=:book, fontpath=nothing)
Function to convert Pluto notebooks. The arguments are the same as the ones in
`notebooktolatex`.
"""
function plutotolatex(notebookname, targetdir="./build_latex"; template=:book, fontpath=nothing)

    createproject(targetdir, template)
    nb = extractnotebook(notebookname)
    texfile = read(targetdir*"/main.tex", String)
    lineinsert = 1
    for (i,line) in enumerate(split(texfile, "\n"))
        if startswith(line, "% INCLUDE NOTEBOOKS")
            lineinsert = i
            break
        end
    end
    
    if !occursin("\\include{./notebooks/"*nb[:notebookname]*"}",read(targetdir*"/main.tex", String))

        insertlinebelow(targetdir*"/main.tex",
            "\\include{./notebooks/"*nb[:notebookname]*"}", lineinsert)
    end

    outputs = collectoutputs(nb,targetdir);
    notebook = targetdir*"/notebooks/"*nb[:notebookname]*".tex"
    open(notebook, "w") do f
        write(f,"\\newpage\n")
        for i in nb[:order]
            if nb[:celltype][i] == "markdown"
                parsed = markdowntolatex(strip(nb[:contents][i])[7:end-3])
                write(f,parsed)
            elseif nb[:celltype][i] == "code" && nb[:view][i] == "showcode"
                write(f,"\n\\begin{lstlisting}[language=JuliaLocal, style=julia]\n")
                write(f, strip(nb[:contents][i]))
                write(f,"\n\\end{lstlisting}\n")
            end
            if nb[:celltype][i] == "code" && nb[:outputtag][i] == "showoutput"
                if outputs[i][1] == :text
                    write(f,"\n\\begin{verbatim}\n")
                    write(f, outputs[i][2])
                    write(f,"\n\\end{verbatim}\n")
                elseif outputs[i][1] == :plot
                    write(f,"\n\\begin{figure}[H]\n")
                    write(f,"\t\\centering\n")
                    write(f,"\t\\includegraphics[width=0.8\\textwidth]{./figures/"*outputs[i][2]*"}\n")
                    write(f,"\t\\label{fig:"*outputs[i][2]*"}\n")
                    write(f,"\n\\end{figure}\n")
                elseif outputs[i][1] == :image
                    write(f,"\n\\begin{figure}[H]\n")
                    write(f,"\t\\centering\n")
                    write(f,"\t\\includegraphics[width=0.8\\textwidth]{"*outputs[i][2]*"}\n")
                    write(f,"\t\\label{fig:"*outputs[i][2]*"}\n")
                    write(f,"\n\\end{figure}\n")
                end
            end
        end
    end
end


end