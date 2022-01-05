******************************************************************
*Program to calculate QRISK2 2015 score based on open source code*
******************************************************************
*calculate at indexdate with optional time updating until enddate*
******************************************************************

/*Instructions for use
*You will need in memory: file with patient IDs and one or two stata format date variables (note there can be other variables present in your file):
--for single point QRISK2/3: you need one stata format date variable; the date at which you want QRISK to be calculated. This is the indexdate.
--for time updating QRISK2/3: you need two stata format date variables; between which QRISK2/3 will be calculated whenever a change occurs. the indexdate is the start of this period and the enddate is the end.
*arguments:
--indexdate: name of stata format date variable specifying when/the start of the period in which QRISK2 should be calculated
--enddate: only specified if time updating variable required; name of stata format date variable specifying end of period in which QRISK2/3 should be calculated
--patientfile etc: location of the patient, practice, test... file from your CPRD extract
--Townsendfile: location of file containing townsend data (file name needs to include the year - 2001 or 2011)
--level (patient / practice): must be specified if townsend is used, specifies whether Townsend data is patient or practice level
--tchdl_cutoff: upper limit of total cholesterol/hdl ratio considered acceptable (above this will be recoded as missing)
--bmi_cutoff: BMI upper limit (EH set as 50 as per Krishnan Bhaskaran)
--runin: time before indexdate (in years) to look for information
--sbp_lowest and sbp_highest: lower and higher limits of systolic blood pressure (mmHg) considered acceptable
--smokedef: there are two ways to define smoking status. (1) select records using Read/SNOMED codes only (codeonly). This gives the closest fit to recorded QRISK2 Read codes. (2) use all records in the smoking status entity type that have smoking status specified in the additional clinical details file or within the Read code(codeentity). This is more complete than (1)
--commondosage: common dosages build to use in treated hypertension file. either "merged" = rawdata already merged with lookup, or substring to common dosages file saved in code list folder e.g. JUL18
*specify the following filepaths in your global file:
--global $QRiskCodelistdir "J:\EHR-Working\QRISK\qrisk_bundle_aurum\codelists" 
--global $QRiskDodir "J:\EHR-Working\QRISK\qrisk_bundle_aurum\dofiles\v2" 
*/


cap prog drop pr_qrisk_aurum
program define pr_qrisk_aurum
syntax, qriskscore(string) patientfile(string) practicefile(string) clinicalfile(string) therapyfile(string) clinfilenum(string) therapyfilenum(string) indexdate(string) [enddate(string)] [townsendfile(string) level(string) tchdl_cutoff(string) sbp_lowest(string) sbp_highest(string) bmi_cutoff(string)] runin(integer) commondosage(string)
 
*error messages*
if "`townsendfile'"!="" & "`level'"!="patient" & "`level'"!="practice" {
	noi di in red "If option townsendfile() is specified, the option level(practice) or level(patient) should be specified to identify the whether data is at practice or patient level."
	exit
}
 
 
tempfile originaldata
save `originaldata', replace
keep patid `indexdate' `enddate'

quietly { 
*load programs
do $QRiskDodir\pr_get_bclin_aurum
do $QRiskDodir\pr_get_btherapy_aurum
do $QRiskDodir\pr_get_treatedhyp_aurum
do $QRiskDodir\pr_get_bmiupdates_aurum
do $QRiskDodir\pr_get_sbpupdates_aurum
do $QRiskDodir\pr_get_smokingupdates_aurum
do $QRiskDodir\pr_get_fhcvd60_aurum
do $QRiskDodir\pr_get_tchdl_aurum
do $QRiskDodir\pr_get_diabetes_aurum
do $QRiskDodir\pr_get_sbpvarupdates_aurum
do $QRiskDodir\pr_get_ED_aurum

do $QRiskDodir\pr_getlast_bclin_aurum
do $QRiskDodir\pr_getlast_btherapy_aurum
do $QRiskDodir\pr_getlast_treatedhyp_aurum
do $QRiskDodir\pr_getlast_bmi_aurum
do $QRiskDodir\pr_getlast_sbp_aurum
do $QRiskDodir\pr_getlast_smokrec_aurum
do $QRiskDodir\pr_getlast_fhcvd60_aurum
do $QRiskDodir\pr_getlast_tchdlrec_aurum
do $QRiskDodir\pr_getlast_sbpvar_aurum


do $QRiskDodir\pr_cvd_male_raw_bmirep_`qriskscore'
do $QRiskDodir\pr_cvd_female_raw_bmirep_`qriskscore'


*organise patient and practice file into variables patid yob sex and imd indexdate enddate
noi di in yellow "Identifying variables:"

*identify ethnicity
noi di in yellow "Ethnicity"
noi di in red "*******************Observation file number: 1*******************"
use "`clinicalfile'_1", clear
merge m:1 medcodeid using $QRiskCodelistdir\cr_codelist_qrisk_ethnicity_aurum, keep(match) nogen
gsort patid obsdate -ethdm
/*by patid: gen dif=1 if ethdm!=ethdm[_N] 
by patid: egen dif2=total(dif)
by patid: replace ethdm=9 if dif2>0 */
/*put the above three lines back in if you want to replace ethnicity with 9 if there is a conflict, without these lines it uses the latest record*/
by patid: keep if _n==_N 
tempfile ethfile
*drop dif dif2
save `ethfile', replace

forvalues n=2/`clinfilenum' {
noi di in red "*******************Observation file number: `n'*******************"
use "`clinicalfile'_`n'", clear
merge m:1 medcodeid using $QRiskCodelistdir\cr_codelist_qrisk_ethnicity_aurum, keep(match) nogen
gsort patid obsdate -ethdm
by patid: keep if _n==_N 
append using "`ethfile'"
save `ethfile', replace
}

gsort patid obsdate -ethdm
by patid: keep if _n==_N
save `ethfile', replace

*identify patient sex
noi di in yellow "Sex"
use `originaldata', clear
merge 1:m patid using `patientfile', nogen keep(match master)
keep patid yob gender `indexdate' `enddate'
rename gender sex

*identify townsend score at patient or practice level from townsend file. If Townsend file not present, impute 0
noi di in yellow "Townsend deprivation score"
gen town=.

if "`townsendfile'"!="" {
	if "`level'"=="patient" {
	local variable "patid"
	}
	if "`level'"=="practice" {
	local variable  "pracid" 
	}
	merge 1:1 `variable' using `townsendfile' , nogen keep(match master) keepusing(townsend*_20)
	if strmatch("`townsendfile'", "*2001*") == 1 {
		replace town = townsend2001_20 
		recode town 1=-4.77 2=-4.16 3=-3.76 4=-3.41 5=-3.08 ///
		6=-2.74 7=-2.38 8=-1.98 9=-1.56 ///
		10=-1.08 11=-0.54 12=-0.03 13=0.62  ///
		14=1.30 15=2.03 16=2.83 17=3.71 18=4.71 19=6.00 20=8.02
		}
	if strmatch("`townsendfile'", "*2011*") == 1 {
		replace town = townsend2011_20 
		recode town 1=-4.86 2=-4.25 3=-3.85 4=-3.49 5=-2.13 ///
		6=-2.76 7=-2.36 8=-1.93 9=-1.45 ///
		10=-0.93 11=-0.38 12=-0.18 13=-0.79  ///
		14=1.44 15=2.12 16=2.88 17=3.71 18=4.64 19=5.81 20=7.62
		}
}    
replace town=0 if town==. /*this is the mean value for the LSOA Townsend scores*/


tempfile patients
save `patients' , replace

pause

*does this section only if enddate is specified -- i.e. time updating qrisk variable required. If not, skips to line 340
if "`enddate'"!=""{

*gathers all records for each variable and appends to previously collected variables

*binary clinical and referral variables - QOF codelists (excluding diabetes)
tempfile updaters

local i = 1
foreach var in ra atrialfib {
	noi di in yellow "`var'"
	*if `i' > 1 
	use `patients', clear
	pr_get_bclin_aurum, variable(`var') qof(qof) clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') begin(`indexdate') end(`enddate') runin(`runin')
	if `i' > 1 append using `updaters'
	save `updaters' , replace
	local i = `i' + 1
	}

*diabetes - defined by most recent type 1 or type 2 diabetes variable
noi di in yellow "diabetes"
use `patients' , clear
pr_get_diabetes_aurum, clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') begin(`indexdate') end(`enddate') runin(`runin')
append using `updaters'
save `updaters' , replace
	
*binary observational variables - individual code lists
noi di in yellow "renal_`qriskscore'"
use `patients' , clear
pr_get_bclin_aurum, variable(renal_`qriskscore') qof(notqof) clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') begin(`indexdate') end(`enddate') runin(`runin')
append using `updaters'
save `updaters' , replace

if "`qriskscore'" == "qrisk3" {
foreach var in migraine sle smi hiv {
	noi di in yellow "`var'"
	use `patients' , clear
	pr_get_bclin_aurum, variable(`var') qof(notqof) clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') begin(`indexdate') end(`enddate') runin(`runin')
	append using `updaters'
	save `updaters' , replace
	}
}

*binary therapy variables
if "`qriskscore'" == "qrisk3" {
foreach var in antipsychotics corticosteroids  {
	noi di in yellow "`var'"
	use `patients' , clear
	pr_get_btherapy_aurum, variable(`var') therapyfile(`therapyfile') therapyfilenum(`therapyfilenum') begin(`indexdate') end(`enddate') runin(`runin') time(current)
	append using `updaters'
	save `updaters' , replace
	}
}

if "`qriskscore'" == "qrisk3" {
use `patients' , clear
noi di in yellow "Erectile dysfunction"
pr_get_ED_aurum, clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') therapyfile(`therapyfile') therapyfilenum(`therapyfilenum') begin(`indexdate') end(`enddate') runin(`runin')
append using `updaters'
save `updaters' , replace
}

use `patients' , clear
noi di in yellow "Treated hypertension"	
pr_get_treatedhyp_aurum, clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') therapyfile(`therapyfile') therapyfilenum(`therapyfilenum') begin(`indexdate') end(`enddate') runin(`runin') commondosage(`commondosage') 
append using `updaters'
save `updaters' , replace

use `patients' , clear
noi di in yellow "Family history of CVD"
pr_get_fhcvd60_aurum, clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') begin(`indexdate') end(`enddate') runin(`runin')
append using `updaters'
save `updaters' , replace

use `patients' , clear
noi di in yellow "Smoking status"
pr_get_smokingupdates_aurum, clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') smokingstatusvar(smokstatus) begin(`indexdate') end(`enddate') runin(`runin') 
append using `updaters'
save `updaters' , replace

use `patients' , clear
noi di in yellow "BMI"
pr_get_bmiupdates_aurum, clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') begin(`indexdate') end(`enddate') runin(`runin') bmi_cutoff(`bmi_cutoff')  
append using `updaters'
save `updaters' , replace

use `patients' , clear
noi di in yellow "Total cholesterol/HDL ratio"
pr_get_tchdl_aurum, clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') begin(`indexdate') end(`enddate') runin(`runin') cutoff(`tchdl_cutoff')
append using `updaters'
save `updaters' , replace

use `patients' , clear
noi di in yellow "Systolic blood pressure"
pr_get_sbpupdates_aurum, clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') begin(`indexdate') end(`enddate') runin(`runin')
append using `updaters'
save `updaters' , replace

if "`qriskscore'" == "qrisk3" {
use `patients', clear
noi di in yellow "Systolic blood pressure variability"
pr_get_sbpvarupdates_aurum, clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') begin(`indexdate') end(`enddate') runin(`runin') 
append using `updaters'
save `updaters' , replace
}

*adds age updating date at the first of July of each year -- this just inserts an extra record, the actual age variable is added later
noi di in yellow "Age"
use `patients' , clear
summ `indexdate'
local minyear=year(`r(min)')
summ `enddate'
local maxyear=year(`r(max)')
forvalues i= `minyear'/`maxyear' {
gen age_date`i' = mdy(7,1,`i')
}
reshape long age_date , i(patid)
drop if age_date<`indexdate'
drop if age_date>`enddate'

append using `updaters'
save `updaters' , replace

*generates age
gen _dob = mdy(7,01,yob)
gen ageindex = round((`indexdate' - _dob)/365.25)
drop _dob

*merges with ethnicity file made earlier
noi di in yellow "Ethnicity"

merge m:1 patid using `ethfile' , keep(match master) nogen keepusing(ethdm)
replace ethdm=1 if ethdm==.


*generates score updating date from each date record (QRISK2/3 variables)
gen score_update=.
format score_update %td

local datevarlist "atrialfibdate age_date fh_date smoke_update type1date type2date bmidate TC_HDLdate radate renal_`qriskscore' treatedhypdate bpdate"
if "`qriskscore'" == "qrisk3" {
	local datevarlist "`datevarlist' migrainedate sledate smidate hivdate EDdate sbp_sddate corticosteroidsdate antipsychoticsdate"
	}
noi di "`datevarlist'"

foreach var of local datevarlist { 
replace score_update = `var' if score_update==.
}

drop `datevarlist'
sort patid score_update

*adds variable values in gaps between updates
local binvarlist "b_atrialfib fh_cvd b_type1 b_type2 b_ra b_renal_`qriskscore' b_treatedhyp"
if "`qriskscore'" == "qrisk3" {
	local binvarlist "`binvarlist' b_antipsychotics b_corticosteroids b_ED b_migraine b_sle b_smi b_hiv b_ED"
	}
noi di "`binvarlist'"		
	
local valuevarlist "smokstatus TC_HDLratio bmi sbp"
if "`qriskscore'" == "qrisk3" {
	local valuevarlist "`valuevarlist' sbp_sd"
	}
noi di "`valuevarlist'"	
	
local allvarlist "`binvarlist' `valuevarlist'"
noi di "`allvarlist'"	
	
foreach var of local allvarlist { 
	by patid: replace `var' = `var'[_n-1] if `var'==.
}

*counts number of missing variables for each record. If several records on the same date, keeps the one with the least missing variables
gen nmissing=0
foreach var of local allvarlist { 
	replace nmissing=nmissing+1 if `var'==. 
	}
	
gsort patid score_update -nmissing
by patid score_update: keep if _n==_N
format score_update %td

*replaces missing binary variables with 0
foreach var of local binvarlist { 
noi replace `var'=0 if `var'==.
}

*keeps only the most recent score before indexdate
gen before=1 if score_update<=`indexdate'
gsort patid before -score_update -nmissing
by patid before: drop if _n>1 & before==1
drop before nmissing

}

*does this only if no enddate specified -- qrisk variable required at single point. If not, skips to line 334

if "`enddate'"=="" {

*gathers most recent record before indexdate for each variables and merges, so only one record per person
tempfile updaters

*binary clinical variables - QOF codelists
local i = 1
foreach var in type1 type2 ra atrialfib {
	noi di in yellow "`var'"	 
	pr_getlast_bclin_aurum, variable(`var') qof(qof) clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') index(`indexdate') runin(`runin')
	if `i' > 1 merge 1:1 patid using `updaters', nogen
	save `updaters' , replace
	local i = `i' + 1
	}
	
*binary clinical variables - individual codelists
noi di in yellow "renal_`qriskscore'"
pr_getlast_bclin_aurum, variable(renal_`qriskscore') qof(notqof) clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') index(`indexdate') runin(`runin')
merge 1:1 patid using `updaters', nogen
save `updaters', replace

if "`qriskscore'" == "qrisk3" {
foreach var in migraine sle smi hiv ED  {
	noi di in yellow "`var'"
	pr_getlast_bclin_aurum, variable(`var') qof(notqof) clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') index(`indexdate') runin(`runin')
	merge 1:1 patid using `updaters' , nogen
	save `updaters' , replace
	}
}

*
*both type1 and type 2 diabetes (define according to latest eventdate)
replace b_type2 = 0 if b_type1 == 1 & b_type2 == 1 & type1date>type2date
replace b_type1 = 0 if b_type1 == 1 & b_type2 == 1 & type2date>=type1date

*binary therapy variables
if "`qriskscore'" == "qrisk3" {
foreach var in antipsychotics corticosteroids ED_drugs  {
	if "`var'" == "ED_drugs" local time = "ever"
	else local time = "current"
	noi di in yellow "`var'"
	pr_getlast_btherapy_aurum, variable(`var') therapyfile(`therapyfile') therapyfilenum(`therapyfilenum') index(`indexdate') time(`time') runin(`runin')
	merge 1:1 patid using `updaters' , nogen
	save `updaters' , replace
	}
	
	
	*ED = diagnosis of erectile dysfunction or treatment with ED drugs
	replace b_ED = 1 if b_ED_drugs == 1
	drop EDdate b_ED_drugs
	save `updaters' , replace
}


use `patients', clear
noi di in yellow "Treated hypertension"	 
pr_getlast_treatedhyp_aurum,  therapyfile(`therapyfile') therapyfilenum(`therapyfilenum') clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') index(`indexdate') runin(`runin') commondosage(`commondosage') 
merge 1:1 patid using `updaters', nogen
save `updaters', replace

use `patients', clear
noi di in yellow "Family history of CVD"
pr_getlast_fhcvd60_aurum, clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') index(`indexdate') runin(`runin')
merge 1:1 patid using `updaters', nogen
save `updaters', replace

use `patients', clear
noi di in yellow "Smoking status"
pr_getlast_smokrec_aurum, clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') smokingstatusvar(smokstatus) index(`indexdate') runin(`runin')
merge 1:1 patid using `updaters', nogen
save `updaters', replace
use `patients', clear

noi di in yellow "BMI"
pr_getlast_bmi_aurum,  clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') index(`indexdate') runin(`runin') bmi_cutoff(`bmi_cutoff')
merge 1:1 patid using `updaters', nogen
save `updaters', replace

use `patients', clear
noi di in yellow "Total cholesterol/HDL ratio"
pr_getlast_tchdlrec_aurum, clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') index(`indexdate') runin(`runin') cutoff(`tchdl_cutoff')
merge 1:1 patid using `updaters', nogen
save `updaters', replace

use `patients', clear
noi di in yellow "Systolic Blood pressure"
pr_getlast_sbp_aurum, clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') index(`indexdate') runin(`runin') 
merge 1:1 patid using `updaters', nogen
save `updaters', replace

if "`qriskscore'" == "qrisk3" {
	use `patients' , clear
	noi di in yellow "Systolic blood pressure variability"
	pr_getlast_sbpvar_aurum, clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') index(`indexdate') runin(`runin')
	merge 1:1 patid using `updaters', nogen
	save `updaters' , replace
	}

*calculate age for each entry
noi di in yellow "Age"
gen _dob = mdy(7,01,yob)
gen ageindex = round((`indexdate' - _dob)/365.25)
drop _dob

*merge ethnicity file
noi di in yellow "Ethnicity"

merge m:1 patid using `ethfile', keep(match master) nogen keepusing(ethdm)
replace ethdm=1 if ethdm==.

local binvarlist "b_atrialfib fh_cvd b_type1 b_type2 b_ra b_renal_`qriskscore' b_treatedhyp"
if "`qriskscore'" == "qrisk3" {
	local binvarlist "`binvarlist' b_antipsychotics b_corticosteroids b_ED b_migraine b_sle b_smi b_hiv b_ED"
	}
noi di "`binvarlist'"	
	
*replaces missing binary variables with 0
foreach var of local binvarlist { 
replace `var'=0 if `var'==.
}

}


*rename any variables to QRISK names
rename (smokstatus b_atrialfib TC_HDLratio ethdm b_renal_`qriskscore') (smoke_cat b_AF rati ethrisk b_renal) 
if "`qriskscore'" == "qrisk3" {
rename (b_antipsychotics b_smi sbp_sd b_ED) (b_atypicalantipsy b_semi sbps5 b_impotence2) 
}

************************************
*IMPUTATION OF SMOKINGSTATUS TC/HDL SBP BMI
************************************

*Keep version of non-imputed variables
gen smoke_cat2=smoke_cat
gen bmi2=bmi
gen sbp2=sbp
gen rati2=rati

gen impute_info=1000000 if sex==1
replace impute_info=2000000 if sex==2

replace impute_info=impute_info+100000 if smoke_cat==.
replace smoke_cat=0 if smoke_cat==.

replace impute_info=impute_info+10000 if bmi==.
replace impute_info=impute_info+1000 if bmi<20
replace bmi=20 if bmi<20
replace bmi=27.3 if bmi==. & sex==1
replace bmi=26.8 if bmi==. & sex==2

replace impute_info=impute_info+100 if sbp==.
replace sbp=134 if sbp==. & sex==1
replace sbp=132 if sbp==. & sex==2

replace impute_info=impute_info+10 if rati==.
replace rati=4.1 if rati==. & sex==1
replace rati=3.5 if rati==. & sex==2

if "`qriskscore'" == "qrisk3" {
	replace impute_info=impute_info+1 if sbps5==.
	replace sbps5 = 0 if sbps5==.
	}

	
note impute_info: First column denotes sex, and thus imputed values. Second=1 smoking imputed as non-smoker. Third=1 BMI imputes as 27.3(M) 26.8(F). Fourth=1 BMI imputed as 20 if below 20. Fifth=1 SBP imputed as 134(M) 132(F). Sixth=1 TC/HDL ratio imputed as 4.1(M) 3.5(F).

*calculate qrisk
if "`qriskscore'" == "qrisk2" local score = "QRISK2 2015"
if "`qriskscore'" == "qrisk3" local score = "QRISK3 2017"


noi di in yellow " "
noi di in yellow "Calculating `score' (Townsend data is the median twentile value, or imputed as 0 if absent. Imputed BMI, TCHDL and SBP as per rounded score on qrisk website and smoking as 0.)"

*these programs run the QRISK2 2015 or QRISK3 2017 equation to generate a score
cvd_male_raw_`qriskscore'
cvd_female_raw_`qriskscore'


*merge with the original file
if "`enddate'"=="" {
	*keep patid score impute_info /*Get rid of this line if you want to see the variable values*/
	tempfile scores
	save `scores', replace
	use `originaldata', clear
	merge 1:1 patid using `scores', keep(master match) nogen
}
else {
*keep patid score_update score impute_info /*Get rid of this line if you want to see the variable values*/
	tempfile scores
	save `scores', replace
	use `originaldata', clear
	merge 1:m patid using `scores', keep(master match) nogen
}

}

end
