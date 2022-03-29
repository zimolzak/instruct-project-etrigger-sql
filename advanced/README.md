Advanced usage
========

Useful pseudocode files
--------

- `discovery.md`
- `lung-icd10.md`
- `colon-icd10.md`

Other files
--------

This directory also includes auxiliary scripts to do pretty-printing of SQL source code
listings (enscript), listing the input and output tables of each SQL
file (Perl), and string replacements to make the SQL work on the wider
VA data warehouse.

At command prompt, type `cd advanced` and then `make`. Most notably,
the script `transform.py` does useful string replacements that should
make the SQL work on the overall, generic VA data warehouse. Files
called `xxxx_altered.sql` are output by this script. The makefile and
other scripts depend on:

- Python 3
- Perl
- Gnu make
- pandoc
- enscript, ps2pdf, pdflatex
- usual Unix/Linux toolchain like sort, uniq

If you learn Git / GitHub:

- This code can be "forked" so you can make your own changes

- All previous versions can be viewed

- You can suggest changes (pull request) to this repository or make
changes directly (push)

- You can keep your local code in sync easily with this repository (pull)
