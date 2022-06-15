
clear
set more off
capture log close
log using "$Logdir\cr_codelist_fh_cvd_60.txt", replace text

/*Program:  	do file to select code list for family history of CVD
*Name:	  		cr_codelist_fh_cvd_60_aurum.do
*Authors:  		Jennifer Davidson has modified Helen Strongman's Gold work
*Date created:  09/08/2019
*/

use "$Medicaldic.dta", clear
replace term=lower(term)

*************************************************************************************************************************
*STEP 1: DEFINE SEARCH TERMS
*************************************************************************************************************************
loc interm " "*fh*cardio*" "*family history*cardio*" "*fh*myocardial*infarct*" "*family history*myocardial*infarct*" "*fh*heart*dis*" "*family history*heart*dis*" "*fh*angina*" "*family history*angina*" " 

*************************************************************************************************************************
*STEP 2: WORD SEARCH OF READ CODE DICTIONARY
*************************************************************************************************************************

*create a marker for useful observations
gen marker=.

foreach word in `interm'{
	replace marker=1 if strmatch(term, "`word'")
}


*************************************************************************************************************************
*STEP 3: CODE SEARCH OF READ CODE DICTIONARY FOR TERMS NOT IDENTIFIED IN STEP 2
*************************************************************************************************************************
loc incode "12C*"

foreach word in `incode'{
  replace marker=1 if strmatch(cleansedreadcode, "`word'")
  }


*************************************************************************************************************************
*STEP 4: FLAG ALL CODES WHICH MATCH CONCEPT ID FOR CODES IDENTIFIED IN STEP 2 & 3
*************************************************************************************************************************
sort snomedctconceptid marker
by snomedctconceptid: replace marker=marker[1]  
 
 
*************************************************************************************************************************
*STEP 5: DROP ALL TERMS NOT CAPTURED BY SEARCH TERMS
*************************************************************************************************************************
keep if marker==1

*************************************************************************************************************************
*STEP 6: FURTHER INCLUSION TERMS TO MAKE SEARCH MORE SPECIFIC
*************************************************************************************************************************
*only keep codes which identify family history <60
local incterm " "*<*6*" "*<*5*" "*less*than*6*" "*less*than*5*" "

gen familychd=0
foreach word in local `incterm' {
replace familychd = 1 if strmatch(term, "`word'")
}

keep if familychd==1

*************************************************************************************************************************
*STEP 7: EXCLUDE ANY REMAINING UNWANTED CODES FOR THIS LIST
*************************************************************************************************************************
*remove codes that rated by clinician as not relevant to the list
local exterm " "no fh*" "

foreach word in `exterm' {
replace familychd=. if strmatch(term, "`word'")
}

*drop redundant variables and order variables
keep medcodeid term snomedctconceptid cleansedreadcode familychd

*************************************************************************************************************************
*STEP 8: SAVE LIST OF CODES AS STATA FILE
*************************************************************************************************************************
save "$Datadir\\cr_codelist_fhcvd60_aurum.dta", replace
export delimited using "$Textdir\\cr_codelist_fhcvd60_aurum.txt", replace
capture log close

