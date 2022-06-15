
clear
set more off
capture log close
log using "$Logdir\cr_codelist_hiv.txt", replace text

// Program: 		do file to create HIV diagnoses code list for QRisk3 
// Name:			cr_codelist_hiv_aurum.do
// Authors:			Jennifer Davidson has modified Helen Strongman's Gold work 
// Date created: 	19/02/2021

use "$Medicaldic.dta", clear
replace term=lower(term)

*************************************************************************************************************************
*STEP 1: DEFINE SEARCH TERMS
*************************************************************************************************************************
loc interm " "* hiv *" "hiv *" "*hiv dis*" "*hiv positive*" "*human*immuno*" "*deficiency*virus*" "* aids *" "aids *" "* aids" "aids" "*acquired*immun*" "*deficiency*syndrome*" "*pneumocystis*carinii*" "

*************************************************************************************************************************
*STEP 2: WORD SEARCH OF READ CODE DICTIONARY
*************************************************************************************************************************

*create a marker for useful observations
gen hiv=.

foreach word in `interm' {
		replace hiv = 1 if strmatch(term, "`word'")
}


*************************************************************************************************************************
*STEP 3: CODE SEARCH OF READ CODE DICTIONARY FOR TERMS NOT IDENTIFIED IN STEP 2
*************************************************************************************************************************
loc incode " "66j*" "A788*" "

foreach word in `incode'{
  replace hiv = 1 if strmatch(cleansedreadcode, "`word'")
  }


*************************************************************************************************************************
*STEP 4: EXCLUDE UNWANTED TERMS TO MAKE SEARCH MORE SPECIFIC
*************************************************************************************************************************

local exterm " "*aids*operator*" "*screening*" "*contact*" "*prevention*" "*test*" "*exposure*prophyl*" "*daily*" "*nurse*" "*iodine*" "*vitamin*" "*glut1*" "*glucose*transporter*" "*risk*behaviour*" "*fear*of*" "*development*aids*" "*negative*" "*family*history*" "*counsel*ing*" "*monitoring*" "*status*" "*risk*" "*use of aids*" "*mobility aids*" "*using aids*" "*human*immunoglobulin*" "use of * aids" "mobili*ing without aids" "iron deficiency*" "*handicapped*" "*hearing aids" "*communication aids" "*exposure*" "*discussion*" "*assay*" "*antibody*" "*antigen*" "*pcr*" "*igg*" "*polymerase chain reaction*" "*serology*" "*health check serv* declin*" "*carrier*" "shhapt (sexual health and hiv activity property type) codes" "*mother*" "coagulation factor*" "eczema*" "neuropathy*" "pneumocystis carinii if" "vasopressin*" "

foreach word in `exterm' {
replace hiv = . if strmatch(term, "`word'")
}

*results checked against own HIV codelist from PhD project

*************************************************************************************************************************
*STEP 5: FLAG ALL CODES WHICH MATCH CONCEPT ID FOR CODES IDENTIFIED IN STEP 2 & 3
*************************************************************************************************************************

gen hiv_concept=hiv
sort snomedctconceptid hiv_concept
by snomedctconceptid: replace hiv_concept=hiv_concept[1] 
*from review don't want to include any of these

*************************************************************************************************************************
*STEP 6: DROP ALL TERMS NOT CAPTURED BY SEARCH TERMS
*************************************************************************************************************************
keep if hiv==1

*drop redundant variables and order variables
keep medcodeid term snomedctconceptid cleansedreadcode hiv

*************************************************************************************************************************
*STEP 5: SAVE LIST OF CODES AS STATA FILE
*************************************************************************************************************************
save "$Datadir\\cr_codelist_hiv_aurum.dta", replace
export delimited using "$Textdir\\cr_codelist_hiv_aurum.txt", replace

capture log close
