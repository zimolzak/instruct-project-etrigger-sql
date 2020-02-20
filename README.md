InSTRuCt Project e-Trigger Quick Start
========

Downloading the SQL code
--------

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
for change package and other documentation can be found at
https://dvagov.sharepoint.com/sites/VHAiquest/SitePages/Singh_InSTRuCt.aspx
. Access this site from the VA network.

Setting dates
--------

1. Find the first day of the current month (e.g. today is Feb 19, so
you rewind to find Feb 1).

2. Subtract two more months from that (so you get Dec 1).

3. Set sp_start equal to that (set @sp_start='2019-12-01 00:00:00').

4. Set sp_end to the end of that month (set @sp_end='2019-12-31 23:59:59').

5. Done! Other stuff like fu_period can be left as it is.

Setting other parameters and viewing outputs
--------

- You need to change all lines that mention MyDB and MySchema.

- You need to set your sta3n and sta6a.

- For lung, the most interesting outputs are
`Lung_Sta3n528_3_Ins_U_TriggerPos` and `Lung_Sta3n528_4_01_Count`.




Details
========

InSTRuCt is the **I**mprovi**n**g **S**afety of **T**est
**R**es**u**lts **C**ollabora**t**ive, designed to help the follow-up
of medical diagnostic tests. This repository stores SQL code that
implements some e-triggers for diagnostic tests. An e-trigger answers
the question, "How do you find (in the database) patients who had a
test that shows a possibility of cancer, but who have **not** had
timely follow-up?" In brief, the code performs the following steps:

1. Construct multiple tables with diagnostic codes we will need later
(this can comprise half of the lines in the SQL code).

2. Find tests that are suspicious for cancer (most critical step but
few lines of code).

3. Collect diagnosis/procedure codes that will be used for exclusion

4. Perform the exclusion (e.g. too young, deceased, known prior lung
cancer, known other terminal condition).

5. Exclude those who had the proper follow-up (e.g. lung biopsy,
follow-up imaging, tumor board).

6. Compile list of e-trigger positive patients.

7. Count e-trigger positive patients.

The SQL code was developed by Li Wei (Houston VAMC) against the US
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

At command prompt, type `cd advanced` and then `make`. Most notably,
the script `transform.py` does useful string replacements that should
make the SQL work on the overall, generic VA data warehouse. The files
`Fobt_altered.sql HCC_altered.sql IDA_altered.sql Lung_altered.sql`
are output by this script. The makefile depends on:

- Python 3
- Perl
- Gnu make
- pandoc
- enscript, ps2pdf
- usual Unix/Linux toolchain like sort, uniq

If you learn Git / GitHub:

- this code can be "forked" so you can make your own changes

- all previous versions can be viewed

- you can suggest changes (pull request) to this repository or make
changes directly (push)

- you can keep your local code in sync easily with this repository (pull)
