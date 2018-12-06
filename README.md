Diagnostic Test Triggers
========

How do you find (in the database) patients who had a test that shows a possibility of cancer, but who have **not** had timely follow-up?

Bladder
========

Main file *Bladder Cancer Trigger Criteria.docx*. Has an external docx with lists of codes. Does have ICD9-ICD-10 docx too.

Inclusion

1. over 50 RBC on UA. Loinc, but incompletely expressed.

Exclusion

1. age: within main
2. deceased: within main
3. prior bladder CA dx *ICD* docx
4. cystect, *CPT* *ICD* docx
5. terminal dx. *ICD* within main
6. hospice. *icd* *stop code* within main
7. other bleeding dx. *icd* docx
8. e/o uti. **incompletely.** "abx order, positive cx, positive other ua components"
9. cysto. *cpt* docx
10. recent gu procedure
    - renal bx *cpt* *icdp* docx
    - prost bx *cpt* *icdp*  docx 
    - renal stone surgery *cpt* *icdp*
    - stent *cpt* *icdp* docx
    - bladder surg *cpt* *icdp* docx


Expected follow up

1. uro visit *stop* docx but **not listed at all**
2. cysto *cpt* docx
3. imaging *cpt* *icdp* docx
4. renal bx *cpt* *icdp* docx
5. bladd bx *cpt* *icdp* docx
6. bladd surg *cpt* *icdp* docx


Breast
========

No external docx w/ pure code lists. Does have ICD9-ICD10 docx.

Inclusion

1. Abnormal mammo. List of BIRADS. *cpt* *icd* main

Exclusion

1. age: main
2. deceased: main
3. previous breast ca dx: *icd* main
4. terminal illness: *icd* main
5. hospice or palliative: *icd* *stop* main

Expected follow up

1. repeat mammo: *cpt* *icd*
2. breast bx: *cpt* *icd*
3. breast us: *cpt*
4. breast mri: *cpt* 
5. breast surg: *cpt* *icdp*
6. onc referral completed: *stop*


Colorectal
========
Inclusion

1. IDA, defined by hgb level and mcv and ferritin. *loinc* and "search by test name" **incomplete**
2. Positive FOBT or FIT. *loinc*.

Exclusion

1. age: main
2. deceased: main
3. prior colo CA dx: *icd*
4. total colec: *cpt/icdp*
5. terminal: *icd*
6. hospice: *icd stop*
7. e/o UGIB: *icd*
8. had a cscope: *cpt/icdp*

Exclusion for IDA only

1. other bleed src: *icd*
2. preg: *icd*
3. thalassemia: *icd*

Expected follow up

1. cscope done: *cpt/icdp*
2. GI referral complete: *stop*




Hepatocellular
========
Inclusion

1. AFP level. *loinc*, test name **incomplete**

Exclusion

1. age: main
2. deceased: main
3. recent hcc dx: *icd*
4. terminal: *icd*
5. hospice: *icd stop*
6. gonadal: *icd*
7. preg: *icd* *loinc* may be **incomplete**


Expected follow up

1. hepatol referral: *stop* **incomplete**
2. GI referral: *stop* **incomplete**
3. surg refer: *stop* **incomplete**
4. onc refer: *stop* **incomplete**
5. transplant refer: *stop* **incomplete**
6. liver bx: *cpt/icdp*
7. liver img: *cpt/icdp*
8. liver surg: *cpt/icdp*
9. liver tumor embol: *cpt*
10. tumor board: *stop* and *note title* **incomplete**


Lung
========
Inclusion

1. abnormal cxr. *cpt* "flagged as suspicious," and "primary diagnostic code flag." **incomplete? not sure.**
2. abnl chest CT. *cpt* "flagged as suspicious," and "primary diagnostic code flag." **incomplete? not sure.**

Exclusion

1. age: main
2. deceased: main
3. recent lung ca dx: *icd*
4. terminal: *icd*
5. hospice: *icd* *stop*
6. tuberculosis: *icd*

Expected follow up

1. pulm visit: *stop*
2. thoracic visit: *stop*
3. lung bx: *cpt* *icdp*
4. bronch: *cpt* *icdp*
5. lung surg: *cpt* *icdp*
6. repeat cxr: *cpt*
7. repeat ct: *cpt*
8. PET or PET/CT: *cpt*
9. tumor board: *stop* and *note title* **incomplete**
