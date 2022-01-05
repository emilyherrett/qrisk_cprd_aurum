cap prog drop pr_get_diabetes_aurum

capture program drop pr_get_diabetes_aurum
prog define pr_get_diabetes_aurum
syntax, clinicalfile(string) clinfilenum(string) begin(string) end(string) runin(integer) 


preserve

display in red "*******************Observation file number: 1*******************"
*get all events matching code list
use "$QRiskCodelistdir\cr_codelist_qof_cod_aurum.dta", clear
keep if variable == "b_type1" | variable == "b_type2"

merge 1:m medcodeid using "`clinicalfile'_1", keep(match) keepusing(patid obsdate) nogen

gen diabetes = 1 if variable == "b_type1"
replace diabetes = 2 if variable == "b_type2"
keep patid obsdate diabetes
drop if obsdate==.
tempfile bdiab
save `bdiab', replace


forvalues n=2/`clinfilenum' {
display in red "*******************Observation file number: `n'*******************"
use "$QRiskCodelistdir\cr_codelist_qof_cod_aurum.dta", clear
keep if variable == "b_type1" | variable == "b_type2"

merge 1:m medcodeid using "`clinicalfile'_`n'", keep(match) keepusing(patid obsdate) nogen

gen diabetes = 1 if variable == "b_type1"
replace diabetes = 2 if variable == "b_type2"
keep patid obsdate diabetes
drop if obsdate==.
append using `bdiab'
save `bdiab', replace
}

*merge with patient file
restore
merge 1:m patid using `bdiab', keep(match master)

*keep records within specified timetable
drop if _merge==3 & obsdate>`end'
drop if _merge==3 & obsdate<`begin'-365.25*`runin'
gsort patid -obsdate
duplicates drop patid if obsdate<`begin' & _merge==3 , force

drop _merge

sort patid obsdate
*by patid: keep if _n==1

replace diabetes=0 if diab==.

*if sequential records are for the same diabetes type, keep the first record
by patid: gen drop = 1 if patid[_n]==patid[_n-1] & diab[_n] == diab[_n-1]
drop if drop == 1
drop drop

*add record for unexposed time between start of follow-up and first event
expand 2 if obsdate>`begin' & obsdate!=. & patid[_n]!=patid[_n-1]
sort patid obsdate
by patid: replace diab=0 if _n==1 & obsdate>`begin'
by patid: replace obsdate = `begin' if _n==1 & obsdate>`begin'

/*at each record, set the recorded type to 1 and the other to 0
i.e. diabetes is defined by the latest record and patients cannot have
type 1 and type 2 diabetes at the same time*/
gen b_type1 = 0
gen b_type2 = 0
replace b_type1 = 1 if diab == 1
replace b_type2 = 1 if diab == 2

gen type1date = obsdate
gen type2date = obsdate
format type1date type2date %dD/N/CY
drop obsdate diabetes

if "`wide'"=="wide" {
by patid: gen b_obs_num=_n

reshape wide b_`variable' `variable'date, i(patid) j(b_obs_num)
}

end



