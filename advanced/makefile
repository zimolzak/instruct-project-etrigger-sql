pdfs = Fobt.pdf HCC.pdf IDA.pdf Lung.pdf Triggers-Overview.pdf LungOperational.pdf
srctxt = list_src_Fobt.txt list_src_HCC.txt list_src_IDA.txt list_src_Lung.txt
dsttxt = list_dst_Fobt.txt list_dst_HCC.txt list_dst_IDA.txt list_dst_Lung.txt
mod_sql = Fobt_altered.sql HCC_altered.sql IDA_altered.sql Lung_altered.sql
manual = instruct-trigger-manual.pdf instruct-trigger-manual.docx instruct-trigger-manual.txt

.PHONY : all
all : $(pdfs) primitive_Fobt_list.txt $(srctxt) $(dsttxt) $(mod_sql) $(manual)

%.pdf : ../%.sql
	enscript --fancy-header --landscape --highlight=sql --font=Courier7 \
	--media=Letter -o - $< | ps2pdf - > $@

instruct-trigger-manual.pdf: instruct-trigger-manual.tex
	pdflatex $<
	pdflatex $<

%.docx: %.tex
	pandoc -o $@ $<

instruct-trigger-manual.txt: instruct-trigger-manual.tex
	pandoc -o $@ $<

LungOperational.pdf : ../LungOperational.sql
	enscript --fancy-header --landscape --highlight=sql --font=Courier7 \
	--media=Letter --mark-wrapped-lines=arrow --line-numbers -o - $< | \
	ps2pdf - > $@

Triggers-Overview.pdf : Triggers-Overview.md
	pandoc -o $@ $<

primitive_Fobt_list.txt : ../Fobt.sql list_tables.pl
	./list_tables.pl ../Fobt.sql | sort | uniq > $@

list_src_%.txt : ../%.sql list_tables_2.pl
	./list_tables_2.pl $< --src | sort | uniq > $@

list_dst_%.txt : ../%.sql list_tables_2.pl
	./list_tables_2.pl $< --dst | sort | uniq > $@

%_altered.sql : ../%.sql transform.py
	python transform.py $< > $@

.PHONY : clean cleanall

clean :
	rm -f primitive_Fobt_list.txt $(srctxt) $(dsttxt) \
	instruct-trigger-manual.aux instruct-trigger-manual.log

cleanall : clean
	rm -f $(pdfs) $(mod_sql) $(manual)
