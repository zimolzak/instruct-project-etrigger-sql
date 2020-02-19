InSTRuCt Project e-Trigger Quick Start
========

Assuming you are reading this on github.com:

1. Before downloading, you might want to jot down or copy/paste what
it says above under "Latest commit 2a8f123 *xx* days ago" for future
reference.

2. Click on the SQL file you want above (such as LungOperational.sql).

3. Click on the grey button "Raw" at the top the page that comes up.

4. Use your browser menu to save file to disk (such as "File / Save
Page As...").

The code you download should always be the latest version. Email z i m
o l z a k **at** bcm.edu with any questions (delete those spaces
first, and replace **at** with a real at sign). The SharePoint site
for change package and other documentation can be found at (insert URL
here).


Details
========

This repository stores SQL code that implements some e-triggers for
diagnostic tests. An e-trigger answers the question, "How do you find
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
- you can suggest changes to this repository or make changes directly
