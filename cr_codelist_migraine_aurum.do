
clear
set more off
capture log close
log using "$Logdir\cr_codelist_migraine.txt", replace text


/*Program:   do file to select code list for migraine
*Name:	  cr_codelist_migraine.do
*Authors:  Jennifer Davidson has modified Emily Herrett and Helen Strongman's Gold work 
*Date created:  19/02/2021
*/

use "$Medicaldic.dta", clear
replace term=lower(term)

*************************************************************************************************************************
*STEP 1: DEFINE SEARCH TERMS
*************************************************************************************************************************
loc interm " "*migraine*" "*migrainous*" "* aura *" " 

*************************************************************************************************************************
*STEP 2: WORD SEARCH OF READ CODE DICTIONARY
*************************************************************************************************************************

*create a marker for useful observations
gen migraine=.

foreach word in `interm'{
		replace migraine = 1 if strmatch(term, "`word'")
}


*************************************************************************************************************************
*STEP 3: CODE SEARCH OF READ CODE DICTIONARY FOR TERMS NOT IDENTIFIED IN STEP 2
*************************************************************************************************************************
loc incode "F26*"

foreach word in `incode'{
  replace migraine = 1 if strmatch(cleansedreadcode, "`word'")
  }

*************************************************************************************************************************
*STEP 4: EXCLUDE UNWANTED TERMS TO MAKE SEARCH MORE SPECIFIC
*************************************************************************************************************************

local exterm " "*no history*" "*family*" "*fh*" "*ophthalm*" "*ocular*" "*induced*" "*sick*" "*tension*" "adverse reaction*" "*drugs*" "*nurofen*" "*welland*" "neuralgic migraine" "

foreach word in `exterm' {
replace migraine = . if strmatch(term, "`word'")
}

*************************************************************************************************************************
*STEP 5: EXCLUDE ANY REMAINING UNWANTED CODES FOR THIS LIST
*************************************************************************************************************************
*remove codes that rated by clinician as not relevant to the list
local excode " "F262C00" "

foreach word in `excode' {
replace migraine = . if strpos(cleansedreadcode, "`word'")
}


************************************************************************************************************************
*STEP 6: FLAG ALL CODES WHICH MATCH CONCEPT ID FOR CODES IDENTIFIED IN STEP 2 & 3
*************************************************************************************************************************

gen migraine_concept=migraine
sort snomedctconceptid migraine_concept
by snomedctconceptid: replace migraine_concept=migraine_concept[1] 
*from review don't want to include any of these

	
*************************************************************************************************************************
*STEP 7: DROP ALL TERMS NOT CAPTURED BY SEARCH TERMS
*************************************************************************************************************************
keep if migraine==1

*drop redundant variables and order variables
keep medcodeid term snomedctconceptid cleansedreadcode migraine


*************************************************************************************************************************
*STEP 8: SAVE LIST OF CODES AS STATA FILE
*************************************************************************************************************************
save "$Datadir\\cr_codelist_migraine_aurum.dta", replace
export delimited using "$Textdir\\cr_codelist_migraine_aurum.txt", replace
capture log close

