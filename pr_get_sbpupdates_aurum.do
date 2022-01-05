cap prog drop pr_get_sbpupdates_aurum

program define pr_get_sbpupdates_aurum
syntax , clinicalfile(string) clinfilenum(string) begin(string) end(string) runin(integer) 

preserve

display in red "*******************Observation file number: 1*******************"
use "$QRiskCodelistdir\cr_codelist_qof_cod_aurum", clear
keep if variable=="sbp"
merge 1:m medcodeid using "`clinicalfile'_1", keep(match) keepusing(patid obsdate value) nogen

tempfile sbprecs
save `sbprecs', replace

forvalues n=2/`clinfilenum' {
display in red "*******************Observation file number: `n'*******************"
use "$QRiskCodelistdir\cr_codelist_qof_cod_aurum", clear
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
merge 1:m patid using `sbprecs',  keep(match master)

rename obsdate bpdate
sort patid bpdate

drop if (bpdate<`begin'-365.25*`runin' | bpdate>`end') & _merge==3
gsort patid -bpdate sbp
duplicates drop patid if bpdate<`begin', force

sort patid bpdate
by patid: drop if sbp[_n-1]==sbp & _n>1

expand 2 if bpdate>`begin' & bpdate!=. & patid[_n]!=patid[_n-1]
sort patid bpdate
by patid: replace sbp=. if _n==1 & bpdate>`begin'
by patid: replace bpdate=`begin' if _n==1 & bpdate>`begin'

drop _merge

end

