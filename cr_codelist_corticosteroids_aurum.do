
clear all
set more off
cap log close
log using "$Logdir\\cr_codelist_corticosteroids.txt", replace text

// Program: do file to create corticosteroids code list for QRisk3
// Definition: Corticosteroid use (British National Formulary (BNF) chapter 6.3.2 
// including oral or parenteral prednisolone, betamethasone, cortisone, 
// depo-medrone, dexamethasone, deflazacort, efcortesol, hydrocortisone, 
// methylprednisolone, or triamcinolone)
// Name:	cr_codelist_corticosteroids.do
// Authors:	Jennifer Davidson (copy of previous oral steroids do file from ARI & MACE project, without oral restriction)
// Date created: 18/02/2021

use "$Productdic.dta"

foreach var of varlist termfromemis productname drugsubstancename {
	generate Z=lower(`var')
	drop `var'
	rename Z `var'
}

*******************************************************************************/
* DEFINE DRUG SUBSTANCE AND PRODUCT INCLUSION TERMS
*-------------------------------------------------------------------------------

loc incode " "6030200" "

* Search desc variable for words in the searchterm string
gen corticosteroids=.

foreach word in `incode'{
	replace corticosteroids = 1 if strmatch(bnfchapter, "`word'")
	}

*******************************************************************************/
* RERUN SEARCH WITH NEW INCLUSION TERMS
*-------------------------------------------------------------------------------

local interm " "*prednis*" "*dexamethasone*" "*triamcinolone*" "*cortisone*" "*budesonide*" "*deflazacort*" "*beclometasone*" "*betamethasone*" "*alkindi*" "*betnesol*" "*budenofalk*" "*calcort*" "*cortelan*" "*cortiment*" "*cortistab*" "*cortisyl*" "*decadron*" "*deflazacort*" "*deltacortril*" "*deltastab*" "*dilacort*" "*entocort*" "*lodotra*" "*martapan*" "*medrone*" "*pevanti*" " 

foreach word in `interm'{
	replace corticosteroids=1 if strmatch(productname, "`word'")
	replace corticosteroids=1 if strmatch(drugsubstance, "`word'")
	replace corticosteroids=1 if strmatch(termfromemis, "`word'")
}

*******************************************************************************/
* EXCLUSION TERMS 
*-------------------------------------------------------------------------------

loc exterm " "*drops*" "*mouthwash*" "*suppositor*" "*cream*" "*lotion*" "*ointment*" "*gel*" "*scalp*" "*canister*" "*refill*" "*enema*" "*implant*" "*bandage*" "*plasters*" "*paste*" "*foam*" "*spray*" "*powder*" "*haler*" "*halation*" "*puff*" "*respule*" "*solid bp*" "*orodispersible*" "*fludrocortisone*" "*rectal*" "  

*"*liquid*"

foreach word in `exterm'{
	replace corticosteroids=. if strmatch(productname, "`word'")
	replace corticosteroids=. if strmatch(drugsubstance, "`word'")
	replace corticosteroids=. if strmatch(termfromemis, "`word'")
	replace corticosteroids=. if strmatch(formulation, "`word'")
	replace corticosteroids=. if strmatch(routeofadministration, "`word'")
 }	

keep if corticosteroids==1

drop dmdid formulation routeofadministration substancestrength release
 
/*******************************************************************************
5 - SAVE FILE
*******************************************************************************/

save "$Datadir\\cr_codelist_corticosteroids_aurum.dta", replace
export delimited using "$Textdir\\cr_codelist_corticosteroids_aurum.txt", replace

capture log close
