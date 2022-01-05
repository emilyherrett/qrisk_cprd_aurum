cap prog drop pr_getlast_sbp_aurum

program define pr_getlast_sbp_aurum 
syntax , clinicalfile(string) clinfilenum(string) index(string) runin(integer)

preserve

display in red "*******************Observation file number: 1*******************"
use "$QRiskCodelistdir\cr_codelist_qof_cod_aurum.dta", clear
keep if variable=="sbp"
merge 1:m medcodeid using "`clinicalfile'_1", keep(match) keepusing(patid obsdate value) nogen

tempfile sbprecs
save `sbprecs', replace

forvalues n=2/`clinfilenum' {
display in red "*******************Observation file number: `n'*******************"
use "$QRiskCodelistdir\cr_codelist_qof_cod_aurum.dta", clear
keep if variable=="sbp"
merge 1:m medcodeid using "`clinicalfile'_`n'", keep(match) keepusing(patid obsdate value) nogen

append using "`sbprecs'"
save `sbprecs', replace
}

rename value sbp
destring sbp, replace
drop if obsdate==.
drop if sbp==.
drop if sbp<=1 

*keep lowest sbp if more than one measurement on same day
keep patid obsdate sbp
bysort patid obsdate (sbp): keep if _n==1

save `sbprecs', replace

restore
merge 1:m patid using `sbprecs', keep(match master)

rename obsdate bpdate
sort patid bpdate

*if first sbp record is after index, sets sbp and eventdate to missing for this record
by patid: replace sbp=. if _merge==3 & bpdate>`index' & _n==1
by patid: replace bpdate=. if _merge==3 & bpdate>`index' & _n==1

*drop remaining eventdates that are after the indexdate
drop if bpdate>`index' & _merge==3 & bpdate!=.

*if last sbp is before the run in period, sets sbp and eventdate to missing for this record
by patid: replace sbp=. if _merge==3 & bpdate<`index'-365.25*`runin' & _n==_N
by patid: replace bpdate=. if _merge==3 & bpdate<`index'-365.25*`runin' & _n==_N

*drop remaining eventdates that are before the run in period
drop if _merge==3 & bpdate<`index'-365.25*`runin' 

*keeps last event of sbp records that are within the specified period (i.e. event nearest to index)
gsort patid -bpdate sbp
duplicates drop patid if _merge==3 , force

drop _merge

end

