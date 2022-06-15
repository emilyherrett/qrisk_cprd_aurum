
clear all
set more off
cap log close
log using "$Logdir\\cr_codelist_antipsychotics.txt", replace text

// Program: do file to create antipsychotics code list for QRisk3
// Definition: Second generation “atypical” antipsychotic use (including amisulpride, 
//				aripiprazole, clozapine, lurasidone, olanzapine, paliperidone, 
//				quetiapine, risperidone, sertindole, or zotepine)
// Name:	cr_codelist_antipsychotics.do
// Authors:	Jennifer Davidson has modified Helen Strongman & Emily Herrett's Gold work
// Date created: 17/02/2021

use "$Productdic.dta"

foreach var of varlist termfromemis productname drugsubstancename {
	generate Z=lower(`var')
	drop `var'
	rename Z `var'
}

*******************************************************************************/
* DEFINE DRUG SUBSTANCE AND PRODUCT INCLUSION TERMS
*-------------------------------------------------------------------------------

*BNF codes in Aurum are different to Gold, for this search want to use 04020102 but only 4020100 available & this includes 1st gen as well as 2nd gen antipsychotics. Also alot of products don't have any BNF code so word searches needed anyway
loc interm " "*amisulpride*" "*aripiprazole*" "*clozapine*" "*lurasidone*" "*olanzapine*" "*paliperidone*" "*risperidone*" "*serdolect*" "*sertindole*" "*zoleptil*" "*zotepine*" "*zyprexa*" "

gen antipsychotics=.
 
foreach word in `interm'{
	replace  antipsychotics=1 if strmatch(productname, "`word'")
	replace  antipsychotics=1 if strmatch(drugsubstance, "`word'")
	replace  antipsychotics=1 if strmatch(termfromemis, "`word'")
}	
	
keep if antipsychotics==1

drop dmdid formulation routeofadministration substancestrength release

/*******************************************************************************
SAVE FILE
*******************************************************************************/
save "$Datadir\cr_codelist_antipsychotics_aurum.dta", replace
export delimited using "$Textdir\\cr_codelist_antipsychotics_aurum.txt", replace

capture log close
