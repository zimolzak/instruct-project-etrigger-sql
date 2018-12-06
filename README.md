Diagnostic Test Triggers
========

How do you find (in the database) patients who had a test that shows a possibility of cancer, but who have **not** had timely follow-up?

Bladder
========

Main file *Bladder Cancer Trigger Criteria.docx*

Inclusion

1. over 50 RBC on UA. Loinc, but incompletely expressed.

Exclusion

1. age: within main
2. deceased: within main
3. prior bladder CA dx **ICD** docx
4. cystect, **CPT** **ICD** docx
5. terminal dx. **ICD** within main
6. hospice. **icd** **stop code** within main
7. other bleeding dx. **icd** docx
8. e/o uti. incompletely. "abx order, positive cx, positive other ua components"
9. cysto. **cpt** docx
10. recent gu procedure
    - renal bx **cpt** **icdp** docx
	- prost bx **cpt** **icdp**  docx 
	- renal stone surgery **cpt** **icdp**
	- stent **cpt** **icdp** docx
	- bladder surg **cpt** **icdp** docx


Expected follow up

1. uro visit **stop** docx but not listed at all
2. cysto **cpt** docx
3. imaging **cpt** **icdp** docx
4. renal bx **cpt** **icdp** docx
5. bladd bx **cpt** **icdp** docx
6. bladd surg **cpt** **icdp** docx




Breast
========
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus vel faucibus nunc. Fusce finibus vel felis at ullamcorper. Quisque leo enim, vestibulum vel urna ac, lacinia iaculis lacus. In hac habitasse platea dictumst. Curabitur a magna libero. 

Colorectal
========
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus vel faucibus nunc. Fusce finibus vel felis at ullamcorper. Quisque leo enim, vestibulum vel urna ac, lacinia iaculis lacus. In hac habitasse platea dictumst. Curabitur a magna libero. 


Hepatocellular
========
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus vel faucibus nunc. Fusce finibus vel felis at ullamcorper. Quisque leo enim, vestibulum vel urna ac, lacinia iaculis lacus. In hac habitasse platea dictumst. Curabitur a magna libero. 

Lung
========
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus vel faucibus nunc. Fusce finibus vel felis at ullamcorper. Quisque leo enim, vestibulum vel urna ac, lacinia iaculis lacus. In hac habitasse platea dictumst. Curabitur a magna libero. 
