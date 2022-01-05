cap prog drop pr_getlast_sbpvar_aurum

program define pr_getlast_sbpvar_aurum 
syntax , clinicalfile(string) clinfilenum(string) index(string) runin(integer)

preserve

display in red "*******************Observation file number: 1*******************"
use "$QRiskCodelistdir\cr_codelist_qof_cod_aurum.dta", clear
keep if variable=="sbp"
merge 1:m medcode using  "`clinicalfile'_1" , keep(match) keepusing(patid obsdate value) nogen

tempfile sbprecs
save `sbprecs' , replace

forvalues n=2/`clinfilenum' {
display in red "*******************Observation file number: `n'*******************"
use "$QRiskCodelistdir\cr_codelist_qof_cod_aurum.dta", clear
keep if variable=="sbp"
merge 1:m medcode using  "`clinicalfile'_`n'" , keep(match) keepusing(patid obsdate value) nogen

append using "`sbprecs'"
save `sbprecs' , replace
}

rename value sbp
destring sbp, replace
drop if obsdate == .
drop if sbp==.
drop if sbp<=1

*keep lowest sbp if more than one measurement on same day
keep patid obsdate sbp
bysort patid obsdate (sbp): keep if _n==1

save `sbprecs' , replace

**keep all records 5 years prior to index
restore
merge 1:m patid using `sbprecs' ,  keep(match master) nogen
sort patid obsdate

*identify all sbp measurements recorded in the five years before study entry
gen _diff = `index' - obsdate
gen _sbp5yr = 1 if _diff < (365.25*5) & _diff >= 0
by patid: egen _countsbp5yr = count(_sbp5yr)

*calculate standard deviation where there are two or more recorded values
by patid: egen sbp_sd = sd(sbp) if _sbp5yr == 1 & _countsbp5yr >= 2
keep patid sbp_sd
keep if sbp_sd !=.
duplicates drop
isid patid

end

