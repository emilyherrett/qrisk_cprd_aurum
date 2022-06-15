
capture log close
log using "$Logdir\cr_codelist_lupus_aurum.txt", replace text

/*Program:   do file to select code list for Systemic lupus erythematosus
*Name:	  cr_codelist_SLE_aurum.do
*Authors:  Jennifer Davidson has copied do file from J:\EHR-Working\HelenS\Excess_mortality\codelists\dofiles\cr_codelist_lupus_aurum written by Helena Carreira with links & format updated to QRISK3 & added review on SNOMED concept matches
*Date created:  19/02/2021
*/


use "$Medicaldic.dta", clear
replace term=lower(term)


*************************************************************************************************************************
*STEP 1: DEFINE SEARCH TERMS
*************************************************************************************************************************

loc interm " "*lupus*" "* sle *" " 


*************************************************************************************************************************
*STEP 2: WORD SEARCH OF READ CODE DICTIONARY
*************************************************************************************************************************

*create a marker for useful observations
gen lupus=.

foreach word in `interm'{
		replace lupus = 1 if strmatch(term, "`word'")
}

*************************************************************************************************************************
*STEP 3: EXCLUDE UNWANTED TERMS TO MAKE SEARCH MORE SPECIFIC
*************************************************************************************************************************

loc exterm " "*tuberculo*" "*cells*" "*anticoagulant*" "*inhibitor*" "*pernio*" "*test*" "*exedens*" "lupus insensitive activated partial thromboplastin time" "synovial fluid: lupus erythematosus cells" "lupus miliaris disseminatum faciei" "

foreach word in `exterm' {
replace lupus = . if strmatch(term, "`word'")
}

************************************************************************************************************************
*STEP 4: FLAG ALL CODES WHICH MATCH CONCEPT ID FOR CODES IDENTIFIED IN STEP 2 & 3
*************************************************************************************************************************

gen lupus_concept=lupus
sort snomedctconceptid lupus_concept
by snomedctconceptid: replace lupus_concept=lupus_concept[1] 
*from review don't want to include any of these

	
*************************************************************************************************************************
*STEP 5: DROP ALL TERMS NOT CAPTURED BY SEARCH TERMS
*************************************************************************************************************************
keep if lupus==1

*drop redundant variables and order variables
keep medcodeid term snomedctconceptid cleansedreadcode lupus


*************************************************************************************************************************
*STEP 6: SAVE LIST OF CODES AS STATA FILE
*************************************************************************************************************************
save "$Datadir\\cr_codelist_SLE_aurum.dta", replace
export delimited using "$Textdir\\cr_codelist_SLE_aurum.txt", replace
capture log close
