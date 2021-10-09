function createtemplate(path="."; template=:book)

    if template == :book
        tex = "%! TeX program = lualatex\n\\documentclass[12pt, oneside]{book}\n\n\\usepackage{listings}\n\n\\pagestyle{plain}\n\\usepackage{pdfpages}\n\\usepackage{titlesec}\n\n\\usepackage[square,numbers]{natbib}\n\\usepackage[pdftex,bookmarks=true,bookmarksopen=false,bookmarksnumbered=true,colorlinks=true,linkcolor=blue]{hyperref}\n\\usepackage[utf8]{inputenc}\n\\usepackage{float}\n\\usepackage{enumerate}\n\n%%%%%%% JULIA %%%%%%%%%%\n\\input{julia_font}\n\\input{julia_listings}\n\\input{julia_listings}\n\\input{julia_listings_unicode}\n\n\\lstdefinelanguage{JuliaLocal}{\n    language = Julia, % inherit Julia lang. to add keywords\n    morekeywords = [3]{thompson_sampling}, % define more functions\n    morekeywords = [2]{Beta, Distributions}, % define more types and modules\n}\n%%%%%%%%%%%%%%%%%%%%%%%%\n\n\n%%%%%%%%%% BOOK INFORMATION %%%%%%%%%%\n\\newcommand{\\authorname}{Name}\n\\newcommand{\\booktitle}{Title}\n\\newcommand{\\subtitle}{Subtitle}\n\\newcommand{\\publisher}{TBD}\n\\newcommand{\\editionyear}{2021}\n\\newcommand{\\isbn}{XYZ}   % replace this with your own ISBN\n\n\\title{\\booktitle}\n\\author{\\authorname}\n\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n\n\\begin{document}\n\n% \\includepdf{cover.pdf}\n\n\\frontmatter\n\\input{frontmatter/titlepage}\n\\input{frontmatter/copyright}\n% \\include{preface}\n\n\\newpage\n\\tableofcontents\n\n\\mainmatter\n\\newpage\n\n\n\\bibliography{ref}\n\n\\bibliographystyle{plainnat}\n\n\\include{appendix}\n\n\\end{document}\n"

    elseif template == :mathbook
        tex = "%! TeX program = lualatex\n\\documentclass[12pt, oneside]{book}\n\n\\usepackage{listings}\n\n\\pagestyle{plain}\n\\usepackage{pdfpages}\n\\usepackage{titlesec}\n\n%%%% MATH PACKAGES %%%%\n\n\\usepackage{amsfonts, amsthm,amsmath,amssymb,mathtools}\n\\usepackage{bbm}\n\\usepackage{bm}\n\\usepackage{mathtools}\n\\usepackage{thmtools} % List of Theorems\n\n%%%%%%%%%%%%%%%%%%%%%%%\n\n\\usepackage[square,numbers]{natbib}\n\\usepackage[pdftex,bookmarks=true,bookmarksopen=false,bookmarksnumbered=true,colorlinks=true,linkcolor=blue]{hyperref}\n\\usepackage[utf8]{inputenc}\n\\usepackage{float}\n\\usepackage{enumerate}\n\n%%%%%%% JULIA %%%%%%%%%%\n\\input{julia_font}\n\\input{julia_listings}\n\\input{julia_listings_unicode}\n\n\\lstdefinelanguage{JuliaLocal}{\n    language = Julia, % inherit Julia lang. to add keywords\n    morekeywords = [3]{thompson_sampling}, % define more functions\n    morekeywords = [2]{Beta, Distributions}, % define more types and modules\n}\n%%%%%%%%%%%%%%%%%%%%%%%%\n\n\n%%%%%%%%%% BOOK INFORMATION %%%%%%%%%%\n\\newcommand{\\authorname}{Name}\n\\newcommand{\\booktitle}{Title}\n\\newcommand{\\subtitle}{Subtitle}\n\\newcommand{\\publisher}{TBD}\n\\newcommand{\\editionyear}{2021}\n\\newcommand{\\isbn}{XYZ}   % replace this with your own ISBN\n\n\\title{\\booktitle}\n\\author{\\authorname}\n\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n%%%%%%%%%%%% MATH STYLE  %%%%%%%%%%%%%\n\\newtheoremstyle{bfnote}%\n  {}{}\n  {}{}\n  {\\bfseries}{.}\n  { }{\\thmname{#1}\\thmnumber{ #2}\\thmnote{ (#3)}}\n\\theoremstyle{bfnote}\n\\newenvironment{prf}[1][Proof]{\\textbf{#1.} }{\\qed}\n\\newtheorem{theorem}{Theorem}[section]\n\\newtheorem{definition}[theorem]{Definition}\n\\newtheorem{exer}{Exercise}[section]\n\\newtheorem{lemma}[theorem]{Lemma}\n\\newtheorem{corollary}[theorem]{Corollary}\n\\newtheorem{proposition}[theorem]{Proposition}\n\n\\newtheorem{note}{Note}[section]\n\\newtheorem{example}{Example}[section]\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n\\begin{document}\n\n% \\includepdf{cover.pdf}\n\n\\frontmatter\n\\input{frontmatter/titlepage}\n\\input{frontmatter/copyright}\n% \\include{preface}\n\n\\newpage\n\\tableofcontents\n\n%\\listoftheorems[onlynamed]\n\n\\mainmatter\n\\newpage\n\n\n\\bibliography{ref}\n\n\\bibliographystyle{plainnat}\n\n\\include{appendix}\n\n\\end{document}\n\n"
    end
    maintex = path * "/build_latex/main.tex"
    open(maintex, "w") do f
        write(f, tex)
    end
end
