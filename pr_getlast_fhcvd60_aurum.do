cap prog drop pr_getlast_fhcvd60_aurum
program define pr_getlast_fhcvd60_aurum
syntax, clinicalfile(string) clinfilenum(string) index(string) runin(integer)

preserve

display in red "*******************Observation file number: 1*******************"
use "`clinicalfile'_1", clear
keep patid medcodeid obsdate
merge m:1 medcodeid using "$QRiskCodelistdir\cr_codelist_fhcvd60_aurum", keep(match) nogen
drop if obsdate==.
rename obsdate fh_date 
keep fh_date patid

tempfile tempura
save `tempura', replace


forvalues n=2/`clinfilenum' {
display in red "*******************Observation file number: `n'*******************"
use "`clinicalfile'_`n'", clear
keep patid medcodeid obsdate
merge m:1 medcodeid using "$QRiskCodelistdir\cr_codelist_fhcvd60_aurum", keep(match) nogen
drop if obsdate==.
rename obsdate fh_date 
keep fh_date patid

append using "`tempura'"
save `tempura', replace
}


restore
merge 1:m patid using `tempura', keep(match master)

gen before=1 if fh_date>`index' & _merge==3 & fh_date!=.
sort patid before fh_date 
by patid: keep if _n==_N
replace fh_date=. if fh_date>`index'
replace fh_date=. if fh_date<`index'-365.25*`runin' 

drop _merge before

gen fh_cvd=1 if fh_date!=.
replace fh_cvd=0 if fh_cvd==. 
replace fh_date=. if fh_cvd==0 

end
