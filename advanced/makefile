pdfs = Fobt.pdf Lung.pdf Triggers-Overview.pdf instruct-graph.png
mod_sql = HCC_altered.sql IDA_altered.sql
manual = instruct-trigger-manual.pdf instruct-trigger-manual.docx instruct-trigger-manual.txt discovery.pdf discovery.docx colon.docx lung.docx discovery-manual-with-appendices.docx

.PHONY : all
all : $(pdfs) $(mod_sql) $(manual)

%.pdf : ../%.sql
	enscript --fancy-header --landscape --highlight=sql --font=Courier7 \
	--media=Letter --mark-wrapped-lines=arrow --line-numbers -o - $< | \
	ps2pdf - > $@

## manuals

instruct-trigger-manual.pdf: instruct-trigger-manual.tex
	pdflatex $<
	pdflatex $<

%.docx: %.tex
	pandoc -o $@ $<

instruct-trigger-manual.txt: instruct-trigger-manual.tex
	pandoc -o $@ $<

discovery.pdf: discovery.md
	pandoc -o $@ $<

discovery.docx: discovery.md
	pandoc -o $@ $<

colon.docx: colon.md
	pandoc -o $@ $<

lung.docx: lung.md
	pandoc -o $@ $<

discovery-manual-with-appendices.docx: discovery-manual-with-appendices.md
	pandoc -o $@ $<

discovery-manual-with-appendices.md: discovery.md lung.md colon.md
	cat discovery.md colon.md lung.md > $@

## end manuals

Triggers-Overview.pdf : Triggers-Overview.md
	pandoc -o $@ $<

%_altered.sql : ../unmodified/%.sql transform.py
	python transform.py $< > $@

%.png: %.dot
	dot -Tpng -o $@ $<

.PHONY : clean

clean :
	rm -f instruct-trigger-manual.aux instruct-trigger-manual.log
	rm -f $(pdfs) $(mod_sql) $(manual)
