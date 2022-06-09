discovery = discovery-manual.docx discovery-manual.pdf discovery-manual.md
instruct = instruct-trigger-manual.pdf instruct-trigger-manual.docx
code_pdfs = Fobt_sql.pdf Lung_sql.pdf
mod_sql = HCC_altered.sql IDA_altered.sql
misc = Triggers-Overview.pdf instruct-graph.png orcids-credits.pdf

.PHONY : all
all : $(discovery) $(instruct) $(code_pdfs) $(mod_sql) $(misc)

## Discovery manuals

discovery-manual.md: discovery.md lung-icd10.md colon-icd10.md
	cat discovery.md colon-icd10.md lung-icd10.md > $@

discovery-manual.docx: discovery-manual.md
	pandoc -o $@ $<

%.pdf: %.md
	pandoc -o $@ $<

## Instruct manuals

instruct-trigger-manual.pdf: instruct-trigger-manual.tex
	pdflatex $<
	pdflatex $<

instruct-trigger-manual.docx: instruct-trigger-manual.tex
	pandoc -o $@ $<

## Code PDFs

%_sql.pdf : ../%.sql
	enscript --fancy-header --landscape --highlight=sql --font=Courier7 \
	--media=Letter --mark-wrapped-lines=arrow --line-numbers -o - $< | \
	ps2pdf - > $@

## Auto-modified SQL

%_altered.sql : ../unmodified/%.sql transform.py
	python transform.py $< > $@

## Misc.

# Triggers-Overview.pdf = covered by wildcard "%" pandoc rule

%.png: %.dot
	dot -Tpng -o $@ $<

## Clean

.PHONY : clean clean-instruct clean-discovery

clean : clean-instruct clean-discovery
	rm -f $(code_pdfs) $(mod_sql) $(misc)

clean-instruct:
	rm -f instruct-trigger-manual.aux instruct-trigger-manual.log
	rm -f $(instruct)

clean-discovery:
	rm -f $(discovery)
