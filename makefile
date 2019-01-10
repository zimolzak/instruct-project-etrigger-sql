pdfs = Fobt.pdf HCC.pdf IDA.pdf Lung.pdf

all : $(pdfs)

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

.PHONY : clean
clean :
	rm -f $(pdfs)
