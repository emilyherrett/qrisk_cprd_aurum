capture log close
log using "$Logdir\cr_codelist_qrisk_ethnicity.txt", replace text

/*=========================================================================

DO FILE NAME:		cr_codelist_qrisk_ethnicity_aurum

AUTHOR:				Jennifer Davidson adapted from Sarah Gadd & Helen Strongman	
					QRISK work for Gold using Harriet Forbes ethnicity codelist 
					for Aurum
				
VERSION:			1.0
DATE CREATED: 		14/05/2020		
							
DATABASE:			CPRD AURUM - SNOMED CODES

DESCRIPTION:		ETHNICITY SNOMED CODES WITH QRISK CATEGORIES
						
DATASET USED: 		ethnicity_codelist_Aurum_hf.dta
									
DATASET CREATED:	cr_codelist_qrisk_ethnicity_aurum	

*=========================================================================*/

*import Harriet's list of snomed codes
use "J:\EHR-Working\QRISK\qrisk_bundle_aurum\codelists\v2\sourcefiles\ethnicity_codelist_Aurum_hf"

*regroup ethnicities for QRISK
gen ethdm=9
replace ethdm=1 if inlist(eth16,1,2,3,17)
replace ethdm=2 if eth16==8
replace ethdm=3 if eth16==9
replace ethdm=4 if eth16==10
replace ethdm=5 if eth16==11
replace ethdm=6 if eth16==12
replace ethdm=7 if eth16==13
replace ethdm=8 if eth16==15

label define ethnicitycat ///
1 "White or not stated" ///
2 "Indian" ///
3 "Pakistani" ///
4 "Bangladeshi" ///
5 "Other Asian" ///
6 "Black Caribbean" ///
7 "Black African" ///
8 "Chinese" ///
9 "Other"
label values ethdm ethnicitycat

tab eth16 ethdm, m

keep medcodeid term originalreadcode cleansedreadcode ethdm 

save "$Datadir\\cr_codelist_qrisk_ethnicity_aurum.dta", replace
export delimited using "$Textdir\\cr_codelist_qrisk_ethnicity_aurum.txt", replace

capture log close
