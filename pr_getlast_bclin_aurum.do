cap prog drop pr_getlast_bclin_aurum

prog define pr_getlast_bclin_aurum 
syntax , variable(string) qof(string) clinicalfile(string) clinfilenum(string) index(string) runin(integer)

pause

preserve

display in red "*******************Observation file number: 1*******************"

if "`qof'" == "qof" {
	use "$QRiskCodelistdir\cr_codelist_qof_cod_aurum.dta", clear
	keep if variable=="b_`variable'"
	}
	else {
		use "$QRiskCodelistdir\cr_codelist_`variable'_aurum.dta", clear
		}
pause
merge 1:m medcodeid using "`clinicalfile'_1", keep(match) keepusing(patid obsdate) nogen
gen b_`variable'=1
keep patid obsdate b_`variable'
drop if obsdate==.
tempfile tempclinb
save `tempclinb' , replace


forvalues n=2/`clinfilenum' {
display in red "*******************Observation file number: `n'*******************"

if "`qof'" == "qof" {
	use "$QRiskCodelistdir\cr_codelist_qof_cod_aurum.dta", clear
	keep if variable=="b_`variable'"
	}
	else {
		use "$QRiskCodelistdir\cr_codelist_`variable'_aurum.dta", clear
		}
pause
merge 1:m medcodeid using "`clinicalfile'_`n'", keep(match) keepusing(patid obsdate) nogen
gen b_`variable'=1
keep patid obsdate b_`variable'
drop if obsdate==.
append using "`tempclinb'"
save `tempclinb' , replace
}
pause

restore
pause 
merge 1:m patid using `tempclinb', keep(match master)
pause
sort patid obsdate
by patid: replace obsdate=. if _merge==3 & obsdate>`index' & _n==1
by patid: replace b_`variable'=. if _merge==3 & obsdate>`index' & _n==1
drop if _merge==3 & obsdate>`index' & obsdate!=.

by patid: replace b_`variable'=. if _merge==3 & obsdate<`index'-365.25*`runin' & _n==_N 
by patid: replace obsdate=. if _merge==3 & obsdate<`index'-365.25*`runin' & _n==_N
drop if _merge==3 & obsdate<`index'-365.25*`runin'
gsort patid -obsdate
count if  _merge==3 
if `r(N)'>0 {
duplicates drop patid if  _merge==3 , force
}
replace b_`variable'=0 if b_`variable'==.

drop _merge
rename obsdate `variable'date

end


