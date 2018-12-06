Diagnostic Test Triggers
========

How do you find (in the database) patients who had a test that shows a possibility of cancer, but who have **not** had timely follow-up?

List of cancers currently
--------

- bladder
- breast
- colorectal
- hepatocellular
- lung

Bladder
========

Main file *Bladder Cancer Trigger Criteria.docx*

Inclusion

1. over 50 RBC on UA. Loinc, but incompletely expressed.

Exclusion

1. age
2. deceased
3. prior bladder CA dx **ICD** docx
4. cystect, **CPT** **ICD** docx
5. terminal dx. **ICD** within main
6. hospice. **icd** **stop code** within main
7. other bleeding dx. **icd** docx
8. e/o uti. incompletely. "abx order, positive cx, positive other ua components"
9. cysto. **cpt**
10. recent gu procedure. **cpt** docx


Expected follow up

1. uro visit **stop** docx
2. cysto **cpt**
3. imaging **cpt** **icdp** docx
4. renal bx **cpt** **icdp** docx
5. bladd bx **cpt** **icdp** docx
6. bladd surg **cpt** **icdp** docx

- prostate bx **cpt** **icdp** mentioned in docx but not main.
- renal stone surgery **cpt** **icdp**
- stent **cpt** **icdp**

