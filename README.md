Quick Start
========

Assuming you are reading this on github.com,

1. Click on the SQL file you want above
2. Click on the grey button "Raw" near top of page
3. Use browser menu to save file to disk (such as "File / Save Page As...")

Email z i m o l z a k **at** bcm.edu with any questions.

Details
========

This repository stores SQL code that implements some e-triggers for
diagnostic tests.

InSTRuCt Project Diagnostic Test Triggers

An e-trigger answers the question, "How do you find
(in the database) patients who had a test that shows a possibility of
cancer, but who have **not** had timely follow-up?"

This SQL code was developed by Li Wei (Houston VAMC) against the US
Dept of Veterans Affairs corporate data warehouse.
Perl/Python/makefile was developed by Andrew Zimolzak. As a work of
the United States Government, this project is in the public domain
within the United States. Additionally, we waive copyright and related
rights in the work worldwide (see LICENSE file).


Advanced usage
========

This will do some pretty-printing of SQL source code listings
(enscript), listing the input and output tables of each SQL file
(Perl), and string replacements to make the SQL work on the wider VA
data warehouse.

At command prompt, type `make`. Most usefully, the script
`transform.py` does useful string replacements that should make the
SQL work on the overall, generic VA data warehouse. You will find that
the files `Fobt_altered.sql HCC_altered.sql IDA_altered.sql
Lung_altered.sql` are useful outputs of this script. The makefile
depends on:

- Python 3
- Perl
- Gnu make
- pandoc
- enscript, ps2pdf
- usual Unix/Linux toolchain like sort, uniq

If you learn Git / GitHub:

- this code can be "forked" so you can make your own changes
- all previous versions can be viewed
