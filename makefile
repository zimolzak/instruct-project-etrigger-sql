Fobt.pdf : Fobt.sql
	enscript -GrEsql -fCourier7 -MLetter -o - Fobt.sql | ps2pdf - > $@
