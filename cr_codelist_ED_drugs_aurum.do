
clear
set more off
capture log close
log using "$Logdir\\cr_codelist_ED_drugs.txt", replace text

*Program:   do file to select code list for erectile dysfunction drugs
*Name:	  cr_codelist_ED_drugs.do
*Authors:  Jennifer Davidson has modified Emily Herrett's Gold work
*Date created:  18/02/2021

*NOTE QRISK3 PAPER https://www.bmj.com/content/bmj/357/bmj.j2099.full.pdf
*TREATMENT INCLUDES CHAPTER 7.4.5

use "$Productdic.dta"

foreach var of varlist termfromemis productname drugsubstancename {
	generate Z=lower(`var')
	drop `var'
	rename Z `var'
}

*************************************************************************************************************************
*STEP 1: DEFINE DRUG SUBSTANCE AND PRODUCT INCLUSION TERMS
*************************************************************************************************************************
loc incode " "7040500" "

* Search desc variable for words in the searchterm string
gen erectdysdrug=.

foreach word in `incode'{
	replace erectdysdrug = 1 if strmatch(bnfchapter, "`word'")
	}



*************************************************************************************************************************
*STEP 2: WORD SEARCH OF READ CODE DICTIONARY
*************************************************************************************************************************

loc interm " "*alprostadil*" "*avanafil*" "*aviptadil*" "*moxisylyte *" "*papaverine*" "*sildenafil*" "*vardenafil*" "*yohimbine*" "

*lidocaine hydrochloride 

foreach word in `interm'{
	replace erectdysdrug=1 if strmatch(productname, "`word'")
	replace erectdysdrug=1 if strmatch(drugsubstance, "`word'")
	replace erectdysdrug=1 if strmatch(termfromemis, "`word'")
}


*************************************************************************************************************************
*STEP 3: EXCLUDE UNWANTED TERMS TO MAKE SEARCH MORE SPECIFIC
*************************************************************************************************************************

loc exterm " "*vacuum*" "

foreach word in `exterm' {
	replace erectdysdrug=. if strmatch(productname, "`word'")
	replace erectdysdrug=. if strmatch(drugsubstance, "`word'")
	replace erectdysdrug=. if strmatch(termfromemis, "`word'")
	replace erectdysdrug=. if strmatch(formulation, "`word'")
	replace erectdysdrug=. if strmatch(routeofadministration, "`word'")
}

keep if erectdysdrug==1
	
drop dmdid formulation routeofadministration substancestrength release

*************************************************************************************************************************
*STEP 8: SAVE LIST OF CODES AS STATA FILE
*************************************************************************************************************************

save "$Datadir\\cr_codelist_ED_drugs_aurum.dta", replace
export delimited using "$Textdir\\cr_codelist_ED_drugs_aurum.txt", replace
