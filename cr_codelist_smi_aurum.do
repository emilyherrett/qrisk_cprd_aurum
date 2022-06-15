
clear
set more off
cap log close
log using "$Logdir\cr_codelist_smi.txt", replace text

// Program: 		do file to create schizophrenia diagnoses code list for QRisk3 
// Name:			cr_codelist_schizophrenia_aurum.do
// Authors:			Jennifer Davidson has modified Helen Strongman's Gold work which referenced Masao Iwagami previous codelists
/*MORE INFORMATION:		
Based on description in QRISK3 paper (https://www.bmj.com/content/357/bmj.j2099)
i.e. "Diagnosis of severe mental illness (including psychosis, schizophrenia, or bipolar affective disease)"
Note this contradicts the definition in the QRISK3 online tool (https://qrisk.org/three/)
i.e. "this includes schizophrenia, bipolar disorder and moderate/severe depression)"
QOF codes are used as a basis for code list - these are restricted to non-organic psychoses
Remission codes included
Added codes are mainly for history and chapter headings
*/
// Date created: 	10/03/2021

*************************************************************************************************************************
*STEP 1: START WITH QOF INCLUSION CODES
*************************************************************************************************************************

/*Source - 
https://digital.nhs.uk/data-and-information/data-collections-and-data-sets/data-collections/quality-and-outcomes-framework-qof/quality-and-outcome-framework-qof-business-rules/quality-and-outcomes-framework-qof-business-rule-v39-2018-2019-baseline-release*/

clear
import excel "J:\EHR-Working\QRISK\qrisk_bundle_aurum\QOF\qof_v39_draft_expanded_cluster_list_for_publication.xlsx", sheet("SNOMED") firstrow allstring
keep if Cluster_Description=="Code for in remission from serious mental illness" | Cluster_Description=="Psychosis and schizophrenia and bipolar affective disease codes"
drop if SNOMED_Description=="Organic delusional disorder (disorder)" // to meet Helen's notes of restricted to non-organic psychoses 
keep SNOMED_Code SNOMED_Description
rename SNOMED_Code snomedctconceptid
duplicates drop

tempfile qofsmicodes
save `qofsmicodes', replace

use "$Medicaldic.dta", clear
replace term=lower(term)

merge m:1 snomedctconceptid using `qofsmicodes', keep(match master)

gen _qofcode=0
replace _qofcode=1 if _merge==3
drop _merge


*************************************************************************************************************************
*STEP 2: INCLUSION WORD SEARCH OF READ CODE DICTIONARY
*************************************************************************************************************************

*words selected from read terms matching QRISK read code search above

loc interm " "*schizophren*" "*manic*disorder*" "*manic*episode*" "*psychosis*" "*bipolar*" "*manic*disorder*" "*paranoid*state*" "*paranoia*" "*schizotyp*" "*psychoses*" "*manic*depress*" "

gen smi=.
foreach word of local interm {
	replace smi = 1 if strmatch(term, "`word'")
}

*************************************************************************************************************************
*STEP 3: EXCLUSION WORD SEARCH OF READ CODE DICTIONARY
*************************************************************************************************************************

loc exterm " "*fh:*" "family*history*" "*puerperal*" "*infantile*" "*child*" "*mother*" "*postnatal*" "*hypomanic*" "*psychogenic*" "*senile*" "*senility*" "*epilepsy*" "*epileptic*" "*korsak*" "*alcohol*" "*infective*" "*arteriosclerotic*" "*drug*" "*hallucinogen*" "*sedative*" "*pre*byophrenic*" "*transient*" "*assoc* member*" "monitoring*" "*signpost*" "*clinical information system*" "possible*" "no evidence of*" "obsessional compulsive*" "mental * behav dis due to*" "face caras*" "*disintegrative*" "*major depressive episode*without psychosis" "*major depressive episode*no psychosis" "[x]organic psychos*" "* org* psychos*" "org* psychos*" "*cognitive behavio*ral therapy*" "*paranoid organic state" "[x]organic * disorder" "organic * disorder" "

foreach word of local exterm {
	replace smi = . if strmatch(term, "`word'")
}

**note list of non QOF codes is longer in Aurum than Gold due to fact there are so many more detailed codes in Aurum than Gold


*************************************************************************************************************************
*STEP 4: DROP ALL TERMS NOT CAPTURED BY SEARCH TERMS
*************************************************************************************************************************
keep if smi==1

*drop redundant variables and order variables
keep medcodeid term snomedctconceptid cleansedreadcode _qofcode smi


***********************************************************************************************************************
*STEP 5: SAVE LIST OF CODES AS STATA FILE 
*************************************************************************************************************************
save "$Datadir\cr_codelist_smi_aurum", replace
export delimited using "$Textdir\\cr_codelist_smi_aurum.txt", replace
capture log close

