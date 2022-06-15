
clear
set more off
capture log close
log using "$Logdir\cr_codelist_ED.txt", replace text

*Program:   do file to select code list for erectile dysfunction
*Name:	  cr_codelist_ED.do
*Authors:  Jennifer Davidson has modified Emily Herrett's GOld work
*Date created:  18/02/2019

use "$Medicaldic.dta", clear
replace term=lower(term)

*************************************************************************************************************************
*STEP 1: DEFINE SEARCH TERMS
*************************************************************************************************************************
loc interms " "*erectile*" "*impoten*" "*erection*" "

*************************************************************************************************************************
*STEP 2: WORD SEARCH OF READ CODE DICTIONARY
*************************************************************************************************************************

*create a marker for useful observations
gen erectdys=.

foreach word in `interms'{
		replace erectdys = 1 if strmatch(term, "`word'")
}


*************************************************************************************************************************
*STEP 3: EXCLUDE UNWANTED TERMS TO MAKE SEARCH MORE SPECIFIC
*************************************************************************************************************************

local exterms " "*does not complain*" "*screen*" "*piloerection*" "*abnormal angle*" "*painful*" "*hardness*" "*education*" "*pathologic*" " 

foreach word in `exterms' {
replace erectdys = . if strmatch(term, "`word'")
}

*************************************************************************************************************************
*STEP 4: FLAG ALL CODES WHICH MATCH CONCEPT ID FOR CODES IDENTIFIED IN STEP 2 & 3
*************************************************************************************************************************

gen erectdys1=erectdys
sort snomedctconceptid erectdys1
by snomedctconceptid: replace erectdys1=erectdys1[1] 

*after review none of concept ID matches wanted

*************************************************************************************************************************
*STEP 5: DROP ALL TERMS NOT CAPTURED BY SEARCH TERMS
*************************************************************************************************************************
keep if erectdys==1

*drop redundant variables and order variables
keep medcodeid term snomedctconceptid cleansedreadcode erectdys

*************************************************************************************************************************
*STEP 6: SAVE LIST OF CODES AS STATA FILE
*************************************************************************************************************************
save "$Datadir\\cr_codelist_ED_aurum.dta", replace
export delimited using "$Textdir\\cr_codelist_ED_aurum.txt", replace
capture log close
