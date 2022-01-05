cap prog drop pr_getlast_treatedhyp_aurum

prog define pr_getlast_treatedhyp_aurum 
syntax , therapyfile(string) therapyfilenum(string) clinicalfile(string) clinfilenum(string) index(string) runin(string) commondosage(string)

*updated 2019 to account for CPRD no longer providing ndd - instead use doseageid lookup
preserve

display in red "*******************Observation file number: 1*******************"
use  "$QRiskCodelistdir\cr_codelist_qof_cod_aurum" , clear
keep if variable=="b_treatedhyp"
merge 1:m medcodeid using "`clinicalfile'_1", keep(match) keepusing(patid obsdate) nogen
gen b_hyp_diag=1
keep patid obsdate b_hyp_diag
drop if obsdate==.
tempfile hyp_diag
save `hyp_diag' , replace

forvalues n=2/`clinfilenum' {
display in red "*******************Observation file number: `n'*******************"
use  "$QRiskCodelistdir\cr_codelist_qof_cod_aurum" , clear
keep if variable=="b_treatedhyp"
merge 1:m medcodeid using "`clinicalfile'_`n'", keep(match) keepusing(patid obsdate) nogen
gen b_hyp_diag=1
keep patid obsdate b_hyp_diag
drop if obsdate==.
append using "`hyp_diag'"
save `hyp_diag' , replace
}

restore

preserve
merge 1:m patid using `hyp_diag', keep(match master)
sort patid obsdate
by patid: replace obsdate=. if _merge==3 & obsdate>`index' & _n==1
by patid: replace b_hyp_diag=. if _merge==3 & obsdate>`index' & _n==1
drop if _merge==3 & obsdate>`index' & obsdate!=.

by patid: replace b_hyp_diag=. if _merge==3 & obsdate<`index'-365.25*`runin' & _n==_N
by patid: replace obsdate=. if _merge==3 & obsdate<`index'-365.25*`runin' & _n==_N
drop if _merge==3 & obsdate<`index'-365.25*`runin' 
gsort patid -obsdate b_hyp_diag
count if  _merge==3 
if `r(N)'>0 {
duplicates drop patid if  _merge==3 , force
}

replace b_hyp_diag=0 if b_hyp_diag==.
drop _merge 
rename obsdate hyp_diag_date
save `hyp_diag' , replace

/*get whether on prescription*/


display in red "*******************Drug issue file number: 1*******************"
use "$QRiskCodelistdir\cr_codelist_antihypertensives_aurum.dta", clear
keep prodcodeid

/*creates file with eventdate and b_treatedhype variables, 
b_treatedhype = 1 for each prescription and 0 at the end of prescriptions if 
there is a gap between two prescriptions*/
merge 1:m prodcodeid using "`therapyfile'_1" , nogen keep(match)

tempfile treatedhyp
save `treatedhyp' , replace

forvalues n=2/`therapyfilenum' {
display in red "*******************Drug issue file number: `n'*******************"
use "$QRiskCodelistdir\cr_codelist_antihypertensives_aurum.dta", clear
keep prodcodeid
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

restore

merge 1:m patid using `treatedhyp', keep(match master)
/*retains nearest record before index period and after run in period or single row
with missing event date abd b_treatedhyp if there are no records within this period*/
sort patid issuedate
by patid: replace issuedate=. if _merge==3 & issuedate>`index' & _n==1
by patid: replace b_treatedhyp=. if _merge==3 & issuedate>`index' & _n==1
drop if _merge==3 & issuedate>`index' & issuedate!=.
sort patid issuedate
by patid: replace b_treatedhyp=. if _merge==3 & issuedate<`index'-365.25*`runin' & _n==_N
by patid: replace issuedate=. if _merge==3 & issuedate<`index'-365.25*`runin' & _n==_N
drop if _merge==3 & issuedate<`index'-365.25*`runin'
gsort patid -issuedate b_treatedhyp
duplicates drop patid if _merge==3, force

*replaces missing b_treatedhyp with 0
replace b_treatedhyp=0 if b_treatedhyp==.
*replace most recent record with 0 if runout is before index
replace b_treatedhyp=0 if issuedate!=. & issuedate!=`index' & b_treatedhyp==1 & runoutdate<`index'

merge m:1 patid using `hyp_diag', nogen

gen treated=1 if b_treatedhyp==1 & b_hyp_diag==1
replace treated=0 if treated!=1
rename b_treatedhyp hyptreat
rename treated b_treatedhyp

drop _merge runoutdate
rename issuedate treatedhypdate

end


