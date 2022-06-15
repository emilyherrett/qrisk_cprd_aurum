
clear all
set more off
cap log close
log using "$Logdir\\cr_codelist_antihypertensives.txt", replace text

// Program: 		do file to create antihypertensives code list for QRisk3 - JD QUERY: IS THIS NOT ALSO NEEDED FOR QRISK2?
// Definition: 		beta_adrenoceptor blocking drugs, ACE-inhibitors, Angiotensin-II receptor antagonists
//					NOTE: THESE DRUG CLASSES ARE NOT SPECIFIED IN THE QRISK3 PAPER
// Name:			cr_codelist_antihypertensives_aurum.do
// Authors:			Jennifer Davidson has modified Helen Strongman's Gold work
// Date created: 	28/04/2020

use "$Productdic.dta"

foreach var of varlist termfromemis productname drugsubstancename {
	generate Z=lower(`var')
	drop `var'
	rename Z `var'
}

*******************************************************************************/
* DEFINE DRUG SUBSTANCE AND PRODUCT INCLUSION TERMS
*-------------------------------------------------------------------------------

/*BNF CHAPTER SEARCH ONLY - CODE LISTS CREATED FOR PREVIOUS PROJECT IDENTIFIED
VERY FEW (c 0.2%) ADDITIONAL EVENTS USING TEXT SEARCH OF DRUG SUBSTANCE AND
PRODUCT NAMES*/
local interms " "*2040000*" "*2040100*" "*2050501*" "*2050502*" "*2050504*" " 

/*
02040000 beta-adrenoceptor blocking drugs
02040100 beta-adrenoceptor blocking drugs with diuretic
02050501 ACE-inhibitors
02050502 angiotensin-ii receptor antagonists
02050504 angiotensin-ii receptor antagonists with diuretic
*/

* Search desc variable for words in the searchterm string
gen antihypertensives=.

foreach word in `interms'{
	replace antihypertensives = 1 if strmatch(bnfchapter, "`word'")
	}

keep if antihypertensives == 1

drop dmdid formulation routeofadministration substancestrength release

/*******************************************************************************
SAVE FILE
*******************************************************************************/
save "$Datadir\cr_codelist_antihypertensives_aurum.dta", replace
export delimited using "$Textdir\\cr_codelist_antihypertensives_aurum.txt", replace

capture log close
