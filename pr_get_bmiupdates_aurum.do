cap prog drop pr_get_bmiupdates_aurum

program define pr_get_bmiupdates_aurum 
syntax , clinicalfile(string) clinfilenum(string) begin(string) end(string) runin(integer) bmi_cutoff(integer)

preserve

display in red "*******************Observation file number: 1*******************"
use "$QRiskCodelistdir\cr_codelist_qof_cod_aurum", clear
keep if variable=="bmi"
merge 1:m medcodeid using "`clinicalfile'_1", keep(match) keepusing(patid obsdate value numunitid) nogen
drop if obsdate==.
tempfile bmirecs
save `bmirecs', replace


forvalues n=2/`clinfilenum' {
display in red "*******************Observation file number: `n'*******************"
use "$QRiskCodelistdir\cr_codelist_qof_cod_aurum", clear
keep if variable=="bmi"
merge 1:m medcodeid using "`clinicalfile'_`n'", keep(match) keepusing(patid obsdate value numunitid) nogen
drop if obsdate==.
append using "`bmirecs'"
save `bmirecs', replace
}

rename value bmi
destring bmi, replace
replace bmi=. if bmi>`bmi_cutoff'
replace bmi=. if bmi<10
drop if bmi==.

*use average bmi if more than one measurement on same day and <= 5kg/m2 difference
duplicates tag patid obsdate, gen(dup)
sort patid obsdate
by patid obsdate: egen minbmi = min(bmi)
by patid obsdate: egen maxbmi = max(bmi)
by patid obsdate: egen avbmi = mean(bmi)
gen diff = maxbmi - minbmi
drop if diff > 5
replace bmi = avbmi if dup > 0

keep patid obsdate bmi

save `bmirecs', replace

restore
merge 1:m patid using `bmirecs',  keep(match master)
rename obsdate bmidate
drop if (bmidate<`begin'-365.25*`runin' | bmidate>`end') & _merge==3
gsort patid -bmidate
duplicates drop patid if bmidate<=`begin', force

sort patid bmidate
expand 2 if bmidate>`begin' & bmidate!=. & patid[_n]!=patid[_n-1]
sort patid bmidate
by patid: replace bmi=. if _n==1 & bmidate>`begin'
by patid: replace bmidate=`begin' if _n==1 & bmidate>`begin'

drop _merge


end

