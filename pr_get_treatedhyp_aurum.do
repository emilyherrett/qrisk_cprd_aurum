cap prog drop pr_get_treatedhyp_aurum

prog define pr_get_treatedhyp_aurum
syntax, clinicalfile(string) clinfilenum(string) therapyfile(string) therapyfilenum(string) begin(string) end(string) runin(integer) commondosage(string)

tempfile dataathand
save `dataathand', replace

display in red "*******************Observation file number: 1*******************"
*identify clinical and referral hypertension records
use  "$QRiskCodelistdir\cr_codelist_qof_cod_aurum.dta" , clear
keep if variable=="b_treatedhyp"
merge 1:m medcodeid using "`clinicalfile'_1" , keep(match) keepusing(patid obsdate) nogen
gen b_hyp_diag=1
keep patid obsdate b_hyp_diag
drop if obsdate==.
tempfile hyp_diag
save `hyp_diag' , replace


forvalues n=2/`clinfilenum' {
display in red "*******************Observation file number: `n'*******************"
use  "$QRiskCodelistdir\cr_codelist_qof_cod_aurum.dta" , clear
keep if variable=="b_treatedhyp"
merge 1:m medcodeid using "`clinicalfile'_`n'" , keep(match) keepusing(patid obsdate) nogen
gen b_hyp_diag=1
keep patid obsdate b_hyp_diag
drop if obsdate==.
append using "`hyp_diag'"
save `hyp_diag' , replace
}

/*merge with patient file, keep hypertension records within specified
time window, and single record for patients with no hypertension records in this
period*/
use `dataathand', clear

merge 1:m patid using `hyp_diag', keep(match master)

drop if _merge==3 & obsdate>`end'
drop if _merge==3 & obsdate<`begin'-365.25*`runin'
gsort patid -obsdate
duplicates drop patid if obsdate<`begin' & _merge==3 , force


sort patid obsdate
by patid: keep if _n==1

replace b_hyp_diag=0 if b_hyp_diag==.

/*create additional records for patients diagnosed with hypertension after the index rate,
set eventdate to start of follow-up and b_hyp_diag to 0*/
expand 2 if obsdate>`begin' & obsdate!=. & patid[_n]!=patid[_n-1]
sort patid obsdate
by patid: replace b_hyp_diag=0 if _n==1 & obsdate>`begin'
by patid: replace obsdate = `begin' if _n==1 & obsdate>`begin'

drop _merge
rename obsdate treatedhypdate

tempfile hypdiags
save `hypdiags' , replace

/*TREATMENT*/

display in red "*******************Drug issue file number: 1*******************"
use "$QRiskCodelistdir\cr_codelist_antihypertensives_aurum.dta", clear
keep prodcode

merge 1:m prodcodeid using "`therapyfile'_1" , nogen keep(match)
tempfile treatedhyp
save `treatedhyp' , replace

forvalues n=2/`therapyfilenum' {
display in red "*******************Drug issue file number: `n'*******************"
use "$QRiskCodelistdir\cr_codelist_antihypertensives_aurum.dta", clear
keep prodcode

merge 1:m prodcodeid using "`therapyfile'_`n'" , nogen keep(match)
append using "`treatedhyp'"
save `treatedhyp' , replace
}

replace issuedate=enterdate if issuedate==.

*merge with common dosages file if not already complete in raw data
if "`commondosage'" != "merged" {
	merge m:1 dosageid using "$QRiskCodelistdir\common_dosages_`commondosage'.dta"
	drop if _merge==2
	}

keep patid issuedate daily_dose duration quantity 

destring quantity, replace
destring duration, replace

replace duration=quantity/daily_dose if duration==0 & quantity!=. & daily_dose!=. & quantity!=0 & daily_dose!=0
replace duration=quantity if duration==0 & (daily_dose==0 | daily_dose==.) & quantity!=0 & quantity!=.
replace duration=28 if duration<=1

drop daily_dose quantity

gsort patid issuedate -duration
duplicates drop patid issuedate, force // only keep the prescription with the longest duration for a given date or runoutdate will not be created

gen runoutdate=issuedate+duration

gen b_treatedhyp=1 
duplicates drop

/*create an additional record for time between prescriptions where eventdate is 
the runout date of the previous record and b_treated hyp is 0
*/
gen order = _n
expand 2 if runoutdate<issuedate[_n+1] & patid==patid[_n+1]
sort order
by order: replace issuedate=runoutdate if _n==2
by order: replace b_treatedhyp=0 if _n==2
drop duration order
save `treatedhyp' , replace

/*merge with patient file, keep events within follow-up period*/
use `dataathand' , clear

merge 1:m patid using `treatedhyp', keep(match master)

drop if _merge==3 & issuedate>`end'
drop if _merge==3 & issuedate<`begin'-365.25*`runin'
gsort patid -issuedate b_treatedhyp
duplicates drop patid if issuedate<=`begin' & _merge==3 , force

replace b_treatedhyp=0 if b_treatedhyp==.

/*create additional records for patients first prescribed hypertension treatment
 after the index rate, set eventdate to start of follow-up and b_hyp_diag to 0*/ 
sort patid issuedate
expand 2 if issuedate>`begin' & issuedate!=. & patid[_n]!=patid[_n-1]
sort patid issuedate
by patid: replace b_treatedhyp=0 if _n==1 & issuedate>`begin'
by patid: replace issuedate = `begin' if _n==1 & issuedate>`begin'

/*for patients with only one record which is pre-baseline and is =1 but runout is before index, replace =0*/ 
by patid: replace b_treatedhyp=0 if _N==1 & issuedate!=. & issuedate!=indexdate & b_treatedhyp==1 & runoutdate<indexdate

drop _merge runoutdate
rename issuedate treatedhypdate

/*APPEND HYPERTENSION DIAGNOSIS AND TREATMENT DATA*/
append using `hypdiags' 

/*b_hyp_diag = value for previous record for treatment records
b_treatedhyp = value for previous record for diagnostic records*/
sort patid treatedhypdate
by patid: replace b_hyp_diag=b_hyp_diag[_n-1] if b_hyp_diag==. & _n>1
by patid: replace b_treatedhyp=b_treatedhyp[_n-1] if b_treatedhyp==. & _n>1

/*final b_treatedhyp variable*/
gen treated = 1 if b_hyp_diag==1 & b_treatedhyp==1
replace treated=0 if treated!=1

rename b_treatedhyp b_bp_treatment
rename treated b_treatedhyp
replace b_bp_treatment=0 if b_bp_treatment==.
replace b_hyp_diag=0 if b_hyp_diag==.
duplicates drop

gsort patid treatedhypdate -b_treatedhyp
duplicates drop patid treatedhypdate, force // to remove conflicting results for the same date
by patid: drop if b_treatedhyp[_n-1]==b_treatedhyp & b_bp_treatment[_n-1]==b_bp_treatment & b_hyp_diag[_n-1]==b_hyp_diag & _n>1
by patid: drop if b_treatedhyp[_n+1]==b_treatedhyp & b_bp_treatment[_n+1]==b_bp_treatment & b_hyp_diag[_n+1]==b_hyp_diag & treatedhypdate<=`begin'

*Only kept the most recent baseline measure
gsort patid -b_treatedhyp treatedhypdate
duplicates drop patid if treatedhypdate<=`begin', force
sort patid treatedhypdate


end



