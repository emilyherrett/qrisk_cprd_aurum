cap prog drop pr_get_fhcvd60_aurum
program define pr_get_fhcvd60_aurum
syntax, clinicalfile(string) clinfilenum(string) begin(string) end(string) runin(integer)

preserve

display in red "*******************Observation file number: 1*******************"
use "`clinicalfile'_1" , clear
keep patid medcodeid obsdate
merge m:1 medcodeid using  "$QRiskCodelistdir\cr_codelist_fhcvd60_aurum", keep(match) nogen
drop if obsdate==.
rename obsdate fh_date
keep fh_date patid

tempfile tempura
save `tempura' , replace

forvalues n=2/`clinfilenum' {
display in red "*******************Observation file number: `n'*******************"
use "`clinicalfile'_`n'" , clear
keep patid medcodeid obsdate
merge m:1 medcodeid using  "$QRiskCodelistdir\cr_codelist_fhcvd60_aurum", keep(match) nogen
drop if obsdate==.
rename obsdate fh_date
keep fh_date patid

append using "`tempura'"
save `tempura' , replace
}

restore
merge 1:m patid using `tempura', nogen keep(match master)

drop if fh_date<`begin'-`runin'*365.25 | fh_date>`end' & fh_date!=.
sort patid fh_date
by patid: keep if _n==1
*keep first in study period*
gen fh_cvd=1 if fh_date<=`begin'
*set record to 1 if fh recorded before begin of follow up

expand 2 if fh_cvd!=1 & fh_date!=.
*generate another record if it has been recorded later in fup
sort patid
by patid: replace fh_date=`begin' if _N>1 & _n==1
*first record keep fh=0 & set date to start of follow up
by patid: replace fh_cvd=1 if _N>1 & _n==2
*second record keep record date and set fh=1

*set remaining missing records to zero
replace fh_cvd=0 if fh_cvd==.
replace fh_date=`begin' if fh_date==.

end
