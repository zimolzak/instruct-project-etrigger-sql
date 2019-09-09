Diagnostic Test Triggers
========

This repository does a bunch of stuff to the SQL code that implements
some medical e-triggers. An e-trigger answers the question, "How do
you find (in the database) patients who had a test that shows a
possibility of cancer, but who have **not** had timely follow-up?"

Quick start
========

At command prompt, type `make`. Most usefully, the script
`transform.py` does useful string replacements that should make the
SQL work on the overall, generic VA data warehouse. You will find that
the files `Fobt_altered.sql HCC_altered.sql IDA_altered.sql
Lung_altered.sql` are useful outputs of this script.

Required software
========

- Python 3
- Perl
- Gnu make
- pandoc
- enscript

Details
========

This SQL code was developed by Li Wei (Houston VAMC) against the US
Dept of Veterans Affairs corporate data warehouse.
Perl/Python/makefile was developed by Andrew Zimolzak.

In more general terms, this repository does some pretty-printing of
SQL source code listings (enscript), listing the input and output
tables of each SQL file (Perl), and string replacements to make the
SQL work on the wider VA data warehouse.
