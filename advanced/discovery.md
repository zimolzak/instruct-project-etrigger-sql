% Cancer Test Result e-Trigger Manual

**Guidance complied by:** Sahar Memon, Andrew Zimolzak, Li Wei, Daniel
Murphy, Hardeep Singh.

**Affiliation:** Michael E. DeBakey Veterans Affairs Medical Center,
  and Baylor College of Medicine. Houston, TX, USA.

**For questions:** [zimolzak@bcm.edu](mailto:zimolzak@bcm.edu) and [Sahar.Memon@bcm.edu](mailto:Sahar.Memon@bcm.edu)

**Date:** October, 2021




# Overview

This manual outlines procedures for implementing e-triggers that
identify missed opportunities in follow-up of 'red flag' findings
suspicious for colorectal or lung cancer. In general, each SQL file
proceeds by:

1. defining the red flags that warrant additional evaluation for
    cancer (often labs or imaging),

2. excluding other explanations for the red flags, such as already
    diagnosed colon cancer, or known cause of bleeding in the upper GI
    tract (often based on ICD/CPT codes),

3. excluding patients for whom follow-up is not deemed necessary, and

4. excluding patients for whom appropriate follow-up was already done
    (e.g., lung biopsy, follow-up imaging, tumor board, usually based
    on stop codes and procedure codes).

As an example, the e-trigger for colorectal cancer identifies patients
with positive fecal blood tests or iron deficiency anemia, and then
excludes patients with any of the following: advanced age, deceased
status, known colon cancer, prior colectomy, terminal illnesses or
hospice care, presence of a known diagnosis that would cause bleeding
in the upper GI tract rather than lower GI tract, and appropriate
colonoscopy or GI referral.

This code is public domain for *anyone* to use as they wish. However,
if you have a published paper based in part on the code, we ask
that you cite:

- [Development and Validation of Trigger Algorithms to Identify Delays in Diagnostic Evaluation of Gastroenterological Cancer.](https://pubmed.ncbi.nlm.nih.gov/28804030/) *Clin Gastroenterol Hepatol.* 2018 Jan;16(1):90-98.
- [Computerized Triggers of Big Data to Detect Delays in Follow-up of Chest Imaging Results.](https://pubmed.ncbi.nlm.nih.gov/27178786/) *Chest.* 2016 Sep;150(3):613-20.
- [Development and Validation of Electronic Health Record-based Triggers to Detect Delays in Follow-up of Abnormal Lung Imaging Findings.](https://pubmed.ncbi.nlm.nih.gov/25961634/) *Radiology.* 2015 Oct;277(1):81-7.
- [Electronic health record-based triggers to detect potential delays in cancer diagnosis.](https://pubmed.ncbi.nlm.nih.gov/23873756/) *BMJ Qual Saf.* 2014 Jan;23(1):8-16.




# How are the e-triggers designed?

The lung and colorectal e-triggers are examples of one type of
e-trigger, which we call a *close the loop e-trigger.* These two
e-triggers answer the question, "How do you find (in the database)
patients who had a test that shows a possibility of cancer, but who
have **not** had timely follow-up?"

Further details about exactly what constitutes exclusion or follow-up
can be found in the e-trigger manual appendices. Non-VA sites should
consult these appendices, as well as SQL code in order to reimplement
the e-triggers in local SQL.




# How to Apply e-Trigger Process at a VA Facility

## Downloading the SQL code

1. The most recent version of the code can be downloaded from
    [github.com/zimolzak/instruct-project-etrigger-sql](https://github.com/zimolzak/instruct-project-etrigger-sql)
    where you can also find additional procedures for setting dates,
    and guidance about which tables to export for final reporting.

2. Before downloading, jot down or copy/paste the text in the bar near
    the top of GitHub, especially the **seven random-looking letters
    and numbers** such as "LWeiBCM Update Lung.sql ... **8c2f54a** 2
    days ago." This will identify the exact version of the code you
    downloaded, for future reference.

3. Click on the SQL file you want above (such as `Lung.sql`).

4. Click on the grey button "Raw" near the top the page that comes up.

5. Use your browser menu to save file to disk (such as "File / Save
    Page As...").




## Setup

This example assumes that you want to retrieve one month worth of
e-trigger counts and patient information.

1. Find the first day of the current month (e.g., if today is Feb 19,
    you rewind to find Feb 1).

2. Subtract two more months from that (so you get Dec 1) if you are
    running `Lung.sql`. Subtract *three months* if you are running
    `Fobt.sql`.

3. Set `sp_start` equal to that (such as `set @sp_start='2019-12-01
00:00:00'`).

4. Set `sp_end` to the end of that month (such as `set
@sp_end='2019-12-31 23:59:59'`).

5. You need to set your sta3n and sta6a. You can do this by
commenting/uncommenting code in lines 100--124 for `Lung.sql`, or
lines 118--146 for `Fobt.sql`.

6. Done! Other variables like `fu_period` can be left as-is.




## Running code

1. Start your operational access to the data warehouse via your usual
    method (e.g., desktop or Citrix connection to SQL Server Management
    Studio software). Login to a SQL server (e.g.
    `vhacdwa01.vha.med.va.gov`) and authenticate (using either
    username such as `vha01\vhabhs...` plus password, or using Windows
    authentication).

2. *Recommended:* Run sections of the SQL file sequentially (for
example, lines 1--198 of `Fobt.sql` cover the first two `INSERT INTO`
operations concerning tables that were newly created), inspecting for
errors.

    *Alternatively:* run the query all at once, inspecting for errors.




## Viewing and validating data

- To view patients with positive lung e-triggers, run the following
SQL, after `Lung.sql` completes: `select * from
#Lung_Sta3n528_3_Ins_U_TriggerPos`

- For lung counts, `Lung_Sta3n528_4_01_Count` should display automatically.

- To view patients with positive colorectal e-triggers, run the
following SQL, after `Fobt.sql` completes: `select * from
#FOBT_Sta3n528_5_Ins_U_TriggerPos`

- For colorectal counts, `FOBT_Sta3n528_5_Ins_X_count` should display
  automatically.

The site personnel doing **validation** should receive the
"Ins_U_TriggerPos" tables (which will contain PHI, so don't send
outside your station). You may review all, or randomly select a few
patients with positive e-trigger, and securely transmit last name and
last 4 of SSN from these patients to the reviewer, who will validate
via CPRS that the sample patients have a positive red flag inside the
time period of interest.

Final note: The VA Corporate Data Warehouse releases patch updates
periodically, and this might require ongoing minor changes/updates to
SQL code, by each site analyst. Standard codes (CPT, ICD, ICDProc,
LOINC, Stop code, etc.) tend to change every year, with addition of new
codes and removal of old codes. These changes require corresponding
updates in the SQL code. Important note here is that you only add new
codes to the SQL; do *not* remove the old ones (this is so the e-trigger
continues to capture usage of both the historical and new codes).




# Further reading (relevant files/attachments)

- Reducing Missed Test Results Change Package
- `Lung.sql` code file (see GitHub)
- `Fobt.sql` code file (see GitHub)


---


