
clear
set more off
cap log close
log using "$Logdir\cr_codelist_qof_cod.txt", replace text

// Program: 		do file to create QOF code list for QRisk3 
// Name:			cr_codelist_qof_cod_aurum.do
// Authors:			Jennifer Davidson has modified Helen Strongman's Gold work 
// Date created: 	10/03/2021

*************************************************************************************************************************
*STEP 1: QOF INCLUSION CODES
*************************************************************************************************************************

/*Source - 
https://digital.nhs.uk/data-and-information/data-collections-and-data-sets/data-collections/quality-and-outcomes-framework-qof/quality-and-outcome-framework-qof-business-rules/quality-and-outcomes-framework-qof-business-rule-v39-2018-2019-baseline-release*/

clear
import excel "J:\EHR-Working\QRISK\qrisk_bundle_aurum\QOF\qof_v39_draft_expanded_cluster_list_for_publication.xlsx", sheet("SNOMED") firstrow allstring
replace SNOMED_Description=lower(SNOMED_Description)

*SMOKING
gen variable="smoke_cat" if Cluster_Description=="Current smoker codes" | Cluster_Description=="Code for ex-smoker" | Cluster_Description=="Smoker codes" | Cluster_Description=="Code for never smoked" | Cluster_Description=="Smoking habit codes"

duplicates tag SNOMED_Code if Cluster_Description=="Current smoker codes" | Cluster_Description=="Code for ex-smoker" | Cluster_Description=="Smoker codes" | Cluster_Description=="Code for never smoked" | Cluster_Description=="Smoking habit codes", gen(dup_smoke_code)

*unclear how the following can be coded to obtain status:
*766931000000106	Smoking status at 12 weeks (observable entity)
*390902009	Smoking status at 4 weeks (observable entity)
*390903004	Smoking status between 4 and 52 weeks (observable entity)
*390904005	Smoking status at 52 weeks (observable entity)
*395177003	Smoking free weeks (observable entity)
*401201003	Cigarette pack-years (observable entity)

loc exterm " "smokes drugs*" "smoking status*" "smoking free weeks*" "cigarette pack-years*" "

foreach word of local exterm {
	replace variable = "" if strmatch(SNOMED_Description, "`word'")
}

gen qofvalue=.
replace qofvalue=2 if strpos(SNOMED_Description, "light") | strpos(SNOMED_Description, "trivial") | strpos(SNOMED_Description, "occasional")
replace qofvalue=3 if strpos(SNOMED_Description, "moderate") 
replace qofvalue=4 if strpos(SNOMED_Description, "heavy")
replace qofvalue=1 if Cluster_Description=="Code for ex-smoker" | strpos(SNOMED_Description, "stopped smoking") | strpos(SNOMED_Description, "ex-") | strpos(SNOMED_Description, "ceased smoking") | strpos(SNOMED_Description, "ex roll-up cigarette smoker")
replace qofvalue=0 if Cluster_Description=="Code for never smoked" | strpos(SNOMED_Description, "non-smoker") | strpos(SNOMED_Description, "never")
replace qofvalue=234 if variable=="smoke_cat" & qofvalue==.
replace qofvalue=234 if SNOMED_Description=="stopped smoking during pregnancy (finding)" | SNOMED_Description=="stopped smoking before pregnancy (finding)"


*ATRIAL FIBRILLATION
replace variable="b_atrialfib" if Cluster_Description=="Atrial fibrillation codes"


*TREATED HYPERTENSION
replace variable="b_treatedhyp" if Cluster_Description=="Hypertension diagnosis codes"


*DIABETES
replace variable="b_type1" if Cluster_Description=="Codes for diabetes" & (strpos(SNOMED_Description, "type i ") | strpos(SNOMED_Description, "type 1") | strpos(SNOMED_Description, "insulin-dependent") | strpos(SNOMED_Description, "autoimmune diabetes") | strpos(SNOMED_Description, "maturity-onset diabetes"))

replace variable="b_type2" if Cluster_Description=="Codes for diabetes" & (strpos(SNOMED_Description, "type ii ") | strpos(SNOMED_Description, "type 2"))

*These diabetes snomed codes are on QOF but can't be classified as type 1 or 2: 8801005, 5368009, 5969009, 51002006, 70694009, 73211009, 75682002, 127012008, 237619009, 284449005, 237601000, 237613005, 408540003, 413183008, 421365002, 426705001, 609572000, 703136005, 112991000000101, 335621000000101


*RHEUMATOID ARTHRITIS
replace variable="b_ra" if Cluster_Description=="Rheumatoid arthritis codes"


*RENAL DISEASE
replace variable="b_renal" if Cluster_Description=="Chronic kidney disease (CKD) codes 3-5"


*BMI
replace variable="bmi" if Cluster_Description=="Body mass index (BMI) codes with an associated BMI value" | Cluster_Description=="Body mass index (BMI) codes without an associated BMI value"


*BP
replace variable="sbp" if Cluster_Description=="Blood pressure (BP) recording codes"
replace variable="" if Cluster_Description=="Blood pressure (BP) recording codes" & strpos(SNOMED_Description, "diastolic") 

*SAVE DATASET
keep if variable!=""
keep variable qofvalue SNOMED_Code
rename SNOMED_Code snomedctconceptid
duplicates drop

tempfile qofcodes
save `qofcodes', replace

use "$Medicaldic.dta", clear
replace term=lower(term)

merge m:1 snomedctconceptid using `qofcodes', keep(match)

keep medcodeid term snomedctconceptid cleansedreadcode qofvalue variable

save "$Datadir\\cr_codelist_qof_cod_aurum.dta", replace
export delimited using "$Textdir\\cr_codelist_qof_cod_aurum.txt", replace
