cap prog drop pr_get_bclin_aurum

capture program drop pr_get_bclin_aurum
prog define pr_get_bclin_aurum
syntax , variable(string) qof(string) clinicalfile(string) clinfilenum(string) begin(string) end(string) runin(integer) 

preserve

display in red "*******************Observation file number: 1*******************"
*get all observation events matching code list
if "`qof'" == "qof" {
	use "$QRiskCodelistdir\cr_codelist_qof_cod_aurum.dta", clear
	keep if variable=="b_`variable'"
	}
	else {
		use "$QRiskCodelistdir\cr_codelist_`variable'_aurum.dta", clear
		}
merge 1:m medcodeid using "`clinicalfile'_1", nogen keep(match) keepusing(patid obsdate)
gen b_`variable'=1
keep patid obsdate b_`variable'
drop if obsdate==.
tempfile bclin
save `bclin' , replace


forvalues n=2/`clinfilenum' {
display in red "*******************Observation file number: `n'*******************"
if "`qof'" == "qof" {
	use "$QRiskCodelistdir\cr_codelist_qof_cod_aurum.dta", clear
	keep if variable=="b_`variable'"
	}
	else {
		use "$QRiskCodelistdir\cr_codelist_`variable'_aurum.dta", clear
		}
merge 1:m medcodeid using "`clinicalfile'_`n'", nogen keep(match) keepusing(patid obsdate)
gen b_`variable'=1
keep patid obsdate b_`variable'
drop if obsdate==.
append using "`bclin'"
save `bclin' , replace
}

*merge with patient file
restore
merge 1:m patid using `bclin', keep(match master)

*keep first event within specified time table
drop if _merge==3 & obsdate>`end'
drop if _merge==3 & obsdate<`begin'-365.25*`runin'
gsort patid -obsdate
duplicates drop patid if obsdate<`begin' & _merge==3 , force

sort patid obsdate
by patid: keep if _n==1

replace b_`variable'=0 if b_`variable'==.

*add record for unexposed time between start of follow-up and first event
expand 2 if obsdate>`begin' & obsdate!=. & patid[_n]!=patid[_n-1]
sort patid obsdate
by patid: replace b_`variable'=0 if _n==1 & obsdate>`begin'
by patid: replace obsdate = `begin' if _n==1 & obsdate>`begin'

drop _merge
rename obsdate `variable'date

end



