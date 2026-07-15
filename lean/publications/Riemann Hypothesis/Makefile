# Makefile for building the F1 Square Manuscript

PDFLATEX = pdflatex
SRC = manuscript.tex
PDF = manuscript.pdf
AUX = manuscript.aux
LOG = manuscript.log
OUT = manuscript.out
TOC = manuscript.toc

.PHONY: all pdf clean

all: pdf

pdf: $(SRC)
	$(PDFLATEX) $(SRC)
	$(PDFLATEX) $(SRC)

clean:
	rm -f $(PDF) $(AUX) $(LOG) $(OUT) $(TOC)
