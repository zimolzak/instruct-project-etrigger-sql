InSTRuCt Study E-Trigger Manual
========

Sahar Memon, Andrew Zimolzak, Li Wei

VA Houston / Baylor College of Medicine

October, 2021

Overview
========

This manual outlines procedures for VA facilities participating in the
InSTRuCt project and enables their data-analysts/informatics personnel
to run electronic triggers (e-triggers) on the data warehouse. The SQL
code for the InSTRuCt study comprises e-triggers to identify missed
opportunities in follow-up of 'red flag' findings suspicious for several
cancers, including bladder, breast, colorectal (FOBT and IDA),
hepatocellular, and lung. In general, each SQL file proceeds by--

1.  defining the red flags that warrant additional evaluation for cancer
    (often labs or imaging),

2.  excluding other explanations for the red flags, such as already
    diagnosed colon cancer, or known cause of bleeding in the upper GI
    tract (often based on ICD/CPT codes),

3.  excluding patients for whom follow-up is not deemed necessary, and

4.  excluding patients for whom appropriate follow-up was already done
    (usually based on stop codes and procedure codes).

As an example, the e-trigger for colorectal cancer identifies patients
with positive fecal blood tests, and then excludes patients with any of
the following: advanced age, deceased status, known colon cancer, prior
colectomy, terminal illnesses or hospice care, presence of a known
diagnosis that would cause bleeding in the upper GI tract rather than
lower GI tract, and appropriate colonoscopy or GI referral.

How to Apply e-Trigger Process at Your Facility
===============================================

1.  Start your operational access to the data warehouse via your usual
    method (e.g. desktop or Citrix connection to SQL Server Management
    Studio software). Login to a SQL server
    (e.g. `vhacdwa01.vha.med.va.gov`) and authenticate (using either
    username such as `vha01\vhabhs…` plus password, or using Windows
    authentication).

2.  The most recent version of the code can be downloaded from
    github.com/zimolzak/instruct-project-etrigger-sql where you can also
    find additional procedures for setting dates, and guidance about
    which tables to export for final reporting.

3.  Most changes to adapt the code to the operational database and
    schema names have been performed automatically (marked by comments
    reading "`–altered`"). However, you will need to make further
    one-time edits to make the code function in your site's local
    database environment. The SQL code as provided uses placeholder
    names of `MyDB` and `MySchema` schema for outputs. Replace these
    with any database/schema combination where you have write
    permissions. *You may have to request write permissions* if you have
    never been granted access to write out an intermediate table.

4.  For the final project, you will be limiting queries to approximately
    one month of data at a time, and you will be running only 1--3
    triggers depending on your facility's choice. Lines of code contain
    variable assignment statements that allow you to customize the query
    date ranges to your local station, such as:

        set @VISN=12
        --set @Sta3n=580 -- -1 all sta3n
        set @run_date=getdate()
        set @sp_start='2020-01-01 00:00:00'
        set @sp_end='2020-01-31 23:59:59'

5.  Recommended: Run sections of the SQL file sequentially (for example,
    lines 1--132 of `Fobt.sql` cover the first two `INSERT INTO`
    operations concerning tables that were newly created), inspecting
    for errors. Alternatively: run query all at once, inspecting for
    errors. Inspection for errors should include not only SQL errors,
    but data validation through a few record reviews performed by the
    site champion. (Randomly select a few patients with positive
    e-trigger, and securely transmit last name and last 4 of SSN from
    these patients to the site champion, who will validate via CPRS that
    the sample patients have a positive red flag inside the time period
    of interest.)

6.  ONLY when your site enters the "action" phase: translate output
    tables into reports as requested by participants in the InSTRuCt
    virtual breakthrough series (e.g. leadership, laboratory managers).
    The most valuable tables are `Lung_Sta3n528_3_Ins_U_TriggerPos`
    (contains PHI, for your site's internal use only) and
    `Lung_Sta3n528_4_01_Count` (aggregate data only, suitable to
    copy/paste into Excel sheet for display on the monthly phone calls).

Estimated Analyst Time Commitment
=================================

Initial set up (one-time tasks)
-------------------------------

**Global modifications to adapt e-triggers to the operational Data
Warehouse: complete**

The e-triggers were developed on the Corporate Data Warehouse using a
research database and schema. Even though research data and operational
data are both hosted on the CDW, their data schemas are not identical.
In cooperation with cluster 1, we have made changes to the SQL code, and
it now runs on the operational schema.

**All sites: Local modifications to the SQL code: 40 person-hours**

With runnable triggers, each site might need to make changes to the SQL
code which are specific to their facility. The typical changes would be
on the data server name, database name, and the interpretations of the
test/image values. For example, for an abnormal result, some sites mark
it as 'A', some sites mark it as '+', some sites use descriptions as
'many', 'TNTC', or ranges such as '\>100', '50-2000', etc. As another
example, some sites may use a '+' to mark a normal and '++' to mark an
abnormal. We recommend that the site analyst work with local clinical
groups to best customize the test/image interpretations. We predict that
the analyst and a clinician will need to get together to review, parse,
and categorize some lab/test results. Another place that might need
attention is the lab test and procedure codes (CPT, ICDProc, LOINC
etc...). They are standard codes, but if your site uses them in
different flavors you might need do some customization. Our estimated
time dedicated to this task will be 40 person-hours of analyst time. The
study team (VA Houston) will also provide guidance to the pioneer site
in this process.

On-going tasks for the duration of the site's participation
-----------------------------------------------------------

**Run SQL code to retrieve data: 17 minutes per trigger per month**

The time between pressing the 'Run' button to retrieve data output (if
run monthly on a single site) is a few minutes if no errors are
encountered. This also depends on the size of the site, network
speed/traffic, data servers' performance, and their concurrent load.
Here is the breakdown based on 6 months: 17 minutes x 6 time points x 2
triggers = 3.4 computer hours.

**Ongoing modifications to SQL code: 40-person hours per year**

The CDW releases patch updates periodically, and this might require
ongoing minor changes/updates to SQL code, by each site analyst.
Standard codes (CPT, ICD, ICDProc, LOINC, Stopcode, etc.) tend to change
every year, with addition of new codes and removal of old codes. These
changes require corresponding updates in the SQL code. Important note
here is that you only add new codes to the SQL, do NOT remove the old
ones (this is so the e-trigger continues to capture usage of both the
historical and new codes).

Summary
-------

40 person-hours one-time effort.\
40 person-hours per year ongoing effort.\
3 hours computer time during 6 month intervention.

Further reading
===============

InSTRuCt project documents
--------------------------

*Reducing Missed Test Results Change Package*\
*InSTRuCt Study FAQ*, also known as `IIR FAQ 5.6.19.docx`\
*Standard Operating Procedure*, also known as
`SOP for INSTRUCT_4.5.19.pdf`\
*InSTRuCt Project Overview*, also known as
`IIR Project Charter_7.12.19.pdf`

List of auxiliary files documenting the SQL code, November 2018
---------------------------------------------------------------

    Bladder Cancer Trigger Criteria.docx
    Bladder cancer trigger- ICD 9 to ICD 10 codes.docx
    Breast Cancer Trigger Criteria.docx
    Breast cancer- ICD 9 to ICD 10 codes.docx
    Colorectal Cancer Trigger Criteria.docx
    Colorectal Cancer- ICD 9 to ICD 10 codes.docx
    Hepatocellular Carcinoma Trigger Criteria.doc
    Hepatocellular Carcinoma- ICD 9 to ICD 10 codes.docx
    Lung Cancer Trigger Criteria.doc
    Lung cancer Trigger- ICD 9 to ICD 10 codes.docx
    bladder cancer ICD andCPT codes.docx
