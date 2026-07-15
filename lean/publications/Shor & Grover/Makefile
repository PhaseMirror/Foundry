clean:
	rm -rf $(input) $(output)
	rm -rf *.log *.aux *.bbl *.blg

%.dvi: %.tex
	-latex -interaction=nonstopmode $*.tex
	latex $*.tex
	-bibtex $*
	latex $*.tex
	
%.pdf: %.tex
	-latex -interaction=nonstopmode $*.tex
	pdflatex $*.tex
	-bibtex $*
	pdflatex $*.tex
	pdflatex $*.tex    