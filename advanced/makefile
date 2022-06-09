discovery = discovery-manual.docx discovery-manual.pdf discovery-manual.md
instruct = instruct-trigger-manual.pdf instruct-trigger-manual.docx
pdfs = Fobt.pdf Lung.pdf
mod_sql = HCC_altered.sql IDA_altered.sql
misc = Triggers-Overview.pdf instruct-graph.png

.PHONY : all
all : $(discovery) $(instruct)  $(pdfs) $(mod_sql) $(misc)

## Discovery manuals

discovery-manual.md: discovery.md lung-icd10.md colon-icd10.md
	cat discovery.md colon-icd10.md lung-icd10.md > $@

discovery-manual.docx: discovery-manual.md
	pandoc -o $@ $<

discovery-manual.pdf: discovery-manual.md
	pandoc -o $@ $<

## Instruct manuals

instruct-trigger-manual.pdf: instruct-trigger-manual.tex
	pdflatex $<
	pdflatex $<

instruct-trigger-manual.docx: instruct-trigger-manual.tex
	pandoc -o $@ $<

## Code PDFs

%.pdf : ../%.sql
	enscript --fancy-header --landscape --highlight=sql --font=Courier7 \
	--media=Letter --mark-wrapped-lines=arrow --line-numbers -o - $< | \
	ps2pdf - > $@

## Auto-modified SQL

%_altered.sql : ../unmodified/%.sql transform.py
	python transform.py $< > $@

## Misc.

Triggers-Overview.pdf : Triggers-Overview.md
	pandoc -o $@ $<

%.png: %.dot
	dot -Tpng -o $@ $<

## Clean

.PHONY : clean clean-instruct clean-discovery

clean : clean-instruct clean-discovery
	rm -f $(pdfs) $(mod_sql) $(misc)

clean-instruct:
	rm -f instruct-trigger-manual.aux instruct-trigger-manual.log
	rm -f $(instruct)

clean-discovery:
	rm -f $(discovery)
