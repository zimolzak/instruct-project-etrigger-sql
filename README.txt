Diagnostic Test Triggers
========

This repository stores SQL code that implements
some medical e-triggers. An e-trigger answers the question, "How do
you find (in the database) patients who had a test that shows a
possibility of cancer, but who have **not** had timely follow-up?"

As of February 2020, end users of the code just need to select the
SQL file they want, download it to their local computer, and run it.
You do not need to "know Git" to do this.


Advanced usage
========

At command prompt, type `make`. Most usefully, the script
`transform.py` does useful string replacements that should make the
SQL work on the overall, generic VA data warehouse. You will find that
the files `Fobt_altered.sql HCC_altered.sql IDA_altered.sql
Lung_altered.sql` are useful outputs of this script. Makefile depends
on:

- Python 3
- Perl
- Gnu make
- pandoc
- enscript

As a Git / GitHub repository:

- this code can be "forked" so you can make your own changes
- all previous versions can be viewed

Details
========

This SQL code was developed by Li Wei (Houston VAMC) against the US
Dept of Veterans Affairs corporate data warehouse.
Perl/Python/makefile was developed by Andrew Zimolzak.

In more general terms, this repository does some pretty-printing of
SQL source code listings (enscript), listing the input and output
tables of each SQL file (Perl), and string replacements to make the
SQL work on the wider VA data warehouse.

As a work of the United States Government, this project is in the
public domain within the United States. Additionally, we waive
copyright and related rights in the work worldwide (see LICENSE file).
