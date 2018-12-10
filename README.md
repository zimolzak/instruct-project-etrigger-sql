Diagnostic Test Triggers
========

How do you find (in the database) patients who had a test that shows a possibility of cancer, but who have **not** had timely follow-up?

Bladder
========

Main file *Bladder Cancer Trigger Criteria.docx*. Has an external docx with lists of codes. Does have ICD9-ICD-10 docx too.

Inclusion

1. over 50 RBC on UA. Loinc, but incompletely expressed.

Exclusion

1. age: within main *age_blad*
2. deceased: within main *dec_blad*
3. prior bladder CA dx *ICD_blad* docx
4. cystect, *Proc_cystec* docx
5. terminal dx. *ICD_term* within main
6. hospice. *icd_hosp* *stop_hosp* within main
7. other bleeding dx. *icd_bleed* docx
8. e/o uti. **incompletely.** "abx order, positive cx, positive other ua components"
9. cysto. *proc_cysto* docx
10. recent gu procedure
    - renal bx *proc_renal_bx* docx
    - prost bx *proc_prost_bx*  docx 
    - renal stone surgery *proc_stone*
    - stent *proc_stent* docx
    - bladder surg *proc_blad_surg* docx

Expected follow up

1. uro visit *stop* docx but **not listed at all**
2. cysto *proc_cysto* docx
3. imaging *proc_blad_imaging* docx
4. renal bx *proc_renal_bx* docx
5. bladd bx *proc_blad_bx* docx
6. bladd surg *proc_blad_surg* docx

`proc_cysto := (27 lines)`

`proc_renal_bx := (8 lines)`

`proc_blad_surg := (7 + 10 + 11 + 2 + 4 + 2 + 3 + 9)`

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
