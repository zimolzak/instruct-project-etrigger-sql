pdfs = Fobt.pdf Lung.pdf Triggers-Overview.pdf instruct-graph.png
mod_sql = HCC_altered.sql IDA_altered.sql
instruct = instruct-trigger-manual.pdf instruct-trigger-manual.docx
discovery = discovery-manual-icd9.docx discovery-manual-icd9.md discovery-manual-icd9.pdf

.PHONY : all
all : $(pdfs) $(mod_sql) $(instruct) $(discovery)

%.pdf : ../%.sql
	enscript --fancy-header --landscape --highlight=sql --font=Courier7 \
	--media=Letter --mark-wrapped-lines=arrow --line-numbers -o - $< | \
	ps2pdf - > $@

## Instruct manuals

instruct-trigger-manual.pdf: instruct-trigger-manual.tex
	pdflatex $<
	pdflatex $<

instruct-trigger-manual.docx: instruct-trigger-manual.tex
	pandoc -o $@ $<

## Discovery manuals

discovery-manual-icd9.md: discovery.md lung-icd9.md colon-icd9.md
	cat discovery.md colon-icd9.md lung-icd9.md > $@

discovery-manual-icd9.docx: discovery-manual-icd9.md
	pandoc -o $@ $<

discovery-manual-icd9.pdf: discovery-manual-icd9.md
	pandoc -o $@ $<

## end manuals

Triggers-Overview.pdf : Triggers-Overview.md
	pandoc -o $@ $<

%_altered.sql : ../unmodified/%.sql transform.py
	python transform.py $< > $@

%.png: %.dot
	dot -Tpng -o $@ $<

.PHONY : clean clean-instruct clean-discovery

clean : clean-instruct clean-discovery
	rm -f $(pdfs) $(mod_sql)

clean-instruct:
	rm -f instruct-trigger-manual.aux instruct-trigger-manual.log
	rm -f $(instruct)

clean-discovery:
	rm -f $(discovery)
