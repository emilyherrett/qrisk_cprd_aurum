cap prog drop pr_get_sbpvarupdates_aurum

program define pr_get_sbpvarupdates_aurum 
syntax , clinicalfile(string) clinfilenum(string) begin(string) end(string) runin(integer) 

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
drop if obsdate==.
drop if sbp==.
drop if sbp<=1

*keep lowest sbp if more than one measurement on same day
keep patid obsdate sbp
bysort patid obsdate (sbp): keep if _n==1

save `sbprecs' , replace

***restrict to events during study period in patient file and order events after index date
restore
merge 1:m patid using `sbprecs' ,  keep(match master) nogen
sort patid obsdate

**add rows five years after each sbp record
gen sbp_sddate = obsdate
gen runoutdate = obsdate + (365.25*5) if obsdate!=.
format sbp_sddate runoutdate %dD/N/CY
gen order = _n
expand 2 if obsdate!=.
bysort patid order: replace obsdate = runoutdate if _n==2
bysort patid order: gen runout = 1 if _n==2
replace sbp_sddate = runoutdate if runout == 1
foreach var in sbp obsdate {
	replace `var' = . if runout == 1
	}
drop runoutdate order


**keep all records 5 years prior to index and before end date
keep if sbp_sddate < `end'
keep if sbp_sddate >= `begin' - (365.25*5)

**order records on or after index date
sort patid sbp_sddate
by patid: egen order = seq() if sbp_sddate >= `begin'
by patid: egen maxrec = max(order)

qui summ maxrec
local maxrecs = `r(max)'
di `maxrecs'

tempfile sbprecs
save `sbprecs' , replace

***CALCULATE SBP_SD AT EACH DATE

**calculate sbp at each subsequent record and append files
forvalues i = 1/`maxrecs' {
	di `i'
	use `sbprecs', clear
	sort patid sbp_sddate
	drop if (order > `i' & order !=.) | maxrec == .
	*identify all sbp measurements recorded in the five years before the sbp record
	by patid: egen orderdate = max(sbp_sddate)
	format orderdate %dD/N/CY
	assert orderdate == sbp_sddate if order == `i'
	gen _diff = orderdate - sbp_sddate
	gen _sbp5yr = 1 if _diff < (365.25*5) & _diff >= 0 & runout == .
	by patid: egen _countsbp5yr = count(_sbp5yr)
	*calculate standard deviation where there are two or more recorded values
	by patid: egen _sbp_sd = sd(sbp) if _sbp5yr == 1 & _countsbp5yr >= 2
	*fill missing records with calculated sbp_sd value (needed for runout dates)
	by patid: egen sbp_sd = min(_sbp_sd)
	keep if order == `i'
	isid patid
	drop sbp obsdate runout order maxrec orderdate _diff _sbp5yr _countsbp5yr _sbp_sd
	replace sbp_sd = 0 if sbp_sd == .
	if `i' > 1 append using "`sbpsdrecs'"
	tempfile sbpsdrecs
	save `sbpsdrecs', replace
	}

**remove sequential records with same sbp_sd value
duplicates drop	
bysort patid (sbp_sddate): gen dup = 1 if sbp_sd == sbp_sd[_n-1] & patid == patid[_n-1]
summ sbp_sd if dup == 1, d
drop if dup == 1
drop dup
save `sbpsdrecs', replace

**sbp_sd at index date 
use `sbprecs', clear
gen _diff = `begin' - obsdate
gen _sbp5yr = 1 if _diff < (365.25*5) & _diff >= 0
by patid: egen _countsbp5yr = count(_sbp5yr)

*calculate standard deviation where there are two or more recorded values
by patid: egen sbp_sd = sd(sbp) if _sbp5yr == 1 & _countsbp5yr >= 2
drop sbp obsdate runout order maxrec _diff _sbp5yr _countsbp5yr
keep if sbp_sd !=.
duplicates drop
gsort patid -sbp_sddate
duplicates drop patid, force
isid patid

append using "`sbpsdrecs'"

**sbp_sd = 0 at index date if no record prior to this date
assert sbp_sddate != .
sort patid sbp_sddate
expand 2 if sbp_sddate>`begin' & patid[_n]!=patid[_n-1] & sbp_sddate !=0

sort patid sbp_sddate
by patid: replace sbp_sd=0 if _n==1 & sbp_sddate>`begin'
by patid: replace sbp_sddate= `begin' if _n==1 & sbp_sddate>`begin'


end

