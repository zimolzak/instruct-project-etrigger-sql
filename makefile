pdfs = Fobt.pdf HCC.pdf IDA.pdf Lung.pdf
srctxt = list_src_Fobt.txt list_src_HCC.txt list_src_IDA.txt list_src_Lung.txt
dsttxt = list_dst_Fobt.txt list_dst_HCC.txt list_dst_IDA.txt list_dst_Lung.txt

# ./list_tables_2.pl Fobt.sql --dst |sort|uniq|wc

.PHONY : all
all : $(pdfs) list1.txt list2.txt $(srctxt) $(dsttxt)

Fobt.pdf : Fobt.sql
	enscript --fancy-header --landscape --highlight=sql --font=Courier7 \
	--media=Letter -o - Fobt.sql | ps2pdf - > $@

HCC.pdf : HCC.sql
	enscript --fancy-header --landscape --highlight=sql --font=Courier7 \
	--media=Letter -o - HCC.sql | ps2pdf - > $@

IDA.pdf : IDA.sql
	enscript --fancy-header --landscape --highlight=sql --font=Courier7 \
	--media=Letter -o - IDA.sql | ps2pdf - > $@

Lung.pdf : Lung.sql
	enscript --fancy-header --landscape --highlight=sql --font=Courier7 \
	--media=Letter -o - Lung.sql | ps2pdf - > $@

list1.txt : Fobt.sql list_tables.pl
	./list_tables.pl Fobt.sql | sort | uniq > $@

list2.txt : Fobt.sql list_tables_2.pl
	./list_tables_2.pl Fobt.sql | sort | uniq > $@

list_src_%.txt : %.sql list_tables_2.pl
	./list_tables_2.pl $< --src | sort | uniq > $@

list_dst_%.txt : %.sql list_tables_2.pl
	./list_tables_2.pl $< --dst | sort | uniq > $@

.PHONY : clean
clean :
	rm -f $(pdfs) list1.txt list2.txt $(srctxt) $(dsttxt)
