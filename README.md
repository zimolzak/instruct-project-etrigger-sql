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
2. deceased: within main *deceased*
3. prior bladder CA dx *ICD_blad_ca* docx
4. cystect, *Proc_cystec* docx
5. terminal dx. *ICD_term* within main
6. hospice. *icd_stopcode_hospice* within main
7. other bleeding dx. *icd_stone* docx
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

Definitions
--------
```
proc_cysto := (27 lines)
proc_renal_bx := (8 lines)
proc_blad_surg := (7 + 10 + 11 + 2 + 4 + 2 + 3 + 9)
```


Breast
========

No external docx w/ pure code lists. Does have ICD9-ICD10 docx.

Inclusion

1. Abnormal mammo. List of BIRADS. *proc_mammo* main

Exclusion

1. age: *age_breast*
2. deceased: *deceased*
3. previous breast ca dx: *icd_breast_ca* main
4. terminal illness: *icd_term* main, note same as bladder
5. hospice or palliative: *icd_stopcode_hospice* main, same as blad

Expected follow up

1. repeat mammo: *proc_mammo*
2. breast bx: *proc_breast_bx*
3. breast us: *proc_breast_us*
4. breast mri: *proc_breast_mri* 
5. breast surg: *proc_breast_surg*
6. onc referral completed: *stopcode_onc*

Definitions
--------
```
icd_term := (14 rows)
icd_stopcode_hospice := (v66.7, 351, 353)

proc_mammo :=(CPT: 77051, 77052, 77053, 77054, 77055, 77056, 77057, 76082, 76083, 76085, 76090, 76092, 
G0202, G0204, G0206, G8111, G8112, G8113, S8080, S8075, 77058, 77059, 77061, 77062, 77063. 
ICD: 793.80, 793.81, 793.82, 793.89)
```


Colorectal
========
Inclusion

1. IDA, defined by hgb level and mcv and ferritin. *loinc* and "search by test name" **incomplete**
2. Positive FOBT or FIT. *loinc_fobt_fit*.

Exclusion

1. age: *age_colo*
2. deceased: *deceased*
3. prior colo CA dx: *icd_colo_ca*
4. total colec: *proc_colectomy*
5. terminal: *icd_term*
6. hospice: *icd_stopcode_hospice*
7. e/o UGIB: *icd_ugib*
8. had a cscope: *proc_cscope*

Exclusion for IDA only

1. other bleed src: *icd_blood_loss_cause*
2. preg: *icd_preg*
3. thalassemia: *icd_thal*

Expected follow up

1. cscope done: *proc_cscope*
2. GI referral complete: *stopcode_gi*

`proc_cscope := (CPT: 	44394, 45378-45387, 44387, 45355, 45391, 45392, 44391, 44392, 44388, 44389. ICD-9: 45.23)`


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
