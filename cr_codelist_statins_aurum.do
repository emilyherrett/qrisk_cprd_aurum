
clear all
set more off
cap log close
log using "$Logdir\\cr_codelist_statins.txt", replace text

// Program: 		do file to create statins code list for QRisk3 
// Name:			cr_codelist_statins_aurum.do
// Authors:			Jennifer Davidson has modified Helen Strongman's Gold work
// Date created: 	25/11/2020

use "$Productdic.dta"

foreach var of varlist termfromemis productname drugsubstancename {
	generate Z=lower(`var')
	drop `var'
	rename Z `var'
}

keep if strpos(drugsubst,"statin") | strpos(termfromemis,"statin") | strpos(productname,"statin")>0

drop if strpos(drugsubst,"nystatin") | strpos(drugsubst,"cilastatin") | strpos(drugsubst,"pentostatin") | strpos(drugsubst,"ecostatin") | strpos(drugsubst,"sandostatin") | strpos(termfromemis,"nystatin") | strpos(termfromemis,"cilastatin") | strpos(termfromemis,"pentostatin") | strpos(termfromemis,"ecostatin") | strpos(termfromemis,"sandostatin") | strpos(productname,"nystatin") | strpos(productname,"cilastatin") | strpos(productname,"pentostatin") | strpos(productname,"ecostatin") | strpos(productname,"sandostatin")

compress
sort bnfchapter

save "$Datadir/cr_codelist_statins", replace

keep prodcodeid drugsubstancename productname formulation route bnfchapter
export delimited using "$Textdir\\cr_codelist_statins.txt", replace

log close
