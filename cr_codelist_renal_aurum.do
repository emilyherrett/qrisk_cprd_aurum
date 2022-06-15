capture log close
log using "$Logdir\cr_codelist_renal.txt", replace text


/*=========================================================================

DO FILE NAME:			cr_codelist_renal_aurum

AUTHOR:					Jennifer Davidson adapted from Helen Strongman's Gold version				
VERSION:				v1.0			[eg v1.0]
DATE VERSION CREATED: 	15/05/2020					
				
DATABASE:				CPRD AURUM			[gprd/hes/thin]	


DESCRIPTION OF FILE:	Code lists for Qisk2 renal definition
									
MORE INFORMATION:
QRISK2 - Chronic kidney disease (stage 4 or 5) and major chronic renal disease 
(including nephrotic syndrome, chronic glomerulonephritis, chronic pyelonephritis,
renal dialysis, and renal transplant)
QRISK3 - also includes stage 3
	
DATASETS CREATED:	cr_codelist_renal_aurum_qrisk2 , cr_codelist_renal_qrisk3_aurum

*=========================================================================*/


clear
set more off
set linesize 100

use "$Medicaldic.dta", clear
replace term=lower(term)

*************************************************************************************************************************
*STEP 1: MERGE CODES FROM GOLD
*************************************************************************************************************************

gen readcode=cleansedreadcode
merge m:1 readcode using "J:\EHR-Working\QRISK\qrisk_bundle\codelists\v2\datafiles\GOLD_2018_07\cr_codelist_renal_qrisk3.dta"
drop if _merge==2
gen marker=1 if _merge==3


*************************************************************************************************************************
*STEP 2: DEFINE SEARCH TERMS
*************************************************************************************************************************
loc interm " "*ckd*3*" "*ckd*4*" "*ckd*5*" "*chronic kidney disease*3*" "*chronic kidney disease*4*" "*chronic kidney disease*5*" "*renal dialysis*" "*kidney dialysis*" "*peritoneal dialysis*" "*renal*transplant*" "*kidney*transplant*" "*transplant*renal*" "*transplant*kidney*" "*h*emodialysis*" "*chronic glomerulonephritis*" "*chronic pyelonephritis*" "*nephrotic syndrome*" " 



*************************************************************************************************************************
*STEP 3: WORD SEARCH
*************************************************************************************************************************

foreach word in `interm'{
	replace marker=1 if strmatch(term, "`word'")
}


*************************************************************************************************************************
*STEP 5: DROP ALL TERMS NOT CAPTURED BY SEARCH TERMS
*************************************************************************************************************************
keep if marker==1
drop marker

*************************************************************************************************************************
*STEP 6: EXCLUDE UNWANTED TERMS TO MAKE SEARCH MORE SPECIFIC
*************************************************************************************************************************
*exclude family, fh, leukaemia etc etc
gen exclusion_term=0

local exterm " "*family*" "*fh*" "*childhood*" "*monitor*" "*qual indic*" "*quality ind*" "*predicted*" "*awaiting*" "*resolved*" "*discontinued*" "*at risk*" "*laboratory study*" "*management*" "*screening*" "*annual review*" "*monthly review*" "*reporting*" "egfr*" "estimated gfr*" "estimated glomerular filtration rate*" "no evidence of chronic kidney disease" "qkidney chronic kidney disease 5 year risk score" "reason for influenza vaccine - chronic kidney disease" "[v]renal dialysis status" "bloodstained peritoneal dialysis effluent" "foreign object*" "infection of*" "mckd - multicystic kidney disease" "*chronic kidney disease with glomerular filtration rate category g1 and albuminuria category a3" "*chronic kidney disease with glomerular filtration rate category g2 and albuminuria category a3" "peritoneal dialysis fluid*" "[x]renal tubulo-interstitial disorders/transplant rejection" "aneurysm of*" "*transplant*renal artery*" "*autotransplant*" "*allotransplant*" "post-transplantation of kidney examination*" "pre-transplantation of kidney work-up*" "renal tubulo-interstitial" "rupture of* of transplanted kidney" "stenosis of vein of transplanted kidney" "*donor*" "not on kidney transplant" "*waiting list*" "thrombosis of*transplanted kidney" "transplant renal vein thrombosis" "*education*" "*knowledge*" "haemodialysis nurse" "*solution*" "*acid concentrate*" "*cartridge*" "*bicarbonate powder*" "*liquid concentrate*" "*dry concentrate*" "*active cooling*" "*active warming*" "perirenal and periureteric post-transplant lymphocele" "renal homotransplantation with unilateral recipient nephrectomy" "renal tubulo-interstitial disorders in transplant rejection" "transplantation of aberrant renal vein" "*adrenal*" "


foreach word in `exterm' {
replace exclusion_term=1 if strmatch(term, "`word'")
}

browse if exclusion_term==1
drop if exclusion_term==1
drop exclusion_term


*drop redundant variables and order variables
keep medcodeid snomedctconceptid term
sort medcodeid

*************************************************************************************************************************
*STEP 7: SAVE LIST OF CODES AS STATA FILE
*************************************************************************************************************************
save "$Datadir\\cr_codelist_renal_qrisk3_aurum.dta", replace
export delimited using "$Textdir\\cr_codelist_renal_qrisk3_aurum.txt", replace
gen qrisk3_only=0
replace qrisk3_only= 1 if strmatch(term, "*stage 3*") | strmatch(term, "*g3*")
list term if qrisk3_only==1
drop if qrisk3_only==1
drop qrisk3_only
save "$Datadir\\cr_codelist_renal_qrisk2_aurum.dta", replace
export delimited using "$Textdir\\cr_codelist_renal_qrisk2_aurum.txt", replace

capture log close



