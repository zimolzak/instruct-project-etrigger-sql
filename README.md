Diagnostic Test Triggers
========

How do you find (in the database) patients who had a test that shows a possibility of cancer, but who have **not** had timely follow-up?


Bladder
========

Main file *Bladder Cancer Trigger Criteria.docx*. Has an external docx with lists of codes. Does have ICD9-ICD-10 docx too.

Inclusion

1. over 50 RBC on UA. **lab_hematuria_incomp** Loinc, but incompletely expressed.

Exclusion

1. age: within main *age_blad*
2. deceased: within main **deceased**
3. prior bladder CA dx *ICD_blad_ca* docx
4. cystect, *Proc_cystec* docx
5. terminal dx. **ICD_term** within main
6. hospice. **icd_stopcode_hospice** within main
7. other bleeding dx. *icd_stone* docx
8. e/o uti. **abx_lab_uti_incomp** "abx order, positive cx, positive other ua components"
9. cysto. **proc_cysto** docx
10. recent gu procedure
    - renal bx **proc_renal_bx** docx
    - prost bx *proc_prost_bx*  docx 
    - renal stone surgery *proc_stone*
    - stent *proc_stent* docx
    - bladder surg **proc_blad_surg** docx

Expected follow up

1. uro visit **stopcode_uro_incomp**
2. cysto **proc_cysto** docx
3. imaging *proc_blad_imaging* docx
4. renal bx **proc_renal_bx** docx
5. bladd bx *proc_blad_bx* docx
6. bladd surg **proc_blad_surg** docx

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

1. Abnormal mammo. List of BIRADS. **proc_mammo_poss_incomp** main. How do you parse BIRADS?

Exclusion

1. age: *age_breast*
2. deceased: **deceased**
3. previous breast ca dx: *icd_breast_ca* main
4. terminal illness: **icd_term** main, note same as bladder
5. hospice or palliative: **icd_stopcode_hospice** main, same as blad

Expected follow up

1. repeat mammo: **proc_mammo_poss_incomp**
2. breast bx: *proc_breast_bx*
3. breast us: *proc_breast_us*
4. breast mri: *proc_breast_mri* 
5. breast surg: *proc_breast_surg*
6. onc referral completed: **stopcode_onc**

Definitions
--------
```
icd_term := (14 rows)
icd_stopcode_hospice := (v66.7, 351, 353)

proc_mammo_poss_incomp :=(CPT: 77051, 77052, 77053, 77054, 77055, 77056, 77057, 76082, 76083, 76085, 76090, 76092, 
G0202, G0204, G0206, G8111, G8112, G8113, S8080, S8075, 77058, 77059, 77061, 77062, 77063. 
ICD: 793.80, 793.81, 793.82, 793.89)
```


Colorectal
========
Inclusion

1. IDA, defined by hgb level and mcv and ferritin. **lab_ida_incomp** and "search by test name"
2. Positive FOBT or FIT. *loinc_fobt_fit*.

Exclusion

1. age: *age_colo*
2. deceased: **deceased**
3. prior colo CA dx: *icd_colo_ca*
4. total colec: *proc_colectomy*
5. terminal: **icd_term**
6. hospice: **icd_stopcode_hospice**
7. e/o UGIB: *icd_ugib*
8. had a cscope: **proc_cscope**

Exclusion for IDA only

1. other bleed src: *icd_blood_loss_cause*
2. preg: *icd_preg_vcodes*
3. thalassemia: *icd_thal*

Expected follow up

1. cscope done: **proc_cscope**
2. GI referral complete: **stopcode_gi**

Definitions
--------
`proc_cscope := (CPT: 	44394, 45378-45387, 44387, 45355, 45391, 45392, 44391, 44392, 44388, 44389. ICD-9: 45.23)`


Hepatocellular
========
Inclusion

1. AFP level. **lab_afp_incomp**, test name

Exclusion

1. age: *age_hcc*
2. deceased: **deceased**
3. recent hcc dx: *icd_hcc*
4. terminal: **icd_term_hcc**
5. hospice: **icd_stopcode_hospice**
6. gonadal: *icd_gonadal*
7. preg: *icd_preg* **lab_hcg_poss_incomplete**

Expected follow up

1. hepatol referral: **stopcode_hep_incomp**
2. GI referral: *stop* **stopcode_gi**
3. surg refer: **stopcode_surg_incomp**
4. onc refer: **stopcode_onc**
5. transplant refer: **stopcode_transp_incomp**
6. liver bx: *proc_liver_bx*
7. liver img: *proc_liver_img*
8. liver surg: *proc_liver_surg*
9. liver tumor embol: *proc_liver_embol*
10. tumor board: **stopcode_notetitle_tumorboard_incomp**

Definitions
--------
```
stopcode_gi := Primary Stop Code 307,33
stopcode_onc := ????
```


Lung
========
Inclusion

1. abnormal cxr. **proc_cxr_poss_incomp** "flagged as suspicious," and "primary diagnostic code flag."
2. abnl chest CT. **proc_chest_ct_poss_incomp** "flagged as suspicious," and "primary diagnostic code flag."

Exclusion

1. age: *age_lung*
2. deceased: **deceased**
3. recent lung ca dx: *icd_lung_ca*
4. terminal: **icd_term_lung**
5. hospice: **icd_stopcode_hospice**
6. tuberculosis: *icd_tb*

Expected follow up

1. pulm visit: *stopcode_pulm*
2. thoracic visit: *stopcode_thoracic*
3. lung bx: *proc_lung_bx*
4. bronch: *proc_bronch*
5. lung surg: *proc_lung_surg*
6. repeat cxr: **proc_cxr_poss_incomp**
7. repeat ct: **proc_chest_ct_poss_incomp**
8. PET or PET/CT: *cpt_pet*
9. tumor board: **stopcode_notetitle_tumorboard_incomp**

Definitions
--------
```
stopcode_notetitle_tumorboard_incomp := (316 and Tumor Board Conference Note Title)
proc_cxr_poss_incomp := (9 CPT codes)
proc_chest_ct_poss_incomp := (4 CPT codes)
```
