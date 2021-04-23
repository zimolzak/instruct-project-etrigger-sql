InSTRuCt Project e-Trigger Quick Start
========

This code is public domain for *anyone* to use as they wish. However,
if you have a peer reviewed paper based in part on the code, we ask
that you cite:

- Murphy et al. [Development and Validation of Trigger Algorithms to Identify Delays in Diagnostic Evaluation of Gastroenterological Cancer.](https://pubmed.ncbi.nlm.nih.gov/28804030/) Clin Gastroenterol Hepatol. 2018 Jan;16(1):90-98.

- Murphy et al. [Computerized Triggers of Big Data to Detect Delays in Follow-up of Chest Imaging Results.](https://pubmed.ncbi.nlm.nih.gov/27178786/) Chest. 2016 Sep;150(3):613-20.

https://pubmed.ncbi.nlm.nih.gov/25961634/

https://pubmed.ncbi.nlm.nih.gov/23873756/

Downloading the SQL code
--------

Assuming you are reading this on github.com:

1. Before downloading, jot down or copy/paste the text in the light
blue bar above, especially the **seven random-looking letters and
numbers** such as "LWeiBCM Update Lung.sql ... **8c2f54a** 2 days
ago." This will identify the exact version of the code you downloaded,
for future reference.

2. Click on the SQL file you want above (such as `Lung.sql`).

3. Click on the grey button "Raw" near the top the page that comes up.

4. Use your browser menu to save file to disk (such as "File / Save
Page As...").

The code you download should always be the latest version. Email z i m
o l z a k **at** bcm.edu with any questions (delete those spaces
first, and replace **at** with a real at sign). The SharePoint site
for change package and other documentation can be found at
https://dvagov.sharepoint.com/sites/VHAiquest/SitePages/Singh_InSTRuCt_2.aspx 
. This link is specific to *cohort 2* and needs to be accessed from the VA network.

Setting dates
--------

1. Find the first day of the current month (e.g. if today is Feb 19,
you rewind to find Feb 1).

2. Subtract two more months from that (so you get Dec 1) if you are running `Lung.sql`. Subtract *three months* if you are running `Fobt.sql`.

3. Set `sp_start` equal to that (such as `set @sp_start='2019-12-01 00:00:00'`).

4. Set `sp_end` to the end of that month (such as `set @sp_end='2019-12-31 23:59:59'`).

5. Done! Other stuff like `fu_period` can be left as it is.

Setting other parameters and viewing outputs
--------

- You need to change all lines that mention MyDB and MySchema.

- You need to set your sta3n and sta6a.

- **IMPORTANT** For lung, view patient level data by running this line of code:
`select * from #Lung_Sta3n528_3_Ins_U_TriggerPos`. For counts, see `Lung_Sta3n528_4_01_Count` which should display automatically.

- **IMPORTANT** For colorectal, view patient level data by running this line of code:
`select * from #FOBT_Sta3n528_5_Ins_U_TriggerPos`. For counts, see `FOBT_Sta3n528_5_Ins_X_count` which should display automatically.

The site personnel doing **validation** should receive the
"Ins_U_TriggerPos" tables (which will contain PHI, so don't send
outside your station). The **data display** spreadsheet should receive
the data from the "_Count" tables.

**IMPORTANT LINK:** For EPRP data, which is different from e-trigger data, go to http://pm.rtp.med.va.gov/ReportServer_RTP/Pages/ReportViewer.aspx?%2fEBB+Reports%2fCombinedMeasureMaster&rs:Command=Render . (needs to be accessed from within VA network.


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

This has auxiliary scripts to do pretty-printing of SQL source code
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
